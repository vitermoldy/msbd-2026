-- Diminta: menyebutkan tiga cara isolasi ini masih bisa gagal, masing-masing
--          dengan satu kalimat perbaikannya, dan membuktikan minimal satu
--          dengan keluaran nyata.
-- Dipilih: ketiganya dibuktikan, bukan satu, karena ketiga celah ini berada
--          di tiga tempat yang berbeda -- setelan tabel, atribut peran, dan
--          kode di dalam basis data -- sehingga memeriksa satu saja tidak
--          memberi alasan untuk percaya pada dua yang lain.
-- Alternatif: membuktikan hanya celah pertama dan menjelaskan dua sisanya
--             secara teori; tidak dipilih karena celah ketiga justru yang
--             paling mudah lolos dari tinjauan, sebab ia tidak terlihat di
--             pg_policies maupun di ACL tabel.

\set ON_ERROR_STOP on

\echo ================================================================
\echo  CELAH 1: pemilik tabel tidak terkena kebijakan tanpa FORCE
\echo  Perbaikan: nyalakan FORCE ROW LEVEL SECURITY pada setiap tabel
\echo             berpenyewa, dan jadikan itu bagian dari migrasi.
\echo ================================================================
BEGIN;
SET LOCAL ROLE skema_owner;
SET LOCAL app.tenant = '1';
SELECT count(*) AS dengan_force FROM lab11.pelanggan;      -- 0, keadaan aman
COMMIT;

ALTER TABLE lab11.pelanggan NO FORCE ROW LEVEL SECURITY;   -- celahnya dibuka

BEGIN;
SET LOCAL ROLE skema_owner;
SET LOCAL app.tenant = '1';
SELECT count(*) AS tanpa_force                FROM lab11.pelanggan;   -- 30000
SELECT count(DISTINCT tenant_id) AS penyewa_terlihat FROM lab11.pelanggan;  -- 3
COMMIT;

ALTER TABLE lab11.pelanggan FORCE ROW LEVEL SECURITY;      -- ditutup kembali

\echo ================================================================
\echo  CELAH 2: atribut peran BYPASSRLS tidak tercatat di ACL mana pun
\echo  Perbaikan: audit rolbypassrls di pg_roles secara berkala, dan
\echo             jangan pernah menyematkannya pada peran aplikasi.
\echo ================================================================
SELECT rolname, rolbypassrls AS bypass_rls
FROM pg_roles WHERE rolname = 'app_laporan';

BEGIN;
SET LOCAL ROLE app_laporan;
SET LOCAL app.tenant = '1';
SELECT count(*) AS sebelum_bypass FROM lab11.pelanggan;    -- 10000
COMMIT;

ALTER ROLE app_laporan BYPASSRLS;                          -- celahnya dibuka

BEGIN;
SET LOCAL ROLE app_laporan;
SET LOCAL app.tenant = '1';
SELECT count(*) AS sesudah_bypass FROM lab11.pelanggan;    -- 30000
COMMIT;

ALTER ROLE app_laporan NOBYPASSRLS;                        -- ditutup kembali

-- Perhatikan: ACL tabel pelanggan TIDAK BERUBAH sedikit pun selama percobaan
-- di atas. Siapa pun yang mengaudit dengan membaca GRANT tidak akan melihat
-- apa-apa.
SELECT relacl AS acl_pelanggan_tidak_berubah
FROM pg_class WHERE oid = 'lab11.pelanggan'::regclass;

\echo ================================================================
\echo  CELAH 3: fungsi SECURITY DEFINER milik peran istimewa
\echo  Perbaikan: tulis fungsi pembaca sebagai SECURITY INVOKER, atau
\echo             bila SECURITY DEFINER memang perlu, pemiliknya harus
\echo             peran biasa yang tunduk kebijakan -- bukan superuser.
\echo ================================================================
SELECT current_user AS pemilik_fungsi_nanti, usesuper AS pemilik_superuser
FROM pg_user WHERE usename = current_user;

CREATE OR REPLACE FUNCTION lab11.rekap_semua()
RETURNS bigint
LANGUAGE sql
SECURITY DEFINER            -- berjalan sebagai PEMILIK fungsi, bukan pemanggil
SET search_path = lab11, pg_temp
AS $$ SELECT count(*) FROM lab11.pelanggan $$;

GRANT EXECUTE ON FUNCTION lab11.rekap_semua() TO app_laporan;

BEGIN;
SET LOCAL ROLE app_laporan;
SET LOCAL app.tenant = '1';
SELECT count(*)              AS lewat_query_biasa FROM lab11.pelanggan;  -- 10000
SELECT lab11.rekap_semua()   AS lewat_fungsi_definer;                    -- 30000
COMMIT;
-- Satu peran, satu transaksi, satu nilai app.tenant: 10000 lewat query
-- biasa dan 30000 lewat fungsi. Kebijakan tidak dilanggar, ia hanya
-- dievaluasi atas nama peran yang salah.

DROP FUNCTION lab11.rekap_semua();

\echo === 11d. Keadaan akhir: ketiga celah tertutup kembali ===
SELECT c.relrowsecurity AS rls_menyala,
       c.relforcerowsecurity AS rls_dipaksa,
       (SELECT count(*) FROM pg_policies
        WHERE schemaname='lab11' AND tablename='pelanggan') AS jumlah_kebijakan,
       (SELECT count(*) FROM pg_roles
        WHERE rolbypassrls AND rolname LIKE 'app%')         AS peran_app_dengan_bypassrls,
       (SELECT count(*) FROM pg_proc p
        JOIN pg_namespace n ON n.oid = p.pronamespace
        WHERE n.nspname='lab11' AND p.prosecdef)            AS fungsi_security_definer
FROM pg_class c WHERE c.oid = 'lab11.pelanggan'::regclass;
-- harapkan: t | t | 2 | 0 | 0
