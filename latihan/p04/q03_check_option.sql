-- Diminta: membuat ulang view dengan WITH CASCADED CHECK OPTION, mengulang penyisipan Q2,
--          lalu menyalin pesan galat secara utuh.
-- Dipilih: CASCADED (bukan LOCAL) agar seandainya kelak dibuat view lain di atas view ini,
--          predikat seluruh rantai tetap diperiksa, bukan hanya predikat lapisan terluar.
-- Alternatif: WITH LOCAL CHECK OPTION; tidak dipilih karena hanya memeriksa predikat view
--          ini sendiri dan meninggalkan celah yang sama begitu view ditumpuk.

SET search_path = lab4, public;

-- Bersihkan baris uji Q2 supaya bukti Q3 tidak tercampur.
DELETE FROM lab4.film WHERE film_id = 9001;

CREATE OR REPLACE VIEW lab4.film_murah AS
SELECT film_id,
       title,
       rental_rate,
       rating
FROM lab4.film
WHERE rental_rate <= 0.99
WITH CASCADED CHECK OPTION;

-- Penyisipan yang sama persis dengan Q2. Kali ini harus GAGAL.
INSERT INTO lab4.film_murah (film_id, title, rental_rate, rating)
VALUES (9001, 'FILM UJI SELISIH', 4.99, 'PG');

-- Penyisipan yang memenuhi predikat harus tetap berhasil.
INSERT INTO lab4.film_murah (film_id, title, rental_rate, rating)
VALUES (9002, 'FILM UJI LOLOS', 0.99, 'PG');

SELECT film_id, title, rental_rate FROM lab4.film_murah WHERE film_id IN (9001, 9002);