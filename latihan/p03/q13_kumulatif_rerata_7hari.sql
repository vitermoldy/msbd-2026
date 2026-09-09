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
    SUM(omzet) OVER (ORDER BY tanggal ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS total_kumulatif,
    ROUND(AVG(omzet) OVER (ORDER BY tanggal ROWS BETWEEN 6 PRECEDING AND CURRENT ROW), 2) AS rata_rata_7_hari
FROM daily_revenue
ORDER BY tanggal;
