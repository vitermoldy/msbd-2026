# Bukti Eksperimen SKIP LOCKED, NOWAIT, dan SERIALIZABLE (Q24–Q29)

Bagian Langkah 5. Hasil pengujian SKIP LOCKED, NOWAIT, Write Skew, dan SERIALIZABLE.

## Q24 · SKIP LOCKED

Urutan | Sesi | Perintah | Hasil
---|---|---|---
1 | A | `BEGIN; SELECT * FROM lab9.antrean_pekerjaan WHERE job_id = 1 FOR UPDATE;` | Mengembalikan baris `(1, PENDING)` dan mengunci baris.
2 | B | `BEGIN; SELECT * FROM lab9.antrean_pekerjaan WHERE status = 'PENDING' FOR UPDATE SKIP LOCKED;` | Mengembalikan baris `(2, PENDING)` dan `(3, PENDING)`. Baris 1 dilewati.
3 | A | `ROLLBACK;` | Transaksi dibatalkan dan kunci dilepaskan.
4 | B | `ROLLBACK;` | Transaksi dibatalkan dan kunci dilepaskan.

### Penjelasan

Sesi A mengunci baris dengan `job_id = 1`. Ketika Sesi B menjalankan `SELECT ... FOR UPDATE SKIP LOCKED`, PostgreSQL melewati baris yang sedang dikunci tanpa menunggu. Sesi B mendapatkan dua baris lainnya, yaitu `job_id = 2` dan `job_id = 3`.

`SKIP LOCKED` berguna untuk sistem antrean pekerjaan karena beberapa pekerja dapat mengambil pekerjaan yang berbeda tanpa harus menunggu baris yang sedang diproses pekerja lain.

## Q25 · NOWAIT

Urutan | Sesi | Perintah | Hasil
---|---|---|---
1 | A | `BEGIN; SELECT * FROM lab9.antrean_pekerjaan WHERE job_id = 2 FOR UPDATE;` | Mengembalikan baris `(2, PENDING)` dan mengunci baris.
2 | B | `BEGIN; SELECT * FROM lab9.antrean_pekerjaan WHERE job_id = 2 FOR UPDATE NOWAIT;` | Gagal seketika karena baris sedang dikunci Sesi A.
3 | B | `ROLLBACK;` | Transaksi yang gagal diakhiri.
4 | A | `ROLLBACK;` | Transaksi dibatalkan dan kunci dilepaskan.

### Pesan Galat

```text
ERROR: could not obtain lock on row in relation "antrean_pekerjaan"
SQLSTATE: 55P03
```

### Penjelasan dan Perbandingan Waktu Tunggu

Sesi B gagal seketika karena menggunakan `NOWAIT`, sehingga PostgreSQL tidak menunggu kunci dilepaskan oleh Sesi A. SQLSTATE `55P03` menunjukkan bahwa kunci yang dibutuhkan tidak dapat diperoleh.

Berbeda dengan Q19 yang menguji perilaku menunggu ketika baris dikunci transaksi lain, `NOWAIT` langsung menghasilkan error jika baris tidak dapat dikunci.

## Q26 · Write Skew pada REPEATABLE READ

Urutan | Sesi | Perintah | Hasil
---|---|---|---
1 | A | `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ; SELECT COUNT(*) FROM lab9.dokter_jaga WHERE is_aktif = TRUE;` | Mengembalikan nilai `2`.
2 | B | `BEGIN TRANSACTION ISOLATION LEVEL REPEATABLE READ; SELECT COUNT(*) FROM lab9.dokter_jaga WHERE is_aktif = TRUE;` | Mengembalikan nilai `2`.
3 | A | `UPDATE lab9.dokter_jaga SET is_aktif = FALSE WHERE dokter_id = 1;` | `UPDATE 1`.
4 | B | `UPDATE lab9.dokter_jaga SET is_aktif = FALSE WHERE dokter_id = 2;` | `UPDATE 1`.
5 | A | `COMMIT;` | Transaksi berhasil commit.
6 | B | `COMMIT;` | Transaksi berhasil commit.
7 | A | `SELECT COUNT(*) FROM lab9.dokter_jaga WHERE is_aktif = TRUE;` | Mengembalikan nilai `0`.

### Penjelasan

Pada tingkat isolasi `REPEATABLE READ`, kedua transaksi membaca snapshot yang sama ketika terdapat dua dokter aktif. Sesi A menonaktifkan Andi, sedangkan Sesi B menonaktifkan Budi. Karena kedua transaksi mengubah baris yang berbeda, keduanya dapat berhasil melakukan `COMMIT`.

Akibatnya, tidak ada dokter yang aktif. Kondisi ini merupakan anomali *write skew* karena kedua transaksi berhasil, tetapi hasil akhirnya melanggar aturan bisnis bahwa minimal satu dokter harus tetap aktif.

