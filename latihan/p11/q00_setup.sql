-- Diminta: menyiapkan klaster tertutup (berkas ini menggantikan sql/lab11_setup.sql dari modul) berisi skema lab11 yang deterministik,
--          dengan tujuh peran berlapis sebagai dasar seluruh percobaan Q1-Q30.
-- Dipilih: data dibangkitkan dari generate_series dengan aritmetika tetap
--          (tanpa random()), supaya setiap anggota kelompok mendapat angka yang
--          sama persis dan bukti di laporan bisa dibandingkan antar mesin.
-- Alternatif: memuat sampel acak atau dump Pagila; tidak dipilih karena angka
--             yang berbeda tiap mesin membuat uji negatif RLS tidak bisa
--             diverifikasi silang antar anggota.

\set ON_ERROR_STOP on

-- =====================================================================
-- 0 - Ekstensi (bersifat per basis data, dibutuhkan Langkah 5)
-- =====================================================================
CREATE EXTENSION IF NOT EXISTS pgcrypto;

-- =====================================================================
-- 1 - Tujuh peran berlapis
--
--     Tiga peran grup tanpa hak login menampung hak; empat peran login
--     dipakai aplikasi dan analis. Aplikasi tidak pernah login sebagai
--     pemilik objek, sehingga DROP dan ALTER tidak pernah ada di
--     jangkauannya (lihat Q2 dan Q5).
-- =====================================================================
DROP SCHEMA IF EXISTS lab11 CASCADE;

DO $$
DECLARE
    r text;
BEGIN
    -- Kata sandi di bawah hanya untuk kontainer lab tertutup ini.
    FOREACH r IN ARRAY ARRAY['skema_owner','app_read','app_write'] LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r) THEN
            EXECUTE format('CREATE ROLE %I NOLOGIN', r);
        END IF;
    END LOOP;
END $$;

DO $$
DECLARE
    r record;
BEGIN
    FOR r IN
        SELECT * FROM (VALUES
            ('app_laporan',  'lab11-laporan'),
            ('app_portal',   'lab11-portal'),
            ('app_analitik', 'lab11-analitik'),
            ('app_audit',    'lab11-audit')
        ) AS v(nama, sandi)
    LOOP
        IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = r.nama) THEN
            EXECUTE format('CREATE ROLE %I LOGIN PASSWORD %L', r.nama, r.sandi);
        ELSE
            EXECUTE format('ALTER ROLE %I LOGIN PASSWORD %L', r.nama, r.sandi);
        END IF;
    END LOOP;
END $$;

-- Keanggotaan: hak menempel pada grup, bukan pada peran login.
GRANT app_read  TO app_laporan;
GRANT app_write TO app_portal;
GRANT app_read  TO app_write;          -- penulis juga boleh membaca

-- =====================================================================
-- 2 - Skema milik skema_owner, bukan milik postgres
-- =====================================================================
CREATE SCHEMA lab11 AUTHORIZATION skema_owner;

-- Dipasang SEBELUM tabel dibuat, supaya berlaku untuk tabel yang lahir
-- kemudian. Inilah yang dibandingkan pada Q3: tabel buatan skema_owner
-- terbaca app_read, tabel buatan postgres tidak.
ALTER DEFAULT PRIVILEGES FOR ROLE skema_owner IN SCHEMA lab11
    GRANT SELECT ON TABLES TO app_read;

GRANT USAGE ON SCHEMA lab11 TO app_read, app_write, app_analitik, app_audit;

-- =====================================================================
-- 3 - Tabel dan data, dibuat SEBAGAI skema_owner
-- =====================================================================
SET ROLE skema_owner;

CREATE TABLE lab11.tenant (
    tenant_id   int PRIMARY KEY,
    nama        text NOT NULL,
    dibuat_pada timestamptz NOT NULL
);

INSERT INTO lab11.tenant VALUES
    (1, 'Koperasi Nusantara', '2024-01-01 08:00+07'),
    (2, 'Bank Sentosa',       '2024-02-01 08:00+07'),
    (3, 'Dana Harapan',       '2024-03-01 08:00+07');

CREATE TABLE lab11.pelanggan (
    id          int PRIMARY KEY,
    tenant_id   int  NOT NULL REFERENCES lab11.tenant,
    nama        text NOT NULL,
    nik         char(16) NOT NULL,
    surel       text NOT NULL,
    lahir       date NOT NULL,
    kota        text NOT NULL,
    saldo       numeric(14,2) NOT NULL,
    rekening    text NOT NULL,
    status      text NOT NULL DEFAULT 'aktif',
    dibuat_pada timestamptz NOT NULL
);

