-- Diminta: view lab4.film_murah berisi film dengan rental_rate <= 0.99,
--          menampilkan film_id, title, rental_rate, rating, tanpa WITH CHECK OPTION.
-- Dipilih: view sederhana satu tabel tanpa check option agar sifat auto-updatable
--          bawaan PostgreSQL dan celah "baris menghilang" pada Q2 dapat dibuktikan.
-- Alternatif: langsung memasang WITH CHECK OPTION; tidak dipilih karena soal Q2
--          justru menuntut bukti apa yang terjadi ketika aturan view tidak ditegakkan.

SET search_path = lab4, public;

DROP VIEW IF EXISTS lab4.film_murah;

CREATE VIEW lab4.film_murah AS
SELECT film_id,
       title,
       rental_rate,
       rating
FROM lab4.film
WHERE rental_rate <= 0.99;

-- Bukti view terbentuk dan isinya masuk akal.
SELECT count(*) AS jumlah_film_murah FROM lab4.film_murah;
SELECT * FROM lab4.film_murah ORDER BY film_id LIMIT 5;

-- Bukti view ini auto-updatable menurut PostgreSQL.
SELECT table_name, is_insertable_into, is_updatable
FROM information_schema.views
WHERE table_schema = 'lab4' AND table_name = 'film_murah';