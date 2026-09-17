# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). Histori
# perubahan status AUX seorang agent, satu baris terbuka (ended_at nil)
# per user pada satu waktu. Lihat docs/DESIGN_AUX_STATUS.md Section 5.6.
class AuxStatusLog < ApplicationModel
  belongs_to :user, optional: false
  belongs_to :changed_by, class_name: 'User', optional: true

  validates :status, presence: true
  validates :started_at, presence: true

  def self.close_open_entry!(user)
    open_entry = where(user:, ended_at: nil).order(started_at: :desc).first
    return if !open_entry

    open_entry.update!(ended_at: Time.zone.now)
  end
end
