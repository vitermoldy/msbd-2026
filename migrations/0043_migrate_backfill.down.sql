DELETE FROM lab4.harga_film
WHERE berlaku @> '2026-01-01'::date;
