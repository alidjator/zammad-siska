# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# "Online" untuk distribusi tiket AUX (docs/DESIGN_AUX_STATUS.md, bagian
# "AUX tanpa Offline"): agent punya minimal satu sesi websocket Zammad (sumber
# yang sama dengan titik hijau di avatar) dengan ping dalam IDLE_SECONDS
# terakhir. Sesi disimpan di Redis (Sessions store) sehingga terbaca dari
# app, scheduler, dan websocket; sesi dihapus saat koneksi ditutup dan
# dibuang WebsocketServer.check_unused_connections kalau idle. Browser yang
# ditinggal terbuka logout sendiri lewat Setting bawaan session_timeout
# (ticket.agent = 2 jam, keputusan user 29 Sep).
class Service::AuxStatus::Presence
  IDLE_SECONDS = 240 # = Sessions.destroy_idle_sessions default

  # @param except_client_id [String, nil] abaikan satu sesi (dipakai event
  #   login untuk tahu apakah ini sesi PERTAMA user tsb)
  # @return [Set<Integer>] id user yang sedang online
  def self.online_user_ids(except_client_id: nil)
    now = Time.now.utc.to_i
    Sessions.list.each_with_object(Set.new) do |(client_id, data), ids|
      next if except_client_id && client_id.to_s == except_client_id.to_s

      user_id = data.dig(:user, :id) || data.dig(:user, 'id')
      next if user_id.blank?
      next if data.dig(:meta, :last_ping).to_i + IDLE_SECONDS < now

      ids << user_id.to_i
    end
  end

  def self.online?(user)
    online_user_ids.include?(user.id)
  end
end
