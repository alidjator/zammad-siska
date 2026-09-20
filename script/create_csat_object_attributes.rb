# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Creates the Custom Object Attributes and Setting needed for native CSAT
# (see docs/DESIGN_FEEDBACK_RATING.md). Run once via:
#
#   bundle exec rails runner script/create_csat_object_attributes.rb RAILS_ENV=production
#
# Safe to re-run: ObjectManager::Attribute.add() without force: true updates
# an existing attribute in place rather than duplicating it, and
# Setting.create_if_not_exists skips settings that already exist.

UserInfo.current_user_id = 1

puts '== Ticket: csat_score =='
ObjectManager::Attribute.add(
  object:      'Ticket',
  name:        'csat_score',
  display:     'CSAT Score',
  data_type:   'integer',
  data_option: {
    default: '',
    min:     1,
    max:     5,
    null:    true,
    note:    'Customer satisfaction score (1-5), submitted by the customer after the ticket is closed.',
  },
  active:      true,
  screens:     {},
  position:    900,
)

puts '== Ticket: csat_submitted_at =='
# PENTING: `diff:` HARUS `nil`, BUKAN `0` -- `0` itu Integer, dan di Ruby
# Integer 0 itu truthy (cuma nil/false yg falsy). `ObjectManager::Attribute::
# SetDefaults#build_value_datetime` (kode inti Zammad) mengecek `return if
# !diff` -- kalau `diff` truthy (termasuk 0!), field ini akan OTOMATIS diisi
# `Time.zone.now` (dibulatkan ke menit) di SETIAP tiket baru dibuat, padahal
# field ini HARUS tetap kosong sampai customer BENERAN submit rating.
# Dikonfirmasi bug nyata: 114 tiket (built sejak attribute ini dibuat
# 2026-09-16) kena isi otomatis palsu. Attribute native Zammad sendiri
# (`pending_time`) memang selalu pakai `diff: nil` utk kasus "tidak ada
# auto-default" -- itu polanya yang benar, ditiru di sini.
ObjectManager::Attribute.add(
  object:      'Ticket',
  name:        'csat_submitted_at',
  display:     'CSAT Submitted At',
  data_type:   'datetime',
  data_option: {
    future:    true,
    past:      true,
    diff:      nil,
    null:      true,
    note:      'When the customer last (re)submitted their CSAT score.',
  },
  active:      true,
  screens:     {},
  position:    901,
)

puts '== Ticket: csat_comment =='
ObjectManager::Attribute.add(
  object:      'Ticket',
  name:        'csat_comment',
  display:     'CSAT Comment',
  data_type:   'textarea',
  data_option: {
    default:   '',
    rows:      4,
    maxlength: 2000,
    null:      true,
    note:      'Optional free-text comment submitted alongside the CSAT score.',
  },
  active:      true,
  screens:     {},
  position:    902,
)

puts '== Ticket: csat_feedback_link (internal) =='
ObjectManager::Attribute.add(
  object:      'Ticket',
  name:        'csat_feedback_link',
  display:     'CSAT Feedback Link',
  data_type:   'input',
  data_option: {
    type:      'text',
    maxlength: 255,
    null:      true,
    note:      'Internal: tokenized CSAT survey URL, populated by the CSAT scheduler job.',
  },
  active:      true,
  screens:     {},
  position:    903,
)

puts '== Ticket: csat_email_sent_at (internal) =='
# `diff: nil` -- lihat catatan panjang di attribute `csat_submitted_at`
# di atas (bug yg sama, field yg sama-sama HARUS tetap kosong sampai
# scheduler CSAT beneran mengisinya).
ObjectManager::Attribute.add(
  object:      'Ticket',
  name:        'csat_email_sent_at',
  display:     'CSAT Survey Sent At',
  data_type:   'datetime',
  data_option: {
    future:    true,
    past:      true,
    diff:      nil,
    null:      true,
    note:      'Internal: when the CSAT survey was last sent, to avoid re-sending. Reset on reopen when the group allows re-rating.',
  },
  active:      true,
  screens:     {},
  position:    904,
)

