# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# User bertanya "apakah ada tabel yang limit perpage nya masih belum
# configurable?" -- disurvei lewat grep ke seluruh app: SEMUA halaman
# Admin > Manage yang sudah server-side (baik native Zammad -- Groups,
# Roles, Users, Organizations, Triggers, Macros, Templates, Webhooks,
# Jobs, Text Modules, Report Profiles, Core Workflow, Public Links,
# Overview config -- MAUPUN 3 yang baru dikonversi sesi ini -- Ticket
# States, Ticket Priorities, Checklist Templates) hardcode
# `pagerPerPage: 50` langsung di CoffeeScript, tidak ada satu pun yang
# bisa diubah lewat Setting. Ini konvensi native Zammad sendiri (14 dari
# 17 file itu kode asli Zammad, bukan buatan proyek ini).
#
# Atas permintaan user "tambahkan untuk semuanya", dibuat SATU Setting
# BERSAMA (bukan 17 Setting terpisah per tabel) -- karena ke-17 halaman
# ini secara konseptual sama persis (ukuran halaman daftar CRUD Admin
# generik), beda dari report_preview_per_page/aux_status_manage_per_page
# yang memang beda domain (fitur custom masing-masing). Semua 17
# controller diubah dari `pagerPerPage: 50` (angka tetap) jadi
# `pagerPerPage: parseInt(App.Config.get('ui_admin_list_per_page'), 10)
# || 50` -- default TETAP 50 kalau Setting belum diisi/kosong, jadi
# perilaku tidak berubah sampai admin benar-benar mengubah nilainya.
#
# Setting ini MURNI dibaca frontend (App.Config.get, frontend: true) --
# backend `IndexFull`/`SearchFull` native SUDAH menerima `per_page`
# apa pun yang dikirim client (dikonfirmasi lewat pembacaan
# _generic_index.coffee sebelumnya di sesi ini, tidak ada whitelist
# angka di sisi server), jadi tidak perlu perubahan backend.
#
#   bundle exec rails runner script/create_admin_list_per_page_setting.rb RAILS_ENV=production

puts '== Setting: ui_admin_list_per_page =='
Setting.create_if_not_exists(
  title:       'Admin List Rows Per Page',
  name:        'ui_admin_list_per_page',
  area:        'SISKA::AdminListPagination',
  description: 'Jumlah baris per halaman untuk semua tabel Admin > Manage yang sudah server-side pagination (Groups, Roles, Users, Organizations, Triggers, Macros, Templates, Webhooks, Jobs, Text Modules, Report Profiles, Core Workflow, Public Links, Overview config, Ticket States, Ticket Priorities, Checklist Templates). Tidak memengaruhi Reporting preview atau Manage AUX Status, yang punya Setting ukuran halamannya sendiri.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'ui_admin_list_per_page',
        tag:     'input',
        type:    'number',
      },
    ],
  },
  state:       50,
  preferences: { permission: ['admin.system'] },
  frontend:    true,
)

puts 'Done.'
