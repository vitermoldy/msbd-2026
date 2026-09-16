-- Diminta: view lab4.pendapatan_kategori yang memakai GROUP BY, mencoba menyisipkan satu
--          baris lewat view, mencatat pesan galat, dan menjelaskan sebab tidak auto-updatable.
-- Dipilih: agregasi per kategori dengan join ke public.film_category dan public.category,
--          karena bentuk ini realistis sebagai laporan sekaligus jelas melanggar dua syarat
--          auto-updatable sekaligus: ada join dan ada GROUP BY.
-- Alternatif: view dengan DISTINCT saja; tidak dipilih karena hanya menunjukkan satu sebab
--          dan tidak menyerupai view laporan yang benar-benar dipakai tim.

SET search_path = lab4, public;

DROP VIEW IF EXISTS lab4.pendapatan_kategori;

CREATE VIEW lab4.pendapatan_kategori AS
SELECT c.name                        AS kategori,
       count(*)                      AS jumlah_film,
       round(avg(f.rental_rate), 2)  AS rata_tarif,
       sum(f.rental_rate)            AS total_tarif
FROM lab4.film f
JOIN public.film_category fc ON fc.film_id = f.film_id
JOIN public.category      c  ON c.category_id = fc.category_id
GROUP BY c.name;

SELECT * FROM lab4.pendapatan_kategori ORDER BY total_tarif DESC LIMIT 5;

-- Bukti dari katalog: view ini tidak dapat disisipi.
SELECT table_name, is_insertable_into, is_updatable
FROM information_schema.views
WHERE table_schema = 'lab4' AND table_name = 'pendapatan_kategori';

-- Penyisipan yang harus GAGAL.
INSERT INTO lab4.pendapatan_kategori (kategori, jumlah_film, rata_tarif, total_tarif)
VALUES ('Kategori Uji', 1, 1.00, 1.00);