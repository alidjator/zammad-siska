# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

class Sessions::Event::ChatSessionReaction < Sessions::Event::ChatBase

=begin

the customer (widget) sets or removes an emoji reaction on an agent message

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

    # Fase ini hanya CUSTOMER (visitor anonim, tanpa user login) -- agent
    # menyusul fase berikutnya.
    return if @session && @session['id']

    chat_session = current_chat_session

    # Otorisasi: client pengirim WAJIB peserta sesi ini (ditambahkan saat
    # chat_session_start / reconnect chat_status_customer), bukan cuma
    # tahu session_id-nya.
    return if Array(chat_session.preferences[:participants]).exclude?(@client_id)

    reaction = @payload['data']['reaction'].presence
    return if reaction && ALLOWED_REACTIONS.exclude?(reaction)

    # Reaksi hanya utk pesan AGENT (created_by_id terisi) di sesi yg sama.
    chat_message = Chat::Message.find_by(id: @payload['data']['message_id'], chat_session_id: chat_session.id)
    return if !chat_message || chat_message.created_by_id.blank?

    # update_columns: tanpa callback/sinkron tiket -- reaksi bukan isi
    # percakapan yg perlu jadi artikel tiket.
    chat_message.update_columns(customer_reaction: reaction)

    data = {
      session_id: chat_session.session_id,
      message_id: chat_message.id,
      reaction:   reaction,
    }

    # Peserta lain (tab customer lain, agent -- agent belum menampilkan,
    # fase berikutnya) ikut diberi tahu.
    chat_session.send_to_recipients({ event: 'chat_session_reaction', data: data }, @client_id)

    { event: 'chat_session_reaction', data: data.merge(self_written: true) }
  end

end