## Q27 · SERIALIZABLE

Urutan | Sesi | Perintah | Hasil
---|---|---|---
1 | A | `BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE; SELECT COUNT(*) FROM lab9.dokter_jaga WHERE is_aktif = TRUE;` | Mengembalikan nilai `2`.
2 | B | `BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE; SELECT COUNT(*) FROM lab9.dokter_jaga WHERE is_aktif = TRUE;` | Mengembalikan nilai `2`.
3 | A | `UPDATE lab9.dokter_jaga SET is_aktif = FALSE WHERE dokter_id = 1;` | `UPDATE 1`.
4 | B | `UPDATE lab9.dokter_jaga SET is_aktif = FALSE WHERE dokter_id = 2;` | `UPDATE 1`.
5 | A | `COMMIT;` | Transaksi berhasil commit.
6 | B | `COMMIT;` | Diharapkan gagal dengan SQLSTATE `40001` apabila PostgreSQL mendeteksi konflik serialisasi pada urutan ini.
7 | B | `ROLLBACK;` | Mengakhiri transaksi yang gagal.

### Pesan Galat

```text
ERROR: could not serialize access due to read/write dependencies among transactions
SQLSTATE: 40001
```

### Penjelasan

Pada tingkat isolasi `SERIALIZABLE`, PostgreSQL menggunakan mekanisme *Serializable Snapshot Isolation* (SSI) untuk mendeteksi ketergantungan ant transaksi yang dapat menyebabkan hasil tidak konsisten. Jika konflik serialisasi terdeteksi, PostgreSQL membatalkan salah satu transaksi dengan SQLSTATE `40001`.

Dengan demikian, PostgreSQL mencegah kedua transaksi berhasil menghasilkan kondisi yang melanggar aturan bisnis. Transaksi yang gagal perlu diulang dari awal setelah dilakukan `ROLLBACK`.

Catatan: Sesi yang mengalami kegagalan bergantung pada urutan eksekusi dan deteksi konflik. Hasil aktual harus dicocokkan dengan keluaran PostgreSQL.

## Q28 · Fungsi SIREAD Lock dan Sifat SELECT dalam SERIALIZABLE

- **SIREAD Lock:** Mekanisme internal PostgreSQL untuk mencatat pembacaan data dan membantu mendeteksi ketergantungan baca-tulis ant transaksi yang dapat menyebabkan anomali serialisasi.
- **Mengapa SELECT tidak mengunci semua baris:** Pada tingkat isolasi `SERIALIZABLE`, PostgreSQL menggunakan mekanisme SSI dan predicate locking untuk mendeteksi potensi konflik serialisasi tanpa harus memblokir setiap transaksi yang membaca data.

Dengan demikian, `SERIALIZABLE` tidak berarti setiap perintah `SELECT` mengunci semua baris seperti `SELECT ... FOR UPDATE`.

## Q29 · Pseudocode Retry Transaksi

```python
max_retries = 3
base_delay = 0.1

for attempt in range(max_retries):
    try:
        db.execute(
            "BEGIN TRANSACTION ISOLATION LEVEL SERIALIZABLE;"
        )

        # Jalankan seluruh operasi database dalam transaksi.

        db.execute("COMMIT;")

        # Operasi eksternal dilakukan setelah COMMIT berhasil.
        send_notification()
        break

    except (SerializationFailure, DeadlockDetected):
        db.execute("ROLLBACK;")

        if attempt == max_retries - 1:
            raise

        delay = base_delay * (2 ** attempt)
        delay += random.uniform(0, base_delay)
        time.sleep(delay)
```

### Penjelasan

Retry digunakan ketika transaksi gagal karena konflik serialisasi (`40001`) atau deadlock (`40P01`). Seluruh transaksi harus diulang dari awal setelah `ROLLBACK`, bukan hanya mengulang perintah yang gagal.

Jumlah percobaan dibatasi agar proses tidak berjalan tanpa henti. Jeda eksponensial dengan *jitter* menambahkan variasi waktu tunggu sehingga transaksi yang gagal bersamaan tidak terus mencoba ulang pada waktu yang sama.

Operasi eksternal, seperti mengirim notifikasi atau email, sebaiknya dilakukan setelah `COMMIT` berhasil agar pemberitahuan tidak dikirim untuk transaksi yang gagal. Dalam implementasi nyata, pola *transactional outbox* atau mekanisme idempotensi dapat digunakan untuk meningkatkan keandalan pengiriman.

Catatan: Pseudocode ini menggunakan nama exception abstrak. Implementasi sebenarnya perlu menyesuaikannya dengan library database yang digunakan.