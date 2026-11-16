-- Diminta: menyalakan RLS pada pelanggan, lalu SEBELUM satu pun kebijakan
--          dibuat, menghitung baris yang terlihat app_laporan dan menjelaskan
--          mengapa hasilnya justru aman.
-- Dipilih: hak SELECT app_laporan dicetak berdampingan dengan jumlah baris
--          yang ia lihat, karena inti jawabannya adalah keduanya terpisah:
--          hak tetap ada, visibilitasnya nol.
-- Alternatif: hanya mencetak count(*); tidak dipilih karena angka 0 sendirian
--             bisa disalahartikan sebagai hak yang hilang atau tabel kosong.

\set ON_ERROR_STOP on

\echo === 6a. Pastikan belum ada kebijakan apa pun pada pelanggan ===
SELECT count(*) AS jumlah_kebijakan
FROM pg_policies WHERE schemaname = 'lab11' AND tablename = 'pelanggan';
-- harapkan 0. Bila bukan 0, q07 sudah pernah dijalankan: muat ulang
-- q00_setup.sql lebih dulu, karena keadaan "RLS menyala tanpa kebijakan"
-- tidak dapat diamati lagi tanpa menghapus kebijakannya.

\echo === 6b. Nyalakan RLS ===
ALTER TABLE lab11.pelanggan ENABLE ROW LEVEL SECURITY;

SELECT relname, relrowsecurity AS rls_menyala, relforcerowsecurity AS rls_dipaksa
FROM pg_class WHERE oid = 'lab11.pelanggan'::regclass;

\echo === 6c. Hak SELECT app_laporan: masih utuh ===
SELECT has_table_privilege('app_laporan','lab11.pelanggan','SELECT') AS hak_select_masih_ada;
-- harapkan t

\echo === 6d. Baris yang DILIHAT app_laporan: nol ===
BEGIN;
SET LOCAL ROLE app_laporan;
SELECT current_user AS peran_aktif;
SELECT count(*) AS sebelum_ada_kebijakan FROM lab11.pelanggan;   -- harapkan 0
COMMIT;

\echo === 6e. Pembanding: baris yang sebenarnya ada di tabel ===
SELECT count(*) AS baris_sesungguhnya FROM lab11.pelanggan;      -- 30000
-- Angka ini dibaca sebagai postgres (superuser), yang tidak terkena RLS.
-- Selisih 0 lawan 30000 inilah jawaban Q6.