puts '== Group: csat_allow_rerating_on_reopen =='
ObjectManager::Attribute.add(
  object:      'Group',
  name:        'csat_allow_rerating_on_reopen',
  display:     'Allow CSAT Re-rating on Reopen',
  data_type:   'boolean',
  data_option: {
    default:    true,
    null:       true,
    note:       'If a ticket in this group is reopened and closed again, send a new CSAT survey. Disable for groups where a ticket should only ever be rated once (e.g. Payroll).',
    options:    {
      true:  'yes',
      false: 'no',
    },
    translate:  true,
  },
  active:      true,
  screens:     {
    edit: {
      '-all-' => {
        shown: true,
        null:  true,
      },
    },
  },
  position:    500,
)

puts '== Apply pending schema migrations =='
ObjectManager::Attribute.migration_execute

Ticket.reset_column_information
Group.reset_column_information

puts '== Setting: csat_feedback_expiry_days =='
Setting.create_if_not_exists(
  title:         'CSAT Feedback Link Expiry (days)',
  name:          'csat_feedback_expiry_days',
  area:          'CSAT::Base',
  description:   'Number of days a CSAT survey link stays valid after being sent.',
  options:       {
    form: [
      {
        display: '',
        null:    true,
        name:    'csat_feedback_expiry_days',
        tag:     'select',
        options: (1..30).index_with { |n| n.to_s },
      },
    ],
  },
  state:       7,
  preferences: {
    permission: ['admin.system'],
  },
  frontend:    false,
)

puts '== Setting: csat_feature_launched_at =='
# Internal cutoff: tickets closed before this timestamp are never surveyed,
# so enabling the feature doesn't flood the historical backlog with surveys.
#
# options.form is REQUIRED even for an "internal" setting like this one --
# App.SettingsArea (the generic Admin UI renderer, see
# _manage/siska_settings.coffee) lists every Setting under its area and
# crashes with "No such options.form for <name>" on any that lack a form
# definition. Confirmed by hitting this exact error after wiring CSAT::Base
# into the new "SISKA" admin tab.
Setting.create_if_not_exists(
  title:       'CSAT Feature Launched At',
  name:        'csat_feature_launched_at',
  area:        'CSAT::Base',
  description: 'Internal: tickets closed before this timestamp are never surveyed for CSAT. ISO8601 format.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'csat_feature_launched_at',
        tag:     'input',
        type:    'text',
      },
    ],
  },
  state:       Time.zone.now.iso8601,
  preferences: {
    permission: ['admin.system'],
  },
  frontend:    false,
)

puts '== Setting: csat_whatsapp_enabled (safety toggle) =='
# Off by default: the WhatsApp payload shape sent to the gateway is a
# best-effort guess (see docs/WHATSAPP_GATEWAY_REQUIREMENTS.md) until the
# team maintaining it confirms the actual contract. Email and Telegram are
# unaffected by this toggle -- they can go live independently.
Setting.create_if_not_exists(
  title:       'CSAT WhatsApp Sending Enabled',
  name:        'csat_whatsapp_enabled',
  area:        'CSAT::Base',
  description: 'Whether CSAT surveys are actually sent via WhatsApp. Keep disabled until the gateway payload format is confirmed with the team that maintains it (see docs/WHATSAPP_GATEWAY_REQUIREMENTS.md) -- does not affect Email or Telegram delivery.',
  options:     {
    form: [
      {
        display: '',
        null:    true,
        name:    'csat_whatsapp_enabled',
        tag:     'boolean',
        options: {
          true  => 'yes',
          false => 'no',
        },
      },
    ],
  },
  state:       false,
  preferences: {
    permission: ['admin.system'],
  },
  frontend:    false,
)

puts 'Done.'
