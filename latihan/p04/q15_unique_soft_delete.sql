-- Diminta: tambahkan deleted_at, buktikan UNIQUE biasa pada title menghalangi pendaftaran ulang judul yang sudah soft-delete, lalu menggantinya dengan unique index parsial.
-- Dipilih: film_id 9102 dan 9103 sebagai data uji.
-- Alternatif: langsung menggunakan unique index parsial; tidak dianjurkan karena tugas mau pembuktian masalah UNIQUE biasa.

SET search_path = lab4, public;

ALTER TABLE lab4.film
ADD COLUMN IF NOT EXISTS deleted_at timestamptz;

ALTER TABLE lab4.film
DROP CONSTRAINT IF EXISTS film_judul_unik;

DROP INDEX IF EXISTS ux_film_judul_aktif;

DELETE FROM lab4.film
WHERE film_id IN (9102, 9103);

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