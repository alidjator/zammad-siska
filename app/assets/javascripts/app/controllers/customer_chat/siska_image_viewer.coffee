# Redesign sisi agent (Tahap 2) -- viewer gambar layar penuh (mockup
# artboard 6 "Viewer gambar layar penuh"), pola sama dgn viewer widget.
# Menggantikan App.CustomerChatImageView untuk jendela chat varian `siska`;
# App.MyChat tetap memakai modal lama.
#
# Sengaja bukan App.ControllerModal: tampilannya overlay gelap penuh, bukan
# modal Bootstrap. Ditempel di <body> (di luar .siska-agent halaman chat),
# jadi root-nya sendiri membawa class `siska-agent` supaya token kit berlaku.
class App.SiskaImageViewer
  constructor: (@options) ->
    @returnFocus = @options.returnFocus || document.activeElement
    @el = $(App.view('customer_chat/siska_image_viewer')(
      src:         @options.src
      name:        @options.name
      meta:        @options.meta
      downloadUrl: @options.downloadUrl
    ))
    @el.on('click', '.js-close', @close)
    # klik area gelap di luar gambar = tutup
    @el.on('click', '.js-stage', (e) => @close() if e.target is e.currentTarget)
    $(document).on('keydown.siska-viewer', @onKeydown)
    $('body').append(@el)
    @el.find('.js-close').trigger('focus')

  onKeydown: (e) =>
    if e.keyCode is 27
      e.preventDefault()
      e.stopPropagation()
      @close()
      return

    # tahan fokus di dalam viewer (Tab / Shift+Tab)
    return if e.keyCode isnt 9
    focusable = @el.find('a[href], button').filter(':visible')
    return if !focusable.length
    first = focusable.first().get(0)
    last = focusable.last().get(0)
    if e.shiftKey && document.activeElement is first
      e.preventDefault()
      last.focus()
    else if !e.shiftKey && document.activeElement is last
      e.preventDefault()
      first.focus()

  close: =>
    $(document).off('keydown.siska-viewer')
    @el.remove()
    $(@returnFocus).trigger('focus') if @returnFocus && document.body.contains(@returnFocus)
