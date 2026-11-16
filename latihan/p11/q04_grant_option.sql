-- Diminta: memberi app_write SELECT dengan GRANT OPTION, meneruskannya ke
--          app_analitik, mencabut grant option tanpa CASCADE lalu dengan
--          CASCADE, dan membuktikan app_write tetap bisa membaca.
-- Dipilih: relacl dicetak di setiap tahap, karena app_write juga mewarisi
--          SELECT lewat keanggotaan app_read sehingga has_table_privilege
--          saja akan selalu bernilai t dan tidak membuktikan apa pun.
-- Alternatif: mencabut keanggotaan app_read dari app_write lebih dulu supaya
--             has_table_privilege menjadi bukti yang bersih; tidak dipilih
--             karena mengubah susunan peran yang sedang diuji soal lain.

\set ON_ERROR_STOP off
\set VERBOSITY verbose

\echo === 4a. Keadaan awal ACL transaksi ===
SELECT relacl AS acl_awal FROM pg_class WHERE oid = 'lab11.transaksi'::regclass;

\echo === 4b. Beri app_write SELECT WITH GRANT OPTION ===
GRANT SELECT ON lab11.transaksi TO app_write WITH GRANT OPTION;
SELECT relacl AS acl_sesudah_grant_option FROM pg_class WHERE oid = 'lab11.transaksi'::regclass;
-- perhatikan app_write=r*: tanda bintang itulah grant option

\echo === 4c. app_write meneruskan haknya ke app_analitik ===
SET ROLE app_write;
SELECT current_user AS pemberi;
GRANT SELECT ON lab11.transaksi TO app_analitik;
RESET ROLE;

SELECT relacl AS acl_sesudah_diteruskan FROM pg_class WHERE oid = 'lab11.transaksi'::regclass;
-- perhatikan app_analitik=r/app_write: pemberinya app_write, bukan postgres

SELECT has_table_privilege('app_analitik','lab11.transaksi','SELECT') AS analitik_boleh_baca;

\echo === 4d. Cabut HANYA grant option, tanpa CASCADE: harus DITOLAK ===
REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write;
-- harapkan SQLSTATE 2BP01

\echo === 4e. Ulangi dengan CASCADE ===
REVOKE GRANT OPTION FOR SELECT ON lab11.transaksi FROM app_write CASCADE;

SELECT relacl AS acl_sesudah_cascade FROM pg_class WHERE oid = 'lab11.transaksi'::regclass;
-- harapkan app_write=r (tanpa bintang) dan app_analitik hilang dari daftar

\echo === 4f. Siapa yang masih bisa membaca ===
SELECT has_table_privilege('app_analitik','lab11.transaksi','SELECT') AS analitik,
       has_table_privilege('app_write','lab11.transaksi','SELECT')    AS app_write;
-- harapkan: analitik = f, app_write = t

\echo === 4g. Dari mana kebolehan app_write datang: grant langsung DAN warisan ===
SELECT 'grant langsung pada ACL' AS sumber,
       (SELECT count(*) FROM aclexplode(relacl) a
        WHERE a.grantee = 'app_write'::regrole AND a.privilege_type = 'SELECT') AS ada
FROM pg_class WHERE oid = 'lab11.transaksi'::regclass
UNION ALL
SELECT 'warisan keanggotaan app_read',
       (SELECT count(*) FROM pg_auth_members m
        WHERE m.member = 'app_write'::regrole AND m.roleid = 'app_read'::regrole);

\echo === 4h. Pulihkan keadaan untuk soal berikutnya ===
REVOKE SELECT ON lab11.transaksi FROM app_write;
SELECT relacl AS acl_akhir FROM pg_class WHERE oid = 'lab11.transaksi'::regclass;
