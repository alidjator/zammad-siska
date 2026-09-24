do(window) ->

  scripts = document.getElementsByTagName('script')

  # search for script to get protocol and hostname for ws connection
  myScript = scripts[scripts.length - 1]
  scriptProtocol = window.location.protocol.replace(':', '') # set default protocol
  if myScript && myScript.src
    scriptHost = myScript.src.match('.*://([^:/]*).*')[1]
    scriptProtocol = myScript.src.match('(.*)://[^:/]*.*')[1]

  # Atas permintaan user -- mirror persis dari chat.coffee: halaman
  # HOST lintas-domain sering TIDAK PUNYA `<meta name="viewport">`,
  # bikin browser mobile merender di lebar virtual ~980px lalu
  # zoom-out (widget tampil kecil, media query & `matchMedia` JS
  # sama-sama tidak aktif). Disisipkan SEKALI, PALING AWAL, HANYA
  # kalau belum ada.
  ensureViewportMeta = ->
    return if document.querySelector('meta[name="viewport"]')
    return if !document.head
    meta = document.createElement('meta')
    meta.setAttribute('name', 'viewport')
    meta.setAttribute('content', 'width=device-width, initial-scale=1')
    document.head.appendChild(meta)

  ensureViewportMeta()

  # Define the plugin class
  class Core
    defaults:
      debug: false

    constructor: (options) ->
      @options = {}

      for key, value of @defaults
        @options[key] = value

      for key, value of options
        @options[key] = value

  class Base extends Core
    constructor: (options) ->
      super(options)

      @log = new Log(debug: @options.debug, logPrefix: @options.logPrefix || @logPrefix)

  class Log extends Core
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
      element = document.querySelector('.js-chatLogDisplay')
      if element
        element.innerHTML = '<div>' + logString + '</div>' + element.innerHTML

  class Timeout extends Base
    timeoutStartedAt: null
    logPrefix: 'timeout'
    defaults:
      debug: false
      timeout: 4
      timeoutIntervallCheck: 0.5

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
    # Atas permintaan user ("mau" -- auto-reconnect websocket) --
    # mirror persis dari chat.coffee (lihat komentar detail di sana).
    maxReconnectAttempts: 6
    reconnectBaseDelay: 1000
    reconnectMaxDelay: 30000

    set: (params) =>
      for key, value of params
        @options[key] = value

    connect: =>
      @log.debug "Connecting to #{@options.host}"
      @ws = new window.WebSocket("#{@options.host}")
      @ws.onopen = (e) =>
        @log.debug 'onOpen', e
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
        # TIDAK langsung panggil `onError` di sini lagi -- lihat
        # catatan sama di chat.coffee.
        @log.debug 'onError', e

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
      if @reconnectTimeoutId
        clearTimeout(@reconnectTimeoutId)
        @reconnectTimeoutId = undefined
      @reconnectAttempts = 0
      # Bug tepi -- lihat catatan sama di chat.coffee: `WebSocket#close()`
      # no-op utk socket yg SUDAH `CLOSED`/`CLOSING`, `onClose` tidak
      # akan pernah terpanggil tanpa cabang ini.
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
      return if !@ws or @ws.readyState isnt window.WebSocket.OPEN
      msg = JSON.stringify
        event: event
        data: data
      @ws.send msg

    ping: =>
      localPing = =>
        @send('ping')
      @pingDelayId = setTimeout(localPing, 29000)

  # Ikon widget SERAGAM (permintaan user, mockup "Ikon seragam - Phosphor
  # Duotone"): SATU sumber path, diekstrak apa adanya dari
  # `fonts/phosphor/duotone/selection.json` kit (grid 1024, [lapisan isi,
  # lapisan garis]). Tetap SVG inline (tanpa request font ~460KB, aman dari
  # bentrok CSS/ID situs klien). Dipanggil lewat `@icon(name, size, opts)`
  # di template (disuntikkan di `view:`) atau `siskaIcon(...)` di sini.
  # tone: 'single' (default, garis saja -- ikon kecil fungsional), 'full'
  # (isi 0.2 -- ikon status besar), 'active' (isi via class
  # `.zammad-chat-icon-fill`, tampil saat state aktif, lihat chat.scss).
  # Logo mark Home SENGAJA tidak lewat sini (brand mark, tetap sprite).
  SISKA_ICONS =
    'arrow-bend-up-left': ["M320 224v384l-192-192z", "M512 384h-160v-160c0-0.007 0-0.016 0-0.025 0-17.673-14.327-32-32-32-8.843 0-16.848 3.587-22.64 9.385l-0 0-192 192c-5.798 5.792-9.385 13.797-9.385 22.64s3.587 16.848 9.385 22.64l0 0 192 192c5.792 5.798 13.797 9.385 22.64 9.385 17.673 0 32-14.327 32-32 0-0.009-0-0.018-0-0.027l0 0.001v-160h160c194.313 0.228 351.772 157.687 352 351.978l0 0.022c0 17.673 14.327 32 32 32s32-14.327 32-32v0c-0.25-229.65-186.35-415.75-415.976-416l-0.024-0zM288 530.76l-114.76-114.76 114.76-114.76z"]
    'arrow-circle-down': ["M896 512c0 212.077-171.923 384-384 384s-384-171.923-384-384c0-212.077 171.923-384 384-384v0c212.077 0 384 171.923 384 384v0z", "M512 96c-229.75 0-416 186.25-416 416s186.25 416 416 416c229.75 0 416-186.25 416-416v0c-0.25-229.65-186.35-415.75-415.976-416l-0.024-0zM512 864c-194.404 0-352-157.596-352-352s157.596-352 352-352c194.404 0 352 157.596 352 352v0c-0.228 194.313-157.687 351.772-351.978 352l-0.022 0zM662.64 521.36c5.798 5.792 9.385 13.797 9.385 22.64s-3.587 16.848-9.385 22.64l-0 0-128 128c-5.792 5.798-13.797 9.385-22.64 9.385s-16.848-3.587-22.64-9.385l-0-0-128-128c-5.794-5.794-9.378-13.799-9.378-22.64 0-17.683 14.335-32.018 32.018-32.018 8.841 0 16.846 3.584 22.64 9.378l73.36 73.4v-242.76c0-17.673 14.327-32 32-32s32 14.327 32 32v0 242.76l73.36-73.4c5.792-5.798 13.797-9.385 22.64-9.385s16.848 3.587 22.64 9.385l0 0z"]
    'book-open-text': ["M928 256v512c0 17.673-14.327 32-32 32v0h-256c-70.692 0-128 57.308-128 128v0-576c0-70.692 57.308-128 128-128v0h256c17.673 0 32 14.327 32 32v0z", "M896 192h-256c-52.165 0-98.5 24.964-127.708 63.598l-0.292 0.402c-29.5-39.036-75.835-64-128-64v0h-256c-35.346 0-64 28.654-64 64v0 512c0 35.346 28.654 64 64 64v0h256c53.019 0 96 42.981 96 96v0c0 17.673 14.327 32 32 32s32-14.327 32-32v0c0-53.019 42.981-96 96-96v0h256c35.346 0 64-28.654 64-64v0-512c0-35.346-28.654-64-64-64v0zM384 768h-256v-512h256c53.019 0 96 42.981 96 96v0 448c-26.32-19.976-59.629-32-95.747-32-0.089 0-0.178 0-0.267 0l0.014-0zM896 768h-256c-0.075-0-0.164-0-0.253-0-36.117 0-69.426 12.024-96.142 32.288l0.396-0.288v-448c0-53.019 42.981-96 96-96v0h256zM640 352h160c17.673 0 32 14.327 32 32s-14.327 32-32 32v0h-160c-17.673 0-32-14.327-32-32s14.327-32 32-32v0zM832 512c0 17.673-14.327 32-32 32v0h-160c-17.673 0-32-14.327-32-32s14.327-32 32-32v0h160c17.673 0 32 14.327 32 32v0zM832 640c0 17.673-14.327 32-32 32v0h-160c-17.673 0-32-14.327-32-32s14.327-32 32-32v0h160c17.673 0 32 14.327 32 32v0z"]
    'caret-down': ["M832 384l-320 320-320-320z", "M861.56 371.76c-4.934-11.696-16.306-19.757-29.56-19.76l-640-0c-0.007-0-0.016-0-0.025-0-17.673 0-32 14.327-32 32 0 8.843 3.587 16.848 9.385 22.64l0 0 320 320c5.792 5.798 13.797 9.385 22.64 9.385s16.848-3.587 22.64-9.385l0-0 320-320c5.785-5.79 9.363-13.786 9.363-22.618 0-4.425-0.898-8.639-2.522-12.472l0.079 0.21zM512 658.76l-242.76-242.76h485.52z"]
    'caret-right': ["M704 512l-320 320v-640z", "M726.64 489.36l-320-320c-5.792-5.798-13.797-9.385-22.64-9.385-17.673 0-32 14.327-32 32 0 0.009 0 0.018 0 0.027l-0-0.001v640c-0 0.007-0 0.016-0 0.025 0 17.673 14.327 32 32 32 8.843 0 16.848-3.587 22.64-9.385l0-0 320-320c5.798-5.792 9.385-13.797 9.385-22.64s-3.587-16.848-9.385-22.64l-0-0zM416 754.76v-485.52l242.76 242.76z"]
    'chat-circle-dots': ["M896 512c0 0.014 0 0.031 0 0.048 0 212.077-171.923 384-384 384-70.806 0-137.136-19.164-194.086-52.588l1.806 0.98-149.56 49.88c-3.021 1.042-6.502 1.644-10.124 1.644-17.673 0-32-14.327-32-32 0-3.622 0.602-7.103 1.71-10.349l-0.067 0.225 49.88-149.56c-32.414-55.124-51.56-121.425-51.56-192.197 0-212.077 171.923-384 384-384 212.048 0 383.953 171.875 384 383.912l0 0.005z", "M512 96c-0.027-0-0.059-0-0.091-0-229.75 0-416 186.25-416 416 0 71.565 18.071 138.91 49.9 197.72l-1.089-2.2-45.4 136.2c-2.084 6.042-3.287 13.004-3.287 20.247 0 35.346 28.654 64 64 64 7.243 0 14.205-1.203 20.698-3.421l-0.45 0.134 136.2-45.4c56.567 30.683 123.852 48.72 195.349 48.72 229.75 0 416-186.25 416-416 0-229.69-186.152-415.903-415.82-416l-0.009-0zM512 864c-0.071 0-0.155 0-0.239 0-64.812 0-125.526-17.542-177.654-48.137l1.654 0.897c-4.587-2.706-10.105-4.309-15.997-4.32l-0.003-0c-3.623 0.002-7.103 0.617-10.34 1.747l0.22-0.067-149.64 49.88 49.88-149.6c1.048-3.029 1.653-6.519 1.653-10.151 0-5.895-1.594-11.417-4.374-16.16l0.082 0.151c-29.734-50.544-47.298-111.341-47.298-176.24 0-194.404 157.596-352 352-352s352 157.596 352 352c0 194.384-157.563 351.967-351.939 352l-0.003 0zM560 512c0 26.51-21.49 48-48 48s-48-21.49-48-48c0-26.51 21.49-48 48-48v0c26.51 0 48 21.49 48 48v0zM384 512c0 26.51-21.49 48-48 48s-48-21.49-48-48c0-26.51 21.49-48 48-48v0c26.51 0 48 21.49 48 48v0zM736 512c0 26.51-21.49 48-48 48s-48-21.49-48-48c0-26.51 21.49-48 48-48v0c26.51 0 48 21.49 48 48v0z"]
    'check': ["M928 224v576c0 35.346-28.654 64-64 64v0h-704c-35.346 0-64-28.654-64-64v0-576c0-35.346 28.654-64 64-64v0h704c35.346 0 64 28.654 64 64v0z", "M822.64 342.64l-384 384c-5.792 5.798-13.797 9.385-22.64 9.385s-16.848-3.587-22.64-9.385l-0-0-160-160c-5.794-5.794-9.378-13.799-9.378-22.64 0-17.683 14.335-32.018 32.018-32.018 8.841 0 16.846 3.584 22.64 9.378l137.36 137.4 361.36-361.4c5.794-5.794 13.799-9.378 22.64-9.378 17.683 0 32.018 14.335 32.018 32.018 0 8.841-3.584 16.846-9.378 22.64l0-0z"]
    'check-circle': ["M896 512c0 212.077-171.923 384-384 384s-384-171.923-384-384c0-212.077 171.923-384 384-384v0c212.077 0 384 171.923 384 384v0z", "M694.64 393.36c5.798 5.792 9.385 13.797 9.385 22.64s-3.587 16.848-9.385 22.64l-0 0-224 224c-5.792 5.798-13.797 9.385-22.64 9.385s-16.848-3.587-22.64-9.385l-0-0-96-96c-5.794-5.794-9.378-13.799-9.378-22.64 0-17.683 14.335-32.018 32.018-32.018 8.841 0 16.846 3.584 22.64 9.378l73.36 73.4 201.36-201.4c5.792-5.798 13.797-9.385 22.64-9.385s16.848 3.587 22.64 9.385l0 0zM928 512c0 229.75-186.25 416-416 416s-416-186.25-416-416c0-229.75 186.25-416 416-416v0c229.65 0.25 415.75 186.35 416 415.976l0 0.024zM864 512c0-194.404-157.596-352-352-352s-352 157.596-352 352c0 194.404 157.596 352 352 352v0c194.313-0.228 351.772-157.687 352-351.978l0-0.022z"]
    'checks': ["M960 256v512c0 35.346-28.654 64-64 64v0h-768c-35.346 0-64-28.654-64-64v0-512c0-35.346 28.654-64 64-64v0h768c35.346 0 64 28.654 64 64v0z", "M566.64 406.64l-224 224c-5.792 5.798-13.797 9.385-22.64 9.385s-16.848-3.587-22.64-9.385l-0-0-96-96c-5.794-5.794-9.378-13.799-9.378-22.64 0-17.683 14.335-32.018 32.018-32.018 8.841 0 16.846 3.584 22.64 9.378h0l73.36 73.4 201.36-201.4c5.794-5.794 13.799-9.378 22.64-9.378 17.683 0 32.018 14.335 32.018 32.018 0 8.841-3.584 16.846-9.378 22.64l0-0zM854.64 361.36c-5.792-5.798-13.797-9.385-22.64-9.385s-16.848 3.587-22.64 9.385l-0 0-201.36 201.4-41.36-41.4c-5.794-5.794-13.799-9.378-22.64-9.378-17.683 0-32.018 14.335-32.018 32.018 0 8.841 3.584 16.846 9.378 22.64l64 64c5.792 5.798 13.797 9.385 22.64 9.385s16.848-3.587 22.64-9.385l0-0 224-224c5.798-5.792 9.385-13.797 9.385-22.64s-3.587-16.848-9.385-22.64l-0-0z"]
    'clock': ["M896 512c0 212.077-171.923 384-384 384s-384-171.923-384-384c0-212.077 171.923-384 384-384v0c212.077 0 384 171.923 384 384v0z", "M512 96c-229.75 0-416 186.25-416 416s186.25 416 416 416c229.75 0 416-186.25 416-416v0c-0.25-229.65-186.35-415.75-415.976-416l-0.024-0zM512 864c-194.404 0-352-157.596-352-352s157.596-352 352-352c194.404 0 352 157.596 352 352v0c-0.228 194.313-157.687 351.772-351.978 352l-0.022 0zM768 512c0 17.673-14.327 32-32 32v0h-224c-17.673 0-32-14.327-32-32v0-224c0-17.673 14.327-32 32-32s32 14.327 32 32v0 192h192c17.673 0 32 14.327 32 32v0z"]
    'download-simple': ["M672 448l-160 160-160-160z", "M896 608v224c0 35.346-28.654 64-64 64v0h-640c-35.346 0-64-28.654-64-64v0-224c0-17.673 14.327-32 32-32s32 14.327 32 32v0 224h640v-224c0-17.673 14.327-32 32-32s32 14.327 32 32v0zM329.36 470.64c-5.798-5.792-9.385-13.797-9.385-22.64 0-17.673 14.327-32 32-32 0.009 0 0.018 0 0.027 0l127.999-0v-256c0-17.673 14.327-32 32-32s32 14.327 32 32v0 256h128c0.007-0 0.016-0 0.025-0 17.673 0 32 14.327 32 32 0 8.843-3.587 16.848-9.385 22.64l-0 0-160 160c-5.792 5.798-13.797 9.385-22.64 9.385s-16.848-3.587-22.64-9.385l-0-0zM429.36 480l82.64 82.76 82.76-82.76z"]
    'heart': ["M928 376c0 264-416 488-416 488s-416-224-416-488c0-119.294 96.706-216 216-216v0c90.36 0 167.76 49.24 200 128 32.24-78.76 109.64-128 200-128 119.294 0 216 96.706 216 216v0z", "M712 128c-82.6 0-154.92 35.52-200 95.56-45.080-60.040-117.4-95.56-200-95.56-136.903 0.159-247.841 111.097-248 247.985l-0 0.015c0 280 415.16 506.64 432.84 516 4.385 2.405 9.607 3.819 15.16 3.819s10.775-1.414 15.327-3.903l-0.167 0.084c17.68-9.36 432.84-236 432.84-516-0.159-136.903-111.097-247.841-247.985-248l-0.015-0zM512 827.2c-73.040-42.56-384-236.44-384-451.2 0.136-101.565 82.435-183.864 183.987-184l0.013-0c77.8 0 143.12 41.44 170.4 108 4.916 11.742 16.312 19.841 29.6 19.841s24.684-8.099 29.521-19.63l0.079-0.211c27.28-66.68 92.6-108 170.4-108 101.565 0.136 183.864 82.435 184 183.987l0 0.013c0 214.44-311.040 408.6-384 451.2z"]
    'house': ["M864 462.16v369.84c0 17.673-14.327 32-32 32v0h-192c-17.673 0-32-14.327-32-32v0-192c0-17.673-14.327-32-32-32v0h-128c-17.673 0-32 14.327-32 32v0 192c0 17.673-14.327 32-32 32v0h-192c-17.673 0-32-14.327-32-32v0-369.84c0.001-9.373 4.032-17.805 10.455-23.657l0.025-0.023 320-302.16c5.663-5.169 13.232-8.335 21.54-8.335s15.877 3.166 21.565 8.358l-0.025-0.023 320 302.16c6.425 5.873 10.44 14.291 10.44 23.647 0 0.012-0 0.023-0 0.035l0-0.002z", "M875.32 415.080l-320-301.92c-0.158-0.138-0.302-0.282-0.435-0.435l-0.005-0.005c-11.324-10.327-26.453-16.652-43.060-16.652s-31.736 6.325-43.11 16.697l0.050-0.045-0.44 0.44-319.64 301.92c-12.732 11.735-20.68 28.495-20.68 47.11 0 0.003 0 0.007 0 0.010l-0-0.001v369.8c0 35.346 28.654 64 64 64v0h192c35.346 0 64-28.654 64-64v0-192h128v192c0 35.346 28.654 64 64 64v0h192c35.346 0 64-28.654 64-64v0-369.8c0-0.003 0-0.006 0-0.010 0-18.616-7.948-35.375-20.636-47.070l-0.044-0.040zM832 832h-192v-192c0-35.346-28.654-64-64-64v0h-128c-35.346 0-64 28.654-64 64v0 192h-192v-369.8l0.44-0.4 319.56-301.8 320.040 302.12z"]
    'info': ["M896 512c0 212.077-171.923 384-384 384s-384-171.923-384-384c0-212.077 171.923-384 384-384v0c212.077 0 384 171.923 384 384v0z", "M576 704c0 17.673-14.327 32-32 32v0c-35.346 0-64-28.654-64-64v0-160c-17.673 0-32-14.327-32-32s14.327-32 32-32v0c35.346 0 64 28.654 64 64v0 160c17.673 0 32 14.327 32 32v0zM928 512c0 229.75-186.25 416-416 416s-416-186.25-416-416c0-229.75 186.25-416 416-416v0c229.65 0.25 415.75 186.35 416 415.976l0 0.024zM864 512c0-194.404-157.596-352-352-352s-352 157.596-352 352c0 194.404 157.596 352 352 352v0c194.313-0.228 351.772-157.687 352-351.978l0-0.022zM496 384c26.51 0 48-21.49 48-48s-21.49-48-48-48c-26.51 0-48 21.49-48 48v0c0 26.51 21.49 48 48 48v0z"]
    'lock': ["M864 384v448c0 17.673-14.327 32-32 32v0h-640c-17.673 0-32-14.327-32-32v0-448c0-17.673 14.327-32 32-32v0h640c17.673 0 32 14.327 32 32v0z", "M832 320h-128v-96c0-106.039-85.961-192-192-192s-192 85.961-192 192v0 96h-128c-35.346 0-64 28.654-64 64v0 448c0 35.346 28.654 64 64 64v0h640c35.346 0 64-28.654 64-64v0-448c0-35.346-28.654-64-64-64v0zM384 224c0-70.692 57.308-128 128-128s128 57.308 128 128v0 96h-256zM832 832h-640v-448h640v448zM560 608c0 26.51-21.49 48-48 48s-48-21.49-48-48c0-26.51 21.49-48 48-48v0c26.51 0 48 21.49 48 48v0z"]
    'magnifying-glass': ["M768 448c0 176.731-143.269 320-320 320s-320-143.269-320-320c0-176.731 143.269-320 320-320v0c176.731 0 320 143.269 320 320v0z", "M918.64 873.36l-200.24-200.24c50.917-60.738 81.843-139.736 81.843-225.957 0-194.868-157.972-352.84-352.84-352.84s-352.84 157.972-352.84 352.84c0 194.868 157.972 352.84 352.84 352.84 86.111 0 165.018-30.847 226.272-82.095l-0.555 0.452 200.24 200.28c5.794 5.794 13.799 9.378 22.64 9.378 17.683 0 32.018-14.335 32.018-32.018 0-8.841-3.584-16.846-9.378-22.64l0 0zM160 448c0-159.058 128.942-288 288-288s288 128.942 288 288c0 159.058-128.942 288-288 288v0c-158.985-0.182-287.818-129.015-288-287.983l-0-0.017z"]
    'paper-plane-right': ["M879.64 539.44l-671.92 384.56c-4.498 2.561-9.883 4.071-15.62 4.071-17.673 0-32-14.327-32-32 0-3.855 0.682-7.551 1.931-10.974l-0.071 0.222 124-362.84c1.198-3.201 1.891-6.899 1.891-10.76s-0.693-7.559-1.962-10.978l0.071 0.218-124-361.88c-1.178-3.2-1.86-6.896-1.86-10.751 0-17.673 14.327-32 32-32 5.737 0 11.122 1.51 15.779 4.154l-0.158-0.083 672 383.4c9.715 5.616 16.147 15.956 16.147 27.797 0 11.874-6.467 22.238-16.072 27.76l-0.155 0.082z", "M895.48 456l-672-383.56c-9.013-5.147-19.808-8.182-31.311-8.182-35.346 0-64 28.654-64 64 0 7.531 1.301 14.759 3.69 21.47l-0.139-0.447 124 361.88c-0.008 0.060-0.012 0.13-0.012 0.2s0.004 0.14 0.013 0.208l-0.001-0.008c-0.011 0.060-0.017 0.129-0.017 0.2s0.006 0.14 0.018 0.207l-0.001-0.007-124 362.68c-2.325 6.36-3.67 13.703-3.67 21.36 0 35.329 28.625 63.971 63.947 64l0.003 0c11.653-0.031 22.572-3.144 31.993-8.566l-0.313 0.166 671.64-384.2c19.669-11.172 32.722-31.98 32.722-55.836 0-23.776-12.965-44.523-32.21-55.559l-0.312-0.165zM192 896v-0.36l120.56-351.64h231.44c17.673 0 32-14.327 32-32s-14.327-32-32-32v0h-231.12l-120.64-351.52-0.24-0.48 672 383.32z"]
    'paperclip': ["M723 419l93 93-328.24 327.76c-34.631 34.087-82.185 55.134-134.654 55.134-106.039 0-192-85.961-192-192 0-52.47 21.047-100.023 55.159-134.679l-0.025 0.025 397.24-402.76c23.166-23.166 55.17-37.495 90.52-37.495 70.701 0 128.015 57.314 128.015 128.015 0 35.35-14.329 67.354-37.495 90.52v0z", "M838.64 489.36c5.798 5.792 9.385 13.797 9.385 22.64s-3.587 16.848-9.385 22.64l-328.2 328c-40.54 40.535-96.542 65.606-158.4 65.606-123.726 0-224.026-100.3-224.026-224.026 0-61.868 25.079-117.878 65.625-158.42l0-0 397.040-402.88c28.966-28.996 68.998-46.932 113.22-46.932 88.383 0 160.032 71.649 160.032 160.032 0 44.162-17.888 84.146-46.814 113.101l0.001-0.001-397.12 402.88c-17.403 17.403-41.444 28.167-68 28.167-53.111 0-96.167-43.055-96.167-96.167 0-26.556 10.764-50.597 28.167-68l0-0 333.2-338.48c5.853-6.233 14.146-10.115 23.346-10.115 17.673 0 32 14.327 32 32 0 9.021-3.733 17.17-9.738 22.987l-0.008 0.008-333.24 338.84c-5.845 5.8-9.464 13.838-9.464 22.72 0 17.675 14.329 32.004 32.004 32.004 8.793 0 16.758-3.546 22.542-9.286l-0.002 0.002 397.080-402.68c17.427-17.392 28.208-41.437 28.208-68 0-53.057-43.011-96.068-96.068-96.068-26.494 0-50.482 10.725-67.862 28.069l0.002-0.002-396.96 402.72c-29.011 28.967-46.958 69.007-46.958 113.24 0 88.376 71.643 160.018 160.018 160.018 44.143 0 84.111-17.874 113.062-46.78l-0.002 0.002 328.24-328c5.782-5.739 13.747-9.285 22.54-9.285 8.873 0 16.902 3.611 22.698 9.444l0.002 0.002z"]
    'smiley': ["M896 512c0 212.077-171.923 384-384 384s-384-171.923-384-384c0-212.077 171.923-384 384-384v0c212.077 0 384 171.923 384 384v0z", "M512 96c-229.75 0-416 186.25-416 416s186.25 416 416 416c229.75 0 416-186.25 416-416v0c-0.25-229.65-186.35-415.75-415.976-416l-0.024-0zM512 864c-194.404 0-352-157.596-352-352s157.596-352 352-352c194.404 0 352 157.596 352 352v0c-0.228 194.313-157.687 351.772-351.978 352l-0.022 0zM320 432c0-26.51 21.49-48 48-48s48 21.49 48 48c0 26.51-21.49 48-48 48v0c-26.51 0-48-21.49-48-48v0zM704 432c0 26.51-21.49 48-48 48s-48-21.49-48-48c0-26.51 21.49-48 48-48v0c26.51 0 48 21.49 48 48v0zM699.68 624c-41.16 71.16-109.56 112-187.68 112s-146.52-40.8-187.68-112c-3.133-4.86-4.995-10.796-4.995-17.167 0-17.673 14.327-32 32-32 12.25 0 22.893 6.884 28.271 16.994l0.084 0.173c29.88 51.64 76.84 80 132.32 80s102.44-28.4 132.32-80c5.462-10.283 16.104-17.167 28.355-17.167 17.673 0 32 14.327 32 32 0 6.371-1.862 12.307-5.071 17.294l0.076-0.127z"]
    'warning': ["M861.84 864h-699.68c-50.48 0-82.16-52.84-57.64-95.64l349.84-607.48c25.2-44 90.080-44 115.28 0l349.84 607.48c24.52 42.8-7.16 95.64-57.64 95.64z", "M947.2 752.36l-349.8-607.48c-17.525-29.455-49.194-48.883-85.4-48.883s-67.875 19.428-85.149 48.428l-0.251 0.455-349.8 607.48c-8.072 13.588-12.843 29.957-12.843 47.44s4.771 33.852 13.082 47.875l-0.239-0.435c17.146 29.356 48.5 48.765 84.389 48.765 0.356 0 0.711-0.002 1.066-0.006l-0.054 0h699.6c0.277 0.003 0.604 0.004 0.932 0.004 35.888 0 67.242-19.409 84.139-48.304l0.249-0.461c8.097-13.604 12.883-29.998 12.883-47.508 0-17.455-4.756-33.8-13.042-47.808l0.239 0.437zM891.72 815.2c-6.013 10.125-16.892 16.805-29.331 16.805-0.207 0-0.413-0.002-0.619-0.006l0.031 0h-699.6c-0.175 0.003-0.382 0.005-0.589 0.005-12.439 0-23.318-6.68-29.245-16.649l-0.086-0.157c-2.651-4.416-4.219-9.745-4.219-15.44s1.568-11.024 4.296-15.578l-0.077 0.138 349.8-607.48c6.23-10.239 17.329-16.972 30-16.972s23.77 6.734 29.913 16.818l0.087 0.154 349.8 607.48c2.602 4.384 4.14 9.665 4.14 15.305 0 5.75-1.599 11.127-4.376 15.711l0.076-0.135zM480 576v-160c0-17.673 14.327-32 32-32s32 14.327 32 32v0 160c0 17.673-14.327 32-32 32s-32-14.327-32-32v0zM560 720c0 26.51-21.49 48-48 48s-48-21.49-48-48c0-26.51 21.49-48 48-48v0c26.51 0 48 21.49 48 48v0z"]
    'x': ["M864 192v640c0 17.673-14.327 32-32 32v0h-640c-17.673 0-32-14.327-32-32v0-640c0-17.673 14.327-32 32-32v0h640c17.673 0 32 14.327 32 32v0z", "M822.64 777.36c5.794 5.794 9.378 13.799 9.378 22.64 0 17.683-14.335 32.018-32.018 32.018-8.841 0-16.846-3.584-22.64-9.378l-265.36-265.4-265.36 265.4c-5.794 5.794-13.799 9.378-22.64 9.378-17.683 0-32.018-14.335-32.018-32.018 0-8.841 3.584-16.846 9.378-22.64l-0 0 265.4-265.36-265.4-265.36c-5.794-5.794-9.378-13.799-9.378-22.64 0-17.683 14.335-32.018 32.018-32.018 8.841 0 16.846 3.584 22.64 9.378l265.36 265.4 265.36-265.4c5.794-5.794 13.799-9.378 22.64-9.378 17.683 0 32.018 14.335 32.018 32.018 0 8.841-3.584 16.846-9.378 22.64l-0 0-265.4 265.36z"]
    'x-circle': ["M896 512c0 212.077-171.923 384-384 384s-384-171.923-384-384c0-212.077 171.923-384 384-384v0c212.077 0 384 171.923 384 384v0z", "M662.64 406.64l-105.4 105.36 105.4 105.36c5.794 5.794 9.378 13.799 9.378 22.64 0 17.683-14.335 32.018-32.018 32.018-8.841 0-16.846-3.584-22.64-9.378l-105.36-105.4-105.36 105.4c-5.794 5.794-13.799 9.378-22.64 9.378-17.683 0-32.018-14.335-32.018-32.018 0-8.841 3.584-16.846 9.378-22.64l105.4-105.36-105.4-105.36c-5.794-5.794-9.378-13.799-9.378-22.64 0-17.683 14.335-32.018 32.018-32.018 8.841 0 16.846 3.584 22.64 9.378l105.36 105.4 105.36-105.4c5.794-5.794 13.799-9.378 22.64-9.378 17.683 0 32.018 14.335 32.018 32.018 0 8.841-3.584 16.846-9.378 22.64l0-0zM928 512c0 229.75-186.25 416-416 416s-416-186.25-416-416c0-229.75 186.25-416 416-416v0c229.65 0.25 415.75 186.35 416 415.976l0 0.024zM864 512c0-194.404-157.596-352-352-352s-352 157.596-352 352c0 194.404 157.596 352 352 352v0c194.313-0.228 351.772-157.687 352-351.978l0-0.022z"]

  siskaIcon = (name, size = 16, opts = {}) ->
    paths = SISKA_ICONS[name]
    return '' if !paths
    tone = opts.tone || 'single'
    cls = if opts.class then " class=\"#{opts.class}\"" else ''
    fill = ''
    if tone is 'full'
      fill = "<path opacity=\"0.2\" d=\"#{paths[0]}\"/>"
    else if tone is 'active'
      fill = "<path class=\"zammad-chat-icon-fill\" d=\"#{paths[0]}\"/>"
    "<svg#{cls} width=\"#{size}\" height=\"#{size}\" viewBox=\"0 0 1024 1024\" fill=\"currentColor\" aria-hidden=\"true\">#{fill}<path d=\"#{paths[1]}\"/></svg>"

  class ZammadChat extends Base
    defaults:
      chatId: undefined
      show: true
      target: document.querySelector('body')
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
    # Enhancement 1 -- Tahap 3 -- mirror persis dari chat.coffee (lihat
    # komentar detail di sana).
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
    # Enhancement 4 -- lihat catatan di `updatePhrases`.
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
        options.icon = siskaIcon
        options.background = @options.background
        options.flat = @options.flat
        options.fontSize = @options.fontSize
        # Enhancement 4 -- lihat catatan di `updatePhrases`.
        options.phrases = @phrases
        return window.zammadChatTemplates[name](options)

    constructor: (options) ->
      super(options)

      # jQuery migration
      if typeof jQuery != 'undefined' && @options.target instanceof jQuery
        @log.notice 'Chat: target option is a jQuery object. jQuery is not a requirement for the chat any more.'
        @options.target = @options.target.get(0)

      # fullscreen
      @isFullscreen = (window.matchMedia and window.matchMedia('(max-width: 768px)').matches)
      @scrollRoot = @getScrollRoot()

      # check prerequisites
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
        @options.lang = document.documentElement.getAttribute('lang')
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
        # mirror persis dari chat.coffee.
        onReconnecting: @onIoReconnecting
        onReconnected: @onIoReconnected
        # Atas permintaan user (mockup fullpage "Connection lost") --
        # callback KHUSUS utk kegagalan reconnect (bukan `onError`
        # generik, yg msh dipakai skenario lain spt chat disabled/
        # antrian penuh dan TIDAK relevan dgn overlay koneksi ini).
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
      start = parseInt(html.pageYOffset, 10)
      html.pageYOffset = start + 1
      end = parseInt(html.pageYOffset, 10)
      html.pageYOffset = start
      return if end > start then html else document.body

    render: =>
      if !@el || !document.querySelector('.zammad-chat')
        @renderBase()

      # disable open button
      btn = document.querySelector(".#{ @options.buttonClass }")
      if btn
        btn.classList.add @options.inactiveClass

      @setAgentOnlineState 'online'

      @log.debug 'widget rendered'

      @startTimeoutObservers()
      @idleTimeout.start()

      # get current chat status
      @sessionId = sessionStorage.getItem('sessionId')
      # dipulihkan bersamaan dgn sessionId -- dibutuhkan
      # `onReopenSession` utk avatar inisial pesan customer sendiri.
      @customerName = sessionStorage.getItem('customerName')
      @send 'chat_status_customer',
        session_id: @sessionId
        url: window.location.href

    # Atas permintaan user (loading full page) -- mirror persis dari
    # chat.coffee (lihat komentar detail di sana).
    showPreload: ->
      return if @preloadEl
      @options.target.insertAdjacentHTML('beforeend', @view('preload')())
      @preloadEl = @options.target.querySelector('.zammad-chat-preload')

    hidePreload: =>
      return if !@preloadEl
      @preloadEl.remove()
      @preloadEl = undefined

    renderBase: ->
      @showPreload()
      @el.remove() if @el
      @launcherEl.remove() if @launcherEl
      @options.target.insertAdjacentHTML('beforeend', @view('chat')(
        title: @options.title,
        scrollHint: @options.scrollHint
      ))
      @el = @options.target.querySelector('.zammad-chat')
      # Bug ditemukan user -- mirror persis dari chat.coffee (lihat
      # catatan panjang di sana): sembunyikan SEKETIKA lewat `style`
      # inline sampai `chat.css` selesai dimuat, supaya HTML mentah
      # tanpa style tidak sempat tampil (race condition WS vs CSS).
      @el.style.display = 'none' if !@cssLoaded

      # Struktur baru (atas permintaan user): tombol bulat mengambang
      # TERPISAH dari panel -- SATU-SATUNYA elemen yang tampil saat
      # widget tertutup. Mirror persis dari chat.coffee -- `@el`
      # (panel) TIDAK diubah maknanya, tetap `.zammad-chat` seperti
      # dulu.
      @options.target.insertAdjacentHTML('beforeend', @view('launcher')())
      @launcherEl = @options.target.querySelector('.zammad-chat-launcher')
      @launcherEl.style.display = 'none' if !@cssLoaded
      @launcherEl.addEventListener('click', @toggle)

      @input = @el.querySelector('.zammad-chat-input')
      @body = @el.querySelector('.zammad-chat-body')

      # start bindings
      # Atas permintaan user -- mirror persis dari chat.coffee: X di
      # header sekarang mengakhiri chat (`exitChat`), bukan lagi
      # menyembunyikan panel.
      @el.querySelector('.js-chat-close').addEventListener('click', @exitChat)
      # Atas permintaan user -- mirror persis dari chat.coffee: tombol
      # minimize BARU di header (khusus mobile), gantikan launcher yg
      # disembunyikan saat panel terbuka di mobile.
      @el.querySelector('.js-chat-minimize').addEventListener('click', @close)
      # `.js-chat-status` sekarang jadi bagian dari `views/agent.eco`
      # (dot online di avatar) -- dirender ULANG setiap
      # `onConnectionEstablished`, TIDAK ADA di DOM statis sejak awal
      # (beda dari sebelumnya). Binding LANGSUNG di sini akan CRASH
      # (`querySelector` balik `null`) krn elemen belum ada saat
      # `renderBase()` jalan -- didelegasikan dari `.zammad-chat-agent`
      # (elemen statis, SELALU ada meski masih kosong), pola manual yg
      # sama dgn delegasi `[data-tab]`/`.js-waiting-cancel`.
      @el.querySelector('.zammad-chat-agent').addEventListener 'click', (event) =>
        target = event.target.closest('.js-chat-status')
        return if !target
        @stopPropagation(event)
      @el.querySelector('.zammad-chat-controls').addEventListener('submit', @onSubmit)
      @body.addEventListener('scroll', @detectScrolledtoBottom)
      @el.querySelector('.zammad-scroll-hint').addEventListener('click', @onScrollHintClick)
      @input.addEventListener('keydown', @onKeydown)
      @input.addEventListener('input', @onInput)
      @input.addEventListener('paste', @onPaste)
      @input.addEventListener('drop', @onDrop)

      # Fitur tambahan "Reply ke Pesan Spesifik" -- Section 5.3. Tidak
      # ada delegasi bawaan seperti jQuery `.on(event, selector, ...)`
      # di sini -- dicek manual di dalam `startReply` sendiri lewat
      # `event.target.closest(...)`, karena bubble pesan ditambahkan
      # dinamis setelah render awal ini.
      @body.addEventListener('click', @startReply)

      # Atas permintaan user (mockup `Waiting.dc.html`, koreksi "keluar
      # dari antrian kembali ke home") -- tombol Batalkan dirender ulang
      # tiap kali `.zammad-chat-modal` diisi ulang (loader/waiting/dst.)
      # -- delegasi manual dari `.zammad-chat-modal` sendiri (elemen
      # statis), pola yang sama dgn delegasi `[data-tab]` di bawah,
      # supaya tidak perlu bind ulang tiap render spt `renderReplyIndicator`.
      @el.querySelector('.zammad-chat-modal').addEventListener 'click', (event) =>
        target = event.target.closest('.js-waiting-cancel')
        return if !target
        @cancelQueue(event)

      # Enhancement 1 -- Tahap 3 (Offline Message + OTP) -- delegasi
      # SAMA persis alasannya dgn `.js-waiting-cancel` di atas, mirror
      # persis dari chat.coffee.
      @el.querySelector('.zammad-chat-modal').addEventListener 'click', (event) =>
        target = event.target.closest('.js-otp-submit')
        return if !target
        @submitOfflineOtp(event)
      @el.querySelector('.zammad-chat-modal').addEventListener 'click', (event) =>
        target = event.target.closest('.js-otp-resend')
        return if !target
        @resendOfflineOtp(event)
      @el.querySelector('.zammad-chat-modal').addEventListener 'click', (event) =>
        target = event.target.closest('.js-otp-change-email')
        return if !target
        @showPrechatForm()
      @el.querySelector('.zammad-chat-modal').addEventListener 'input', (event) =>
        target = event.target.closest('.js-otp-digit')
        return if !target
        @onOtpDigitInput(event)
      @el.querySelector('.zammad-chat-modal').addEventListener 'keydown', (event) =>
        target = event.target.closest('.js-otp-digit')
        return if !target
        @onOtpDigitKeydown(event)
      @el.querySelector('.zammad-chat-modal').addEventListener 'paste', (event) =>
        target = event.target.closest('.js-otp-digit')
        return if !target
        @onOtpDigitPaste(event)
      @el.querySelector('.zammad-chat-modal').addEventListener 'click', (event) =>
        target = event.target.closest('.js-offline-compose-submit')
        return if !target
        @submitOfflineMessage(event)
      @el.querySelector('.zammad-chat-modal').addEventListener 'click', (event) =>
        target = event.target.closest('.js-offline-sent-done')
        return if !target
        @finishOfflineFlow(event)

      # Item lampiran OfflineCompose (follow-up terpisah dari
      # Enhancement 4 awal) -- delegasi sama persis alasannya.
      @el.querySelector('.zammad-chat-modal').addEventListener 'click', (event) =>
        target = event.target.closest('.js-offline-compose-attach')
        return if !target
        @triggerOfflineAttachmentInput(event)
      @el.querySelector('.zammad-chat-modal').addEventListener 'change', (event) =>
        target = event.target.closest('.js-offline-compose-attachment-input')
        return if !target
        @uploadOfflineAttachment(event)

      # Enhancement 2 -- Rating Kepuasan (Feedback). Delegasi ke `@el`
      # (BUKAN `.zammad-chat-modal` lagi) -- semenjak feedback bisa
      # dirender INLINE di `.zammad-chat-body` (`showFeedback(true)`,
      # atas permintaan user "sematkan di jendela chat"), delegasi ke
      # `.zammad-chat-modal` tidak lagi menangkap klik di kartu inline.
      # `@el` aman utk kedua mode (modal maupun inline), pola sama
      # dgn `[data-tab]`/`.js-connection-reload` di atas.
      @el.addEventListener 'click', (event) =>
        target = event.target.closest('.js-feedback-star')
        return if !target
        @selectFeedbackScore(event, target.dataset.score)
      @el.addEventListener 'click', (event) =>
        target = event.target.closest('.js-feedback-submit')
        return if !target
        @submitFeedback(event)
      @el.addEventListener 'click', (event) =>
        target = event.target.closest('.js-feedback-skip')
        return if !target
        @skipFeedback(event)

      # Fase 5 -- Item No. 6 (Attachment). Section 5.2.3.
      @el.querySelector('.js-chat-attach').addEventListener('click', @triggerAttachmentInput)
      @el.querySelector('.js-chat-attachment-input').addEventListener('change', @uploadAttachment)

      # Fase 7 -- Widget bergaya tab (Home/Messages/Help). Section 4.2/4.3.
      # Home & Help TIDAK PUNYA konten dinamis per-sesi -- cukup diisi
      # SEKALI di sini. Mirror persis dari chat.coffee (versi jQuery).
      @el.querySelector('.zammad-chat-tab-body--home').innerHTML = @view('home')()
      @el.querySelector('.zammad-chat-tab-body--help').innerHTML = @view('help')()
      @el.querySelector('.zammad-chat-tabbar').innerHTML = @view('tabbar')()
      @el.querySelector('.js-emoji-picker').innerHTML = @view('emoji_picker')()
      @activeTab = 'home'
      @updateHeader('home')

      # Delegasi manual (bukan `.on(event, selector, ...)` seperti
      # jQuery) -- tombol tab bar & tombol pintasan tab Home SAMA-SAMA
      # dikenali lewat atribut `data-tab` (Section 4.1: "reuse switch
      # tab, bukan event baru").
      #
      # Atas permintaan user -- mirror persis dari chat.coffee: KHUSUS
      # tombol Home dapat loading state, dimatikan manual segera setelah
      # `switchTab` (sinkron, TIDAK PERNAH merender ulang markup Home).
      @el.addEventListener 'click', (event) =>
        target = event.target.closest('[data-tab]')
        return if !target
        isHomeAction = !!target.closest('.zammad-chat-home-actions')
        @setButtonLoading(target, true) if isHomeAction
        @switchTab target.dataset.tab
        @setButtonLoading(target, false) if isHomeAction

      # Atas permintaan user (mockup fullpage "Connection lost") --
      # delegasi (pola sama dgn `[data-tab]` di atas) krn tombol ini
      # cuma ada di DOM SETELAH `showConnectionOverlay('lost')`
      # menyuntik markup-nya, bukan elemen statis sejak render awal.
      @el.addEventListener 'click', (event) =>
        target = event.target.closest('.js-connection-reload')
        return if !target
        window.location.reload()

      # Revisi desain (gaya Able Pro) -- ikon smile membuka/menutup
      # panel emoji; klik satu emoji menyisipkannya ke posisi kursor
      # terakhir di kotak ketik. Mirror persis dari chat.coffee.
      @el.querySelector('.js-emoji-toggle').addEventListener('click', @toggleEmojiPicker)
      @el.querySelector('.js-emoji-picker').addEventListener 'click', (event) =>
        item = event.target.closest('.js-emoji-item')
        return if !item
        @insertEmoji item.dataset.emoji

      # Bug ditemukan user (pencarian Help tidak pernah mengirim apa
      # pun) -- `updatePhrases()` mengganti TOTAL innerHTML
      # `.zammad-chat-tab-body--help` SETIAP `chat_status_customer`
      # (TERMASUK yang PERTAMA kali widget terhubung), menghancurkan
      # elemen `.js-kb-search` ASLI yang listener ini terpasang.
      # Diperbaiki jadi DELEGASI ke `@el` (pola yang SAMA dipakai
      # `[data-tab]`/`.js-emoji-item` di atas) -- lihat juga
      # `onKbSearchInput` yang diubah pakai `event.target` bukan
      # `event.currentTarget` supaya tetap benar saat didelegasikan.
      @el.addEventListener 'input', (event) =>
        target = event.target.closest('.js-kb-search')
        return if !target
        @onKbSearchInput(event)

      # `scroll` TIDAK bubbling -- didengarkan lewat FASE CAPTURE
      # (argumen ke-3 `true`) di `@el`, bukan didelegasikan biasa,
      # supaya tetap jalan walau `.zammad-chat-kb-results` dibongkar-
      # pasang ulang lewat `updatePhrases()`.
      @el.addEventListener('scroll', @onKbResultsScroll, true)

      window.addEventListener('beforeunload', @onLeaveTemporary)
      window.addEventListener('hashchange', =>
        if @isOpen
          if @sessionId
            @send 'chat_session_notice',
              session_id: @sessionId
              message: window.location.href
          return
        @idleTimeout.start()
      )

    # Fase 7 -- Widget bergaya tab (Home/Messages/Help). Section 4.3.
    # Mirror persis dari chat.coffee (versi jQuery), disesuaikan ke DOM
    # API polos yang dipakai file ini.
    switchTab: (tabName) =>
      return if @activeTab is tabName
      @activeTab = tabName

      for body in @el.querySelectorAll('.zammad-chat-tab-body')
        body.classList.remove('is-active')
      activeBody = @el.querySelector(".zammad-chat-tab-body--#{tabName}")
      activeBody?.classList.add('is-active')

      # Audit kit Tailwind -- `aria-current` ikut `is-active` supaya tab
      # aktif diumumkan pembaca layar.
      for item in @el.querySelectorAll('.zammad-chat-tabbar-item')
        item.classList.remove('is-active')
        item.removeAttribute('aria-current')
      activeItem = @el.querySelector(".zammad-chat-tabbar-item[data-tab='#{tabName}']")
      activeItem?.classList.add('is-active')
      activeItem?.setAttribute('aria-current', 'page')

      @updateHeader(tabName)

      # Atas permintaan user: tab Help langsung menampilkan artikel
      # (5 terbaru) begitu dibuka, TANPA perlu mengetik dulu -- cukup
      # sekali per sesi widget (`@kbLoaded` guard).
      if tabName is 'help' and !@kbLoaded
        @kbLoaded = true
        @loadKnowledgeBase(true)

    # Revisi desain (identik referensi Intercom/Claude) -- isi header
    # BERBEDA per tab. Mirror persis dari chat.coffee.
    updateHeader: (tabName) =>
      tabName ?= @activeTab

      showAgent   = tabName is 'messages' and @agent?
      showWelcome = tabName is 'home' and !showAgent
      showTitle   = !showWelcome and !showAgent

      @el.querySelector('.zammad-chat-header').classList.toggle('zammad-chat-header--tinted', showWelcome)
      @el.querySelector('.zammad-chat-welcome').classList.toggle('zammad-chat-is-hidden', !showWelcome)
      # `.zammad-chat-agent-status` (dot online) sekarang dirender
      # SEBAGAI BAGIAN dari `.zammad-chat-agent` (views/agent.eco, di
      # dalam avatar) -- toggle induknya saja sudah cukup. PENTING:
      # elemen ini TIDAK ADA di DOM statis lagi (cuma muncul setelah
      # `onConnectionEstablished` merender `agent.eco`) -- querySelector
      # terpisah di sini akan balik `null` & CRASH kalau tetap dipanggil
      # (beda dari jQuery yang no-op diam-diam pada seleksi kosong).
      @el.querySelector('.zammad-chat-agent').classList.toggle('zammad-chat-is-hidden', !showAgent)
      @el.querySelector('.zammad-chat-header-title').classList.toggle('zammad-chat-is-hidden', !showTitle)

      if showTitle
        title = if tabName is 'help' then @T('Help') else @T('Messages')
        @el.querySelector('.js-header-title-text').textContent = title

    # Revisi desain (gaya Able Pro). Mirror persis dari chat.coffee.
    toggleEmojiPicker: (event) =>
      event?.preventDefault()
      @el.querySelector('.js-emoji-picker').classList.toggle('zammad-chat-is-hidden')
      isOpen = @el.querySelector('.js-emoji-toggle').classList.toggle('is-active')
      # Audit ulang kit: toggle kini `<button>` -- status buka/tutup
      # picker diumumkan ke pembaca layar.
      @el.querySelector('.js-emoji-toggle').setAttribute('aria-expanded', String(isOpen))

    insertEmoji: (emoji) =>
      @input.focus()
      document.execCommand('insertText', false, emoji)
      @el.querySelector('.js-emoji-picker').classList.add('zammad-chat-is-hidden')
      @el.querySelector('.js-emoji-toggle').classList.remove('is-active')
      @el.querySelector('.js-emoji-toggle').setAttribute('aria-expanded', 'false')
      @onInput()

    # Fase 7 -- Tab Help, pencarian KB. Section 4.5. Debounce dengan
    # pola timer yang sama dipakai `onAgentTypingStart` (@stopTypingId).
    #
    # Follow-up atas permintaan user: tab Help SEKARANG menampilkan
    # artikel (5 terbaru) BAHKAN TANPA mengetik apa pun (`@kbQuery`
    # kosong = mode "jelajahi"), mengetik di kolom cuma MEMFILTER
    # daftar yang sama (`@kbQuery` terisi = mode "cari"), dan halaman
    # berikutnya dimuat lewat SCROLL ke dasar daftar (bukan tombol/
    # nomor halaman) -- lihat `loadKnowledgeBase`/`onKbResultsScroll`.
    # Mirror persis dari chat.coffee (versi jQuery).
    onKbSearchInput: (event) =>
      # `event.target` (BUKAN `event.currentTarget`) -- listener ini
      # didelegasikan ke `@el`, `currentTarget` akan selalu `@el`
      # sendiri, bukan input yang sungguhan diketik.
      @kbQuery = event.target.value?.trim() || ''

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
      @el.querySelector('.zammad-chat-kb-loading')?.classList.remove('zammad-chat-is-hidden')

      @send 'chat_knowledge_base_search',
        query: @kbQuery || ''
        offset: @kbOffset || 0

    onKnowledgeBaseSearchResult: (data) =>
      @kbLoading = false
      @el.querySelector('.zammad-chat-kb-loading')?.classList.add('zammad-chat-is-hidden')

      # Buang respons BASI -- bisa terjadi kalau user mengetik cepat
      # lalu balasan query SEBELUMNYA baru sampai belakangan, setelah
      # `@kbQuery` sendiri sudah berubah lagi.
      return if (data.query || '') isnt (@kbQuery || '')

      results     = @el.querySelector('.zammad-chat-kb-results')
      emptyMessage = @el.querySelector('.zammad-chat-kb-empty')
      isFirstPage = (data.offset || 0) is 0

      results.innerHTML = '' if isFirstPage

      @kbHasMore = !!data.has_more
      @kbOffset  = (data.offset || 0) + (data.result?.length || 0)

      if isFirstPage and (!data.result || data.result.length is 0)
        emptyMessage?.classList.remove('zammad-chat-is-hidden')
        return

      emptyMessage?.classList.add('zammad-chat-is-hidden')
      for item in (data.result || [])
        results.insertAdjacentHTML('beforeend', @view('kb_result')(item))

    # Dipicu scroll di dalam `.zammad-chat-kb-results` -- listener
    # dipasang di FASE CAPTURE pada `@el` (bukan didelegasikan biasa,
    # krn event `scroll` TIDAK bubbling) supaya TETAP jalan walau
    # elemen `.zammad-chat-kb-results` sendiri dibongkar-pasang ulang
    # lewat `updatePhrases()`.
    onKbResultsScroll: (event) =>
      return if !event.target.classList?.contains('zammad-chat-kb-results')
      el = event.target
      return if el.scrollTop + el.clientHeight < el.scrollHeight - 200
      @loadKnowledgeBase(false)

    stopPropagation: (event) ->
      event.stopPropagation()

    onDrop: (e) =>
      e.stopPropagation()
      e.preventDefault()

      if window.dataTransfer # ie
        dataTransfer = window.dataTransfer
      else if e.dataTransfer # other browsers
        dataTransfer = e.dataTransfer
      else
        throw 'No clipboardData support'

      x = e.clientX
      y = e.clientY
      file = dataTransfer.files[0]

      # look for images
      if file.type.match('image.*')
        reader = new FileReader()
        reader.onload = (e) =>
          # Insert the image at the carat
          insert = (dataUrl, width) =>

            # adapt image if we are on retina devices
            if @isRetina()
              width = width / 2

            result = dataUrl
            img = new Image()
            img.style.width = '100%'
            img.style.maxWidth = width + 'px'
            img.src = result

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
          @resizeImage(e.target.result, 460, 'auto', 2, 'image/jpeg', 'auto', insert)
        reader.readAsDataURL(file)

    onPaste: (e) =>
      e.stopPropagation()
      e.preventDefault()

      if e.clipboardData
        clipboardData = e.clipboardData
      else if window.clipboardData
        clipboardData = window.clipboardData
      else if e.clipboardData
        clipboardData = e.clipboardData
      else
        throw 'No clipboardData support'

      imageInserted = false
      if clipboardData && clipboardData.items && clipboardData.items[0]
        item = clipboardData.items[0]
        if item.kind == 'file' && (item.type == 'image/png' || item.type == 'image/jpeg')
          imageFile = item.getAsFile()
          reader = new FileReader()

          reader.onload = (e) =>
            insert = (dataUrl, width) =>

              # adapt image if we are on retina devices
              if @isRetina()
                width = width / 2

              img = new Image()
              img.style.width = '100%'
              img.style.maxWidth = width + 'px'
              img.src = dataUrl
              document.execCommand('insertHTML', false, img)

            # resize if to big
            @resizeImage(e.target.result, 460, 'auto', 2, 'image/jpeg', 'auto', insert)

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
        html = document.createElement('div')
        # can't log because might contain malicious content
        # @log.debug 'HTML clipboard', text
        sanitized = DOMPurify.sanitize(text)
        @log.debug 'sanitized HTML clipboard', sanitized
        html.innerHTML = sanitized
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

        for node in html.childNodes
          if node.nodeType == 8
            node.remove()

        # remove tags, keep content
        for node in html.querySelectorAll('a, font, small, time, form, label')
          node.outerHTML = node.innerHTML

        # replace tags with generic div
        # New type of the tag
        replacementTag = 'div';

        # Replace all x tags with the type of replacementTag
        for node in html.querySelectorAll('textarea')
          outer = node.outerHTML

          # Replace opening tag
          regex = new RegExp('<' + node.tagName, 'i')
          newTag = outer.replace(regex, '<' + replacementTag)

          # Replace closing tag
          regex = new RegExp('</' + node.tagName, 'i')
          newTag = newTag.replace(regex, '</' + replacementTag)

          node.outerHTML = newTag

        # remove tags & content
        for node in html.querySelectorAll('font, img, svg, input, select, button, style, applet, embed, noframes, canvas, script, frame, iframe, meta, link, title, head, fieldset')
          node.remove()

        @removeAttributes(html)

        text = html.innerHTML

      # as fallback, insert html via pasteHtmlAtCaret (for IE 11 and lower)
      if docType is 'text3'
        @pasteHtmlAtCaret(text)
      else
        document.execCommand('insertHTML', false, text)
      true

    onKeydown: (e) =>
      # check for enter
      if not @inputDisabled and not e.shiftKey and e.keyCode is 13
        e.preventDefault()
        @sendMessage()

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
            # sini, beda dari chat_session_message) -- render dilakukan
            # HANYA lewat jalur ini, tidak ada render optimis terpisah
            # saat upload.
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
          # Atas permintaan user (mockup `Messages.dc.html`): penanda
          # "sudah dibaca" ala WhatsApp -- mirror persis dari
          # chat.coffee (lihat komentar detail di sana).
          when 'chat_session_message_read'
            @markMessagesRead()
          when 'chat_knowledge_base_search'
            @onKnowledgeBaseSearchResult pipe.data
          # Enhancement 1 -- Tahap 3 -- mirror persis dari chat.coffee.
          when 'chat_offline_session_init'
            @onOfflineSessionInitResult pipe.data
          when 'chat_offline_otp_verify'
            @onOfflineOtpVerifyResult pipe.data
          when 'chat_offline_otp_resend'
            @onOfflineOtpResendResult pipe.data
          when 'chat_offline_message_send'
            @onOfflineMessageSendResult pipe.data
          # Enhancement 2 -- Rating Kepuasan (Feedback) -- mirror
          # persis dari chat.coffee.
          when 'chat_session_feedback_submit'
            @onFeedbackSubmitResult pipe.data
          when 'chat_status_customer'
            # Atas permintaan user ("logo pada home mengambil dari
            # setting logo zammad") -- mirror persis dari chat.coffee.
            #
            # Bug ditemukan user ("logo home dan offlineHome satu
            # sumber dgn logo aplikasi") -- mirror persis dari
            # chat.coffee (lihat catatan panjang di sana): `@logoUrl`
            # disimpan persisten, dipasang ULANG di akhir
            # `updatePhrases()`.
            @logoUrl = pipe.data.logo_url if pipe.data.logo_url
            @updateHomeLogo(@logoUrl) if @logoUrl
            # Bug ditemukan user -- mirror persis dari chat.coffee
            # (lihat catatan panjang di sana).
            @offlineMode = pipe.data.state is 'offline'
            # Atas permintaan user: tombol launcher jadi abu-abu saat
            # offline -- mirror persis dari chat.coffee (lihat catatan
            # panjang di sana).
            @launcherEl?.classList.toggle('zammad-chat-launcher--offline', @offlineMode)
            @updatePhrases(pipe.data.phrases) if pipe.data.phrases
            # Atas permintaan user (field Category Prechat) -- pola
            # SAMA dgn `@phrases`: disimpan di instance, dibaca nanti
            # oleh `showPrechatForm` saat form dirender. TIDAK perlu
            # method `updateX()` terpisah spt `updatePhrases` (yg ada
            # krn phrases menyentuh BANYAK elemen sekaligus) -- field
            # ini cuma dipakai SATU tempat (Prechat), cukup assignment
            # polos, dibaca ulang tiap `showPrechatForm` dipanggil.
            @categoryOptions = pipe.data.category_options if pipe.data.category_options
            # Bug ditemukan user -- mirror persis dari chat.coffee
            # (lihat catatan panjang di sana): `hidePreload()` HARUS
            # jalan utk STATUS APA PUN, bukan cuma 'online'.
            @statusReceived = true
            @hidePreload() if @cssLoaded
            switch pipe.data.state
              when 'online'
                @setSessionId undefined

                if !@options.cssAutoload || @cssLoaded
                  @onReady()
                else
                  @socketReady = true
              when 'offline'
                # Enhancement 1 -- Tahap 3 -- mirror persis dari
                # chat.coffee. Bug ditemukan user (hard refresh saat
                # OTP) -- lihat catatan panjang di chat.coffee soal
                # `@sessionId` sesi offline_pending yg tidak pernah
                # dibersihkan di sini, bikin `open()` salah kira ada
                # chat sungguhan yg sedang berjalan.
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
      # Mirror persis dari chat.coffee.
      @hidePreload()
      btn = document.querySelector(".#{ @options.buttonClass }")
      if btn
        btn.addEventListener('click', @open)
        btn.classList.remove(@options.inactiveClass)

      @options.onReady?()

      if @options.show
        @show()

    onError: (message) =>
      @log.debug message
      # Mirror persis dari chat.coffee.
      @hidePreload()
      @addStatus(message)
      btn = document.querySelector(".#{ @options.buttonClass }")
      if btn
        btn.classList.add('zammad-chat-is-hidden')

      if @isOpen
        @disableInput()
        @destroy(remove: false)
      else
        @destroy(remove: true)

      @options.onError?(message)

    onReopenSession: (data) =>
      # Bug ditemukan user (loading full page tidak pernah hilang) --
      # mirror persis dari chat.coffee (lihat catatan panjang di
      # sana).
      @hidePreload()
      @log.debug 'old messages', data.session
      @inactiveTimeout.start()

      unfinishedMessage = sessionStorage.getItem 'unfinished_message'

      # rerender chat history
      if data.agent
        # `showGreeting: false` -- ini sesi LAMA digambar ulang (reload
        # halaman), bukan sesi baru, jadi sapaan otomatis TIDAK diulang
        # (lihat catatan panjang di `onConnectionEstablished`).
        @onConnectionEstablished(data, false)

        # Bug ditemukan lewat laporan user (hard refresh -> jam pesan
        # hilang dari riwayat) -- mirror persis dari chat.coffee.
        # (`avatarInitials` DIHAPUS -- avatar per-pesan tidak lagi ada
        # di markup.)
        for message in data.session
          isAgentMessage = !!message.created_by_id
          time = @formatTime(message.created_at)

          # Bug KEDUA ditemukan lewat pengujian langsung -- mirror
          # persis dari chat.coffee: pesan attachment di riwayat
          # SEBELUMNYA di-render sbg bubble teks "[attachment]" TANPA
          # link unduh. `filename` dipakai sbg penanda attachment.
          #
          # Atas permintaan user (mockup `Messages.dc.html`): penanda
          # "terkirim"/"sudah dibaca" -- mirror persis dari chat.coffee
          # (`read_at` otomatis ikut ke `message.attributes`, kolom asli
          # tabel).
          isRead = !!message.read_at

          if message.filename
            @body.insertAdjacentHTML 'beforeend', @view('attachment_message')(
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
              # Bug ke-3 ditemukan lewat laporan user (kutipan
              # "Membalas: ..." hilang setelah reload) -- mirror persis
              # dari chat.coffee, backend sekarang menyertakan
              # `reply_to.content` (`app/models/chat/session.rb`).
              replyTo: message.reply_to?.content

          # Bug ke-2 ditemukan lewat simulasi LANGSUNG diminta user
          # (hard refresh lalu klik ikon reply) -- mirror persis dari
          # chat.coffee: `startReply` cuma baca
          # `@agentMessagesById[messageId]` (diisi HANYA oleh
          # `receiveMessage`), balik `undefined` utk pesan hasil replay
          # ini, gagal diam-diam tanpa error.
          @agentMessagesById[message.id] = message if isAgentMessage and message.id

        if unfinishedMessage
          @input.innerHTML = unfinishedMessage

      # show wait list
      if data.position
        @onQueue data

      # Bug ditemukan lewat pengujian sendiri -- mirror persis dari
      # chat.coffee: `@show()` HARUS tanpa syarat (mengembalikan
      # visibilitas @launcherEl yg dihapus onWebSocketClose di tengah
      # siklus reconnect minimize) -- hanya @open()/@scrollToBottom()
      # (paksa-buka PANEL) yang di-skip kalau reconnect ini dipicu
      # minimize, bukan reload halaman sungguhan.
      @show()
      if !@minimizedWithSession
        @open()
        @scrollToBottom()

      if unfinishedMessage
        @input.focus()

    onInput: =>
      # remove unread-state from messages
      for message in @el.querySelectorAll('.zammad-chat-message--unread')
        message.classList.remove 'zammad-chat-message--unread'

      sessionStorage.setItem 'unfinished_message', @input.innerHTML

      @onTyping()

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
      message = @input.innerHTML
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
      if @el.querySelector('.zammad-chat-message--typing')
        @lastAddedType = 'typing-placeholder'
        @el.querySelector('.zammad-chat-message--typing').insertAdjacentHTML('beforebegin', messageElement)
      else
        @lastAddedType = 'message--customer'
        @body.insertAdjacentHTML('beforeend', messageElement)

      @input.innerHTML = ''
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
      @body.insertAdjacentHTML('beforeend', @view('message')(data))

    # Fitur tambahan "Reply ke Pesan Spesifik (Seperti WhatsApp)" --
    # docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.3.
    startReply: (event) =>
      # delegasi manual -- lihat komentar pemasangan listener di renderBase.
      return if !event.target.closest('.js-message-reply')
      event.preventDefault()

      target = event.target.closest('.zammad-chat-message')
      return if !target
      messageId = target.dataset.messageId
      return if !messageId
      message = @agentMessagesById[messageId]
      return if !message

      # Atas permintaan user (screenshot: kutipan reply ke pesan
      # attachment menampilkan literal "[attachment]") -- mirror persis
      # dari chat.coffee (lihat komentar detail di sana).
      @replyTo = { id: messageId, content: message.filename || message.content }
      @renderReplyIndicator()
      @input.focus()

    cancelReply: (event) =>
      event?.preventDefault()
      @replyTo = null
      @renderReplyIndicator()

    renderReplyIndicator: =>
      indicator = @el.querySelector('.js-reply-indicator')
      if !@replyTo
        indicator.classList.add('zammad-chat-is-hidden')
        indicator.innerHTML = ''
        return

      snippet = @replyTo.content.replace(/<[^>]*>/g, '').substr(0, 80)
      indicator.classList.remove('zammad-chat-is-hidden')
      indicator.innerHTML = @view('reply_indicator')(
        snippet: snippet
      )
      indicator.querySelector('.js-reply-cancel').addEventListener('click', @cancelReply)

    # Fase 5 -- Item No. 6 (Attachment). Section 5.2.3.
    triggerAttachmentInput: (event) =>
      event.preventDefault()
      @el.querySelector('.js-chat-attachment-input').click()

    uploadAttachment: (event) =>
      file = event.target.files?[0]
      return if !file

      formData = new FormData()
      formData.append('File', file)

      xhr = new XMLHttpRequest()
      xhr.open('POST', "#{@apiBaseUrl()}/api/v1/chat_sessions/#{@sessionId}/attachments")
      xhr.onload = =>
        return if xhr.status >= 200 and xhr.status < 300
        message = @T(@phrases['chat_phrase_attachment_upload_error'] || 'The attachment could not be uploaded.')
        try
          parsed = JSON.parse(xhr.responseText)
          message = parsed.error if parsed.error
        @addStatus(message)
      xhr.send(formData)

      event.target.value = ''

    # Bug ditemukan lewat laporan user ("kenapa pada attachment tidak
    # terdapat reply?") -- mirror persis dari chat.coffee.
    addAttachmentMessage: (data, from) =>
      @maybeAddTimestamp()
      @lastAddedType = "message--#{ from }"
      @body.insertAdjacentHTML 'beforeend', @view('attachment_message')(
        from: from
        id: data.id
        filename: data.filename
        metaLabel: @attachmentMeta(data.filename, data.size)
        url: "#{@apiBaseUrl()}/api/v1/chat_sessions/#{@sessionId}/attachments/#{data.id}"
        unreadClass: if document.hidden then ' zammad-chat-message--unread' else ''
        time: @formatTime(data.created_at)
      )
      @agentMessagesById[data.id] = data if from is 'agent' and data.id
      @scrollToBottom showHint: true

    open: =>
      if @isOpen
        @log.debug 'widget already open, block'
        return

      # Dibalik lagi begitu user SENDIRI yang membuka panel -- mirror
      # persis dari chat.coffee.
      @minimizedWithSession = false

      @isOpen = true
      @log.debug 'open widget'
      @show()

      if @sessionId
        # Fase 7 -- ada sesi chat yang sedang berjalan (reconnect) --
        # langsung ke tab Messages. Section 4.3. Mirror persis dari
        # chat.coffee.
        @switchTab('messages')
      else
        # Revisi desain (gaya Able Pro) -- form pra-chat langsung
        # mengisi `.zammad-chat-modal` di sini. Mirror persis dari
        # chat.coffee.
        @showPrechatForm()

      # Fase 7 -- struktur baru "tombol bulat mengambang + panel
      # terpisah" (atas permintaan user, meniru gaya Intercom/Claude).
      # Mirror persis dari chat.coffee: transisi tampil/sembunyi murni
      # CSS (opacity+transform) lewat class `zammad-chat-is-open`,
      # TIDAK ADA lagi animasi geser posisi manual (`translateY` dari
      # tinggi panel) seperti sebelumnya -- tidak dibutuhkan lagi
      # karena panel sekarang SELALU tersembunyi total saat tertutup,
      # bukan cuma digeser sebagian ke luar layar.
      @launcherEl.classList.add 'zammad-chat-is-open'
      # Audit kit Tailwind -- launcher sekarang <button>, status buka/
      # tutup diumumkan ke pembaca layar.
      @launcherEl.setAttribute 'aria-expanded', 'true'
      @el.addEventListener 'transitionend', @onOpenAnimationEnd
      @el.classList.add 'zammad-chat-is-open'

    # Fase 5 -- Item No. 5 (Auto-Create Ticket). See
    # docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.1.1. Nama & email
    # SEKARANG WAJIB diisi SEBELUM `chat_session_init` dikirim -- server
    # (lib/sessions/event/chat_session_init.rb) menolak sesi yang tidak
    # membawa keduanya. Mirror persis dari chat.coffee (versi jQuery),
    # disesuaikan ke DOM API polos yang dipakai file ini.
    showPrechatForm: (params = {}) =>
      @el.querySelector('.zammad-chat-modal').innerHTML = @view('prechat')(
        error: params.error
        notice: params.notice
        name: params.name
        email: params.email
        category: params.category
      )
      @el.querySelector('.zammad-chat-prechat-form').addEventListener 'submit', @submitPrechatForm
      # Logo custom -- mirror persis dari chat.coffee (lihat catatan
      # panjang di sana).
      @updateHomeLogo(@logoUrl) if @logoUrl

      # Atas permintaan user (field Category Prechat, wajib diisi
      # sama spt name/email) -- kontrol dropdown CUSTOM (bukan
      # <select> native, widget ini konsisten pakai kontrol sendiri
      # spy gaya Able Pro genuinely terpasang, lihat catatan di
      # views/prechat.eco). Isi menu dipopulasi di sini via loop +
      # `insertAdjacentHTML` (pola SAMA dgn `onKnowledgeBaseSearchResult`
      # utk `.zammad-chat-kb-results`) -- BUKAN loop di eco -- dari
      # `@categoryOptions` (diisi `chat_status_customer`, 1 sumber
      # kebenaran yg SAMA dipakai server memvalidasi, lihat
      # `Chat::Session.category_options`).
      menu           = @el.querySelector('.js-prechat-category-menu')
      selectedValue  = params.category
      for opt in (@categoryOptions or [])
        menu.insertAdjacentHTML 'beforeend', @view('prechat_category_option')(
          value:    opt.value
          label:    opt.label
          selected: opt.value is selectedValue
        )

      toggleBtn = @el.querySelector('.js-prechat-category-toggle')
      # Listener DIAJARKAN LANGSUNG di sini (bukan delegasi ke `@el`)
      # -- SENGAJA, pola SAMA dgn listener `submit` di atas: fungsi
      # INI SATU-SATUNYA yg pernah mengganti `.zammad-chat-modal`
      # (beda dari `.js-kb-search`/entri 170 yg KETIMPA `updatePhrases()`
      # -- Prechat sama sekali tidak disentuh fungsi itu), jadi aman
      # tanpa delegasi.
      toggleBtn.addEventListener 'click', (event) =>
        event.preventDefault()
        isOpen = !menu.classList.contains('zammad-chat-is-hidden')
        menu.classList.toggle('zammad-chat-is-hidden', isOpen)
        toggleBtn.classList.toggle('is-open', !isOpen)
        toggleBtn.setAttribute('aria-expanded', (!isOpen).toString())

      menu.addEventListener 'click', (event) =>
        option = event.target.closest('.js-prechat-category-option')
        return if !option

        value = option.dataset.value
        label = option.querySelector('span').textContent

        @el.querySelector('.js-prechat-category-input').value = value
        valueEl = @el.querySelector('.js-prechat-category-value')
        valueEl.textContent = label
        valueEl.classList.remove('is-placeholder')

        for other in menu.querySelectorAll('.js-prechat-category-option')
          other.classList.toggle('is-selected', other is option)

        menu.classList.add('zammad-chat-is-hidden')
        toggleBtn.classList.remove('is-open')
        toggleBtn.setAttribute('aria-expanded', 'false')

    # Atas permintaan user -- mirror persis dari chat.coffee (lihat
    # komentar detail di sana), disesuaikan ke DOM API polos.
    setButtonLoading: (button, loading) =>
      return if !button
      if loading
        if !button.querySelector('.zammad-chat-btn-label')
          label = document.createElement('span')
          label.className = 'zammad-chat-btn-label'
          while button.firstChild
            label.appendChild(button.firstChild)
          button.appendChild(label)
          loader = document.createElement('span')
          loader.className = 'zammad-chat-btn-loader'
          loader.setAttribute('aria-hidden', 'true')
          loader.innerHTML = '<svg viewBox="0 0 50 50"><circle cx="25" cy="25" r="20"></circle></svg>'
          button.appendChild(loader)
        button.classList.add('is-loading')
        button.disabled = true
      else
        button.classList.remove('is-loading')
        button.disabled = false

    submitPrechatForm: (event) =>
      event.preventDefault()

      name     = @el.querySelector('.zammad-chat-prechat-name')?.value?.trim()
      email    = @el.querySelector('.zammad-chat-prechat-email')?.value?.trim()
      # Atas permintaan user (field Category, wajib sama spt
      # name/email) -- nilai SUNGGUHAN disimpan di input tersembunyi
      # `.js-prechat-category-input` (diisi lewat klik opsi menu,
      # lihat `showPrechatForm`), BUKAN dibaca dari tombol toggle-nya
      # (yang cuma menampilkan LABEL, bisa beda kapitalisasi/dst dari
      # `value` sungguhan yang dikirim ke server).
      category = @el.querySelector('.js-prechat-category-input')?.value?.trim()

      emailFormat = /^[^@\s]+@[^@\s]+\.[^@\s]+$/
      if !name || !email || !emailFormat.test(email) || !category
        @showPrechatForm
          error:    @T(@phrases['chat_phrase_prechat_validation_error'] || 'Please provide a valid name, email, and category.')
          name:     name
          email:    email
          category: category
        return

      # Dipakai lagi nanti utk avatar inisial di bubble pesan sendiri
      # (views/message.eco) -- disimpan JUGA ke `sessionStorage` (pola
      # sama dgn `sessionId`, mirror persis dari chat.coffee) -- bug
      # ditemukan lewat laporan user (hard refresh menghilangkan avatar
      # & jam pesan): `@customerName` cuma variabel JS di memori,
      # server TIDAK PERNAH mengirim balik nama customer di payload
      # reconnect (`Chat#customer_state`).
      @customerName = name
      sessionStorage.setItem 'customerName', name
      # Enhancement 1 -- Tahap 3 -- mirror persis dari chat.coffee
      # (lihat komentar detail di sana).
      @customerEmail = email

      @setButtonLoading(@el.querySelector('.zammad-chat-prechat-submit'), true)

      if @offlineMode
        @send('chat_offline_session_init'
          url:      window.location.href
          name:     name
          email:    email
          category: category
        )
      else
        @showLoader()
        @send('chat_session_init'
          url:      window.location.href
          name:     name
          email:    email
          category: category
        )

    # ============================================================
    # Enhancement 1 -- Tahap 3: Offline Message + Verifikasi OTP.
    # Mirror persis dari chat.coffee (lihat komentar detail di sana),
    # disesuaikan ke DOM API polos yang dipakai file ini.
    # ============================================================

    # Bug ditemukan user (mirror persis dari chat.coffee, lihat catatan
    # panjang di sana): WS bisa reconnect kapan saja (`onOpen: @render`),
    # `chat_status_customer` terkirim ulang, `updatePhrases` SELALU
    # reset ke tampilan online -- versi LAMA method ini cuma sanggup
    # jalan sekali (`return if @offlineMode`), jadi mixed-state kalau
    # agent MASIH offline saat reconnect terjadi.
    enterOfflineMode: =>
      # `@offlineMode` sudah di-set di handler `chat_status_customer`
      # di atas -- lihat catatan sama di chat.coffee.
      #
      # Bug ditemukan user (loading full page tidak pernah hilang) --
      # mirror persis dari chat.coffee (lihat catatan panjang di
      # sana).
      @hidePreload()
      @applyOfflineHomeState()
      @show()

    # Diekstrak dari `enterOfflineMode` -- AMAN dipanggil berulang kali
    # (dari sini MAUPUN dari `updatePhrases` tiap WS reconnect). Beda
    # kunci dari versi lama: `.zammad-chat-welcome-subtext` TIDAK LAGI
    # diganti total (`replaceWith`, elemen aslinya hilang selamanya
    # setelah panggilan pertama) -- cuma ISINYA (`innerHTML`) yg
    # diganti, elemen pembungkusnya (& selectornya) tetap ada,
    # bisa ditimpa lagi arah manapun kapan saja.
    applyOfflineHomeState: =>
      return if !@offlineMode
      return if !@el

      subtext = @el.querySelector('.zammad-chat-welcome-subtext')
      if subtext
        status = document.createElement('span')
        status.className = 'zammad-chat-welcome-offline-status'
        dot = document.createElement('span')
        dot.className = 'zammad-chat-welcome-offline-dot'
        status.appendChild(dot)
        status.appendChild(document.createTextNode(@T(@phrases['chat_phrase_offline_status'] || "We're offline right now")))
        subtext.innerHTML = ''
        subtext.appendChild(status)

      notice = @el.querySelector('.zammad-chat-home-offline-notice')
      notice?.classList.remove('zammad-chat-is-hidden')

      # Atas permintaan user ("hilangkan icon pada button") -- mirror
      # persis dari chat.coffee: ikon dihapus dari markup, toggle
      # visibilitasnya di sini ikut dihapus.
      startAction = @el.querySelector('.js-home-start-action')
      if startAction
        startAction.querySelector('.js-home-start-label').textContent = @T(@phrases['chat_phrase_offline_start_button'] || 'Leave us a message')

    # Atas permintaan user ("pada halaman home saat agent online,
    # ditambahkan juga alert seperti tadi") -- kebalikan
    # `applyOfflineHomeState()` di atas, pola SAMA PERSIS (aman
    # dipanggil berulang kali, cukup toggle class, tidak menggambar
    # ulang apa pun). Notice ini SENGAJA tidak diberi konten dinamis
    # lain (spt status dot di welcome-subtext) -- cuma satu alert
    # statis, beda dari offline yg jg mengubah subtext & label tombol.
    applyOnlineHomeState: =>
      return if @offlineMode
      return if !@el

      notice = @el.querySelector('.zammad-chat-home-online-notice')
      notice?.classList.remove('zammad-chat-is-hidden')

    onOfflineSessionInitResult: (data) =>
      if data.state isnt 'ok'
        # Atas permintaan user -- mirror persis dari chat.coffee
        # (lihat catatan panjang di sana).
        if data.reason is 'agent_available'
          @showPrechatForm(notice: data.message)
        else
          @showPrechatForm(error: data.message)
        return

      @setSessionId data.session_id
      @showOfflineOtp()

    showOfflineOtp: =>
      @el.querySelector('.zammad-chat-modal').innerHTML = @view('offline_otp')(email: @customerEmail)
      @el.querySelector('.js-otp-digit')?.focus()

    onOtpDigitInput: (event) =>
      input = event.target
      value = input.value.replace(/[^0-9]/g, '')
      input.value = value.slice(-1)
      if value
        nextIndex = parseInt(input.dataset.index, 10) + 1
        next = input.closest('.zammad-chat-offline-otp-boxes').querySelector(".js-otp-digit[data-index='#{nextIndex}']")
        next?.focus()

    onOtpDigitKeydown: (event) =>
      return if event.keyCode isnt 8
      input = event.target
      return if input.value

      prevIndex = parseInt(input.dataset.index, 10) - 1
      return if prevIndex < 0

      prev = input.closest('.zammad-chat-offline-otp-boxes').querySelector(".js-otp-digit[data-index='#{prevIndex}']")
      if prev
        prev.value = ''
        prev.focus()

    onOtpDigitPaste: (event) =>
      event.preventDefault()
      pasted = event.clipboardData?.getData('text')?.replace(/[^0-9]/g, '') || ''
      return if !pasted

      boxes = event.target.closest('.zammad-chat-offline-otp-boxes').querySelectorAll('.js-otp-digit')
      boxes.forEach (el, i) ->
        el.value = pasted.charAt(i) || ''
      lastFilled = Math.min(pasted.length, boxes.length) - 1
      boxes[Math.max(lastFilled, 0)]?.focus()

    submitOfflineOtp: (event) =>
      event?.preventDefault()
      code = ''
      @el.querySelectorAll('.js-otp-digit').forEach (el) ->
        code += el.value || ''

      if code.length isnt 6
        @showOtpError @T(@phrases['chat_phrase_otp_incomplete_error'] || 'Please enter the full 6-digit code.')
        return

      @setButtonLoading(@el.querySelector('.js-otp-submit'), true)
      @send('chat_offline_otp_verify', session_id: @sessionId, code: code)

    # Bug ditemukan -- lihat catatan sama di chat.coffee (ikon
    # peringatan tidak pernah ada + `.textContent =` menghapusnya).
    showOtpError: (message) =>
      error = @el.querySelector('.js-otp-error')
      return if !error

      error.classList.remove('zammad-chat-is-hidden')
      textEl = error.querySelector('.js-otp-error-text')
      textEl.textContent = message if textEl

    onOfflineOtpVerifyResult: (data) =>
      if data.state is 'ok'
        @showOfflineCompose()
        return

      @setButtonLoading(@el.querySelector('.js-otp-submit'), false)
      @showOtpError data.message
      @el.querySelectorAll('.js-otp-digit').forEach (el) -> el.value = ''
      @el.querySelector('.js-otp-digit')?.focus()

    resendOfflineOtp: (event) =>
      event?.preventDefault()
      @send('chat_offline_otp_resend', session_id: @sessionId)

    onOfflineOtpResendResult: (data) =>
      if data.state is 'ok'
        @el.querySelectorAll('.js-otp-digit').forEach (el) -> el.value = ''
        @el.querySelector('.js-otp-digit')?.focus()
        @showOtpError @T(@phrases['chat_phrase_otp_resend_success'] || 'A new code has been sent.')
        return

      @showOtpError data.message || @T(@phrases['chat_phrase_otp_resend_error_fallback'] || 'Could not resend code. Please try again.')

    showOfflineCompose: =>
      @el.querySelector('.zammad-chat-modal').innerHTML = @view('offline_compose')(email: @customerEmail)

    # Atas permintaan user ("subject ini mandatory harus diisi") --
    # mirror persis dari chat.coffee: divalidasi DULUAN (sebelum isi
    # pesan, urutan field atas-ke-bawah), backend mengulang validasi
    # yg sama.
    submitOfflineMessage: (event) =>
      event?.preventDefault()
      subject = @el.querySelector('.js-offline-subject')?.value?.trim()
      content = @el.querySelector('.js-offline-message')?.value?.trim()
      errorEl = @el.querySelector('.js-offline-compose-error')

      if !subject
        if errorEl
          errorEl.textContent = @T(@phrases['chat_phrase_offline_compose_subject_empty_error'] || 'Please enter a subject.')
          errorEl.classList.remove('zammad-chat-is-hidden')
        return

      if !content
        if errorEl
          errorEl.textContent = @T(@phrases['chat_phrase_offline_compose_empty_error'] || 'Please write a message.')
          errorEl.classList.remove('zammad-chat-is-hidden')
        return

      errorEl?.classList.add('zammad-chat-is-hidden')
      @setButtonLoading(@el.querySelector('.js-offline-compose-submit'), true)
      @send('chat_offline_message_send', session_id: @sessionId, subject: subject, content: content)

    # Item lampiran OfflineCompose (follow-up terpisah dari
    # Enhancement 4 awal) -- mirror persis dari chat.coffee (lihat
    # catatan panjang di sana).
    triggerOfflineAttachmentInput: (event) =>
      event?.preventDefault()
      @el.querySelector('.js-offline-compose-attachment-input').click()

    uploadOfflineAttachment: (event) =>
      file = event.target.files?[0]
      return if !file

      formData = new FormData()
      formData.append('File', file)

      attachBtn = @el.querySelector('.js-offline-compose-attach')
      attachBtn?.setAttribute('disabled', 'disabled')

      xhr = new XMLHttpRequest()
      xhr.open('POST', "#{@apiBaseUrl()}/api/v1/chat_sessions/#{@sessionId}/attachments")
      xhr.onload = =>
        attachBtn?.removeAttribute('disabled')
        if xhr.status >= 200 and xhr.status < 300
          data = JSON.parse(xhr.responseText)
          chip = document.createElement('div')
          chip.className = 'zammad-chat-offline-compose-attachment-chip'
          # Audit migrasi ikon Tabler (2026-09-23) -- ikon INI
          # ketinggalan waktu migrasi massal krn dibuat di JS
          # (`chip.innerHTML`), bukan file `.eco` spt ikon lain
          # (`views/*.eco`, discan terpisah). Glyph SAMA persis dgn
          # tombol attach lain (`paperclip`, lihat views/chat.eco),
          # diekstrak dari font sama.
          chip.innerHTML = siskaIcon('paperclip', 16)
          filenameEl = document.createElement('span')
          filenameEl.textContent = data.filename
          chip.appendChild(filenameEl)
          @el.querySelector('.js-offline-compose-attachments')?.appendChild(chip)
          return

        message = @T(@phrases['chat_phrase_attachment_upload_error'] || 'The attachment could not be uploaded.')
        try
          parsed = JSON.parse(xhr.responseText)
          message = parsed.error if parsed.error
        errorEl = @el.querySelector('.js-offline-compose-error')
        if errorEl
          errorEl.textContent = message
          errorEl.classList.remove('zammad-chat-is-hidden')
      xhr.send(formData)

      event.target.value = ''

    onOfflineMessageSendResult: (data) =>
      @setButtonLoading(@el.querySelector('.js-offline-compose-submit'), false)

      if data.state isnt 'ok'
        errorEl = @el.querySelector('.js-offline-compose-error')
        if errorEl
          errorEl.textContent = data.message
          errorEl.classList.remove('zammad-chat-is-hidden')
        return

      # Enhancement 2 -- lihat catatan sama di chat.coffee.
      @lastSessionId = @sessionId
      @setSessionId undefined
      @showOfflineSent()

    showOfflineSent: =>
      @el.querySelector('.zammad-chat-modal').innerHTML = @view('offline_sent')(email: @customerEmail)

    # Enhancement 2 -- lihat catatan sama di chat.coffee: tombol ini
    # sekarang lanjut ke layar Feedback dulu, bukan langsung Home.
    finishOfflineFlow: (event) =>
      event?.preventDefault()
      @setButtonLoading(@el.querySelector('.js-offline-sent-done'), true)
      @showFeedback()

    # Enhancement 2 -- Rating Kepuasan (Feedback) -- mirror persis dari
    # chat.coffee (lihat catatan panjang di sana).
    #
    # Atas permintaan user (mockup "SISKA Widget Mockup" board
    # FeedbackInline): saat AGENT yg menutup sesi (`onSessionClosed`),
    # feedback SEKARANG jadi kartu DI DALAM `.zammad-chat-body`
    # (`inline = true`) -- riwayat percakapan TETAP terlihat penuh di
    # atasnya, bukan lagi menutupi seluruh jendela lewat
    # `.zammad-chat-modal`. Jalur LAIN yg jg memanggil method ini
    # (`exitChat` -- customer sendiri klik X, `finishOfflineFlow` --
    # alur pesan offline) SENGAJA TIDAK diubah (`inline` default
    # `false`, tetap modal spt sebelumnya) -- di luar scope permintaan
    # ini, dan utk alur offline `.zammad-chat-body` genuinely kosong
    # (tidak ada histori realtime utk ditampilkan di belakangnya).
    showFeedback: (inline = false) =>
      @feedbackScore = undefined
      @feedbackInline = inline
      markup = @view('feedback')()
      if inline
        @hideModal()
        @maybeAddTimestamp()
        @body.insertAdjacentHTML 'beforeend', "<div class=\"zammad-chat-feedback-inline js-feedback-inline\">#{markup}</div>"
        @scrollToBottom()
      else
        @el.querySelector('.zammad-chat-modal').innerHTML = markup
      # Lihat catatan sama di chat.coffee.
      @agent = undefined
      @updateHeader()

    selectFeedbackScore: (event, score) =>
      event?.preventDefault()
      @feedbackScore = parseInt(score, 10)
      @el.querySelectorAll('.js-feedback-star').forEach (el) =>
        starScore = parseInt(el.dataset.score, 10)
        el.classList.toggle('is-active', starScore <= @feedbackScore)

    submitFeedback: (event) =>
      event?.preventDefault()

      errorEl = @el.querySelector('.js-feedback-error')
      if !@feedbackScore
        if errorEl
          errorEl.textContent = @T(@phrases['chat_phrase_feedback_score_error'] || 'Please select a rating.')
          errorEl.classList.remove('zammad-chat-is-hidden')
        return

      errorEl?.classList.add('zammad-chat-is-hidden')
      @setButtonLoading(@el.querySelector('.js-feedback-submit'), true)

      comment = @el.querySelector('.js-feedback-comment')?.value?.trim()
      @send 'chat_session_feedback_submit',
        session_id: @lastSessionId
        score: @feedbackScore
        comment: comment

    onFeedbackSubmitResult: (data) =>
      @setButtonLoading(@el.querySelector('.js-feedback-submit'), false)

      if data.state isnt 'ok'
        errorEl = @el.querySelector('.js-feedback-error')
        if errorEl
          errorEl.textContent = data.message || @T(@phrases['chat_phrase_feedback_submit_error_fallback'] || 'Could not save your feedback. Please try again.')
          errorEl.classList.remove('zammad-chat-is-hidden')
        return

      @showFeedbackThanks()

    skipFeedback: (event) =>
      event?.preventDefault()
      @setButtonLoading(@el.querySelector('.js-feedback-skip'), true)
      @goToStartChat()

    # Atas permintaan user: rating-nya sendiri inline (`showFeedback`
    # di atas), TAPI layar "Terima kasih" SETELAH submit tetap fullpage
    # -- overlay TERPISAH (`.js-feedback-thanks-overlay`, lihat
    # `chat.eco`/`chat.scss`) dari overlay status koneksi, gaya scrim
    # sama (semi-transparan, jendela chat kelihatan samar di belakang).
    showFeedbackThanks: =>
      markup = @view('feedback_thanks')()
      if @feedbackInline
        overlay = @el.querySelector('.js-feedback-thanks-overlay')
        if overlay
          overlay.innerHTML = markup
          overlay.classList.remove('zammad-chat-is-hidden')
      else
        @el.querySelector('.zammad-chat-modal').innerHTML = markup
      setTimeout (=> @hideFeedbackThanksOverlay(); @goToStartChat()), 2000

    hideFeedbackThanksOverlay: =>
      overlay = @el.querySelector('.js-feedback-thanks-overlay')
      return if !overlay
      overlay.classList.add('zammad-chat-is-hidden')
      overlay.innerHTML = ''

    onOpenAnimationEnd: =>
      @el.removeEventListener 'transitionend', @onOpenAnimationEnd
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

      # Enhancement 2 -- lihat catatan sama di chat.coffee.
      @lastSessionId = @sessionId
      @setSessionId undefined

    # Atas permintaan user (mockup `Waiting.dc.html` + koreksi "keluar
    # dari antrian kembali ke home") -- mirror persis dari chat.coffee
    # (versi jQuery). `sessionClose()` valid dipanggil walau sesi belum
    # tersambung ke agent (dicek ke `lib/sessions/event/
    # chat_session_close.rb`), `.zammad-chat-modal` diisi ulang dengan
    # form pra-chat segar supaya visitor yang buka tab Messages lagi
    # LEWAT tab bar tidak melihat layar antre lama yang sudah berlaku.
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
    # tidak exit chat") -- mirror persis dari chat.coffee. `close()`
    # SEKARANG cuma menyembunyikan panel, TIDAK PERNAH mengakhiri sesi
    # chat lagi.
    close: (event) =>
      if !@isOpen
        @log.debug 'can\'t close widget, it\'s not open'
        return
      if @initDelayId
        clearTimeout(@initDelayId)

      # Bug KEDUA ditemukan lewat pengujian langsung -- mirror persis
      # dari chat.coffee: `onReopenSession` (dipicu `@io.reconnect()`
      # di `onCloseAnimationEnd`) SEBELUMNYA selalu memaksa panel
      # terbuka lagi, meniadakan minimize sekarang bahwa sesi tetap
      # hidup saat diminimize.
      @minimizedWithSession = !!@sessionId

      @log.debug 'close widget'

      event.stopPropagation() if event

      if @isFullscreen
        @enableScrollOnRoot()

      # Fase 7 -- lihat komentar sama di open().
      @launcherEl.classList.remove 'zammad-chat-is-open'
      @launcherEl.setAttribute 'aria-expanded', 'false'
      @el.addEventListener 'transitionend', @onCloseAnimationEnd
      @el.classList.remove 'zammad-chat-is-open'

    # Atas permintaan user ("chat berakhir HANYA jika klik tombol
    # exit") -- mirror persis dari chat.coffee.
    #
    # Revisi lanjutan ("hanya tombol X pada halaman Messages yang bisa
    # untuk end chat, tombol X pada halaman lain berfungsi normal") --
    # mirror persis dari chat.coffee: elemen `.js-chat-close` SATU-SATUNYA
    # dipakai di SEMUA tab, jadi dibedakan lewat `@activeTab`. Di tab
    # lain (bukan Messages), didelegasikan ke `close()` (perilaku
    # "normal" = cuma sembunyikan panel, spt tombol minimize).
    # Revisi lanjutan (mockup `EndingChat.dc.html`) -- mirror persis
    # dari chat.coffee: tampilkan `.zammad-chat-modal` berisi spinner
    # "Ending conversation…" selama 2 detik (customer TIDAK PERNAH
    # menerima balasan `chat_session_closed` utk penutupan yg dia
    # inisiasi sendiri -- lihat komentar detail di chat.coffee -- jadi
    # transisi ini murni lokal/optimis, tidak menunggu server).
    #
    # Revisi lanjutan lagi ("...reload kembali ke halaman MULAI CHAT")
    # -- mirror persis dari chat.coffee: tujuan akhir sekarang tab HOME
    # dgn form pra-chat SUDAH disiapkan di modal Messages (pola SAMA
    # dgn `cancelQueue()` yg sudah ada), bukan lagi cuma `hideModal()`
    # diam di tab Messages.
    # Atas permintaan user -- mirror persis dari chat.coffee:
    # `@offlineMode` ditambahkan sbg penanda tambahan (selain
    # `@activeTab`) supaya klik X saat alur offline (OfflineOtp/
    # Compose/Sent, SEMUA dirender di dalam `.zammad-chat-modal` yg
    # tetap anak tab Messages) TIDAK salah masuk ke cabang "akhiri
    # sesi chat" -- diperlakukan sama seperti tombol X di tab lain
    # (`close()`).
    exitChat: (event) =>
      if @activeTab isnt 'messages' or @offlineMode
        @close(event)
        return

      event?.preventDefault()
      event?.stopPropagation()

      if @sessionId
        @log.debug 'exit chat'
        @el.querySelector('.zammad-chat-modal').innerHTML = @view('ending_chat')()
        @sessionClose()
        # Enhancement 2 -- lihat catatan sama di chat.coffee.
        setTimeout @showFeedback, 2000
      else
        @goToStartChat()

    # Diekstrak dari closure lokal -- lihat catatan sama di chat.coffee.
    goToStartChat: =>
      @agent = undefined
      @showPrechatForm()
      @switchTab('home')

    onCloseAnimationEnd: =>
      @el.removeEventListener 'transitionend', @onCloseAnimationEnd

      # Revisi desain -- lihat komentar sama di chat.coffee.
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
        @launcherEl.classList.remove('zammad-chat-is-shown')
        @launcherEl.classList.remove('zammad-chat-is-loaded')

    show: ->
      return if @state is 'offline'

      # Fase 7 -- gerbang "widget ini tersedia sama sekali" sekarang
      # ada di tombol mengambang (@launcherEl). Mirror persis dari
      # chat.coffee.
      @launcherEl.classList.add('zammad-chat-is-loaded')
      @launcherEl.classList.add('zammad-chat-is-shown')

    disableInput: ->
      @inputDisabled = true
      @input.setAttribute('contenteditable', false)
      @el.querySelector('.zammad-chat-send').disabled = true
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
      @input?.setAttribute('contenteditable', false)
      sendBtn = @el.querySelector('.zammad-chat-send')
      sendBtn.disabled = true if sendBtn

    enableInput: ->
      @inputDisabled = false
      @input.setAttribute('contenteditable', true)
      @el.querySelector('.zammad-chat-send').disabled = false

    hideModal: ->
      @el.querySelector('.zammad-chat-modal').innerHTML = ''

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

      @el.querySelector('.zammad-chat-modal').innerHTML = @view('waiting')
        position: data.position

    onAgentTypingStart: =>
      if @stopTypingId
        clearTimeout(@stopTypingId)
      @stopTypingId = setTimeout(@onAgentTypingEnd, 3000)

      # never display two typing indicators
      return if @el.querySelector('.zammad-chat-message--typing')

      @maybeAddTimestamp()

      @body.insertAdjacentHTML('beforeend', @view('typingIndicator')())

      # only if typing indicator is shown
      return if !@isVisible(@el.querySelector('.zammad-chat-message--typing'), true)
      @scrollToBottom()

    onAgentTypingEnd: =>
      @el.querySelector('.zammad-chat-message--typing').remove() if @el.querySelector('.zammad-chat-message--typing')

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
          @body.insertAdjacentHTML 'beforeend', @view('timestamp')
            label: label
            time: time
          @lastTimestamp = timestamp
          @lastAddedType = 'timestamp'
          @scrollToBottom()

    updateLastTimestamp: (label, time) ->
      return if !@el
      timestamps = @el.querySelectorAll('.zammad-chat-body .zammad-chat-timestamp')
      return if !timestamps
      timestamps[timestamps.length - 1].outerHTML = @view('timestamp')
        label: label
        time: time

    addStatus: (status) ->
      return if !@el
      @maybeAddTimestamp()

      @body.insertAdjacentHTML 'beforeend', @view('status')
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
    # backend yg jg msh hardcode).
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
      overlay = @el.querySelector('.js-connection-overlay')
      return if !overlay

      if @connectionOverlayHideTimeoutId
        clearTimeout(@connectionOverlayHideTimeoutId)
        @connectionOverlayHideTimeoutId = undefined

      copy = @connectionOverlayCopy(state)
      overlay.innerHTML = @view('connection_overlay')
        state: state
        title: copy.title
        subtitle: copy.subtitle

      for otherState in ['reconnecting', 'restored', 'lost']
        overlay.classList.remove("zammad-chat-connection-overlay--#{otherState}")
      overlay.classList.add("zammad-chat-connection-overlay--#{state}")
      overlay.classList.remove('zammad-chat-is-hidden')

      # 'restored' cuma konfirmasi sesaat -- hilang otomatis, jendela
      # chat (yg sudah genuinely aktif kembali di belakangnya) lalu
      # kelihatan penuh tanpa scrim.
      if state is 'restored'
        @connectionOverlayHideTimeoutId = setTimeout(@hideConnectionOverlay, 1800)

    hideConnectionOverlay: =>
      return if !@el
      overlay = @el.querySelector('.js-connection-overlay')
      return if !overlay
      overlay.classList.add('zammad-chat-is-hidden')
      overlay.innerHTML = ''

    # Toggle warna tombol launcher (abu-abu netral) selama koneksi
    # WEBSOCKET WIDGET SENDIRI bermasalah -- class TERPISAH dari
    # `zammad-chat-launcher--offline` (dipakai utk status AGENT
    # offline, `@offlineMode`) supaya kedua mekanisme independen tidak
    # saling menimpa lewat `classList.toggle` yg sama.
    updateLauncherConnectionState: (hasIssue) =>
      @launcherEl?.classList.toggle('zammad-chat-launcher--connection-issue', hasIssue)

    detectScrolledtoBottom: =>
      scrollBottom = @body.scrollTop + @body.offsetHeight
      @scrolledToBottom = Math.abs(scrollBottom - @body.scrollHeight) <= @scrollSnapTolerance
      @el.querySelector('.zammad-scroll-hint').classList.add('is-hidden') if @scrolledToBottom

    showScrollHint: ->
      @el.querySelector('.zammad-scroll-hint').classList.remove('is-hidden')
      # compensate scroll
      @body.scrollTop = @body.scrollTop + @el.querySelector('.zammad-scroll-hint').offsetHeight

    onScrollHintClick: =>
      # animate scroll
      @body.scrollTo
        top: @body.scrollHeight
        behavior: 'smooth'

    scrollToBottom: ({ showHint } = { showHint: false }) ->
      if @scrolledToBottom
        @body.scrollTop = @body.scrollHeight
      else if showHint
        @showScrollHint()

    destroy: (params = {}) =>
      @log.debug 'destroy widget', params

      @setAgentOnlineState 'offline'

      if params.remove && @el
        @el.remove()
        @launcherEl?.remove()

        # Remove button, because it can no longer be used.
        btn = document.querySelector(".#{ @options.buttonClass }")
        if btn
          btn.classList.add @options.inactiveClass
          btn.style.display = 'none';

      # stop all timer
      if @waitingListTimeout
        @waitingListTimeout.stop()
      if @inactiveTimeout
        @inactiveTimeout.stop()
      if @idleTimeout
        @idleTimeout.stop()

      # stop ws connection
      @io.close()

    # Atas permintaan user ("mau" -- auto-reconnect websocket) -- mirror
    # persis dari chat.coffee (lihat komentar detail di sana): method
    # LAMA (`reconnect()`/`onConnectionReestablished()`) tidak pernah
    # dipanggil dari mana pun, diganti di sini, disambungkan ke
    # `Io#attemptReconnect()` (BARU) via `@io.set(...)` di constructor.
    # SENGAJA TIDAK pakai `disableInput()` (efek samping `@io.close()`
    # akan meracuni flag `manualClose` milik `Io` di tengah retry).
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
        @input?.setAttribute('contenteditable', false)
        sendBtn = @el.querySelector('.zammad-chat-send')
        sendBtn.disabled = true if sendBtn

    onIoReconnected: =>
      @log.debug 'reconnected'
      return if !@isOpen
      @setAgentOnlineState 'online'
      @showConnectionOverlay('restored')
      @updateLauncherConnectionState(false)
      @options.onConnectionReestablished?()
      if @reconnectDisabledInput
        @reconnectDisabledInput = false
        @input?.setAttribute('contenteditable', true)
        sendBtn = @el.querySelector('.zammad-chat-send')
        sendBtn.disabled = false if sendBtn

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

      # Revisi desain -- lihat komentar sama di chat.coffee.
      @agent = undefined
      @updateHeader()

      @options.onSessionClosed?(data)

      # Atas permintaan user -- mirror persis dari chat.coffee: layar
      # feedback rating muncul kalau AGENT SENDIRI yang menutup sesi
      # (`data.closed_by_agent`, backend `chat_session_close.rb`),
      # TIDAK PERNAH utk penutupan pasif (cleanup scheduler/socket
      # putus/reload).
      if data.closed_by_agent and @sessionId
        sessionStorage.removeItem 'unfinished_message'
        @lastSessionId = @sessionId
        @setSessionId undefined
        setTimeout (=> @showFeedback(true)), 2000

    # Atas permintaan user (mockup `Messages.dc.html`): penanda
    # "sudah dibaca" ala WhatsApp -- mirror persis dari chat.coffee
    # (lihat komentar detail di sana, termasuk bug `innerHTML` hardcode
    # yg SUDAH DIHAPUS TOTAL -- ikon SEKARANG selalu sama, cuma warna
    # yg beda lewat class).
    markMessagesRead: =>
      statusEls = @el.querySelectorAll('.zammad-chat-message--customer .zammad-chat-message-status--sent')
      return if !statusEls.length

      for statusEl in statusEls
        statusEl.classList.remove('zammad-chat-message-status--sent')
        statusEl.classList.add('zammad-chat-message-status--read')
        statusEl.setAttribute('aria-label', @T('Read'))

    setSessionId: (id) =>
      @sessionId = id
      if id is undefined
        sessionStorage.removeItem 'sessionId'
      else
        sessionStorage.setItem 'sessionId', id

    # Atas permintaan user ("mau ada welcome greeting dari agent saat
    # terkoneksi") -- param baru `showGreeting` (default true) supaya
    # sapaan HANYA muncul saat sesi BENAR-BENAR baru (`chat_session_start`,
    # lihat pemanggilan di `ws.onmessage`), BUKAN saat `onReopenSession`
    # menggambar ulang riwayat sesi yg SAMA sesudah reload halaman --
    # caller itu eksplisit kirim `false` di bawah.
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
      @body.innerHTML = ''

      @el.querySelector('.zammad-chat-agent').innerHTML = @view('agent')
        agent: @agent
        initials: @initialsOf(@agent?.name)

      @showWelcomeGreeting() if showGreeting

      # Fase 5 -- Item No. 6, fitur tambahan enable/disable attachment
      # global+per-agent. Section 5.2.6. Tombol attach disembunyikan
      # by default (views/chat.eco) -- server yang memutuskan boleh
      # tidaknya lewat flag ini, dikirim di payload chat_session_start
      # yang sama.
      if data.attachment_enabled
        @el.querySelector('.js-chat-attach').classList.remove('zammad-chat-is-hidden')
      else
        @el.querySelector('.js-chat-attach').classList.add('zammad-chat-is-hidden')

      @enableInput()

      @hideModal()
      @updateHeader()

      @input.focus() if not @isFullscreen

      @setAgentOnlineState 'online'

      @waitingListTimeout.stop()
      @idleTimeout.stop()
      @inactiveTimeout.start()
      @options.onConnectionEstablished?(data)

    # Sapaan otomatis dari agent, disuntik widget (BUKAN pesan sungguhan
    # dari server -- tidak ada `id`, jadi tombol reply otomatis tidak
    # muncul, lihat `views/message.eco`: `if @from is 'agent' and @id`).
    # `@renderMessage` dipakai (bukan tulis markup manual) supaya
    # bubble-nya IDENTIK dgn pesan agent asli (avatar, waktu, style).
    # Kosong/tidak dikonfigurasi -> tidak render apa pun (bukan bubble
    # kosong) -- lihat `chat_phrase_messages_welcome_greeting` di
    # `script/create_widget_phrase_settings.rb`.
    showWelcomeGreeting: =>
      greeting = @phrases['chat_phrase_messages_welcome_greeting']
      return if !greeting
      @maybeAddTimestamp()
      @renderMessage
        message: greeting
        from: 'agent'
        time: @formatTime()

    showCustomerTimeout: ->
      @el.querySelector('.zammad-chat-modal').innerHTML = @view('customer_timeout')
        agent: @agent.name
        delay: @options.inactiveTimeout
      @el.querySelector('.js-restart').addEventListener 'click', -> location.reload()
      @sessionClose()

    showWaitingListTimeout: ->
      @el.querySelector('.zammad-chat-modal').innerHTML = @view('waiting_list_timeout')
        delay: @options.watingListTimeout
      @el.querySelector('.js-restart').addEventListener 'click', -> location.reload()
      @sessionClose()

    showLoader: ->
      @el.querySelector('.zammad-chat-modal').innerHTML = @view('loader')()

    # Atas permintaan user (mockup `Messages.dc.html`) -- mirror persis
    # dari chat.coffee. Avatar inisial dipakai di header (agent.eco)
    # MAUPUN tiap bubble pesan (message.eco).
    initialsOf: (name) ->
      return '' if !name
      parts = name.trim().split(/\s+/)
      ((parts[0]?[0] || '') + (parts[1]?[0] || '')).toUpperCase()

    # Atas permintaan user ("logo pada home mengambil dari setting
    # logo zammad") -- mirror persis dari chat.coffee. Selector
    # diperluas ke `.zammad-chat-prechat-icon` (permintaan lanjutan
    # "tambahkan juga logo pada halaman ini seperti home dan offline
    # home") -- BEDA dari jQuery, DOM native TIDAK meng-clone otomatis
    # kalau 1 node yg sama di-`appendChild` ke >1 induk (node cuma
    # PINDAH ke induk terakhir) -- jadi WAJIB bikin `<img>` BARU per
    # elemen lewat `forEach`, bukan 1 elemen dipakai bersama.
    updateHomeLogo: (url) =>
      marks = @el.querySelectorAll('.zammad-chat-home-logo-mark, .zammad-chat-prechat-icon')
      marks.forEach (mark) ->
        mark.style.background = 'none'
        img = document.createElement('img')
        img.src = url
        img.alt = ''
        img.style.width = '100%'
        img.style.height = '100%'
        img.style.objectFit = 'contain'
        mark.innerHTML = ''
        mark.appendChild(img)

    # Enhancement 4 -- mirror persis dari chat.coffee (lihat catatan
    # panjang di sana).
    updatePhrases: (phrases) =>
      @phrases = phrases
      return if !@el
      @el.querySelector('.zammad-chat-tab-body--home').innerHTML = @view('home')()
      @el.querySelector('.zammad-chat-tab-body--help').innerHTML = @view('help')()
      # `.zammad-chat-tab-body--help` di atas baru diganti TOTAL --
      # lihat catatan panjang di chat.coffee (mirror persis).
      if @activeTab is 'help'
        @loadKnowledgeBase(true)
      else
        @kbLoaded = false
      welcomeTitle = @el.querySelector('.zammad-chat-welcome-title')
      welcomeTitle.innerHTML = @T(@phrases['chat_phrase_home_greeting'] || 'Hi there') + ' 👋' if welcomeTitle
      welcomeSubtext = @el.querySelector('.zammad-chat-welcome-subtext')
      welcomeSubtext.textContent = @T(@phrases['chat_phrase_home_subtitle'] || 'How can we help you today?') if welcomeSubtext
      input = @el.querySelector('.zammad-chat-input')
      input.setAttribute('placeholder', @T(@phrases['chat_phrase_messages_compose_placeholder'] || 'Compose your message…')) if input

      # Bug ditemukan user -- lihat catatan panjang di chat.coffee.
      @applyOfflineHomeState()
      # Atas permintaan user (notice Home saat agent online) -- pola
      # SAMA, dipanggil di titik yg SAMA (`updatePhrases` jalan tiap
      # `chat_status_customer`, status APA PUN) supaya notice yg
      # benar SELALU tampil begitu status berubah arah manapun --
      # `.zammad-chat-tab-body--home` di atas SUDAH digambar ulang
      # PENUH dari template (notice online balik ke hidden by default
      # tiap kali), jadi di sini cukup tampilkan kalau memang online.
      @applyOnlineHomeState()
      # Logo custom -- mirror persis dari chat.coffee (lihat catatan
      # panjang di sana).
      @updateHomeLogo(@logoUrl) if @logoUrl

    # Atas permintaan user (mockup `Messages.dc.html`, "tidak ada time
    # per chat") -- mirror persis dari chat.coffee.
    formatTime: (isoString) ->
      date = if isoString then new Date(isoString) else new Date()
      date.toTimeString().substr(0, 5)

    # Atas permintaan user (mockup kartu lampiran gaya WhatsApp) --
    # mirror persis dari chat.coffee.
    formatFileSize: (bytes) ->
      return '' if !bytes
      return "#{bytes} B" if bytes < 1024
      return "#{Math.round(bytes / 1024)} KB" if bytes < 1024 * 1024
      "#{(bytes / (1024 * 1024)).toFixed(1)} MB"

    fileExtensionLabel: (filename) ->
      return '' if !filename
      parts = filename.split('.')
      return '' if parts.length < 2
      parts[parts.length - 1].toUpperCase()

    # Mirror persis dari chat.coffee.
    attachmentMeta: (filename, size) ->
      [@fileExtensionLabel(filename), @formatFileSize(size)].filter((part) -> part).join(' · ')

    setAgentOnlineState: (state) =>
      @state = state
      return if !@el
      capitalizedState = state.charAt(0).toUpperCase() + state.slice(1)
      # `.zammad-chat-agent-status` sekarang cuma ada di DOM SETELAH
      # `onConnectionEstablished` merender `agent.eco` (dulu elemen
      # statis, selalu ada sejak render awal) -- dipanggil di sini juga
      # oleh `render()` SEBELUM itu terjadi, jadi WAJIB null-guard
      # (beda dari jQuery yang no-op diam-diam pada seleksi kosong).
      statusEl = @el.querySelector('.zammad-chat-agent-status')
      return if !statusEl
      statusEl.dataset.status = state
      statusEl.textContent = @T(capitalizedState)

    detectHost: ->
      protocol = 'ws://'
      if scriptProtocol is 'https'
        protocol = 'wss://'
      @options.host = "#{ protocol }#{ scriptHost }/ws"

    # Fase 5 -- Item No. 6 (Attachment). Section 5.2.1. Konversi
    # ws(s):// -> http(s):// yang SAMA dipakai `loadCss` di bawah --
    # `@options.host` adalah URL WebSocket, BUKAN origin HTTP.
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
      # Mirror persis dari chat.coffee.
      @el?.style.display = ''
      @launcherEl?.style.display = ''
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
      @rootScrollOffset = @scrollRoot.scrollTop
      @scrollRoot.style.overflow = 'hidden'
      @scrollRoot.style.position = 'fixed'

    enableScrollOnRoot: ->
      @scrollRoot.scrollTop = @rootScrollOffset
      @scrollRoot.style.overflow = ''
      @scrollRoot.style.position = ''

    # based on https://github.com/customd/jquery-visible/blob/master/jquery.visible.js
    # to have not dependency, port to coffeescript
    isVisible: (el, partial, hidden, direction) ->
      return if el.length < 1

      vpWidth    = window.innerWidth
      vpHeight   = window.innerHeight
      direction  = if direction then direction else 'both'
      clientSize = if hidden is true then t.offsetWidth * t.offsetHeight else true

      rec      = el.getBoundingClientRect()
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

      editor.innerHTML = content

      # Parse out list indent level for lists
      for p in editor.querySelectorAll('p')
        str = p.getAttribute('style')
        matches = /mso-list:\w+ \w+([0-9]+)/.exec(str)
        if matches
          p.dataset._listLevel = parseInt(matches[1], 10)

      # Parse Lists
      last_level = 0
      pnt = null
      for p in editor.querySelectorAll('p')
        cur_level = p.dataset._listLevel
        if cur_level != undefined
          txt = p.textContent
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
              p.insertAdjacentHTML 'beforebegin', list_tag
              pnt = p.previousElementSibling
            else
            pnt.insertAdjacentHTML 'beforeend', list_tag

          if cur_level < last_level
            for i in [i..last_level-cur_level]
              pnt = pnt.parentNode

          p.querySelector('span:first').remove() if p.querySelector('span:first')
          pnt.insertAdjacentHTML 'beforeend', '<li>' + p.innerHTML + '</li>'
          p.remove()
          last_level = cur_level
        else
          last_level = 0

      el.removeAttribute('style') for el in editor.querySelectorAll('[style]')
      el.removeAttribute('align') for el in editor.querySelectorAll('[align]')
      el.outerHTML = el.innerHTML for el in editor.querySelectorAll('span')
      el.remove() for el in editor.querySelectorAll('span:empty')
      el.removeAttribute('class') for el in editor.querySelectorAll("[class^='Mso']")
      el.remove() for el in editor.querySelectorAll('p:empty')
      editor

    removeAttribute: (element) ->
      return if !element
      for att in element.attributes
        element.removeAttribute(att.name)

    removeAttributes: (html) =>
      for node in html.querySelectorAll('*')
        @removeAttribute node
      html

  window.ZammadChat = ZammadChat
