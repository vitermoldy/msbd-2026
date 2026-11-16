-- Diminta: menyusun tabel tujuh peran pada lab11, apa yang boleh dilakukan
--          masing-masing, menandai mana yang dapat login, dan menjelaskan
--          dalam satu kalimat mengapa aplikasi tidak pernah login sebagai
--          pemilik.
-- Dipilih: tabelnya dibangkitkan dari katalog (pg_roles, pg_auth_members,
--          aclexplode) dan bukan ditulis tangan, supaya ia ikut berubah bila
--          hak digeser soal lain dan tidak pernah berbohong tentang keadaan
--          klaster saat laporan dibuat.
-- Alternatif: menulis tabelnya sebagai Markdown di laporan.md saja; tidak
--             dipilih karena tabel tangan akan basi begitu Q9 memberi
--             pg_read_all_data dan Q23 mencabutnya.

\set ON_ERROR_STOP on

\echo === 5a. Tujuh peran: atribut dan kemampuan login ===
SELECT r.rolname                       AS peran,
       CASE WHEN r.rolcanlogin THEN 'ya' ELSE 'tidak' END AS dapat_login,
       r.rolsuper                      AS superuser,
       r.rolbypassrls                  AS bypass_rls,
       r.rolcreaterole                 AS boleh_buat_peran,
       coalesce(string_agg(g.rolname, ', ' ORDER BY g.rolname), '-') AS anggota_dari
FROM pg_roles r
LEFT JOIN pg_auth_members m ON m.member = r.oid
LEFT JOIN pg_roles g        ON g.oid = m.roleid
WHERE r.rolname IN ('skema_owner','app_read','app_write',
                    'app_laporan','app_portal','app_analitik','app_audit')
GROUP BY r.rolname, r.rolcanlogin, r.rolsuper, r.rolbypassrls, r.rolcreaterole
ORDER BY r.rolcanlogin, r.rolname;

\echo === 5b. Hak langsung per tabel, hanya yang tercatat di ACL ===
SELECT a.grantee::regrole::text AS peran,
       c.relname                AS tabel,
       string_agg(DISTINCT a.privilege_type, ', ' ORDER BY a.privilege_type) AS hak_langsung
FROM pg_class c
CROSS JOIN LATERAL aclexplode(c.relacl) AS a
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'lab11'
  AND a.grantee::regrole::text IN ('skema_owner','app_read','app_write',
                                   'app_laporan','app_portal','app_analitik','app_audit')
GROUP BY 1, 2
ORDER BY 1, 2;

\echo === 5c. Kepemilikan: satu-satunya peran yang memegang DROP dan ALTER ===
SELECT tablename AS tabel, tableowner AS pemilik
FROM pg_tables WHERE schemaname = 'lab11' ORDER BY tablename;

\echo === 5d. Hak efektif yang benar-benar dirasakan peran login ===
-- Menggabungkan hak langsung dan hak warisan, jadi inilah kolom yang
-- menjawab "apa yang boleh dilakukan masing-masing".
SELECT p.peran,
       has_table_privilege(p.peran,'lab11.pelanggan','SELECT') AS pelanggan_select,
       has_table_privilege(p.peran,'lab11.pelanggan','UPDATE') AS pelanggan_update,
       has_table_privilege(p.peran,'lab11.pelanggan','DELETE') AS pelanggan_delete,
       has_table_privilege(p.peran,'lab11.transaksi','SELECT') AS transaksi_select,
       has_table_privilege(p.peran,'lab11.akun','SELECT')      AS akun_select
FROM (VALUES ('skema_owner'),('app_read'),('app_write'),
             ('app_laporan'),('app_portal'),('app_analitik'),('app_audit')) AS p(peran)
ORDER BY p.peran;

-- JAWABAN SATU KALIMAT (Q5):
-- Aplikasi tidak pernah login sebagai pemilik karena hak DROP dan ALTER
-- melekat pada kepemilikan dan tidak dapat dicabut dengan REVOKE (dibuktikan
-- pada Q1 dan Q2), sehingga satu-satunya cara memastikan aplikasi tidak bisa
-- menghapus tabel adalah tidak pernah memberinya kepemilikan sejak awal.
