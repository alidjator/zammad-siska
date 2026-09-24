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
