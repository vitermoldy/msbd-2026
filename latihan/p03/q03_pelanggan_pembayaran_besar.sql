-- Diminta: nama pelanggan yang pernah melakukan pembayaran lebih dari 9.99
--          dalam satu transaksi.
-- Dipilih: EXISTS berkorelasi, karena pertanyaannya hanya "pernah atau tidak".
--          EXISTS berhenti pada baris cocok pertama dan tidak menggandakan
--          baris pelanggan.
-- Alternatif: JOIN ke payment lalu DISTINCT; tidak dipilih karena
--          menggelembungkan hasil dulu baru membuangnya, dua pekerjaan untuk
--          satu pertanyaan sederhana.

SELECT c.first_name,
       c.last_name
FROM customer c
WHERE EXISTS (
    SELECT 1
    FROM payment p
    WHERE p.customer_id = c.customer_id
      AND p.amount > 9.99
)
ORDER BY c.last_name, c.first_name;

-- Hasil: 107 baris