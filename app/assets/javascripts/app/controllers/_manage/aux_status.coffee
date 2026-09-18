# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). Admin >
# Manage > AUX Status -- lets a supervisor/admin (permission
# aux_status.override) see every agent's current AUX status and override
# it, complementing the self-service dropdown in the personal nav menu
# (aux_status_switch.coffee). See docs/DESIGN_AUX_STATUS.md Section
# 5.7/6d/6n/6o.
#
# Search-first, NOT load-everything-on-open -- per explicit user request
# after the org's real agent count (513, see docs/DESIGN_AUX_STATUS.md
# Section 6b) made the page slow to open every time, even for an admin
# who just wants to override ONE specific agent. Nothing is fetched
# until the admin actually types a search term -- GET /api/v1/aux_statuses
# itself now requires a non-blank `query` and returns an empty array
# immediately (no DB/permission-check work at all) when it's missing,
# see AuxStatusesController#index.
#
# Pagination (below) is still client-side over whatever the CURRENT
# search returned -- a broad search term (e.g. a common first name) can
# still match more than one page's worth of agents.
class App.ManageAuxStatus extends App.Controller
  @requiredPermission: 'aux_status.override'
  header: __('AUX Status')

  PAGE_SIZE: 25

  elements:
    '.js-aux-status-search': 'searchInput'

  events:
    'change .js-aux-status-select': 'onChangeStatus'
    'click .js-page':               'onPageClick'
    'keyup .js-aux-status-search':  'onSearchInput'

  constructor: ->
    super
    @page          = 0 # 0-indexed, matching generic/table_pager's own convention (reused as-is below)
    @sortedAgents  = []
    @query         = ''
    @html App.view('manage/aux_status')()
    @showHint(__('Type at least 2 characters to search for an agent.'))

  onSearchInput: =>
    @delay(@runSearch, 300, 'aux-status-search')

  runSearch: =>
    query = (@searchInput.val() || '').trim()
    @query = query

    if query.length < 2
      @showHint(__('Type at least 2 characters to search for an agent.'))
      return

    @search(query)

  showHint: (text) =>
    @$('.js-aux-status-body').html("<p class=\"u-textMuted\">#{App.Utils.htmlEscape(text)}</p>")

  # Deliberately NOT using @startLoading()/@stopLoading() -- confirmed
  # earlier this Fase (see docs/DESIGN_REPORTING_FRT.md Section 6, same
  # root cause) that native startLoading()'s anti-flicker delay
  # (App.Delay, 1800ms, random key when none given) can inject
  # "Loading…" and never have it cleared if that timer fires before
  # stopLoading() runs -- stopLoading() only cancels a live timer, it
  # doesn't touch already-injected DOM. Direct injection/clearing into
  # a specific placeholder (.js-aux-status-body) sidesteps that
  # entirely: a success always overwrites it via #renderPage, and the
  # error branch explicitly clears/replaces it too, so it can never get
  # stuck.
  search: (query) =>
    @$('.js-aux-status-body').html(App.view('generic/page_loading')())
    @ajax(
      id:          'aux_statuses'
      type:        'GET'
      url:         "#{@apiPath}/aux_statuses"
      data:
        query: query
      processData: true
      success:     (data) =>
        return if query isnt @query # a newer keystroke already started another search
        @sortedAgents = _.sortBy(data, (a) -> (a.fullname || '').toLowerCase())
        @page = 0
        @renderPage()
      error: (xhr) =>
        return if query isnt @query
        message = xhr.responseJSON?.error || __('The AUX status list could not be loaded.')
        @$('.js-aux-status-body').html("<div class=\"alert alert--danger\">#{App.Utils.htmlEscape(message)}</div>")
    )

  # Reuses the SAME pagination partial (generic/table_pager) native
  # Admin list pages (Roles, Groups, ...) already render, rather than a
  # hand-rolled version -- confirmed by reading it first: 0-indexed
  # pages, @pages is the LAST page's index (not a count), 'js-page'
  # class + data-page drive the click target.
  renderPage: =>
    lastPageIndex = Math.max(0, Math.ceil(@sortedAgents.length / @PAGE_SIZE) - 1)
    @page         = Math.min(Math.max(0, @page), lastPageIndex)

    start = @page * @PAGE_SIZE
    page  = @sortedAgents.slice(start, start + @PAGE_SIZE)

    @$('.js-aux-status-body').html App.view('manage/aux_status_table')(
      agents:        page
      statuses:      App.AuxStatusSwitch.options()
      page:          @page
      lastPageIndex: lastPageIndex
      totalCount:    @sortedAgents.length
    )

  onPageClick: (e) =>
    e.preventDefault()
    return if $(e.currentTarget).hasClass('is-disabled')

    page = parseInt($(e.currentTarget).data('page'), 10)
    return if isNaN(page) or page is @page
    @page = page
    @renderPage()

  onChangeStatus: (e) =>
    select  = $(e.currentTarget)
    user_id = select.closest('tr').data('id')
    status  = select.val()

    select.prop('disabled', true)

    @ajax(
      id:          'aux-status-override'
      type:        'PUT'
      url:         "#{@apiPath}/aux_status/#{user_id}"
      data:        JSON.stringify(status: status)
      processData: true
      success:     (data) =>
        App.User.refresh([data], clear: false)
        @search(@query) if @query
      error: (xhr) =>
        select.prop('disabled', false)
        message = xhr.responseJSON?.error || __('The AUX status could not be changed.')
        new App.ControllerConfirm(
          head:         __('AUX Status')
          message:      message
          buttonCancel: false
          buttonSubmit: __('OK')
        )
    )

App.Config.set('ManageAuxStatus', {
  prio:       2900
  name:       __('AUX Status')
  parent:     '#manage'
  target:     '#manage/aux_status'
  controller: App.ManageAuxStatus
  permission: ['aux_status.override']
}, 'NavBarAdmin')
