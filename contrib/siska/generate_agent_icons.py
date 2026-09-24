#!/usr/bin/env python3
# Redesign sisi agent (Tahap 0): generator ikon Phosphor Duotone untuk
# panel chat agent. Sumber path SAMA dengan widget (SISKA_ICONS di
# public/assets/chat/chat-no-jquery.coffee): `selection.json` kit Able Pro
# Tailwind (grid 1024, [lapisan isi 0.2, lapisan garis]).
#
# Pemakaian (tambah nama ikon di ICONS lalu jalankan ulang):
#   python3 contrib/siska/generate_agent_icons.py \
#     /usr/local/src/claudeai/able-pro-tailwind-v1.2.0/src/assets/fonts/phosphor/duotone/selection.json
import json
import os
import sys

ICONS = """
arrow-bend-up-left arrow-down arrow-square-out arrows-left-right calendar
caret-down chat-circle-dots chat-teardrop-dots chats check check-circle checks
clock clock-counter-clockwise copy dots-three-vertical download-simple
envelope-simple file file-audio file-csv file-doc file-image file-pdf file-ppt
file-jpg file-png file-text file-video file-xls file-zip gear-six globe-hemisphere-west headset
heart hourglass image info magnifying-glass paper-plane-right paperclip power
prohibit sign-out smiley spinner-gap ticket tray user user-circle users
warning wifi-slash x x-circle
""".split()

OUT = os.path.join(os.path.dirname(__file__), '..', '..',
                   'app/assets/javascripts/app/lib/app_post/siska_icons.coffee')

HEADER = """\
# FILE HASIL GENERATE -- jangan diedit manual. Sumber & cara menambah ikon:
# contrib/siska/generate_agent_icons.py
#
# Redesign sisi agent (Tahap 0): ikon Phosphor Duotone yang SAMA dengan
# widget (SISKA_ICONS di public/assets/chat/chat-no-jquery.coffee), supaya
# panel agent & widget memakai satu bahasa ikon. SVG inline (bukan sprite
# `icons.svg` bawaan Zammad), karena ikon duotone butuh 2 lapisan path.
#
# Dipakai lewat helper view `@SiskaIcon(name, size, opts)` (lihat
# view_helpers.coffee) atau `App.SiskaIcon.render(...)` di controller.
# tone: 'single' (default, garis saja), 'full' (isi 0.2), 'active' (isi
# lewat class `.siska-icon-fill`, tampil saat state aktif, lihat
# siska_agent_chat.scss).
class App.SiskaIcon
  @PATHS:
"""

FOOTER = """
  @render: (name, size = 16, opts = {}) ->
    paths = @PATHS[name]
    return '' if !paths
    tone = opts.tone || 'single'
    cls = 'siska-icon'
    cls += " #{opts.class}" if opts.class
    fill = ''
    if tone is 'full'
      fill = "<path opacity=\\"0.2\\" d=\\"#{paths[0]}\\"/>"
    else if tone is 'active'
      fill = "<path class=\\"siska-icon-fill\\" d=\\"#{paths[0]}\\"/>"
    "<svg class=\\"#{cls}\\" width=\\"#{size}\\" height=\\"#{size}\\" viewBox=\\"0 0 1024 1024\\" fill=\\"currentColor\\" aria-hidden=\\"true\\" focusable=\\"false\\">#{fill}<path d=\\"#{paths[1]}\\"/></svg>"

  # Ikon & warna per jenis file -- pemetaan SAMA PERSIS dengan
  # SISKA_FILE_ICONS / SISKA_FILE_TONES widget (lihat alasan pemilihan
  # warna berbasis kontras di sana).
  @FILE_TYPES:
    'file-pdf':   'pdf'
    'file-doc':   'doc docx odt rtf'
    'file-xls':   'xls xlsx ods'
    'file-csv':   'csv'
    'file-ppt':   'ppt pptx odp'
    'file-jpg':   'jpg jpeg'
    'file-png':   'png'
    'file-image': 'gif webp bmp heic tif tiff'
    'file-zip':   'zip rar 7z tar gz'
    'file-text':  'txt log md'
    'file-audio': 'mp3 wav ogg m4a'
    'file-video': 'mp4 mov avi webm mkv'

  @FILE_TONES:
    'file-pdf':   'danger'
    'file-doc':   'primary'
    'file-xls':   'success'
    'file-csv':   'success'
    'file-ppt':   'warning'
    'file-jpg':   'primary'
    'file-png':   'primary'
    'file-image': 'primary'

  @fileTone: (filename) ->
    @FILE_TONES[@forFile(filename)] || 'secondary'

  @forFile: (filename) ->
    ext = String(filename || '').split('.').pop().toLowerCase()
    for icon, exts of @FILE_TYPES
      return icon if ext in exts.split(' ')
    'file'
"""


def main():
    data = json.load(open(sys.argv[1]))
    by_name = {i['properties']['name'].replace('-duotone', ''): i for i in data['icons']}
    missing = [n for n in ICONS if n not in by_name]
    if missing:
        sys.exit('ikon tidak ada di selection.json: %s' % ', '.join(missing))
    lines = []
    for name in sorted(ICONS):
        paths = by_name[name]['icon']['paths']
        if len(paths) != 2:
            sys.exit('ikon %s tidak punya tepat 2 lapisan' % name)
        lines.append("    '%s': [%s]" % (name, ', '.join(json.dumps(p) for p in paths)))
    with open(OUT, 'w') as f:
        f.write(HEADER + '\n'.join(lines) + '\n' + FOOTER)
    print('%d ikon -> %s' % (len(ICONS), os.path.normpath(OUT)))


if __name__ == '__main__':
    main()
