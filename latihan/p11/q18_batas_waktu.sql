\set VERBOSITY verbose

ALTER ROLE app_portal SET statement_timeout = '5s';

SELECT rolname, rolconfig
FROM pg_roles
WHERE rolname = 'app_portal';

BEGIN;
SET LOCAL statement_timeout = '5s';
SELECT pg_sleep(6);
ROLLBACK;
