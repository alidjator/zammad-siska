# Redesign sisi agent -- helper format kecil yang dipakai bersama oleh
# App.CustomerChat (kartu daftar) dan App.ChatWindow (bubble, viewer).
class App.SiskaFormat
  @initials: (name) ->
    words = _.compact(String(name || '').trim().split(/\s+/))
    return '?' if !words.length
    return words[0].substr(0, 2).toUpperCase() if words.length is 1
    (words[0][0] + words[words.length - 1][0]).toUpperCase()

  # HH:MM untuk hari ini, tanggal untuk hari lain.
  @time: (time) ->
    return '' if !time
    date = new Date(time)
    return '' if isNaN(date.getTime())
    if date.toDateString() is new Date().toDateString()
      pad = (n) -> if n < 10 then "0#{n}" else "#{n}"
      return "#{pad(date.getHours())}:#{pad(date.getMinutes())}"
    App.i18n.translateDate(time)

  # Selalu HH:MM (dipakai di bubble riwayat, tanggalnya sudah ada di pil).
  @clock: (time) ->
    return '' if !time
    date = new Date(time)
    return '' if isNaN(date.getTime())
    pad = (n) -> if n < 10 then "0#{n}" else "#{n}"
    "#{pad(date.getHours())}:#{pad(date.getMinutes())}"

  # Label pil tanggal: "Today" untuk hari ini, selain itu tanggal lokal.
  # Atas permintaan user ("grouping nya seperti ini, today, yesterday,
  # nama hari, dan seterusnya seperti pada whatsapp"): hari ini ->
  # "Today", kemarin -> "Yesterday", 2-6 hari lalu -> NAMA HARI, lebih
  # lama -> tanggal. Aturan yang SAMA ada di `historyDateLabel` widget
  # (chat-no-jquery.coffee), supaya kedua sisi seragam.
  @dayLabel: (time) ->
    date = if time instanceof Date then time else new Date(time)
    return '' if isNaN(date.getTime())
    # Selisih HARI KALENDER (bukan 24 jam): pesan jam 23:50 kemarin &
    # jam 00:10 hari ini tetap beda hari.
    midnight = (d) -> new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()
    days = Math.round((midnight(new Date()) - midnight(date)) / 86400000)
    return App.i18n.translatePlain('Today') if days is 0
    return App.i18n.translatePlain('Yesterday') if days is 1
    if days > 1 and days < 7
      weekday = @weekdayName(date)
      return weekday if weekday
    App.i18n.translateDate(date.toISOString())

  # Nama hari dilokalkan browser (id -> "Senin"), bukan lewat katalog
  # terjemahan: daftar nama hari sudah disediakan Intl.
  @weekdayName: (date) ->
    try
      date.toLocaleDateString(App.i18n.get() || undefined, weekday: 'long')
    catch
      ''

  @fileSize: (bytes) ->
    bytes = parseInt(bytes, 10)
    return '' if isNaN(bytes)
    return "#{bytes} B" if bytes < 1024
    return "#{Math.round(bytes / 1024)} KB" if bytes < 1024 * 1024
    "#{(bytes / (1024 * 1024)).toFixed(1)} MB"

  # "XLSX · 24 KB"
  @fileMeta: (filename, size) ->
    ext = String(filename || '').split('.')
    ext = if ext.length > 1 then ext.pop().toUpperCase() else ''
    _.compact([ext, @fileSize(size)]).join(' · ')

  # Label reaksi, whitelist SAMA dgn backend
  # (Sessions::Event::ChatSessionReaction::ALLOWED_REACTIONS) & widget.
  @REACTIONS:
    '😀': 'Grinning'
    '😊': 'Smile'
    '🙏': 'Thanks'
    '👍': 'Thumbs up'
    '❤️': 'Heart'

  # Set emoji pemilih di area ketik, SAMA dgn widget (views/emoji_picker.eco).
  @EMOJI: [
    ['😀', 'Grinning'], ['😂', 'Joy'], ['😍', 'Heart eyes'], ['😊', 'Smile']
    ['🙏', 'Thanks'], ['👍', 'Thumbs up'], ['👋', 'Wave'], ['❤️', 'Heart']
    ['😢', 'Sad'], ['😮', 'Surprised'], ['🎉', 'Party'], ['🔥', 'Fire']
    ['✅', 'Check'], ['💡', 'Idea'], ['🤔', 'Thinking'], ['👌', 'OK']
    ['🙌', 'Raised hands'], ['😎', 'Cool']
  ]

  # Tipe yang boleh tampil sebagai gambar -- SAMA dgn
  # ChatAttachmentsController::IMAGE_TYPES (server hanya menyajikan inline
  # untuk tipe ini).
  @IMAGE_TYPES: ['image/jpeg', 'image/png', 'image/gif', 'image/webp']

  @isImage: (message) ->
    return false if message.display is 'file'
    _.contains(@IMAGE_TYPES, message.content_type)
