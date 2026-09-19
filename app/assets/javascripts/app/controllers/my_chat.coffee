# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 6 -- Live Chat Follow-Up Tiket untuk Semua User Login. See
# docs/DESIGN_CHAT_SELF_SERVICE.md. Halaman BARU, terbuka untuk SEMUA
# user login (permission ['*'], Section 4.3) -- BUKAN App.CustomerChat
# (yang tetap khusus agent, tidak disentuh sama sekali di sini).
#
# Chat di sini CUMA untuk follow-up tiket yang SUDAH ADA (Section 1
# poin 2/3) -- state `idle` menampilkan daftar tiket milik user
# sendiri, bukan tombol "mulai chat" bebas.
class App.MyChat extends App.Controller
  className: 'my-chat-page'

  events:
    'click .js-startChat': 'startChat'

  constructor: ->
    super

    @currentSessionId = null
    @chatWindow        = null

    @renderIdle(loading: true)
    @fetchTickets()

    # Balasan `chat_session_init` (Section 5.2 backend) -- SUKSES
    # datang sebagai `chat_session_queue`, GAGAL sebagai
    # `chat_session_init` dengan `state: 'failed'` -- konvensi yang
    # SAMA dipakai widget publik (public/assets/chat/chat-no-jquery.coffee),
    # dipakai ulang di sini bukan pola baru.
    @controllerBind('chat_session_queue', (data) =>
      return if !@waitingForSessionId
      @currentSessionId     = data.session_id
      @waitingForSessionId  = false
      @renderWaiting(data.position)
    )
    @controllerBind('chat_session_init', (data) =>
      return if data.state isnt 'failed'
      return if !@waitingForSessionId
      @waitingForSessionId = false
      @notify(
        type: 'error'
        msg:  data.message || __('This ticket is not available for chat follow-up.')
      )
      @fetchTickets()
    )
    # Fase 6 -- ChatSessionStart#run (agent accept) mengirim bentuk
    # payload LENGKAP `{session: {...}}` untuk sesi self-service
    # (docs/DESIGN_CHAT_SELF_SERVICE.md Section 5.5) -- persis yang
    # dibutuhkan App.ChatWindow (chat.coffee).
    @controllerBind('chat_session_start', (data) =>
      return if !data.session
      return if data.session.session_id isnt @currentSessionId
      @renderActive(data.session)
    )

  release: =>
    @chatWindow?.release()

  fetchTickets: =>
    @ajax(
      id:          'my_chat_tickets'
      type:        'GET'
      url:         "#{@apiPath}/tickets/search"
      data:
        query:       "customer_id:#{@Session.get('id')}"
        limit:       100
        full:        true
      processData: true
      success:     @onTicketsLoaded
      error:       => @renderIdle(loading: false, failed: true)
    )

  onTicketsLoaded: (data) =>
    App.Collection.loadAssets(data.assets) if data.assets

    # Filter "tiket terbuka" DI SINI cuma kenyamanan UX -- backend
    # (ChatSessionInit#self_service_init, docs/DESIGN_CHAT_SELF_SERVICE.md
    # Section 5.2) TETAP jadi penegak sesungguhnya (menolak tiket
    # closed/merged apa pun yang ditampilkan di sini). Kalau data
    # App.TicketState/state_type belum tersedia di collection lokal
    # (mis. race kecil tepat sesudah login), tiket TETAP ditampilkan
    # apa adanya alih-alih membuat daftar kosong/crash -- lebih aman
    # salah tampil (lalu ditolak sopan oleh server kalau memang bukan
    # tiket terbuka) daripada gagal total menampilkan daftar.
    open_state_types = ['new', 'open', 'pending reminder', 'pending action']
    tickets = (data.record_ids || [])
      .map((id) -> App.Ticket.find(id))
      .filter (ticket) ->
        return false if !ticket
        ticket_state = App.TicketState.find(ticket.state_id)
        return true if !ticket_state?.state_type
        _.contains(open_state_types, ticket_state.state_type.name)

    @renderIdle(loading: false, tickets: tickets)

  renderIdle: (params = {}) ->
    @html App.view('my_chat/ticket_list')(
      tickets: params.tickets || []
      loading: params.loading
      failed:  params.failed
    )

  startChat: (e) =>
    e.preventDefault()
    ticketId = $(e.currentTarget).data('ticket-id')
    return if !ticketId

    @waitingForSessionId = true
    @renderWaiting(null)

    App.WebSocket.send(
      event: 'chat_session_init'
      data:
        ticket_id: ticketId
        url:       window.location.href
    )

  renderWaiting: (position) ->
    @html App.view('my_chat/waiting')(
      position: position
    )

  renderActive: (session) ->
    @chatWindow?.release()
    @chatWindow = new App.ChatWindow(
      session:         session
      removeCallback:  @onChatEnded
      messageCallback: =>
    )
    # Atas laporan user: jendela sempat nempel batas lebar 640px
    # (dipakai buat 2 state lain, my_chat.scss) -- `.chat-window`
    # sendiri butuh DIBUNGKUS `.chat-workspace` (class NATIVE yang
    # SAMA dipakai App.CustomerChat#addChat) supaya sizing flexnya
    # (`.chat-window.is-open { flex: 1 0 25% }`) bisa membesar mengisi
    # ruang tersedia, PERSIS seperti sisi agent -- bukan CSS baru,
    # pakai ulang struktur yang sudah ada.
    workspace = $('<div class="chat-workspace"></div>')
    workspace.append(@chatWindow.el)
    @html workspace
    # Urutan yang SAMA seperti App.CustomerChat#addChat (chat.coffee) --
    # `render()` TIDAK dipanggil otomatis oleh constructor `ChatWindow`,
    # harus dipanggil eksplisit SETELAH `.el`-nya ditempel ke DOM.
    @chatWindow.render()

  onChatEnded: (session_id) =>
    @currentSessionId = null
    @chatWindow        = null
    @fetchTickets()

class MyChatRouter extends App.ControllerPermanent
  @requiredPermission: '*'
  constructor: (params) ->
    super

    App.TaskManager.execute(
      key:        'MyChat'
      controller: 'MyChat'
      params:     {}
      show:       true
      persistent: true
    )

App.Config.set('my_chat', MyChatRouter, 'Routes')
App.Config.set('MyChat', { controller: 'MyChat', permission: ['*'] }, 'permanentTask')
App.Config.set('MyChat', { prio: 1250, parent: '', name: __('Live Chat'), target: '#my_chat', key: 'MyChat', permission: ['*'], class: 'chat' }, 'NavBar')
