-- Menampilkan seluruh notifikasi berstatus lunas beserta nomor transaksi,kota pelanggan, dan jumlah sebagai angka.
-- Menggunakan ->> untuk mengambil nilai JSONB dan @> untuk memfilter status.
-- Menambahkan indeks GIN pada payload untuk mendukung pencarian JSONB.

CREATE INDEX idx_notifikasi_payload_gin
ON notifikasi USING GIN (payload);

SELECT
    payload ->> 'trx' AS trx,
    payload -> 'pelanggan' ->> 'kota' AS kota,
    (payload ->> 'jumlah')::numeric AS jumlah
FROM notifikasi
WHERE payload @> '{"status":"lunas"}';