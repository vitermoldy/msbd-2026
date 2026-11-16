-- Diminta: menjelaskan dengan potongan kode bagaimana konteks penyewa bisa
--          tertinggal di kolam koneksi dan bocor ke permintaan berikutnya,
--          lalu menunjukkan pola SET LOCAL atau set_config(..., true) yang
--          mencegahnya.
-- Dipilih: kebocorannya diperagakan sungguhan dalam satu session psql, karena
--          satu session psql persis setara dengan satu koneksi yang dipegang
--          kolam dan dipakai ulang; setiap blok BEGIN..COMMIT di bawah adalah
--          satu permintaan HTTP yang kebetulan mendapat koneksi yang sama.
-- Alternatif: menjelaskannya dengan diagram atau pseudocode saja; tidak
--             dipilih karena angka 10000 yang muncul pada permintaan yang
--             tidak pernah menyebut penyewa adalah satu-satunya bukti yang
--             tidak bisa dibantah.

\set ON_ERROR_STOP on

\echo ===== BAGIAN 1: POLA YANG SALAH (SET tanpa LOCAL) =====

\echo === 10a. Permintaan ke-1: pengguna penyewa 1, menyetel dengan SET ===
BEGIN;
SET LOCAL ROLE app_laporan;
SET app.tenant = '1';          -- SALAH: tanpa LOCAL, nilainya milik SESSION
SELECT current_setting('app.tenant', true) AS penyewa,
       count(*)                            AS dilihat
FROM lab11.pelanggan;
COMMIT;

\echo === 10b. Permintaan ke-2: koneksi yang sama, TIDAK menyebut penyewa ===
-- Inilah permintaan berikutnya yang mendapat koneksi bekas dari kolam.
-- Kodenya tidak pernah menyetel app.tenant. Seharusnya ia tidak melihat apa
-- pun, tetapi konteks penyewa 1 masih menempel pada koneksinya.
BEGIN;
SET LOCAL ROLE app_laporan;
SELECT current_setting('app.tenant', true) AS penyewa_yang_tertinggal,
       count(*)                            AS dilihat
FROM lab11.pelanggan;
COMMIT;
-- harapkan: penyewa_yang_tertinggal = 1 dan dilihat = 10000  <-- KEBOCORAN

\echo === 10c. Mengapa ini berbahaya ===
-- Bila permintaan ke-2 datang dari pengguna penyewa 2, ia akan menerima
-- 10000 baris milik penyewa 1 tanpa satu pun galat, tanpa satu pun hak yang
-- dilanggar, dan tanpa jejak di log. Kebijakan RLS bekerja sempurna; yang
-- salah adalah nilai yang diberikan aplikasi kepadanya.

\echo ===== BAGIAN 2: POLA YANG BENAR =====

\echo === 10d. Bersihkan sisa dari kolam ===
RESET app.tenant;
SELECT quote_literal(current_setting('app.tenant', true)) AS sesudah_reset;

\echo === 10e. Permintaan ke-3: set_config(..., true) -- parameter is_local ===
BEGIN;
SET LOCAL ROLE app_laporan;
SELECT set_config('app.tenant', '1', true) AS disetel_lokal;   -- BENAR
SELECT current_setting('app.tenant', true) AS penyewa,
       count(*)                            AS dilihat
FROM lab11.pelanggan;
COMMIT;
-- harapkan dilihat = 10000

\echo === 10f. Permintaan ke-4: koneksi yang sama, tidak ada sisa lagi ===
BEGIN;
SET LOCAL ROLE app_laporan;
SELECT quote_literal(current_setting('app.tenant', true)) AS penyewa_tersisa,
       count(*)                                           AS dilihat
FROM lab11.pelanggan;
COMMIT;
-- harapkan dilihat = 0: nilainya hilang bersama transaksi, dan nullif pada
-- kebijakan mengubah string kosong menjadi NULL sehingga hasilnya menolak.

\echo === 10g. Pola yang dipakai rentan.py ===
-- Lihat fungsi pasang_penyewa() di rentan.py: parameter ketiga true itulah
-- is_local. Dua bentuk yang benar dan setara:
--     SET LOCAL app.tenant = '1';                  -- di dalam transaksi
--     SELECT set_config('app.tenant', '1', true);  -- dapat diparameterkan
-- Bentuk kedua dipakai aplikasi karena nilainya boleh datang dari variabel
-- tanpa perlu merangkai teks SQL.
SELECT 'SET LOCAL dan set_config(...,true) hanya hidup selama transaksi' AS kaidah;
