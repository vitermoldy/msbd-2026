-- Diminta: buat tabel ulasan dengan foreign key ke film, uji perilaku NO ACTION, CASCADE, dan SET NULL jika film dihapus.
-- Dipilih: tiga film uji berbeda agar ketiga perilaku dapat diuji.
-- Alternatif: satu film untuk semua pengujian; tidak dianjurkan karena CASCADE dapat menghapus data anak yang sedang diuji.

SET search_path = lab4, public;

DROP TABLE IF EXISTS lab4.ulasan CASCADE;

CREATE TABLE lab4.ulasan (
    ulasan_id bigserial PRIMARY KEY,
    film_id integer,
    isi text NOT NULL
);

INSERT INTO lab4.film
    (film_id, title, rental_rate, rating)
VALUES
    (9201, 'FILM UJI NO ACTION', 2.99, 'PG'),
    (9202, 'FILM UJI CASCADE', 2.99, 'PG'),
    (9203, 'FILM UJI SET NULL', 2.99, 'PG');

-- Pengujian NO ACTION.
ALTER TABLE lab4.ulasan
ADD CONSTRAINT fk_ulasan_film
FOREIGN KEY (film_id)
REFERENCES lab4.film(film_id)
ON DELETE NO ACTION;

INSERT INTO lab4.ulasan (film_id, isi)
VALUES (9201, 'Ulasan NO ACTION');

DELETE FROM lab4.film
WHERE film_id = 9201;

ALTER TABLE lab4.ulasan
DROP CONSTRAINT fk_ulasan_film;

-- Pengujian CASCADE.
ALTER TABLE lab4.ulasan
ADD CONSTRAINT fk_ulasan_film
FOREIGN KEY (film_id)
REFERENCES lab4.film(film_id)
ON DELETE CASCADE;

INSERT INTO lab4.ulasan (film_id, isi)
VALUES (9202, 'Ulasan CASCADE');

DELETE FROM lab4.film
WHERE film_id = 9202;

SELECT *
FROM lab4.ulasan
WHERE film_id = 9202;

ALTER TABLE lab4.ulasan
DROP CONSTRAINT fk_ulasan_film;

-- Pengujian SET NULL.
ALTER TABLE lab4.ulasan
ADD CONSTRAINT fk_ulasan_film
FOREIGN KEY (film_id)
REFERENCES lab4.film(film_id)
ON DELETE SET NULL;

INSERT INTO lab4.ulasan (film_id, isi)
VALUES (9203, 'Ulasan SET NULL');

DELETE FROM lab4.film
WHERE film_id = 9203;

SELECT *
FROM lab4.ulasan
WHERE isi = 'Ulasan SET NULL';