-- Diminta: membuat siklus pada data pegawai, mengamati bahwa Q7 tidak
--          berhenti, lalu memperbaiki query agar tahan siklus dan
--          mengembalikan data ke keadaan semula setelah pengujian.
-- Dipilih: menambahkan kolom array jalur_id yang mengumpulkan seluruh
--          pegawai_id yang sudah dilewati sepanjang rekursi. Recursive term
--          hanya melanjutkan ke baris yang pegawai_id-nya BELUM ada di
--          jalur_id (NOT (... = ANY(...))). Begitu rekursi akan kembali ke
--          pegawai yang sudah pernah dilewati, baris itu tidak lagi
--          dihasilkan, sehingga rekursi berhenti dengan sendirinya.
-- Alternatif: klausa CYCLE bawaan PostgreSQL 17
--          (... CYCLE pegawai_id SET is_cycle USING jalur_id). Tidak dipilih
--          sebagai jawaban utama karena sintaksnya lebih ringkas tapi
--          menyembunyikan mekanismenya di balik kata kunci -- untuk latihan
--          ini pelacakan array eksplisit lebih jelas menunjukkan *mengapa*
--          rekursi berhenti, bukan cuma *bahwa* ia berhenti.

-- =====================================================================
-- PROSEDUR UJI (jalankan manual, satu per satu -- JANGAN dieksekusi
-- sekaligus sebagai satu berkas otomatis, supaya setiap tahap bisa diamati)
-- =====================================================================

-- 1) Buat siklus:
-- UPDATE pegawai SET atasan_id = 6 WHERE pegawai_id = 1;

-- 2) Jalankan Q7 (versi TANPA pengaman) di sesi terpisah untuk mengamati
--    bahwa ia tidak pernah berhenti. Siapkan Ctrl-C. Jika container tidak
--    responsif setelahnya: docker compose restart postgres

-- 3) Jalankan query cycle-safe di bawah ini pada data yang masih bersiklus
--    untuk membuktikan ia berhenti dengan aman.

-- 4) Setelah pengujian selesai, WAJIB kembalikan data:
-- UPDATE pegawai SET atasan_id = NULL WHERE pegawai_id = 1;

-- =====================================================================
-- QUERY CYCLE-SAFE
-- =====================================================================

WITH RECURSIVE hierarki AS (
    SELECT
        pegawai_id,
        nama,
        atasan_id,
        1 AS level,
        nama::text AS jalur,
        ARRAY[pegawai_id] AS jalur_id
    FROM pegawai
    WHERE atasan_id IS NULL

    UNION ALL

    SELECT
        p.pegawai_id,
        p.nama,
        p.atasan_id,
        h.level + 1,
        h.jalur || ' > ' || p.nama,
        h.jalur_id || p.pegawai_id
    FROM pegawai p
    JOIN hierarki h ON p.atasan_id = h.pegawai_id
    WHERE NOT (p.pegawai_id = ANY(h.jalur_id))
)
SELECT
    pegawai_id,
    nama,
    level,
    jalur
FROM hierarki
ORDER BY jalur;
