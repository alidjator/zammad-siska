# Development Workflow — Zammad SISKA

## 1. Branching Strategy

- **`main`** — baseline stabil. Setiap commit di sini harus merupakan kode yang sudah lolos test dan siap/sudah di-deploy ke staging.
- **`feature/<no>-<slug>`** — satu branch per item gap analysis, dibuat dari `main`:
  - `feature/01-aux-status`
  - `feature/03-12-eskalasi-sla` (item 3 & 12 digabung karena sama-sama soal state Eskalasi + SLA)
  - `feature/07-reporting`
  - `feature/08-dashboard`
  - `feature/05-chat-auto-ticket`
  - `feature/06-chat-attachment`
- **Merge ke `main`** lewat Pull Request setelah:
  - Test suite Zammad (`bundle exec rspec`, atau subset relevan) lolos.
  - Review manual (minimal 1 reviewer bila tim >1 orang).
- **Tagging** — setelah satu batch item selesai dan di-deploy ke staging, tag `main` (mis. `v7.1.3-siska.1`, `.2`, dst) sebagai titik rollback.
- **Upstream tracking (opsional, untuk upgrade Zammad berikutnya)** — tambahkan remote terpisah:
  ```bash
  git remote add upstream https://github.com/zammad/zammad.git
  git fetch upstream --tags
  ```
  Lakukan upgrade version di branch khusus (`upgrade/7.2.0`) terpisah dari branch fitur, supaya proses merge/rebase custom code tidak bercampur dengan pekerjaan fitur yang sedang berjalan.

## 2. Build & Deploy Flow

Berdasarkan setup aktual di `/usr/local/src/zammad-staging/` (Dockerfile + docker-compose.yml):

- 3 service (`zammad-app`, `zammad-websocket`, `zammad-scheduler`) semuanya di-build dari image yang sama: `zammad-staging-app:7.1.3`, dari `Dockerfile` yang sama, context `COPY app/ /opt/zammad`.
- Artinya: **rebuild sekali, restart ketiga service-nya** — image yang sama dipakai bertiga.

### Langkah deploy ke staging

```bash
# 1. Di direktori source (perlu akses root, karena folder ini dimiliki root)
cd /usr/local/src/zammad-staging

# 2. Pastikan app/ berisi source hasil merge branch fitur terbaru dari main
#    (lihat catatan "Gap Saat Ini" di bawah)

# 3. Backup image lama untuk rollback cepat
docker tag zammad-staging-app:7.1.3 zammad-staging-app:7.1.3-prev

# 4. Build ulang image
docker compose build zammad-app

# 5. Recreate ketiga container yang pakai image ini
docker compose up -d zammad-app zammad-websocket zammad-scheduler

# 6. Smoke test
docker compose logs -f zammad-app        # pastikan rails server start tanpa error
curl -I http://127.0.0.1:3010            # cek response
```

### Rollback cepat

```bash
docker tag zammad-staging-app:7.1.3-prev zammad-staging-app:7.1.3
docker compose up -d zammad-app zammad-websocket zammad-scheduler
```

## 3. Status Repoint Remote (Selesai)

`/usr/local/src/zammad-staging/app` sudah di-repoint ke `git@github.com:alidjator/zammad-siska.git`, branch `main` tracking `origin/main`, memakai deploy key yang sama (disalin ke `/root/.ssh/`). Catatan: karena repo lama adalah shallow clone (`--branch 7.1.3 --depth 1`), `remote.origin.fetch` sempat perlu direset ke `+refs/heads/*:refs/remotes/origin/*` (default) sebelum `git fetch origin` bisa menemukan branch `main` di repo baru.

Alur `git pull` di folder ini sekarang sudah bisa dipakai sesuai langkah deploy di atas.
