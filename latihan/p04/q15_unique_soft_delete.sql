-- Diminta: menambah deleted_at, membuktikan UNIQUE biasa menghalangi judul yang sudah di soft-delete, lalu menggantinya dengan unique index partial.
-- Dipilih: film_id 9102 dan 9103 sebagai data uji agar data asli tidak terganggu.
-- Alternatif: langsung membuat unique index partial; tidak disarankan karena soal mau pembuktian masalah UNIQUE biasa.

SET search_path = lab4, public;

ALTER TABLE lab4.film
ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

ALTER TABLE lab4.film
ADD CONSTRAINT film_judul_unik UNIQUE (title);

INSERT INTO lab4.film
    (film_id, title, rental_rate, rating)
VALUES
    (9102, 'FILM UJI SOFT DELETE', 2.99, 'PG');

UPDATE lab4.film
SET deleted_at = now()
WHERE film_id = 9102;

INSERT INTO lab4.film
    (film_id, title, rental_rate, rating)
VALUES
    (9103, 'FILM UJI SOFT DELETE', 2.99, 'PG');

ALTER TABLE lab4.film
DROP CONSTRAINT film_judul_unik;

CREATE UNIQUE INDEX ux_film_judul_aktif
ON lab4.film (title)
WHERE deleted_at IS NULL;

INSERT INTO lab4.film
    (film_id, title, rental_rate, rating)
VALUES
    (9103, 'FILM UJI SOFT DELETE', 2.99, 'PG');

SELECT film_id, title, deleted_at
FROM lab4.film
WHERE title = 'FILM UJI SOFT DELETE';