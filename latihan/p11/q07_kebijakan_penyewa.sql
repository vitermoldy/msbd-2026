-- Diminta: membuat sepasang kebijakan isolasi penyewa, memakai
--          nullif(current_setting('app.tenant', true), '')::int dan bukan
--          ::int langsung.
-- Dipilih: sebab pemakaian nullif dibuktikan lebih dulu dengan menjalankan
--          kedua bentuk cast pada app.tenant yang berisi string kosong,
--          sehingga alasannya berupa SQLSTATE dan bukan anjuran.
-- Alternatif: membuat kebijakan dengan ::int langsung lalu menunggu uji
--             negatif gagal; tidak dipilih karena galatnya muncul jauh dari
--             sebabnya dan menyesatkan anggota yang menjalankan ulang.

\set ON_ERROR_STOP off
\set VERBOSITY verbose

\echo === 7a. Mengapa nullif: app.tenant yang pernah dipakai berisi '' ===
BEGIN;
SET LOCAL app.tenant = '';
SELECT current_setting('app.tenant', true) AS nilai_mentah,
       length(current_setting('app.tenant', true)) AS panjang;
SELECT (current_setting('app.tenant', true))::int AS cast_langsung;
-- harapkan SQLSTATE 22P02: invalid input syntax for type integer: ""
ROLLBACK;

BEGIN;
SET LOCAL app.tenant = '';
SELECT nullif(current_setting('app.tenant', true), '')::int AS cast_dengan_nullif;
-- harapkan NULL, tanpa galat. Kebijakan yang memakai bentuk ini akan
-- membandingkan tenant_id dengan NULL, yang bernilai tidak-benar, sehingga
-- hasilnya nol baris: menolak, bukan membocorkan.
ROLLBACK;

\set ON_ERROR_STOP on

\echo === 7b. Sepasang kebijakan isolasi penyewa ===
DROP POLICY IF EXISTS p_tenant_baca  ON lab11.pelanggan;
DROP POLICY IF EXISTS p_tenant_tulis ON lab11.pelanggan;

CREATE POLICY p_tenant_baca ON lab11.pelanggan
    FOR SELECT TO app_read, app_write
    USING (tenant_id = nullif(current_setting('app.tenant', true), '')::int);

CREATE POLICY p_tenant_tulis ON lab11.pelanggan
    FOR ALL TO app_write
    USING      (tenant_id = nullif(current_setting('app.tenant', true), '')::int)
    WITH CHECK (tenant_id = nullif(current_setting('app.tenant', true), '')::int);

\echo === 7c. Kebijakan yang terpasang ===
SELECT policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'lab11' AND tablename = 'pelanggan'
ORDER BY policyname;

\echo === 7d. Kebijakan bersifat permissive: keduanya digabung dengan OR ===
-- Penting untuk Q11: menambah satu kebijakan permissive hanya dapat
-- MELEBARKAN akses, tidak pernah mempersempitnya.
SELECT count(*) AS jumlah_kebijakan,
       count(*) FILTER (WHERE permissive = 'PERMISSIVE') AS permissive,
       count(*) FILTER (WHERE permissive = 'RESTRICTIVE') AS restrictive
FROM pg_policies WHERE schemaname = 'lab11' AND tablename = 'pelanggan';
