# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Redesign sisi agent -- riwayat chat di jendela percakapan, gaya WhatsApp
# (mockup "Riwayat chat di jendela percakapan", canvas SISKA Agent - Kit
# Tailwind). Keputusan user: cakupan = semua sesi lain dari EMAIL yang sama
# yang dimulai sebelum sesi ini; per halaman 10 pesan riwayat (percakapan
# saat ini selalu tampil utuh, tidak ikut dihitung); paging dengan scroll
# ke atas lewat `before_id`.

class Sessions::Event::ChatSessionHistory < Sessions::Event::ChatBase

=begin

an agent loads one page of earlier messages from the same customer email

payload

  {
    event: 'chat_session_history',
    data: {
      session_id: '...',   # the session shown in the agent's chat window
      before_id:  123,     # optional: only messages with a smaller id
    },
  }

return is sent as message back to peer

  {
    event: 'chat_session_history',
    data: {
      session_id: '...',
      messages:   [...],   # oldest first, max. PAGE_SIZE
      sessions:   { '<id>' => { ... } },
      has_more:   true,
    },
  }

=end

  PAGE_SIZE = 10

  def run
    return super if super
    return if !check_chat_session_exists
    return if !permission_check('chat.agent', 'chat')

    chat_session = current_chat_session
    data = {
      session_id: chat_session.session_id,
      before_id:  @payload['data']['before_id'],
      messages:   [],
      sessions:   {},
      has_more:   false,
    }
    return { event: 'chat_session_history', data: data } if chat_session.email.blank?

    history_session_ids = Chat::Session
      .where(email: chat_session.email)
      .where.not(id: chat_session.id)
      .where('created_at < ?', chat_session.created_at)
      .pluck(:id)
    return { event: 'chat_session_history', data: data } if history_session_ids.blank?

    scope = Chat::Message.where(chat_session_id: history_session_ids)
    before_id = @payload['data']['before_id'].to_i
    scope = scope.where('id < ?', before_id) if before_id.positive?
    page = scope.reorder(id: :desc).limit(PAGE_SIZE + 1).to_a

    data[:has_more] = page.size > PAGE_SIZE
    page = page.first(PAGE_SIZE).reverse

    sessions = Chat::Session.where(id: page.map(&:chat_session_id).uniq).index_by(&:id)
    data[:messages] = page.map do |message|
      Chat::Session.send(:enrich_message_attributes, message).merge(
        'is_from_agent' => message.created_by_id.present? && message.created_by_id == sessions[message.chat_session_id]&.user_id,
      )
    end
    data[:sessions] = sessions.transform_values { |session| session_summary(session) }

    { event: 'chat_session_history', data: data }
  end

  private

  def session_summary(session)
    first_id = session.messages.minimum(:id)
    last_message = session.messages.reorder(id: :desc).first
    summary = {
      id:               session.id,
      session_id:       session.session_id,
      created_at:       session.created_at,
      ended_at:         session.preferences[:closed_at] || last_message&.created_at,
      closed_by:        session.preferences[:closed_by],
      state:            session.state,
      name:             session.name,
      agent_id:         session.user_id,
      agent_name:       session.user_id ? User.lookup(id: session.user_id)&.fullname : nil,
      first_message_id: first_id,
      last_message_id:  last_message&.id,
    }
    ticket = session.ticket
    if ticket
      summary[:ticket_id]     = ticket.id
      summary[:ticket_number] = ticket.number
      if Setting.get('chat_agent_show_rating') && ticket.try(:csat_score).present?
        summary[:csat_score]   = ticket.csat_score
        summary[:csat_comment] = ticket.csat_comment
      end
    end
    summary
  end

end
