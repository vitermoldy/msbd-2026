# Laporan Latihan 3 - Pertemuan 3

## Nama Anggota dan Kontribusi

| Anggota | Kontribusi Commit |
|---|---|
| **Viter Moldy Kesuma** | `docs:` menambahkan readme pertemuan 3 dan Reflektif A <br>`feat:` add q01-q05 |
| **Gideon Finsus Siburian** | `feat:` menambahkan q10-q15 <br> `docs:` menambahkan Reflektif C |
| **Nadine Tantiara Hutagaol** | `feat:` menambahkan q19-q20 dan `r1_laporan_bulanan.sql` <br> `docs:` menambahkan Reflektif E dan bukti r1_10_baris.png |
| **Rizky Cristian Fero Sihombing** | `feat:` menambahkan q06-q09 <br> `docs:` menambahkan Reflektif B |
| **Siti Naifah Batubara** | `feat:` menambahkan q16-q18 <br> `docs:` menambahkan Reflektif D dan bukti |

## Pertanyaan Reflektif A - Subquery

**1. Pada Q4, apa tepatnya yang membuat NOT IN berbahaya, dan bagaimana memeriksa apakah sebuah kolom rawan terhadap masalah itu?**



**2. Pada Q5, berapa kali subquery dievaluasi secara konseptual, dan mengapa “sekali per baris luar” belum tentu sama dengan yang benar-benar dikerjakan mesin?**


## Pertanyaan Reflektif B - CTE dan Recursive CTE

**1. Pada Q7, mengapa recursive term hanya melihat baris yang baru dihasilkan pada iterasi sebelumnya, dan apa akibatnya jika ia melihat seluruh hasil?**



**2. Kapan mengganti `UNION ALL` dengan `UNION` dapat menghentikan siklus, dan mengapa itu tetap bukan solusi yang baik?**



## Pertanyaan Reflektif C - Window Function

**1. Pada Q14, berapa tanggal yang berbeda, dan sifat data apa pada tabel payment yang menyebabkan perbedaan?**


**2. Jika Q13 menjadi laporan resmi keuangan, versi mana yang benar dan mengapa kesalahan frame sulit ditemukan melalui pengujian biasa?**


**3. Pada Q15, apa yang terjadi pada total belanja jika ORDER BY ditambahkan ke dalam OVER tanpa menuliskan frame?**


## Pertanyaan Reflektif D - Agregasi Lanjutan dan Operasi Himpunan

**1. Pada Q16, tanpa `GROUPING()`, bagaimana pembaca membedakan subtotal dari baris data yang kolomnya memang kosong?**

> Q16: Tanpa menggunakan GROUPING() , baris subtotal yang dihasilkan oleh ROLLUP akan ditampilkan sebagai NULL. Hal ini dapat menyebabkan kebingungan karena sulit membedakan NULL yang merupakan subtotal atau grand total dengan NULL yang memang berasal dari data. Fungsi GROUPING() digunakan untuk membedakan keduanya, karena akan menghasilkan nilai 1 pada baris hasil agregasi ROLLUP. Nilai tersebut kemudian dapat ditampilkan sebagai teks seperti SEMUA agar hasilnya lebih mudah dipahami.


**2. Pada Q17, mengapa versi `FILTER` dan `CASE WHEN` dapat memberi rata-rata berbeda walaupun jumlah baris sama?**

> Q17: Q17 : FILTER (WHERE length > 90) dan CASE WHEN length > 90 THEN length END menghasilkan nilai rata-rata yang sama karena AVG() secara otomatis mengabaikan nilai NULL. Perbedaan akan terjadi jika CASE WHEN menggunakan ELSE 0. Dengan adanya ELSE 0, data dengan durasi ≤ 90 akan dianggap sebagai nilai 0 dan ikut dihitung dalam rata-rata. Akibatnya, nilai rata-rata yang dihasilkan menjadi lebih kecil.


## Pertanyaan Reflektif E - JSONB

**1. Dari nomor transaksi, status, jumlah, dan identitas pelanggan di dalam payload, mana yang sebaiknya dipromosikan menjadi kolom relasional dengan constraint dan mana yang tepat tetap berada di JSON? Berikan alasan untuk setiap pilihan.**

> Menurut kelompok kami, nomor transaksi, status, jumlah, dan identitas pelanggan sebaiknya dipromosikan jadi kolom relasional. Data tersebut merupakan informasi utama untuk mencari, memfilter, mengurutkan, dan melakukan perhitungan. Jadi jika dijadikan kolom, kita bisa memberikan constraint seperti `NOT NULL`, `UNIQUE`, atau tipe data tertentu lainnya jadi datanya lebih teratur dan konsisten.
>
> Sedangkan buat data yang lebih fleksibel, seperti kontak pelanggan, lebih cocok tetap di `JSON`. Karena satu pelanggan bisa memiliki beberapa kontak dengan jenis yang berbeda, misalnya WhatsApp dan email, juga jumlah kontaknya ga selalu sama. Kalau dibuat menjadi banyak kolom, strukturnya malah bisa menjadi kurang fleksibel. Jadi, menurut kelompok kami data yang penting dan sering dipakai dalam proses database bagusnya dijadikan kolom relasional, sedangkan data yang sifatnya fleksibel dan tidak selalu memiliki struktur yang sama bisa tetap disimpan dalam `JSON`.

## Temuan Q14

> Pada Q14 dilakukan perbandingan antara window frame `RANGE` dan `ROWS` untuk menghitung rata-rata omzet harian.
>
>`RANGE BETWEEN 6 PRECEDING AND CURRENT ROW` menghitung berdasarkan rentang nilai pada kolom `tanggal`, sedangkan `ROWS BETWEEN 6 PRECEDING AND CURRENT ROW` menghitung berdasarkan 7 baris fisik terakhir.
>
>Perbedaan hasil dapat terjadi ketika terdapat tanggal yang tidak berurutan atau terdapat nilai tanggal yang sama. Dari percobaan ini dapat dilihat bahwa pemilihan `RANGE` atau `ROWS` perlu disesuaikan dengan kebutuhan analisis data.

## Hasil R1

> R1 berhasil menghasilkan laporan pendapatan bulanan berdasarkan kategori. Hasilnya menampilkan bulan, nama kategori, total pendapatan, peringkat kategori, pendapatan bulan sebelumnya, persentase pertumbuhan, pendapatan kumulatif, dan proporsi pendapatan kategori terhadap total pendapatan.

![Bukti ss sepuluh baris pertama](r1_10_baris.png)

## Tautan Merge Request

> `PULL REQUEST` https://github.com/vitermoldy/msbd-2026/pull/1