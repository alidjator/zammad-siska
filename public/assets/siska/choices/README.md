# Choices.js 11.1.0

`choices-11.1.0.min.js` -- salinan apa adanya dari kit Able Pro Tailwind v1.2.0
(`dist/assets/js/plugins/choices.min.js`). Choices.js oleh Josh Johnson,
lisensi MIT: https://github.com/Choices-js/Choices

Dipakai multi-select filter Prioritas / Kanal / Kategori di tab Dashboard ->
KPI Tim (`team_kpi.coffee`, docs/DESIGN_TEAM_KPI_DASHBOARD.md Section 18).
Dimuat lazy (sekali per halaman) saat tab KPI Tim dirender, bukan bagian
application.js. Gaya mengikuti `src/assets/scss/partial/choices.css` kit,
diterjemahkan ke `app/assets/stylesheets/team_kpi.scss`.
