# Redesign sisi agent (Tahap 1) -- pola DAFTAR + DETAIL (mockup canvas
# "SISKA Agent - Kit Tailwind", artboard 1) menggantikan jendela chat yang
# berjajar. Semua jendela (`App.ChatWindow`) tetap dibuat & hidup seperti
# sebelumnya (event WebSocket, unread, dst tidak berubah), hanya SATU yang
# tampil di kartu detail; sisanya disembunyikan dengan `visibility`, BUKAN
# `display: none`, karena `ChatWindow` baru menyiapkan input-nya di event
# `transitionend` (lihat `onTransitionend`), yang tidak pernah terjadi pada
# elemen `display: none`.
#
# Terima chat tetap FIFO (keputusan user): satu tombol "Accept next" per
# topik, backend `chat_session_start` tidak berubah. Daftar tunggu hanya
# informasi.
class App.CustomerChat extends App.Controller
  events:
    'click .js-acceptChat':    'acceptChat'
    'click .js-settings':      'settings'
    'click .js-selectChat':    'onSelectChat'
    'change .js-onlineSwitch': 'onOnlineSwitch'
    'input .js-listSearch':    'onListSearch'
    'click .js-goOnline':      'onGoOnline'
    'click .js-settingsCancel': 'closeSettings'
    'submit .js-settingsForm':  'saveSettings'
    'change .js-topicActive':   'onTopicActiveChange'

  elements:
    '.chat-workspace':  'workspace'
    '.js-list':         'list'
    '.js-summary':      'summary'
    '.js-onlineSwitch': 'onlineSwitch'
    '.js-onlineLabel':  'onlineLabel'
    '.js-detailEmpty':  'detailEmpty'
    '.js-offlineBanner': 'offlineBanner'
    '.js-settingsView':  'settingsView'

  sounds:
    chat_new: new Audio('assets/sounds/chat_new.mp3')

  constructor: ->
    super

    @chatWindows = {}
    @maxChatWindows = 4
    preferences = @Session.get('preferences')
    if preferences && preferences.chat && preferences.chat.max_windows
      @maxChatWindows = parseInt(preferences.chat.max_windows)

    @pushStateIntervalOn = undefined
    @selectedSessionId = undefined
    @listQuery = ''
    @idleTimeout = parseInt(@Config.get('chat_agent_idle_timeout') || 120)
    @messageCounter = 0
    @meta =
      active: false
      waiting_chat_count: 0
      waiting_chat_count_by_chat: {}
      waiting_chat_session_list: []
      waiting_chat_session_list_by_chat: {}
      running_chat_count: 0
      running_chat_session_list: []
      active_agent_count: 0
      active_agent_ids: []

    @render()
    @on('layout-has-changed', @propagateLayoutChange)

    # timer tunggu & jam di daftar
    @interval(@renderList, 30000, 'siska-chat-list')

    # klik notifikasi desktop -> pilih percakapannya juga (fokus input
    # sendiri tetap ditangani ChatWindow lewat event yang sama)
    @controllerBind('chat_focus', (data) =>
      @selectChat(data.session_id) if @chatWindows[data.session_id]
    )

    # update navbar on new status
    @controllerBind('chat_status_agent', (data) =>
      if data.assets
        App.Collection.loadAssets(data.assets)
      @meta = data
      # banner Offline baru boleh tampil setelah status asli dari server
      # diketahui (bukan default `active: false` saat halaman dimuat)
      @metaLoaded = true
      @updateMeta()
      if data.active is true
        @startPushState()
    )

    # add new chat window
    @controllerBind('chat_session_start', (data) =>
      if data.session
        @addChat(data.session)
      else
        # mis. antrean sudah diambil agent lain -- jangan sampai sesi lain
        # yang datang belakangan ikut dipilih otomatis
        @acceptPending = false
    )

    # on new login or on
    @controllerBind('ws:login chat_agent_state', ->
      App.WebSocket.send(event:'chat_status_agent')
    )
    App.WebSocket.send(event:'chat_status_agent')

    # rerender view, e. g. on langauge change
    @controllerBind('ui:rerender chat:rerender', =>
      return if !@authenticateCheck()
      for session_id, chat of @chatWindows
        chat.el.remove()
      @chatWindows = {}
      @render()
      App.WebSocket.send(event:'chat_status_agent')
    )

  startPushState: =>
    return if @pushStateIntervalOn
    @pushStateIntervalOn = true
    @interval(@pushState, 55000, 'pushState')

  stopPushState: =>
    @pushStateIntervalOn = false
    @clearInterval('pushState')

  pushState: =>
    App.WebSocket.send(
      event:'chat_agent_state'
      data:
        active: @meta.active
    )

  featureActive: =>
    return true if @Config.get('chat')
    false

  render: ->
    if !@permissionCheck('chat.agent')
      @renderScreenUnauthorized(objectName: 'Chat')
      return
    if !@Config.get('chat')
      @renderScreenError(detail: __('Feature disabled!'))
      return

    @html App.view('customer_chat/index')()
    @selectedSessionId = undefined
    @renderHeader()
    @renderList()


  show: (params) =>
    @title(__('Customer Chat'), true)
    @navupdate('#customer_chat')

    if params.session_id
      callback = (session) =>
        @addChat(session)
      App.ChatSession.full(params.session_id, callback)
      @navigate '#customer_chat'

  active: (state) =>
    return @shown if state is undefined
    @shown = state

  counter: =>
    counter = 0

    # get count of controller messages
    if @meta.waiting_chat_count
      counter += @meta.waiting_chat_count

    # play on changes
    if @lastWaitingChatCount isnt counter

      # do not play sound on initial load
      if @switch()
        if counter > 0 && @lastWaitingChatCount isnt undefined
          @sounds.chat_new.play()
          @notifyDesktop(
            title: "#{counter} #{App.i18n.translateInline('Waiting Customers')}",
            url: '#customer_chat'
          )
      @lastWaitingChatCount = counter

    # collect chat window messages
    for key, value of @chatWindows
      if value
        counter += value.unreadMessages()

    @messageCounter = counter

  switch: (state = undefined) =>

    # read state
    if state is undefined
      return @meta.active

    @meta.active = state

    # check if min one chat is active
    if state
      @startPushState()
      preferences = @Session.get('preferences')
      if App.Chat.first() && !preferences || !preferences.chat || !preferences.chat.active || _.isEmpty(preferences.chat.active)

        # if we only have one chat, active it automatically
        if App.Chat.count() < 2
          preferences.chat = {}
          preferences.chat.active = {}
          preferences.chat.active[App.Chat.first().id] = 'on'

          # update user preferences
          @ajax(
            id:          'preferences'
            type:        'PUT'
            url:         "#{@apiPath}/users/preferences"
            data:        JSON.stringify(chat: preferences.chat)
            processData: true
            success:     @success
            error:       @error
          )

        # if we have more chats, let decide the user
        else
          msg = __('To be able to chat you need to select at least one chat topic from below!')

          # open modal settings
          @settings(
            errors:
              settings: msg
            active: @meta.active
          )

          @meta.active = false
          @pushState()
    else
      @stopPushState()
      @pushState()

    @renderHeader()
    @renderList()

  activeChatTopcis: =>
    preferences = @Session.get('preferences')
    return [] if !preferences
    return [] if !preferences.chat
    return [] if !preferences.chat.active
    chats = []
    for chat in App.Chat.all()
      if preferences.chat.active[chat.id] is 'on' || preferences.chat.active[chat.id.toString()] is 'on'
        chats.push chat
    chats

  updateMeta: =>
    if @meta.waiting_chat_count && @maxChatWindows > @windowCount()
      @idleTimeoutStart()
    else
      @idleTimeoutStop()

    # reopen chats
    if @meta.active_sessions
      for session in @meta.active_sessions
        @addChat(session)
    @meta.active_sessions = false

    @renderHeader()
    @renderList()
    @updateNavMenu()

  renderHeader: =>
    return if !@summary?.length
    running = _.filter(_.values(@chatWindows), (chat) -> chat && !chat.isOffline).length
    waiting = @meta.waiting_chat_count || 0
    parts = [
      App.i18n.translateInline('%s in progress', running)
      App.i18n.translateInline('%s waiting', waiting)
      App.i18n.translateInline('%s active agents', @meta.active_agent_count || 0)
    ]
    @summary.html(parts.join(' &middot; '))

    agents = (App.User.find(id)?.displayName() for id in (@meta.active_agent_ids || []))
    @summary.attr('title', _.compact(agents).join(', '))

    active = !!@meta.active
    @onlineSwitch.prop('checked', active)
    @onlineLabel.text(App.i18n.translatePlain(if active then 'Online' else 'Offline'))
    @offlineBanner.toggleClass('hidden', !@metaLoaded || active)

  onGoOnline: (e) =>
    e.preventDefault()
    @switch(true)
    @updateNavMenu()

  renderList: =>
    return if !@list?.length
    query = @listQuery.toLowerCase()
    matches = (text) ->
      return true if !query
      (text || '').toLowerCase().indexOf(query) isnt -1

    running = []
    ended = []
    for sessionId, chat of @chatWindows
      continue if !chat
      session = chat.session
      continue if !matches("#{chat.name} #{session.email || ''} ##{session.id}")
      last = chat.lastMessage
      target = if chat.isOffline then ended else running
      target.push(
        sessionId:   sessionId
        name:        chat.name || "##{session.id}"
        initials:    App.SiskaFormat.initials(chat.name)
        time:        App.SiskaFormat.time(last?.time || session.created_at)
        snippet:     last?.text || App.i18n.translatePlain('Chat #%s', session.id)
        snippetIcon: last?.icon
        unread:      chat.unreadMessages()
        ended:       !!chat.isOffline
        selected:    sessionId is @selectedSessionId
      )

    topics = @activeChatTopcis()
    waiting = []
    waitingTotal = 0
    for topic in topics
      sessions = []
      for waitingSession in (@meta.waiting_chat_session_list_by_chat?[topic.id] || [])
        continue if !matches("#{waitingSession.name || ''} #{waitingSession.email || ''} #{waitingSession.category || ''}")
        sessions.push(
          name:     waitingSession.name || App.i18n.translatePlain('Visitor')
          initials: App.SiskaFormat.initials(waitingSession.name)
          category: waitingSession.category
          wait:     @formatWait(waitingSession.created_at)
        )
      waitingTotal += sessions.length
      waiting.push(id: topic.id, name: topic.displayName(), sessions: sessions)

    @list.html App.view('customer_chat/siska_list')(
      running:      running
      ended:        ended
      waiting:      waiting
      waitingTotal: waitingTotal
      showTopics:   topics.length > 1
      canAccept:    @maxChatWindows > @windowCount()
      active:       !!@meta.active
      query:        @listQuery
    )

    @detailEmpty.toggleClass('hidden', !!@selectedSessionId)

  formatWait: (time) ->
    return '' if !time
    minutes = Math.max(0, Math.floor((Date.now() - new Date(time).getTime()) / 60000))
    return App.i18n.translatePlain('just now') if minutes < 1
    return App.i18n.translatePlain('%s min', minutes) if minutes < 60
    App.i18n.translatePlain('%s h %s min', Math.floor(minutes / 60), minutes % 60)

  onListSearch: (e) =>
    @listQuery = $(e.currentTarget).val() || ''
    @renderList()

  onOnlineSwitch: (e) =>
    @switch($(e.currentTarget).prop('checked'))
    @updateNavMenu()

  onSelectChat: (e) =>
    e.preventDefault()
    @selectChat($(e.currentTarget).attr('data-session-id'))

  # Tampilkan satu jendela di kartu detail. Fokus ke input memicu
  # `clearUnread` milik ChatWindow (tanda dibaca ke customer), sama seperti
  # agent mengklik jendela di tata letak lama.
  selectChat: (sessionId) =>
    chat = @chatWindows[sessionId]
    return if !chat
    @selectedSessionId = sessionId
    for id, other of @chatWindows
      other.el.toggleClass('is-selected', id is sessionId)
    chat.trigger('layout-changed')
    chat.focus()
    @renderList()

  # dipanggil ChatWindow per pesan (termasuk saat replay riwayat), jadi
  # di-debounce supaya daftar tidak dirender ulang puluhan kali berturut-turut
  onChatChanged: =>
    @delay(=>
      @renderList()
      @updateNavMenu()
    , 50, 'siska-chat-changed')

  addChat: (session) ->
    return if @chatWindows[session.session_id]
    chat = new App.ChatWindow(
      session: session
      removeCallback: @removeChat
      messageCallback: @onChatChanged
      changeCallback: @onChatChanged
      siska: true
    )

    @workspace.append chat.el
    chat.render()
    @chatWindows[session.session_id] = chat

    # chat yang baru diterima (atau satu-satunya) langsung dibuka;
    # sesi yang dipulihkan setelah reload tidak merebut pilihan agent
    if !@selectedSessionId || @acceptPending
      @acceptPending = false
      @selectChat(session.session_id)
    else
      @renderList()

  windowCount: =>
    count = 0
    for chat of @chatWindows
      count++
    count

  removeChat: (session_id) =>
    delete @chatWindows[session_id]
    if @selectedSessionId is session_id
      @selectedSessionId = undefined
      next = _.keys(@chatWindows)[0]
      @selectChat(next) if next
    @updateMeta()

  propagateLayoutChange: (event) =>
    # adjust scroll position on layoutChange
    for session_id, chat of @chatWindows
      chat.trigger('layout-changed')

  acceptChat: (e) =>
    return if @windowCount() >= @maxChatWindows
    chat_id = $(e.currentTarget).attr('data-chat-id')
    @acceptPending = true
    App.WebSocket.send(event:'chat_session_start', chat_id: chat_id)
    @idleTimeoutStop()

  # Redesign sisi agent (Tahap 5) -- halaman Pengaturan menggantikan modal
  # `Setting` lama. Dipanggil dari tombol Settings ATAU dari `switch` (Online
  # tanpa topik aktif, dgn pesan error + `active` = status yang diminta),
  # persis seperti modal dulu. Jendela chat tetap hidup di belakangnya.
  settings: (params = {}) ->
    @openSettings(params)

  openSettings: (params = {}) =>
    preferences = @Session.get('preferences') || {}
    chatPrefs = preferences.chat || {}
    active = chatPrefs.active || {}
    phrase = chatPrefs.phrase || {}
    @settingsActive = params.active

    chats = for chat in App.Chat.all()
      id: chat.id
      name: chat.displayName()
      phrase: phrase[chat.id] || phrase[chat.id.toString()]
      active: active[chat.id] is 'on' || active[chat.id.toString()] is 'on'

    @settingsView.html App.view('customer_chat/siska_settings')(
      preferences:      _.extend({ max_windows: @maxChatWindows }, chatPrefs)
      chats:            chats
      error:            params.errors?.settings
      attachmentGlobal: !!App.Config.get('chat_attachment_enabled')
      policy:           @meta.attachment_policy
      firstname:        App.Session.get('firstname')
    )
    @el.find('.siska-chat-page').addBack('.siska-chat-page').addClass('is-settings')
    @settingsView.removeClass('hidden')
    @settingsView.find('.js-maxWindows').trigger('focus')

  closeSettings: (e) =>
    e?.preventDefault()
    @settingsView.addClass('hidden').empty()
    @el.find('.siska-chat-page').addBack('.siska-chat-page').removeClass('is-settings')
    @$('.js-settings').trigger('focus')

  onTopicActiveChange: (e) =>
    input = $(e.currentTarget)
    input.closest('.js-topic').find('.js-topicState').text(
      App.i18n.translatePlain(if input.prop('checked') then 'Receiving chats' else 'Not receiving chats')
    )

  saveSettings: (e) =>
    e.preventDefault()
    view = @settingsView
    previous = @Session.get('preferences')?.chat || {}

    chat =
      max_windows:      view.find('.js-maxWindows').val()
      alternative_name: view.find('.js-alternativeName').val()
      avatar_state:     if view.find('.js-avatarState').prop('checked') then 'enabled' else 'disabled'
      phrase:           {}
      active:           {}
    # saklar lampiran hanya tampil bila fitur global menyala; kalau tidak,
    # nilai lama dipertahankan (modal lama juga tidak menyentuhnya)
    attachment = view.find('.js-attachmentEnabled')
    if attachment.length
      chat.attachment_enabled = attachment.prop('checked')
    else if previous.attachment_enabled?
      chat.attachment_enabled = previous.attachment_enabled
    view.find('.js-topic').each (index, el) ->
      topic = $(el)
      id = topic.attr('data-chat-id')
      chat.phrase[id] = topic.find('.js-topicPhrase').val()
      chat.active[id] = 'on' if topic.find('.js-topicActive').prop('checked')

    # berlaku langsung tanpa reload (sama dgn modal lama)
    @maxChatWindows = parseInt(chat.max_windows, 10)

    # semua topik dimatikan -> agent Offline
    @settingsActive = false if _.isEmpty(chat.active)

    save = view.find('.js-settingsSave').prop('disabled', true)
    @ajax(
      id:          'preferences'
      type:        'PUT'
      url:         "#{@apiPath}/users/preferences"
      data:        JSON.stringify(chat: chat)
      processData: true
      success:     =>
        if @settingsActive is true || @settingsActive is false
          @meta.active = @settingsActive
          @pushState()
        else
          App.WebSocket.send(event:'chat_status_agent')
        App.User.full(
          App.Session.get('id'),
          =>
            @closeSettings()
            @renderHeader()
            @renderList()
            @updateNavMenu()
          ,
          true
        )
      error: (xhr) =>
        save.prop('disabled', false)
        data = try JSON.parse(xhr.responseText) catch then {}
        @notify(
          type: 'error'
          msg:  data?.message || __('The settings could not be saved.')
        )
    )

  idleTimeoutStart: =>
    return if @idleTimeoutId
    switchOff = =>
      @switch(false)
      @notify(
        type: 'notice'
        msg:  __('Chat not answered, automatically set to offline.')
      )
    @idleTimeoutId = @delay(switchOff, @idleTimeout * 1000)

  idleTimeoutStop: =>
    return if !@idleTimeoutId
    @clearDelay(@idleTimeoutId)
    @idleTimeoutId = undefined

  setPosition: (position) =>
    @$('.main').scrollTop(position)

  currentPosition: =>
    @$('.main').scrollTop()

