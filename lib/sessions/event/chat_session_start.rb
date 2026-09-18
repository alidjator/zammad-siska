# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::ChatSessionStart < Sessions::Event::ChatBase

=begin

a agent start`s a new chat session

payload

  {
    event: 'chat_session_start',
    data: {},
  }

return is sent as message back to peer

=end

  def run
    return super if super
    return if !permission_check('chat.agent', 'chat')

    # find first in waiting list
    chat_user = User.lookup(id: @session['id'])
    chat_ids = Chat.agent_active_chat_ids(chat_user)
    chat_session = if @payload['chat_id']
                     Chat::Session.where(state: 'waiting', chat_id: @payload['chat_id']).reorder(created_at: :asc).first
                   else
                     Chat::Session.where(state: 'waiting', chat_id: chat_ids).reorder(created_at: :asc).first
                   end
    if !chat_session
      return {
        event: 'chat_session_start',
        data:  {
          state:   'failed',
          message: __('No session available.'),
        },
      }
    end
    chat_session.user_id = chat_user.id
    chat_session.state = 'running'
    chat_session.preferences[:participants] = chat_session.add_recipient(@client_id)
    chat_session.save

    # Fase 5 -- Item No. 5 (Auto-Create Ticket). See
    # docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.1.3. Dieksekusi
    # PERSIS di sini (titik "agent benar-benar mulai kontak dengan
    # customer"), bukan di chat_session_init (customer baru masuk
    # antrean, belum tentu ada agent yang akan melayani).
    create_ticket_for_chat_session(chat_session)

    session_attributes = chat_session.attributes
    session_attributes['messages'] = []
    Chat::Message.where(chat_session_id: chat_session.id).reorder(created_at: :asc).each do |message|
      session_attributes['messages'].push message.attributes
    end
    # Fase 5 -- fitur tambahan "Riwayat Chat Sebelumnya". Section 5.1.7.
    session_attributes['previous_sessions'] = previous_sessions_for(chat_session)

    # send chat_session_init to customer client
    if session_attributes['messages'].blank?
      user = chat_session.agent_user
      data = {
        event: 'chat_session_start',
        data:  {
          state:               'ok',
          agent:               user,
          session_id:          chat_session.session_id,
          chat_id:             chat_session.chat_id,
          # Fase 5 -- fitur tambahan enable/disable attachment
          # global+per-agent, Section 5.2.6. Widget customer tidak bisa
          # baca Setting/preferensi agent secara langsung -- dikirim di
          # sini (satu-satunya payload yang benar-benar sampai ke
          # customer) supaya tombol attach cuma muncul kalau memang
          # boleh dipakai untuk sesi ini.
          attachment_enabled: chat_session.attachment_enabled?,
        },
      }
      chat_session.send_to_recipients(data, @client_id)
    end

    # send to agent
    data = {
      event: 'chat_session_start',
      data:  {
        session: session_attributes,
      },
    }
    Sessions.send(@client_id, data)

    # send state update with sessions to agents
    Chat.broadcast_agent_state_update([chat_session.chat_id])

    # send position update to other waiting sessions
    Chat.broadcast_customer_state_update(chat_session.chat_id)

    nil
  end

  private

  # Fase 5 -- docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.1.3.
  def create_ticket_for_chat_session(chat_session)
    group_id = chat_session.chat.preferences[:ticket_group_id] || Setting.get('chat_auto_ticket_group_id')
    if group_id.blank?
      Rails.logger.info "Live Chat auto-ticket dilewati untuk sesi #{chat_session.session_id} -- chat_auto_ticket_group_id belum dikonfigurasi."
      return
    end

    customer = Channel::Filter::BaseIdentifyUser.user_create(
      email:     chat_session.email,
      firstname: chat_session.name.presence || chat_session.email,
      lastname:  '',
    )

    ticket = Ticket.create!(
      title:       "Live Chat - #{chat_session.name.presence || chat_session.email}",
      group_id:    group_id,
      customer_id: customer.id,
    )

    Ticket::Article.create!(
      ticket_id: ticket.id,
      type:      Ticket::Article::Type.find_by(name: 'chat'),
      sender:    Ticket::Article::Sender.find_by(name: 'System'),
      from:      chat_session.name.presence || chat_session.email,
      body:      __('Live chat dimulai.'),
      internal:  false,
    )

    chat_session.update!(ticket_id: ticket.id)
  rescue => e
    Rails.logger.error "Live Chat auto-ticket gagal dibuat untuk sesi #{chat_session.session_id}: #{e.message}"
  end

  # Fase 5 -- fitur tambahan "Riwayat Chat Sebelumnya dari Customer yang
  # Sama". docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.1.7. Dibatasi
  # 5 sesi terakhir -- cukup untuk konteks agent, tanpa daftar panjang
  # atau query berat untuk visitor yang sangat sering chat. Sesi lama
  # (sebelum email wajib diisi) tidak akan pernah muncul di sini
  # (email-nya kosong) -- keterbatasan yang disengaja diterima.
  def previous_sessions_for(chat_session)
    return [] if chat_session.email.blank?

    Chat::Session
      .where(email: chat_session.email)
      .where.not(id: chat_session.id)
      .order(created_at: :desc)
      .limit(5)
      .map { |session| { created_at: session.created_at, ticket_id: session.ticket_id } }
  end

end
