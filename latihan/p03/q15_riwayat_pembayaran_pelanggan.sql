SELECT
    customer_id,
    payment_date,
    amount,
    ROW_NUMBER() OVER (PARTITION BY customer_id ORDER BY payment_date) AS urutan_bayar,
    payment_date - LAG(payment_date) OVER (PARTITION BY customer_id ORDER BY payment_date) AS jarak_hari,
    SUM(amount) OVER (PARTITION BY customer_id) AS total_belanja_pelanggan
FROM payment
ORDER BY customer_id, payment_date;