-- 30000 baris, 10000 per penyewa. Penyewa dibagi per blok supaya uji
-- negatif RLS (Q8) menghasilkan angka bulat yang mudah diperiksa.
INSERT INTO lab11.pelanggan (id, tenant_id, nama, nik, surel, lahir, kota, saldo, rekening, status, dibuat_pada)
SELECT  i,
        ((i - 1) / 10000) + 1,
        'Pelanggan ' || i,
        lpad((((i::bigint * 7919)   % 99999999))::text, 8, '0') ||
        lpad((((i::bigint * 104729) % 99999999))::text, 8, '0'),
        'pelanggan' || i || '@contoh.test',
        -- Enam dari sepuluh pelanggan lahir dalam jendela lima tahun yang
        -- sama; sisanya tersebar di empat dekade. Gerombolan ini disengaja:
        -- tanpanya setiap pasangan (kota, lahir) unik dan Q24 kehilangan
        -- nuansanya.
        DATE '1960-01-01' + (CASE WHEN x.h % 100 < 60
                                  THEN 9000 + (x.h % 1826)
                                  ELSE x.h % 14600
                             END)::int,
        (ARRAY['Jakarta','Bandung','Surabaya','Medan','Makassar',
               'Semarang','Denpasar','Palembang','Yogyakarta','Balikpapan'])[((x.h / 14600) % 10)::int + 1],
        ((i % 9000) + 1000)::numeric,
        '62' || lpad((((i::bigint * 37) % 9999999999))::text, 10, '0'),
        'aktif',
        TIMESTAMPTZ '2024-01-01 00:00+07' + ((i % 700) || ' days')::interval
FROM generate_series(1, 30000) AS g(i)
-- h adalah pencampur deterministik: tanggal lahir dan kota tidak lagi
-- bergerak serentak dengan id, sehingga sebarannya tidak rata sempurna.
-- Tanpa ini setiap pasangan (kota, lahir) persis berisi dua orang dan
-- Q24 kehilangan kasus yang bisa diungkap.
CROSS JOIN LATERAL (SELECT ((g.i::bigint * 2654435761) % 2147483647) AS h) AS x;

CREATE INDEX pelanggan_tenant_idx ON lab11.pelanggan (tenant_id);
CREATE INDEX pelanggan_nama_idx   ON lab11.pelanggan (nama);

CREATE TABLE lab11.akun (
    akun_id    int PRIMARY KEY,
    tenant_id  int  NOT NULL REFERENCES lab11.tenant,
    pengguna   text NOT NULL UNIQUE,
    kata_sandi text,                       -- diisi hash pada Q19
    peran_app  text NOT NULL
);

INSERT INTO lab11.akun VALUES
    (1, 1, 'ani.koperasi',    NULL, 'operator'),
    (2, 1, 'budi.koperasi',   NULL, 'penyelia'),
    (3, 2, 'citra.sentosa',   NULL, 'operator'),
    (4, 3, 'dedi.harapan',    NULL, 'operator');

CREATE TABLE lab11.transaksi (
    transaksi_id  bigint PRIMARY KEY,
    tenant_id     int  NOT NULL REFERENCES lab11.tenant,
    pelanggan_id  int  NOT NULL REFERENCES lab11.pelanggan,
    jumlah        numeric(14,2) NOT NULL,
    jenis         text NOT NULL,
    terjadi_pada  timestamptz NOT NULL
);

-- Tepat empat transaksi per pelanggan: 30000 x 4 = 120000.
INSERT INTO lab11.transaksi (transaksi_id, tenant_id, pelanggan_id, jumlah, jenis, terjadi_pada)
SELECT  (p.id::bigint - 1) * 4 + k,
        p.tenant_id,
        p.id,
        (((p.id * k) % 5000) + 10)::numeric,
        (ARRAY['setor','tarik','transfer','biaya'])[k],
        p.dibuat_pada + ((k * 37) || ' hours')::interval
FROM lab11.pelanggan p
CROSS JOIN generate_series(1, 4) AS g(k);

CREATE INDEX transaksi_pelanggan_idx ON lab11.transaksi (pelanggan_id);

RESET ROLE;

-- =====================================================================
-- 4 - Hak eksplisit per tabel (hak minimum, bukan ALL)
-- =====================================================================
GRANT SELECT                         ON ALL TABLES IN SCHEMA lab11 TO app_read;
GRANT INSERT, UPDATE, DELETE         ON lab11.pelanggan, lab11.transaksi TO app_write;
GRANT SELECT                         ON lab11.pelanggan TO app_analitik;

-- Statistik supaya rencana eksekusi pada Reflektif B stabil.
ANALYZE lab11.tenant;
ANALYZE lab11.pelanggan;
ANALYZE lab11.akun;
ANALYZE lab11.transaksi;

-- =====================================================================
-- 5 - Verifikasi: angka inilah yang disalin ke laporan
-- =====================================================================
SELECT version();

SELECT (SELECT count(*) FROM lab11.tenant)    AS tenant,
       (SELECT count(*) FROM lab11.pelanggan) AS pelanggan,
       (SELECT count(*) FROM lab11.akun)      AS akun,
       (SELECT count(*) FROM lab11.transaksi) AS transaksi;
-- harapkan: 3 | 30000 | 4 | 120000

SELECT tenant_id, count(*) FROM lab11.pelanggan GROUP BY 1 ORDER BY 1;
-- harapkan tiap penyewa 10000

SELECT rolname,
       rolcanlogin AS bisa_login,
       rolsuper    AS superuser,
       rolbypassrls AS bypass_rls
FROM pg_roles
WHERE rolname IN ('skema_owner','app_read','app_write',
                  'app_laporan','app_portal','app_analitik','app_audit')
ORDER BY rolcanlogin, rolname;

SELECT tablename, tableowner
FROM pg_tables WHERE schemaname = 'lab11' ORDER BY tablename;

-- Pembanding untuk Q12: jumlah baris untuk pencarian nama biasa
-- pada penyewa 1, sebelum satu pun payload dijalankan.
SELECT count(*) AS q12_pembanding
FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%Pelanggan 12%';
