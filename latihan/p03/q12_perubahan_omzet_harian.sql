WITH daily_revenue AS (
    SELECT
        DATE(payment_date) AS tanggal,
        SUM(amount) AS omzet_harian
    FROM payment
    GROUP BY DATE(payment_date)
)
SELECT
    tanggal,
    omzet_harian,
    LAG(omzet_harian) OVER (ORDER BY tanggal) AS omzet_hari_lalu,
    omzet_harian - LAG(omzet_harian) OVER (ORDER BY tanggal) AS selisih,
    ROUND(
        ((omzet_harian - LAG(omzet_harian) OVER (ORDER BY tanggal))
        / NULLIF(LAG(omzet_harian) OVER (ORDER BY tanggal), 0)) * 100,
    2) AS persen_perubahan
FROM daily_revenue
ORDER BY tanggal;
