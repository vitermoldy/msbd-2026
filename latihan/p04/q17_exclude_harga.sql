-- Diminta: buat tabel harga film dengan constraint EXCLUDE jadi periode harga film dan wilayah yang sama tidak tumpang tindih. Dibuktikan dengan satu INSERT diterima dan satu INSERT ditolak.
-- Dipilih: daterange & btree_gist dari ketentuan tugas.
-- Alternatif: trigger untuk mengecek bentrokan periode; tidak dianjurkan karena tugas mau penggunaan constraint EXCLUDE.

SET search_path = lab4, public;

CREATE EXTENSION IF NOT EXISTS btree_gist;

DROP TABLE IF EXISTS lab4.harga_film CASCADE;

CREATE TABLE lab4.harga_film (
    harga_film_id bigserial PRIMARY KEY,
    film_id integer NOT NULL REFERENCES lab4.film (film_id),
    wilayah text NOT NULL,
    harga numeric(5,2) NOT NULL CHECK (harga >= 0),
    berlaku daterange NOT NULL,

    EXCLUDE USING gist (
        film_id WITH =,
        wilayah WITH =,
        berlaku WITH &&
    )
);

INSERT INTO lab4.harga_film
    (film_id, wilayah, harga, berlaku)
VALUES
    (1, 'Indonesia', 10.00,
     daterange('2026-01-01', '2026-02-01', '[)'));

INSERT INTO lab4.harga_film
    (film_id, wilayah, harga, berlaku)
VALUES
    (1, 'Indonesia', 12.00,
     daterange('2026-01-15', '2026-02-15', '[)'));

SELECT *
FROM lab4.harga_film;