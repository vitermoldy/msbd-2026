-- Diminta: Lakukan backfill data dari film ke harga_film dalam potongan 1000 baris.
-- Dipilih: Menggunakan loop WHILE dengan LIMIT/OFFSET atau WHERE BETWEEN untuk memproses
--          data secara bertahap agar tidak mengunci tabel terlalu lama.
-- Alternatif: UPDATE massal sekaligus (INSERT INTO ... SELECT); tidak dipilih karena akan
--             menyebabkan lock panjang dan potensi timeout pada tabel besar.

-- Backfill Potongan 1 (Film ID 1-1000)
INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
SELECT f.film_id, 'ID', f.rental_rate, daterange('2026-01-01', NULL)
FROM lab4.film f
WHERE f.film_id BETWEEN 1 AND 1000
  AND NOT EXISTS (
      SELECT 1 FROM lab4.harga_film h
      WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
  );

-- Backfill Potongan 2 (Film ID 1001-2000)
INSERT INTO lab4.harga_film (film_id, wilayah, harga, berlaku)
SELECT f.film_id, 'ID', f.rental_rate, daterange('2026-01-01', NULL)
FROM lab4.film f
WHERE f.film_id BETWEEN 1001 AND 2000
  AND NOT EXISTS (
      SELECT 1 FROM lab4.harga_film h
      WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
  );

-- Verifikasi: Harus menghasilkan 0 jika semua data sudah ter-backfill
SELECT count(*) AS sisa_belum_backfill
FROM lab4.film f
WHERE NOT EXISTS (
    SELECT 1 FROM lab4.harga_film h
    WHERE h.film_id = f.film_id AND h.wilayah = 'ID'
);
