# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). Native
# Transaction Backend (async), registered via Setting area
# Transaction::Backend::Async by script/create_aux_status_transaction_backend.rb
# -- same mechanism as e.g. Transaction::ClearbitEnrichment. This is the
# titik pemicu for "a brand-new ticket was just created unassigned" (can
# come from many code paths -- email channel, API, agent UI, chat -- so a
# Transaction Backend that watches ALL Ticket creation is the right hook,
# unlike the "agent went Available" trigger point, which is handled
# directly and synchronously inside Service::AuxStatus::ChangeStatus
# instead, since that code path is already fully controlled by us -- see
# docs/DESIGN_AUX_STATUS.md Section 5.5 for the rationale).
class Transaction::AuxStatusDistribution

=begin
  {
    object: 'Ticket',
    type: 'create',
    object_id: 123,
    ...
  },
=end

  def initialize(item, params = {})
    @item   = item
    @params = params
  end

  def perform
    return if Setting.get('import_mode')
    return if @item[:object] != 'Ticket'
    return if @item[:type] != 'create'

    ticket = Ticket.lookup(id: @item[:object_id])
    return if !ticket

    Service::AuxStatus::DistributeTicket.for_new_ticket(ticket)
    true
  end
end
