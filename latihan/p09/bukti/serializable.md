# Bukti Eksperimen SKIP LOCKED, NOWAIT, dan SERIALIZABLE (Q24–Q29)

> **Bagian Langkah 5.** Kerangka ini disiapkan bersama Langkah 1–2 agar struktur folder
> `bukti/` sesuai ketentuan soal. Pengisiannya oleh anggota pemegang Langkah 5.

Pola pencatatan mengikuti `isolation-level.md`: satu tabel urutan per eksperimen dengan kolom
**Urutan · Sesi · Perintah · Hasil**, lalu pesan galat apa adanya, lalu penjelasan sebab.

## Q24 · SKIP LOCKED

Tabel antrean pekerjaan (misalnya `lab9.pekerjaan` dengan `id` dan `status`), satu baris
dikunci Sesi A, lalu Sesi B menjalankan `SELECT ... FOR UPDATE SKIP LOCKED`. Catat **id baris
mana** yang dikembalikan ke Sesi B, bukan hanya bahwa perintahnya berhasil.

## Q25 · NOWAIT

Penguncian baris yang sama dengan `FOR UPDATE NOWAIT`. Salin pesan galatnya lengkap dengan
SQLSTATE-nya, dan bandingkan waktu tunggunya dengan Q19 yang menunggu sampai Sesi A `COMMIT`.

## Q26 · Write skew pada REPEATABLE READ

Tabel `lab9.dokter_jaga` dengan dua dokter aktif dan aturan "minimal satu dokter aktif". Kedua
transaksi `REPEATABLE READ` membaca jumlah dokter aktif **sebelum** salah satunya `COMMIT`,
lalu masing-masing menonaktifkan dokter yang berbeda. Catat apakah keduanya berhasil `COMMIT`
dan berapa jumlah dokter aktif setelahnya.

## Q27 · SERIALIZABLE

Ulangi Q26 pada `SERIALIZABLE`. Kedua `SELECT` harus dijalankan sebelum salah satu `COMMIT`,
karena urutan eksekusi menentukan kapan galat muncul. Catat `COMMIT` mana yang ditolak dan
salin pesan `40001` beserta `DETAIL`-nya.

## Q28–Q29

Q28 dan Q29 berupa penjelasan dan pseudocode; keduanya mengacu pada galat `40001` dari Q27 dan
`40P01` dari `deadlock.md`.
