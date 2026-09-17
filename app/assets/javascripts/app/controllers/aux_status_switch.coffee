# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). Quick status
# switcher in the personal/avatar nav dropdown -- see
# docs/DESIGN_AUX_STATUS.md Section 5.7.
#
# Registered as 5 flat NavBarRight entries (parent: '#current_user'),
# the same mechanism App.DarkMode uses for its own single entry --
# confirmed by reading _plugin/navigation.coffee#getItems /
# views/navigation/personal.jst.eco first: nesting only goes ONE level
# deep (a level1 icon -> a flat list of child rows), the child template
# loop has no further '.child' support of its own, so a submenu-within-
# the-submenu ("AUX Status" > 5 options) is not something this component
# can render -- the 5 options are its own flat rows instead, grouped
# under one navheader/divider for clarity (the same navheader mechanism
# Navigation#recentViewNavbarItemsRebuild already uses).
#
# Each row's checkmark reflects the CURRENT status via `callback`, the
# same generic per-item reactive hook App.TaskManager workers use (see
# _plugin/navigation.coffee#filterNavbar) -- re-evaluated on every
# Navigation#renderPersonal, not just once at boot.
#
# Actual click handling is done by App.AuxStatusSwitchWidget, a small
# controller re-constructed fresh every renderPersonal call, exactly
# like `new App.DarkMode()` is (see navigation.coffee) -- plain jQuery
# bound to the freshly rendered `data-key` attributes, not the heavier
# TaskManager 'js-onclick' worker mechanism (meant for taskbar/overview
# items, not a simple menu action).
App.AuxStatusSwitch =
  STATUSES: [
    { key: 'available',     name: __('Available') }
    { key: 'busy_lunch',    name: __('Busy Lunch') }
    { key: 'busy_meeting',  name: __('Busy Meeting') }
    { key: 'busy_training', name: __('Busy Training') }
    { key: 'offline',       name: __('Offline') }
  ]

  currentStatus: ->
    App.Session.get('aux_status') || 'available'

class App.AuxStatusSwitchWidget extends App.Controller
  constructor: ->
    super
    $('.navbar-items-personal').find('[data-key^="aux-status-"]')
      .off('click.aux-status-switch')
      .on('click.aux-status-switch', @onClick)

  onClick: (event) =>
    event.preventDefault()
    event.stopPropagation()

    key    = $(event.currentTarget).data('key')
    status = key.replace('aux-status-', '')
    return if status is App.AuxStatusSwitch.currentStatus()

    @ajax(
      id:          'aux-status-switch'
      type:        'PUT'
      url:         "#{@apiPath}/aux_status"
      data:        JSON.stringify(status: status)
      processData: true
      success:     (data) =>
        App.User.refresh([data], clear: false)
        App.Event.trigger('personal:render')
      error: (xhr) =>
        message = xhr.responseJSON?.error || __('The AUX status could not be changed.')
        new App.ControllerConfirm(
          head:         __('AUX Status')
          message:      message
          buttonCancel: false
          buttonSubmit: __('OK')
        )
    )

for status, index in App.AuxStatusSwitch.STATUSES
  do (status, index) ->
    App.Config.set("AuxStatusSwitch::#{status.key}", {
      prio:       (950 + index)
      parent:     '#current_user'
      name:       status.name
      translate:  false
      target:     '#'
      key:        "aux-status-#{status.key}"
      permission: ['ticket.agent']
      divider:    index is 0
      navheader:  (if index is 0 then __('AUX Status') else undefined)
      callback:   ->
        iconClass: (if App.AuxStatusSwitch.currentStatus() is status.key then 'check' else undefined)
    }, 'NavBarRight')
