SET max_parallel_workers_per_gather = 0;

SELECT
    (ctid::text::point)[0] AS page_number,
    COUNT(*) AS tuple_count
FROM lab6.event_log
GROUP BY page_number
ORDER BY page_number
LIMIT 10;
