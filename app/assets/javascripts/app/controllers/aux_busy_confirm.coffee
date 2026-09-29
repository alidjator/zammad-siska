# Konfirmasi sebelum masuk status AUX berdurasi (Busy, memicu layar freeze)
# saat agent masih punya chat berjalan -- selama freeze customer tidak dapat
# balasan. Opsi (a) keputusan user 29 Sep, mockup Aux-BusyConfirm,
# docs/DESIGN_AUX_STATUS.md. Modal & tombol = komponen kit Able Pro
# (.modal-content/.modal-header/.modal-footer, .btn-secondary/.btn-primary),
# gaya di aux_status.scss (.aux-kit-*).
#
# Dipanggil dari AuxStatusSwitchWidget#onClick. Daftar chat berjalan diisi
# halaman Customer Chat (App.CustomerChat#renderHeader) ke
# App.AuxBusyConfirm.runningChats. Level file hanya definisi kelas (lihat
# insiden 29 Sep di DESIGN_AUX_STATUS.md).
class App.AuxBusyConfirm extends App.Controller
  @runningChats: []

  constructor: (@options = {}) ->
    super
    option   = @options.option || {}
    minutes  = parseInt(option.duration_minutes, 10) || 0
    label    = App.i18n.translateInline(option.label || option.value)
    chats = for chat in (@options.chats || [])
      name:    chat.name || App.i18n.translatePlain('Customer')
      initials: App.SiskaFormat?.initials?(chat.name || '') || (chat.name || '?').substr(0, 2).toUpperCase()
      ago:     @ago(chat.lastAt)
    @el = $(App.view('aux_busy_confirm')(
      status:  label
      minutes: minutes
      count:   chats.length
      chats:   chats
    ))
    @el.appendTo('body')
    @el.on('click', '.js-auxConfirmCancel', @cancel)
    @el.on('click', '.js-auxConfirmOk', @confirm)
    @el.on('click', (e) => @cancel(e) if e.target is @el[0])
    @onKey = (e) => @cancel(e) if e.key is 'Escape'
    $(document).on('keydown', @onKey)
    # fokus aman ke Cancel (tindakan yang tidak mengubah apa pun)
    @el.find('.js-auxConfirmCancel').trigger('focus')

  ago: (at) ->
    return '' if !at
    minutes = Math.floor((Date.now() - at) / 60000)
    return App.i18n.translatePlain('just now') if minutes < 1
    App.i18n.translatePlain('%s min ago', minutes)

  cancel: (e) =>
    e?.preventDefault()
    @close()

  confirm: (e) =>
    e?.preventDefault()
    @close()
    @options.onConfirm?()

  close: =>
    $(document).off('keydown', @onKey)
    @el?.remove()
