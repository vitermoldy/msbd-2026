-- Diminta: buat view tersamar untuk app_analitik tanpa security_invoker;
--          cabut pg_read_all_data dan buktikan SELECT langsung ke tabel ditolak.
-- Dipilih: view security_invoker=false yang dimiliki postgres (superuser lab),
--          sehingga hak baca tabel berasal dari pemilik view, bukan analis.
-- Alternatif: security_invoker=true atau memberi SELECT tabel asli kepada analis.

\set ON_ERROR_STOP off

-- Q9 memberi pg_read_all_data kepada app_analitik; hak itu harus dicabut dahulu.
REVOKE pg_read_all_data FROM app_analitik;
ALTER ROLE app_analitik NOBYPASSRLS;
REVOKE ALL ON lab11.pelanggan FROM app_analitik;

-- PENTING: jalankan bagian CREATE VIEW sebagai postgres/superuser lab.
-- Karena FORCE RLS aktif dan tidak ada policy untuk skema_owner, view yang
-- dimiliki skema_owner dapat menghasilkan 0 baris. Pemilik postgres di lab
-- ini melewati RLS; karena itu hak pemilik view harus sangat dibatasi.
DROP VIEW IF EXISTS lab11.v_pelanggan_samar;
CREATE VIEW lab11.v_pelanggan_samar
WITH (security_invoker = false)
AS
SELECT
    id,
    tenant_id,
    left(nama, 1) || repeat('*', greatest(length(nama) - 1, 0)) AS nama,
    'xxxxxxxxxxxx' || right(nik, 4) AS nik,
    regexp_replace(surel, '^[^@]+', '****') AS surel,
    date_trunc('year', lahir)::date AS lahir,
    kota,
    round(saldo, -5) AS saldo
FROM lab11.pelanggan;

GRANT SELECT ON lab11.v_pelanggan_samar TO app_analitik;

-- Uji positif: SELECT view seharusnya berhasil.
SET ROLE app_analitik;
SELECT * FROM lab11.v_pelanggan_samar ORDER BY id LIMIT 5;

-- Uji negatif: SELECT tabel asli seharusnya gagal dengan SQLSTATE 42501.
SELECT * FROM lab11.pelanggan LIMIT 1;

RESET ROLE;
\set ON_ERROR_STOP on
