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
    #
    # Enhancement 1 -- Tahap 2: logikanya DIPINDAH ke
    # `Chat::Session#create_ticket_for_chat!` (murni ekstraksi, TIDAK
    # ADA perubahan perilaku) supaya bisa dipakai ulang dari alur
    # pesan-offline (Tahap 3) yang tidak punya langkah "Accept" spt di
    # sini.
    chat_session.create_ticket_for_chat!

    session_attributes = chat_session.attributes
    session_attributes['messages'] = []
    Chat::Message.where(chat_session_id: chat_session.id).reorder(created_at: :asc).each do |message|
      session_attributes['messages'].push message.attributes
    end
    # Fase 5 -- fitur tambahan "Riwayat Chat Sebelumnya". Section 5.1.7.
    # Dipindah jadi method di `Chat::Session` (`previous_sessions_summary`)
    # supaya jendela chat yang RECONNECT (`Chat.active_chats_by_user_id`,
    # dipicu reload halaman) juga dapat riwayat ini -- lihat komentar di
    # model, sebelumnya field ini cuma dikirim sekali di sini saja.
    session_attributes['previous_sessions'] = chat_session.previous_sessions_summary
    # Fase 6 -- docs/DESIGN_CHAT_SELF_SERVICE.md. Disertakan di
    # `session_attributes` (dipakai KEDUA payload di bawah) supaya
    # `ChatWindow` milik USER LOGIN (bukan agent yang di-assign ke
    # sesi ini) bisa tahu apakah attachment boleh dipakai untuk SESI
    # INI -- lihat comment di `chat.coffee#render` (tidak bisa lagi
    # cuma mengandalkan preferensi pribadi orang yang sedang login,
    # karena bisa jadi customer, bukan agent).
    session_attributes['attachment_enabled'] = chat_session.attachment_enabled?

    # send chat_session_init to customer client
    if session_attributes['messages'].blank?
      data = if chat_session.preferences[:self_service]
               # Fase 6 -- docs/DESIGN_CHAT_SELF_SERVICE.md Section 5.5.
               # Customer di sini adalah App.ChatWindow, KOMPONEN YANG
               # SAMA PERSIS dipakai agent -- butuh bentuk payload
               # LENGKAP yang sama seperti agent terima (termasuk
               # previous_sessions untuk riwayat), BUKAN payload datar
               # ala widget publik anonim di bawah (yang punya parser
               # JS sendiri, cuma butuh field-field itu).
               {
                 event: 'chat_session_start',
                 data:  { session: session_attributes },
               }
             else
               # widget anonim (Item 5 asli) -- TIDAK BERUBAH SAMA SEKALI.
               user = chat_session.agent_user
               {
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
             end
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

end
