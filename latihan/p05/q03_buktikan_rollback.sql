-- Diminta: memanggil procedure dengan p_amount = -4.99, menghitung jumlah baris rental_tx sesudahnya, dan membuktikan bahwa transaksi mengalami rollback.
-- Dipilih: menggunakan nilai -4.99 sesuai materi untuk memicu galat dan melihat jumlah baris rental_tx setelah pemanggilan.
-- Alternatif: melihat isi tabel satu per satu; tidak dipilih karena jumlah baris sudah cukup untuk membuktikan rollback.

CALL lab5.process_rental(1, 1, 1, -4.99);

SELECT count(*) FROM lab5.rental_tx;