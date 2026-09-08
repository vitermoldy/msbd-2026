-- Diminta: judul film yang tarif sewanya di atas rata-rata tarif seluruh film,
--          beserta tarif, nilai rata-rata, dan selisihnya, diurutkan menurun.
-- Dipilih: subquery skalar. Rata-rata seluruh film adalah satu nilai tunggal
--          yang tidak bergantung pada baris yang sedang diperiksa, sehingga
--          cukup ditulis sebagai subquery tanpa korelasi.
-- Alternatif: CTE yang menghitung rata-rata lebih dulu; tidak dipilih karena
--          alurnya hanya satu langkah, dan CTE menambah lapisan tanpa
--          menambah kejelasan.

SELECT f.title,
       f.rental_rate,
       (SELECT round(avg(rental_rate), 2) FROM film) AS rata_rata,
       round(f.rental_rate - (SELECT avg(rental_rate) FROM film), 2) AS selisih
FROM film f
WHERE f.rental_rate > (SELECT avg(rental_rate) FROM film)
ORDER BY f.rental_rate DESC, f.title;

-- Hasil: 659 baris