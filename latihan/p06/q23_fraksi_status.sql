SELECT 
    status, 
    COUNT(*) AS jumlah,
    ROUND(COUNT(*) * 100.0 / SUM(COUNT(*)) OVER (), 2) AS persentase
FROM lab6.event_log
GROUP BY status;