# Fase 6 -- diekspor sebagai App.ChatWindow (bukan cuma ChatWindow
# top-level) supaya bisa dipakai ulang secara EKSPLISIT dari controller
# lain (App.MyChat, my_chat.coffee) untuk live chat follow-up tiket
# oleh user login -- lihat docs/DESIGN_CHAT_SELF_SERVICE.md Section 4.1.
# Rename MURNI, tidak ada logika di bawah ini yang berubah.
class App.ChatWindow extends App.Controller
  className: 'chat-window'

  events:
    'keydown .js-customerChatInput': 'onKeydown'
    'focus .js-customerChatInput':   'clearUnread'
    'click':                         'clearUnread'
    'click .js-send':                'sendMessage'
    'click .js-close':               'close'
    'click .js-disconnect':          'disconnect'
    'click .js-scrollHint':          'onScrollHintClick'
    'click .js-info':                'toggleMeta'
    'click .js-createTicket':        'ticketCreate'
    'click .js-transferChat':        'transfer'
    'click .chat-message img':       'imageView'
    'submit .js-metaForm':           'sendMetaForm'
    'click .js-replyMessage':        'startReply'
    'click .js-cancelReply':         'cancelReply'
    'click .js-openPreviousTicket':  'openPreviousTicket'
    'click .js-attachButton':        'triggerAttachmentInput'
    'change .js-attachmentInput':    'uploadAttachment'
    # Redesign sisi agent (Tahap 2) -- hanya ada di markup varian `siska`
    'click .js-imageButton':         'triggerImageInput'
    'change .js-imageInput':         'uploadAttachment'
    'click .js-siskaImage':          'openSiskaImage'
    'click .siska-msg-text img':     'imageView'
    'click .js-msgMenuToggle':       'toggleMessageMenu'
    'click .js-emojiToggle':         'toggleEmojiPicker'
    'click .js-emojiItem':           'insertEmoji'
    'keydown':                       'onWindowKeydown'
    'click .js-toggleProfile':       'toggleProfile'
    'click .js-historyMore':         'loadMoreHistory'
    'click .js-copyMessage':         'copyMessage'
    'click .js-reactMessage':        'reactToMessage'
    'click .js-agentReaction':       'removeAgentReaction'

  elements:
    '.js-customerChatInput':         'input'
    '.js-status':                    'status'
    '.js-close':                     'closeButton'
    '.js-disconnect':                'disconnectButton'
    '.js-body':                      'body'
    '.js-meta':                      'meta'
    '.js-name':                      'metaName'
    '.js-scrollHolder':              'scrollHolder'
    '.js-scrollHint':                'scrollHint'
    '.js-metaForm':                  'metaForm'
    '.js-replyIndicator':            'replyIndicator'
    '.js-attachmentInput':           'attachmentInput'
    '.js-imageInput':                'imageInput'
    '.js-profile':                   'profile'

  sounds:
    message: new Audio('assets/sounds/chat_message.mp3')

  constructor: ->
    super

    @showTimeEveryXMinutes = 2
    @lastTimestamp
    @lastAddedType
    @isTyping = false
    @isAgentTyping = false
    @resetUnreadMessages()
    @scrolledToBottom = true
    @scrollSnapTolerance = 10 # pixels

    # Fase 6 -- `App.Chat` (koleksi asset topik chat) cuma pernah
    # dikirim ke sisi AGENT (lewat broadcast `chat_status_agent`),
    # tidak pernah ke sisi customer/user. Jendela chat follow-up milik
    # USER (App.MyChat, docs/DESIGN_CHAT_SELF_SERVICE.md Section 4.1)
    # jadi TIDAK PUNYA `App.Chat` untuk topik itu -- `find` bisa balik
    # `undefined`. Dipakai `?.` (bukan `.displayName()` langsung) supaya
    # tidak crash; `@session.name` (SELALU terisi untuk sesi follow-up,
    # lihat ChatSessionInit#run) tetap jadi sumber nama yang benar,
    # sama seperti sebelumnya untuk sesi widget anonim yang punya nama.
    @chat = App.Chat.find(@session.chat_id)
    @name = @chat?.displayName() || ''
    if @session && !_.isEmpty(@session.name)
      @name = @session.name

    # Fitur tambahan "Reply ke Pesan Spesifik" -- docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md
    # Section 5.3. null = tidak sedang membalas pesan mana pun.
    @replyTo = null

    # dipetakan by id supaya render kutipan (5.3) bisa mengambil isi
    # pesan asli tanpa perlu request/lookup terpisah -- konsisten
    # dengan mengapa backend menyertakan reply_to inline di broadcast
    # (lihat lib/sessions/event/chat_session_message.rb).
    @messagesById = {}

    # Redesign sisi agent (Tahap 2): `siska: true` (dari App.CustomerChat)
    # memakai bubble & area ketik gaya kit. App.MyChat tidak mengisinya,
    # jadi tetap memakai template lama.
    @pendingMessages = []
    @pendingCounter = 0

    @on('layout-change', @onLayoutChange)

    # Reaksi emoji customer pada pesan agent (server sudah menyiarkan
    # event ini ke agent sejak fitur reaksi widget; baru ditampilkan sekarang).
    @controllerBind('chat_session_reaction', (data) =>
      return if data.session_id isnt @session.session_id
      # G3: reactor 'agent' = reaksi agent ke pesan customer (echo sendiri /
      # agent lain); selain itu reaksi customer ke pesan agent
      if data.reactor is 'agent'
        @applyAgentReaction(data.message_id, data.reaction)
      else
        @setReaction(data.message_id, data.reaction)
    )

    @controllerBind('chat_session_typing', (data) =>
      return if data.session_id isnt @session.session_id
      return if data.self_written
      @showWritingLoader()
    )
    @controllerBind('chat_session_message', (data) =>
      return if data.session_id isnt @session.session_id
      if data.self_written
        @confirmOwnMessage(data.message)
        return
      @receiveMessage(data.message)
    )
    # Fase 5 -- Item No. 6 (Attachment). docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md
    # Section 5.2.2 poin 4. Broadcast BARU, terpisah dari
    # chat_session_message -- server sudah kirim ke KEDUA sisi (customer
    # & agent) tanpa mengecualikan pengirim, jadi cukup dengarkan di sini
    # untuk merender attachment yang di-upload SIAPA PUN di sesi ini,
    # tanpa perlu render optimis terpisah di sisi uploader.
    @controllerBind('chat_session_attachment', (data) =>
      return if data.session_id isnt @session.session_id
      isFocused = @input.is(':focus')
      sender = if data.message.created_by_id then 'agent' else 'customer'
      @addAttachmentMessage(data.message, sender, !isFocused)
    )
    @controllerBind('chat_session_notice', (data) =>
      return if data.session_id isnt @session.session_id
      return if data.self_written
      @addNoticeMessage(data.message)
    )
    @controllerBind('chat_session_left', (data) =>
      return if data.session_id isnt @session.session_id
      return if data.self_written
      if @siska
        @addSeparator(App.i18n.translatePlain('The customer left the conversation'))
      else
        @addStatusMessage("<strong>#{data.realname}</strong> left the conversation")
      @goOffline()
    )
    @controllerBind('chat_session_closed', (data) =>
      return if data.session_id isnt @session.session_id
      return if data.self_written
      if @siska
        text = if data.closed_by_agent
          App.i18n.translatePlain('Chat ended by %s', data.realname)
        else
          App.i18n.translatePlain('Chat ended by the customer')
        @addSeparator(text)
      else
        @addStatusMessage("<strong>#{data.realname}</strong> closed the conversation")
      @goOffline()
    )
    # Redesign sisi agent (Tahap 4) -- rating yang dikirim customer setelah
    # chat berakhir (server hanya menyiarkannya bila Setting
    # chat_agent_show_rating menyala, lihat chat_session_feedback_submit.rb).
    # G1 (docs/COMPARISON_WIDGET_VS_AGENT.md): customer sudah melihat pesan
    # agent. `reader: 'agent'` (tanda baca milik agent sendiri / agent lain)
    # diabaikan di sini.
    @controllerBind('chat_session_message_read', (data) =>
      return if data.session_id isnt @session.session_id
      return if data.reader isnt 'customer'
      @markAgentMessagesRead()
    )
    # Riwayat chat dari email yang sama (chat_session_history.rb)
    @controllerBind('chat_session_history', (data) =>
      return if data.session_id isnt @session.session_id
      @onHistoryPage(data)
    )
    @controllerBind('chat_session_feedback', (data) =>
      return if data.session_id isnt @session.session_id
      @addRatingCard(data)
    )
    @controllerBind('chat_focus', (data) =>
      return if data.session_id isnt @session.session_id
      @focus()
    )

  onLayoutChange: =>
    @scrollToBottom()

  toggleMeta: =>
    if @meta.hasClass('hidden')
      @showMeta()
    else
      @hideMeta()

  hideMeta: =>
    @body.removeClass('hidden')
    @meta.addClass('hidden')
    @sendMetaForm()

  showMeta: =>
    @body.addClass('hidden')
    @meta.removeClass('hidden')

  sendMetaForm: (e) =>
    if e
      e.preventDefault()
    params = @formParam(@metaForm)

    App.WebSocket.send(
      event:'chat_session_update'
      data:
        session_id: @session.session_id
        name: params.name
        tags: params.tags
    )

    if !_.isEmpty(params.name)
      @metaName.text(params.name)

  render: ->
    if @siska
      @html App.view('customer_chat/siska_window')(@siskaWindowParams())
      @el.addClass('siska-chat-window')
      @loadTicketNumber()
      @initHistory()
    else
      @html App.view('customer_chat/chat_window')(
        name: @name
        session: @session
        chats: App.Chat.all()
        previousSessions: @session.previous_sessions
      )

    @el.one('transitionend', @onTransitionend)
    @scrollHolder.on('scroll', @detectScrolledtoBottom)

    # Fase 5 -- Item No. 6, fitur tambahan enable/disable attachment
    # global+per-agent. Section 5.2.6. Sembunyikan tombol attach kalau
    # saklar global mati ATAU agent INI belum mengaktifkannya sendiri
    # lewat Chat Settings (default nonaktif per-agent) -- 2 lapis yang
    # SAMA dipakai backend (Chat::Session#attachment_enabled?), dicek
    # ulang di sini karena backend belum tentu punya `chat_session.user_id`
    # terisi saat window pertama kali dirender (baru terisi setelah
    # chat_session_start, yang justru memicu render ini).
    #
    # Fase 6 -- `ChatWindow` ini sekarang JUGA dipakai untuk jendela
    # milik USER LOGIN sendiri (docs/DESIGN_CHAT_SELF_SERVICE.md), bukan
    # cuma agent. `@Session.get('preferences')` selalu berarti "preferensi
    # SIAPA PUN yang sedang login melihat jendela ini" -- benar untuk
    # AGENT (memang preferensi PER-AGENT), tapi SALAH untuk user login
    # yang bukan agent (preferensi attachment mereka sendiri tidak ada
    # artinya sama sekali, chat_attachment_enabled hasilnya SELALU
    # tersembunyi walau agent yang menangani sesi ini sudah mengizinkan).
    # Dibedakan lewat perbandingan yang SAMA seperti backend menentukan
    # customer vs agent (created_by_id == chat_session.user_id, lihat
    # chat_session_message.rb) -- kalau user yang login SAAT INI adalah
    # agent yang di-assign ke sesi ini, pakai preferensi PRIBADI seperti
    # sebelumnya; kalau bukan (customer/self-service), pakai keputusan
    # yang SUDAH dihitung server per-sesi (`@session.attachment_enabled`,
    # sekarang selalu disertakan di `session_attributes`).
    isAssignedAgent = @Session.get('id') is @session.user_id
    attachmentEnabled = if isAssignedAgent
      preferences = @Session.get('preferences')
      App.Config.get('chat_attachment_enabled') && preferences?.chat?.attachment_enabled
    else
      !!@session.attachment_enabled
    @$('.js-attachButton, .js-imageButton').toggleClass('hidden', !attachmentEnabled)

    # force repaint
    @el.prop('offsetHeight')
    @el.addClass('is-open')

    # @addMessage 'Hello. My name is Roger, how can I help you?', 'agent'
    if @session

      # set chat to offline if state is already closed
      activeChat = true
      if @session.state is 'closed'
        activeChat = false

      if @session && @session.preferences && @session.preferences.url
        @addNoticeMessage(@session.preferences.url, undefined, activeChat, @session.created_at)

      if @session.messages
        for message in @session.messages
          sender = if message.created_by_id then 'agent' else 'customer'

          # Bug ditemukan (bukan cuma diduga) lewat pengecekan silang
          # thd bug yang SAMA PERSIS di widget customer
          # (public/assets/chat/, lihat docs/ACTIVITY_LOG_SISKA.md
          # entri 131): jendela chat ini JUGA cuma punya SATU jalur
          # render pesan riwayat (`@addMessage`, template TEKS biasa)
          # -- pesan attachment lama tampil sbg bubble berbunyi
          # literal "[attachment]" TANPA link unduh sama sekali begitu
          # agent reload halaman utk chat yang masih berjalan. Backend
          # (`Chat::Session.active_chats_by_user_id`) SUDAH menyertakan
          # `filename` sejak perbaikan widget customer (dipakai
          # method `enrich_message_attributes` yang SAMA utk KEDUA
          # sisi) -- di sini tinggal dipakai sbg penanda utk pilih
          # jalur render yang benar, belum pernah dipakai sama sekali
          # sebelumnya.
          if message.filename
            @addAttachmentMessage(message, sender, false)
          else
            @addMessage(message, sender, false, activeChat)

      # send init reply
      if activeChat && _.isEmpty(@session.messages)
        preferences = @Session.get('preferences')
        if preferences.chat && preferences.chat.phrase
          phrases = preferences.chat.phrase[@session.chat_id]
          if phrases
            phrasesArray = phrases.split(';')
            phrase = phrasesArray[_.random(0, phrasesArray.length-1)]
            @input.html(phrase)
            @sendMessage(1600)

      # set chat to offline if state is already closed
      if !activeChat
        @goOffline()

    # show text module UI
    new App.WidgetTextModule(
      el: @input
      data:
        user: App.Session.get()
        config: App.Config.all()
    )

    configureAttributesOutbound = [
      { name: 'name', display: __('Name'), tag: 'input', null: true, },
      { name: 'tags', display: __('Tags'), tag: 'tag', null: true, },
    ]
    new App.ControllerForm(
      el:    @$('.js-metaForm')
      model:
        configure_attributes: configureAttributesOutbound
        className: ''
      params: @session
    )

  focus: =>
    @input.trigger('focus')

  onTransitionend: (event) =>
    # chat window is done with animation - adjust scroll-bars
    # of sibling chat windows
    @trigger('layout-has-changed')

    if event.data and event.data.callback
      event.data.callback()

    @input.ce({
      mode:       'richtext'
      multiline:  true
      maxlength:  40000
      imageWidth: 'relative'
    })

  disconnect: =>
    if @siska
      @addSeparator(App.i18n.translatePlain('You ended the chat'))
    else
      @addStatusMessage('<strong>You</strong> left the conversation')
    App.WebSocket.send(
      event:'chat_session_close'
      data:
        session_id: @session.session_id
    )
    @goOffline()

  close: =>
    @sendMetaForm()
    @el.one('transitionend', { callback: @release }, @onTransitionend)
    @el.removeClass('is-open')
    if @removeCallback
      @removeCallback(@session.session_id)

  release: =>
    for uploadId of (@uploadPreviewUrls || {})
      @releaseUploadPreview(uploadId)
    @trigger('closed')
    @el.remove()

  clearUnread: (e) =>
    if @siska && e?.type is 'click'
      target = $(e.target)
      @closeMenus() if !target.closest('.js-msgMenu').length
      @closeEmojiPicker() if !target.closest('.siska-composer-emoji').length
    hadUnread = @unreadMessagesCounter > 0
    @$('.chat-message--new').removeClass('chat-message--new')
    @updateModified(false)
    @resetUnreadMessages()

    # Atas permintaan user (penanda "sudah dibaca" ala WhatsApp di
    # widget customer, mockup `Messages.dc.html`) -- SEBELUMNYA method
    # ini (dipicu fokus ke kotak ketik ATAU klik di mana pun di jendela
    # chat, lihat `events` di atas) MURNI efek visual lokal (badge
    # unread milik agent sendiri), TIDAK PERNAH mengirim sinyal apa pun
    # ke customer. Sekarang jadi titik pemicu utk memberi tahu server
    # "agent sudah melihat pesan customer" -- server yang menentukan
    # pesan mana saja yang perlu ditandai (lihat
    # `chat_session_message_read.rb`), di sini cukup kirim event kalau
    # MEMANG ada sesuatu yang belum terbaca (hindari kirim event
    # percuma tiap klik di jendela chat yang tidak ada perubahan apa
    # pun).
    if hadUnread
      App.WebSocket.send(
        event: 'chat_session_message_read'
        data:
          session_id: @session.session_id
      )

  onKeydown: (event) =>
    TABKEY = 9
    ENTERKEY = 13

    if event.keyCode isnt TABKEY && event.keyCode isnt ENTERKEY

      # send typing start event only every 1.4 seconds
      return if @isAgentTyping && @isAgentTyping > new Date(new Date().getTime() - 1400)
      @isAgentTyping = new Date()
      App.WebSocket.send(
        event:'chat_session_typing'
        data:
          session_id: @session.session_id
      )

    switch event.keyCode
      when TABKEY
        allChatInputs = @input.not('[disabled="disabled"]')
        chatCount = allChatInputs.length
        index = allChatInputs.index(@input)

        if chatCount > 1
          switch index
            when chatCount-1
              if !event.shiftKey
                # State: tab without shift on last input
                # Jump to first input
                event.preventDefault()
                allChatInputs.eq(0).focus()
            when 0
              if event.shiftKey
                # State: tab with shift on first input
                # Jump to last input
                event.preventDefault()
                allChatInputs.eq(chatCount-1).focus()

      when ENTERKEY
        if !event.shiftKey && !event.altKey && !event.ctrlKey && !event.metaKey
          event.preventDefault()
          @sendMessage()

  sendMessage: (delay) =>
    content = @input.html()
    return if !content
    return if @el.hasClass('is-offline')

    # Fitur tambahan "Reply ke Pesan Spesifik" -- Section 5.3.
    replyToId = @replyTo?.id

    send = =>
      data =
        content: content
        session_id: @session.session_id
      data.reply_to_id = replyToId if replyToId
      App.WebSocket.send(
        event:'chat_session_message'
        data: data
      )
    if !delay
      send()
    else
      # show key enter and send phrase
      App.WebSocket.send(
        event:'chat_session_typing'
        data:
          session_id: @session.session_id
      )
      @delay(send, delay)

    @hideMeta() if !@siska
    @pendingCounter += 1
    pendingId = "p#{@pendingCounter}"
    @pendingMessages.push(pendingId)
    @addMessage({ content: content, reply_to: @replyTo, pendingId: pendingId }, 'agent')
    @input.html('')
    @cancelReply()

  updateModified: (state) =>
    @status.toggleClass('is-modified', state)

  receiveMessage: (message) =>
    isFocused = @input.is(':focus')

    @removeWritingLoader()
    @addMessage(message, 'customer', !isFocused)

    if !isFocused
      @addUnreadMessages()
      @updateModified(true)
      @sounds.message.play()
      @notifyDesktop(
        title: @name
        body: App.Utils.html2text(message.content)
        url: '#customer_chat'
        callback: =>
          App.Event.trigger('chat_focus', { session_id: @session.session_id })
      )

  unreadMessages: =>
    @unreadMessagesCounter

  addUnreadMessages: =>
    if @messageCallback
      @messageCallback(@session.session_id)
    @unreadMessagesCounter += 1

  resetUnreadMessages: =>
    if @messageCallback
      @messageCallback(@session.session_id)
    @unreadMessagesCounter = 0

  # `message` bisa berupa string polos (dipakai `sendMessage` untuk
  # render optimis SEBELUM ada balasan sungguhan dari server, belum
  # punya `id`) atau object `{id, content, reply_to}` (dari
  # `chat_session_message`/replay histori sesi) -- fitur tambahan
  # "Reply ke Pesan Spesifik", Section 5.3.
  addMessage: (message, sender, isNew, useMaybeAddTimestamp = true) =>
    @maybeAddTimestamp(message?.created_at) if useMaybeAddTimestamp

    @lastAddedType = sender

    if _.isString(message)
      message = { content: message }

    @setLastMessage(
      text: App.Utils.html2text(message.content || '').substr(0, 120)
      time: message.created_at
      sender: sender
    )

    @messagesById[message.id] = message if message.id

    if @siska
      @body.append App.view('customer_chat/siska_message')(@siskaMessageParams(message, sender, isNew, 'text'))
    else
      @body.append App.view('customer_chat/chat_message')(
        message: message.content
        messageId: message.id
        replyTo: message.reply_to
        sender: sender
        isNew: isNew
        timestamp: Date.now()
      )

    @scrollToBottom(showHint: true)

  # Redesign sisi agent (Tahap 3) -- parameter header percakapan & panel
  # "Profile & history" (template siska_window).
  siskaWindowParams: =>
    session = @session
    prefs = session.preferences || {}
    started = App.SiskaFormat.time(session.created_at)
    details = []
    details.push(label: __('Category'), value: session.category) if session.category
    details.push(label: __('Session'), value: _.compact(["##{session.id}", (App.i18n.translatePlain('started %s', started) if started)]).join(' · '))
    details.push(label: __('Ticket'), value: '…', ticketId: session.ticket_id) if session.ticket_id
    if prefs.url
      page = String(prefs.url).split('?')[0].replace(/\/+$/, '').split('/').pop() || prefs.url
      details.push(label: __('Page'), value: page, title: prefs.url)
    geo = _.compact([prefs.geo_ip?.city_name, prefs.geo_ip?.country_name]).join(', ')
    details.push(label: __('Location'), value: geo) if geo
    details.push(label: __('IP'), value: prefs.remote_ip) if prefs.remote_ip

    previous = for entry in (session.previous_sessions || [])
      _.extend({}, entry, dateLabel: App.i18n.translateTimestamp(entry.created_at))

    name:             @name
    session:          session
    initials:         App.SiskaFormat.initials(@name)
    subline:          _.compact([session.email, session.category, App.i18n.translatePlain('session #%s', session.id)]).join(' · ')
    transferChats:    ({ id: chat.id, name: chat.displayName() } for chat in App.Chat.all() when chat.id isnt session.chat_id)
    details:          details
    previousSessions: previous
    showRating:       App.Config.get('chat_agent_show_rating') isnt false

  # Pemisah "Chat ended by … · HH:MM" (teks di-escape oleh template).
  addSeparator: (text) =>
    @body.append App.view('customer_chat/siska_separator')(
      text: text
      time: App.SiskaFormat.time(new Date().toISOString())
    )
    @scrollToBottom()

  addRatingCard: (data) =>
    return if !@siska
    return if App.Config.get('chat_agent_show_rating') is false
    score = parseInt(data.score, 10)
    return if !(score >= 1 && score <= 5)
    @$('.siska-rating-card').remove()
    @body.append App.view('customer_chat/siska_rating_card')(
      score: score
      comment: data.comment
    )
    @scrollToBottom()

  # --- Riwayat chat di jendela percakapan (gaya WhatsApp) -------------------
  # Keputusan user: semua sesi lain dari email yang sama; 10 pesan riwayat per
  # halaman (percakapan saat ini tidak dihitung); halaman berikutnya dimuat
  # saat digulir mendekati puncak. Semua pesan riwayat yang sudah dimuat
  # disimpan lalu thread dirender ulang utuh, supaya pil tanggal, kapsul sesi
  # & penutup sesi selalu benar walau satu sesi terpotong di antara halaman.
  initHistory: =>
    @history = { messages: [], sessions: {}, hasMore: false, loading: false, started: false }
    return if !@session.email
    @historyEl = $('<div class="siska-thread js-historyThread"></div>')
    @body.prepend(@historyEl)
    @scrollHolder.on('scroll', @onHistoryScroll)
    @requestHistory()

  requestHistory: =>
    return if @history.loading
    @history.loading = true
    @history.pendingBefore = @history.messages[0]?.id
    @renderHistory() if @history.started
    App.WebSocket.send(
      event: 'chat_session_history'
      data:
        session_id: @session.session_id
        before_id:  @history.pendingBefore
    )

  loadMoreHistory: (e) =>
    e?.preventDefault()
    return if !@history?.hasMore
    @requestHistory()

  onHistoryScroll: =>
    return if !@history?.hasMore || @history.loading
    @requestHistory() if @scrollHolder.scrollTop() < 80

  onHistoryPage: (data) =>
    # balasan basi (halaman lain sudah diminta) diabaikan
    return if (data.before_id || undefined) isnt (@history.pendingBefore || undefined)
    first = !@history.started
    @history.started = true
    @history.loading = false
    @history.hasMore = !!data.has_more
    _.extend(@history.sessions, data.sessions || {})
    known = _.indexBy(@history.messages, 'id')
    for message in (data.messages || []) when !known[message.id]
      @history.messages.push(message)
    @history.messages = _.sortBy(@history.messages, 'id')

    # jaga posisi: saat dibuka tetap di bawah, saat paging tetap di pesan
    # yang sedang dilihat (jarak dari bawah tidak berubah)
    holder = @scrollHolder.get(0)
    fromBottom = holder.scrollHeight - holder.scrollTop
    @renderHistory()
    if first
      @scrollToBottom()
    else
      holder.scrollTop = holder.scrollHeight - fromBottom

  historySessionKey: (message) ->
    String(message.chat_session_id)

  renderHistory: =>
    return if !@historyEl
    items = []
    lastDay = null
    lastSession = null
    messages = @history.messages
    for message, index in messages
      session = @history.sessions[@historySessionKey(message)] || {}
      if session isnt lastSession
        @pushHistoryEnd(items, lastSession, messages[index - 1]) if lastSession
      day = new Date(message.created_at).toDateString()
      if day isnt lastDay
        items.push(type: 'date', label: App.SiskaFormat.dayLabel(message.created_at))
        lastDay = day
      if session isnt lastSession
        items.push(@historySessionItem(session))
        lastSession = session
      items.push(type: 'message', html: @historyMessageHtml(message, session))
    @pushHistoryEnd(items, lastSession, messages[messages.length - 1]) if lastSession

    state = if @history.loading then 'loading' else if @history.hasMore then 'ready' else if items.length then 'end' else null
    @historyEl.html App.view('customer_chat/siska_history')(
      items:     items
      state:     state
      pageSize:  10
      email:     @session.email
      currentId: @session.id
    )
    @historyEl.find('.js-siskaImage img').one('load', => @scrollToBottom() if @scrolledToBottom)

  historySessionItem: (session) ->
    started = App.SiskaFormat.clock(session.created_at)
    ended = App.SiskaFormat.clock(session.ended_at)
    range = if started && ended && started isnt ended then "#{started}–#{ended}" else started
    type:         'session'
    id:           session.id
    meta:         _.compact([session.agent_name, range]).join(' · ')
    ticketId:     session.ticket_id
    ticketNumber: session.ticket_number

  # penutup sesi hanya bila pesan terakhir sesi itu memang sudah dimuat
  pushHistoryEnd: (items, session, lastMessage) ->
    return if !session || !lastMessage
    return if session.state isnt 'closed'
    return if session.last_message_id && lastMessage.id isnt session.last_message_id
    text = switch session.closed_by
      when 'agent' then App.i18n.translatePlain('Chat ended by the agent')
      when 'customer' then App.i18n.translatePlain('Chat ended by the customer')
      else App.i18n.translatePlain('Chat ended')
    time = App.SiskaFormat.clock(session.ended_at)
    showRating = App.Config.get('chat_agent_show_rating') isnt false
    items.push(
      type:  'end'
      text:  _.compact([text, time]).join(' · ')
      score: if showRating then session.csat_score else undefined
    )

  historyMessageHtml: (message, session) =>
    sender = if message.is_from_agent then 'agent' else 'customer'
    message.history_session_id = session.session_id
    @messagesById[message.id] = message
    kind = if message.filename then (if App.SiskaFormat.isImage(message) then 'image' else 'file') else 'text'
    params = @siskaMessageParams(message, sender, false, kind, session.session_id)
    params.history = true
    params.time = App.SiskaFormat.clock(message.created_at)
    if sender is 'agent'
      params.author = if session.agent_id && session.agent_id is App.Session.get('id') then App.i18n.translatePlain('You') else (session.agent_name || App.i18n.translatePlain('Agent'))
    else if session.name
      params.author = session.name
      params.initials = App.SiskaFormat.initials(session.name)
    App.view('customer_chat/siska_message')(params)

  # Nomor tiket (bukan id) utk baris "Ticket" di panel profil.
  loadTicketNumber: =>
    ticketId = @session.ticket_id
    return if !ticketId
    show = (ticket) =>
      @$('.js-ticketNumber').text("##{ticket.number}") if ticket?.number
    if App.Ticket.exists(ticketId)
      show(App.Ticket.find(ticketId))
    else
      App.Ticket.full(ticketId, show)

  toggleProfile: (e) =>
    e?.preventDefault()
    open = @profile.hasClass('hidden')
    @profile.toggleClass('hidden', !open)
    @el.toggleClass('has-profile', open)
    @$('.siska-conv-actions .js-toggleProfile').attr('aria-expanded', String(open)).toggleClass('is-active', open)
    if open
      @profile.find('.js-toggleProfile').trigger('focus')
    else
      # simpan perubahan nama/tag, sama seperti saat panel meta lama ditutup
      @sendMetaForm()
      @$('.siska-conv-actions .js-toggleProfile').trigger('focus')
    @trigger('layout-changed')

  # Parameter template `siska_message`. `pendingId` dipakai untuk pesan
  # agent yang dirender optimis sebelum server membalas dengan id-nya
  # (lihat `confirmOwnMessage`).
  siskaMessageParams: (message, sender, isNew, kind, sessionKey = @session.session_id) =>
    isAgent = sender is 'agent'
    params =
      sender:        sender
      isNew:         isNew
      kind:          kind
      messageId:     message.id
      pendingId:     message.pendingId
      author:        if isAgent then App.i18n.translatePlain('You') else (@name || App.i18n.translatePlain('Customer'))
      initials:      App.SiskaFormat.initials(@name)
      time:          App.SiskaFormat.time(message.created_at || new Date().toISOString())
      html:          message.content
      replyTo:       if message.reply_to then App.Utils.html2text(message.reply_to.content || '').substr(0, 80) else undefined
      isRead:        !!message.read_at
      reaction:      message.customer_reaction
      reactionLabel: App.SiskaFormat.REACTIONS[message.customer_reaction] || message.customer_reaction
      agentReaction: message.agent_reaction
      agentReactionLabel: App.SiskaFormat.REACTIONS[message.agent_reaction] || message.agent_reaction
      reactions:     ({ emoji: emoji, label: label } for emoji, label of App.SiskaFormat.REACTIONS)
    if kind isnt 'text'
      base = "#{@apiPath}/chat_sessions/#{sessionKey}/attachments/#{message.id}"
      icon = if kind is 'image' then 'file-image' else App.SiskaIcon.forFile(message.filename)
      params.file =
        name:        message.filename
        url:         base
        previewUrl:  "#{base}?view=preview"
        downloadUrl: "#{base}?disposition=attachment"
        meta:        App.SiskaFormat.fileMeta(message.filename, message.size)
        icon:        icon
        tone:        App.SiskaIcon.fileTone(message.filename)
    params

  # Echo `self_written` dari server membawa id pesan agent sendiri. Id itu
  # ditempel ke bubble optimis tertua yang masih menunggu, supaya pesan
  # agent bisa di-reply & menerima reaksi customer.
  confirmOwnMessage: (message) =>
    return if !message?.id
    pendingId = @pendingMessages.shift()
    return if !pendingId
    @messagesById[message.id] = message
    el = @body.find("[data-pending-id='#{pendingId}']")
    el.attr('data-message-id', message.id).removeAttr('data-pending-id')
    el.find('.siska-msg-time').text(App.SiskaFormat.time(message.created_at))

  # Semua pesan agent di percakapan saat ini jadi "dibaca" (server menandai
  # secara bulk). Pesan riwayat ada di dalam .js-historyThread, bukan anak
  # langsung body, jadi tidak ikut.
  markAgentMessagesRead: =>
    return if !@siska
    readAt = new Date().toISOString()
    for id, message of @messagesById when message.created_by_id && !message.history_session_id
      message.read_at ||= readAt
    label = App.i18n.translateInline('Read by customer')
    @body.children('.siska-msg--agent').find('.js-msgStatus').not('.is-read')
      .addClass('is-read').attr('aria-label', label).attr('title', label)

  # G3: agent memberi / mengganti / menghapus reaksi pada pesan customer.
  # Klik emoji yang sama dgn reaksi aktif = hapus (pola widget). UI diperbarui
  # langsung (optimis); echo server menegaskan nilai yang sama.
  reactToMessage: (e) =>
    e.preventDefault()
    button = $(e.currentTarget)
    messageId = button.closest('[data-message-id]').attr('data-message-id')
    return if !messageId
    emoji = button.attr('data-reaction')
    current = @messagesById[messageId]?.agent_reaction || null
    next = if emoji && emoji isnt current then emoji else null
    @closeMenus(true)
    @sendAgentReaction(messageId, next)

  removeAgentReaction: (e) =>
    e.preventDefault()
    e.stopPropagation()
    messageId = $(e.currentTarget).closest('[data-message-id]').attr('data-message-id')
    @sendAgentReaction(messageId, null) if messageId

  sendAgentReaction: (messageId, reaction) =>
    @applyAgentReaction(messageId, reaction)
    App.WebSocket.send(
      event: 'chat_session_reaction'
      data:
        session_id: @session.session_id
        message_id: parseInt(messageId, 10)
        reaction:   reaction
    )

  applyAgentReaction: (messageId, reaction) =>
    message = @messagesById[messageId]
    message.agent_reaction = reaction if message
    el = @body.find("[data-message-id='#{messageId}']")
    return if !el.length
    chip = el.find('.js-agentReaction')
    if reaction
      label = App.SiskaFormat.REACTIONS[reaction] || reaction
      chip.text(reaction).attr('aria-label', App.i18n.translatePlain('Your reaction: %s. Remove', App.i18n.translatePlain(label))).removeClass('hidden')
    else
      chip.text('').addClass('hidden')
    el.find('.js-reactMessage').each (index, item) ->
      active = $(item).attr('data-reaction') is reaction
      $(item).toggleClass('is-active', active).attr('aria-checked', String(active))

  setReaction: (messageId, reaction) =>
    message = @messagesById[messageId]
    message.customer_reaction = reaction if message
    chip = @body.find("[data-message-id='#{messageId}'] .js-reaction")
    return if !chip.length
    if reaction
      label = App.SiskaFormat.REACTIONS[reaction] || reaction
      chip.text(reaction).attr('aria-label', App.i18n.translateInline('Customer reaction: %s', label)).removeClass('hidden')
    else
      chip.text('').removeAttr('aria-label').addClass('hidden')

  # G2 (docs/COMPARISON_WIDGET_VS_AGENT.md): salin teks pesan, pola sama dgn
  # widget (`copyMessage`): teks bubble tanpa kutipan reply, jam, atau chip.
  copyMessage: (e) =>
    e.preventDefault()
    toggle = $(e.currentTarget).closest('.js-msgMenu').find('.js-msgMenuToggle')
    text = App.Utils.html2text($(e.currentTarget).closest('.siska-msg').find('.siska-msg-text').html() || '').trim()
    @closeMenus()
    toggle.trigger('focus')
    return if !text
    done = => @notify(type: 'success', msg: __('Copied'), timeout: 2000)
    failed = => @notify(type: 'error', msg: __('The text could not be copied.'))
    if navigator.clipboard?.writeText
      navigator.clipboard.writeText(text).then(done, => @copyTextFallback(text, done, failed))
    else
      @copyTextFallback(text, done, failed)

  # Fallback untuk konteks tanpa Clipboard API (mis. http non-aman).
  copyTextFallback: (text, done, failed) ->
    area = $('<textarea readonly></textarea>').val(text).css(position: 'fixed', top: 0, left: 0, opacity: 0)
    $('body').append(area)
    area.get(0).select()
    copied = false
    try
      copied = document.execCommand('copy')
    area.remove()
    if copied then done() else failed()

  toggleMessageMenu: (e) =>
    e.preventDefault()
    e.stopPropagation()
    toggle = $(e.currentTarget)
    menu = toggle.siblings('[role=menu]')
    open = menu.hasClass('hidden')
    @closeMenus()
    return if !open
    menu.removeClass('hidden')
    toggle.attr('aria-expanded', 'true').closest('.siska-msg').addClass('is-menu-open')
    @placeMessageMenu(menu)
    menu.find('[role=menuitem]').first().trigger('focus')

  # Menu dibuka di dalam area pesan yang bisa digulir (overflow), jadi pada
  # pesan paling bawah menu yang membuka ke bawah terpotong. Buka ke atas bila
  # ruang di bawah tidak cukup; bila di atas pun tidak cukup, tetap ke bawah &
  # gulir seperlunya supaya seluruh menu terlihat.
  placeMessageMenu: (menu) =>
    menu.removeClass('is-up')
    holder = menu.closest('.js-scrollHolder').get(0)
    return if !holder
    bounds = holder.getBoundingClientRect()
    rect = menu.get(0).getBoundingClientRect()
    return if rect.bottom <= bounds.bottom
    menu.addClass('is-up')
    rect = menu.get(0).getBoundingClientRect()
    return if rect.top >= bounds.top
    menu.removeClass('is-up')
    menu.get(0).scrollIntoView?(block: 'nearest')

  closeMenus: (restoreFocus = false) =>
    openToggle = @$('.js-msgMenuToggle[aria-expanded=true]')
    @$('.js-msgMenu [role=menu]').addClass('hidden').removeClass('is-up')
    @$('.js-msgMenuToggle').attr('aria-expanded', 'false')
    @$('.siska-msg.is-menu-open').removeClass('is-menu-open')
    openToggle.trigger('focus') if restoreFocus && openToggle.length

  toggleEmojiPicker: (e) =>
    e.preventDefault()
    e.stopPropagation()
    picker = @$('.js-emojiPicker')
    open = picker.hasClass('hidden')
    @closeEmojiPicker()
    return if !open
    # simpan posisi kursor supaya emoji disisipkan di tempat yang benar
    selection = window.getSelection()
    if selection.rangeCount && @input.get(0).contains(selection.anchorNode)
      @emojiRange = selection.getRangeAt(0).cloneRange()
    picker.removeClass('hidden')
    @$('.js-emojiToggle').attr('aria-expanded', 'true').addClass('is-active')
    picker.find('.js-emojiItem').first().trigger('focus')

  closeEmojiPicker: =>
    @$('.js-emojiPicker').addClass('hidden')
    @$('.js-emojiToggle').attr('aria-expanded', 'false').removeClass('is-active')

  insertEmoji: (e) =>
    e.preventDefault()
    emoji = $(e.currentTarget).attr('data-emoji')
    @closeEmojiPicker()
    @input.trigger('focus')
    if @emojiRange
      selection = window.getSelection()
      selection.removeAllRanges()
      selection.addRange(@emojiRange)
      @emojiRange = null
    document.execCommand('insertText', false, emoji)

  # Esc menutup menu/pemilih emoji; klik di luar menutup semuanya.
  onWindowKeydown: (e) =>
    return if e.keyCode isnt 27
    if @$('.js-msgMenuToggle[aria-expanded=true]').length
      @closeMenus(true)
      e.stopPropagation()
    else if !@$('.js-emojiPicker').hasClass('hidden')
      @closeEmojiPicker()
      @$('.js-emojiToggle').trigger('focus')
      e.stopPropagation()

  openSiskaImage: (e) =>
    e.preventDefault()
    messageId = $(e.currentTarget).closest('[data-message-id]').attr('data-message-id')
    message = @messagesById[messageId]
    return if !message
    base = "#{@apiPath}/chat_sessions/#{message.history_session_id || @session.session_id}/attachments/#{message.id}"
    sender = if message.history_session_id then null else (if message.created_by_id then App.i18n.translatePlain('You') else @name)
    new App.SiskaImageViewer(
      src:         base
      name:        message.filename
      meta:        _.compact([sender, App.SiskaFormat.time(message.created_at), App.SiskaFormat.fileMeta(message.filename, message.size)]).join(' · ')
      downloadUrl: "#{base}?disposition=attachment"
      returnFocus: e.currentTarget
    )

  # Fitur tambahan "Reply ke Pesan Spesifik (Seperti WhatsApp)" --
  # docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.3.
  startReply: (e) =>
    e.preventDefault()
    messageId = $(e.currentTarget).closest('[data-message-id]').attr('data-message-id')
    return if !messageId
    message = @messagesById[messageId]
    return if !message
    @closeMenus()
    content = message.content
    content = message.filename if message.filename

    @replyTo = { id: messageId, content: content }
    @renderReplyIndicator()
    @input.trigger('focus')

  cancelReply: (e) =>
    e?.preventDefault()
    @replyTo = null
    @renderReplyIndicator()

  renderReplyIndicator: =>
    return if !@replyIndicator.length

    if !@replyTo
      @replyIndicator.addClass('hidden').empty()
      return

    snippet = App.Utils.html2text(@replyTo.content)
    snippet = snippet.substr(0, 80)
    @replyIndicator.removeClass('hidden').html App.view('customer_chat/chat_reply_indicator')(
      snippet: snippet
    )

  # Fitur tambahan "Riwayat Chat Sebelumnya dari Customer yang Sama" --
  # docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.1.7.
  openPreviousTicket: (e) =>
    e.preventDefault()
    ticketId = $(e.currentTarget).data('ticket-id')
    return if !ticketId
    @navigate "#ticket/zoom/#{ticketId}"

  # Fase 5 -- Item No. 6 (Attachment). Section 5.2.3.
  triggerAttachmentInput: (e) =>
    e.preventDefault()
    @attachmentInput.trigger('click')

  triggerImageInput: (e) =>
    e.preventDefault()
    @imageInput.trigger('click')

  uploadAttachment: (e) =>
    input = $(e.currentTarget)
    file = e.currentTarget.files?[0]
    return if !file

    formData = new FormData()
    formData.append('File', file)
    # Sama dgn widget ("Opsi B", ikuti WhatsApp): lewat tombol lampiran
    # selalu jadi kartu file, gambar hanya lewat tombol kirim gambar.
    asFile = @siska && input.is(@attachmentInput)
    formData.append('display', 'file') if asFile

    # B1 (docs/INVENTORY_AGENT_CHAT.md): id unik per upload. Dulu id tetap
    # 'chat-attachment-upload' -- App.Ajax membatalkan request lama ber-id
    # sama secara global, jadi upload di satu jendela chat membatalkan upload
    # yang masih berjalan di jendela lain.
    @uploadSeq = (@uploadSeq || 0) + 1
    uploadId = "#{@session.session_id}-#{@uploadSeq}"
    kind = if !asFile && _.contains(App.SiskaFormat.IMAGE_TYPES, file.type) then 'image' else 'file'
    @addUploadPlaceholder(uploadId, file, kind) if @siska

    @ajax(
      id:          "chat-attachment-upload-#{uploadId}"
      type:        'POST'
      url:         "#{@apiPath}/chat_sessions/#{@session.session_id}/attachments"
      data:        formData
      processData: false
      contentType: false
      cache:       false
      # G6: progres unggah dalam persen (pola sama dgn widget)
      xhr:         =>
        request = new window.XMLHttpRequest()
        if @siska
          request.upload.addEventListener('progress', (event) =>
            return if !event.lengthComputable
            @updateUploadPlaceholder(uploadId, Math.round(event.loaded / event.total * 100))
          )
        request
      success:     =>
        @updateUploadPlaceholder(uploadId, 100)
        # rendering dilakukan lewat broadcast chat_session_attachment
        # (dikirim server ke KEDUA sisi termasuk pengunggah sendiri),
        # bukan di sini, supaya tidak dobel & konsisten dengan cara
        # pesan teks sendiri direfleksikan balik. Placeholder diganti di
        # posisinya oleh `addAttachmentMessage`.
      error: (xhr) =>
        @removeUploadPlaceholder(uploadId)
        message = xhr.responseJSON?.error || __('The attachment could not be uploaded.')
        new App.ControllerConfirm(
          head:         __('Attachment')
          message:      message
          buttonCancel: false
          buttonSubmit: __('OK')
        )
    )

    input.val('')

  # --- G6: placeholder unggah (varian siska) -------------------------------
  addUploadPlaceholder: (uploadId, file, kind) =>
    @uploadPreviewUrls ||= {}
    previewUrl = undefined
    if kind is 'image' && window.URL?.createObjectURL
      previewUrl = @uploadPreviewUrls[uploadId] = window.URL.createObjectURL(file)
    @maybeAddTimestamp()
    @lastAddedType = 'agent'
    @body.append App.view('customer_chat/siska_upload')(
      uploadId:   uploadId
      kind:       kind
      previewUrl: previewUrl
      filename:   file.name
      author:     App.i18n.translatePlain('You')
      icon:       App.SiskaIcon.forFile(file.name)
      tone:       App.SiskaIcon.fileTone(file.name)
    )
    @scrollToBottom(showHint: true)

  updateUploadPlaceholder: (uploadId, percent) =>
    el = @body.find(".js-upload[data-upload-id='#{uploadId}']")
    return if !el.length
    label = if percent >= 100 then App.i18n.translatePlain('Processing…') else "#{App.i18n.translatePlain('Uploading…')} #{percent}%"
    el.find('.js-uploadLabel').text(label)
    el.find('.js-uploadBar').css('width', "#{percent}%").attr('aria-valuenow', percent)

  releaseUploadPreview: (uploadId) =>
    url = @uploadPreviewUrls?[uploadId]
    return if !url
    window.URL.revokeObjectURL(url)
    delete @uploadPreviewUrls[uploadId]

  removeUploadPlaceholder: (uploadId) =>
    @body.find(".js-upload[data-upload-id='#{uploadId}']").remove()
    @releaseUploadPreview(uploadId)

  addAttachmentMessage: (message, sender, isNew) =>
    @maybeAddTimestamp(message?.created_at)
    @lastAddedType = sender

    @setLastMessage(
      text: message.filename
      time: message.created_at
      sender: sender
      icon: if /\.(jpe?g|png|gif|webp|bmp|heic)$/i.test(message.filename || '') then 'image' else 'paperclip'
    )

    if @siska
      @messagesById[message.id] = message if message.id
      kind = if App.SiskaFormat.isImage(message) then 'image' else 'file'
      html = App.view('customer_chat/siska_message')(@siskaMessageParams(message, sender, isNew, kind))
      # lampiran milik sendiri menggantikan placeholder unggah tertua dgn jenis
      # yang sama DI POSISINYA (pola widget), bukan ditambah di bawah
      placeholder = if sender is 'agent' then @body.find(".js-upload[data-upload-kind='#{kind}']").first() else $()
      if placeholder.length
        @releaseUploadPreview(placeholder.attr('data-upload-id'))
        placeholder.before(html).remove()
      else
        @body.append html
      # tinggi gambar baru diketahui setelah dimuat
      @body.find('.js-siskaImage img').last().one('load', => @scrollToBottom())
    else
      @body.append App.view('customer_chat/chat_attachment_message')(
        sender:      sender
        isNew:       isNew
        filename:    message.filename
        url:         "#{@apiPath}/chat_sessions/#{@session.session_id}/attachments/#{message.id}"
        timestamp:   Date.now()
      )

    @scrollToBottom(showHint: true)

  showWritingLoader: =>
    if !@isTyping
      @isTyping = true
      @maybeAddTimestamp()
      if @siska
        @body.append App.view('customer_chat/siska_loader')(
          name: @name || App.i18n.translatePlain('Customer')
          initials: App.SiskaFormat.initials(@name)
        )
      else
        @body.append App.view('customer_chat/chat_loader')()
      @scrollToBottom()

    # clear old delay, set new
    @delay(@removeWritingLoader, 2000, 'typing')

  removeWritingLoader: =>
    @isTyping = false
    @$('.js-loader').remove()

  # Redesign sisi agent (Tahap 1) -- cuplikan pesan terakhir untuk kartu
  # daftar di App.CustomerChat. `changeCallback` opsional: App.MyChat (yang
  # juga memakai ChatWindow) tidak mengisinya, jadi perilakunya tidak berubah.
  setLastMessage: (last) =>
    last.time ||= new Date().toISOString()
    @lastMessage = last
    @changeCallback?(@session.session_id)

  goOffline: =>
    @isOffline = true
    @changeCallback?(@session.session_id)
    if @siska
      @$('.js-onlineOnly').addClass('hidden')
      @$('.js-profileState').addClass('is-ended').contents().last().replaceWith(App.i18n.translatePlain('Ended'))
    @status.attr('data-status', 'offline')
    @disconnectButton.addClass 'is-hidden'
    @closeButton.removeClass 'is-hidden'
    @el.addClass('is-offline')
    @input.attr('disabled', true)

    # add footer with create ticket button -- tombol berubah jadi
    # "Open Ticket" kalau tiket sudah otomatis dibuat sejak awal
    # (Fase 5, Item No. 5, Section 5.1.5), supaya tidak duplikat
    # dengan tiket yang sudah ada.
    if @siska
      # composer diganti bilah "percakapan telah berakhir" (mockup artboard 5)
      @$('.siska-composer, .js-replyIndicator').addClass('hidden')
      @$('.js-endedBar').removeClass('hidden')
      return

    @body.append App.view('customer_chat/chat_footer')(
      ticketId: @session.ticket_id
    )

  # B2 (docs/INVENTORY_AGENT_CHAT.md): `at` = waktu pesan yang dirender.
  # Dulu selalu Date.now(), jadi saat jendela dirender ulang (reload) pil
  # menampilkan jam render, bukan jam pesan. Tanpa `at` = pesan baru (now).
  maybeAddTimestamp: (at) ->
    date = if at then new Date(at) else new Date()
    date = new Date() if isNaN(date.getTime())
    timestamp = date.getTime()

    if !@lastTimestamp or timestamp - @lastTimestamp > @showTimeEveryXMinutes * 60000
      label = if date.toDateString() is new Date().toDateString()
        App.i18n.translateInline('today')
      else
        App.i18n.translateDate(date.toISOString())
      time = date.toTimeString().substr(0,5)
      if @lastAddedType is 'timestamp'
        # update last time
        @updateLastTimestamp label, time
        @lastTimestamp = timestamp
      else
        @addTimestamp label, time
        @lastTimestamp = timestamp
        @lastAddedType = 'timestamp'

  addTimestamp: (label, time) =>
    @body.append App.view('customer_chat/chat_timestamp')(
      label: label
      time: time
    )

  updateLastTimestamp: (label, time) ->
    @body
      .find('.js-timestamp')
      .last()
      .replaceWith App.view('customer_chat/chat_timestamp')(
        label: label
        time: time
      )

  addStatusMessage: (message, args, useMaybeAddTimestamp = true) ->
    @maybeAddTimestamp() if useMaybeAddTimestamp

    @body.append App.view('customer_chat/chat_status_message')(
      message: message
      args: args
    )

    @scrollToBottom()

  addNoticeMessage: (message, args, useMaybeAddTimestamp = true, at) ->
    # B3: notice yang sama persis dgn notice terakhir tidak diulang (server
    # mengirim URL halaman customer tiap reload / reconnect widget). URL yang
    # berbeda (customer pindah halaman) tetap tampil.
    return if message? && message is @lastNoticeMessage
    @lastNoticeMessage = message
    @maybeAddTimestamp(at) if useMaybeAddTimestamp

    @body.append App.view('customer_chat/chat_notice_message')(
      message: message
      args: args
    )

    @scrollToBottom()

  imageView: (e) ->
    if @siska
      e.preventDefault()
      new App.SiskaImageViewer(src: $(e.target).get(0).src, name: App.i18n.translatePlain('Image'), returnFocus: e.target)
      return
    e.preventDefault()
    e.stopPropagation()
    new App.CustomerChatImageView(image_base64: $(e.target).get(0).src)

  detectScrolledtoBottom: =>
    scrollBottom = @scrollHolder.scrollTop() + @scrollHolder.outerHeight()
    @scrolledToBottom = Math.abs(scrollBottom - @scrollHolder.prop('scrollHeight')) <= @scrollSnapTolerance
    @scrollHint.addClass('is-hidden') if @scrolledToBottom

  showScrollHint: ->
    @scrollHint.removeClass('is-hidden')
    # compensate scroll
    @scrollHolder.scrollTop(@scrollHolder.scrollTop() + @scrollHint.outerHeight())

  onScrollHintClick: ->
    # animate scroll
    @scrollHolder.animate({scrollTop: @scrollHolder.prop('scrollHeight')}, 300)

  scrollToBottom: ({ showHint } = { showHint: false }) ->
    if @scrolledToBottom
      @scrollHolder.scrollTop(@scrollHolder.prop('scrollHeight'))
    else if showHint
      @showScrollHint()

  transfer: (e) =>
    e.preventDefault()
    chat_id = $(e.currentTarget).attr('data-chat-id')
    App.WebSocket.send(event:'chat_transfer', chat_id: chat_id, session_id: @session.id)
    @close()

  ticketCreate: (e) =>
    e.preventDefault()

    # Fase 5, Item No. 5, Section 5.1.5 -- kalau tiket sudah otomatis
    # dibuat sejak sesi ini mulai, buka LANGSUNG tiket yang sudah ada,
    # bukan buka form New Ticket kosong lagi (menghindari duplikasi).
    if @session.ticket_id
      @navigate "#ticket/zoom/#{@session.ticket_id}"
      return

    id = Math.floor( Math.random() * 99999 )
    @navigate "#ticket/create/id/#{id}"

    # cleanup params
    fqdn      = App.Config.get('fqdn')
    http_type = App.Config.get('http_type')
    url       = ''
    session   = @session

    # in case we do not have a model, create one
    if session && !session.uiUrl
      session = new App.ChatSession(session)
    if session && session.uiUrl
      url = session.uiUrl()

    clean_params =
      id: id
      prefilledParams:
        body: "#{http_type}://#{fqdn}/#{url}"
        title: __('Chat')

    App.TaskManager.execute(
      key:        "TicketCreateScreen-#{id}"
      controller: 'TicketCreate'
      params:     clean_params
      show:       true
    )

class CustomerChatRouter extends App.ControllerPermanent
  @requiredPermission: 'chat.agent'
  constructor: (params) ->
    super

    # cleanup params
    clean_params =
      session_id: params.session_id

    App.TaskManager.execute(
      key:        'CustomerChat'
      controller: 'CustomerChat'
      params:     clean_params
      show:       true
      persistent: true
    )

App.Config.set('customer_chat', CustomerChatRouter, 'Routes')
App.Config.set('customer_chat/session/:session_id', CustomerChatRouter, 'Routes')
App.Config.set('CustomerChat', { controller: 'CustomerChat', permission: ['chat.agent'] }, 'permanentTask')
App.Config.set('CustomerChat', { prio: 1200, parent: '', name: __('Customer Chat'), target: '#customer_chat', key: 'CustomerChat', shown: false, permission: ['chat.agent'], class: 'chat' }, 'NavBar')
