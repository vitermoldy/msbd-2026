-- Diminta: mencabut UPDATE dari skema_owner, membuktikan penolakannya, lalu
--          memberikan hak itu kembali kepada diri sendiri dan mengulanginya.
-- Dipilih: relacl dicetak di tiga titik (sebelum REVOKE, sesudah REVOKE,
--          sesudah GRANT ulang), karena yang perlu dibuktikan bukan hanya
--          "ditolak lalu berhasil" tetapi bahwa pemilik tetap memegang grant
--          option meski hak biasanya sudah dicabut.
-- Alternatif: hanya membandingkan has_table_privilege sebelum dan sesudah;
--             tidak dipilih karena fungsi itu menjawab "boleh atau tidak" dan
--             menyembunyikan dari mana kebolehan itu datang.

\set ON_ERROR_STOP off
\set VERBOSITY verbose

\echo === 1a. Keadaan awal: ACL dan pemilik tabel ===
SELECT c.relname,
       pg_get_userbyid(c.relowner) AS pemilik,
       c.relacl
FROM pg_class c
WHERE c.oid = 'lab11.pelanggan'::regclass;

SELECT has_table_privilege('skema_owner','lab11.pelanggan','UPDATE') AS update_sebelum_revoke;

\echo === 1b. Cabut UPDATE dari pemilik ===
REVOKE UPDATE ON lab11.pelanggan FROM skema_owner;

SELECT c.relacl AS acl_sesudah_revoke
FROM pg_class c WHERE c.oid = 'lab11.pelanggan'::regclass;

SELECT has_table_privilege('skema_owner','lab11.pelanggan','UPDATE') AS update_sesudah_revoke;

\echo === 1c. UPDATE sebagai skema_owner: harus DITOLAK ===
SET ROLE skema_owner;
SELECT current_user AS peran_aktif, session_user AS peran_login;

BEGIN;
UPDATE lab11.pelanggan SET kota = kota WHERE id = 3;   -- harapkan SQLSTATE 42501
ROLLBACK;

\echo === 1d. Pemilik memberikan hak itu kembali KEPADA DIRINYA SENDIRI ===
-- Masih sebagai skema_owner. Perhatikan bahwa tidak ada superuser yang
-- menolong di sini: perintah ini dijalankan oleh peran yang tadi ditolak.
GRANT UPDATE ON lab11.pelanggan TO skema_owner;

SELECT has_table_privilege('skema_owner','lab11.pelanggan','UPDATE') AS update_sesudah_grant_ulang;

\echo === 1e. UPDATE yang sama: sekarang BERHASIL ===
BEGIN;
UPDATE lab11.pelanggan SET kota = kota WHERE id = 3;
SELECT count(*) AS baris_terdampak FROM lab11.pelanggan WHERE id = 3;
ROLLBACK;

RESET ROLE;

\echo === 1f. ACL akhir: hak kembali. Perhatikan nama sesudah tanda / yaitu pemberi hak ===
SELECT c.relacl AS acl_akhir
FROM pg_class c WHERE c.oid = 'lab11.pelanggan'::regclass;
