-- Diminta: sebagai app_laporan penyewa 1, menghitung baris yang terlihat dan
--          baris penyewa 2; keduanya wajib dilaporkan.
-- Dipilih: uji negatifnya diperbanyak menjadi enam bentuk kegagalan yang
--          berbeda (penyewa lain, id milik penyewa lain, app.tenant tidak
--          disetel, berisi string kosong, berisi penyewa yang tidak ada, dan
--          percobaan menulis lintas penyewa), karena satu uji negatif saja
--          tidak membedakan kebijakan yang benar dari kebijakan yang kebetulan
--          mengembalikan nol.
-- Alternatif: hanya dua query seperti pada contoh soal; tidak dipilih karena
--             contoh itu tidak menyentuh jalur tulis, padahal justru di situ
--             WITH CHECK diuji.

\set ON_ERROR_STOP off
\set VERBOSITY verbose

\echo ===== UJI POSITIF =====
\echo === 8a. app_laporan, penyewa 1 ===
BEGIN;
SET LOCAL ROLE app_laporan;
SET LOCAL app.tenant = '1';
SELECT current_user AS peran, current_setting('app.tenant', true) AS penyewa;
SELECT count(*) AS terlihat_tenant1 FROM lab11.pelanggan;              -- harapkan 10000
SELECT min(id) AS id_terkecil, max(id) AS id_terbesar FROM lab11.pelanggan;
SELECT count(DISTINCT tenant_id) AS penyewa_yang_terlihat FROM lab11.pelanggan;  -- harapkan 1
COMMIT;

\echo === 8b. app_laporan, penyewa 2: kebijakan yang sama, jendela berbeda ===
BEGIN;
SET LOCAL ROLE app_laporan;
SET LOCAL app.tenant = '2';
SELECT count(*) AS terlihat_tenant2 FROM lab11.pelanggan;              -- harapkan 10000
SELECT min(id) AS id_terkecil, max(id) AS id_terbesar FROM lab11.pelanggan;
COMMIT;

\echo ===== UJI NEGATIF: enam bentuk kegagalan =====
\echo === 8c. (1) Penyewa 1 meminta baris penyewa 2 secara eksplisit ===
BEGIN;
SET LOCAL ROLE app_laporan;
SET LOCAL app.tenant = '1';
SELECT count(*) AS harus_nol FROM lab11.pelanggan WHERE tenant_id = 2;  -- harapkan 0
COMMIT;

\echo === 8d. (2) Penyewa 1 menyebut id milik penyewa 2 ===
BEGIN;
SET LOCAL ROLE app_laporan;
SET LOCAL app.tenant = '1';
SELECT count(*) AS harus_nol FROM lab11.pelanggan WHERE id = 15000;     -- harapkan 0
SELECT count(*) AS harus_nol_rentang FROM lab11.pelanggan WHERE id BETWEEN 10001 AND 30000;
COMMIT;

\echo === 8e. (3) app.tenant tidak disetel pada transaksi ini ===
BEGIN;
SET LOCAL ROLE app_laporan;
-- Perhatikan nilainya. Pada koneksi yang BARU, current_setting mengembalikan
-- NULL. Pada koneksi yang sudah pernah menyetel app.tenant -- yaitu keadaan
-- normal di kolam koneksi -- yang tertinggal adalah STRING KOSONG, bukan NULL.
-- Inilah jebakan yang membuat ::int langsung melempar 22P02 di Q7, dan
-- inilah sebabnya kebijakan kita memakai nullif.
SELECT current_setting('app.tenant', true)          AS nilai,
       current_setting('app.tenant', true) IS NULL  AS apakah_null,
       quote_literal(current_setting('app.tenant', true)) AS terkutip;
SELECT count(*) AS harus_nol FROM lab11.pelanggan;                      -- harapkan 0
COMMIT;

\echo === 8f. (4) app.tenant berisi string kosong ===
BEGIN;
SET LOCAL ROLE app_laporan;
SET LOCAL app.tenant = '';
SELECT count(*) AS harus_nol FROM lab11.pelanggan;                      -- harapkan 0, tanpa galat
COMMIT;

\echo === 8g. (5) app.tenant menyebut penyewa yang tidak ada ===
BEGIN;
SET LOCAL ROLE app_laporan;
SET LOCAL app.tenant = '99';
SELECT count(*) AS harus_nol FROM lab11.pelanggan;                      -- harapkan 0
COMMIT;

\echo === 8h. (6) Jalur tulis: penyewa 1 mencoba menyentuh penyewa 2 ===
BEGIN;
SET LOCAL ROLE app_portal;
SET LOCAL app.tenant = '1';
SELECT current_user AS peran;

-- UPDATE lintas penyewa: USING menyaringnya, jadi nol baris terdampak.
-- Dibungkus CTE + count supaya jumlahnya tercetak sebagai hasil query dan
-- tidak bergantung pada tag perintah psql, yang hilang bila dijalankan -q.
WITH diubah AS (
    UPDATE lab11.pelanggan SET kota = 'DIUBAH' WHERE tenant_id = 2 RETURNING 1)
SELECT count(*) AS baris_terdampak_update FROM diubah;   -- harapkan 0

-- DELETE lintas penyewa: juga nol baris.
WITH dihapus AS (
    DELETE FROM lab11.pelanggan WHERE tenant_id = 2 RETURNING 1)
SELECT count(*) AS baris_terdampak_delete FROM dihapus;  -- harapkan 0

-- INSERT baris milik penyewa 2: ditolak WITH CHECK.
INSERT INTO lab11.pelanggan
    (id, tenant_id, nama, nik, surel, lahir, kota, saldo, rekening, status, dibuat_pada)
VALUES (999001, 2, 'Sisipan Lintas Penyewa', '1111111111111111',
        'uji@contoh.test', '1990-01-01', 'Jakarta', 0, '620000000000', 'aktif', now());
-- harapkan SQLSTATE 42501: new row violates row-level security policy
ROLLBACK;

\echo === 8i. Pastikan tidak ada data yang berubah ===
SELECT count(*) AS total_pelanggan FROM lab11.pelanggan;
SELECT count(*) AS kota_diubah FROM lab11.pelanggan WHERE kota = 'DIUBAH';  -- harapkan 0
SELECT tenant_id, count(*) FROM lab11.pelanggan GROUP BY 1 ORDER BY 1;
