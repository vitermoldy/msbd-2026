PREPARE cari_aman (text) AS
SELECT id, nama, kota
FROM lab11.pelanggan
WHERE nama ILIKE $1
LIMIT 100;

EXECUTE cari_aman('%zz'' OR ''1''=''1'' --%');

DEALLOCATE cari_aman;
