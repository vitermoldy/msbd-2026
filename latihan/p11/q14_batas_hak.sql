\set VERBOSITY verbose

BEGIN;
SET LOCAL ROLE app_laporan;
SET LOCAL app.tenant = '1';

SELECT count(*) AS total_bocor_via_app_laporan
FROM lab11.pelanggan
WHERE tenant_id = 1 AND nama ILIKE '%zz' OR '1'='1' --%';

UPDATE lab11.pelanggan SET kota = 'Medan' WHERE id = 1;

ROLLBACK;
