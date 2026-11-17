-- Diminta: dari session kedua, periksa pg_stat_activity ketika proses enkripsi
--          berjalan; tentukan apakah kunci/teks terang terlihat dan sebutkan
--          dua lokasi kebocoran lain.
-- Dipilih: inspeksi aktivitas session lain tanpa menampilkan query session ini.
-- Alternatif: menganggap ciphertext otomatis melindungi kunci di luar tabel.

\set ON_ERROR_STOP on

-- Jalankan query ini dari SESSION KEDUA ketika UPDATE enkripsi Q21 sedang berjalan.
-- pg_stat_activity hanya memperlihatkan teks query aktif; hasil bergantung pada
-- hak statistik dan timing pengamatan. Jangan menaruh kunci literal pada query
-- UPDATE yang berjalan lama.
SELECT
    pid,
    usename,
    application_name,
    state,
    wait_event_type,
    wait_event,
    query
FROM pg_stat_activity
WHERE datname = current_database()
  AND pid <> pg_backend_pid()
ORDER BY query_start;

-- Pemeriksaan tambahan: apakah statistik aktivitas dapat dibaca oleh session ini?
SELECT
    current_user AS pemeriksa,
    has_database_privilege(current_user, current_database(), 'CONNECT') AS dapat_connect;

-- Dua lokasi lain yang perlu diaudit: log PostgreSQL (log_statement/log_min_duration_statement)
-- dan log/debug aplikasi (parameter query, exception, tracing, atau telemetry).
