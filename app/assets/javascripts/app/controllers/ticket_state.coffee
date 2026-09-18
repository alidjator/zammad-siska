class TicketState extends App.ControllerSubContent
  @requiredPermission: 'admin.ticket_state'
  header: __('Ticket States')
  constructor: ->
    super

    @pendingActionStateTypeId = App.TicketStateType.findByAttribute('name', 'pending action').id.toString()

    @genericController = new App.ControllerGenericIndex(
      el: @el
      id: @id
      genericObject: 'TicketState'
      defaultSortBy: 'name'
      handlers: [@formHandler]
      editAvailable: (id) -> App.TicketState.find(id)?.state_type?.name isnt 'merged'
      pageData:
        home: 'ticket_states'
        object: __('Ticket State')
        objects: __('Ticket States')
        searchPlaceholder: __('Search for ticket states')
        navupdate: '#ticket_states'
        # Server-side pagination (survey: "buat semua menjadi server-side
        # untuk semua yang masih belum server-side" -- see
        # docs/DESIGN_REPORTING_FRT.md Section 7/8) -- mirrors
        # group.coffee's own pagerAjax config exactly (same
        # App.ControllerGenericIndex, same generic manage/:target/:page/
        # :search_query route already registered for every Manage page in
        # manage.coffee, confirmed by reading it first).
        pagerAjax: true
        pagerBaseUrl: '#manage/ticket_states/'
        pagerSelected: ( @page || 1 )
        pagerPerPage: parseInt(App.Config.get('ui_admin_list_per_page'), 10) || 50
        buttons: [
          { name: __('New Ticket State'), 'data-type': 'new', class: 'btn--success' }
        ]
        tableExtend: {
          clone: (object) -> object.state_type.name isnt 'merged'
          customActions: [
            {
              name: 'set_default_create'
              display: __('Set default for new tickets')
              icon: 'reload'
              class: 'set_default_create'
              callback: (id) =>
                @setDefaultState('default_create', id)
              available: (object) ->
                object.active and not object.default_create and object.state_type.name isnt 'merged'
            },
            {
              name: 'set_default_follow_up'
              display: __('Set default for follow-ups')
              icon: 'reload'
              class: 'set_default_follow_up'
              callback: (id) =>
                @setDefaultState('default_follow_up', id)
              available: (object) ->
                object.active and not object.default_follow_up and object.state_type.name isnt 'merged'
            },
            {
              name: 'set_default_close'
              display: __('Set default for closed tickets')
              icon: 'reload'
              class: 'set_default_close'
              callback: (id) =>
                @setDefaultState('default_close', id)
              available: (object) ->
                object.active and not object.default_close and object.state_type.name isnt 'merged'
            },
          ]
        }
      container: @el.closest('.content')
      veryLarge: true
    )

  # Overrides App.ControllerSubContent's default no-arg show() -- needed
  # so clicking a pager link (which navigates to
  # #manage/ticket_states/:page/:search_query, handled generically by
  # ManageRouter, manage.coffee) actually re-fetches that page from the
  # server, exactly like group.coffee's own show() override does.
  show: (params) =>
    for key, value of params
      if key isnt 'el' && key isnt 'shown' && key isnt 'match'
        @[key] = value

    @genericController.paginate(@page || 1, params)

  formHandler: (params, attribute, attributes, classname, form, ui) =>
    merged_state = App.TicketStateType.findByAttribute('name', 'merged')
    form.find("select[name='state_type_id'] option[value='#{merged_state.id}']").remove()

    if params.state_type_id is @pendingActionStateTypeId
      form.find('[data-attribute-name="next_state_id"]').show()
    else
      form.find('[data-attribute-name="next_state_id"]').hide()

  setDefaultState: (type, id) ->
    currentItem = App.TicketState.findByAttribute(type, true)
    selectedItem = App.TicketState.find(id)

    return if not selectedItem
    return if currentItem?.id is selectedItem.id

    selectedItem.updateAttribute(type, true)
    if type == 'default_create'
      currentItem?.refresh(default_create: false)
    else if type == 'default_follow_up'
      currentItem?.refresh(default_follow_up: false)
    else if type == 'default_close'
      currentItem?.refresh(default_close: false)
    else
      console.error('Unknown default state type', type)


App.Config.set('Ticket States', { prio: 3325, name: __('Ticket States'), parent: '#manage', target: '#manage/ticket_states', controller: TicketState, permission: ['admin.object'], hidden: true }, 'NavBarAdmin')
