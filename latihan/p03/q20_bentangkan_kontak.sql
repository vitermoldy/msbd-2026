-- Membentangkan array kontak menjadi satu baris untuk setiap kontak.
-- Menampilkan nomor transaksi, jenis kontak, dan nomor kontak.
-- Menggunakan jsonb_array_elements dengan LEFT JOIN LATERAL agar notifikasi dengan array kontak kosong tetap muncul.

SELECT
    n.payload ->> 'trx' AS trx,
    kontak ->> 'jenis' AS jenis_kontak,
    kontak ->> 'nomor' AS nomor_kontak
FROM notifikasi n
LEFT JOIN LATERAL jsonb_array_elements(n.payload -> 'kontak') AS c(kontak)
    ON true
ORDER BY n.notifikasi_id;