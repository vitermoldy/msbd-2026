DO $$
BEGIN
    IF EXISTS (
        SELECT 1 FROM lab4.film f
        WHERE NOT EXISTS (
            SELECT 1 FROM lab4.harga_film h
            WHERE h.film_id = f.film_id AND h.wilayah = 'ID' AND upper(h.berlaku) IS NULL
        )
    ) THEN
        RAISE EXCEPTION 'Verifikasi gagal: masih ada film tanpa harga aktif di tabel baru';
    END IF;
END $$;
