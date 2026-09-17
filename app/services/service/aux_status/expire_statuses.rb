# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). Runs
# periodically via Scheduler (see docs/DESIGN_AUX_STATUS.md Section 5.4).
# Reverts any user whose timed aux_status has passed its
# aux_status_expires_at back to "available" -- never to "offline", only
# the timed/temporary statuses (Busy Lunch/Meeting/Training) auto-expire,
# per Section 4 decision. changed_by: nil marks these as system-driven in
# AuxStatusLog (see Service::AuxStatus::ChangeStatus#authorize!).
class Service::AuxStatus::ExpireStatuses
  def self.run
    new.run
  end

  def run
    User.where.not(aux_status_expires_at: nil)
        .where(aux_status_expires_at: ..Time.zone.now)
        .find_each do |user|
      Service::AuxStatus::ChangeStatus.run(target: user, status: 'available', changed_by: nil)
    end
  end
end
