# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). Quick status
# switcher in the personal/avatar nav dropdown -- see
# docs/DESIGN_AUX_STATUS.md Section 5.7 / 6j.
#
# The list of statuses is DYNAMIC, read from Setting aux_status_options
# (JSON string, frontend: true -- see
# script/create_aux_status_object_attributes.rb) via
# App.Config.get('aux_status_options'), per explicit user request that
# admins be able to add/remove AUX statuses from a Setting, not a
# hardcoded list. Because the count can change at runtime, the
# NavBarRight entries for each row can't be registered once at file-load
# time like a normal fixed nav item (e.g. App.DarkMode) -- they're
# (re-)registered by #syncNavBarEntries, called from
# Navigation#renderPersonal (_plugin/navigation.coffee) BEFORE that
# method reads NavBarRight to build the menu, so the row count always
# matches the current Setting value. Stale entries from a previously
# longer list are explicitly removed first (App.Config.delete), not
# just overwritten, so shrinking the list actually removes rows instead
# of leaving orphaned/blank ones behind.
#
# Registered as flat NavBarRight entries (parent: '#current_user'), the
# same mechanism App.DarkMode uses for its own single entry --
# confirmed by reading _plugin/navigation.coffee#getItems /
# views/navigation/personal.jst.eco first: nesting only goes ONE level
# deep (a level1 icon -> a flat list of child rows), the child template
# loop has no further '.child' support of its own, so a submenu-within-
# the-submenu ("AUX Status" > N options) is not something this component
# can render -- the options are their own flat rows instead, grouped
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
  registeredKeys: []

  # Setting aux_status_options is stored as a JSON STRING (see
  # script/create_aux_status_object_attributes.rb for why), so this
  # always needs an explicit parse -- never assume App.Config.get
  # already returns an Array here.
  options: ->
    raw = App.Config.get('aux_status_options')
    return [] if !raw
    try
      JSON.parse(raw)
    catch e
      []

  currentStatus: ->
    App.Session.get('aux_status') || 'available'

  findOption: (value) ->
    _.find(App.AuxStatusSwitch.options(), (option) -> option.value is value)

  syncNavBarEntries: ->
    App.Config.delete(key, 'NavBarRight') for key in App.AuxStatusSwitch.registeredKeys
    App.AuxStatusSwitch.registeredKeys = []

    for option, index in App.AuxStatusSwitch.options()
      do (option, index) ->
        configKey = "AuxStatusSwitch::#{option.value}"
        App.AuxStatusSwitch.registeredKeys.push(configKey)
        App.Config.set(configKey, {
          prio:           (950 + index)
          parent:         '#current_user'
          name:           option.label
          translate:      false
          target:         '#'
          key:            "aux-status-#{option.value}"
          containerClass: 'js-aux-status-row'
          permission:     ['ticket.agent']
          divider:        index is 0
          navheader:      (if index is 0 then __('AUX Status') else undefined)
          callback:       ->
            # 'checkmark', NOT 'check' -- 'check' is not a real icon in
            # Zammad's sprite (public/assets/images/icons.svg has no
            # icon-check). App.Utils.icon() never validates the name, it
            # just blindly emits <svg><use href="#icon-check"/></svg> --
            # a <use> pointing at a non-existent id resolves to nothing,
            # and with no matching CSS to size it, a bare <svg> falls
            # back to the browser default replaced-element size
            # (300x150px) inside this 39px-tall row, visually pushing/
            # covering the row's own text. This was the real root cause
            # of the "selected status text invisible" bug reported by
            # the user.
            iconClass: (if App.AuxStatusSwitch.currentStatus() is option.value then 'checkmark' else undefined)
        }, 'NavBarRight')

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
