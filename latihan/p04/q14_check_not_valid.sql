-- Diminta: menambahkan CHECK bahwa rental_rate tidak boleh negatif melalui NOT VALID lalu VALIDATE. Lalu coba masukkan data negatif untuk membuktikan validasi gagal, kemudian diperbaiki dan divalidasi ulang.
-- Dipilih: film_id 9101 jadi data uji agar data film asli tidak terganggu.
-- Alternatif: langsung membuat CHECK tanpa NOT VALID; tidak dianjurkan karena soal mau pembuktian proses validasi bertahap.

SET search_path = lab4, public;

ALTER TABLE lab4.film
DROP CONSTRAINT IF EXISTS film_rental_rate_nonneg;

INSERT INTO lab4.film
    (film_id, title, rental_rate, rating)
VALUES
    (9101, 'FILM UJI NEGATIF', -1.00, 'PG');

ALTER TABLE lab4.film
ADD CONSTRAINT film_rental_rate_nonneg
CHECK (rental_rate >= 0) NOT VALID;

SELECT conname, convalidated
FROM pg_constraint
WHERE conrelid = 'lab4.film'::regclass
  AND conname = 'film_rental_rate_nonneg';

ALTER TABLE lab4.film
VALIDATE CONSTRAINT film_rental_rate_nonneg;

UPDATE lab4.film
SET rental_rate = 1.00
WHERE film_id = 9101;

ALTER TABLE lab4.film
VALIDATE CONSTRAINT film_rental_rate_nonneg;

SELECT film_id, title, rental_rate
FROM lab4.film
WHERE film_id = 9101;