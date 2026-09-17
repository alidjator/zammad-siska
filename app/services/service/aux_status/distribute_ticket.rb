# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). Two entry
# points, both proactive (push, not the reactive/claim native
# ticket_auto_assignment -- see docs/DESIGN_AUX_STATUS.md Section 1a/4):
#
# * .for_new_ticket(ticket) -- a brand-new ticket just got created
#   unassigned; try to push it to an Available agent in its Group right
#   away.
# * .pending_for(agent) -- an agent just went Available; pull in the
#   oldest unassigned ticket waiting in a Group this agent has access to.
#
# Both are called from Transaction::AuxStatusDistribution (Section 5.5).
class Service::AuxStatus::DistributeTicket
  UNASSIGNED_OWNER_ID = 1 # native Zammad convention, see Ticket#owner_id defaults

  def self.for_new_ticket(ticket)
    new.for_new_ticket(ticket)
  end

  def self.pending_for(agent)
    new.pending_for(agent)
  end

  def for_new_ticket(ticket)
    return if ticket.owner_id != UNASSIGNED_OWNER_ID
    return if ticket.group.blank?

    agent = Service::AuxStatus::SelectAgent.pick(available_agents_for(ticket.group))
    return if !agent

    ticket.update!(owner: agent)
  end

  def pending_for(agent)
    ticket = oldest_pending_ticket_for(agent)
    return if !ticket

    ticket.update!(owner: agent)
  end

  private

  # Section 4 decision (poin 3): kalau tidak ada kandidat Available sama
  # sekali, tiket TETAP unassigned biasa -- tidak ada fallback/eskalasi di
  # sini, sengaja dibiarkan return nil.
  # aux_status nil (belum pernah diubah sama sekali sejak field ini ada,
  # atau user baru dibuat setelahnya) diperlakukan sama dengan 'available'
  # -- Object Manager tidak menegakkan default di level kolom DB (murni
  # default form UI, tidak berlaku untuk field ini karena screens: {}),
  # jadi ini dilakukan di sini supaya agent yang belum pernah menyentuh
  # dropdown status tetap dianggap Available sesuai default yang disepakati
  # (Section 4 poin 1), bukan diam-diam terkecualikan dari distribusi.
  #
  # 'full' access, BUKAN 'change' -- ditemukan lewat pengujian langsung
  # (bukan tebakan) bahwa native Ticket#check_owner_active (before_save
  # callback bawaan Zammad) diam-diam mengembalikan owner_id ke 1 kalau
  # calon owner tidak punya akses 'full' ke Group tiket tsb -- assignment
  # ke agent ber-akses 'change' saja akan "berhasil" tanpa error (update!
  # return true) tapi nilainya langsung ditimpa balik sebelum tersimpan.
  def available_agents_for(group)
    User.group_access(group, 'full')
        .select { |agent| (agent.aux_status || 'available') == 'available' }
  end

  def oldest_pending_ticket_for(agent)
    accessible_group_ids = agent.groups.access('full').pluck(:id)
    return if accessible_group_ids.blank?

    Ticket.where(
      group_id: accessible_group_ids,
      owner_id: UNASSIGNED_OWNER_ID,
      state_id: Ticket::State.by_category_ids(:open),
    ).order(:created_at).first
  end
end
