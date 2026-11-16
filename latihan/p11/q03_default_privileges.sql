-- Diminta: sebagai postgres, membuat tabel baru di skema lab11 dan memeriksa
--          apakah app_laporan bisa membacanya, lalu menjelaskan hasilnya dan
--          perintah apa yang seharusnya sudah dijalankan.
-- Dipilih: dua tabel dibuat berurutan dalam satu berkas, satu oleh postgres
--          dan satu oleh skema_owner, karena jawabannya adalah selisih antara
--          keduanya dan selisih itu hanya sah bila segala hal lain sama.
-- Alternatif: membandingkan tabel baru buatan postgres dengan lab11.pelanggan
--             yang sudah ada; tidak dipilih karena pelanggan juga menerima
--             GRANT eksplisit di q00, sehingga sumber kebolehannya bercampur.

\set ON_ERROR_STOP on

\echo === 3a. Default privileges yang terpasang di skema lab11 ===
SELECT pg_get_userbyid(d.defaclrole) AS untuk_peran,
       n.nspname                     AS skema,
       d.defaclobjtype               AS jenis_objek,
       d.defaclacl                   AS acl_bawaan
FROM pg_default_acl d
JOIN pg_namespace n ON n.oid = d.defaclnamespace
WHERE n.nspname = 'lab11';

\echo === 3b. Tabel dibuat oleh postgres ===
SELECT current_user AS pembuat;
CREATE TABLE lab11.catatan_postgres (id int);

\echo === 3c. Tabel dibuat oleh skema_owner, segala hal lain sama ===
SET ROLE skema_owner;
SELECT current_user AS pembuat;
CREATE TABLE lab11.catatan_owner (id int);
RESET ROLE;

\echo === 3d. Selisihnya ===
SELECT 'catatan_postgres' AS tabel,
       pg_get_userbyid(relowner) AS pemilik,
       has_table_privilege('app_laporan','lab11.catatan_postgres','SELECT') AS app_laporan_boleh_select,
       relacl
FROM pg_class WHERE oid = 'lab11.catatan_postgres'::regclass
UNION ALL
SELECT 'catatan_owner',
       pg_get_userbyid(relowner),
       has_table_privilege('app_laporan','lab11.catatan_owner','SELECT'),
       relacl
FROM pg_class WHERE oid = 'lab11.catatan_owner'::regclass;
-- harapkan: catatan_postgres = f, catatan_owner = t

\echo === 3e. Perintah yang seharusnya sudah dijalankan untuk peran pembuat ===
-- Untuk postgres, perintah ini belum pernah dijalankan:
--   ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lab11
--       GRANT SELECT ON TABLES TO app_read;
-- Dibuktikan: pasang, buat tabel ketiga, lalu periksa lagi.
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lab11
    GRANT SELECT ON TABLES TO app_read;

CREATE TABLE lab11.catatan_postgres_2 (id int);

SELECT 'catatan_postgres_2' AS tabel,
       pg_get_userbyid(relowner) AS pemilik,
       has_table_privilege('app_laporan','lab11.catatan_postgres_2','SELECT') AS app_laporan_boleh_select,
       relacl
FROM pg_class WHERE oid = 'lab11.catatan_postgres_2'::regclass;
-- harapkan: t

\echo === 3f. Bersihkan, termasuk default privileges yang baru dipasang ===
ALTER DEFAULT PRIVILEGES FOR ROLE postgres IN SCHEMA lab11
    REVOKE SELECT ON TABLES FROM app_read;
DROP TABLE lab11.catatan_postgres;
DROP TABLE lab11.catatan_postgres_2;
DROP TABLE lab11.catatan_owner;

SELECT count(*) AS tabel_sisa_di_lab11
FROM pg_tables WHERE schemaname = 'lab11';   -- harapkan 4
