CREATE INDEX ev_salah_idx
ON lab6.event_log (terjadi_pada, customer_id);

SELECT pg_size_pretty(pg_relation_size('lab6.ev_salah_idx'));

SELECT pg_size_pretty(pg_relation_size('lab6.ev_benar_idx'));