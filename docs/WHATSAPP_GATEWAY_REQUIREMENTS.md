# Kebutuhan Konfirmasi — Integrasi Gateway WhatsApp untuk CSAT

**Untuk:** Tim yang maintain gateway WhatsApp SISKA
**Dari:** Tim SISKA Enhancement
**Konteks:** Fitur CSAT native Zammad (lihat [DESIGN_FEEDBACK_RATING.md](DESIGN_FEEDBACK_RATING.md)) perlu kirim pesan survey rating ke customer via WhatsApp setelah tiket closed. Kami sudah punya info parsial dari konfigurasi existing di Zammad, tapi perlu konfirmasi supaya tidak salah kirim ke gateway production.

---

## Yang Sudah Diketahui (dari konfigurasi existing di Zammad)

| Item | Nilai |
|---|---|
| Gateway URL | `http://8.215.68.231:1000/wa/send` |
| Device identifier | `SISKA` |
| Method pengiriman saat ini | Tidak diketahui — kode adapter aslinya (`sms/pkpwa`) sudah tidak ada di source Zammad manapun (kemungkinan hilang saat upgrade versi) |

## Yang Perlu Dikonfirmasi

### 1. Autentikasi
- [ ] Apakah butuh API key/token? Kalau ya, di mana ditaruh — header (`Authorization`, custom header lain), atau field di body?
- [ ] Apakah `device: "SISKA"` itu identifier yang harus dikirim tiap request, atau itu cuma label internal di sisi gateway (auth sepenuhnya dari API key)?

### 2. Format Request
- [ ] Method: `POST` dikonfirmasi (dari config existing), tapi apakah body-nya `JSON`, `form-urlencoded`, atau `multipart`?
- [ ] Nama field untuk **nomor tujuan** (`to`, `phone`, `target`, `number`, dll?)
- [ ] Format nomor tujuan — pakai `62xxx`, `+62xxx`, atau `08xxx`?
- [ ] Nama field untuk **isi pesan** (`message`, `text`, `body`, dll?)
- [ ] Apakah field `device` wajib disertakan di tiap request body, atau cuma untuk keperluan lain?

### 3. Response
- [ ] Format response sukses (JSON? Field apa yang menandakan berhasil?)
- [ ] Format response gagal — HTTP status code apa (400? 401? 422?), dan bagaimana pesan error-nya?
- [ ] Apakah ada rate limit yang perlu kami tahu (request per detik/menit)?

### 4. Konteks Tambahan
- [ ] Apakah gateway ini masih aktif digunakan untuk keperluan lain di production saat ini? (Kalau ya, kami perlu extra hati-hati saat testing supaya tidak mengganggu penggunaan lain.)
- [ ] Apakah ada dokumentasi API resmi (Postman collection, Swagger, atau sekadar contoh `curl`) yang bisa dibagikan?
- [ ] Apakah ada environment/nomor **test** terpisah dari production yang bisa kami pakai untuk uji coba tanpa risiko ke nomor customer asli?

---

## Contoh Format Jawaban (silakan isi/koreksi)

```
Auth: Bearer token di header "Authorization"
Method: POST, Content-Type: application/json
Body:
{
  "device": "SISKA",
  "phone": "62812xxxxxxx",
  "message": "isi pesan di sini"
}

Response sukses (200):
{ "status": "success", "message_id": "..." }

Response gagal (4xx):
{ "status": "error", "reason": "..." }

Nomor test: 628xx-xxxx-xxxx (aman untuk dipakai coba-coba)
```

---

## Kenapa Ini Penting

Sampai poin-poin di atas dikonfirmasi, jalur pengiriman WhatsApp untuk CSAT **belum akan diaktifkan** di sisi kami (Email & Telegram bisa jalan lebih dulu secara terpisah, karena keduanya tidak bergantung ke gateway ini). Kami tidak ingin menebak-nebak format request ke gateway production tanpa konfirmasi, untuk menghindari resiko salah kirim atau mengganggu penggunaan gateway yang sudah ada.
