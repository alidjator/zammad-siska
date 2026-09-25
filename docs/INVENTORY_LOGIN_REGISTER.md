# Inventaris Halaman Login & Register SISKA (sebelum redesign)

Disusun 2026-09-25, **sebelum** redesign dimulai, atas permintaan user
("redesign halaman login dan register siska, lakukan inventarisir dulu
... pada login dan register saya mau ditambahkan otp").

- **Baseline:** commit `a81e10e8` (Zammad 7.1.3). Semua berkas di bawah
  **belum pernah diubah** untuk SISKA.
- **Cakupan:** aplikasi desktop lama (CoffeeScript/eco) yang dipakai di
  `https://helpdesk.satu.solutions/#login`, `#signup`, `#password_reset`,
  `#email_verify/:token`.
- **Di luar cakupan:** aplikasi Vue baru (`/mobile/login`, `/desktop/login`,
  `app/frontend/apps/*/pages/authentication`). `ui_desktop_beta_switch`
  = false, jadi versi desktop Vue tidak dipakai. Link "Continue to mobile"
  hanya muncul di perangkat mobile.

Legenda: ✅ dipertahankan · 🔄 berubah · ➕ baru · ❓ perlu keputusan

---

## 1. Berkas yang terlibat

| Bagian | Berkas |
|---|---|
| Login (controller) | `app/assets/javascripts/app/controllers/login.coffee` |
| Login (view) | `app/assets/javascripts/app/views/login.jst.eco` |
| 2FA saat login | `controllers/widget/two_factor_login/*`, `views/widget/two_factor_login/*`, `lib/app_post/two_factor_methods/*` |
| Register | `controllers/signup.coffee`, `views/signup.jst.eco`, `views/signup/verify.jst.eco` |
| Verifikasi email (link) | `controllers/email_verify.coffee`, `UsersController#email_verify`, `Service::User::SignupVerify` |
| Lupa password | `controllers/password_reset.coffee`, `password_reset_verify.coffee`, `views/password/*` |
| Login admin (token) | `controllers/admin_password_auth.coffee` |
| Server login | `SessionsController`, `lib/auth.rb`, `lib/auth/backend/internal.rb`, `lib/auth/two_factor*` |
| Server signup | `UsersController#create_signup` → `Service::User::Deprecated::Signup` |
| Gaya | `app/assets/stylesheets/zammad.scss` (`.login`, `.signup`, `.fullscreen`, `.hero-unit`, `.poweredBy`) |

## 2. Setting yang aktif di staging

| Setting | Nilai | Pengaruh |
|---|---|---|
| `product_name` | SISKA (SIM Solusi Kebutuhan Anda) | Judul "Join %s" di register |
| `fqdn` | helpdesk.satu.solutions | Judul "Log in to %s" di login |
| `product_logo` | ada (custom) | Logo di kartu login |
| `user_create_account` | true | Link "Register as a new customer" + halaman `#signup` |
| `user_lost_password` | true | Link "Forgot password?" |
| `user_show_password_login` | true | Form username/password tampil |
| Provider pihak ketiga (`auth_*`) | tidak ada yang aktif | Blok "or sign in using" tidak tampil |
| 2FA authenticator app / security keys | **nonaktif** | Langkah 2FA tidak pernah muncul |
| `two_factor_authentication_enforce_role_ids` | [2] | Tidak berefek karena semua metode nonaktif |
| `password_min_size` | 6 | Kebijakan password |
| `password_need_digit` | true | Password wajib ada angka |
| `password_min_2_lower_2_upper_characters` / `password_need_special_character` | false / false | |
| `password_max_login_failed` | 10 | Akun terkunci setelah 10x gagal |
| Public links (screen login/signup) | kosong | |
| Pengguna customer | ±71.214 | Mayoritas pengguna login adalah customer |

## 3. Halaman Login (`#login`)

| # | Elemen / perilaku sekarang | Status | Catatan |
|---|---|---|---|
| 3.1 | Judul "Log in to helpdesk.satu.solutions" di atas kartu | 🔄 | Diganti judul yang lebih manusiawi ("Masuk ke SISKA") |
| 3.2 | Banner maintenance mode & pesan maintenance login | ✅ | Wajib dipertahankan |
| 3.3 | Logo produk di dalam kartu | ✅ | |
| 3.4 | Field "Username / email" (teks bebas, autocapitalize off) | ✅ | Tetap menerima login atau email |
| 3.5 | Field "Password" | 🔄 | Ditambah tombol tampilkan/sembunyikan |
| 3.6 | Checkbox "Remember me" | ✅ | |
| 3.7 | Tombol "Sign in" + link "Forgot password?" | ✅ | |
| 3.8 | Pesan error di atas form + animasi "shake" kartu | ✅ | |
| 3.9 | Pesan session timeout / session invalid (`#session_timeout`, `#session_invalid`) | ✅ | |
| 3.10 | Blok provider pihak ketiga ("or sign in using") | ✅ | Tidak aktif di staging, tetap didukung |
| 3.11 | Login admin lewat token (`#login/admin/:token`) saat password login dimatikan | ✅ | |
| 3.12 | Langkah 2FA (authenticator/security key/recovery code, "try another method") | ✅ | Mekanismenya dipakai ulang untuk OTP email |
| 3.13 | Teks footer "You're already registered ... request your password here" | 🔄 | Diringkas |
| 3.14 | Link "Register as a new customer" + public links | 🔄 | Jadi "Belum punya akun? Daftar" di bawah tombol |
| 3.15 | Link "Continue to mobile" (hanya di mobile) | ✅ | |
| 3.16 | Footer "Powered by Zammad" | 🔄 | Diganti branding SISKA (K5) |
| 3.17 | Re-render otomatis saat setting login berubah (`config_update_local`) | ✅ | |
| 3.18 | **OTP email setelah password benar** | ➕ | Lihat §6 |

## 4. Halaman Register (`#signup`)

| # | Elemen / perilaku sekarang | Status | Catatan |
|---|---|---|---|
| 4.1 | Judul "Join SISKA (SIM Solusi Kebutuhan Anda)" | 🔄 | |
| 4.2 | Form dibangun otomatis dari atribut User screen `signup`: First name, Last name (opsional), Email (wajib), Password (wajib) | 🔄 | Tata letak kit: nama depan + belakang sebaris |
| 4.3 | Atribut custom `position`, `cabang`, `tm` punya screen signup tapi `shown: false` | ✅ | Tetap tidak tampil (server juga hanya menerima firstname/lastname/email/password) |
| 4.4 | Validasi kebijakan password dari server (min 6, wajib angka) | 🔄 | Ditampilkan sebagai checklist langsung saat mengetik |
| 4.5 | Field "Password (confirm)" otomatis dari form generik (`attribute.single` false) | ✅ | Dipertahankan sebagai "Confirm password" |
| 4.6 | Tombol "Cancel & Go Back" + "Create my account" | 🔄 | Jadi 1 tombol utama + link "Sudah punya akun? Masuk" |
| 4.7 | Sukses → halaman "Registration successful! ... click on the link in the verification email" + tombol "Resend verification email" | 🔄 | **Diganti OTP 6 digit** (lihat §6) |
| 4.8 | Verifikasi lewat link `#email_verify/:token` | ✅ | Tetap dikirim sebagai cadangan di samping kode (K3) |
| 4.9 | Akun signup yang belum terverifikasi **tidak bisa login** (`auth/backend/internal.rb:24`) | ✅ | Aturan dipertahankan; OTP register yang memverifikasi |
| 4.10 | Email sudah terdaftar → server tetap membalas sukses (tidak membocorkan) | ✅ | Wajib dipertahankan untuk OTP juga |

## 5. Halaman terkait yang ikut terlihat

| # | Halaman | Status | Catatan |
|---|---|---|---|
| 5.1 | Lupa password (`#password_reset`, `reset_sent`, `reset_change`, `reset_failed`) | 🔄 | Redesign + OTP (K4) |
| 5.2 | Request login admin (`#admin_password_auth`) | ✅ | Hanya gaya |

## 6. Usulan OTP

**Register**
1. Isi form → server membuat akun (belum terverifikasi) dan mengirim kode
   6 digit ke email.
2. Layar "Masukkan kode verifikasi" (6 kotak, tempel otomatis, kirim ulang
   dengan jeda 30 detik, berlaku 5 menit, maks. 5 percobaan — sama dengan
   OTP pesan offline di widget).
3. Kode benar → akun terverifikasi dan langsung masuk.

**Login**
1. Username/email + password benar → server mengirim kode 6 digit ke email
   akun, layar kode OTP tampil (password tidak disimpan di browser lebih
   lama dari yang diperlukan).
2. Kode benar → sesi dibuat.
3. Diimplementasikan sebagai **metode 2FA baru "Email OTP"** di kerangka
   2FA Zammad yang sudah ada (`lib/auth/two_factor/authentication_method/`),
   jadi recovery code, "try another method", dan penegakan per role ikut
   berfungsi.

**Keputusan (2026-09-25)**

| # | Pertanyaan | Keputusan |
|---|---|---|
| K1 | OTP login berlaku untuk siapa | **Semua pengguna**, lewat setting on/off baru, **default off** |
| K2 | "Don't ask again on this device for 30 days" | **Ya, 30 hari** |
| K3 | Isi email verifikasi register | **Kode 6 digit + link verifikasi lama sebagai cadangan** |
| K4 | Halaman lupa password | **Redesign + OTP**: email → kode → password baru → langsung masuk |
| K5 | Footer "Powered by Zammad" | Diganti "© SISKA · helpdesk.satu.solutions" (sesuai mockup) |
| K6 | Layout | Kit Able Pro **Authentication v2** + ilustrasi customer service SISKA di kiri |

Mockup: canvas "SISKA Login & Register" (login, register, lupa password;
masing-masing sekarang vs usulan).
