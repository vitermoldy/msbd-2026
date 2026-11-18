# Q30 — Peta Tiket #1134 ke UU PDP

> STATUS: belum dapat difinalkan. Isi lima keluhan Tiket #1134 tidak terdapat pada berkas latihan/ZIP yang diterima. Ganti setiap placeholder setelah memperoleh teks asli tiket. Jangan menebak isi keluhan.

| No. | Keluhan persis dari Tiket #1134                       | Pasal UU No. 27 Tahun 2022 | Kontrol teknis dari praktikum                           |
| --: | ----------------------------------------------------- | -------------------------- | ------------------------------------------------------- |
|   1 | K1. Aplikasi menggunakan akun pemilik seluruh tabel   | Pasal 35                   | Pemisahan peran pemilik, fungsional, dan login aplikasi |
|   2 | K2. Penyewa A membaca data penyewa B                  | Pasal 39 ayat (1)          | RLS, FORCE RLS, dan SET LOCAL                           |
|   3 | K3. SQL Injection membuka seluruh tabel               | Pasal 38                   | Query berparameter, daftar putih, dan hak minimum       |
|   4 | K4. Backup berisi NIK dan rekening tanpa perlindungan | Pasal 36                   | Enkripsi backup, enkripsi kolom, dan penyamaran         |
|   5 | K5. Data yang diminta dihapus masih tersebar          | Pasal 43                   | Permintaan penghapusan, kebijakan retensi, dan audit    |

Dasar pemilihan pasalnya:
- Pasal 35 mengatur kewajiban memastikan keamanan data pribadi melalui langkah teknis dan operasional.
- Pasal 36 mengatur kewajiban menjaga kerahasiaan data pribadi.
- Pasal 38 mengatur perlindungan terhadap pemrosesan yang tidak sah.
- Pasal 39 ayat (1) mengatur pencegahan akses tidak sah.
- Pasal 43 mengatur kewajiban penghapusan data dalam kondisi yang ditentukan, termasuk adanya permintaan subjek data.

## Rujukan yang sudah disebut eksplisit dalam instruksi latihan

- **Pasal 31:** instruksi latihan mengaitkannya dengan kewajiban merekam/mendokumentasikan kegiatan pemrosesan data pribadi. Hubungkan dengan `jejak_audit` dan bukti Q25–Q27.
- **Pasal 43:** instruksi latihan mengaitkannya dengan penghapusan/pemusnahan data pribadi. Hubungkan dengan permintaan penghapusan, tenggat 72 jam, dan pemeriksaan sisa data Q28–Q29.

Periksa bunyi pasal lengkap pada naskah resmi UU No. 27 Tahun 2022 sebelum menyerahkan laporan. Dua pasal di atas belum cukup untuk mengisi lima baris tanpa isi keluhan tiket.
