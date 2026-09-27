# ApexCharts 4.7.0 (vendor)

Dipakai tab Dashboard "KPI Tim" untuk grafik tren dan heatmap beban per jam
(`app/assets/javascripts/app/controllers/_dashboard/team_kpi.coffee`).

- Sumber: kit Able Pro Tailwind v1.2.0, `dist/assets/js/plugins/apexcharts.min.js`
  (versi yang sama dengan chart di kit: `line-chart-3`, `heatmap-chart-1`).
- Lisensi: MIT (lihat header file). Versi dikunci di 4.7.0 -- cek ulang
  lisensi sebelum upgrade.
- Tidak masuk bundle `application.js`: dimuat sekali secara lazy saat tab
  KPI Tim dibuka, supaya halaman Zammad lain tidak ikut berat (576 KB).
- File statis (seperti `public/assets/chat/`), bukan aset Sprockets, jadi
  URL-nya tetap tanpa digest.
