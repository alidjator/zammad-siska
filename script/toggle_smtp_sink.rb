# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Mitigation #2 from docs/INCIDENT_EMAIL_NOTIFICATION_TESTING.md
# (recommendation, not yet committed to that filename since the report
# itself was kept out of git -- see docs/TASKLIST_SISKA.md /
# ACTIVITY_LOG_SISKA.md instead): a toggle to temporarily redirect ALL
# outbound SMTP channels to a local sink (Mailpit, see
# script/create_smtp_sink.rb) during an active testing session, so no
# outbound email can physically leave the server and reach a real
# recipient regardless of what testing does -- independent of, and a
# stronger guarantee than, the "QA - Internal Testing" group (mitigation
# #1, script/create_qa_testing_group.rb), which only stops the *group
# member* notification path specifically.
#
# IMPORTANT: this is a SHARED system also used for real support work
# (see docs/ANONYMIZATION_CONTACT_INFO.md background) -- while enabled,
# ALL real outbound email (agent replies, ticket-update notifications,
# etc.) is also silently captured by the sink instead of reaching real
# recipients. Only enable this immediately before a testing session,
# and ALWAYS disable it again right after -- coordinate timing with
# real agents' working hours. Verify with `disable` that the original
# configuration was restored, don't just assume it.
#
# State (which channels were touched, and their original values) is
# kept in STATE_PATH so `disable` knows exactly what to restore --
# contains no PII (SMTP host/port/user only), safe to inspect, but
# container-local (lost if the container is recreated; if that happens
# after `enable` without a matching `disable`, the *real* channel
# configuration in the database is still visible via Channel.find and
# can be restored manually from docs/DESIGN_* or by an admin).
#
#   bundle exec rails runner "script/toggle_smtp_sink.rb enable"  RAILS_ENV=production
#   bundle exec rails runner "script/toggle_smtp_sink.rb disable" RAILS_ENV=production
#   bundle exec rails runner "script/toggle_smtp_sink.rb status"  RAILS_ENV=production

require 'json'

STATE_PATH = '/tmp/smtp_sink_toggle_state.json'
SINK_HOST  = 'siska-qa-mailsink'
SINK_PORT  = '1025'

mode = ARGV[0]
raise "Usage: toggle_smtp_sink.rb [enable|disable|status], got: #{mode.inspect}" if !%w[enable disable status].include?(mode)

def smtp_channels
  Channel.all.select { |c| c.options.dig('outbound', 'adapter') == 'smtp' }
end

case mode
when 'status'
  smtp_channels.each do |c|
    o = c.options['outbound']['options']
    puts "channel id=#{c.id} area=#{c.area} active=#{c.active} outbound_host=#{o['host']} outbound_port=#{o['port']}"
  end
  puts "state file present: #{File.exist?(STATE_PATH)} (#{STATE_PATH})"

when 'enable'
  raise "Aborting: #{STATE_PATH} already exists -- looks like sink mode is already ON (or a previous run didn't clean up). Run 'status' to check, and 'disable' first if needed." if File.exist?(STATE_PATH)

  state = {}
  smtp_channels.each do |c|
    o = c.options.deep_dup
    outbound_opts = o['outbound']['options']
    state[c.id] = { 'host' => outbound_opts['host'], 'port' => outbound_opts['port'], 'ssl' => o['outbound']['ssl'] }

    outbound_opts['host'] = SINK_HOST
    outbound_opts['port'] = SINK_PORT
    o['outbound']['ssl'] = false if o['outbound'].key?('ssl')

    c.update!(options: o)
    puts "channel id=#{c.id}: outbound redirected to #{SINK_HOST}:#{SINK_PORT} (was #{state[c.id]['host']}:#{state[c.id]['port']})"
  end

  File.write(STATE_PATH, JSON.pretty_generate(state))
  puts "Sink mode ON. #{state.size} channel(s) redirected. Remember to run 'disable' when the testing session ends."

when 'disable'
  raise "Aborting: #{STATE_PATH} not found -- nothing to restore (sink mode is probably already off)." if !File.exist?(STATE_PATH)

  state = JSON.parse(File.read(STATE_PATH))
  state.each do |channel_id, original|
    c = Channel.find(channel_id.to_i)
    o = c.options.deep_dup
    o['outbound']['options']['host'] = original['host']
    o['outbound']['options']['port'] = original['port']
    o['outbound']['ssl'] = original['ssl'] if o['outbound'].key?('ssl')
    c.update!(options: o)
    puts "channel id=#{c.id}: outbound restored to #{original['host']}:#{original['port']}"
  end

  File.delete(STATE_PATH)
  puts 'Sink mode OFF. Original configuration restored.'
end
