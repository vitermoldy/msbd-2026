-- Diminta: menjalankan REVOKE DROP ON lab11.akun FROM skema_owner, mengutip
--          galatnya, dan menjelaskan beda hak biasa dengan hak kepemilikan.
-- Dipilih: sesudah galat, kemampuan DROP dibuktikan masih ada dengan
--          menjalankan DROP sungguhan di dalam transaksi lalu ROLLBACK,
--          supaya klaim "tidak bisa dicabut" berdiri di atas bukti dan bukan
--          hanya di atas pesan galat sintaks.
-- Alternatif: berhenti pada pesan galat saja; tidak dipilih karena galat
--             sintaks hanya membuktikan DROP bukan kata yang dikenal GRANT,
--             belum membuktikan pemiliknya masih berdaya.

\set ON_ERROR_STOP off
\set VERBOSITY verbose

\echo === 2a. Mencabut DROP dari pemilik: tidak ada sintaksnya ===
REVOKE DROP ON lab11.akun FROM skema_owner;   -- harapkan SQLSTATE 42601

\echo === 2b. Hak apa saja yang SEBENARNYA dapat diberikan dan dicabut ===
-- Daftar tertutup ini yang menjadi inti jawaban: DROP dan ALTER tidak ada.
SELECT string_agg(p, ', ' ORDER BY p) AS hak_yang_dapat_di_grant
FROM unnest(ARRAY['SELECT','INSERT','UPDATE','DELETE','TRUNCATE',
                  'REFERENCES','TRIGGER','MAINTAIN']) AS t(p);

SELECT grantee, string_agg(privilege_type, ', ' ORDER BY privilege_type) AS hak
FROM information_schema.table_privileges
WHERE table_schema = 'lab11' AND table_name = 'akun'
GROUP BY grantee ORDER BY grantee;

\echo === 2c. Pemilik tetap bisa DROP meski seluruh hak biasa dicabut ===
REVOKE ALL ON lab11.akun FROM skema_owner;

SELECT has_table_privilege('skema_owner','lab11.akun','SELECT') AS boleh_select,
       has_table_privilege('skema_owner','lab11.akun','INSERT') AS boleh_insert,
       has_table_privilege('skema_owner','lab11.akun','UPDATE') AS boleh_update,
       has_table_privilege('skema_owner','lab11.akun','DELETE') AS boleh_delete;

SET ROLE skema_owner;
SELECT current_user AS peran_aktif;

-- SELECT ditolak: hak biasa memang sudah tidak ada.
SELECT count(*) FROM lab11.akun;                -- harapkan SQLSTATE 42501

-- Tetapi ALTER dan DROP tetap jalan. Dibungkus transaksi lalu ROLLBACK
-- supaya tabelnya kembali utuh untuk soal berikutnya.
BEGIN;
ALTER TABLE lab11.akun ADD COLUMN bukti_alter int;
DROP TABLE lab11.akun;
SELECT 'ALTER dan DROP berhasil dijalankan oleh pemilik' AS hasil;
ROLLBACK;

RESET ROLE;

\echo === 2d. Pulihkan hak biasa pemilik ===
GRANT ALL ON lab11.akun TO skema_owner;

SELECT c.relname, pg_get_userbyid(c.relowner) AS pemilik, c.relacl
FROM pg_class c WHERE c.oid = 'lab11.akun'::regclass;

SELECT count(*) AS akun_masih_utuh FROM lab11.akun;   -- harapkan 4
