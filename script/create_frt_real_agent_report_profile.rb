# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# New Report Profile: First Response Time, restricted to genuinely
# customer-initiated tickets -- fixes a gap found while reviewing Fase 1
# reporting deliverables (native Admin > Reporting > "First Response
# Time (median minutes)" showed a flat ~0 line for nearly every month
# of 2026 under the "-all-" profile).
#
# Root cause (NOT the timezone migration bug -- checked and ruled out,
# clean post-cutover September 2026 data shows the same pattern): a
# large share of tickets in this instance (~68% in the Jan-Aug 2026
# sample checked) are AGENT-initiated (e.g. logging a completed phone
# call) rather than customer-initiated (inbound email/chat/web form).
# For an agent-initiated ticket, the agent creates the ticket AND
# writes its first article in the same action, so `first_response_at`
# is trivially ~= `created_at` by construction -- not a real
# "responsiveness" measurement. Verified via
# `create_article_sender_id`: tickets whose first article's sender is
# "Customer" have median FRT ~25 minutes (realistic); tickets whose
# first article's sender is "Agent" have median FRT ~0.01 minutes.
#
# This profile filters on `ticket.create_article_sender_id = Customer`
# so Report::TicketFirstResponseTime (lib/report/ticket_first_response_time.rb,
# see its own data-integrity note re: the timezone bug) reflects real
# human agent responsiveness to genuine customer inquiries, not diluted
# by agent-logged tickets.
#
#   bundle exec rails runner script/create_frt_real_agent_report_profile.rb RAILS_ENV=production

UserInfo.current_user_id = 1

customer_sender_id = Ticket::Article::Sender.find_by!(name: 'Customer').id

Report::Profile.create_if_not_exists(
  name:      'FRT: Customer-Initiated Tickets Only',
  condition: {
    'ticket.create_article_sender_id' => { 'operator' => 'is', 'value' => customer_sender_id.to_s },
  },
  active:      true,
  created_by_id: 1,
  updated_by_id: 1,
)

puts 'Done.'
