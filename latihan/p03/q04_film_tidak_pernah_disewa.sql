-- Diminta: judul film yang tidak pernah disewa, ditulis dalam dua versi,
--          NOT IN dan NOT EXISTS, lalu dibandingkan hasilnya.
-- Dipilih: NOT EXISTS sebagai bentuk utama, karena aman terhadap NULL pada
--          kolom yang dibandingkan.
-- Alternatif: NOT IN; ditulis sebagai pembanding, tidak dijadikan bentuk utama
--          karena satu NULL saja di dalam daftar membuat seluruh hasil menjadi
--          kosong tanpa pesan galat apa pun.

-- Versi A: NOT IN
SELECT f.title
FROM film f
WHERE f.film_id NOT IN (
    SELECT i.film_id
    FROM inventory i
    JOIN rental r ON r.inventory_id = i.inventory_id
)
ORDER BY f.title;

-- Versi B: NOT EXISTS
SELECT f.title
FROM film f
WHERE NOT EXISTS (
    SELECT 1
    FROM inventory i
    JOIN rental r ON r.inventory_id = i.inventory_id
    WHERE i.film_id = f.film_id
)
ORDER BY f.title;

-- Hasil: 42 baris (kedua versi memberi hasil identik)