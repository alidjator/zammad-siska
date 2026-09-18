class App.DarkMode extends App.Controller
  constructor: ->
    super

    @quickToggle         = $('#dark-mode-quick-switch')
    @quickToggleLabel    = @quickToggle.next('label')
    @quickToggleMenuItem = @quickToggle.closest('.dropdown-menu-item--toggle').find('span.u-textTruncate')

    @quickToggleMenuItem.on('click', @onMenuItemClick)
    @quickToggleLabel.on('click', @quickToggleChange)
    @controllerBind('ui:theme:changed', @onUpdate)

  currentTheme: ->
    if @quickToggle.prop('checked') then 'dark' else 'light'

  oppositeTheme: ->
    if @quickToggle.prop('checked') then 'light' else 'dark'

  onMenuItemClick: (event) =>
    event.stopPropagation()
    @quickToggleLabel.trigger('click')

  quickToggleChange: (event) =>
    event.stopPropagation()
    App.Event.trigger('ui:theme:set', { theme: @oppositeTheme(), save: true, toggleLoop: true })

  onUpdate: (event) =>
    return if event.toggleLoop is true
    return if event.theme is @currentTheme()

    @quickToggle.prop('checked', if event.theme is 'dark' then true else false)

# divider: true added (Fase 4, AUX Status) -- with the new AUX Status
# group now registered right before this one (prio 950-954, see
# aux_status_switch.coffee), Dark Mode needs its own leading divider to
# stay visually separated, the same way Logout separates itself from
# whatever's above it (logout.coffee, prio 1800, divider: true) --
# dividers are always owned by the item AFTER the gap, not before.
App.Config.set('DarkMode', { prio: 1000, parent: '#current_user', name: __('Dark Mode'), translate: true, toggle: 'dark-mode-quick', checked: (-> document.documentElement.dataset.theme == 'dark'), permission: ['user_preferences.appearance'], divider: true }, 'NavBarRight')
