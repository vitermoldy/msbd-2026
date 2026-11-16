-- Diminta: menghitung baris yang dilihat skema_owner sebelum dan sesudah
--          FORCE ROW LEVEL SECURITY, lalu memberi app_analitik peran
--          pg_read_all_data dan menghitung lagi, dibandingkan dengan setelah
--          BYPASSRLS, serta menjelaskan apa yang itu ajarkan.
-- Dipilih: keempat keadaan diukur dengan query yang sama persis dan dicetak
--          berdampingan, karena pelajaran soal ini adalah satu angka berubah
--          dari 30000 ke 0 ke 0 ke 30000 sementara querynya tidak bergerak.
-- Alternatif: memakai superuser sebagai pembanding; tidak dipilih karena
--             superuser selalu melewati RLS sehingga tidak dapat
--             memperlihatkan efek FORCE sama sekali.

\set ON_ERROR_STOP on

\echo === 9a. skema_owner SEBELUM force: pemilik tidak terkena kebijakan ===
SELECT relrowsecurity AS rls_menyala, relforcerowsecurity AS rls_dipaksa
FROM pg_class WHERE oid = 'lab11.pelanggan'::regclass;

BEGIN;
SET LOCAL ROLE skema_owner;
SET LOCAL app.tenant = '1';
SELECT current_user AS peran, count(*) AS dilihat_owner_sebelum_force
FROM lab11.pelanggan;                                  -- harapkan 30000
COMMIT;

\echo === 9b. Nyalakan FORCE, lalu ukur lagi dengan query yang sama ===
ALTER TABLE lab11.pelanggan FORCE ROW LEVEL SECURITY;

SELECT relrowsecurity AS rls_menyala, relforcerowsecurity AS rls_dipaksa
FROM pg_class WHERE oid = 'lab11.pelanggan'::regclass;

BEGIN;
SET LOCAL ROLE skema_owner;
SET LOCAL app.tenant = '1';
SELECT current_user AS peran, count(*) AS dilihat_owner_sesudah_force
FROM lab11.pelanggan;                                  -- harapkan 0
COMMIT;
-- Nol, bukan 10000: kebijakan p_tenant_baca diberikan kepada app_read dan
-- app_write, dan skema_owner bukan anggota keduanya. FORCE membuat pemilik
-- tunduk pada kebijakan, dan tanpa kebijakan yang menyebutnya, yang berlaku
-- adalah default deny dari Q6.

\echo === 9c. app_analitik dengan pg_read_all_data ===
GRANT pg_read_all_data TO app_analitik;

SELECT has_table_privilege('app_analitik','lab11.pelanggan','SELECT') AS hak_select,
       pg_has_role('app_analitik','pg_read_all_data','member')        AS anggota_read_all,
       rolbypassrls AS bypass_rls
FROM pg_roles WHERE rolname = 'app_analitik';

BEGIN;
SET LOCAL ROLE app_analitik;
SET LOCAL app.tenant = '1';
SELECT current_user AS peran, count(*) AS dilihat_dengan_read_all_data
FROM lab11.pelanggan;                                  -- harapkan 0
COMMIT;

\echo === 9d. app_analitik dengan BYPASSRLS ===
ALTER ROLE app_analitik BYPASSRLS;

SELECT rolname, rolbypassrls AS bypass_rls FROM pg_roles WHERE rolname = 'app_analitik';

BEGIN;
SET LOCAL ROLE app_analitik;
SET LOCAL app.tenant = '1';
SELECT current_user AS peran, count(*) AS dilihat_dengan_bypassrls
FROM lab11.pelanggan;                                  -- harapkan 30000
SELECT count(DISTINCT tenant_id) AS penyewa_yang_terlihat FROM lab11.pelanggan;  -- 3
COMMIT;

\echo === 9e. Cabut BYPASSRLS; pg_read_all_data DIBIARKAN untuk dicabut Q23 ===
ALTER ROLE app_analitik NOBYPASSRLS;

SELECT rolname, rolbypassrls AS bypass_rls,
       pg_has_role('app_analitik','pg_read_all_data','member') AS masih_anggota_read_all
FROM pg_roles WHERE rolname = 'app_analitik';

\echo === 9f. Ringkasan empat keadaan, query tidak pernah berubah ===
-- 30000 -> 0 -> 0 -> 30000
-- pg_read_all_data memberi HAK membaca semua tabel; ia tidak memberi
-- kekebalan terhadap kebijakan baris. Yang memberi kekebalan itu atribut
-- peran BYPASSRLS, dan atribut itu tidak muncul di ACL tabel mana pun
-- sehingga tidak akan terlihat saat memeriksa GRANT.
SELECT 'FORCE wajib, sebab pemilik tabel tidak terkena kebijakan tanpa itu' AS pelajaran_1,
       'pg_read_all_data bukan BYPASSRLS; audit hak tidak cukup memeriksa ACL' AS pelajaran_2;
