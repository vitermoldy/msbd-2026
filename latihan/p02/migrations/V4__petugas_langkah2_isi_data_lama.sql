UPDATE tiket
   SET petugas_penerima = 'tidak tercatat'
 WHERE petugas_penerima IS NULL;
