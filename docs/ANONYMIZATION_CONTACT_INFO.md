# Anonimisasi Kontak User Non-Admin — Staging

**Tanggal eksekusi:** 2026-09-17 01:02 UTC
**Dijalankan oleh:** User (manual, lewat `docker exec`, karena eksekusi tulis massal diblokir untuk Claude oleh auto-mode classifier)
**Skrip:** [`script/anonymize_non_admin_contacts.rb`](../script/anonymize_non_admin_contacts.rb)
**Server:** `zammad-staging-zammad-app-1` (Koi-Server-Dev)

> ⚠️ **Catatan penting soal isi dokumen ini:** semua contoh "Sebelum" di bawah **sengaja disamarkan sebagian (masked)**, bukan nilai asli utuh — supaya dokumen ini (yang akan di-commit ke git) tidak justru menyimpan PII asli secara permanen di riwayat repo. Nilai asli lengkap (untuk keperluan pemulihan darurat) hanya ada di file backup lokal di server, **tidak pernah di-commit ke git** — lihat Section "Backup" di bawah.

## Latar Belakang

Ada komplain email hasil aktivitas testing di server staging ini "nyasar" ke customer asli — ditemukan bahwa database staging (`zammad-staging-zammad-app-1`, 72.032 user) adalah **salinan penuh data production**, termasuk koneksi SMTP outbound yang hidup, bukan data dummy. Untuk mencegah kebocoran lebih lanjut, seluruh kontak (email, login, telepon, HP) user non-admin diacak permanen di database staging.

## Scope

**Yang diubah:** kolom `users.email`, `users.login` (disinkronkan ke nilai baru yang sama), `users.phone`, `users.mobile`.

**Semua user KECUALI:**
- Role **Admin**
- User id `1` (akun sistem internal Zammad, login `-`)
- Domain **`@pkp.co.id`** (staf internal PKP, termasuk akun operator proyek ini sendiri dan akun service `integration-kpi-api@pkp.co.id` yang sudah didokumentasikan & dipakai integrasi eksternal — lihat `docs/DESIGN_TEAM_KPI_DASHBOARD.md`)

**phone/mobile** hanya ditimpa kalau nilai aslinya memang terisi (tidak null/kosong) — tidak memalsukan kontak yang memang tidak pernah ada.

**Total baris ter-update: 72.017** (dari 72.032 total user, dikurangi 3 Admin + 1 sistem + ~11 akun `@pkp.co.id`).

**Di luar scope (belum diproses, sengaja ditunda):** identitas **Telegram** — tidak ditemukan kolom per-user yang stabil untuk ini (kemungkinan besar cuma tersimpan di `ticket_articles.preferences` per pesan, bukan per-user), butuh investigasi terpisah sebelum diputuskan aman diubah atau tidak.

## Format Transformasi

| Field | Pola baru | Contoh |
|---|---|---|
| `email` / `login` (disinkronkan) | `anon-<id>-<10 hex acak>@anon.invalid` | `anon-51-605c3cce09@anon.invalid` |
| `phone` / `mobile` (kalau aslinya terisi) | `id` di-zero-pad jadi 16 digit | `0000000000000051` |

- Domain `.invalid` adalah TLD yang **sengaja direservasi IETF (RFC 2606)** supaya dijamin tidak akan pernah bisa di-resolve/dikirimi email — jadi walau nilai bocor, tidak akan pernah sampai ke mana pun.
- Prefix `<id>` pada email menjamin keunikan global (kolom `login` punya unique index), terlepas dari kemungkinan tabrakan bagian acaknya.
- phone/mobile sengaja **bukan pola nomor telepon** (bukan diawali `08`/format wajar) — permintaan eksplisit supaya tidak ada yang salah kira ini nomor asli yang bisa dihubungi/di-WhatsApp.
- Dieksekusi lewat **SQL mentah** (bukan lewat model `User` Rails) — sengaja melewati semua callback/observer Zammad, supaya **tidak ada satu pun notifikasi** yang terpicu ke siapa pun selama proses ini.

## Contoh Nyata (5 baris sampel, before di-mask)

| id | Email (sebelum, di-mask) | Email/Login (sesudah) | Phone (sebelum, di-mask) | Phone/Mobile (sesudah) |
|---|---|---|---|---|
| 2 | `im***n@agriaku.com` | `anon-2-f9dd9d8a3f@anon.invalid` | *(kosong, tidak diubah)* | *(kosong, tidak diubah)* |
| 5 | `vi***a@andalanfinance.co.id` | `anon-5-09189ce56d@anon.invalid` | *(kosong, tidak diubah)* | *(kosong, tidak diubah)* |
| 51 | `gu***a@yahoo.co.id` | `anon-51-605c3cce09@anon.invalid` | `0899***1722` | `0000000000000051` |
| 52 | `is***l@seid.sharpworld.com` | `anon-52-9b2d3031c3@anon.invalid` | `0812***7171` (phone), `0878***1000` (mobile) | `0000000000000052` |
| 4325 | `co***t@nct-cargo.com` | `anon-4325-d1d15c2841@anon.invalid` | *(kosong, tidak diubah)* | *(kosong, tidak diubah)* |

Semua nilai "sesudah" di atas adalah **data live** dari database staging saat dokumen ini ditulis (`updated_at = 2026-09-17 01:02:19 UTC` untuk seluruh 72.017 baris, seragam karena satu transaksi UPDATE).

## Backup (untuk Pemulihan Darurat — TIDAK Ikut ke Git)

Sebelum eksekusi, skrip otomatis menyimpan nilai LAMA (`id`, `email`, `login`, `phone`, `mobile`) seluruh 72.017 baris terdampak ke file JSONL. File ini awalnya sempat berada di `/tmp` dalam container `zammad-staging-zammad-app-1` (lokasi yang bisa hilang kalau container di-recreate), lalu **sudah dipindahkan** (2026-09-17, checksum SHA-256 diverifikasi cocok sebelum salinan lama dihapus) ke penyimpanan permanen di host:

```
/usr/local/src/claudeai/backups/anonymize_contacts_backup_20260917_010218.jsonl   (host, di luar container & di luar repo git)
```

File ini **berisi PII asli** — sengaja **tidak dipindahkan ke repo/git**. Selain itu, ada juga `anonymization_before_after.xlsx` (nilai before/after real, 72.017 baris, format lebih mudah dibaca daripada JSONL mentah) di lokasi host yang sama: `/usr/local/src/claudeai/anonymization_before_after.xlsx`.

## Verifikasi

- Jumlah baris ter-update sesuai ekspektasi: **72.017** (cocok persis dengan hasil dry-run sebelum eksekusi)
- Tidak ada duplikat `login` setelah update (diverifikasi lewat query terpisah sebelum eksekusi sungguhan)
- Akun operator (`jajat.sudrajat@pkp.co.id`), staf internal PKP lainnya, dan akun service `integration-kpi-api@pkp.co.id` **tidak tersentuh** (dikecualikan lewat domain `@pkp.co.id`)
