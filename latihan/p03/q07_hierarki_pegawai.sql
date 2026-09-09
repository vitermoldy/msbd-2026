-- Diminta: menampilkan seluruh pegawai beserta level kedalaman dan jalur
--          jabatan dari puncak, misalnya "Rina > Bima > Toni".
-- Dipilih: recursive CTE dengan anchor pegawai yang atasan_id IS NULL
--          (pegawai puncak). Recursive term mencari pegawai yang atasan_id-nya
--          cocok dengan pegawai_id pada baris hasil iterasi sebelumnya, sambil
--          menambah level dan menyambung string jalur.
-- Alternatif: query self-join berulang dengan jumlah level tetap (misalnya
--          LEFT JOIN pegawai ke pegawai sebanyak 3-4 kali). Tidak dipilih
--          karena kedalaman hierarki organisasi tidak diketahui pasti di awal,
--          dan recursive CTE otomatis berhenti saat tidak ada baris anak lagi.

WITH RECURSIVE hierarki AS (
    -- anchor: pegawai puncak
    SELECT
        pegawai_id,
        nama,
        atasan_id,
        1 AS level,
        nama::text AS jalur
    FROM pegawai
    WHERE atasan_id IS NULL

    UNION ALL

    -- recursive term: cari bawahan langsung dari baris yang baru dihasilkan
    SELECT
        p.pegawai_id,
        p.nama,
        p.atasan_id,
        h.level + 1,
        h.jalur || ' > ' || p.nama
    FROM pegawai p
    JOIN hierarki h ON p.atasan_id = h.pegawai_id
)
SELECT
    pegawai_id,
    nama,
    level,
    jalur
FROM hierarki
ORDER BY jalur;
