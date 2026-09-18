# Copyright (C) 2012-2026 Zammad Foundation, https://zammad-foundation.org/

# Fase 4 -- Item No. 1 (AUX Status + Auto-distribusi Tiket). See
# docs/DESIGN_AUX_STATUS.md Section 5.7. Both actions are thin wrappers
# around Service::AuxStatus::ChangeStatus, which does the actual
# self-or-override authorization check -- Exceptions::Forbidden /
# Exceptions::UnprocessableContent it raises are already handled
# globally by ApplicationController::HandlesErrors, no local rescue
# needed here.
class AuxStatusesController < ApplicationController
  prepend_before_action :authentication_check

  # GET /api/v1/aux_statuses?query=...
  # Daftar agent (dicari lewat `query`) + status AUX-nya saat ini --
  # dipakai layar Admin > Manage > AUX Status (override) di
  # app/assets/javascripts/app/controllers/_manage/aux_status.coffee.
  # Sengaja butuh permission 'aux_status.override' juga di sini (bukan
  # cuma 'ticket.agent') -- agent biasa tidak perlu bisa melihat status
  # SELURUH agent lain, cuma yang punya hak override yang butuh daftar
  # ini.
  #
  # `query` WAJIB diisi -- kalau kosong langsung return array kosong
  # TANPA menyentuh tabel `users` sama sekali. Ini disengaja: organisasi
  # ini punya 513 akun ber-permission ticket.agent (lihat
  # docs/DESIGN_AUX_STATUS.md Section 6b), dan halaman ini search-first,
  # bukan tampilkan-semua-lalu-paginate, per permintaan user.
  #
  # Server-side pagination (docs/DESIGN_REPORTING_FRT.md Section 8):
  # `page`/`per_page` menentukan baris mana yang dikirim lewat SQL
  # LIMIT/OFFSET langsung -- BUKAN mengambil sejumlah baris lalu
  # memfilter/memotongnya di Ruby.
  #
  # BUG YANG SUDAH DIPERBAIKI: versi sebelumnya mengambil 100 baris
  # ter-ILIKE-match dulu (CANDIDATE_WINDOW) baru memfilter
  # `permissions?('ticket.agent')` satu-per-satu di Ruby, karena
  # `permissions?` adalah method instance, bukan kolom, jadi kelihatannya
  # tidak bisa didorong ke SQL. Ini SALAH untuk query luas: dari 71.771
  # user aktif cuma 513 (~0.7%) yang agent, jadi window 100 baris --
  # bagaimanapun cara mengurutkannya (termasuk sudah dicoba ORDER BY
  # firstname/lastname, tetap gagal) -- punya peluang besar tidak berisi
  # SATU PUN agent asli. Query "anon" yang cocok ke 71 ribu+ baris
  # akhirnya konsisten mengembalikan 0 hasil walau 508 agent asli cocok.
  #
  # PERBAIKAN: `Permission.join_with` (dipakai native Zammad sendiri di
  # User::HasGroups#group_access) mendorong pengecekan permission ke SQL
  # via JOIN roles -> role_permissions -> permissions, BUKAN loop Ruby
  # setelah LIMIT. Dengan ini filter ILIKE + filter permission jadi SATU
  # query SQL, sehingga `.count` akurat dan `.limit/.offset` benar-benar
  # membagi HASIL AKHIR (bukan kandidat sebelum difilter) -- tidak ada
  # lagi jendela kandidat yang bisa "kehabisan" agent asli.
  DEFAULT_PER_PAGE = 25
  MAX_PER_PAGE     = 100

  def index
    raise Exceptions::Forbidden if !current_user.permissions?('aux_status.override')

    query = params[:query].to_s.strip
    return render(json: { count: 0, agents: [] }) if query.blank?

    like    = "%#{User.sanitize_sql_like(query)}%"
    matched = Permission.join_with(User, 'ticket.agent')
                         .where(users: { active: true })
                         .where('firstname ILIKE :q OR lastname ILIKE :q OR login ILIKE :q OR email ILIKE :q', q: like)
                         .distinct

    page     = [params[:page].to_i, 1].max
    per_page = params[:per_page].to_i
    per_page = DEFAULT_PER_PAGE if per_page <= 0
    per_page = MAX_PER_PAGE if per_page > MAX_PER_PAGE

    total_count = matched.count
    page_agents = matched.order(:firstname, :lastname).limit(per_page).offset((page - 1) * per_page)

    render json: {
      count:  total_count,
      agents: page_agents.map { |u| status_json(u).merge(fullname: u.fullname) },
    }, status: :ok
  end

  # PUT /api/v1/aux_status
  # Ubah status milik diri sendiri.
  def update
    raise Exceptions::Forbidden if !current_user.permissions?('ticket.agent')

    user = Service::AuxStatus::ChangeStatus.run(
      target:     current_user,
      status:     params[:status],
      changed_by: current_user,
    )
    render json: status_json(user), status: :ok
  end

  # PUT /api/v1/aux_status/:user_id
  # Override status milik agent lain -- butuh permission 'aux_status.override'
  # (dicek di dalam Service::AuxStatus::ChangeStatus#authorize!, bukan di
  # sini, supaya jalur otorisasinya satu-satunya/tidak terduplikasi).
  def override
    raise Exceptions::Forbidden if !current_user.permissions?('ticket.agent')

    target = User.find(params[:user_id])
    user   = Service::AuxStatus::ChangeStatus.run(
      target:,
      status:     params[:status],
      changed_by: current_user,
    )
    render json: status_json(user), status: :ok
  end

  private

  # id (not just user_id) is required so the frontend can feed this
  # straight into App.User.refresh([...]) -- Spine collections match
  # records by `id`, not an arbitrary key.
  def status_json(user)
    {
      id:                    user.id,
      user_id:               user.id,
      aux_status:            user.aux_status,
      aux_status_since:      user.aux_status_since,
      aux_status_expires_at: user.aux_status_expires_at,
    }
  end
end
