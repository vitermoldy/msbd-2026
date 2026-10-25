-- 1. Coba set status menjadi EXPIRED
UPDATE lab5.rental_tx SET status = 'EXPIRED' WHERE rental_id = 1;

-- 2. Tambahkan nilai EXPIRED ke ENUM
ALTER TYPE lab5.rental_status ADD VALUE 'EXPIRED';

-- 3. Ulangi set status menjadi EXPIRED
UPDATE lab5.rental_tx SET status = 'EXPIRED' WHERE rental_id = 1;

-- Cek hasilnya
SELECT rental_id, status FROM lab5.rental_tx WHERE rental_id = 1;