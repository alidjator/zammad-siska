# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). Friendly
# row-based editor for Setting aux_status_options, replacing the raw
# JSON textarea -- per explicit user request ("saya mau penambahan
# pengurangan ini menggunakan input field bukan dengan JSON, karena
# semua admin belum tentu tau JSON"). See docs/DESIGN_AUX_STATUS.md
# Section 6l.
#
# Registered via Setting#preferences.controller
# (script/create_aux_status_object_attributes.rb sets
# preferences: { controller: 'SettingsAreaAuxStatusOptions', ... }) --
# the native per-Setting override mechanism `_settings/area.coffee`
# already uses for e.g. App.SettingsAreaSwitch/
# App.SettingsAreaStorageProvider, confirmed by reading that file first
# rather than building a parallel mechanism of our own.
#
# The Setting itself is still stored as a JSON STRING (see the Ruby
# script for why) -- this widget just gives editing that string a
# proper UI instead of asking the admin to hand-write JSON, using the
# exact same App.Setting.set(name, value, ...) save path the generic
# Setting widgets use (confirmed by reading _settings/area_item.coffee
# and _settings/area_switch.coffee first).
class App.SettingsAreaAuxStatusOptions extends App.Controller
  events:
    'click .js-aux-status-option-add':    'addRow'
    'click .js-aux-status-option-remove': 'removeRow'
    'submit form':                        'save'

  constructor: ->
    super
    @options = @parseCurrentValue()
    @render()

  parseCurrentValue: ->
    raw = @setting.state_current?.value
    return @defaultOptions() if !raw

    try
      parsed = JSON.parse(raw)
    catch e
      parsed = null

    return @defaultOptions() if !_.isArray(parsed) || _.isEmpty(parsed)
    parsed

  defaultOptions: ->
    [{ value: '', label: '', duration_minutes: 0 }]

  render: =>
    @html App.view('settings/aux_status_options')(
      setting: @setting
      options: @options
    )

  addRow: (e) =>
    e.preventDefault()
    @collectFromDom()
    @options.push({ value: '', label: '', duration_minutes: 0 })
    @render()

  removeRow: (e) =>
    e.preventDefault()
    @collectFromDom()
    index = $(e.currentTarget).closest('.js-aux-status-option-row').data('index')
    @options.splice(index, 1)
    @options = @defaultOptions() if _.isEmpty(@options)
    @render()

  # Keep in-memory @options in sync with whatever's currently in the DOM
  # before add/remove-ing a row, so unsaved edits in OTHER rows aren't
  # lost when the table re-renders.
  collectFromDom: ->
    @options = @rowsFromDom()

  rowsFromDom: ->
    collected = []
    @$('.js-aux-status-option-row').each (i, row) =>
      row = $(row)
      collected.push(
        value:            row.find('.js-aux-status-option-value').val()
        label:            row.find('.js-aux-status-option-label').val()
        duration_minutes: parseInt(row.find('.js-aux-status-option-duration').val(), 10) || 0
      )
    collected

  save: (e) =>
    e.preventDefault()

    collected = @rowsFromDom()
    for option in collected
      option.value = (option.value || '').trim().toLowerCase().replace(/\s+/g, '_')
      option.label = (option.label || '').trim()

    if _.some(collected, (option) -> !option.value || !option.label)
      App.Event.trigger 'notify', {
        type:    'error'
        msg:     __('Setiap status harus punya Value dan Label.')
        timeout: 4000
      }
      return

    values = _.map(collected, (option) -> option.value)
    if values.length isnt _.uniq(values).length
      App.Event.trigger 'notify', {
        type:    'error'
        msg:     __('Value harus unik, tidak boleh ada yang sama.')
        timeout: 4000
      }
      return

    @formDisable(e)
    @options = collected

    App.Setting.set(
      @setting.name
      JSON.stringify(collected)
      notify:    true
      doneLocal: =>
        @formEnable(e)
        @render()
      failLocal: =>
        @formEnable(e)
    )
