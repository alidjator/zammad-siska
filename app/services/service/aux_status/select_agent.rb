# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). Picks one
# agent out of a list of candidates, per the routing method chosen in
# Setting aux_status_routing_method. See docs/DESIGN_AUX_STATUS.md
# Section 2a / 5.3.
class Service::AuxStatus::SelectAgent
  def self.pick(candidates)
    new(candidates).pick
  end

  def initialize(candidates)
    @candidates = candidates.to_a
  end

  def pick
    return if @candidates.blank?

    case Setting.get('aux_status_routing_method')
    when 'fewestcalls'
      pick_fewestcalls
    when 'roundrobin'
      pick_roundrobin
    else
      pick_leastrecent
    end
  end

  private

  # Agent Available paling lama TIDAK menerima assignment tiket. Dihitung
  # real-time dari data tiket (bukan counter tersimpan) -- nil (belum
  # pernah dapat tiket sama sekali) diperlakukan sebagai prioritas
  # tertinggi.
  def pick_leastrecent
    @candidates.min_by { |agent| last_owner_update_at(agent)&.to_f || 0.0 }
  end

  def last_owner_update_at(agent)
    Ticket.where(owner_id: agent.id).maximum(:last_owner_update_at)
  end

  # Beban kerja saat ini paling sedikit -- jumlah tiket berstatus kategori
  # "open" yang jadi milik agent tsb sekarang, bukan histori/total
  # sepanjang waktu (lihat keputusan Section 4 poin 2 / hasil klarifikasi
  # basis fewestcalls).
  def pick_fewestcalls
    @candidates.min_by { |agent| open_ticket_count(agent) }
  end

  def open_ticket_count(agent)
    Ticket.where(owner_id: agent.id, state_id: Ticket::State.by_category_ids(:open)).count
  end

  # Satu-satunya strategi yang butuh state tersimpan -- pointer user_id
  # terakhir yang dapat giliran, di Setting aux_status_roundrobin_pointer.
  def pick_roundrobin
    sorted  = @candidates.sort_by(&:id)
    pointer = Setting.get('aux_status_roundrobin_pointer')

    next_agent = sorted.find { |agent| pointer.nil? || agent.id > pointer } || sorted.first
    Setting.set('aux_status_roundrobin_pointer', next_agent.id)
    next_agent
  end
end
