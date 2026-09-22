do($ = window.jQuery, window) ->

  scripts = document.getElementsByTagName('script')

  # search for script to get protocol and hostname for ws connection
  myScript = scripts[scripts.length - 1]
  scriptProtocol = window.location.protocol.replace(':', '') # set default protocol
  if myScript && myScript.src
    scriptHost = myScript.src.match('.*://([^:/]*).*')[1]
    scriptProtocol = myScript.src.match('(.*)://[^:/]*.*')[1]

  # Atas permintaan user (screenshot HP: widget tampil kecil/ter-zoom,
  # BUKAN fullscreen mobile spt seharusnya) -- root cause SEBENARNYA
  # BUKAN CSS widget (media query `max-width:768px` SUDAH benar) --
  # halaman HOST (situs customer PIHAK LAIN, widget di-embed lintas-
  # domain) yang TIDAK PUNYA `<meta name="viewport">` SAMA SEKALI.
  # TANPA itu, browser mobile merender halaman di lebar virtual ~980px
  # (emulasi desktop) lalu zoom-out biar muat ke layar fisik -- BUKAN
  # cuma CSS widget yang tidak aktif, `@isFullscreen` (JS, constructor
  # `ZammadChat` di bawah, pakai `matchMedia`) JUGA ikut salah baca
  # krn dasar masalahnya sama: viewport halaman ITU SENDIRI.
  # Disisipkan SEKALI, PALING AWAL (module-level, sebelum class apa pun
  # didefinisikan) -- jalan begitu file skrip ini dieksekusi browser,
  # SEBELUM `new ZammadChat(...)` sungguhan dipanggil, supaya
  # `@isFullscreen` (dihitung di constructor) SUDAH benar sejak awal.
  # HANYA kalau BELUM ADA sama sekali (`document.querySelector`, dicek
  # dulu) -- JANGAN timpa/duplikasi kalau halaman host SUDAH py
  # viewport meta sendiri, itu genuinely lebih tahu kebutuhan mereka
  # drpd widget ini.
  ensureViewportMeta = ->
    return if document.querySelector('meta[name="viewport"]')
    return if !document.head
    meta = document.createElement('meta')
    meta.setAttribute('name', 'viewport')
    meta.setAttribute('content', 'width=device-width, initial-scale=1')
    document.head.appendChild(meta)

  ensureViewportMeta()

  # Define the plugin class
  class Base
    defaults:
      debug: false

    constructor: (options) ->
      @options = $.extend {}, @defaults, options
      @log = new Log(debug: @options.debug, logPrefix: @options.logPrefix || @logPrefix)

  class Log
    defaults:
      debug: false

    constructor: (options) ->
      @options = $.extend {}, @defaults, options

    debug: (items...) =>
      return if !@options.debug
      @log('debug', items)

    notice: (items...) =>
      @log('notice', items)

    error: (items...) =>
      @log('error', items)

    log: (level, items) =>
      items.unshift('||')
      items.unshift(level)
      items.unshift(@options.logPrefix)
      console.log.apply console, items

      return if !@options.debug
      logString = ''
      for item in items
        logString += ' '
        if typeof item is 'object'
          logString += JSON.stringify(item)
        else if item && item.toString
          logString += item.toString()
        else
          logString += item
      $('.js-chatLogDisplay').prepend('<div>' + logString + '</div>')

  class Timeout extends Base
    timeoutStartedAt: null
    logPrefix: 'timeout'
    defaults:
      debug: false
      timeout: 4
      timeoutIntervallCheck: 0.5

    constructor: (options) ->
      super(options)

    start: =>
      @stop()
      timeoutStartedAt = new Date
      check = =>
        timeLeft = new Date - new Date(timeoutStartedAt.getTime() + @options.timeout * 1000 * 60)
        @log.debug "Timeout check for #{@options.timeout} minutes (left #{timeLeft/1000} sec.)"#, new Date
        return if timeLeft < 0
        @stop()
        @options.callback()
      @log.debug "Start timeout in #{@options.timeout} minutes"#, new Date
      @intervallId = setInterval(check, @options.timeoutIntervallCheck * 1000 * 60)

    stop: =>
      return if !@intervallId
      @log.debug "Stop timeout of #{@options.timeout} minutes"#, new Date
      clearInterval(@intervallId)

  class Io extends Base
    logPrefix: 'io'
    reconnectAttempts: 0
    # Atas permintaan user ("mau" -- auto-reconnect websocket kalau
    # websocket close): SEBELUM ini, koneksi putus TIDAK TERDUGA
    # (jaringan drop, server restart, dll -- BEDA dari `close()`
    # deliberate spt minimize) LANGSUNG memanggil `onError` pada
    # kegagalan PERTAMA, yg ujungnya `@destroy()` widget TOTAL (lihat
    # `ZammadChat#onError`) -- visitor WAJIB reload halaman. Backoff
    # eksponensial di bawah (1s,2s,4s,8s,16s,30s -- dibulatkan maks
    # 30 detik/percobaan, TOTAL ~61 detik) dicoba DULU sebelum akhirnya
    # menyerah ke perilaku lama itu -- angka dipilih supaya visitor
    # TIDAK menunggu tanpa batas, tapi jg tidak membombardir server
    # tiap detik kalau server genuinely down (mis. restart deploy).
    maxReconnectAttempts: 6
    reconnectBaseDelay: 1000
    reconnectMaxDelay: 30000

    constructor: (options) ->
      super(options)

    set: (params) =>
      for key, value of params
        @options[key] = value

    connect: =>
      @log.debug "Connecting to #{@options.host}"
      @ws = new window.WebSocket("#{@options.host}")
      @ws.onopen = (e) =>
        @log.debug 'onOpen', e
        # Begitu koneksi BENAR2 berhasil lagi, reset penghitung &
        # kabari lapisan atas (`ZammadChat`) supaya UI bisa munculkan
        # "Connection re-established" -- HANYA kalau sebelumnya memang
        # sedang retry (bukan koneksi pertama kali/manual reconnect
        # biasa).
        if @reconnectAttempts > 0
          @log.debug "reconnected after #{@reconnectAttempts} attempt(s)"
          @reconnectAttempts = 0
          @options.onReconnected?()
        @options.onOpen(e)
        @ping()

      @ws.onmessage = (e) =>
        pipes = JSON.parse(e.data)
        @log.debug 'onMessage', e.data
        for pipe in pipes
          if pipe.event is 'pong'
            @ping()
        if @options.onMessage
          @options.onMessage(pipes)

      @ws.onclose = (e) =>
        @log.debug 'close websocket connection', e
        if @pingDelayId
          clearTimeout(@pingDelayId)
        if @manualClose
          @log.debug 'manual close, onClose callback'
          @manualClose = false
          if @options.onClose
            @options.onClose(e)
        else
          @attemptReconnect()

      @ws.onerror = (e) =>
        # TIDAK langsung panggil `onError` di sini lagi (dulu bikin
        # `onError` terpanggil 2x utk 1 kegagalan -- `close` SELALU
        # menyusul `error` pada WebSocket native, per spec) -- retry
        # SEPENUHNYA ditangani terpusat di `onclose`
        # (`attemptReconnect`), di sini cukup dicatat log.
        @log.debug 'onError', e

    # Dicoba SEBELUM menyerah ke `onError` (perilaku lama -- widget
    # dihancurkan total). Kalau berhasil, `onopen` di atas otomatis
    # membereskan sisanya lewat `ZammadChat#render()` -- method itu
    # SUDAH PUNYA logic ambil-ulang `sessionId` dari `sessionStorage` +
    # minta status terbaru ke server via `chat_status_customer`,
    # mekanisme YANG SAMA PERSIS dipakai jalur minimize->buka-lagi &
    # hard-refresh -- TIDAK PERLU logic pemulihan sesi baru di sini.
    attemptReconnect: =>
      if @reconnectAttempts >= @maxReconnectAttempts
        @log.debug "gave up after #{@reconnectAttempts} reconnect attempts"
        @reconnectAttempts = 0
        @options.onReconnectFailed?()
        return

      @reconnectAttempts += 1
      delay = Math.min(@reconnectBaseDelay * Math.pow(2, @reconnectAttempts - 1), @reconnectMaxDelay)
      @log.debug "reconnect attempt #{@reconnectAttempts}/#{@maxReconnectAttempts} in #{delay}ms"
      @options.onReconnecting?(@reconnectAttempts, @maxReconnectAttempts)
      @reconnectTimeoutId = setTimeout(@connect, delay)

    close: =>
      @log.debug 'close websocket manually'
      @manualClose = true
      # Jaga-jaga penutupan manual (mis. visitor minimize widget)
      # terjadi PERSIS di tengah jeda backoff yg sedang menunggu --
      # percobaan yg TERTUNDA itu WAJIB dibatalkan, kalau tidak
      # `connect()` akan tetap terpanggil belakangan (koneksi BARU
      # nyelonong padahal visitor sudah minta tutup).
      if @reconnectTimeoutId
        clearTimeout(@reconnectTimeoutId)
        @reconnectTimeoutId = undefined
      @reconnectAttempts = 0
      # Bug TEPI ditemukan lewat uji unit sendiri (bukan laporan user)
      # -- kalau `close()` manual dipanggil PERSIS di jendela ini
      # (socket LAMA sudah genuinely closed duluan, itu SEBABNYA sedang
      # menunggu retry), `WebSocket#close()` NATIVE adalah no-op utk
      # socket yg statusnya SUDAH `CLOSED`/`CLOSING` (tidak memicu
      # event `close` lagi, per spesifikasi) -- `onClose` TIDAK PERNAH
      # terpanggil tanpa cabang ini, padahal pemanggil (mis.
      # `onCloseAnimationEnd`) mengandalkannya utk membereskan UI
      # launcher. Kalau memang tidak ada socket HIDUP utk ditutup,
      # panggil `onClose` LANGSUNG di sini -- efeknya SAMA PERSIS spt
      # kalau event `close` sungguhan sempat terpicu.
      if @ws and @ws.readyState isnt window.WebSocket.CLOSED and @ws.readyState isnt window.WebSocket.CLOSING
        @ws.close()
      else
        @manualClose = false
        @options.onClose?()

    reconnect: =>
      @log.debug 'reconnect'
      @close()
      @connect()

    send: (event, data = {}) =>
      @log.debug 'send', event, data
      # Jaga2 (auto-reconnect): kalau method ini sempat terpanggil
      # SELAGI koneksi belum/tidak lagi terbuka (mis. race condition
      # tipis di tengah jeda retry) -- `WebSocket#send` NATIVE akan
      # throw exception kalau dipaksa dipanggil di state ini, no-op
      # diam2 di sini jauh lebih aman drpd JS error tak tertangani.
      return if !@ws or @ws.readyState isnt window.WebSocket.OPEN
      msg = JSON.stringify
        event: event
        data: data
      @ws.send msg

    ping: =>
      localPing = =>
        @send('ping')
      @pingDelayId = setTimeout(localPing, 29000)

  class ZammadChat extends Base
    defaults:
      chatId: undefined
      show: true
      target: $('body')
      host: ''
      debug: false
      flat: false
      lang: undefined
      cssAutoload: true
      cssUrl: undefined
      fontSize: undefined
      buttonClass: 'open-zammad-chat'
      inactiveClass: 'is-inactive'
      title: '<strong>Chat</strong> with us!'
      scrollHint: 'Scroll down to see new messages'
      idleTimeout: 6
      idleTimeoutIntervallCheck: 0.5
      inactiveTimeout: 8
      inactiveTimeoutIntervallCheck: 0.5
      waitingListTimeout: 4
      waitingListTimeoutIntervallCheck: 0.5
      # Callbacks
      onReady: undefined
      onCloseAnimationEnd: undefined
      onError: undefined
      onOpenAnimationEnd: undefined
      onConnectionReestablished: undefined
      onSessionClosed: undefined
      onConnectionEstablished: undefined
      onCssLoaded: undefined

    logPrefix: 'chat'
    _messageCount: 0
    isOpen: false
    blinkOnlineInterval: null
    stopBlinOnlineStateTimeout: null
    showTimeEveryXMinutes: 2
    lastTimestamp: null
    lastAddedType: null
    inputDisabled: false
    inputTimeout: null
    isTyping: false
    state: 'offline'
    # Enhancement 1 -- Tahap 3 (Offline Message + OTP). BEDA dari
    # `state` di atas (itu status koneksi WebSocket ke server, native
    # Zammad -- lihat `setAgentOnlineState`/`render()`) -- flag INI
    # murni "apakah SEMUA agent sedang tidak tersedia" (dikonfirmasi
    # via `chat_status_customer` state 'offline', sudah AUX-aware
    # sejak entri 143), dipakai `submitPrechatForm` utk memilih jalur
    # kirim (`chat_session_init` biasa vs `chat_offline_session_init`).
    offlineMode: false
    initialQueueDelay: 10000
    translations:
    # ZAMMAD_TRANSLATIONS_START
      'ca':
        '<strong>Chat</strong> with us!': '<strong>Xateja</strong> amb nosaltres!'
        'All colleagues are busy.': 'Tot el personal està ocupat.'
        'Chat closed by %s': 'Xat tancat per %s'
        'Compose your message…': 'Redacta el teu missatge…'
        'Connecting': 'Connectant'
        'Connection lost': 'Connexió perduda'
        'Connection re-established': 'Connexió restablerta'
        'Offline': 'Fora de línia'
        'Online': 'En línia'
        'Scroll down to see new messages': 'Desplaçat més avall per veure nous missatges'
        'Send': 'Envia'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Com que no heu respost en els darrers %s minuts, la vostra conversa s\'ha tancat.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Com que no heu respost en els darrers %s minuts, la vostra conversa amb <strong>%s</strong> s\'ha tancat.'
        'Start new conversation': 'Inicia una conversa nova'
        'Today': 'Avui'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Ho sentim, està tardant més del que s\'esperava per aconseguir un espai. Si us plau, torna-ho a intentar més tard o envia\'ns un correu electrònic. Gràcies!'
        'You are on waiting list position <strong>%s</strong>.': 'Estàs en la posició <strong>%s</strong> de la llista d\'espera.'
      'cs':
        '<strong>Chat</strong> with us!': '<strong>Chatujte</strong> s námi!'
        'All colleagues are busy.': 'Všichni kolegové jsou vytíženi.'
        'Chat closed by %s': '%s ukončil konverzaci'
        'Compose your message…': 'Napište svou zprávu…'
        'Connecting': 'Připojování'
        'Connection lost': 'Připojení ztraceno'
        'Connection re-established': 'Připojení obnoveno'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Srolujte dolů pro zobrazení nových zpráv'
        'Send': 'Odeslat'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Jelikož jste nereagovali v posledních %s minutách, vaše konverzace byla uzavřena.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Jelikož jste nereagovali v posledních %s minutách, vaše konverzace s <strong>%s</strong> byla uzavřena.'
        'Start new conversation': 'Zahájit novou konverzaci'
        'Today': 'Dnes'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Omlouváme se, že musíte čekat déle, než je vhodné pro získání slotu. Prosím, zkuste to později, případně nám napište e-mail. Děkujeme!'
        'You are on waiting list position <strong>%s</strong>.': 'Jste <strong>%s</strong>. v pořadí na čekací listině.'
      'da':
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> med os!'
        'All colleagues are busy.': 'Alle medarbejdere er optaget.'
        'Chat closed by %s': 'Chat lukket af %s'
        'Compose your message…': 'Skriv din besked…'
        'Connecting': 'Forbinder'
        'Connection lost': 'Forbindelse mistet'
        'Connection re-established': 'Forbindelse genoprettet'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Rul ned for at se nye beskeder'
        'Send': 'Send'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Da du ikke svarede inden for de sidste %s minutter, blev din samtale lukket.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Da du ikke svarede inden for de sidste %s minutter, blev din samtale med <strong>%s</strong> lukket.'
        'Start new conversation': 'Start en ny samtale'
        'Today': 'I dag'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Vi beklager, det tager længere end forventet at få en ledig plads. Prøv igen senere, eller send os en email. Tak!'
        'You are on waiting list position <strong>%s</strong>.': 'Du er i kø som nummer <strong>%s</strong>.'
      'de':
        '<strong>Chat</strong> with us!': '<strong>Chatte</strong> mit uns!'
        'All colleagues are busy.': 'Alle Kollegen sind beschäftigt.'
        'Chat closed by %s': 'Chat von %s geschlossen'
        'Compose your message…': 'Verfassen Sie Ihre Nachricht…'
        'Connecting': 'Verbinde'
        'Connection lost': 'Verbindung verloren'
        'Connection re-established': 'Verbindung wieder aufgebaut'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Nach unten scrollen um neue Nachrichten zu sehen'
        'Send': 'Senden'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Da Sie innerhalb der letzten %s Minuten nicht reagiert haben, wurde Ihre Unterhaltung geschlossen.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Da Sie innerhalb der letzten %s Minuten nicht reagiert haben, wurde Ihre Unterhaltung mit <strong>%s</strong> geschlossen.'
        'Start new conversation': 'Neue Unterhaltung starten'
        'Today': 'Heute'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Entschuldigung, es dauert länger als erwartet einen freien Platz zu bekommen. Versuchen Sie es später erneut oder senden Sie uns eine E-Mail. Vielen Dank!'
        'You are on waiting list position <strong>%s</strong>.': 'Sie sind in der Warteliste auf Position <strong>%s</strong>.'
      'es':
        '<strong>Chat</strong> with us!': '<strong>Chatee</strong> con nosotros!'
        'All colleagues are busy.': 'Todos los colegas están ocupados.'
        'Chat closed by %s': 'Chat cerrado por %s'
        'Compose your message…': 'Escribe tu mensaje…'
        'Connecting': 'Conectando'
        'Connection lost': 'Conexión perdida'
        'Connection re-established': 'Conexión reestablecida'
        'Offline': 'Desconectado'
        'Online': 'En línea'
        'Scroll down to see new messages': 'Desplace hacia abajo para ver nuevos mensajes'
        'Send': 'Enviar'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Debido a que usted no ha respondido en los últimos %s minutos, su conversación se ha cerrado.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Debido a que usted no ha respondido en los últimos %s minutos, su conversación con <strong>%s</strong> se ha cerrado.'
        'Start new conversation': 'Iniciar nueva conversación'
        'Today': 'Hoy'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Lo sentimos, estamos tardando más de lo esperado para asignar un agente. Inténtelo de nuevo más tarde o envíenos un correo electrónico. ¡Gracias!'
        'You are on waiting list position <strong>%s</strong>.': 'Usted está en la posición <strong>%s</strong> de la lista de espera.'
      'fa':
        '<strong>Chat</strong> with us!': 'با ما <strong>گفتگو کنید</strong>!'
        'All colleagues are busy.': 'تمام همکاران مشغول هستند.'
        'Chat closed by %s': 'چت توسط %s بسته شد'
        'Compose your message…': 'پیام خود را وارد نمایید…'
        'Connecting': 'درحال برقراری ارتباط'
        'Connection lost': 'ارتباط قطع شد'
        'Connection re-established': 'ارتباط مجددا برقرار شد'
        'Offline': 'برون خط'
        'Online': 'آنلاین'
        'Scroll down to see new messages': 'برای دیدن پیام‌های جدید به سمت پایین حرکت کنید'
        'Send': 'ارسال'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'از آنجایی که در %s دقیقه گذشته پاسخی ندادید، مکالمه شما بسته شد.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'از آنجایی که در %s دقیقه گذشته پاسخی ندادید، مکالمه شما با <strong>%s</strong> بسته شد.'
        'Start new conversation': 'شروع مکالمه جدید'
        'Today': 'امروز'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'متاسفیم، گرفتن یک موقعیت بیشتر از حد انتظار طول می‌کشد. لطفاً بعداً دوباره تلاش کنید یا برای ما ایمیل بفرستید. متشکریم!'
        'You are on waiting list position <strong>%s</strong>.': 'شما در موقعیت لیست انتظار <strong>%s</strong> هستید.'
      'fr':
        '<strong>Chat</strong> with us!': '<strong>Chattez</strong> avec nous !'
        'All colleagues are busy.': 'Tous les agents sont occupés.'
        'Chat closed by %s': 'Chat fermé par %s'
        'Compose your message…': 'Écrivez votre message…'
        'Connecting': 'Connexion'
        'Connection lost': 'Connexion perdue'
        'Connection re-established': 'Connexion ré-établie'
        'Offline': 'Hors-ligne'
        'Online': 'En ligne'
        'Scroll down to see new messages': 'Défiler vers le bas pour voir les nouveaux messages'
        'Send': 'Envoyer'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Sans réponse de votre part depuis %s minutes, votre conservation a été fermée.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Sans réponse de votre part depuis %s minutes, votre conversation avec <strong>%s</strong> a été fermée.'
        'Start new conversation': 'Démarrer une nouvelle conversation'
        'Today': 'Aujourd\'hui'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Nous sommes désolés, trouver un agent disponible prend plus de temps que prévu. Réessayez ultérieurement ou envoyez-nous un mail. Merci !'
        'You are on waiting list position <strong>%s</strong>.': 'Vous êtes actuellement en position <strong>%s</strong> dans la file d\'attente.'
      'hr':
        '<strong>Chat</strong> with us!': '<strong>Čavrljajte</strong> sa nama!'
        'All colleagues are busy.': 'Svi agenti su zauzeti.'
        'Chat closed by %s': '%s zatvara chat'
        'Compose your message…': 'Sastavite poruku…'
        'Connecting': 'Povezivanje'
        'Connection lost': 'Veza prekinuta'
        'Connection re-established': 'Veza je ponovno uspostavljena'
        'Offline': 'Odsutan'
        'Online': 'Dostupan(a)'
        'Scroll down to see new messages': 'Pomaknite se prema dolje da biste vidjeli nove poruke'
        'Send': 'Pošalji'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Budući da niste odgovorili u posljednjih %s minuta, Vaš je razgovor zatvoren.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Budući da niste odgovorili u posljednjih %s minuta, Vaš je razgovor s <strong>%</strong>s zatvoren.'
        'Start new conversation': 'Započni novi razgovor'
        'Today': 'Danas'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Oprostite, traje duže nego inače za dobiti slobodan termin. Molimo, pokušajte ponovno kasnije ili nam pošaljite e-mail. Hvala!'
        'You are on waiting list position <strong>%s</strong>.': 'Nalazite se u redu čekanja na poziciji <strong>%s</strong>.'
      'hu':
        '<strong>Chat</strong> with us!': '<strong>Csevegjen</strong> velünk!'
        'All colleagues are busy.': 'Az összes munkatárs elfoglalt.'
        'Chat closed by %s': 'A csevegés %s által lezárva'
        'Compose your message…': 'Üzenet írása…'
        'Connecting': 'Kapcsolatépítés'
        'Connection lost': 'A kapcsolat megszakadt'
        'Connection re-established': 'A kapcsolat helyreállt'
        'Offline': 'Kapcsolat nélkül'
        'Online': 'Elérhető'
        'Scroll down to see new messages': 'Görgessen le az új üzenetek megtekintéséhez'
        'Send': 'Küldés'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Mivel nem válaszolt az elmúlt %s percben, a beszélgetése lezárásra került.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Mivel nem válaszolt az elmúlt %s percben, <strong>%s</strong> ügyintézővel folytatott beszélgetése lezárásra került.'
        'Start new conversation': 'Új beszélgetés indítása'
        'Today': 'Ma'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Sajnáljuk, a vártnál hosszabb ideig tart a helyfoglalás. Próbálja meg később újra, vagy küldjön nekünk e-mailt. Köszönjük!'
        'You are on waiting list position <strong>%s</strong>.': 'Ön a várólista <strong>%s.</strong> helyén szerepel.'
      'id':
        '<strong>Chat</strong> with us!': '<strong>Obrolan</strong> dengan kami!'
        'All colleagues are busy.': 'Semua rekan sedang sibuk.'
        'Chat closed by %s': 'Obrolan ditutup oleh %s'
        'Compose your message…': 'Tulis pesan Anda…'
        'Connecting': 'Menghubungkan'
        'Connection lost': 'Koneksi terputus'
        'Connection re-established': 'Koneksi dipulihkan'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Gulir ke bawah untuk melihat pesan baru'
        'Send': 'Kirim'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Karena Anda tidak membalas dalam %s menit terakhir, percakapan Anda ditutup.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Karena Anda tidak membalas dalam %s menit terakhir, percakapan Anda dengan <strong>%s</strong> ditutup.'
        'Start new conversation': 'Mulai percakapan baru'
        'Today': 'Hari ini'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Kami minta maaf, proses ini memakan waktu lebih lama dari yang diharapkan untuk mendapatkan slot. Silakan coba lagi nanti atau kirimkan email ke kami. Terima kasih!'
        'You are on waiting list position <strong>%s</strong>.': 'Anda berada di posisi daftar tunggu <strong>%s</strong>.'
      'it':
        '<strong>Chat</strong> with us!': '<strong>Chatta</strong> con noi!'
        'All colleagues are busy.': 'Tutti i colleghi sono occupati.'
        'Chat closed by %s': 'Chat chiusa da %s'
        'Compose your message…': 'Scrivi il tuo messaggio…'
        'Connecting': 'Connessione in corso'
        'Connection lost': 'Connessione persa'
        'Connection re-established': 'Connessione ristabilita'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Scorri verso il basso per vedere i nuovi messaggi'
        'Send': 'Invia'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Dato che non hai risposto negli ultimi %s minuti, la conversazione è stata chiusa.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Dato che non hai risposto negli ultimi %s minuti, la conversazione con <strong>%s</strong> è stata chiusa.'
        'Start new conversation': 'Avvia una nuova chat'
        'Today': 'Oggi'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Siamo spiacenti, ci vuole più tempo del previsto per ottenere uno spazio libero. Riprova più tardi o inviaci un\'e-mail. Grazie!'
        'You are on waiting list position <strong>%s</strong>.': 'Sei alla posizione <strong>%s</strong> della lista di attesa.'
      'ko':
        '<strong>Chat</strong> with us!': '우리와 <strong>채팅</strong> !'
        'All colleagues are busy.': '모든 동료가 바쁩니다.'
        'Chat closed by %s': '%s에 의해 채팅 종료'
        'Compose your message…': '메시지를 작성하세요…'
        'Connecting': '연결 중'
        'Connection lost': '연결 끊김'
        'Connection re-established': '연결 재설정됨'
        'Offline': '오프라인'
        'Online': '온라인'
        'Scroll down to see new messages': '새 메시지를 보려면 아래로 스크롤'
        'Send': '보내기'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': '지난 %s분 동안 응답하지 않아 대화가 종료되었습니다.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': '지난 %s분 동안 응답하지 않아 <strong>%s</strong>님과의 대화가 종료되었습니다.'
        'Start new conversation': '새 대화 시작'
        'Today': '오늘'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': '죄송합니다. 슬롯을 받는 데 예상보다 시간이 오래 걸리고 있습니다. 나중에 다시 시도하거나 이메일을 보내주세요. 감사합니다!'
        'You are on waiting list position <strong>%s</strong>.': '대기 목록 위치 <strong>%s</strong>에 있습니다.'
      'lt':
        '<strong>Chat</strong> with us!': '<strong>Kalbėkitės</strong> su mumis!'
        'All colleagues are busy.': 'Visi kolegos užimti.'
        'Chat closed by %s': '%s uždarė pokalbį'
        'Compose your message…': 'Rašykite žinutę…'
        'Connecting': 'Jungiamasi'
        'Connection lost': 'Dingo ryšys'
        'Connection re-established': 'Ryšys atnaujintas'
        'Offline': 'Atsijungęs'
        'Online': 'Prisijungęs'
        'Scroll down to see new messages': 'Naujos žinutės žemiau'
        'Send': 'Siųsti'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Jūsų pokalbis buvo uždarytas, nes nieko neatsakėte per %s minučių.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Jūsų pokalbis su <strong>%s</strong> buvo uždarytas, nes nieko neatsakėte per %s minučių.'
        'Start new conversation': 'Pradėti naują pokalbį'
        'Today': 'Šiandien'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Atsiprašome, kad tenka laukti atskymo. Bandykite vėliau arba rašykite el. paštu. Ačiū!'
        'You are on waiting list position <strong>%s</strong>.': 'Esate <strong>%s</strong> eilėje.'
      'nl':
        '<strong>Chat</strong> with us!': '<strong>Chat</strong> met ons!'
        'All colleagues are busy.': 'Alle collega\'s zijn bezet.'
        'Chat closed by %s': 'Chat gesloten door %s'
        'Compose your message…': 'Stel je bericht op…'
        'Connecting': 'Verbinden'
        'Connection lost': 'Verbinding verbroken'
        'Connection re-established': 'Verbinding hersteld'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Scroll naar beneden om nieuwe tickets te bekijken'
        'Send': 'Verstuur'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'De chat is afgesloten omdat je de laatste %s minuten niet hebt gereageerd.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Je chat met <strong>%s</strong> is afgesloten omdat je niet hebt gereageerd in de laatste %s minuten.'
        'Start new conversation': 'Nieuw gesprek starten'
        'Today': 'Vandaag'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Het spijt ons, het duurt langer dan verwacht om een chat te starten. Probeer het later nog eens of stuur ons een e-mail. Bedankt!'
        'You are on waiting list position <strong>%s</strong>.': 'Je bevindt zich op wachtlijstpositie <strong>%s</strong>.'
      'pl':
        '<strong>Chat</strong> with us!': '<strong>Czatuj</strong> z nami!'
        'All colleagues are busy.': 'Wszyscy agenci są zajęci.'
        'Chat closed by %s': 'Chat zamknięty przez %s'
        'Compose your message…': 'Skomponuj swoją wiadomość…'
        'Connecting': 'Łączenie'
        'Connection lost': 'Utracono połączenie'
        'Connection re-established': 'Ponowne nawiązanie połączenia'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Skroluj w dół, aby zobaczyć wiadomości'
        'Send': 'Wyślij'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Ponieważ nie odpowiedziałeś w ciągu ostatnich %s minut, Twoja rozmowa została zamknięta.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Ponieważ nie odpowiedziałeś w ciągu ostatnich %s minut, Twoja rozmowa z <strong>%s</strong> została zamknięta.'
        'Start new conversation': 'Rozpocznij nową rozmowę'
        'Today': 'Dzisiaj'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Przepraszamy, znalezienie wolnego konsultanta zajmuje więcej czasu niż oczekiwano. Spróbuj ponownie później lub wyślij nam e-mail. Dziękujemy!'
        'You are on waiting list position <strong>%s</strong>.': 'Jesteś na pozycji listy oczekujących <strong>%s</strong>.'
      'pt-br':
        '<strong>Chat</strong> with us!': '<strong>Converse</strong> conosco!'
        'All colleagues are busy.': 'Todos os agentes estão ocupados.'
        'Chat closed by %s': 'Chat encerrado por %s'
        'Compose your message…': 'Escreva sua mensagem…'
        'Connecting': 'Conectando'
        'Connection lost': 'Conexão perdida'
        'Connection re-established': 'Conexão restabelecida'
        'Offline': 'Desconectado'
        'Online': 'Online'
        'Scroll down to see new messages': 'Role para baixo para ver novas mensagens'
        'Send': 'Enviar'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Como você não respondeu nos últimos %s minutos, sua conversa foi encerrada.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Como você não respondeu nos últimos %s minutos, sua conversa com <strong>%s</strong> foi encerrada.'
        'Start new conversation': 'Iniciar uma nova conversa'
        'Today': 'Hoje'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Lamentamos, está demorando mais do que o esperado para conseguir uma vaga. Tente novamente mais tarde ou envie-nos um email. Obrigado!'
        'You are on waiting list position <strong>%s</strong>.': 'Você está na posição <strong>%s</strong> da lista de espera.'
      'ro':
        '<strong>Chat</strong> with us!': '<strong>Comunică</strong> cu noi!'
        'All colleagues are busy.': 'Toți colegii sunt ocupați momentan.'
        'Chat closed by %s': 'Chat închis de către %s'
        'Compose your message…': 'Compune-ți mesajul…'
        'Connecting': 'Se conectează'
        'Connection lost': 'Conexiune pierdută'
        'Connection re-established': 'Conexiune restabilită'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Derulați în jos pentru a vedea mesajele noi'
        'Send': 'Trimite'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Deoarece nu ai răspuns în ultimele %s minute, conversația ta a fost închisă.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Deoarece nu ai răspuns în ultimele %s minute, conversația ta cu <strong>%s</strong> a fost închisă.'
        'Start new conversation': 'Începe o conversație nouă'
        'Today': 'Azi'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Ne pare rău, durează mai mult decât ne așteptam să obținem un loc. Te rugăm să încerci din nou mai târziu sau să ne trimiți un email. Mulțumim!'
        'You are on waiting list position <strong>%s</strong>.': 'Aveți poziția <strong>%s</strong> în lista de așteptare.'
      'ru':
        '<strong>Chat</strong> with us!': '<strong>Напишите</strong> нам!'
        'All colleagues are busy.': 'Все коллеги заняты.'
        'Chat closed by %s': 'Чат закрыт %s'
        'Compose your message…': 'Составьте сообщение…'
        'Connecting': 'Подключение'
        'Connection lost': 'Подключение потеряно'
        'Connection re-established': 'Подключение восстановлено'
        'Offline': 'Оффлайн'
        'Online': 'В сети'
        'Scroll down to see new messages': 'Прокрутите вниз, чтобы увидеть новые сообщения'
        'Send': 'Отправить'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Поскольку Вы не ответили в течение последних %s минут, Ваш разговор был закрыт.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Поскольку Вы не ответили в течение последних %s минут, Ваш разговор с <strong>%s</strong> был закрыт.'
        'Start new conversation': 'Начать новый разговор'
        'Today': 'Сегодня'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Извините, получение свободного слота занимает больше времени, чем ожидалось. Пожалуйста, повторите попытку позже или отправьте нам электронное письмо. Благодарим Вас!'
        'You are on waiting list position <strong>%s</strong>.': 'Вы находитесь в списке ожидания <strong>%s</strong>.'
      'sk':
        '<strong>Chat</strong> with us!': '<strong>Napíšte</strong> nám cez chat!'
        'All colleagues are busy.': 'Všetci kolegovia sú zaneprázdnení.'
        'Chat closed by %s': 'Chat zatvoril(a) %s'
        'Compose your message…': 'Napíšte vašu správu…'
        'Connecting': 'Pripája sa'
        'Connection lost': 'Spojenie prerušené'
        'Connection re-established': 'Pripojenie obnovené'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Posuňte sa nadol, aby ste videli nové správy'
        'Send': 'Odoslať'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Keďže ste neodpovedali v posledných %s minútach, vaša konverzácia bola uzavretá.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Keďže ste v posledných %s minútach neodpovedali, vaša konverzácia s <strong>%s</strong> bola ukončená.'
        'Start new conversation': 'Začať novú konverzáciu'
        'Today': 'Dnes'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Je nám ľúto, že získanie slotu trvá dlhšie, než sme očakávali. Skúste to prosím neskôr alebo nám pošlite e-mail. Ďakujeme!'
        'You are on waiting list position <strong>%s</strong>.': 'Na čakacej listine ste na pozícii <strong>%s</strong>.'
      'sr':
        '<strong>Chat</strong> with us!': '<strong>Ћаскајте</strong> са нама!'
        'All colleagues are busy.': 'Све колеге су заузете.'
        'Chat closed by %s': 'Ћаскање затворено од стране %s'
        'Compose your message…': 'Напишите поруку…'
        'Connecting': 'Повезивање'
        'Connection lost': 'Веза је изгубљена'
        'Connection re-established': 'Веза је поново успостављена'
        'Offline': 'Одсутан(а)'
        'Online': 'Доступан(а)'
        'Scroll down to see new messages': 'Скролујте на доле за нове поруке'
        'Send': 'Пошаљи'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Пошто нисте одговорили у последњих %s минут(a), ваш разговор је завршен.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Пошто нисте одговорили у последњих %s минут(a), ваш разговор са <strong>%s</strong> је завршен.'
        'Start new conversation': 'Започни нови разговор'
        'Today': 'Данас'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Жао нам је, добијање празног термина траје дуже од очекиваног. Молимо покушајте поново касније или нам пошаљите имејл поруку. Хвала вам!'
        'You are on waiting list position <strong>%s</strong>.': 'Ви сте тренутно <strong>%s.</strong> у реду за чекање.'
      'sr-latn-rs':
        '<strong>Chat</strong> with us!': '<strong>Ćaskajte</strong> sa nama!'
        'All colleagues are busy.': 'Sve kolege su zauzete.'
        'Chat closed by %s': 'Ćaskanje zatvoreno od strane %s'
        'Compose your message…': 'Napišite poruku…'
        'Connecting': 'Povezivanje'
        'Connection lost': 'Veza je izgubljena'
        'Connection re-established': 'Veza je ponovo uspostavljena'
        'Offline': 'Odsutan(a)'
        'Online': 'Dostupan(a)'
        'Scroll down to see new messages': 'Skrolujte na dole za nove poruke'
        'Send': 'Pošalji'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Pošto niste odgovorili u poslednjih %s minut(a), vaš razgovor je završen.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Pošto niste odgovorili u poslednjih %s minut(a), vaš razgovor sa <strong>%s</strong> je završen.'
        'Start new conversation': 'Započni novi razgovor'
        'Today': 'Danas'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Žao nam je, dobijanje praznog termina traje duže od očekivanog. Molimo pokušajte ponovo kasnije ili nam pošaljite imejl poruku. Hvala vam!'
        'You are on waiting list position <strong>%s</strong>.': 'Vi ste trenutno <strong>%s.</strong> u redu za čekanje.'
      'sv':
        '<strong>Chat</strong> with us!': '<strong>Chatta</strong> med oss!'
        'All colleagues are busy.': 'Alla kollegor är upptagna.'
        'Chat closed by %s': 'Chatt stängd av %s'
        'Compose your message…': 'Skriv ditt meddelande …'
        'Connecting': 'Ansluter'
        'Connection lost': 'Anslutningen försvann'
        'Connection re-established': 'Anslutningen återupprättas'
        'Offline': 'Offline'
        'Online': 'Online'
        'Scroll down to see new messages': 'Bläddra ner för att se nya meddelanden'
        'Send': 'Skicka'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Din chatt avslutades då du inte svarade inom %s minuter.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Chatten stängdes eftersom du inte svarat inom %s minuter i din konversation med <strong>%s</strong>.'
        'Start new conversation': 'Starta ny konversation'
        'Today': 'Idag'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Det tar tyvärr längre tid än förväntat att få en ledig plats. Försök igen senare eller skicka ett mejl till oss. Tack!'
        'You are on waiting list position <strong>%s</strong>.': 'Du är på väntelistan som position <strong>%s</strong>.'
      'tr':
        '<strong>Chat</strong> with us!': 'Bizimle <strong>Sohbet</strong> edin!'
        'All colleagues are busy.': 'Tüm meslektaşlar meşgul.'
        'Chat closed by %s': 'Sohbet %s tarafından kapatıldı'
        'Compose your message…': 'Mesajınızı yazın…'
        'Connecting': 'Bağlanıyor'
        'Connection lost': 'Bağlantı koptu'
        'Connection re-established': 'Bağlantı yeniden sağlandı'
        'Offline': 'Çevrimdışı'
        'Online': 'Online'
        'Scroll down to see new messages': 'Scroll down to see new messages'
        'Send': 'Gönder'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Son %s dakika içinde yanıt vermediğiniz için görüşmeniz kapatıldı.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Son %s dakika içinde yanıt vermediğiniz için <strong>%s</strong> ile görüşmeniz sonlandırıldı.'
        'Start new conversation': 'Yeni görüşme başlat'
        'Today': 'Bugün'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Üzgünüz, yer bulmamız beklenenden daha uzun sürüyor. Lütfen daha sonra tekrar deneyin veya bize bir e-posta gönderin. Teşekkür ederiz!'
        'You are on waiting list position <strong>%s</strong>.': 'Bekleme listesindeki sıranız <strong>%s</strong>.'
      'uk':
        '<strong>Chat</strong> with us!': '<strong>Напишіть</strong> нам!'
        'All colleagues are busy.': 'Всі колеги зайняті.'
        'Chat closed by %s': 'Чат закрито %s'
        'Compose your message…': 'Складіть ваше повідомлення…'
        'Connecting': 'Підключення'
        'Connection lost': 'Підключення втрачено'
        'Connection re-established': 'Підключення відновлено'
        'Offline': 'Не в мережі'
        'Online': 'В мережі'
        'Scroll down to see new messages': 'Прокрутіть униз, щоб побачити нові повідомлення'
        'Send': 'Відправити'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': 'Оскільки ви не відповіли протягом останніх %s хвилин, вашу розмову було закрито.'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': 'Оскільки ви не відповіли протягом останніх %s хвилин, ваша розмова з <strong>%s</strong> була завершена.'
        'Start new conversation': 'Почніть нову розмову'
        'Today': 'Сьогодні'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': 'Вибачте, отримання слоту займає більше часу, ніж очікувалося. Будь ласка, спробуйте пізніше або надішліть нам електронного листа. Дякуємо!'
        'You are on waiting list position <strong>%s</strong>.': 'Ви перебуваєте у списку очікування <strong>%s</strong>.'
      'zh-cn':
        '<strong>Chat</strong> with us!': '发起<strong>即时对话</strong>!'
        'All colleagues are busy.': '所有同事都很忙。'
        'Chat closed by %s': '对话已被 %s 关闭'
        'Compose your message…': '编辑您的信息…'
        'Connecting': '连接中'
        'Connection lost': '连接丢失'
        'Connection re-established': '正在重新建立连接'
        'Offline': '离线'
        'Online': '在线'
        'Scroll down to see new messages': '向下滚动以查看新消息'
        'Send': '发送'
        'Since you didn\'t respond in the last %s minutes your conversation was closed.': '"由于您超过 %s 分钟没有任何回复'
        'Since you didn\'t respond in the last %s minutes your conversation with <strong>%s</strong> was closed.': '"由于您超过 %s 分钟没有回复'
        'Start new conversation': '开始新的会话'
        'Today': '今天'
        'We are sorry, it is taking longer than expected to get a slot. Please try again later or send us an email. Thank you!': ''
        'You are on waiting list position <strong>%s</strong>.': '您目前的等候位置是第 <strong>%s</strong> 位.'
    # ZAMMAD_TRANSLATIONS_END
    sessionId: undefined
    # Enhancement 2 -- lihat catatan di `showFeedback`.
    lastSessionId: undefined
    feedbackScore: undefined
    # Enhancement 4 -- lihat catatan di `updatePhrases`. Object literal
    # ini AMAN dipakai sbg default class-body (BUKAN prototype yang
    # dimutasi) krn `updatePhrases` selalu REASSIGN `@phrases = ...`
    # (bikin own-property baru per instance), tidak pernah memutasi
    # object yang sama secara langsung.
    phrases: {}
    scrolledToBottom: true
    scrollSnapTolerance: 10
    richTextFormatKey:
      66: true # b
      73: true # i
      85: true # u
      83: true # s

    T: (string, items...) =>
      if @options.lang && @options.lang isnt 'en'
        if !@translations[@options.lang]
          @log.notice "Translation '#{@options.lang}' needed!"
        else
          translations = @translations[@options.lang]
          if !translations[string]
            @log.notice "Translation needed for '#{string}'"
          string = translations[string] || string
      if items
        for item in items
          string = string.replace(/%s/, item)
      string

    view: (name) =>
      return (options) =>
        if !options
          options = {}

        options.T = @T
        options.background = @options.background
        options.flat = @options.flat
        options.fontSize = @options.fontSize
        # Enhancement 4 -- lihat catatan di `updatePhrases`.
        options.phrases = @phrases
        return window.zammadChatTemplates[name](options)

    constructor: (options) ->
      @options = $.extend {}, @defaults, options
      super(@options)

      # fullscreen
      @isFullscreen = (window.matchMedia and window.matchMedia('(max-width: 768px)').matches)
      @scrollRoot = $(@getScrollRoot())

      # check prerequisites
      if !$
        @state = 'unsupported'
        @log.notice 'Chat: no jquery found!'
        return
      if !window.WebSocket or !sessionStorage
        @state = 'unsupported'
        @log.notice 'Chat: Browser not supported!'
        return
      if !@options.chatId
        @state = 'unsupported'
        @log.error 'Chat: need chatId as option!'
        return

      # detect language
      if !@options.lang
        @options.lang = $('html').attr('lang')
      if @options.lang
        if !@translations[@options.lang]
          @log.debug "lang: No #{@options.lang} found, try first two letters"
          @options.lang = @options.lang.replace(/-.+?$/, '') # replace "-xx" of xx-xx
        @log.debug "lang: #{@options.lang}"

      # detect host
      @detectHost() if !@options.host

      @loadCss()

      @io = new Io(@options)
      @io.set(
        onOpen: @render
        onClose: @onWebSocketClose
        onMessage: @onWebSocketMessage
        onError: @onError
        # Atas permintaan user ("mau" -- auto-reconnect websocket) --
        # lihat `Io#attemptReconnect()` utk mekanisme retry-nya sendiri;
        # 2 callback BARU ini KHUSUS urusan UI (pesan status di
        # transkrip chat + toggle kotak ketik), lihat definisinya
        # masing-masing di bawah.
        onReconnecting: @onIoReconnecting
        onReconnected: @onIoReconnected
        # Atas permintaan user (mockup fullpage "Connection lost") --
        # callback KHUSUS utk kegagalan reconnect (bukan `onError`
        # generik, msh dipakai skenario lain spt chat disabled/antrian
        # penuh dan TIDAK relevan dgn overlay koneksi ini).
        onReconnectFailed: @onReconnectFailed
      )

      @io.connect()

      # Fitur tambahan "Reply ke Pesan Spesifik" -- Section 5.3. null =
      # tidak sedang membalas pesan mana pun. Cuma pesan dari AGENT yang
      # bisa dibalas dari sisi customer (id server sungguhan cuma
      # diketahui dari pesan yang DITERIMA, bukan yang baru dikirim
      # sendiri -- lihat komentar di sendMessage).
      @replyTo = null
      @agentMessagesById = {}

    getScrollRoot: ->
      return document.scrollingElement if 'scrollingElement' of document
      html = document.documentElement
      start = html.scrollTop
      html.scrollTop = start + 1
      end = html.scrollTop
      html.scrollTop = start
      return if end > start then html else document.body

    render: =>
      if !@el || !$('.zammad-chat').get(0)
        @renderBase()

      # disable open button
      $(".#{ @options.buttonClass }").addClass @options.inactiveClass

      @setAgentOnlineState 'online'

      @log.debug 'widget rendered'

      @startTimeoutObservers()
      @idleTimeout.start()

      # get current chat status
      @sessionId = sessionStorage.getItem('sessionId')
      # dipulihkan bersamaan dgn sessionId (lihat submitPrechatForm) --
      # dibutuhkan `onReopenSession` utk avatar inisial pesan customer
      # sendiri saat riwayat percakapan dimuat ulang setelah reconnect.
      @customerName = sessionStorage.getItem('customerName')
      @send 'chat_status_customer',
        session_id: @sessionId
        url: window.location.href

    # Atas permintaan user ("dari mulai websocket terhubung sampai page
    # diload sempurna, diberi loading full page, gunakan loading nya
    # ablepro") -- `views/preload.eco` SENGAJA "berdiri sendiri", BUKAN
    # `@view('waiting')()`/spinner yg SUDAH ADA (`.zammad-chat-waiting-
    # spinner`, dipakai `loader.eco`) -- itu bergantung PENUH ke class
    # `chat.scss`, TIDAK AKAN tampil benar sebelum CSS itu SENDIRI
    # selesai dimuat (justru KETIADAAN CSS itu masalah yg mau
    # diselesaikan). `preload.eco` REUSE visual yg SAMA (lingkaran
    # track abu + arc biru berputar + ikon logo di tengah, ukuran &
    # warna identik) tapi SEMUANYA inline (`style="..."` + 1 tag
    # `<style>` mandiri utk `@keyframes`, BUKAN dari `chat.scss`) --
    # aman tampil kapan pun, tidak peduli CSS eksternal sudah ada atau
    # belum.
    showPreload: ->
      return if @preloadEl
      @preloadEl = $(@view('preload')())
      @options.target.append @preloadEl

    hidePreload: =>
      return if !@preloadEl
      @preloadEl.remove()
      @preloadEl = undefined

    renderBase: ->
      # Atas permintaan user ("dari mulai websocket terhubung sampai
      # page diload sempurna, diberi loading full page, gunakan
      # loading nya ablepro") -- ditampilkan di SINI (titik paling
      # awal `renderBase`, dipanggil dari `render()` = callback WS
      # `onOpen`, PERSIS titik "websocket terhubung" yg dimaksud user)
      # -- SEBELUM `@el` dibuat/disembunyikan di bawah, mengisi jendela
      # waktu yg SAMA yg sebelumnya cuma kosong polos. Dihilangkan lagi
      # di `onReady()` ("page diload sempurna" = KEDUA syarat terpenuhi,
      # status WS SUNGGUHAN diterima DAN CSS selesai, bukan cuma WS
      # terbuka).
      @showPreload()

      @el = $(@view('chat')(
        title: @options.title,
        scrollHint: @options.scrollHint
      ))
      # Bug ditemukan user (screen recording: HTML mentah tanpa style
      # SEMPAT tampil sekilas tiap widget dimuat) -- root cause: elemen
      # ini di-insert SEGERA begitu WebSocket terhubung (`render()`,
      # dipanggil dari `@io`'s `onOpen`), TIDAK PERNAH menunggu
      # `chat.css` (dimuat TERPISAH & ASINKRON lewat `loadCss()`,
      # SATU request ekstra lebih lambat drpd CSS biasa krn dibungkus
      # `@import` di dalam `data:` URL) selesai dimuat -- race condition
      # NYATA, WS SERING terhubung lebih dulu, jadi visitor sempat
      # lihat SEMUA `<div>`/`<button>` polos bertumpuk vertikal (gaya
      # default browser tanpa CSS sama sekali). Disembunyikan lewat
      # atribut `style` INLINE (BUKAN class -- justru stylesheet-nya
      # yang belum tentu ada) supaya berlaku SEKETIKA tanpa bergantung
      # ke CSS apa pun -- `onCssLoaded` di bawah yang membuka lagi.
      @el.css('display', 'none') if !@cssLoaded
      @options.target.append @el

      # Struktur baru (atas permintaan user): tombol bulat mengambang
      # TERPISAH dari panel -- SATU-SATUNYA elemen yang tampil saat
      # widget tertutup (meniru gaya Intercom/Claude), bukan pil header
      # yang bisa diklik seperti sebelumnya. `@el` (panel) TIDAK
      # diubah maknanya sama sekali -- tetap `.zammad-chat` seperti
      # dulu, supaya SEMUA `@el.find(...)` yang sudah ada di file ini
      # tidak perlu disentuh.
      @launcherEl = $(@view('launcher')())
      # Sama persis alasannya dgn `@el` di atas -- tombol bulat
      # mengambang ini JUSTRU elemen yg PALING kentara kalau tampil
      # tanpa style (default browser: kotak polos di sudut layar).
      @launcherEl.css('display', 'none') if !@cssLoaded
      @options.target.append @launcherEl
      @launcherEl.on 'click', @toggle

      @input = @el.find('.zammad-chat-input')

      # start bindings
      # Atas permintaan user -- tombol X di header ("exit") sekarang
      # mengakhiri chat (lihat `exitChat`), BUKAN lagi menyembunyikan
      # panel spt sebelumnya (itu sekarang KHUSUS tugas tombol
      # mengambang/`toggle()`, lihat `close()`).
      @el.find('.js-chat-close').on 'click', @exitChat
      # Atas permintaan user: tombol minimize BARU di header (KHUSUS
      # tampil di mobile, lihat CSS `.zammad-chat-header-icon-minimize`)
      # -- gantikan peran launcher yg disembunyikan saat panel terbuka
      # di mobile. `close()` (BUKAN `exitChat`) -- cuma menyembunyikan
      # panel, sesi TETAP jalan, persis perilaku launcher yg
      # digantikannya.
      @el.find('.js-chat-minimize').on 'click', @close
      # `.js-chat-status` sekarang jadi bagian dari `views/agent.eco`
      # (dot online di avatar) -- dirender ULANG setiap
      # `onConnectionEstablished`, TIDAK ADA di DOM statis sejak awal.
      # Didelegasikan dari `.zammad-chat-agent` (elemen statis, SELALU
      # ada meski masih kosong) supaya tetap kena walau isinya diganti
      # berkali-kali -- binding langsung di sini TIDAK AKAN PERNAH kena
      # elemen yang baru dirender belakangan.
      @el.find('.zammad-chat-agent').on 'click', '.js-chat-status', @stopPropagation
      @el.find('.zammad-chat-controls').on 'submit', @onSubmit
      @el.find('.zammad-chat-body').on 'scroll', @detectScrolledtoBottom
      @el.find('.zammad-scroll-hint').on 'click', @onScrollHintClick

      # Fitur tambahan "Reply ke Pesan Spesifik" -- Section 5.3.
      # Delegasi karena bubble pesan ditambahkan dinamis setelah render
      # awal ini.
      @el.find('.zammad-chat-body').on 'click', '.js-message-reply', @startReply
      @el.find('.js-reply-indicator').on 'click', '.js-reply-cancel', @cancelReply

      # Atas permintaan user (mockup `Waiting.dc.html`, koreksi "keluar
      # dari antrian kembali ke home") -- tombol Batalkan dirender ulang
      # tiap kali `.zammad-chat-modal` diisi ulang (loader/waiting/dst.,
      # pola yang sama seperti `.js-reply-cancel` di atas), jadi
      # didelegasikan dari `.zammad-chat-modal` sendiri (elemen statis).
      @el.find('.zammad-chat-modal').on 'click', '.js-waiting-cancel', @cancelQueue

      # Enhancement 1 -- Tahap 3 (Offline Message + OTP) -- delegasi
      # SAMA persis alasannya dgn `.js-waiting-cancel` di atas: 3 view
      # (`offline_otp`/`offline_compose`/`offline_sent`) gantian
      # mengisi `.zammad-chat-modal` yang SAMA.
      @el.find('.zammad-chat-modal').on 'click', '.js-otp-submit', @submitOfflineOtp
      @el.find('.zammad-chat-modal').on 'click', '.js-otp-resend', @resendOfflineOtp
      @el.find('.zammad-chat-modal').on 'click', '.js-otp-change-email', => @showPrechatForm()
      @el.find('.zammad-chat-modal').on 'input', '.js-otp-digit', @onOtpDigitInput
      @el.find('.zammad-chat-modal').on 'keydown', '.js-otp-digit', @onOtpDigitKeydown
      @el.find('.zammad-chat-modal').on 'paste', '.js-otp-digit', @onOtpDigitPaste
      @el.find('.zammad-chat-modal').on 'click', '.js-offline-compose-submit', @submitOfflineMessage
      @el.find('.zammad-chat-modal').on 'click', '.js-offline-sent-done', @finishOfflineFlow

      # Item lampiran OfflineCompose (follow-up terpisah dari
      # Enhancement 4 awal) -- delegasi sama persis alasannya.
      @el.find('.zammad-chat-modal').on 'click', '.js-offline-compose-attach', @triggerOfflineAttachmentInput
      @el.find('.zammad-chat-modal').on 'change', '.js-offline-compose-attachment-input', @uploadOfflineAttachment

      # Enhancement 2 -- Rating Kepuasan (Feedback). Delegasi sama
      # persis alasannya dgn blok Enhancement 1 di atas.
      # Delegasi ke `@el` (BUKAN `.zammad-chat-modal` lagi) -- semenjak
      # feedback bisa dirender INLINE di `.zammad-chat-body`
      # (`showFeedback(true)`, atas permintaan user "sematkan di
      # jendela chat"), delegasi ke `.zammad-chat-modal` tidak lagi
      # menangkap klik di kartu inline. `@el` aman utk kedua mode.
      @el.on 'click', '.js-feedback-star', @selectFeedbackScore
      @el.on 'click', '.js-feedback-submit', @submitFeedback
      @el.on 'click', '.js-feedback-skip', @skipFeedback

      # Fase 5 -- Item No. 6 (Attachment). Section 5.2.3.
      @el.find('.js-chat-attach').on 'click', @triggerAttachmentInput
      @el.find('.js-chat-attachment-input').on 'change', @uploadAttachment

      # Fase 7 -- Widget bergaya tab (Home/Messages/Help). Section 4.2/4.3.
      # Home & Help TIDAK PUNYA konten dinamis per-sesi (beda dari
      # `.zammad-chat-modal`, yang diisi ulang tiap state chat berubah)
      # -- cukup diisi SEKALI di sini, pola yang sama dipakai `.zammad-chat-agent`
      # (diisi lewat @view() saat kondisinya baru terjadi, bukan tiap render).
      @el.find('.zammad-chat-tab-body--home').html @view('home')()
      @el.find('.zammad-chat-tab-body--help').html @view('help')()
      @el.find('.zammad-chat-tabbar').html @view('tabbar')()
      @el.find('.js-emoji-picker').html @view('emoji_picker')()
      @activeTab = 'home'
      @updateHeader('home')

      # Delegasi (bukan dipasang ulang tiap render) -- tombol tab bar
      # (statis) & tombol pintasan tab Home (statis) SAMA-SAMA cukup
      # dikenali lewat atribut `data-tab` (Section 4.1: "reuse switch
      # tab, bukan event baru").
      #
      # Atas permintaan user ("loading pada button ... untuk tombol
      # pada halaman home dan offlineHome") -- KHUSUS tombol Home
      # (`.zammad-chat-home-actions button`, BUKAN tombol tab bar bawah
      # yg SAMA-SAMA cocok `[data-tab]`) dapat loading state. `switchTab`
      # SEPENUHNYA sinkron & TIDAK PERNAH menghancurkan/merender ulang
      # markup tab Home (cuma toggle class `is-active`, elemen tombol
      # ini TETAP ADA di DOM meski tersembunyi) -- BEDA dari tombol lain
      # (entri sebelumnya) yg re-render TOTAL saat pindah layar --
      # WAJIB dimatikan manual di sini (bukan diandalkan re-render),
      # kalau tidak status loading akan NYANGKUT begitu user kembali
      # ke tab Home.
      @el.on 'click', '[data-tab]', (event) =>
        target = $(event.currentTarget)
        isHomeAction = target.closest('.zammad-chat-home-actions').length > 0
        @setButtonLoading(target, true) if isHomeAction
        @switchTab target.data('tab')
        @setButtonLoading(target, false) if isHomeAction

      # Atas permintaan user (mockup fullpage "Connection lost") --
      # delegasi krn tombol ini cuma ada di DOM SETELAH
      # `showConnectionOverlay('lost')` menyuntik markup-nya, bukan
      # elemen statis sejak render awal.
      @el.on 'click', '.js-connection-reload', (event) =>
        window.location.reload()

      # Revisi desain (gaya Able Pro) -- ikon smile membuka/menutup
      # panel emoji; klik satu emoji menyisipkannya ke posisi kursor
      # terakhir di kotak ketik (`document.execCommand('insertText')`,
      # BUKAN cuma ditambahkan di akhir -- pola native yang sama dipakai
      # `document.execCommand('bold')` dkk. di handler richTextControl).
      @el.find('.js-emoji-toggle').on 'click', @toggleEmojiPicker
      @el.find('.js-emoji-picker').on 'click', '.js-emoji-item', (event) =>
        @insertEmoji $(event.currentTarget).data('emoji')

      # Bug ditemukan user (pencarian Help tidak pernah mengirim apa
      # pun walau sudah menunggu, dikonfirmasi via WebSocket mentah
      # bahwa backend genuinely benar) -- `updatePhrases()` (dipanggil
      # SETIAP `chat_status_customer`, TERMASUK yang PERTAMA kali
      # widget terhubung) mengganti TOTAL innerHTML
      # `.zammad-chat-tab-body--help` (`@view('help')()`), menghancurkan
      # elemen `.js-kb-search` ASLI yang listener ini terpasang -- input
      # BARU hasil render ulang itu TIDAK PERNAH punya listener sama
      # sekali, jadi mengetik apa pun tidak pernah mengirim WS event.
      # Diperbaiki jadi DELEGASI ke `@el` (pola yang SAMA dipakai
      # `[data-tab]` di atas) -- listener nempel ke elemen INDUK yang
      # stabil, bukan ke elemen input yang bisa hilang-timbul lewat
      # render ulang manapun.
      @el.on 'input', '.js-kb-search', @onKbSearchInput

      # `scroll` TIDAK bubbling -- didengarkan lewat FASE CAPTURE di
      # `@el` (elemen stabil), bukan didelegasikan biasa, supaya tetap
      # jalan walau `.zammad-chat-kb-results` dibongkar-pasang ulang.
      @el[0].addEventListener('scroll', @onKbResultsScroll, true)

      @input.on(
        keydown: @checkForEnter
        input: @onInput
      )
      @input.on('keydown', (e) =>
        richtTextControl = false
        if !e.altKey && !e.ctrlKey && e.metaKey
          richtTextControl = true
        else if !e.altKey && e.ctrlKey && !e.metaKey
          richtTextControl = true

        if richtTextControl && @richTextFormatKey[ e.keyCode ]
          e.preventDefault()
          if e.keyCode is 66
            document.execCommand('bold')
            return true
          if e.keyCode is 73
            document.execCommand('italic')
            return true
          if e.keyCode is 85
            document.execCommand('underline')
            return true
          if e.keyCode is 83
            document.execCommand('strikeThrough')
            return true
      )
      @input.on('paste', (e) =>
        e.stopPropagation()
        e.preventDefault()

        clipboardData
        if e.clipboardData
          clipboardData = e.clipboardData
        else if window.clipboardData
          clipboardData = window.clipboardData
        else if e.originalEvent.clipboardData
          clipboardData = e.originalEvent.clipboardData
        else
          throw 'No clipboardData support'

        imageInserted = false
        if clipboardData && clipboardData.items && clipboardData.items[0]
          item = clipboardData.items[0]
          if item.kind == 'file' && (item.type == 'image/png' || item.type == 'image/jpeg')
            imageFile = item.getAsFile()
            reader = new FileReader()

            reader.onload = (e) =>
              result = e.target.result
              img = document.createElement('img')
              img.src = result

              insert = (dataUrl, width, height, isRetina) =>

                # adapt image if we are on retina devices
                if @isRetina()
                  width = width / 2
                  height = height / 2
                result = dataUrl
                img = "<img style=\"width: 100%; max-width: #{width}px;\" src=\"#{result}\">"
                document.execCommand('insertHTML', false, img)

              # resize if to big
              @resizeImage(img.src, 460, 'auto', 2, 'image/jpeg', 'auto', insert)

            reader.readAsDataURL(imageFile)
            imageInserted = true

        return if imageInserted

        # check existing + paste text for limit
        text = undefined
        docType = undefined
        try
          text = clipboardData.getData('text/html')
          docType = 'html'
          if !text || text.length is 0
            docType = 'text'
            text = clipboardData.getData('text/plain')
          if !text || text.length is 0
            docType = 'text2'
            text = clipboardData.getData('text')
        catch e
          console.log('Sorry, can\'t insert markup because browser is not supporting it.')
          docType = 'text3'
          text = clipboardData.getData('text')

        if docType is 'text' || docType is 'text2' || docType is 'text3'
          text = '<div>' + text.replace(/\n/g, '</div><div>') + '</div>'
          text = text.replace(/<div><\/div>/g, '<div><br></div>')
        console.log('p', docType, text)
        if docType is 'html'
          sanitized = DOMPurify.sanitize(text)
          @log.debug 'sanitized HTML clipboard', sanitized
          html = $("<div>#{sanitized}</div>")
          match = false
          htmlTmp = text
          regex = new RegExp('<(/w|w)\:[A-Za-z]')
          if htmlTmp.match(regex)
            match = true
            htmlTmp = htmlTmp.replace(regex, '')
          regex = new RegExp('<(/o|o)\:[A-Za-z]')
          if htmlTmp.match(regex)
            match = true
            htmlTmp = htmlTmp.replace(regex, '')
          if match
            html = @wordFilter(html)
          #html

          html = $(html)

          html.contents().each( ->
            if @nodeType == 8
              $(@).remove()
          )

          # remove tags, keep content
          html.find('a, font, small, time, form, label').replaceWith( ->
            $(@).contents()
          )

          # replace tags with generic div
          # New type of the tag
          replacementTag = 'div';

          # Replace all x tags with the type of replacementTag
          html.find('textarea').each( ->
            outer = @outerHTML

            # Replace opening tag
            regex = new RegExp('<' + @tagName, 'i')
            newTag = outer.replace(regex, '<' + replacementTag)

            # Replace closing tag
            regex = new RegExp('</' + @tagName, 'i')
            newTag = newTag.replace(regex, '</' + replacementTag)

            $(@).replaceWith(newTag)
          )

          # remove tags & content
          html.find('font, img, svg, input, select, button, style, applet, embed, noframes, canvas, script, frame, iframe, meta, link, title, head, fieldset').remove()

          @removeAttributes(html)

          text = html.html()

        # as fallback, insert html via pasteHtmlAtCaret (for IE 11 and lower)
        if docType is 'text3'
          @pasteHtmlAtCaret(text)
        else
          document.execCommand('insertHTML', false, text)
        true
      )
      @input.on('drop', (e) =>
        e.stopPropagation()
        e.preventDefault()

        dataTransfer
        if window.dataTransfer # ie
          dataTransfer = window.dataTransfer
        else if e.originalEvent.dataTransfer # other browsers
          dataTransfer = e.originalEvent.dataTransfer
        else
          throw 'No clipboardData support'

        x = e.clientX
        y = e.clientY
        file = dataTransfer.files[0]

        # look for images
        if file.type.match('image.*')
          reader = new FileReader()
          reader.onload = (e) =>
            result = e.target.result
            img = document.createElement('img')
            img.src = result

            # Insert the image at the carat
            insert = (dataUrl, width, height, isRetina) =>

              # adapt image if we are on retina devices
              if @isRetina()
                width = width / 2
                height = height / 2

              result = dataUrl
              img = $("<img style=\"width: 100%; max-width: #{width}px;\" src=\"#{result}\">")
              img = img.get(0)

              if document.caretPositionFromPoint
                pos = document.caretPositionFromPoint(x, y)
                range = document.createRange()
                range.setStart(pos.offsetNode, pos.offset)
                range.collapse()
                range.insertNode(img)
              else if document.caretRangeFromPoint
                range = document.caretRangeFromPoint(x, y)
                range.insertNode(img)
              else
                console.log('could not find carat')

            # resize if to big
            @resizeImage(img.src, 460, 'auto', 2, 'image/jpeg', 'auto', insert)
          reader.readAsDataURL(file)
      )

      $(window).on('beforeunload', =>
        @onLeaveTemporary()
      )
      $(window).on('hashchange', =>
        if @isOpen
          if @sessionId
            @send 'chat_session_notice',
              session_id: @sessionId
              message: window.location.href
          return
        @idleTimeout.start()
      )

      if @isFullscreen
        @input.on
          focus: @onFocus
          focusout: @onFocusOut

    # Fase 7 -- Widget bergaya tab (Home/Messages/Help). Section 4.3.
    # Toggle class `is-active` -- pola yang SAMA seperti toggle
    # `zammad-chat-is-hidden` yang sudah dipakai di banyak tempat lain
    # di widget ini, bukan mekanisme baru.
    switchTab: (tabName) =>
      return if @activeTab is tabName
      @activeTab = tabName

      @el.find('.zammad-chat-tab-body').removeClass('is-active')
      @el.find(".zammad-chat-tab-body--#{tabName}").addClass('is-active')

      @el.find('.zammad-chat-tabbar-item').removeClass('is-active')
      @el.find(".zammad-chat-tabbar-item[data-tab='#{tabName}']").addClass('is-active')

      @updateHeader(tabName)

      # Atas permintaan user: tab Help langsung menampilkan artikel
      # (5 terbaru) begitu dibuka, TANPA perlu mengetik dulu -- cukup
      # sekali per sesi widget (`@kbLoaded` guard), bukan tiap kali
      # tab ini dibuka lagi.
      if tabName is 'help' and !@kbLoaded
        @kbLoaded = true
        @loadKnowledgeBase(true)

    # Revisi desain (identik referensi Intercom/Claude) -- isi header
    # BERBEDA per tab: Home gelap dengan sapaan besar, Messages/Help
    # putih dengan judul polos di tengah -- KECUALI tab Messages saat
    # ada agent yang sedang menangani (`@agent` terisi, lihat
    # onConnectionEstablished), header tetap menampilkan info agent
    # SAMA seperti sebelumnya, apa pun tab yang aktif saat itu terjadi.
    updateHeader: (tabName) =>
      tabName ?= @activeTab

      showAgent   = tabName is 'messages' and @agent?
      showWelcome = tabName is 'home' and !showAgent
      showTitle   = !showWelcome and !showAgent

      @el.find('.zammad-chat-header').toggleClass('zammad-chat-header--tinted', showWelcome)
      @el.find('.zammad-chat-welcome').toggleClass('zammad-chat-is-hidden', !showWelcome)
      # `.zammad-chat-agent-status` (dot online) sekarang dirender SEBAGAI
      # BAGIAN dari `.zammad-chat-agent` (views/agent.eco, di dalam
      # avatar) -- toggle induknya saja sudah cukup, tidak perlu
      # ditoggle terpisah lagi.
      @el.find('.zammad-chat-agent').toggleClass('zammad-chat-is-hidden', !showAgent)
      @el.find('.zammad-chat-header-title').toggleClass('zammad-chat-is-hidden', !showTitle)

      if showTitle
        title = if tabName is 'help' then @T('Help') else @T('Messages')
        @el.find('.js-header-title-text').text(title)

    # Revisi desain (gaya Able Pro) -- panel emoji, sama seperti
    # `.zammad-chat-modal` yang lain: TIDAK disembunyikan/ditampilkan
    # ulang tiap kali, cukup toggle `zammad-chat-is-hidden` (isinya
    # statis, dirender sekali di renderBase).
    toggleEmojiPicker: (event) =>
      event?.preventDefault()
      @el.find('.js-emoji-picker').toggleClass('zammad-chat-is-hidden')
      @el.find('.js-emoji-toggle').toggleClass('is-active')

    insertEmoji: (emoji) =>
      @input.trigger('focus')
      document.execCommand('insertText', false, emoji)
      @el.find('.js-emoji-picker').addClass('zammad-chat-is-hidden')
      @el.find('.js-emoji-toggle').removeClass('is-active')
      @onInput()

    # Fase 7 -- Tab Help, pencarian KB. Section 4.5. Debounce dengan
    # pola timer yang sama dipakai `onAgentTypingStart` (@stopTypingId)
    # -- supaya tidak kirim event WebSocket di SETIAP keystroke.
    #
    # Follow-up atas permintaan user: tab Help SEKARANG menampilkan
    # artikel (5 terbaru) BAHKAN TANPA mengetik apa pun (`@kbQuery`
    # kosong = mode "jelajahi"), mengetik di kolom cuma MEMFILTER
    # daftar yang sama (`@kbQuery` terisi = mode "cari"), dan halaman
    # berikutnya dimuat lewat SCROLL ke dasar daftar (bukan tombol/
    # nomor halaman) -- lihat `loadKnowledgeBase`/`onKbResultsScroll`.
    onKbSearchInput: (event) =>
      @kbQuery = $(event.currentTarget).val()?.trim() || ''

      if @kbSearchDelayId
        clearTimeout(@kbSearchDelayId)

      @kbSearchDelayId = setTimeout((=>
        @loadKnowledgeBase(true)
      ), 400)

    # `reset=true` -- mulai dari awal (ketikan baru/pembukaan tab Help
    # pertama kali), mengganti TOTAL daftar. `reset=false` -- "load
    # more" dipicu scroll, MENAMBAHKAN ke daftar yang sudah ada.
    loadKnowledgeBase: (reset) =>
      return if @kbLoading
      return if !reset and !@kbHasMore

      @kbOffset = 0 if reset
      @kbLoading = true
      @el.find('.zammad-chat-kb-loading').removeClass('zammad-chat-is-hidden')

      @send 'chat_knowledge_base_search',
        query: @kbQuery || ''
        offset: @kbOffset || 0

    onKnowledgeBaseSearchResult: (data) =>
      @kbLoading = false
      @el.find('.zammad-chat-kb-loading').addClass('zammad-chat-is-hidden')

      # Buang respons BASI -- bisa terjadi kalau user mengetik cepat
      # lalu balasan query SEBELUMNYA baru sampai belakangan, setelah
      # `@kbQuery` sendiri sudah berubah lagi.
      return if (data.query || '') isnt (@kbQuery || '')

      results     = @el.find('.zammad-chat-kb-results')
      isFirstPage = (data.offset || 0) is 0

      results.empty() if isFirstPage

      @kbHasMore = !!data.has_more
      @kbOffset  = (data.offset || 0) + (data.result?.length || 0)

      if isFirstPage and (!data.result || data.result.length is 0)
        @el.find('.zammad-chat-kb-empty').removeClass('zammad-chat-is-hidden')
        return

      @el.find('.zammad-chat-kb-empty').addClass('zammad-chat-is-hidden')
      for item in (data.result || [])
        results.append @view('kb_result')(item)

    # Dipicu scroll di dalam `.zammad-chat-kb-results` -- listener
    # dipasang di FASE CAPTURE pada `@el` (bukan didelegasikan biasa,
    # krn event `scroll` TIDAK bubbling) supaya TETAP jalan walau
    # elemen `.zammad-chat-kb-results` sendiri dibongkar-pasang ulang
    # lewat `updatePhrases()` (pola bug yang SAMA dgn `.js-kb-search`,
    # dihindari dgn cara yang sama: menempel ke elemen INDUK stabil).
    onKbResultsScroll: (event) =>
      return if !event.target.classList?.contains('zammad-chat-kb-results')
      el = event.target
      return if el.scrollTop + el.clientHeight < el.scrollHeight - 200
      @loadKnowledgeBase(false)

    stopPropagation: (event) ->
      event.stopPropagation()

    checkForEnter: (event) =>
      if not @inputDisabled and not event.shiftKey and event.keyCode is 13
        event.preventDefault()
        @sendMessage()

    send: (event, data = {}) =>
      data.chat_id = @options.chatId
      @io.send(event, data)

    onWebSocketMessage: (pipes) =>
      for pipe in pipes
        @log.debug 'ws:onmessage', pipe
        switch pipe.event
          when 'chat_error'
            @log.notice pipe.data
            if pipe.data && pipe.data.state is 'chat_disabled'
              @destroy(remove: true)
          when 'chat_session_message'
            return if pipe.data.self_written
            @receiveMessage pipe.data
          when 'chat_session_attachment'
            # Fase 5 -- Item No. 6. Server mem-broadcast ke KEDUA sisi
            # TERMASUK pengunggah sendiri (tidak ada self_written di
            # sini, beda dari chat_session_message) -- jadi render
            # dilakukan HANYA lewat jalur ini, tidak ada render optimis
            # terpisah saat upload.
            from = if pipe.data.message.created_by_id then 'agent' else 'customer'
            @addAttachmentMessage(pipe.data.message, from)
          when 'chat_session_typing'
            return if pipe.data.self_written
            @onAgentTypingStart()
          when 'chat_session_start'
            @onConnectionEstablished pipe.data
          when 'chat_session_queue'
            @onQueueScreen pipe.data
          when 'chat_session_init'
            # Fase 5 -- server menolak (nama/email tidak valid, lihat
            # showPrechatForm di atas) -- munculkan lagi form pra-chat
            # dengan pesan error, jangan biarkan loader berputar terus.
            if pipe.data.state is 'failed'
              @showPrechatForm(error: pipe.data.message)
          when 'chat_session_closed'
            @onSessionClosed pipe.data
          when 'chat_session_left'
            @onSessionClosed pipe.data
          when 'chat_session_notice'
            @addStatus @T(pipe.data.message)
          # Atas permintaan user (mockup `Messages.dc.html`): penanda
          # "sudah dibaca" ala WhatsApp -- dikirim server (lihat
          # `chat_session_message_read.rb`) begitu agent fokus/klik ke
          # jendela chat (`clearUnread()` di
          # app/assets/javascripts/app/controllers/chat.coffee). Tidak
          # ada `self_written` di broadcast ini (beda dari event lain
          # spt `chat_session_message`) krn yang mengirim ADALAH agent,
          # widget customer di sini SELALU jadi penerima, tidak pernah
          # jadi pengirimnya sendiri.
          when 'chat_session_message_read'
            @markMessagesRead()
          when 'chat_knowledge_base_search'
            @onKnowledgeBaseSearchResult pipe.data
          # Enhancement 1 -- Tahap 3 (Offline Message + OTP). Balasan
          # 4 event WS baru (`lib/sessions/event/chat_offline_*.rb`).
          when 'chat_offline_session_init'
            @onOfflineSessionInitResult pipe.data
          when 'chat_offline_otp_verify'
            @onOfflineOtpVerifyResult pipe.data
          when 'chat_offline_otp_resend'
            @onOfflineOtpResendResult pipe.data
          when 'chat_offline_message_send'
            @onOfflineMessageSendResult pipe.data
          # Enhancement 2 -- Rating Kepuasan (Feedback), direlasikan
          # dgn CSAT Fase 1 (`lib/sessions/event/
          # chat_session_feedback_submit.rb`).
          when 'chat_session_feedback_submit'
            @onFeedbackSubmitResult pipe.data
          when 'chat_status_customer'
            # Atas permintaan user ("logo pada home mengambil dari
            # setting logo zammad") -- disertakan di SEMUA state
            # respons ini (bukan cuma 'online'), backend sudah
            # menggabungkannya (`chat_status_customer.rb`).
            #
            # Bug ditemukan user ("logo home dan offlineHome satu
            # sumber dgn logo aplikasi") -- logo custom di sini TIDAK
            # PERNAH benar2 tampil krn `updatePhrases()` (dipanggil
            # SETELAH baris ini, tiap `chat_status_customer` termasuk
            # reconnect) menggambar ULANG TOTAL tab Home dari template
            # mentah (`@view('home')()`, ikon default hardcode) --
            # menghapus `<img>` yg baru saja disisipkan. Pola SAMA
            # persis dgn bug KB search entri 176 & notice offline
            # entri 161 (render ulang menghapus perubahan yg baru
            # ditempel). Diperbaiki: URL disimpan persisten (`@logoUrl`,
            # pola sama dgn `@phrases`), dipasang ULANG di akhir
            # `updatePhrases()` (SETELAH render ulang tab Home terjadi
            # di sana) -- bukan cuma di sini.
            @logoUrl = pipe.data.logo_url if pipe.data.logo_url
            @updateHomeLogo(@logoUrl) if @logoUrl
            # Bug ditemukan user ("notice muncul padahal ada agent
            # online") -- SEBELUMNYA `@offlineMode` cuma di-set `true`
            # di dalam `enterOfflineMode()` (case 'offline' di bawah),
            # TIDAK PERNAH di-set balik `false` di case 'online' manapun
            # -- jadi begitu widget PERNAH offline sekali, `@offlineMode`
            # nyangkut `true` SELAMANYA, dan `applyOfflineHomeState()`
            # (dipanggil dari `updatePhrases` TIAP status response, lihat
            # entri 160) akan TERUS memaksa tampilan offline pada
            # RECONNECT manapun berikutnya, WALAU agent SUDAH online lagi
            # sungguhan. Diperbaiki: `@offlineMode` SEKARANG ditentukan
            # ULANG di sini, LANGSUNG dari state respons yg BARU datang
            # -- SEBELUM `updatePhrases` (yg memakai nilai ini) dipanggil,
            # supaya kedua ARAH transisi (offline->online MAUPUN
            # online->offline) sama2 benar, bukan cuma satu arah.
            @offlineMode = pipe.data.state is 'offline'
            # Atas permintaan user: tombol launcher (ikon mengambang,
            # SELALU terpisah dari `@el`, lihat `renderBase`) jadi
            # abu-abu saat offline. `@launcherEl` TIDAK PERNAH digambar
            # ulang (beda dari tab Home di dalam `@el`), jadi toggle
            # EKSPLISIT di SINI langsung dari `@offlineMode` -- bukan
            # dari `applyOfflineHomeState` (yg cuma jalan pas offline,
            # early-return kalau tidak, tidak bisa dipakai utk
            # membersihkan arah balik ke online).
            @launcherEl?.toggleClass('zammad-chat-launcher--offline', @offlineMode)
            @updatePhrases(pipe.data.phrases) if pipe.data.phrases
            # Bug ditemukan user (screenshot: loading full-page entri
            # 193 NYANGKUT SELAMANYA) -- root cause: `hidePreload()`
            # sebelumnya cuma dipasang di `onReady()`, TAPI `onReady()`
            # (lihat blok `switch` di bawah) HANYA PERNAH dipanggil utk
            # state 'online' -- state 'offline' (SEMUA agent tidak
            # tersedia, kemungkinan besar kondisi lingkungan pengujian
            # user) TIDAK PERNAH memanggil `onReady()` sama sekali, gap
            # LAMA yg sudah ada SEBELUM fitur loading ini (sebelumnya
            # tidak kentara krn `onReady()` cuma mengurus tombol
            # EKSTERNAL, `@launcherEl` sendiri sudah bisa diklik
            # independen sejak `renderBase()`). `@statusReceived`
            # (BARU, SENGAJA terpisah dari `@socketReady` yg tetap
            # exclusive utk 'online' -- TIDAK diubah, hindari resiko
            # regresi ke perilaku tombol eksternal yg sudah ada) SEKARANG
            # ditandai di SINI, SEBELUM `switch`, jadi berlaku utk STATUS
            # APA PUN (online/offline/dst) -- "page diload sempurna"
            # SEHARUSNYA berarti "status APA PUN sudah diterima", bukan
            # sempit "ada agent online".
            @statusReceived = true
            @hidePreload() if @cssLoaded
            switch pipe.data.state
              when 'online'
                # `setSessionId undefined` (BUKAN cuma `@sessionId =
                # undefined` spt sebelumnya) -- lihat catatan panjang
                # di case 'offline' di bawah, alasan yg SAMA berlaku
                # di sini juga (bersihkan `sessionStorage`, bukan cuma
                # variabel in-memory).
                @setSessionId undefined

                if !@options.cssAutoload || @cssLoaded
                  @onReady()
                else
                  @socketReady = true
              when 'offline'
                # Enhancement 1 -- Tahap 3. SEBELUMNYA method ini
                # (`@onError`) MENGHANCURKAN widget total
                # (`@destroy`) begitu tidak ada agent online --
                # sekarang widget TETAP tampil, cuma alur Home-nya
                # diganti ke "Leave us a message" (OTP+pesan offline)
                # lewat `enterOfflineMode()`, bukan mati total.
                #
                # Bug ditemukan user (simulasi manual: masuk ke OTP,
                # HARD REFRESH) -- `@sessionId` sisa dari sesi offline
                # LAMA (state `offline_pending`, `session_id` sudah
                # disimpan `sessionStorage` sejak `chat_offline_
                # session_init`, lihat `onOfflineSessionInitResult`)
                # TIDAK PERNAH dibersihkan di sini, beda dari case
                # 'online' di atas yg SUDAH lebih dulu membersihkannya.
                # Backend (`Chat.customer_state`) SENGAJA cuma
                # menganggap `state: %w[waiting running]` sbg
                # reconnect valid -- sesi `offline_pending` TIDAK
                # PERNAH match, jatuh ke sini ('offline'), tapi
                # frontend tetap menyimpan `@sessionId` basi itu.
                # Akibatnya: `open()`'s `if @sessionId` (dipakai utk
                # tahu "ada chat SEDANG BERJALAN, reconnect ke situ")
                # salah kira sesi offline BELUM-terverifikasi ini
                # sbg chat sungguhan, lempar visitor ke tab Messages
                # KOSONG (kotak ketik chat biasa) alih-alih mulai
                # ulang dari Home spt yang didesain ("reload di tengah
                # OTP/compose cukup mulai ulang dari Home").
                @setSessionId undefined
                @enterOfflineMode()
              when 'chat_disabled'
                @onError 'Zammad Chat: Chat is disabled'
              when 'no_seats_available'
                @onError "Zammad Chat: Too many clients in queue. Clients in queue: #{pipe.data.queue}"
              when 'reconnect'
                @onReopenSession pipe.data

    onReady: ->
      @log.debug 'widget ready for use'
      # Atas permintaan user (loading full page) -- `onReady` HANYA
      # jalan setelah KEDUA syarat terpenuhi (status WS diterima DAN
      # CSS selesai dimuat, lihat pemanggil method ini), titik PALING
      # tepat utk anggap "page diload sempurna".
      @hidePreload()
      $(".#{ @options.buttonClass }").on('click', @open).removeClass(@options.inactiveClass)

      @options.onReady?()

      if @options.show
        @show()

    onError: (message) =>
      @log.debug message
      # Jaga-jaga (bukan jalur utama) -- kalau widget GAGAL total
      # sebelum sempat "ready" (mis. chat dinonaktifkan), placeholder
      # loading jangan sampai nyangkut selamanya di layar.
      @hidePreload()
      @addStatus(message)
      $(".#{ @options.buttonClass }").hide()
      if @isOpen
        @disableInput()
        @destroy(remove: false)
      else
        @destroy(remove: true)

      @options.onError?(message)

    onReopenSession: (data) =>
      # Bug ditemukan user (loading full page tidak pernah hilang) --
      # state 'reconnect' (sesi lama ditemukan lagi) jatuh ke sini,
      # sama seperti 'offline' di `enterOfflineMode()`, TIDAK PERNAH
      # memanggil `hidePreload()` sebelumnya.
      @hidePreload()
      @log.debug 'old messages', data.session
      @inactiveTimeout.start()

      unfinishedMessage = sessionStorage.getItem 'unfinished_message'

      # rerender chat history
      if data.agent
        # `showGreeting: false` -- sesi LAMA digambar ulang (reload
        # halaman), bukan sesi baru, sapaan otomatis TIDAK diulang.
        @onConnectionEstablished(data, false)

        # Bug ditemukan lewat laporan user (hard refresh Ctrl+Shift+R
        # -> jam pesan hilang dari SEMUA riwayat percakapan) -- field
        # `time` ditambahkan ke `sendMessage`/`receiveMessage` (entri
        # 124-125) TAPI TERLEWAT di jalur riwayat/reconnect ini -- titik
        # ke-3 yang merender `message.eco`, tidak ikut ke-update
        # sebelumnya. (`avatarInitials` yg DULU ikut dihitung di sini
        # SUDAH DIHAPUS -- avatar per-pesan tidak lagi ada di markup,
        # lihat perbaikan avatar-dihapus/jam-di-dalam-bubble.)
        for message in data.session
          isAgentMessage = !!message.created_by_id
          time = @formatTime(message.created_at)

          # Bug KEDUA ditemukan lewat pengujian LANGSUNG (bukan laporan
          # user) saat menyiapkan reply-pada-attachment: pesan
          # attachment di riwayat SEBELUMNYA selalu di-render lewat
          # `@renderMessage` (`message.eco`, template TEKS biasa) --
          # tampil sbg bubble berbunyi literal "[attachment]" (isi
          # kolom `content` apa adanya) TANPA link unduh sama sekali.
          # `filename` (backend baru menyertakan ini, lihat
          # `Chat::Session.enrich_message_attributes`) dipakai sbg
          # penanda "pesan ini attachment" -- kalau ada, render lewat
          # `attachment_message.eco` (view+URL yang SAMA dgn
          # `addAttachmentMessage`), bukan sbg teks.
          # Atas permintaan user (mockup `Messages.dc.html`): penanda
          # "terkirim"/"sudah dibaca" -- dibutuhkan JUGA di jalur
          # riwayat ini (bukan cuma real-time), sesuai disiplin proyek
          # ini (lihat bug-bug serupa di entri 124-131). `read_at`
          # otomatis ikut ke `message.attributes` (kolom asli tabel,
          # TIDAK perlu enrichment tambahan di backend spt `reply_to`/
          # `filename`).
          isRead = !!message.read_at

          if message.filename
            @el.find('.zammad-chat-body').append @view('attachment_message')(
              from: if isAgentMessage then 'agent' else 'customer'
              id: message.id
              filename: message.filename
              metaLabel: @attachmentMeta(message.filename, message.size)
              url: "#{@apiBaseUrl()}/api/v1/chat_sessions/#{@sessionId}/attachments/#{message.id}"
              unreadClass: ''
              time: time
              isRead: isRead
            )
          else
            @renderMessage
              message: message.content
              id: message.id
              from: if isAgentMessage then 'agent' else 'customer'
              time: time
              isRead: isRead
              # Bug ke-3 ditemukan lewat laporan user (screenshot:
              # kutipan "Membalas: ..." hilang dari bubble setelah
              # reload) -- `replyTo` TIDAK PERNAH disertakan sama
              # sekali di loop ini (beda dari `receiveMessage` yg
              # sudah pakai `data.message.reply_to?.content` sejak
              # Fase 5). Backend (`messages_by_session_id`) SEKARANG
              # JUGA menyertakan `reply_to.content`, field ini tinggal
              # dipakai.
              replyTo: message.reply_to?.content

          # Bug ke-2 ditemukan lewat simulasi LANGSUNG diminta user
          # (hard refresh lalu klik ikon reply) -- ikon reply TETAP
          # tampil (markup-nya tidak bergantung ke ini) tapi TIDAK
          # BERFUNGSI SAMA SEKALI setelah reload: `startReply` cuma
          # baca `@agentMessagesById[messageId]` (diisi HANYA oleh
          # `receiveMessage`, jalur real-time), balik `undefined` utk
          # SEMUA pesan hasil replay riwayat ini -> `return if
          # !message` diam-diam gagal tanpa error apa pun. Diisi juga
          # di sini, sama persis dgn yang dilakukan `receiveMessage`.
          @agentMessagesById[message.id] = message if isAgentMessage and message.id

        if unfinishedMessage
          @input.html(unfinishedMessage)

      # show wait list
      if data.position
        @onQueue data

      # Bug ditemukan lewat pengujian sendiri (bukan laporan user) --
      # method ini SEBELUMNYA SELALU memaksa panel terbuka lagi
      # (`@show(); @open()`), dirancang utk skenario RELOAD HALAMAN
      # (customer refresh browser, wajar panel harus muncul lagi
      # menampilkan sesi yang masih berjalan). TAPI reconnect yang SAMA
      # ini JUGA terpicu tiap kali panel diminimize (`close()` ->
      # `onCloseAnimationEnd` -> `@io.reconnect()`) SEKARANG bahwa
      # minimize TIDAK LAGI mengakhiri sesi (lihat `close()`) -- tanpa
      # guard di bawah, klik tombol minimize akan langsung "gagal"
      # (panel kebuka paksa lagi beberapa saat kemudian).
      #
      # `@show()` HARUS TETAP dipanggil tanpa syarat: itu yang
      # mengembalikan class `zammad-chat-is-shown`/`is-loaded` pada
      # `@launcherEl` (tombol mengambang), yang barusan DIHAPUS oleh
      # `onWebSocketClose` di tengah siklus reconnect ini (bug KETIGA,
      # ditemukan lewat pengujian Playwright: tanpa ini tombol
      # launcher-nya sendiri jadi tidak kelihatan/tidak bisa diklik
      # lagi setelah minimize). Yang di-skip pas minimize HANYA
      # paksa-buka PANEL-nya (`@open()`/`@scrollToBottom()`).
      @show()
      if !@minimizedWithSession
        @open()
        @scrollToBottom()

      if unfinishedMessage
        @input.trigger('focus')

    onInput: =>
      # remove unread-state from messages
      @el.find('.zammad-chat-message--unread')
        .removeClass 'zammad-chat-message--unread'

      sessionStorage.setItem 'unfinished_message', @input.html()

      @onTyping()

    onFocus: =>
      $(window).scrollTop(10)
      keyboardShown = $(window).scrollTop() > 0
      $(window).scrollTop(0)

      if keyboardShown
        @log.notice 'virtual keyboard shown'
        # on keyboard shown
        # can't measure visible area height :(

    onFocusOut: ->
      # on keyboard hidden

    onTyping: ->

      # send typing start event only every 1.5 seconds
      return if @isTyping && @isTyping > new Date(new Date().getTime() - 1500)
      @isTyping = new Date()
      @send 'chat_session_typing',
        session_id: @sessionId
      @inactiveTimeout.start()

    onSubmit: (event) =>
      event.preventDefault()
      @sendMessage()

    sendMessage: ->
      message = @input.html()
      return if !message

      @inactiveTimeout.start()

      sessionStorage.removeItem 'unfinished_message'

      # Fitur tambahan "Reply ke Pesan Spesifik" -- Section 5.3.
      replyToId = @replyTo?.id
      replyToSnippet = @replyTo?.content

      messageElement = @view('message')
        message: message
        from: 'customer'
        id: @_messageCount++
        unreadClass: ''
        replyTo: replyToSnippet
        time: @formatTime()

      @maybeAddTimestamp()

      # add message before message typing loader
      if @el.find('.zammad-chat-message--typing').get(0)
        @lastAddedType = 'typing-placeholder'
        @el.find('.zammad-chat-message--typing').before messageElement
      else
        @lastAddedType = 'message--customer'
        @el.find('.zammad-chat-body').append messageElement

      @input.html('')
      @scrollToBottom()

      # send message event
      data =
        content: message
        id: @_messageCount
        session_id: @sessionId
      data.reply_to_id = replyToId if replyToId
      @send 'chat_session_message', data

      @cancelReply()

    receiveMessage: (data) =>
      @inactiveTimeout.start()

      # hide writing indicator
      @onAgentTypingEnd()

      @maybeAddTimestamp()

      # Fitur tambahan "Reply ke Pesan Spesifik" -- Section 5.3. Cuma
      # pesan dari AGENT (id server sungguhan) yang bisa jadi target
      # balasan customer nanti.
      @agentMessagesById[data.message.id] = data.message if data.message.id

      @renderMessage
        message: data.message.content
        id: data.message.id
        from: 'agent'
        replyTo: data.message.reply_to?.content
        time: @formatTime(data.message.created_at)

      @scrollToBottom showHint: true

      # Atas permintaan user ("mau ada sound juga seperti di agent") --
      # mirror `App.ChatWindow#receiveMessage` (`app/assets/javascripts/
      # app/controllers/chat.coffee`, sisi agent) yg memutar
      # `chat_message.mp3` saat pesan customer masuk DAN jendela chat
      # sedang tidak difokuskan. Kondisi sepadan di sini: tab browser
      # tidak aktif (`document.hidden`, SAMA persis dgn penanda
      # "unread" di `renderMessage`) ATAU panel widget sedang minimize
      # (`!@isOpen`) -- kalau customer genuinely sedang melihat
      # percakapan, tidak perlu bunyi.
      @playMessageSound()

    # File suara SAMA PERSIS dgn sisi agent (`public/assets/sounds/
    # chat_message.mp3`, sudah ada di server, bukan aset baru). URL
    # dibangun ABSOLUT via `apiBaseUrl()` (BUKAN path relatif) karena
    # widget di-embed lintas-domain di website customer -- path
    # relatif akan salah resolve ke domain website customer, bukan
    # domain Zammad.
    playMessageSound: =>
      return if !document.hidden and @isOpen
      @messageSound ?= new Audio("#{@apiBaseUrl()}/assets/sounds/chat_message.mp3")
      playPromise = @messageSound.play()
      playPromise?.catch (e) =>
        @log.debug 'playMessageSound: diblokir kebijakan autoplay browser', e

    renderMessage: (data) =>
      @lastAddedType = "message--#{ data.from }"
      data.unreadClass = if document.hidden then ' zammad-chat-message--unread' else ''
      @el.find('.zammad-chat-body').append @view('message')(data)

    # Fitur tambahan "Reply ke Pesan Spesifik (Seperti WhatsApp)" --
    # docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.3.
    startReply: (event) =>
      event.preventDefault()
      messageId = $(event.currentTarget).closest('.zammad-chat-message').data('message-id')
      return if !messageId
      message = @agentMessagesById[messageId]
      return if !message

      # Atas permintaan user (screenshot: kutipan reply ke pesan
      # attachment menampilkan literal "[attachment]") -- `message.content`
      # utk pesan attachment SELALU literal string itu (kolom `content`
      # di DB memang begitu, lihat `chat_attachments_controller.rb`),
      # nama file ASLI ada di `message.filename` (diisi
      # `addAttachmentMessage`/`onReopenSession`, lihat entri 131).
      @replyTo = { id: messageId, content: message.filename || message.content }
      @renderReplyIndicator()
      @input.trigger('focus')

    cancelReply: (event) =>
      event?.preventDefault()
      @replyTo = null
      @renderReplyIndicator()

    renderReplyIndicator: =>
      indicator = @el.find('.js-reply-indicator')
      if !@replyTo
        indicator.addClass('zammad-chat-is-hidden').html('')
        return

      snippet = @replyTo.content.replace(/<[^>]*>/g, '').substr(0, 80)
      indicator.removeClass('zammad-chat-is-hidden').html @view('reply_indicator')(
        snippet: snippet
      )

    # Fase 5 -- Item No. 6 (Attachment). Section 5.2.3.
    triggerAttachmentInput: (event) =>
      event.preventDefault()
      @el.find('.js-chat-attachment-input').trigger('click')

    uploadAttachment: (event) =>
      file = event.currentTarget.files?[0]
      return if !file

      formData = new FormData()
      formData.append('File', file)

      $.ajax
        type: 'POST'
        url: "#{@apiBaseUrl()}/api/v1/chat_sessions/#{@sessionId}/attachments"
        data: formData
        processData: false
        contentType: false
        cache: false
        error: (xhr) =>
          message = xhr.responseJSON?.error || @T(@phrases['chat_phrase_attachment_upload_error'] || 'The attachment could not be uploaded.')
          @addStatus(message)

      @el.find('.js-chat-attachment-input').val('')

    # Bug ditemukan lewat laporan user ("kenapa pada attachment tidak
    # terdapat reply?") -- `attachment_message.eco` TIDAK PERNAH ikut
    # diberi ikon-reply/jam saat keduanya ditambahkan ke `message.eco`
    # (entri 124-125) -- pesan attachment jadi tampil "yatim"
    # (mengambang tanpa jam, TIDAK BISA dibalas) dibanding pesan teks
    # biasa. Disamakan strukturnya: `id` (dibutuhkan `startReply` &
    # `data-message-id`), `time` (dari `created_at` ASLI server, `data`
    # di sini adalah `chat_message.attributes` lengkap -- lihat
    # `chat_attachments_controller.rb`).
    addAttachmentMessage: (data, from) =>
      @maybeAddTimestamp()
      @lastAddedType = "message--#{ from }"
      @el.find('.zammad-chat-body').append @view('attachment_message')(
        from: from
        id: data.id
        filename: data.filename
        metaLabel: @attachmentMeta(data.filename, data.size)
        url: "#{@apiBaseUrl()}/api/v1/chat_sessions/#{@sessionId}/attachments/#{data.id}"
        unreadClass: if document.hidden then ' zammad-chat-message--unread' else ''
        time: @formatTime(data.created_at)
      )
      # Reply ke pesan attachment mereferensikan `content` (server
      # SELALU set `'[attachment]'` utk jenis pesan ini, lihat
      # `chat_attachments_controller.rb`) -- diisi persis spt
      # `receiveMessage` isi utk pesan agent yg bisa jadi target reply.
      @agentMessagesById[data.id] = data if from is 'agent' and data.id
      @scrollToBottom showHint: true

    open: =>
      if @isOpen
        @log.debug 'widget already open, block'
        return

      # Dibalik lagi begitu user SENDIRI yang membuka panel -- lihat
      # penjelasan lengkap di `close()`.
      @minimizedWithSession = false

      @isOpen = true
      @log.debug 'open widget'
      @show()

      if @sessionId
        # Fase 7 -- ada sesi chat yang sedang berjalan (reconnect) --
        # langsung ke tab Messages supaya visitor tidak kehilangan
        # percakapannya sendiri di balik tab Home. Section 4.3.
        @switchTab('messages')
      else
        # Revisi desain (gaya Able Pro) -- form pra-chat (nama+email)
        # langsung mengisi `.zammad-chat-modal` di sini, SEBELUM
        # visitor pindah ke tab Messages -- bukan menunggu klik tombol
        # tersendiri. Kalau nanti visitor pindah tab (lewat tombol Home
        # ATAU tab bar), tab Messages SUDAH berisi form ini, tidak perlu
        # mekanisme "status kosong" terpisah lagi.
        @showPrechatForm()

      # Fase 7 -- struktur baru "tombol bulat mengambang + panel
      # terpisah" (atas permintaan user, meniru gaya Intercom/Claude) --
      # panel (@el) dan tombol (@launcherEl) SAMA-SAMA cukup diberi
      # class `zammad-chat-is-open`, transisi tampil/sembunyi (opacity+
      # transform) MURNI CSS lewat class ini (lihat chat.scss), TIDAK
      # ADA lagi animasi geser posisi `bottom` manual seperti
      # sebelumnya -- tidak dibutuhkan lagi karena panel sekarang
      # SELALU tersembunyi total saat tertutup (bukan menyisakan
      # header mengambang), bukan cuma digeser sebagian ke luar layar.
      @launcherEl.addClass('zammad-chat-is-open')
      @el.addClass('zammad-chat-is-open')
      @el.one('transitionend', @onOpenAnimationEnd)

    # Fase 5 -- Item No. 5 (Auto-Create Ticket). See
    # docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.1.1. Nama & email
    # SEKARANG WAJIB diisi SEBELUM `chat_session_init` dikirim -- server
    # (lib/sessions/event/chat_session_init.rb) menolak sesi yang tidak
    # membawa keduanya, jadi widget TIDAK BOLEH lagi mengirim
    # chat_session_init segera saat dibuka seperti sebelumnya.
    showPrechatForm: (params = {}) =>
      @el.find('.zammad-chat-modal').html @view('prechat')(
        error: params.error
        notice: params.notice
        name: params.name
        email: params.email
      )
      @el.find('.zammad-chat-prechat-form').on 'submit', @submitPrechatForm
      # Logo custom (lihat catatan panjang di `updateHomeLogo` &
      # handler `chat_status_customer`) -- `.zammad-chat-prechat-icon`
      # BARU SAJA digambar ulang dari template mentah di atas, pasang
      # ULANG di sini, pola SAMA dgn `updatePhrases()`.
      @updateHomeLogo(@logoUrl) if @logoUrl

    # Atas permintaan user ("Start Chat/Verify/Send Message/Continue/
    # Submit/Maybe Later -- loading pada button, gunakan loading button
    # ablepro") -- helper BERSAMA dipakai ke-6 tombol (bukan diulang
    # per-tombol). Bungkus label ASLI (apa pun isinya, termasuk ikon
    # svg di dalamnya spt "Start Chat") ke `<span>` SEKALI SAJA
    # (`wrapInner`, dicek dulu belum pernah dibungkus -- aman dipanggil
    # berkali-kali), lalu toggle class `is-loading` (CSS yg
    # menyembunyikan/menampilkan via `opacity`, lihat chat.scss) --
    # markup ASLI tombol TIDAK PERNAH dihapus/diganti, cuma
    # disembunyikan, jadi mematikan loading TIDAK PERNAH kehilangan
    # teks/ikon aslinya.
    setButtonLoading: (button, loading) =>
      return if !button? or !button.length
      if loading
        if !button.find('.zammad-chat-btn-label').length
          button.wrapInner('<span class="zammad-chat-btn-label"></span>')
          button.append('<span class="zammad-chat-btn-loader" aria-hidden="true"><svg viewBox="0 0 50 50"><circle cx="25" cy="25" r="20"/></svg></span>')
        button.addClass('is-loading').prop('disabled', true)
      else
        button.removeClass('is-loading').prop('disabled', false)

    submitPrechatForm: (event) =>
      event.preventDefault()

      name  = @el.find('.zammad-chat-prechat-name').val()?.trim()
      email = @el.find('.zammad-chat-prechat-email').val()?.trim()

      emailFormat = /^[^@\s]+@[^@\s]+\.[^@\s]+$/
      if !name || !email || !emailFormat.test(email)
        @showPrechatForm
          error: @T(@phrases['chat_phrase_prechat_validation_error'] || 'Please provide a valid name and email address.')
          name:  name
          email: email
        return

      # Tidak perlu dimatikan manual (`setButtonLoading(..., false)`)
      # di outcome APA PUN -- SEMUA jalur setelah ini (`@showLoader()`
      # utk online, ATAU respons offline sukses/gagal via
      # `onOfflineSessionInitResult`) me-render ULANG TOTAL
      # `.zammad-chat-modal` dgn markup BARU, otomatis membuang tombol
      # lama beserta status loading-nya.
      @setButtonLoading(@el.find('.zammad-chat-prechat-submit'), true)

      # Dipakai lagi nanti utk avatar inisial di bubble pesan sendiri
      # (views/message.eco) -- tidak pernah disimpan sebelumnya, cuma
      # dikirim ke server & dibuang. Disimpan JUGA ke `sessionStorage`
      # (pola sama dgn `sessionId`) -- bug ditemukan lewat laporan user
      # (hard refresh Ctrl+Shift+R menghilangkan avatar & jam pesan):
      # `@customerName` cuma variabel JS di memori, HILANG total saat
      # reload, padahal `onReopenSession` (riwayat pesan setelah
      # reconnect) butuh nama ini utk avatar inisial pesan customer
      # sendiri -- server sendiri TIDAK PERNAH mengirim balik nama
      # customer di payload reconnect (dicek ke
      # `Chat#customer_state`), jadi HARUS disimpan sendiri di sisi
      # client.
      @customerName = name
      sessionStorage.setItem 'customerName', name
      # Enhancement 1 -- Tahap 3. Dipakai layar OTP/compose/sent
      # (`showOfflineOtp` dst.) utk menampilkan "kode dikirim ke
      # ...". TIDAK disimpan ke sessionStorage spt `customerName` --
      # alur offline ini SENGAJA tidak dirancang bertahan lewat hard
      # refresh (reload di tengah OTP cukup mulai ulang dari Home,
      # konsisten dgn mockup yg juga tidak punya skenario "resume").
      @customerEmail = email

      # Enhancement 1 -- Tahap 3. Form pra-chat ini DIPAKAI ULANG APA
      # ADANYA (markup/validasi di atas TIDAK BERUBAH sama sekali,
      # sesuai keputusan reuse) -- yang beda cuma KEMANA hasilnya
      # dikirim. `@showLoader()` (spinner "Menghubungkan ke agent…")
      # SENGAJA DILEWATI utk jalur offline -- teksnya menyesatkan
      # (tidak ada agent yang dihubungkan), dan verifikasi OTP toh
      # bukan proses instan yang butuh spinner terpisah -- layar
      # OTP tampil begitu balasan server datang.
      if @offlineMode
        @send('chat_offline_session_init'
          url:   window.location.href
          name:  name
          email: email
        )
      else
        @showLoader()
        @send('chat_session_init'
          url: window.location.href
          name: name
          email: email
        )

    # ============================================================
    # Enhancement 1 -- Tahap 3: Offline Message + Verifikasi OTP.
    # Mockup: OfflineHome/OfflineOtp/OfflineCompose/OfflineSent
    # (.dc.html). Semua layar SETELAH form pra-chat (yang di-reuse
    # apa adanya, lihat `submitPrechatForm` di atas) dirender ke
    # `.zammad-chat-modal` yang sama, pola SAMA persis dgn
    # loader/waiting/prechat yang sudah ada.
    # ============================================================

    # Dipicu `chat_status_customer` state 'offline' (SEMUA agent tidak
    # tersedia, termasuk yg AUX -- entri 143). Payload ini bisa datang
    # BERULANG (`Io`'s `onOpen: @render` -- WS reconnect kapan saja,
    # bukan cuma sekali per widget dimuat, lihat catatan panjang di
    # `updatePhrases`/`applyOfflineHomeState`).
    enterOfflineMode: =>
      # `@offlineMode` SUDAH di-set (lihat handler `chat_status_customer`
      # di atas, ditentukan LEBIH DULU dari state respons, sebelum
      # `updatePhrases` dipanggil) -- di sini tinggal terapkan +
      # tampilkan.
      #
      # Bug ditemukan user (loading full page tidak pernah hilang) --
      # `hidePreload()` SEBELUMNYA cuma dipanggil dari `onReady()`
      # (jalur state 'online') dan `onError()`. State 'offline' (agent
      # tidak ada yang tersedia -- skenario yang SANGAT umum saat
      # testing) jatuh ke method ini, TIDAK PERNAH memanggil
      # `hidePreload()`, jadi overlay loading nyangkut selamanya
      # menutupi widget walau kontennya (Home offline/OTP) sudah siap
      # di baliknya.
      @hidePreload()
      @applyOfflineHomeState()
      @show()

    # Diekstrak dari `enterOfflineMode` (bug ditemukan user, lihat
    # catatan di `updatePhrases`) -- SEKARANG method TERPISAH yang
    # AMAN dipanggil BERULANG KALI (dari sini MAUPUN dari
    # `updatePhrases` tiap kali WS reconnect), beda dari versi lama yg
    # cuma sanggup jalan SEKALI (`return if @offlineMode`). 2 perubahan
    # kunci spy aman diulang: (1) `.zammad-chat-welcome-subtext` TIDAK
    # LAGI diganti total (`replaceWith`, yg bikin elemen ASLINYA hilang
    # SELAMANYA setelah panggilan pertama -- panggilan kedua dst jadi
    # tidak ketemu apa2 lagi) -- SEKARANG cuma isinya yg diganti
    # (`.html()`), elemen pembungkusnya tetap `.zammad-chat-welcome-
    # subtext` yg SAMA, bisa ditimpa lagi kapan saja oleh `updatePhrases`
    # (arah sebaliknya, balik ke teks online) MAUPUN dipanggil lagi
    # method ini (balik ke offline lagi). (2) TIDAK ada guard idempoten
    # apa pun -- semua operasi di sini (toggle class, ganti teks) SUDAH
    # aman diulang berkali-kali tanpa efek samping.
    applyOfflineHomeState: =>
      return if !@offlineMode
      return if !@el

      @el.find('.zammad-chat-welcome-subtext').html(
        $('<span>')
          .addClass('zammad-chat-welcome-offline-status')
          .append($('<span>').addClass('zammad-chat-welcome-offline-dot'))
          .append(document.createTextNode(@T(@phrases['chat_phrase_offline_status'] || "We're offline right now")))
      )

      @el.find('.zammad-chat-home-offline-notice').removeClass('zammad-chat-is-hidden')

      # Atas permintaan user ("hilangkan icon pada button"): ikon
      # online/offline DIHAPUS dari markup (`views/home.eco`) --
      # toggle visibilitasnya di sini (`.zammad-chat-home-action-icon-
      # default`/`-offline`) DIHAPUS jg, sudah tidak ada elemen yg
      # dituju. Pergantian LABEL teks TETAP jalan.
      startAction = @el.find('.js-home-start-action')
      startAction.find('.js-home-start-label').text @T(@phrases['chat_phrase_offline_start_button'] || 'Leave us a message')

    onOfflineSessionInitResult: (data) =>
      if data.state isnt 'ok'
        # Skenario paling mungkin: race condition -- agent jadi online
        # PERSIS di antara widget menampilkan OfflineHome & visitor
        # submit form (server VALIDASI ULANG ini, lihat
        # `chat_offline_session_init.rb`). Kembalikan ke form pra-chat
        # dgn pesan, JANGAN diam-diam macet di loader.
        #
        # Atas permintaan user: `reason: 'agent_available'` (kabar
        # BAIK, BUKAN error sungguhan) ditampilkan pakai gaya notice
        # sukses Able Pro -- BEDA dari kegagalan validasi nama/email
        # (reason lain/tidak ada), yg TETAP gaya error merah.
        if data.reason is 'agent_available'
          @showPrechatForm(notice: data.message)
        else
          @showPrechatForm(error: data.message)
        return

      @setSessionId data.session_id
      @showOfflineOtp()

    showOfflineOtp: =>
      @el.find('.zammad-chat-modal').html @view('offline_otp')(email: @customerEmail)
      @el.find('.js-otp-digit').first().trigger('focus')

    # Auto-lompat ke kotak berikutnya begitu 1 digit terisi -- pola
    # standar UX kode OTP. `.replace(/[^0-9]/g, '')` menolak apa pun
    # selain angka (termasuk kalau browser/keyboard virtual entah
    # kenapa meloloskan karakter lain lewat `input` event meski
    # `inputmode="numeric"` cuma HINT tampilan, bukan validasi).
    onOtpDigitInput: (event) =>
      input = $(event.currentTarget)
      value = input.val().replace(/[^0-9]/g, '')
      input.val(value.slice(-1))
      if value
        next = input.closest('.zammad-chat-offline-otp-boxes').find(".js-otp-digit[data-index='#{parseInt(input.data('index'), 10) + 1}']")
        next.trigger('focus') if next.length

    # Backspace di kotak KOSONG -- lompat mundur & kosongkan kotak
    # sebelumnya (kalau MASIH ada isi di kotak saat ini, biarkan
    # browser menghapusnya dulu spt biasa, jangan dicegat).
    onOtpDigitKeydown: (event) =>
      return if event.keyCode isnt 8
      input = $(event.currentTarget)
      return if input.val()

      prevIndex = parseInt(input.data('index'), 10) - 1
      return if prevIndex < 0

      prev = input.closest('.zammad-chat-offline-otp-boxes').find(".js-otp-digit[data-index='#{prevIndex}']")
      if prev.length
        prev.val('').trigger('focus')

    # Tempel 1 kode 6 digit sekaligus (copy dari email) -- sebar ke
    # SEMUA kotak, bukan cuma masuk ke kotak yang sedang fokus.
    onOtpDigitPaste: (event) =>
      event.preventDefault()
      clipboard = event.originalEvent?.clipboardData || event.clipboardData
      pasted = clipboard?.getData('text')?.replace(/[^0-9]/g, '') || ''
      return if !pasted

      boxes = $(event.currentTarget).closest('.zammad-chat-offline-otp-boxes').find('.js-otp-digit')
      boxes.each (i, el) ->
        $(el).val(pasted.charAt(i) || '')
      lastFilled = Math.min(pasted.length, boxes.length) - 1
      boxes.eq(Math.max(lastFilled, 0)).trigger('focus')

    submitOfflineOtp: (event) =>
      event?.preventDefault()
      code = ''
      @el.find('.js-otp-digit').each (i, el) ->
        code += $(el).val() || ''

      if code.length isnt 6
        @showOtpError @T(@phrases['chat_phrase_otp_incomplete_error'] || 'Please enter the full 6-digit code.')
        return

      @setButtonLoading(@el.find('.js-otp-submit'), true)
      @send('chat_offline_otp_verify', session_id: @sessionId, code: code)

    # Bug ditemukan lewat laporan user (perbandingan ke mockup
    # `OfflineOtp.dc.html`): ikon peringatan di pesan error TIDAK
    # PERNAH dibuat -- `.js-otp-error` cuma `<div>` kosong yg diisi
    # `.text(message)`, MEMANG tidak ada markup ikon sama sekali, dan
    # `.text()` akan MENGHAPUS ikon apa pun tiap kali dipanggil (isi
    # elemen diganti total jadi teks polos). Diperbaiki: ikon
    # dipindah ke markup statis `views/offline_otp.eco`, `.text()` di
    # sini SEKARANG cuma menyasar `<span>` anak (`.js-otp-error-text`)
    # -- ikon tidak pernah tersentuh/terhapus.
    showOtpError: (message) =>
      @el.find('.js-otp-error').removeClass('zammad-chat-is-hidden')
      @el.find('.js-otp-error-text').text(message)

    onOfflineOtpVerifyResult: (data) =>
      if data.state is 'ok'
        @showOfflineCompose()
        return

      # Kegagalan di sini TIDAK me-render ulang modal (beda dari
      # sukses) -- tombol lama TETAP ada, WAJIB dimatikan manual.
      @setButtonLoading(@el.find('.js-otp-submit'), false)
      @showOtpError data.message
      # Kosongkan & fokus ulang ke kotak pertama supaya gampang coba
      # lagi -- BERLAKU juga utk state 'too_many_attempts' (kotak
      # dikosongkan sbg sinyal visual "mulai dari nol", meski kode
      # LAMA sudah pasti ditolak lagi -- visitor tetap perlu klik
      # "Kirim ulang" sendiri, tombol itu TIDAK diklik otomatis di
      # sini).
      @el.find('.js-otp-digit').val('')
      @el.find('.js-otp-digit').first().trigger('focus')

    resendOfflineOtp: (event) =>
      event?.preventDefault()
      @send('chat_offline_otp_resend', session_id: @sessionId)

    onOfflineOtpResendResult: (data) =>
      if data.state is 'ok'
        @el.find('.js-otp-digit').val('')
        @el.find('.js-otp-digit').first().trigger('focus')
        @showOtpError @T(@phrases['chat_phrase_otp_resend_success'] || 'A new code has been sent.')
        return

      @showOtpError data.message || @T(@phrases['chat_phrase_otp_resend_error_fallback'] || 'Could not resend code. Please try again.')

    showOfflineCompose: =>
      @el.find('.zammad-chat-modal').html @view('offline_compose')(email: @customerEmail)

    # Atas permintaan user ("subject ini mandatory harus diisi") --
    # divalidasi DULUAN (sebelum isi pesan, mengikuti urutan field
    # atas-ke-bawah di form) -- backend (`chat_offline_message_send.rb`)
    # mengulang validasi yg SAMA, tidak cukup dipercaya dari sini saja
    # (WS bisa dipanggil langsung lewat console, lihat pola yg sama
    # dipakai validasi OTP).
    submitOfflineMessage: (event) =>
      event?.preventDefault()
      subject = @el.find('.js-offline-subject').val()?.trim()
      if !subject
        @el.find('.js-offline-compose-error').text(@T(@phrases['chat_phrase_offline_compose_subject_empty_error'] || 'Please enter a subject.')).removeClass('zammad-chat-is-hidden')
        return

      content = @el.find('.js-offline-message').val()?.trim()
      if !content
        @el.find('.js-offline-compose-error').text(@T(@phrases['chat_phrase_offline_compose_empty_error'] || 'Please write a message.')).removeClass('zammad-chat-is-hidden')
        return

      @el.find('.js-offline-compose-error').addClass('zammad-chat-is-hidden')
      @setButtonLoading(@el.find('.js-offline-compose-submit'), true)
      @send('chat_offline_message_send', session_id: @sessionId, subject: subject, content: content)

    # Item lampiran OfflineCompose (follow-up terpisah dari
    # Enhancement 4 awal) -- reuse ENDPOINT REST yang sama dgn
    # attachment chat biasa (`uploadAttachment` di atas), BUKAN event
    # WS baru. `@sessionId` (BUKAN `@lastSessionId`) krn ini terjadi
    # SEBELUM "Kirim Pesan" diklik -- sesi masih `offline_pending`
    # (belum `closed`), `attachment_enabled?` (backend) sudah dibuat
    # khusus mengizinkan sesi offline lewat saklar global saja (tidak
    # ada agent utk dicek preferensinya). Tiket belum tentu ada di
    # titik upload ini -- disinkronkan RETROAKTIF backend sendiri
    # (`Chat::Session#sync_pending_attachments_to_ticket!`) begitu
    # "Kirim Pesan" benar2 membuat tiketnya.
    triggerOfflineAttachmentInput: (event) =>
      event?.preventDefault()
      @el.find('.js-offline-compose-attachment-input').trigger('click')

    uploadOfflineAttachment: (event) =>
      file = event.currentTarget.files?[0]
      return if !file

      formData = new FormData()
      formData.append('File', file)

      attachBtn = @el.find('.js-offline-compose-attach')
      attachBtn.prop('disabled', true)

      $.ajax
        type: 'POST'
        url: "#{@apiBaseUrl()}/api/v1/chat_sessions/#{@sessionId}/attachments"
        data: formData
        processData: false
        contentType: false
        cache: false
        success: (data) =>
          chip = $('<div>').addClass('zammad-chat-offline-compose-attachment-chip')
          chip.append $('<svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M11.97 12v3.5c0 1.93 1.57 3.5 3.5 3.5s3.5-1.57 3.5-3.5V10c0-3.87-3.13-7-7-7s-7 3.13-7 7v6c0 3.31 2.69 6 6 6"/></svg>')
          chip.append $('<span>').text(data.filename)
          @el.find('.js-offline-compose-attachments').append(chip)
        error: (xhr) =>
          message = xhr.responseJSON?.error || @T(@phrases['chat_phrase_attachment_upload_error'] || 'The attachment could not be uploaded.')
          @el.find('.js-offline-compose-error').text(message).removeClass('zammad-chat-is-hidden')
        complete: =>
          attachBtn.prop('disabled', false)

      @el.find('.js-offline-compose-attachment-input').val('')

    onOfflineMessageSendResult: (data) =>
      @setButtonLoading(@el.find('.js-offline-compose-submit'), false)

      if data.state isnt 'ok'
        @el.find('.js-offline-compose-error').text(data.message).removeClass('zammad-chat-is-hidden')
        return

      # Enhancement 2 -- simpan session_id SEBELUM di-undefined-kan,
      # supaya layar Feedback (yang muncul SETELAH ini) masih tahu
      # sesi/tiket mana yang harus dikasih rating.
      @lastSessionId = @sessionId
      @setSessionId undefined
      @showOfflineSent()

    showOfflineSent: =>
      @el.find('.zammad-chat-modal').html @view('offline_sent')(email: @customerEmail)

    # Atas permintaan user (rencana "ending page"): SEBELUMNYA tombol
    # ini langsung "Kembali ke Home" -- sekarang, sesuai urutan
    # OfflineSent -> Feedback -> Home yang disepakati, tombol ini
    # lanjut ke layar Feedback dulu (lihat `showFeedback`), yang pada
    # gilirannya memanggil `goToStartChat()` (baik lewat submit maupun
    # skip) utk benar-benar kembali ke Home.
    finishOfflineFlow: (event) =>
      event?.preventDefault()
      @setButtonLoading(@el.find('.js-offline-sent-done'), true)
      @showFeedback()

    # Enhancement 2 -- Rating Kepuasan (Feedback), direlasikan dgn
    # CSAT Fase 1 (docs/DESIGN_FEEDBACK_RATING.md). Dipanggil dari 2
    # tempat: `exitChat()` (chat biasa, setelah loading EndingChat) &
    # `finishOfflineFlow()` (pesan offline, setelah layar OfflineSent).
    # `@lastSessionId` (diisi di `sessionClose()`/
    # `onOfflineMessageSendResult()` SEBELUM `@sessionId` di-undefined-
    # kan) yang jadi acuan sesi/tiket mana yg dikasih rating -- BUKAN
    # `@sessionId` yg sudah kosong di titik ini.
    # Atas permintaan user (mockup "SISKA Widget Mockup" board
    # FeedbackInline): saat AGENT yg menutup sesi (`onSessionClosed`),
    # feedback SEKARANG jadi kartu DI DALAM `.zammad-chat-body`
    # (`inline = true`) -- riwayat percakapan TETAP terlihat penuh di
    # atasnya, bukan lagi menutupi seluruh jendela lewat
    # `.zammad-chat-modal`. `exitChat` (customer sendiri klik X) &
    # `finishOfflineFlow` (alur pesan offline) SENGAJA TIDAK diubah
    # (`inline` default `false`, tetap modal spt sebelumnya) -- di luar
    # scope permintaan ini, dan utk alur offline `.zammad-chat-body`
    # genuinely kosong (tidak ada histori realtime utk ditampilkan di
    # belakangnya).
    showFeedback: (inline = false) =>
      @feedbackScore = undefined
      @feedbackInline = inline
      markup = @view('feedback')()
      if inline
        @hideModal()
        @maybeAddTimestamp()
        @el.find('.zammad-chat-body').append "<div class=\"zammad-chat-feedback-inline js-feedback-inline\">#{markup}</div>"
        @scrollToBottom()
      else
        @el.find('.zammad-chat-modal').html markup
      # Konsisten dgn Enhancement 1 (header generik "Messages" selama
      # Otp/Compose/Sent) -- tanpa ini, header akan nyangkut nama agent
      # LAMA (chat sudah berakhir) selama layar Feedback tampil, krn
      # `@agent` baru benar2 dikosongkan di `goToStartChat()` yg
      # dipanggil belakangan (submit/skip).
      @agent = undefined
      @updateHeader()

    selectFeedbackScore: (event) =>
      event?.preventDefault()
      @feedbackScore = parseInt($(event.currentTarget).data('score'), 10)
      @el.find('.js-feedback-star').each (i, el) =>
        starScore = parseInt($(el).data('score'), 10)
        $(el).toggleClass('is-active', starScore <= @feedbackScore)

    submitFeedback: (event) =>
      event?.preventDefault()

      if !@feedbackScore
        @el.find('.js-feedback-error').text(@T(@phrases['chat_phrase_feedback_score_error'] || 'Please select a rating.')).removeClass('zammad-chat-is-hidden')
        return

      @el.find('.js-feedback-error').addClass('zammad-chat-is-hidden')
      @setButtonLoading(@el.find('.js-feedback-submit'), true)

      comment = @el.find('.js-feedback-comment').val()?.trim()
      @send 'chat_session_feedback_submit',
        session_id: @lastSessionId
        score: @feedbackScore
        comment: comment

    onFeedbackSubmitResult: (data) =>
      @setButtonLoading(@el.find('.js-feedback-submit'), false)

      if data.state isnt 'ok'
        @el.find('.js-feedback-error').text(data.message || @T(@phrases['chat_phrase_feedback_submit_error_fallback'] || 'Could not save your feedback. Please try again.')).removeClass('zammad-chat-is-hidden')
        return

      @showFeedbackThanks()

    skipFeedback: (event) =>
      event?.preventDefault()
      @setButtonLoading(@el.find('.js-feedback-skip'), true)
      @goToStartChat()

    # Atas permintaan user: rating-nya sendiri inline (`showFeedback`
    # di atas), TAPI layar "Terima kasih" SETELAH submit tetap fullpage
    # -- overlay TERPISAH (`.js-feedback-thanks-overlay`, lihat
    # `chat.eco`/`chat.scss`) dari overlay status koneksi, gaya scrim
    # sama (semi-transparan, jendela chat kelihatan samar di belakang).
    showFeedbackThanks: =>
      markup = @view('feedback_thanks')()
      if @feedbackInline
        overlay = @el.find('.js-feedback-thanks-overlay')
        if overlay.length
          overlay.html(markup).removeClass('zammad-chat-is-hidden')
      else
        @el.find('.zammad-chat-modal').html markup
      setTimeout (=> @hideFeedbackThanksOverlay(); @goToStartChat()), 2000

    hideFeedbackThanksOverlay: =>
      overlay = @el.find('.js-feedback-thanks-overlay')
      return if !overlay.length
      overlay.addClass('zammad-chat-is-hidden')
      overlay.html ''

    onOpenAnimationEnd: =>
      @idleTimeout.stop()

      if @isFullscreen
        @disableScrollOnRoot()
      @options.onOpenAnimationEnd?()

    sessionClose: =>
      # send close
      @send 'chat_session_close',
        session_id: @sessionId

      # stop timer
      @inactiveTimeout.stop()
      @waitingListTimeout.stop()

      # delete input store
      sessionStorage.removeItem 'unfinished_message'

      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout(@onInitialQueueDelayId)

      # Enhancement 2 -- lihat catatan sama di `onOfflineMessageSendResult`.
      @lastSessionId = @sessionId
      @setSessionId undefined

    # Atas permintaan user (mockup `Waiting.dc.html` + koreksi "keluar
    # dari antrian kembali ke home") -- klik tombol Batalkan saat masih
    # di antrean (baik `loader.eco` maupun `waiting.eco`, KEDUANYA
    # sama-sama status "sudah masuk antrean" sejak `chat_session_init`
    # terkirim, lihat `showLoader()`). `sessionClose()` SUDAH menangani
    # sisi backend (event `chat_session_close`, valid utk sesi yang
    # BELUM tersambung ke agent juga -- dicek ke
    # `lib/sessions/event/chat_session_close.rb`: cukup set
    # `state: 'closed'` + broadcast posisi antrean ke sesi lain yang
    # masih menunggu, tidak mengasumsikan ada agent) + reset timer +
    # sessionId. Ditambahkan di sini: reset `@inQueue` (dicek di tempat
    # lain utk tahu status sedang antre atau tidak) + `.zammad-chat-modal`
    # diisi ULANG dengan form pra-chat segar (bukan dibiarkan berisi
    # layar antre basi -- kalau visitor nanti buka tab Messages lagi
    # LEWAT tab bar, bukan lewat tombol Home, tanpa ini mereka akan
    # melihat layar antre lama yang sudah tidak berlaku).
    cancelQueue: (event) =>
      event?.preventDefault()
      @sessionClose()
      @inQueue = false
      @showPrechatForm()
      @switchTab('home')

    toggle: (event) =>
      if @isOpen
        @close(event)
      else
        @open(event)

    # Bug ditemukan lewat laporan user ("tombol panah bawah... widget
    # tidak exit chat, ketika di klik lagi chat tetap aktif") --
    # SEBELUMNYA method ini (dipakai tombol bulat mengambang via
    # `toggle()`) JUGA memanggil `sessionClose()` kalau ada sesi
    # berjalan -- klik tombol minimize diam-diam MENGAKHIRI chat,
    # bukan cuma menyembunyikan panel. `close()` SEKARANG CUMA
    # menyembunyikan panel secara visual, TIDAK PERNAH menyentuh sesi
    # chat sama sekali -- chat tetap berjalan di baliknya, buka lagi
    # via tombol yang sama akan melanjutkan percakapan yang SAMA
    # (`open()` sudah punya logika `if @sessionId then switchTab
    # 'messages'`, tidak perlu diubah).
    close: (event) =>
      if !@isOpen
        @log.debug 'can\'t close widget, it\'s not open'
        return
      if @initDelayId
        clearTimeout(@initDelayId)

      # Bug KEDUA ditemukan lewat pengujian LANGSUNG (bukan diminta,
      # tapi konsekuensi LANGSUNG dari perbaikan di atas): sekarang
      # sesi TETAP hidup saat minimize, `onCloseAnimationEnd` di bawah
      # tetap memanggil `@io.reconnect()` spt sebelumnya -- server
      # BENAR mendeteksi sesi masih berjalan & balas `state:
      # 'reconnect'`, TAPI `onReopenSession` PUNYA `@show(); @open()`
      # TANPA SYARAT di ujungnya (dirancang dulu utk skenario RELOAD
      # HALAMAN, bukan "baru saja diminimize") -- panel jadi
      # TERBUKA PAKSA LAGI beberapa saat setelah diminimize, meniadakan
      # tombol minimize sama sekali. Ditandai di sini, dicek di
      # `onReopenSession` (bukan menghapus `io.reconnect()` -- itu
      # tetap perlu utk skenario reload sungguhan).
      @minimizedWithSession = !!@sessionId

      @log.debug 'close widget'

      event.stopPropagation() if event

      if @isFullscreen
        @enableScrollOnRoot()

      # Fase 7 -- lihat komentar sama di open().
      @launcherEl.removeClass('zammad-chat-is-open')
      @el.one('transitionend', @onCloseAnimationEnd)
      @el.removeClass('zammad-chat-is-open')

    # Atas permintaan user ("chat berakhir HANYA jika klik tombol
    # exit") -- tombol X di header SEKARANG SATU-SATUNYA cara
    # mengakhiri sesi chat (dulu berbagi `close()` dgn tombol
    # mengambang, lihat komentar di atas). BEDA dari `close()` lama:
    # TIDAK menyembunyikan panel sama sekali -- cukup pindah/tampilkan
    # kembali tab Messages (bukan `close()`), sesuai diminta eksplisit
    # "menampilkan kembali halaman messages bukan hide widget".
    #
    # Revisi lanjutan atas permintaan user ("hanya tombol X pada
    # halaman Messages yang bisa untuk end chat, tombol X pada
    # halaman lain berfungsi normal") -- tombol X ini SATU elemen
    # yang SAMA persis dipakai di SEMUA tab (lihat `chat.eco`, header
    # cuma dirender sekali di root, bukan per-tab), jadi cara
    # membedakannya HANYA lewat tab mana yang sedang aktif
    # (`@activeTab`, sudah dilacak `switchTab`). Di tab Messages: tetap
    # perilaku "exit" (akhiri sesi). Di tab LAIN (Home/Help): didelegasikan
    # ke `close()` -- "normal" di sini berarti SAMA seperti tombol
    # minimize mengambang, cuma menyembunyikan panel, TIDAK menyentuh
    # sesi chat sama sekali (biasanya toh belum ada sesi aktif di
    # tab-tab itu).
    # Atas permintaan user (mockup `EndingChat.dc.html`): "arahkan ke
    # halaman loading mengakhiri percakapan, kemudian setelah jeda 2
    # detik reload kembali ke halaman messages" -- ditampilkan lewat
    # `.zammad-chat-modal` yang sama (pola SAMA dgn `showLoader()`/
    # `showCustomerTimeout()`), MENUTUPI penuh area percakapan+kotak
    # ketik (header & tabbar tetap terlihat di luarnya, lihat CSS
    # `.zammad-chat-modal`) selama 2 detik.
    #
    # Revisi lanjutan atas permintaan user ("...reload kembali ke
    # halaman MULAI CHAT" -- bukan lagi "halaman messages" spt
    # permintaan sebelumnya): tujuan akhir sekarang tab HOME dgn form
    # pra-chat SUDAH disiapkan di modal Messages (persis pola
    # `cancelQueue()` yang sudah ada -- `showPrechatForm()` lalu
    # `switchTab('home')`), bukan lagi cuma `hideModal()` diam di tab
    # Messages spt versi sebelumnya. Ini otomatis SEKALIGUS membetulkan
    # bug lama yang sempat dicatat di sini (header nyangkut nama agent
    # lama) krn `switchTab('home')` BENAR2 pindah tab sekarang (bukan
    # no-op lagi spt saat tujuannya 'messages'), `updateHeader()` di
    # dalamnya otomatis jalan wajar.
    #
    # PENTING: `chat_session_close.rb` (backend) mengirim balik event
    # `chat_session_closed` HANYA ke PESERTA LAIN (`send_to_recipients
    # (message, @client_id)` sengaja mengecualikan pengirim) -- customer
    # yang MENGINISIASI penutupan ini TIDAK PERNAH menerima event itu
    # balik. Jadi transisi loading -> kembali ke halaman mulai chat ini
    # MURNI ditangani lokal/optimis di sini (timer tetap, TIDAK
    # menunggu balasan server sama sekali).
    # Atas permintaan user ("tombol close/disconnect chat hanya untuk
    # online chat, tidak berlaku untuk offline message, pada offline
    # message terapkan seperti tombol close pada halaman lainnya") --
    # `@activeTab` SAJA TIDAK CUKUP utk membedakannya: SELURUH alur
    # offline (OfflineOtp/OfflineCompose/OfflineSent) dirender di
    # DALAM `.zammad-chat-modal` yang sama, yang notabene anak dari
    # tab Messages (`@activeTab` TETAP `'messages'` sepanjang alur
    # ini) -- tanpa perbaikan ini, klik X saat OfflineOtp/Compose akan
    # SALAH masuk ke cabang "akhiri sesi chat" (`sessionClose()` +
    # layar EndingChat + Feedback) padahal TIDAK ADA chat/agent sama
    # sekali di sana, cuma sesi `offline_pending` yang belum berujung
    # tiket. `@offlineMode` (SUDAH ADA, ditandai SEJAK `chat_status_
    # customer` state 'offline' -- SATU-SATUNYA alasan alur offline
    # ini bisa dimulai) dipakai sbg penanda tambahan -- perilaku
    # persis SAMA dgn tombol X di tab LAIN (`close()`, cuma
    # menyembunyikan panel, TIDAK menyentuh sesi apa pun).
    exitChat: (event) =>
      if @activeTab isnt 'messages' or @offlineMode
        @close(event)
        return

      event?.preventDefault()
      event?.stopPropagation()

      if @sessionId
        @log.debug 'exit chat'
        @el.find('.zammad-chat-modal').html @view('ending_chat')()
        @sessionClose()
        # Enhancement 2 -- rencana "ending page": setelah loading
        # EndingChat, lanjut ke layar Feedback dulu (BUKAN langsung
        # `goToStartChat` spt sebelumnya) -- Feedback sendiri yang
        # akan memanggil `goToStartChat()` pada akhirnya (via submit
        # maupun skip).
        setTimeout @showFeedback, 2000
      else
        @goToStartChat()

    # Diekstrak dari closure lokal di `exitChat` (dulu bernama
    # `goToStartChat`, hanya dipakai di situ) -- sekarang jadi method
    # instance supaya bisa dipanggil ULANG dari handler Feedback
    # (submit/skip, lihat `submitFeedback`/`skipFeedback`/
    # `showFeedbackThanks`) tanpa duplikasi logika.
    goToStartChat: =>
      @agent = undefined
      @showPrechatForm()
      @switchTab('home')

    onCloseAnimationEnd: =>
      # Revisi desain -- balik ke tab Home HANYA kalau memang tidak ada
      # sesi yang sedang berjalan/menunggu (`@sessionId` kosong) --
      # kalau ADA, biarkan tab Messages+modal apa adanya, reconnect
      # nanti akan mengembalikan tampilan yang benar sendiri lewat
      # onQueueScreen/onConnectionEstablished. Modal tidak perlu
      # ditimpa apa pun di sini -- `open()` berikutnya akan mengisi
      # ulang form pra-chat dari awal kalau memang belum ada sesi.
      if !@sessionId
        @agent = undefined
        @switchTab('home')

      @isOpen = false
      @options.onCloseAnimationEnd?()

      @io.reconnect()

    onWebSocketClose: =>
      return if @isOpen
      # Fase 7 -- gerbang "tersedia sama sekali" sekarang ada di
      # @launcherEl (lihat show()), BUKAN @el lagi.
      if @launcherEl
        @launcherEl.removeClass('zammad-chat-is-shown')
        @launcherEl.removeClass('zammad-chat-is-loaded')

    show: ->
      return if @state is 'offline'

      # Fase 7 -- gerbang "widget ini tersedia sama sekali" sekarang
      # ada di tombol mengambang (@launcherEl), bukan di panel (@el
      # lagi) -- panel sendiri tampil/sembunyi murni lewat
      # `zammad-chat-is-open` (lihat open()/close()).
      @launcherEl.addClass('zammad-chat-is-loaded')

      @launcherEl.addClass('zammad-chat-is-shown')

    disableInput: ->
      @inputDisabled = true
      @input.prop('contenteditable', false)
      @el.find('.zammad-chat-send').prop('disabled', true)
      @io.close()

    # Bug ditemukan user (submit feedback tidak berfungsi setelah agent
    # menutup sesi) -- root cause: `onSessionClosed` sebelumnya
    # memanggil `disableInput()` PENUH, efek samping `@io.close()` ikut
    # menutup WebSocket -- koneksi ini SEHARUSNYA tetap hidup lintas
    # sesi (dipakai jg utk Home/Help/mulai chat baru), BUKAN scoped ke
    # 1 sesi chat. Akibatnya `chat_session_feedback_submit` via
    # `@send()` selalu no-op diam-diam (`Io#send` cuma kirim kalau
    # `readyState` masih `OPEN`). Method ini cuma menonaktifkan kotak
    # ketik SECARA VISUAL (memang harus mati -- sesi sudah berakhir,
    # tidak ada lagi yg menerima pesan baru), TANPA menyentuh `@io`.
    disableComposeInput: ->
      @inputDisabled = true
      @input?.prop('contenteditable', false)
      @el.find('.zammad-chat-send').prop('disabled', true)

    enableInput: ->
      @inputDisabled = false
      @input.prop('contenteditable', true)
      @el.find('.zammad-chat-send').prop('disabled', false)

    hideModal: ->
      @el.find('.zammad-chat-modal').html ''

    onQueueScreen: (data) =>
      @setSessionId data.session_id

      # delay initial queue position, show connecting first
      show = =>
        @onQueue data
        @waitingListTimeout.start()

      if @initialQueueDelay && !@onInitialQueueDelayId
        @onInitialQueueDelayId = setTimeout(show, @initialQueueDelay)
        return

      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout(@onInitialQueueDelayId)

      # show queue position
      show()

    onQueue: (data) =>
      @log.notice 'onQueue', data.position
      @inQueue = true

      @el.find('.zammad-chat-modal').html @view('waiting')
        position: data.position

    onAgentTypingStart: =>
      if @stopTypingId
        clearTimeout(@stopTypingId)
      @stopTypingId = setTimeout(@onAgentTypingEnd, 3000)

      # never display two typing indicators
      return if @el.find('.zammad-chat-message--typing').get(0)

      @maybeAddTimestamp()

      @el.find('.zammad-chat-body').append @view('typingIndicator')()

      # only if typing indicator is shown
      return if !@isVisible(@el.find('.zammad-chat-message--typing'), true)
      @scrollToBottom()

    onAgentTypingEnd: =>
      @el.find('.zammad-chat-message--typing').remove()

    onLeaveTemporary: =>
      return if !@sessionId
      @send 'chat_session_leave_temporary',
        session_id: @sessionId

    maybeAddTimestamp: ->
      timestamp = Date.now()

      if !@lastTimestamp or (timestamp - @lastTimestamp) > @showTimeEveryXMinutes * 60000
        label = @T('Today')
        time = new Date().toTimeString().substr 0,5
        if @lastAddedType is 'timestamp'
          # update last time
          @updateLastTimestamp label, time
          @lastTimestamp = timestamp
        else
          # add new timestamp
          @el.find('.zammad-chat-body').append @view('timestamp')
            label: label
            time: time
          @lastTimestamp = timestamp
          @lastAddedType = 'timestamp'
          @scrollToBottom()

    updateLastTimestamp: (label, time) ->
      return if !@el
      @el.find('.zammad-chat-body')
        .find('.zammad-chat-timestamp')
        .last()
        .replaceWith @view('timestamp')
          label: label
          time: time

    addStatus: (status) ->
      return if !@el
      @maybeAddTimestamp()

      @el.find('.zammad-chat-body').append @view('status')
        status: status

      @scrollToBottom()

    # Atas permintaan user (mockup "SISKA Widget Mockup" -- board
    # IndicatorReconnecting/Restored/Lost) -- indikator fullpage
    # SEMI-TRANSPARAN utk status koneksi WebSocket widget sendiri
    # (beda dari status online/offline AGENT). `state` salah satu dari
    # 'reconnecting'/'restored'/'lost'. Judul 'reconnecting'/'restored'
    # SENGAJA reuse 2 key terjemahan yg SUDAH ADA (25 bahasa, dulu
    # dipakai `addStatus`) supaya tidak kehilangan cakupan bahasa yg
    # sudah dibangun -- subtitle & tombol Reload BELUM configurable/
    # diterjemahkan (follow-up terpisah, pola sama dgn pesan error OTP
    # backend yg jg msh hardcode). Mirror persis dari
    # chat-no-jquery.coffee, disesuaikan ke API jQuery.
    connectionOverlayCopy: (state) =>
      switch state
        when 'reconnecting'
          title: @T('Connection lost')
          subtitle: "Trying to reconnect — please don't close this window."
        when 'restored'
          title: @T('Connection re-established')
          subtitle: "You're back online."
        when 'lost'
          # String literal ini SAMA PERSIS dgn pesan lama yg dikirim
          # `Io#attemptReconnect()` sebelum refactor ini (jg tidak
          # pernah diterjemahkan) -- bukan regresi baru.
          title: 'Connection lost'
          subtitle: "We couldn't reconnect after several attempts. Please reload the page to continue this conversation."

    showConnectionOverlay: (state) =>
      return if !@el
      overlay = @el.find('.js-connection-overlay')
      return if !overlay.length

      if @connectionOverlayHideTimeoutId
        clearTimeout(@connectionOverlayHideTimeoutId)
        @connectionOverlayHideTimeoutId = undefined

      copy = @connectionOverlayCopy(state)
      overlay.html @view('connection_overlay')
        state: state
        title: copy.title
        subtitle: copy.subtitle

      for otherState in ['reconnecting', 'restored', 'lost']
        overlay.removeClass("zammad-chat-connection-overlay--#{otherState}")
      overlay.addClass("zammad-chat-connection-overlay--#{state}")
      overlay.removeClass('zammad-chat-is-hidden')

      # 'restored' cuma konfirmasi sesaat -- hilang otomatis, jendela
      # chat (yg sudah genuinely aktif kembali di belakangnya) lalu
      # kelihatan penuh tanpa scrim.
      if state is 'restored'
        @connectionOverlayHideTimeoutId = setTimeout(@hideConnectionOverlay, 1800)

    hideConnectionOverlay: =>
      return if !@el
      overlay = @el.find('.js-connection-overlay')
      return if !overlay.length
      overlay.addClass('zammad-chat-is-hidden')
      overlay.html ''

    # Toggle warna tombol launcher (abu-abu netral) selama koneksi
    # WEBSOCKET WIDGET SENDIRI bermasalah -- class TERPISAH dari
    # `zammad-chat-launcher--offline` (dipakai utk status AGENT
    # offline, `@offlineMode`) supaya kedua mekanisme independen tidak
    # saling menimpa lewat toggle class yg sama.
    updateLauncherConnectionState: (hasIssue) =>
      @launcherEl?.toggleClass('zammad-chat-launcher--connection-issue', hasIssue)

    detectScrolledtoBottom: =>
      scrollBottom = @el.find('.zammad-chat-body').scrollTop() + @el.find('.zammad-chat-body').outerHeight()
      @scrolledToBottom = Math.abs(scrollBottom - @el.find('.zammad-chat-body').prop('scrollHeight')) <= @scrollSnapTolerance
      @el.find('.zammad-scroll-hint').addClass('is-hidden') if @scrolledToBottom

    showScrollHint: ->
      @el.find('.zammad-scroll-hint').removeClass('is-hidden')
      # compensate scroll
      @el.find('.zammad-chat-body').scrollTop(@el.find('.zammad-chat-body').scrollTop() + @el.find('.zammad-scroll-hint').outerHeight())

    onScrollHintClick: =>
      # animate scroll
      @el.find('.zammad-chat-body').animate({scrollTop: @el.find('.zammad-chat-body').prop('scrollHeight')}, 300)

    scrollToBottom: ({ showHint } = { showHint: false }) ->
      if @scrolledToBottom
        @el.find('.zammad-chat-body').scrollTop($('.zammad-chat-body').prop('scrollHeight'))
      else if showHint
        @showScrollHint()

    destroy: (params = {}) =>
      @log.debug 'destroy widget', params

      @setAgentOnlineState 'offline'

      if params.remove && @el
        @el.remove()
        @launcherEl?.remove()
        # Remove button, because it can no longer be used.
        $(".#{ @options.buttonClass }").hide()


      # stop all timer
      if @waitingListTimeout
        @waitingListTimeout.stop()
      if @inactiveTimeout
        @inactiveTimeout.stop()
      if @idleTimeout
        @idleTimeout.stop()

      # stop ws connection
      @io.close()

    # Atas permintaan user ("mau" -- auto-reconnect websocket) --
    # method INI (dan `onIoReconnected` di bawah) MENGGANTIKAN versi
    # lama (`reconnect()`/`onConnectionReestablished()`) yg TERNYATA
    # TIDAK PERNAH dipanggil dari mana pun (dicek `grep`, nol call site
    # -- sisa kode widget Zammad native asli yg tidak pernah tersambung
    # ke logic sungguhan). SEKARANG disambungkan LANGSUNG ke
    # `Io#attemptReconnect()` (BARU) via `@io.set(...)` di constructor
    # -- `attempt`/`maxAttempts` dikirim tiap percobaan, TAPI pesan
    # status HANYA ditampilkan SEKALI (attempt pertama) -- retry ke-2
    # dst TIDAK perlu spam transkrip chat dgn pesan yg sama berulang.
    #
    # SENGAJA TIDAK pakai `disableInput()` yg SUDAH ADA (method itu
    # JUGA memanggil `@io.close()` sbg efek samping -- akan meracuni
    # flag `manualClose` milik `Io` di TENGAH siklus retry yg sedang
    # berjalan, bikin percobaan berikutnya salah dikira "penutupan
    # manual" & retry loop berhenti prematur). Toggle DOM langsung di
    # sini, HANYA kalau input BELUM disabled krn alasan lain (mis. sesi
    # sudah diakhiri agent via `onSessionClosed`) -- ditandai
    # `@reconnectDisabledInput` supaya `onIoReconnected` tahu PERSIS
    # elemen mana yg boleh diaktifkan lagi (jangan sampai tanpa sengaja
    # mengaktifkan lagi kotak ketik yg MEMANG sudah harus tetap
    # nonaktif krn alasan lain).
    onIoReconnecting: (attempt, maxAttempts) =>
      @log.debug "reconnecting attempt #{attempt}/#{maxAttempts}"
      return if attempt isnt 1
      return if !@isOpen
      @setAgentOnlineState 'connecting'
      # Atas permintaan user (mockup "fullpage semi-transparan") --
      # pengganti pill status inline (`addStatus`) lama -- jendela chat
      # TETAP dirender di belakang (header/riwayat/compose/tab-bar),
      # cuma ditutupi scrim tembus pandang + spinner Circular
      # Indeterminate, bukan diganti/disembunyikan total.
      @showConnectionOverlay('reconnecting')
      @updateLauncherConnectionState(true)
      if !@inputDisabled
        @reconnectDisabledInput = true
        @input?.prop('contenteditable', false)
        @el.find('.zammad-chat-send').prop('disabled', true)

    onIoReconnected: =>
      @log.debug 'reconnected'
      return if !@isOpen
      @setAgentOnlineState 'online'
      @showConnectionOverlay('restored')
      @updateLauncherConnectionState(false)
      @options.onConnectionReestablished?()
      if @reconnectDisabledInput
        @reconnectDisabledInput = false
        @input?.prop('contenteditable', true)
        @el.find('.zammad-chat-send').prop('disabled', false)

    # Atas permintaan user (mockup fullpage "Connection lost") --
    # pengganti alur lama `onError('Connection lost...')` yg diam-diam
    # menghancurkan widget tanpa pesan apa pun ke user. Panel MINIMIZED
    # (tidak ada yg bisa dilihat) tetap pakai perilaku lama (bersihkan
    # total) -- overlay ini cuma relevan kalau panel TERBUKA.
    onReconnectFailed: =>
      @log.debug 'gave up reconnecting'
      if !@isOpen
        @destroy(remove: true)
        return
      @setAgentOnlineState 'offline'
      @showConnectionOverlay('lost')
      @updateLauncherConnectionState(true)
      @disableInput()

    onSessionClosed: (data) =>
      @addStatus @T('Chat closed by %s', data.realname)
      @disableComposeInput()
      @setAgentOnlineState 'offline'
      @inactiveTimeout.stop()

      # Revisi desain -- header tab Messages balik ke judul polos
      # "Messages" (bukan tetap menampilkan nama agent dari sesi yang
      # SUDAH berakhir) begitu sesi ditutup, tanpa perlu tunggu ganti
      # tab dulu.
      @agent = undefined
      @updateHeader()

      @options.onSessionClosed?(data)

      # Atas permintaan user: layar feedback rating SEKARANG JUGA
      # muncul kalau AGENT SENDIRI yang menutup sesi (klik tombol
      # "Disconnect" di sisi agent) -- SEBELUMNYA cuma muncul kalau
      # customer sendiri yang menutup (`exitChat`). `data.
      # closed_by_agent` (backend, `chat_session_close.rb`) SENGAJA
      # HANYA `true` utk klik tombol DELIBERATE tsb -- TIDAK PERNAH utk
      # penutupan pasif (`Chat.cleanup_close`, scheduler, socket
      # putus/reload/tab ditutup TANPA klik apa pun) sesuai
      # permintaan eksplisit user ("bukan karena status socket").
      # `@sessionId` dicek dulu (jaga-jaga event ini nyasar terpanggil
      # 2x/sesi sudah bersih) -- pola `@lastSessionId`/`setSessionId
      # undefined` SAMA PERSIS dgn `sessionClose()` (dipakai jalur
      # customer-initiated), TANPA `@send 'chat_session_close'` lagi
      # (agent SUDAH mengirim itu, customer di sini murni PENERIMA).
      if data.closed_by_agent and @sessionId
        sessionStorage.removeItem 'unfinished_message'
        @lastSessionId = @sessionId
        @setSessionId undefined
        setTimeout (=> @showFeedback(true)), 2000

    # Atas permintaan user (mockup `Messages.dc.html`): penanda
    # "sudah dibaca" ala WhatsApp. Server menandai "read up to now"
    # secara BULK (semua pesan customer yang belum terbaca sekaligus,
    # bukan per-pesan granular -- lihat `chat_session_message_read.rb`)
    # setiap kali agent fokus/klik ke jendela chat, jadi cukup cari
    # SEMUA bubble customer yang MASIH berstatus "sent" (centang 1) di
    # DOM saat ini dan naikkan ke "read" (centang 2, biru) -- tidak
    # perlu mencocokkan id pesan satu-satu.
    #
    # Bug ditemukan user (screenshot: ikon centang berubah jadi bentuk
    # rusak SETELAH pesan ditandai dibaca, TAPI benar lagi begitu
    # halaman dimuat ulang) -- root cause: method ini py SVG hardcode
    # SENDIRI (`.html(...)` di bawah), TERLEWAT saat ikon status
    # diganti dari polyline stroke-based ke path `mdiCheckAll` fill-
    # based (lihat `views/message.eco`/`attachment_message.eco`). SVG
    # polyline LAMA yg disuntik di sini (dirancang utk `fill:none;
    # stroke:currentColor`) ke-timpa CSS BARU (`.zammad-chat-message-
    # status svg { fill:currentColor; stroke:none }`, atribut presentasi
    # SVG SELALU kalah dari rule stylesheet) -- 2 polyline TERBUKA
    # (bukan shape tertutup) yg di-FILL PAKSA otomatis "ditutup" garis
    # lurus balik ke titik awal, membentuk 2 baji/panah solid yg
    # terdistorsi, PERSIS gambar yg dilaporkan user.
    # Diperbaiki: `.html(...)` DIHAPUS TOTAL, bukan disinkronkan ulang
    # -- bentuk ikon SEKARANG SELALU SAMA (`mdiCheckAll`) utk kedua
    # status, HANYA warnanya yg beda (lewat class, CSS `.zammad-chat-
    # message-status--sent`/`--read`) -- tidak ada lagi alasan utk
    # mengganti isi SVG sama sekali, menghapus SELURUH kelas bug ini
    # (tidak ada lagi 2 sumber ikon yg bisa tidak sinkron).
    markMessagesRead: =>
      statusEls = @el.find('.zammad-chat-message--customer .zammad-chat-message-status--sent')
      return if !statusEls.length

      statusEls
        .removeClass('zammad-chat-message-status--sent')
        .addClass('zammad-chat-message-status--read')
        .attr('aria-label', @T('Read'))

    setSessionId: (id) =>
      @sessionId = id
      if id is undefined
        sessionStorage.removeItem 'sessionId'
      else
        sessionStorage.setItem 'sessionId', id

    # Atas permintaan user ("mau ada welcome greeting dari agent saat
    # terkoneksi") -- param baru `showGreeting` (default true), mirror
    # persis dari chat-no-jquery.coffee (lihat catatan panjang di sana).
    onConnectionEstablished: (data, showGreeting = true) =>
      # stop delay of initial queue position
      if @onInitialQueueDelayId
        clearTimeout @onInitialQueueDelayId

      @inQueue = false
      if data.agent
        @agent = data.agent
      if data.session_id
        @setSessionId data.session_id

      # empty old messages
      @el.find('.zammad-chat-body').html('')

      @el.find('.zammad-chat-agent').html @view('agent')
        agent: @agent
        initials: @initialsOf(@agent?.name)

      @showWelcomeGreeting() if showGreeting

      # Fase 5 -- Item No. 6, fitur tambahan enable/disable attachment
      # global+per-agent. Section 5.2.6. Tombol attach disembunyikan
      # by default (views/chat.eco) -- server yang memutuskan boleh
      # tidaknya lewat flag ini (widget tidak bisa baca Setting/
      # preferensi agent secara langsung), dikirim di payload
      # chat_session_start yang sama.
      @el.find('.js-chat-attach').toggleClass('zammad-chat-is-hidden', !data.attachment_enabled)

      @enableInput()

      @hideModal()
      @updateHeader()

      @input.trigger('focus') if not @isFullscreen

      @setAgentOnlineState 'online'

      @waitingListTimeout.stop()
      @idleTimeout.stop()
      @inactiveTimeout.start()
      @options.onConnectionEstablished?(data)

    # Mirror persis dari chat-no-jquery.coffee (lihat catatan panjang di
    # sana) -- sapaan otomatis dari agent, disuntik widget.
    showWelcomeGreeting: =>
      greeting = @phrases['chat_phrase_messages_welcome_greeting']
      return if !greeting
      @maybeAddTimestamp()
      @renderMessage
        message: greeting
        from: 'agent'
        time: @formatTime()

    showCustomerTimeout: ->
      @el.find('.zammad-chat-modal').html @view('customer_timeout')
        agent: @agent.name
        delay: @options.inactiveTimeout
      reload = ->
        location.reload()
      @el.find('.js-restart').on 'click', reload
      @sessionClose()

    showWaitingListTimeout: ->
      @el.find('.zammad-chat-modal').html @view('waiting_list_timeout')
        delay: @options.watingListTimeout
      reload = ->
        location.reload()
      @el.find('.js-restart').on 'click', reload
      @sessionClose()

    showLoader: ->
      @el.find('.zammad-chat-modal').html @view('loader')()

    # Atas permintaan user (mockup `Messages.dc.html`) -- avatar
    # inisial dipakai di header (agent.eco) MAUPUN di tiap bubble pesan
    # (message.eco). Dihitung SEKALI di sini (bukan diduplikasi di tiap
    # tempat) -- 2 kata pertama, huruf awal masing-masing, huruf besar.
    initialsOf: (name) ->
      return '' if !name
      parts = name.trim().split(/\s+/)
      ((parts[0]?[0] || '') + (parts[1]?[0] || '')).toUpperCase()

    # Atas permintaan user ("logo pada home mengambil dari setting
    # logo zammad") -- `home.eco` dirender SEKALI saat widget dimuat
    # (`renderBase`, tanpa data server), jadi TIDAK BISA langsung berisi
    # logo asli sejak awal -- diisi ULANG di sini begitu respons
    # `chat_status_customer` (yg SUDAH SELALU dikirim tiap widget
    # dimuat) datang membawa `logo_url`. `background:none` eksplisit --
    # logo asli TIDAK dipaksa masuk kotak lencana biru spt ikon generik
    # bawaan (banyak logo punya latar transparan/warna sendiri).
    # Atas permintaan user ("tambahkan juga logo pada halaman ini
    # [Prechat] seperti home dan offline home") -- selector diperluas
    # ke `.zammad-chat-prechat-icon` (jQuery `.html()`/`.css()` pada
    # koleksi >1 elemen otomatis meng-clone node yg disisipkan utk tiap
    # elemen, aman dipakai bersama).
    updateHomeLogo: (url) =>
      marks = @el.find('.zammad-chat-home-logo-mark, .zammad-chat-prechat-icon')
      marks.css('background', 'none')
      marks.html $('<img>').attr(src: url, alt: '').css(width: '100%', height: '100%', 'object-fit': 'contain')

    # Enhancement 4 -- "buatkan semua frase dalam widget configurable".
    # Pola SAMA dgn `updateHomeLogo` di atas: `chat_status_customer`
    # SELALU membawa `phrases` (lihat backend), tapi tab Home & Help
    # SUDAH terlanjur dirender SEKALI di awal `render()` (baris
    # `@el.find('.zammad-chat-tab-body--home').html @view('home')()`
    # dkk) SEBELUM balasan WS pertama ini tiba -- jadi keduanya perlu
    # digambar ULANG di sini supaya teksnya ikut ter-update dari
    # hardcode default ke nilai Setting (kalau admin sudah mengubahnya).
    # Screen LAIN (Prechat/Waiting/Otp/Compose/Sent/Feedback/dst) TIDAK
    # perlu penanganan khusus -- semuanya baru dirender ON-DEMAND lewat
    # `@view(...)` SETELAH titik ini, jadi otomatis kebagian `@phrases`
    # yang sudah benar sejak render pertamanya.
    updatePhrases: (phrases) =>
      @phrases = phrases
      return if !@el
      @el.find('.zammad-chat-tab-body--home').html @view('home')()
      @el.find('.zammad-chat-tab-body--help').html @view('help')()
      # `.zammad-chat-tab-body--help` di atas baru diganti TOTAL --
      # daftar KB yg mungkin sudah tampil (kalau visitor sempat buka
      # tab Help sebelum reconnect ini terjadi) ikut hilang. Ditandai
      # BELUM dimuat lagi (`@kbLoaded = false`) supaya `switchTab`
      # memuat ulang begitu tab ini dibuka lagi -- kalau tab Help
      # KEBETULAN sedang aktif SAAT INI JUGA, muat ulang LANGSUNG
      # (tidak nunggu switch tab yg tidak akan pernah terjadi krn
      # tabnya memang sudah aktif).
      if @activeTab is 'help'
        @loadKnowledgeBase(true)
      else
        @kbLoaded = false
      # `views/chat.eco` (shell luar, BEDA dari 2 tab body di atas)
      # dirender SEKALI SAJA di awal `render()` dan tidak pernah
      # digambar ulang -- disentuh manual di sini, pola SAMA dgn
      # `applyOfflineHomeState()`'s penggantian `.zammad-chat-welcome-subtext`.
      @el.find('.zammad-chat-welcome-title').html @T(@phrases['chat_phrase_home_greeting'] || 'Hi there') + ' 👋'
      @el.find('.zammad-chat-welcome-subtext').text @T(@phrases['chat_phrase_home_subtitle'] || 'How can we help you today?')
      @el.find('.zammad-chat-input').attr('placeholder', @T(@phrases['chat_phrase_messages_compose_placeholder'] || 'Compose your message…'))

      # Bug ditemukan user (screenshot: header online tapi notice
      # offline MASIH tampil) -- direproduksi Playwright & dikonfirmasi
      # akar masalahnya: WS BISA reconnect kapan saja (`Io`'s `onOpen:
      # @render`, bukan cuma sekali di awal), `chat_status_customer`
      # terkirim ULANG tiap itu terjadi. Baris2 DI ATAS ini SELALU
      # meng-reset ke tampilan ONLINE (fresh dari template), TAPI
      # kalau agent MASIH offline saat reconnect itu terjadi,
      # `@offlineMode` (di-set SEKALI di `enterOfflineMode()`) TETAP
      # `true` -- jadi di sinilah reset ke online td HARUS ditimpa lagi
      # ke tampilan offline, PERSIS spt saat pertama kali masuk mode
      # ini. Dipanggil DI SINI (bukan cuma di `enterOfflineMode()`)
      # supaya efeknya terulang tiap kali reset ini terjadi, tidak
      # cuma sekali.
      @applyOfflineHomeState()
      # Logo custom (lihat catatan panjang di `chat_status_customer`
      # handler) HARUS dipasang ULANG di sini, SETELAH `.zammad-chat-
      # tab-body--home` digambar ulang di atas -- pola SAMA persis
      # dgn `@applyOfflineHomeState()` di baris sebelum ini.
      @updateHomeLogo(@logoUrl) if @logoUrl

    # Atas permintaan user (mockup `Messages.dc.html`, "tidak ada time
    # per chat") -- jam kecil di bawah TIAP bubble pesan (dulu HANYA
    # ada satu pembagi tanggal/jam per hari/jeda lama, lihat
    # `maybeAddTimestamp`, TIDAK PERNAH per-pesan). Format "HH:MM"
    # SAMA persis dgn yang sudah dipakai pembagi tanggal itu
    # (`toTimeString().substr(0,5)`), supaya konsisten satu gaya jam di
    # seluruh widget -- bukan format baru. `isoString` opsional: pesan
    # AGENT dari server sudah bawa `created_at` asli (`chat_message.
    # attributes`, lib/sessions/event/chat_session_message.rb) --
    # dipakai itu, BUKAN jam klik lokal (bisa meleset kalau ada
    # latency). Pesan CUSTOMER sendiri (render lokal instan, sebelum
    # respons server) tidak punya itu -- fallback ke jam saat ini.
    formatTime: (isoString) ->
      date = if isoString then new Date(isoString) else new Date()
      date.toTimeString().substr(0, 5)

    # Atas permintaan user (mockup kartu lampiran gaya WhatsApp:
    # subjudul "TIPE · UKURAN") -- format byte -> label ringkas.
    # Ambang 1024 (biner, KB/MB asli) -- pola SAMA yg dipakai OS &
    # aplikasi file manager pada umumnya, BUKAN 1000 (SI/desimal).
    formatFileSize: (bytes) ->
      return '' if !bytes
      return "#{bytes} B" if bytes < 1024
      return "#{Math.round(bytes / 1024)} KB" if bytes < 1024 * 1024
      "#{(bytes / (1024 * 1024)).toFixed(1)} MB"

    # Label tipe file dari EKSTENSI nama file (bukan `Content-Type`
    # MIME) -- lebih dekat ke apa yg visitor lihat sendiri di nama
    # filenya (preseden `custom-file-text-fill`, mockup Messages.dc.html).
    fileExtensionLabel: (filename) ->
      return '' if !filename
      parts = filename.split('.')
      return '' if parts.length < 2
      parts[parts.length - 1].toUpperCase()

    # Gabungan "TIPE · UKURAN" utk subjudul kartu lampiran -- salah
    # satu kosong (mis. riwayat lama sebelum `size` ikut disalurkan)
    # tidak menyisakan separator menggantung.
    attachmentMeta: (filename, size) ->
      [@fileExtensionLabel(filename), @formatFileSize(size)].filter((part) -> part).join(' · ')

    setAgentOnlineState: (state) =>
      @state = state
      return if !@el
      capitalizedState = state.charAt(0).toUpperCase() + state.slice(1)
      @el
        .find('.zammad-chat-agent-status')
        .attr('data-status', state)
        .text @T(capitalizedState)  # @T('Online') @T('Offline')

    detectHost: ->
      protocol = 'ws://'
      if scriptProtocol is 'https'
        protocol = 'wss://'
      @options.host = "#{ protocol }#{ scriptHost }/ws"

    # Fase 5 -- Item No. 6 (Attachment). Section 5.2.1. Konversi
    # ws(s):// -> http(s):// yang SAMA dipakai `loadCss` di bawah --
    # `@options.host` adalah URL WebSocket (dipakai langsung sebagai
    # `new WebSocket(...)`), BUKAN origin HTTP, jadi tidak bisa dipakai
    # apa adanya untuk endpoint upload/download attachment.
    apiBaseUrl: =>
      @options.host
        .replace(/^wss/i, 'https')
        .replace(/^ws/i, 'http')
        .replace(/\/ws$/i, '')

    loadCss: ->
      return if !@options.cssAutoload
      url = @options.cssUrl
      if !url
        url = @options.host
          .replace(/^wss/i, 'https')
          .replace(/^ws/i, 'http')
          .replace(/\/ws$/i, '') # WebSocket may run on example.com/ws path
        url += '/assets/chat/chat.css'

      @log.debug "load css from '#{url}'"
      styles = "@import url('#{url}');"
      newSS = document.createElement('link')
      newSS.onload = @onCssLoaded
      newSS.rel = 'stylesheet'
      newSS.href = 'data:text/css,' + escape(styles)
      document.getElementsByTagName('head')[0].appendChild(newSS)

    onCssLoaded: =>
      @cssLoaded = true
      # Buka lagi elemen yg disembunyikan `renderBase` (lihat catatan
      # panjang di sana) -- KEDUANYA opsional (`?.`) krn urutan
      # ketibaan bisa terbalik: CSS BISA SAJA selesai duluan SEBELUM
      # WebSocket terhubung (`renderBase` belum pernah jalan sama
      # sekali di titik ini) -- `.css('display', '')` melepas override
      # inline, KEMBALI ke aturan `chat.css` yg SEKARANG sudah aktif
      # (bukan dipaksa ke `block` sembarangan).
      @el?.css('display', '')
      @launcherEl?.css('display', '')
      # Lihat catatan panjang di `@statusReceived` (handler
      # `chat_status_customer`) -- kebalikan urutan dari situ: status
      # BISA SAJA sudah diterima SEBELUM CSS ini selesai dimuat.
      @hidePreload() if @statusReceived
      if @socketReady
        @onReady()
      @options.onCssLoaded?()

    startTimeoutObservers: =>
      @idleTimeout = new Timeout(
        logPrefix: 'idleTimeout'
        debug: @options.debug
        timeout: @options.idleTimeout
        timeoutIntervallCheck: @options.idleTimeoutIntervallCheck
        callback: =>
          @log.debug 'Idle timeout reached, hide widget', new Date
          @destroy(remove: true)
      )
      @inactiveTimeout = new Timeout(
        logPrefix: 'inactiveTimeout'
        debug: @options.debug
        timeout: @options.inactiveTimeout
        timeoutIntervallCheck: @options.inactiveTimeoutIntervallCheck
        callback: =>
          @log.debug 'Inactive timeout reached, show timeout screen.', new Date
          @showCustomerTimeout()
          @destroy(remove: false)
      )
      @waitingListTimeout = new Timeout(
        logPrefix: 'waitingListTimeout'
        debug: @options.debug
        timeout: @options.waitingListTimeout
        timeoutIntervallCheck: @options.waitingListTimeoutIntervallCheck
        callback: =>
          @log.debug 'Waiting list timeout reached, show timeout screen.', new Date
          @showWaitingListTimeout()
          @destroy(remove: false)
      )

    disableScrollOnRoot: ->
      @rootScrollOffset = @scrollRoot.scrollTop()
      @scrollRoot.css
        overflow: 'hidden'
        position: 'fixed'

    enableScrollOnRoot: ->
      @scrollRoot.scrollTop @rootScrollOffset
      @scrollRoot.css
        overflow: ''
        position: ''

    # based on https://github.com/customd/jquery-visible/blob/master/jquery.visible.js
    # to have not dependency, port to coffeescript
    isVisible: (el, partial, hidden, direction) ->
      return if el.length < 1

      $w         = $(window)
      $t         = if el.length > 1 then el.eq(0) else el
      t          = $t.get(0)
      vpWidth    = $w.width()
      vpHeight   = $w.height()
      direction  = if direction then direction else 'both'
      clientSize = if hidden is true then t.offsetWidth * t.offsetHeight else true

      if typeof t.getBoundingClientRect is 'function'

        # Use this native browser method, if available.
        rec      = t.getBoundingClientRect()
        tViz     = rec.top >= 0 && rec.top    <  vpHeight
        bViz     = rec.bottom >  0 && rec.bottom <= vpHeight
        lViz     = rec.left >= 0 && rec.left   <  vpWidth
        rViz     = rec.right  >  0 && rec.right <= vpWidth
        vVisible = if partial then tViz || bViz else tViz && bViz
        hVisible = if partial then lViz || rViz else lViz && rViz

        if direction is 'both'
          return clientSize && vVisible && hVisible
        else if direction is 'vertical'
          return clientSize && vVisible
        else if direction is 'horizontal'
          return clientSize && hVisible
      else
        viewTop         = $w.scrollTop()
        viewBottom      = viewTop + vpHeight
        viewLeft        = $w.scrollLeft()
        viewRight       = viewLeft + vpWidth
        offset          = $t.offset()
        _top            = offset.top
        _bottom         = _top + $t.height()
        _left           = offset.left
        _right          = _left + $t.width()
        compareTop      = if partial is true then _bottom else _top
        compareBottom   = if partial is true then _top else _bottom
        compareLeft     = if partial is true then _right else _left
        compareRight    = if partial is true then _left else _right

        if direction is 'both'
          return !!clientSize && ((compareBottom <= viewBottom) && (compareTop >= viewTop)) && ((compareRight <= viewRight) && (compareLeft >= viewLeft))
        else if direction is 'vertical'
          return !!clientSize && ((compareBottom <= viewBottom) && (compareTop >= viewTop))
        else if direction is 'horizontal'
          return !!clientSize && ((compareRight <= viewRight) && (compareLeft >= viewLeft))

    isRetina: ->
      if window.matchMedia
        mq = window.matchMedia('only screen and (min--moz-device-pixel-ratio: 1.3), only screen and (-o-min-device-pixel-ratio: 2.6/2), only screen and (-webkit-min-device-pixel-ratio: 1.3), only screen  and (min-device-pixel-ratio: 1.3), only screen and (min-resolution: 1.3dppx)')
        return (mq && mq.matches || (window.devicePixelRatio > 1))
      false

    resizeImage: (dataURL, x = 'auto', y = 'auto', sizeFactor = 1, type, quallity, callback, force = true) ->

      # load image from data url
      imageObject = new Image()
      imageObject.onload = ->
        imageWidth  = imageObject.width
        imageHeight = imageObject.height
        console.log('ImageService', 'current size', imageWidth, imageHeight)
        if y is 'auto' && x is 'auto'
          x = imageWidth
          y = imageHeight

        # get auto dimensions
        if y is 'auto'
          factor = imageWidth / x
          y = imageHeight / factor

        if x is 'auto'
          factor = imageWidth / y
          x = imageHeight / factor

        # check if resize is needed
        resize = false
        if x < imageWidth || y < imageHeight
          resize = true
          x = x * sizeFactor
          y = y * sizeFactor
        else
          x = imageWidth
          y = imageHeight

        # create canvas and set dimensions
        canvas        = document.createElement('canvas')
        canvas.width  = x
        canvas.height = y

        # draw image on canvas and set image dimensions
        context = canvas.getContext('2d')
        context.drawImage(imageObject, 0, 0, x, y)

        # set quallity based on image size
        if quallity == 'auto'
          if x < 200 && y < 200
            quallity = 1
          else if x < 400 && y < 400
            quallity = 0.9
          else if x < 600 && y < 600
            quallity = 0.8
          else if x < 900 && y < 900
            quallity = 0.7
          else
            quallity = 0.6

        # execute callback with resized image
        newDataUrl = canvas.toDataURL(type, quallity)
        if resize
          console.log('ImageService', 'resize', x/sizeFactor, y/sizeFactor, quallity, (newDataUrl.length * 0.75)/1024/1024, 'in mb')
          callback(newDataUrl, x/sizeFactor, y/sizeFactor, true)
          return
        console.log('ImageService', 'no resize', x, y, quallity, (newDataUrl.length * 0.75)/1024/1024, 'in mb')
        callback(newDataUrl, x, y, false)

      # load image from data url
      imageObject.src = dataURL

    # taken from https://stackoverflow.com/questions/6690752/insert-html-at-caret-in-a-contenteditable-div/6691294#6691294
    pasteHtmlAtCaret: (html) ->
      sel = undefined
      range = undefined
      if window.getSelection
        sel = window.getSelection()
        if sel.getRangeAt && sel.rangeCount
          range = sel.getRangeAt(0)
          range.deleteContents()

          el = document.createElement('div')
          el.innerHTML = html
          frag = document.createDocumentFragment(node, lastNode)
          while node = el.firstChild
            lastNode = frag.appendChild(node)
          range.insertNode(frag)

          if lastNode
            range = range.cloneRange()
            range.setStartAfter(lastNode)
            range.collapse(true)
            sel.removeAllRanges()
            sel.addRange(range)
      else if document.selection && document.selection.type != 'Control'
        document.selection.createRange().pasteHTML(html)

    # (C) sbrin - https://github.com/sbrin
    # https://gist.github.com/sbrin/6801034
    wordFilter: (editor) ->
      content = editor.html()

      # Word comments like conditional comments etc
      content = content.replace(/<!--[\s\S]+?-->/gi, '')

      # Remove comments, scripts (e.g., msoShowComment), XML tag, VML content,
      # MS Office namespaced tags, and a few other tags
      content = content.replace(/<(!|script[^>]*>.*?<\/script(?=[>\s])|\/?(\?xml(:\w+)?|img|meta|link|style|\w:\w+)(?=[\s\/>]))[^>]*>/gi, '')

      # Convert <s> into <strike> for line-though
      content = content.replace(/<(\/?)s>/gi, '<$1strike>')

      # Replace nbsp entites to char since it's easier to handle
      # content = content.replace(/&nbsp;/gi, "\u00a0")
      content = content.replace(/&nbsp;/gi, ' ')

      # Convert <span style="mso-spacerun:yes">___</span> to string of alternating
      # breaking/non-breaking spaces of same length
      #content = content.replace(/<span\s+style\s*=\s*"\s*mso-spacerun\s*:\s*yes\s*;?\s*"\s*>([\s\u00a0]*)<\/span>/gi, (str, spaces) ->
      #  return if (spaces.length > 0) then spaces.replace(/./, " ").slice(Math.floor(spaces.length/2)).split("").join("\u00a0") else ''
      #)

      editor.html(content)

      # Parse out list indent level for lists
      $('p', editor).each( ->
        str = $(@).attr('style')
        matches = /mso-list:\w+ \w+([0-9]+)/.exec(str)
        if matches
          $(@).data('_listLevel',  parseInt(matches[1], 10))
      )

      # Parse Lists
      last_level = 0
      pnt = null
      $('p', editor).each(->
        cur_level = $(@).data('_listLevel')
        if cur_level != undefined
          txt = $(@).text()
          list_tag = '<ul></ul>'
          if (/^\s*\w+\./.test(txt))
            matches = /([0-9])\./.exec(txt)
            if matches
              start = parseInt(matches[1], 10)
              list_tag = if start > 1 then '<ol start="' + start + '"></ol>' else '<ol></ol>'
            else
              list_tag = '<ol></ol>'

          if cur_level > last_level
            if last_level == 0
              $(@).before(list_tag)
              pnt = $(@).prev()
            else
              pnt = $(list_tag).appendTo(pnt)

          if cur_level < last_level
            for i in [i..last_level-cur_level]
              pnt = pnt.parent()

          $('span:first', @).remove()
          pnt.append('<li>' + $(@).html() + '</li>')
          $(@).remove()
          last_level = cur_level
        else
          last_level = 0
      )

      $('[style]', editor).removeAttr('style')
      $('[align]', editor).removeAttr('align')
      $('span', editor).replaceWith(->
        $(@).contents()
      )
      $('span:empty', editor).remove()
      $("[class^='Mso']", editor).removeAttr('class')
      $('p:empty', editor).remove()
      editor

    removeAttribute: (element) ->
      return if !element
      $element = $(element)
      for att in element.attributes
        if att && att.name
          element.removeAttribute(att.name)
          #$element.removeAttr(att.name)

      $element.removeAttr('style')
        .removeAttr('class')
        .removeAttr('lang')
        .removeAttr('type')
        .removeAttr('align')
        .removeAttr('id')
        .removeAttr('wrap')
        .removeAttr('title')

    removeAttributes: (html, parent = true) =>
      if parent
        html.each((index, element) => @removeAttribute(element) )
      html.find('*').each((index, element) => @removeAttribute(element) )
      html

  window.ZammadChat = ZammadChat
