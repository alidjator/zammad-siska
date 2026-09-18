# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). Full-screen
# "freeze" overlay shown while the agent is on a TIMED status (any
# status with duration_minutes > 0 in Setting aux_status_options -- e.g.
# Busy Lunch/Meeting/Training out of the box) -- explicit user decision:
# only statuses with a real duration to count down (NOT Available/
# Offline, which have nothing to time), with a manual "End break now"
# escape hatch so the agent is never fully locked out if something
# urgent comes up. See docs/DESIGN_AUX_STATUS.md Section 6h/6j.
#
# "Timed" is derived purely from aux_status_expires_at being present,
# not a hardcoded status-key list -- the backend
# (Service::AuxStatus::ChangeStatus#expires_at) only ever sets that
# field when the CURRENT Setting says this status has a real duration,
# so checking it here automatically covers any status an admin adds
# later too, with zero code changes needed on this end.
#
# Countdown is driven client-side from aux_status_expires_at (already
# available locally via App.Session, synced whenever the User record
# refreshes) rather than waiting on the server. This gives a precise,
# instant end-of-break instead of depending on
# Service::AuxStatus::ExpireStatuses' up-to-1-minute Scheduler poll --
# that Scheduler still runs server-side as a safety net for cases where
# the browser is closed/disconnected during the break, this overlay is
# purely a client-side convenience layered on top of it, not a
# replacement.
#
# Singleton pattern (@current), NOT re-constructed on every
# Navigation#renderPersonal like AuxStatusSwitchWidget/DarkMode --
# recreating this one on every render would restart the countdown
# display and could stack duplicate overlays/intervals. #sync is called
# once per renderPersonal (see _plugin/navigation.coffee) and only
# actually creates/tears down the overlay when the freeze-worthy state
# has genuinely changed.
class App.AuxStatusFreezeWidget extends App.Controller
  @current: null

  @sync: ->
    status    = App.Session.get('aux_status')
    expiresAt = App.Session.get('aux_status_expires_at')

    shouldShow = !!expiresAt

    if !shouldShow
      App.AuxStatusFreezeWidget.current?.teardown()
      App.AuxStatusFreezeWidget.current = null
      return

    return if App.AuxStatusFreezeWidget.current # already showing -- its own interval keeps ticking

    App.AuxStatusFreezeWidget.current = new App.AuxStatusFreezeWidget(status: status, expiresAt: new Date(expiresAt))

  constructor: (@options = {}) ->
    super
    @renderOverlay()
    @tick()
    @interval = setInterval(@tick, 1000)

  renderOverlay: =>
    match      = App.AuxStatusSwitch.findOption(@options.status)
    statusName = if match then App.i18n.translateInline(match.label) else @options.status

    @el = $(App.view('aux_status_freeze')(statusName: statusName))
    @el.appendTo('body')
    @el.find('.js-aux-status-end-break').on('click', @endBreak)

  tick: =>
    remainingMs = @options.expiresAt.getTime() - Date.now()

    if remainingMs <= 0
      @endBreak()
      return

    totalSeconds = Math.floor(remainingMs / 1000)
    minutes      = Math.floor(totalSeconds / 60)
    seconds      = totalSeconds % 60
    display      = "#{minutes}:#{if seconds < 10 then '0' else ''}#{seconds}"
    @el.find('.js-aux-status-countdown').text(display)

  endBreak: =>
    return if @ending
    @ending = true

    @ajax(
      id:          'aux-status-end-break'
      type:        'PUT'
      url:         "#{@apiPath}/aux_status"
      data:        JSON.stringify(status: 'available')
      processData: true
      success:     (data) =>
        App.User.refresh([data], clear: false)
        App.Event.trigger('personal:render')
      error:       =>
        @ending = false
    )

  teardown: ->
    clearInterval(@interval) if @interval
    @el?.remove()
