# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Admin-editable setting for the Reporting download-size guard (see
# docs/DESIGN_REPORTING_FRT.md) -- area 'Reporting::Base', viewable/
# editable via Admin > Settings > SISKA > Reporting.
#
#   bundle exec rails runner script/create_reporting_settings.rb RAILS_ENV=production
#
# create_if_not_exists is a no-op if already present -- to change
# afterwards, either use the Admin UI above, or:
#
#   Setting.set('report_download_max_records', 10000)

# Default 10,000 chosen from measured throughput on staging (~440
# tickets/sec via Report::*.items -- see docs/DESIGN_REPORTING_FRT.md):
# keeps a download request under roughly 20-25 seconds even at the
# limit, while comfortably covering realistic single-profile,
# single-year report sizes (a full year of a real profile measured
# ~5,600-8,500 rows).
Setting.create_if_not_exists(
  title:       'Reporting Download Max Records',
  name:        'report_download_max_records',
  area:        'Reporting::Base',
  description: 'Batas jumlah tiket maksimum untuk satu kali unduhan data Reporting (tombol "DOWNLOAD ... RECORD(S)"). Kombinasi Profile + rentang waktu yang melebihi batas ini akan ditolak dengan pesan error, bukan diproses (mencegah proses yang sangat lambat/membebani server -- lihat docs/DESIGN_REPORTING_FRT.md).',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'report_download_max_records',
        tag:     'input',
        type:    'number',
      },
    ],
  },
  state:       10_000,
  preferences: { permission: ['admin.system'] },
  frontend:    false,
)

puts 'Done.'
