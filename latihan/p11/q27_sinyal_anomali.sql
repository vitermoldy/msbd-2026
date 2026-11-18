-- Diminta: membuat tiga query sinyal anomali dari jejak audit.
-- Dipilih: agregasi jumlah kejadian per pelaku, pemeriksaan jam lokal Jakarta, dan ringkasan aksi.
-- Alternatif: menganggap satu kejadian sebagai bukti penyalahgunaan; tidak dipilih karena anomali perlu konteks dan ambang yang ditinjau.

\set ON_ERROR_STOP on

-- 1. Lonjakan jumlah baris yang disentuh per pelaku per jam.
SELECT
    pelaku,
    date_trunc('hour', waktu) AS jam,
    count(*) AS jumlah_perubahan
FROM lab11.jejak_audit
GROUP BY pelaku, date_trunc('hour', waktu)
HAVING count(*) >= 2
ORDER BY jumlah_perubahan DESC, jam DESC;

-- 2. Aktivitas di luar jam kerja lokal (sebelum 08.00 atau mulai 17.00).
SELECT
    audit_id,
    waktu,
    waktu AT TIME ZONE 'Asia/Jakarta' AS waktu_jakarta,
    pelaku, aksi, nama_tabel, kunci
FROM lab11.jejak_audit
WHERE EXTRACT(HOUR FROM (waktu AT TIME ZONE 'Asia/Jakarta')) < 8
   OR EXTRACT(HOUR FROM (waktu AT TIME ZONE 'Asia/Jakarta')) >= 17
ORDER BY waktu DESC;

-- 3. Ringkasan aksi per pelaku dan jenis operasi.
SELECT pelaku, aksi, nama_tabel, count(*) AS jumlah
FROM lab11.jejak_audit
GROUP BY pelaku, aksi, nama_tabel
ORDER BY pelaku, aksi, nama_tabel;
