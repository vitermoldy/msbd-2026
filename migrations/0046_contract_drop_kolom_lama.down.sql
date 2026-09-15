
ALTER TABLE lab4.film ADD COLUMN rental_rate numeric(5,2);

-- Opsional: isi ulang dari harga_film (jika masih ada data historis)
UPDATE lab4.film f
SET rental_rate = (
    SELECT h.harga FROM lab4.harga_film h
    WHERE h.film_id = f.film_id AND h.wilayah = 'ID' AND upper(h.berlaku) IS NULL
);
