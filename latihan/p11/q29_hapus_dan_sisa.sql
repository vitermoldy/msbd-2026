-- Diminta: catat satu permintaan penghapusan, hapus transaksi lalu pelanggan, dan hitung sisa data.
-- Dipilih: hapus transaksi anak sebelum pelanggan induk agar foreign key tetap dipatuhi; audit menyimpan bukti perubahan.
-- Alternatif: menghapus pelanggan lebih dahulu atau menonaktifkan foreign key; tidak dipilih karena merusak integritas referensial.

\set ON_ERROR_STOP on

-- Jalankan sebagai postgres/superuser lab agar proses penghapusan permintaan subjek
-- tidak terhalang RLS. ID 12 dan 13 adalah data sintetis tenant 1.
INSERT INTO lab11.permintaan_hapus (subjek_ids, alasan)
VALUES (ARRAY[12,13], 'Permintaan penghapusan untuk demonstrasi Q29')
RETURNING permintaan_id, subjek_ids, diterima_pada, tenggat;

-- Hapus baris anak terlebih dahulu karena transaksi memiliki FK ke pelanggan.
DELETE FROM lab11.transaksi
WHERE pelanggan_id IN (12,13);

-- Hapus pelanggan. Trigger Q25 akan merekam nilai lama, termasuk NIK.
DELETE FROM lab11.pelanggan
WHERE id IN (12,13);

UPDATE lab11.permintaan_hapus
SET status = 'selesai', selesai_pada = now()
WHERE permintaan_id = (
    SELECT max(permintaan_id) FROM lab11.permintaan_hapus
);

-- Tiga angka yang wajib dilaporkan.
SELECT count(*) AS sisa_tabel_utama
FROM lab11.pelanggan WHERE id IN (12,13);

SELECT count(*) AS sisa_transaksi
FROM lab11.transaksi WHERE pelanggan_id IN (12,13);

SELECT count(*) AS sisa_jejak_audit
FROM lab11.jejak_audit
WHERE kunci IN ('12', '13') AND nilai_lama ? 'nik';

-- Tampilkan bukti audit penghapusan tanpa menyalin NIK ke laporan.
SELECT audit_id, waktu, pelaku, aksi, nama_tabel, kunci,
       (nilai_lama ? 'nik') AS nik_lama_tercatat
FROM lab11.jejak_audit
WHERE kunci IN ('12', '13')
ORDER BY audit_id;
