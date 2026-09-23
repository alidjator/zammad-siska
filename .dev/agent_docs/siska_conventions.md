# SISKA Project Conventions

Aturan operasional khusus proyek SISKA (kustomisasi live chat widget di atas
Zammad ini), disepakati/ditemukan sepanjang sesi kerja dan dicatat di sini
supaya tidak perlu digali ulang dari `docs/ACTIVITY_LOG_SISKA.md` tiap sesi
baru. Baca file ini sebelum mengerjakan apa pun di area SISKA (live chat
widget, `docs/TASKLIST_SISKA.md`, `docs/ACTIVITY_LOG_SISKA.md`).

Status "SUSPENDED" berarti aturan tersebut dijeda, bukan dicabut — jangan
diterapkan proaktif sampai user eksplisit minta dilanjutkan kembali.

## Instruksi standing

- **Testing dengan Playwright — SUSPENDED (sejak 2026-09-20).** Jangan
  jalankan Playwright untuk kerja SISKA sampai user minta dilanjutkan.
  Verifikasi pakai `curl` / `rails runner` / koneksi WebSocket mentah
  langsung ke server sebagai gantinya.
- **Logging ke `TASKLIST_SISKA.md`/`ACTIVITY_LOG_SISKA.md` — SUSPENDED
  (sejak 2026-09-21).** Hanya catat progres di kedua file itu kalau user
  eksplisit minta, jangan proaktif.
- **Dokumentasi lokasi tiap Setting — SUSPENDED (sejak 2026-09-22).**
  Sebelumnya: setiap Setting baru wajib didokumentasikan persis di mana cara
  mengubahnya (Admin UI kalau genuinely reachable, atau `rails runner`/
  console kalau tidak). Dijeda, tidak diterapkan proaktif sampai diminta lagi.
- **Varian widget jQuery dihentikan total (sejak 2026-09-22).**
  `chat.coffee` (dan bundle `chat.js`/`chat.min.js` hasil build-nya) tidak
  lagi dikerjakan/di-maintain. Semua perbaikan, fitur, dan perubahan style ke
  depan HANYA ditulis di `chat-no-jquery.coffee` + `views/*.eco`/`chat.scss`
  yang dipakai bersama. Jangan mirror perubahan ke `chat.coffee` lagi kecuali
  user eksplisit minta dihidupkan kembali.
- Tiket uji selalu dibuat di grup **"QA - Internal Testing"** (id 89), tidak
  pernah ke grup produksi — supaya tidak mengirim notifikasi email ke staf
  sungguhan.
- Mockup/frontend wajib merujuk ke starter kit Able Pro asli di
  `/usr/local/src/claudeai/able-pro-tailwind-v1.2.0` (kit **Tailwind**,
  BUKAN lagi kit Vue/Vuetify v1.7.0 lama — referensi dipindah 2026-09-23),
  bukan dari ingatan/tebakan.
- Kerjakan tugas langsung sendiri — jangan delegasikan ke Agent/Workflow
  tool (subagent paralel), untuk jenis tugas apa pun.
- Balas ke user dalam Bahasa Indonesia.

## Disiplin deploy & build

- **Kerja SISKA (widget maupun backend) SELALU langsung di repo asli
  `/usr/local/src/zammad-staging/app` — JANGAN di clone/scratchpad
  manapun di `/tmp/...`.** Insiden 2026-09-23: satu sesi penuh (redesign
  kit Tailwind layar Messages) dikerjakan + `npx gulp build` di scratchpad
  clone yang ternyata sudah lama diverged dari live (histori commit beda,
  `origin/main` lokalnya ketinggalan berhari-hari) — baru ketahuan setelah
  user screenshot widget live yang sama sekali tidak berubah walau sudah
  "selesai di-deploy". Edit, `npx gulp build`, DAN `docker cp` semuanya
  wajib dari path repo asli ini, supaya git history & container yang
  dideploy selalu dari sumber yang SAMA. Scratchpad (`/tmp/.../scratchpad/`)
  hanya boleh dipakai utk file benar2 sementara/di luar repo (mis. mockup
  Artifact `.dc.html`), tidak pernah utk kode widget/backend.
- Ubah `.coffee`/`.eco` widget → wajib `npx gulp build` ulang (dijalankan
  dari `public/assets/chat/`, BUKAN root repo) sebelum deploy. File `.eco`
  dikompilasi ke dalam bundle JS saat build time (`gulp-eco`), tidak dibaca
  langsung dari disk saat runtime.
- **Deploy widget = HANYA `chat-no-jquery.min.js`** (+ `chat.css` dan
  `.eco` yang disentuh, kalau relevan) — sejak varian jQuery dihentikan,
  tidak perlu lagi deploy `chat.js`/`chat.min.js`/`chat-no-jquery.js` mentah.
  Tetap verifikasi lewat `curl` langsung ke `.min.js` yang di-deploy, karena
  itu yang genuinely dimuat halaman produksi/uji.
- Perubahan `app/controllers/*.rb`, `app/models/*.rb`,
  `config/environments/*.rb` → wajib **restart container** `zammad-app`
  (`config.eager_load = true` di production, class lama tidak auto-reload).
- Perubahan apa pun di jalur **WebSocket** (`lib/sessions/event/*`, model
  yang dipanggil dari situ) → wajib deploy **+ restart KEDUA container**:
  `zammad-app` DAN `zammad-websocket`. Dua proses Ruby terpisah, tidak
  share filesystem, tidak auto-reload — sumber bug berulang di proyek ini.
- File bagian asset pipeline Rails (Sprockets, `config.assets.compile =
  false` di production) → `docker cp` → `bin/rails assets:precompile` →
  restart `zammad-app`. Beda dari widget statis (`public/assets/chat/`)
  yang cukup `docker cp` tanpa precompile.
- Jangan percaya "`gulp build` bersih" begitu saja sebagai bukti file
  benar-benar tertulis ulang — cek `ls -la` kepemilikan/timestamp file hasil
  build. `gulp` bisa melaporkan "Finished" sukses padahal gagal menulis
  (`EACCES` muncul async belakangan).
- Sebelum menambah blok CSS baru ke `chat.scss` (file besar, >1300 baris)
  — wajib `grep` selector yang sama dulu, supaya tidak membuat duplikat
  yang diam-diam menimpa lewat urutan baris di source.

## Konsistensi data

- Field baru yang ditambahkan ke payload **real-time** (mis. `sendMessage`)
  wajib dicek juga apakah jalur **riwayat/reconnect** (bulk load,
  `onReopenSession`) butuh pembaruan yang sama — dua jalur ini genuinely
  terpisah kodenya, sudah berkali-kali jadi sumber bug kalau salah satu
  kelupaan diupdate.
- Data uji (tiket, artikel Knowledge Base, dll) selalu diisolasi dari data
  produksi asli — pola sama dengan grup tiket QA: kategori KB test terpisah
  ("QA - Testing Widget"), tidak dicampur ke kategori produksi asli.

## Operasional

- **Commit ke git menunggu konfirmasi eksplisit user** — jangan commit
  otomatis di akhir setiap task, tunggu diminta.
- `chat_auto_ticket_group_id` (Setting) masih mengarah ke grup testing —
  wajib diarahkan ke grup produksi sungguhan sebelum go-live ke customer
  asli.
