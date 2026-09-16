-- Diminta: menampilkan semua bawahan langsung maupun tidak langsung dari
--          pegawai bernama Bima, beserta jarak masing-masing dari Bima.
-- Dipilih: recursive CTE dengan anchor yang disaring langsung pada nama
--          'Bima' (bukan pada atasan_id IS NULL seperti Q7), lalu jarak
--          dihitung mulai dari 0 untuk Bima sendiri dan bertambah satu
--          setiap turun satu tingkat. Baris Bima sendiri (jarak = 0)
--          dibuang di lapisan luar karena soal hanya minta bawahannya.
-- Alternatif: memfilter hasil Q7 (hierarki dari puncak) dengan mencari baris
--          yang jalurnya mengandung "Bima", lalu menghitung jarak dari posisi
--          "Bima" di string tersebut. Tidak dipilih karena rapuh -- pemrosesan
--          string untuk menentukan jarak jauh lebih rumit dan rawan salah
--          dibanding memulai rekursi langsung dari anchor Bima.

WITH RECURSIVE bawahan AS (
    -- anchor: Bima sendiri, jarak 0
    SELECT
        pegawai_id,
        nama,
        atasan_id,
        0 AS jarak
    FROM pegawai
    WHERE nama = 'Bima'

    UNION ALL

    -- recursive term: turun satu tingkat setiap iterasi
    SELECT
        p.pegawai_id,
        p.nama,
        p.atasan_id,
        b.jarak + 1
    FROM pegawai p
    JOIN bawahan b ON p.atasan_id = b.pegawai_id
)
SELECT
    pegawai_id,
    nama,
    jarak
FROM bawahan
WHERE jarak > 0
ORDER BY jarak, nama;
