-- Query perbandingan
WITH daily_revenue AS (
    SELECT
        DATE(payment_date) AS tanggal,
        SUM(amount) AS omzet
    FROM payment
    GROUP BY DATE(payment_date)
)
SELECT
    tanggal,
    omzet,
    -- Versi RANGE (Default jika tidak disebutkan frame type)
    AVG(omzet) OVER (ORDER BY tanggal RANGE BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_range,
    -- Versi ROWS (Fisik 7 baris terakhir)
    AVG(omzet) OVER (ORDER BY tanggal ROWS BETWEEN 6 PRECEDING AND CURRENT ROW) AS avg_rows
FROM daily_revenue
ORDER BY tanggal
