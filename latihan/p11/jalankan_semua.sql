-- Diminta: menjalankan seluruh rangkaian Q1-Q11 dalam urutan yang benar.
-- Dipilih: satu berkas penggerak yang memuat berkas lain dengan \ir, karena
--          \ir mencari berkas relatif terhadap letak skrip ini sendiri,
--          sehingga satu perintah yang sama bekerja di dalam kontainer (/lab11)
--          maupun saat diuji di luar kontainer.
-- Alternatif: perulangan FOR di Command Prompt; tidak dipilih karena perintah
--             berikutnya bisa tertelan oleh perintah sebelumnya yang masih
--             berjalan, dan itu sudah terjadi sekali.

\echo ########## q00_setup ##########
\ir q00_setup.sql
\echo ########## q01_hak_pemilik ##########
\ir q01_hak_pemilik.sql
\echo ########## q02_drop_bukan_hak ##########
\ir q02_drop_bukan_hak.sql
\echo ########## q03_default_privileges ##########
\ir q03_default_privileges.sql
\echo ########## q04_grant_option ##########
\ir q04_grant_option.sql
\echo ########## q05_tabel_peran ##########
\ir q05_tabel_peran.sql
\echo ########## q06_default_deny ##########
\ir q06_default_deny.sql
\echo ########## q07_kebijakan_penyewa ##########
\ir q07_kebijakan_penyewa.sql
\echo ########## q08_uji_positif_negatif ##########
\ir q08_uji_positif_negatif.sql
\echo ########## q09_force_dan_bypass ##########
\ir q09_force_dan_bypass.sql
\echo ########## q10_kolam_koneksi ##########
\ir q10_kolam_koneksi.sql
\echo ########## q11_tiga_celah ##########
\ir q11_tiga_celah.sql
\echo ########## SELESAI ##########
