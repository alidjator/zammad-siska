# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Zammad's own native Setting `ui_ticket_overview_ticket_limit`
# (area UI::TicketOverview::TicketLimit, db/seeds/settings.rb) already
# controls the maximum number of tickets an Overview query returns
# (Ticket::Overviews.limit_per_overview, app/models/ticket/overviews.rb)
# -- the closest thing Zammad has to a "page size" for the ticket list
# every agent uses constantly. It already has `frontend: true` and
# permission admin.overview correctly set, but was seeded with
# `options: {}` -- no `form:` array -- so it has NO Admin UI anywhere to
# change it (confirmed by grepping the whole app for its name: only the
# Ruby usage site and the frontend type definition reference it, no
# Settings screen). It can currently only be changed via Rails console.
#
# This script does NOT touch the Setting's actual value/behavior at
# all -- it only adds the missing `options.form` UI metadata (the exact
# same single-number-input shape our own report_download_max_records/
# aux_status_manage_per_page Settings already use), so it can be
# rendered by the generic Admin Settings form
# (App.SettingsAreaItem/_settings/area_item.coffee) instead of throwing
# "No such options.form for ui_ticket_overview_ticket_limit" if
# rendering were attempted as-is.
#
#   bundle exec rails runner script/expose_ticket_overview_limit_setting.rb RAILS_ENV=production

setting = Setting.find_by(name: 'ui_ticket_overview_ticket_limit')
raise "Setting 'ui_ticket_overview_ticket_limit' not found -- unexpected on a standard Zammad install" if !setting

puts '== Setting: ui_ticket_overview_ticket_limit (adding missing options.form) =='
setting.update!(
  options: {
    form: [
      {
        display: '',
        null:    true,
        name:    'ui_ticket_overview_ticket_limit',
        tag:     'input',
        type:    'number',
      },
    ],
  },
)

puts 'Done.'
