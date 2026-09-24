# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::ChatSessionReaction < Sessions::Event::ChatBase

=begin

the customer (widget) sets or removes an emoji reaction on an agent message,
or an agent sets or removes one on a customer message (G3)

payload

  {
    event: 'chat_session_reaction',
    data: {
      session_id: '...',
      message_id: 123,
      reaction:   '👍', # nil / '' = remove
    },
  }

return is sent as message back to peer

=end

  # Atas permintaan user: HANYA 5 emoji ini (mockup "Reaksi emoji bubble").
  # Whitelist di server -- nilai lain ditolak diam-diam, bukan disimpan.
  ALLOWED_REACTIONS = ["\u{1F600}", "\u{1F60A}", "\u{1F64F}", "\u{1F44D}", "\u{2764}\u{FE0F}"].freeze

  def run
    return super if super
    return if !check_chat_session_exists

    chat_session = current_chat_session

    # Otorisasi: client pengirim WAJIB peserta sesi ini (ditambahkan saat
    # chat_session_start / reconnect chat_status_customer), bukan cuma
    # tahu session_id-nya. Berlaku untuk customer maupun agent.
    return if Array(chat_session.preferences[:participants]).exclude?(@client_id)

    reaction = @payload['data']['reaction'].presence
    return if reaction && ALLOWED_REACTIONS.exclude?(reaction)

    chat_message = Chat::Message.find_by(id: @payload['data']['message_id'], chat_session_id: chat_session.id)
    return if !chat_message

    # G3 (docs/COMPARISON_WIDGET_VS_AGENT.md, keputusan user "perlu"): kedua
    # arah. Customer (visitor anonim, tanpa user login) bereaksi ke pesan
    # AGENT (created_by_id terisi) -> `customer_reaction`; agent bereaksi ke
    # pesan CUSTOMER (created_by_id kosong) -> `agent_reaction`. `reactor`
    # di broadcast memberi tahu penerima bubble mana yang diperbarui.
    if @session && @session['id']
      return if !permission_check('chat.agent', 'chat')
      return if chat_message.created_by_id.present?

      reactor = 'agent'
      column  = :agent_reaction
    else
      return if chat_message.created_by_id.blank?

      reactor = 'customer'
      column  = :customer_reaction
    end

    # update_columns: tanpa callback/sinkron tiket -- reaksi bukan isi
    # percakapan yg perlu jadi artikel tiket.
    chat_message.update_columns(column => reaction) # rubocop:disable Rails/SkipsModelValidations

    data = {
      session_id: chat_session.session_id,
      message_id: chat_message.id,
      reaction:   reaction,
      reactor:    reactor,
    }

    # Peserta lain (tab customer lain / agent) ikut diberi tahu.
    chat_session.send_to_recipients({ event: 'chat_session_reaction', data: data }, @client_id)

    { event: 'chat_session_reaction', data: data.merge(self_written: true) }
  end

end
