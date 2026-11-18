-- Diminta: sebagai app_portal penyewa 1, lakukan UPDATE dan DELETE uji; buktikan aplikasi tidak dapat membaca atau memalsukan audit.
-- Dipilih: login langsung sebagai app_portal, SET LOCAL app.tenant='1', lalu hapus baris uji yang baru dibuat tanpa transaksi.
-- Alternatif: SET ROLE app_portal dari postgres; tidak dipilih karena session_user akan tetap postgres dan pelaku audit menjadi keliru.

\set ON_ERROR_STOP off

-- WAJIB: jalankan file ini dengan koneksi LOGIN app_portal, bukan SET ROLE.
BEGIN;
SET LOCAL app.tenant = '1';

-- Buat satu baris uji tenant 1 yang tidak memiliki transaksi.
INSERT INTO lab11.pelanggan
    (id, tenant_id, nama, nik, surel, lahir, kota, saldo, rekening, status, dibuat_pada)
VALUES
    (30001, 1, 'Pelanggan Uji Q26',
     '1111222233334444', 'uji-q26@contoh.test',
     DATE '2000-01-01', 'Medan', 1000.00, '620000000001',
     'uji', clock_timestamp());

-- Update satu baris milik tenant 1.
UPDATE lab11.pelanggan
SET kota = 'Medan-Q26-uji'
WHERE id = 3 AND tenant_id = 1;

-- Hapus baris uji yang baru dibuat; baris ini memang belum memiliki transaksi.
DELETE FROM lab11.pelanggan
WHERE id = 30001 AND tenant_id = 1
RETURNING id;

COMMIT;

-- Dua uji negatif berikut harus gagal dengan SQLSTATE 42501.
-- ON_ERROR_STOP off sengaja dipakai agar kedua penolakan terlihat.
SELECT * FROM lab11.jejak_audit ORDER BY audit_id DESC LIMIT 5;

INSERT INTO lab11.jejak_audit
    (audit_id, pelaku, aksi, nama_tabel, kunci)
VALUES
    (99999999, 'palsu', 'DELETE', 'lab11.pelanggan', '3');
