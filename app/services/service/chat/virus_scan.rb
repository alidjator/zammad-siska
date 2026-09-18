# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 5 -- Item No. 6 (Live Chat Enhancement, Attachment). See
# docs/DESIGN_LIVE_CHAT_ENHANCEMENT.md Section 5.2.5. Pemindaian
# ClamAV OPSIONAL & plug-and-play -- kalau `chat_attachment_clamav_host`
# kosong (default), .scan selalu balas :skipped tanpa mencoba koneksi
# apa pun, jadi tidak ada dampak performa/perilaku sama sekali sampai
# admin benar-benar mengisi Setting itu.
#
# Sengaja implementasi protokol INSTREAM ClamAV langsung lewat
# TCPSocket, bukan gem tambahan (clamby dst) atau shell out ke binary
# clamdscan -- container app ini tidak (dan tidak perlu) menginstal
# apa pun terkait ClamAV, cukup bisa menjangkau host:port clamd lewat
# jaringan.
module Service::Chat::VirusScan
  CHUNK_SIZE = 8192

  # Return: :skipped (belum dikonfigurasi), :clean, :infected,
  # :unavailable (dikonfigurasi tapi clamd tidak bisa dihubungi/error).
  def self.scan(data)
    host = Setting.get('chat_attachment_clamav_host')
    return :skipped if host.blank?

    port = Setting.get('chat_attachment_clamav_port').presence || 3310

    socket = nil
    begin
      socket = TCPSocket.new(host, port.to_i)
      socket.write("zINSTREAM\0")

      data.each_char.each_slice(CHUNK_SIZE) do |chunk_chars|
        chunk = chunk_chars.join
        socket.write([chunk.bytesize].pack('N'))
        socket.write(chunk)
      end
      socket.write([0].pack('N'))

      response = socket.gets

      return :infected if response&.include?('FOUND')
      return :clean if response&.include?('OK')

      :unavailable
    rescue => e
      Rails.logger.error "Service::Chat::VirusScan gagal menghubungi ClamAV (#{host}:#{port}): #{e.message}"
      :unavailable
    ensure
      socket&.close
    end
  end
end
