SELECT id, nama, kota
FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%Pelanggan 12%';
