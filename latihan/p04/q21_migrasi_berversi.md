# Q21 — Migrasi Berversi dan Rollback

Catatan pendamping untuk enam pasang migrasi expand–contract pada `migrations/` di akar
repositori. Berkas ini menjelaskan apa yang dilakukan tiap tahap, urutan menjalankannya, dan
sejauh mana tiap tahap dapat diurungkan.

- Diminta: menuliskan enam tahap expand–contract sebagai migrasi berversi, setiap `.up.sql`
  berpasangan dengan `.down.sql`, disertai tangkapan layar struktur dan tautan commit.
- Dipilih: satu berkas satu tahap, dengan tahap verifikasi dibuat sebagai blok `DO` yang
  melempar `EXCEPTION` bila backfill belum lengkap — sehingga pipeline berhenti dengan status
  gagal dan tidak mungkin melanjutkan ke fase contract secara diam-diam.
- Alternatif: menggabungkan seluruh fase contract ke dalam satu berkas migrasi; tidak dipilih
  karena tahap terakhir tidak dapat diurungkan sepenuhnya, dan menggabungkannya dengan tahap
  yang masih aman akan menghilangkan kesempatan berhenti di titik yang masih bisa mundur.

## Daftar Berkas

```
migrations/
├── 0041_expand_buat_harga_film.up.sql       / .down.sql
├── 0042_expand_trigger_tulis_ganda.up.sql   / .down.sql
├── 0043_migrate_backfill.up.sql             / .down.sql
├── 0044_migrate_verifikasi.up.sql           / .down.sql
├── 0045_contract_view_fasad.up.sql          / .down.sql
└── 0046_contract_drop_kolom_lama.up.sql     / .down.sql
```

Tangkapan layar struktur folder: `latihan/p04/struktur_migrations.png`.

## Isi dan Status Rollback Tiap Tahap

| Migrasi | Fase | Isi `up` | Isi `down` | Dapat diurungkan? |
|---|---|---|---|---|
| 0041 | expand | `CREATE TABLE lab4.harga_film` beserta `CHECK` dan `EXCLUDE USING gist` | `DROP TABLE ... CASCADE` | Ya, penuh — objek baru dan belum dipakai siapa pun |
| 0042 | expand | Fungsi `lab4.sync_harga_film()` dan trigger `trg_sync_harga` | `DROP TRIGGER` dan `DROP FUNCTION` | Ya, penuh — bentuk lama masih jadi sumber kebenaran |
| 0043 | migrate | Backfill berulang per 1000 film sampai `max(film_id)`, disaring `NOT EXISTS` | `DELETE` baris backfill | Ya, dengan syarat — lihat catatan di bawah |
| 0044 | migrate | Blok `DO` yang `RAISE EXCEPTION` bila masih ada film tanpa harga aktif | Tidak melakukan apa-apa | Tidak perlu — tahap ini hanya memeriksa |
| 0045 | contract | `CREATE OR REPLACE VIEW lab4.film_lama` yang membaca harga aktif dari bentuk baru | `DROP VIEW` | Ya, penuh — selama 0046 belum dijalankan |
| 0046 | contract | Lepas trigger, lalu `ALTER TABLE lab4.film DROP COLUMN rental_rate` | Tambah kolom kembali dan isi ulang dari `harga_film` | **Tidak penuh** — lihat peringatan |

## Urutan Menjalankan

Naik, satu per satu dan berurutan:

```bash
for f in 0041 0042 0043 0044 0045; do
  psql -h localhost -U msbd -d pagila -v ON_ERROR_STOP=1 -f migrations/${f}_*.up.sql
done
```

Turun, urutan terbalik:

```bash
for f in 0045 0044 0043 0042 0041; do
  psql -h localhost -U msbd -d pagila -v ON_ERROR_STOP=1 -f migrations/${f}_*.down.sql
done
```

`-v ON_ERROR_STOP=1` wajib. Tanpa opsi itu psql melanjutkan setelah galat lalu keluar dengan
status sukses, sehingga migrasi yang gagal separuh tampak berhasil.

0046 diuji terpisah dan paling akhir, tidak pernah ikut di dalam perulangan di atas.

## Peringatan — 0046 Tidak Dapat Diurungkan Sepenuhnya

`0046_contract_drop_kolom_lama.down.sql` hanya dapat membuat kolomnya kembali, lalu mengisinya
ulang dari `lab4.harga_film`. Yang kembali adalah **harga terkini hasil rekonstruksi**, bukan
nilai historis kolom lama beserta riwayat perubahannya. Bila sejak 0046 dijalankan ada
perubahan harga yang hanya tercatat di bentuk baru, atau ada film yang periode berjalannya
kosong, hasil rekonstruksi akan berbeda dari keadaan sebelum penghapusan.

Karena itu 0046 diperlakukan sebagai pintu satu arah: dijalankan paling akhir, terpisah dari
rilis lain, pada jam sepi, dan hanya setelah bukti pada Refleksi E terkumpul.

Jarak rilis yang diusulkan antara 0045 dan 0046 beserta daftar bukti yang harus dikumpulkan
ada pada Refleksi E di `laporan.md`.

## Catatan Tambahan

**Rollback 0043 tidak sepenuhnya bersih.** Berkas turunnya menghapus baris berdasarkan
`berlaku @> '2026-01-01'::date`. Rentang yang dibuat trigger tulis ganda 0042 juga bisa
mencakup tanggal itu, sehingga rollback 0043 berpotensi ikut menghapus baris yang lahir dari
0042, bukan hanya hasil backfill. Bila ingin lebih tepat sasaran, saring juga berdasarkan
`lower(berlaku) = DATE '2026-01-01'`.

**Konvensi penamaan berbeda dari Flyway.** `migrations/` di akar repositori tidak dijalankan
oleh service `flyway` pada `docker-compose.yml` — service itu hanya me-mount
`latihan/p02/migrations` dengan pola `V1__…sql`. Migrasi P04 memakai pola
`0041_…up.sql` / `0041_…down.sql` dan dijalankan manual dengan psql.

**Temuan pemeriksaan silang yang masih terbuka.** Tiga hal berikut sudah dicatat pada jawaban
Q18–Q21 di `laporan.md` dan perlu dibereskan sebelum pengumpulan:

1. `0042` memakai `daterange(lower(berlaku), now())` dan `daterange(now(), NULL)`. `now()`
   bertipe `timestamptz` sedangkan `daterange` menuntut `date`, sehingga trigger gagal pada
   `UPDATE` harga pertama. Ganti menjadi `current_date`.
2. `0046` akan ditolak selama view `lab4.film_murah` dan `lab4.pendapatan_kategori` masih
   menunjuk kolom `rental_rate`. Arahkan kedua view itu ke sumber baru lebih dulu.
3. Berkas latihan `q19` hanya memuat dua potongan tetap (`film_id` 1–2000), sedangkan film uji
   Q14–Q16 ber-`film_id` di atas 9000. Migrasi `0043` sudah benar karena memakai perulangan
   sampai `max(film_id)`; yang perlu disamakan adalah berkas latihannya.

## Tautan Commit

Tabel commit lengkap beserta tautannya ada pada Bagian 6 `laporan.md`.
