-- Diminta: menyisipkan satu film lewat view dengan rental_rate = 4.99, mencatat keluaran
--          PostgreSQL, lalu menghitung baris berjudul sama pada view dan pada tabel dasar.
-- Dipilih: satu INSERT lewat view dengan film_id sendiri (9001) agar baris uji mudah
--          ditemukan kembali dan mudah dibersihkan tanpa mengganggu 1000 film asli.
-- Alternatif: menyisipkan lewat tabel dasar lalu membandingkan; tidak dipilih karena
--          tidak membuktikan apa pun tentang perilaku view tanpa check option.

SET search_path = lab4, public;

-- Penyisipan dilakukan LEWAT VIEW, bukan lewat tabel.
INSERT INTO lab4.film_murah (film_id, title, rental_rate, rating)
VALUES (9001, 'FILM UJI SELISIH', 4.99, 'PG');

-- Hitung di view dan di tabel dasar.
SELECT 'view'  AS sumber, count(*) AS jumlah
FROM lab4.film_murah WHERE title = 'FILM UJI SELISIH'
UNION ALL
SELECT 'tabel' AS sumber, count(*) AS jumlah
FROM lab4.film       WHERE title = 'FILM UJI SELISIH';

-- Baris itu memang ada, dan memang di luar predikat view.
SELECT film_id, title, rental_rate FROM lab4.film WHERE film_id = 9001;