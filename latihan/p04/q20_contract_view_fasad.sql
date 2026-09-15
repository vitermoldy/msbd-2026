-- Diminta: Buat view fasad untuk mempertahankan kompatibilitas aplikasi lama,
--          lalu drop kolom rental_rate dari tabel film.
-- Dipilih: Membuat view lab4.film_lama yang mengambil harga terbaru dari harga_film,
--          kemudian menghapus kolom rental_rate setelah dipastikan aman.
-- Alternatif: Menyimpan kolom rental_rate sebagai kolom cadangan; tidak dipilih karena
--             melanggar prinsip single source of truth dan memboroskan storage.

-- 1. Buat View Fasad (Kompatibilitas Aplikasi Lama)
CREATE OR REPLACE VIEW lab4.film_lama AS
SELECT
    f.film_id,
    f.title,
    -- Mengambil harga aktif terbaru dari tabel baru
    (SELECT h.harga FROM lab4.harga_film h
     WHERE h.film_id = f.film_id
       AND h.wilayah = 'ID'
       AND upper(h.berlaku) IS NULL
     LIMIT 1) AS rental_rate,
    f.rating
FROM lab4.film f;

-- 2. Hapus Trigger Tulis Ganda (Sudah tidak perlu karena kolom lama akan hilang)
DROP TRIGGER IF EXISTS trg_sync_harga ON lab4.film;
DROP FUNCTION IF EXISTS lab4.sync_harga_film();

-- 3. Drop Kolom Lama (Contract)
-- PERINGATAN: Pastikan aplikasi sudah pointing ke view 'film_lama' atau struktur baru!
ALTER TABLE lab4.film DROP COLUMN rental_rate;
