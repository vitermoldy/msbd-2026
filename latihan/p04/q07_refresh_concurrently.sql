-- Diminta: mencoba REFRESH CONCURRENTLY tanpa index unik, menyalin galatnya, membuat index unik
--          yang mencakup seluruh baris, mengulang refresh concurrent, dan menjelaskan mengapa lebih lambat.
-- Dipilih: UNIQUE INDEX pada (bulan, kanal) karena kombinasi itulah kunci GROUP BY matview,
--          sehingga dijamin unik untuk setiap baris hasil dan tidak memakai klausa WHERE.
-- Alternatif: index unik pada (bulan) saja; tidak dipilih karena satu bulan punya empat kanal,
--          sehingga index gagal dibuat dan refresh concurrent tetap mustahil.

\timing on
SET search_path = lab4, public;

-- Percobaan pertama tanpa index unik. Harus GAGAL.
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;

-- Index unik tanpa WHERE, mencakup seluruh baris matview.
CREATE UNIQUE INDEX ux_ringkasan_akses ON lab4.ringkasan_akses (bulan, kanal);

-- Ulangi refresh concurrent. Catat waktunya.
REFRESH MATERIALIZED VIEW CONCURRENTLY lab4.ringkasan_akses;

-- Refresh biasa sekali lagi sebagai pembanding pada kondisi data yang sama.
REFRESH MATERIALIZED VIEW lab4.ringkasan_akses;