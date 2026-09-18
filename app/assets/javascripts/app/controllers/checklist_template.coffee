class ChecklistTemplate extends App.ControllerSubContent
  @requiredPermission: 'admin.checklist'
  header: __('Checklists')
  events:
    'change .js-checklistSetting input':  'toggleChecklistSetting'

  elements:
    '.js-checklistSetting input': 'checklistSetting'

  constructor: ->
    super
    @subscribeId = App.Setting.subscribe(@render, initFetch: true, clear: false)

  release: =>
    super
    App.Setting.unsubscribe(@subscribeId)

  render: =>
    elLocal = $(App.view('checklist_template/index')())

    @genericController?.releaseController()
    @genericController = new App.ControllerGenericIndex(
      el: elLocal.find('.js-checklistTemplatesTable')
      id: @id
      genericObject: 'ChecklistTemplate'
      defaultSortBy: 'name'
      pageData:
        home: 'checklists'
        head: __('Checklist Template')
        object: __('Manage Checklist Template')
        objects: __('Manage Checklist Templates')
        searchPlaceholder: __('Search for checklist templates')
        subHead: false
        navupdate: '#checklists'
        # Server-side pagination -- mirrors group.coffee's own pagerAjax
        # config exactly (see docs/DESIGN_REPORTING_FRT.md Section 8).
        pagerAjax: true
        pagerBaseUrl: '#manage/checklists/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: parseInt(App.Config.get('ui_admin_list_per_page'), 10) || 50
        notes: [
          __('With checklist templates it is possible to pre-fill new checklists with initial items.')
        ]
        buttons: [
          { name: __('New Checklist Template'), 'data-type': 'new', class: 'btn--success' }
        ]
      validateOnSubmit: @validateOnSubmit
    )

    @html elLocal

    value = @checklistSetting.prop('checked')
    checklistTemplatesTable = elLocal.find('.js-checklistTemplatesTable')
    if value is true
      checklistTemplatesTable.show()
    else
      checklistTemplatesTable.hide()

  # Overrides App.ControllerSubContent's default no-arg show() -- see
  # the identical override in ticket_state.coffee for why. render()
  # rebuilds @genericController from scratch on every Setting change
  # (unrelated to pagination), but a route navigation carrying a new
  # :page/:search_query needs this separate hook to re-paginate the
  # CURRENT instance instead.
  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

  validateOnSubmit: (params) ->
    errors = {}
    if !params.items || params.items.length is 0
      errors['items'] = __('Please add at least one item to the checklist.')

    errors

  toggleChecklistSetting: (e) =>
    value = @checklistSetting.prop('checked')
    App.Setting.set('checklist', value)

App.Config.set('Checklists', { prio: 2340, name: __('Checklists'), parent: '#manage', target: '#manage/checklists', controller: ChecklistTemplate, permission: ['admin.checklist'] }, 'NavBarAdmin')
