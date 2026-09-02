# Laporan Latihan 2 — Pertemuan 2

## Dari Kebutuhan ke Skema Berversi

**Kelompok 5**

**Anggota:**

- Viter Moldy Kesuma - 251402079 (Project Manager)
- Gideon Finsus Siburian - 251402038 
- Nadine Tantiara Hutagaol - 251402050
- Rizky Cristian Fero Sihombing - 251402056
- Siti Naifah Batubara - 251402067

---

# 1. Nama Domain dan Alasan Kelompok Memilih Domain Tersebut

**Domain Pilihan :** Sistem Helpdesk & Pelaporan Fasilitas Kampus

**Alasan memilih domain tersebut :** Sistem ini digunakan untuk mencatat dan mengelola laporan kerusakan fasilitas kampus, mulai dari laporan dibuat oleh civitas akademika, klasifikasi masalah, penentuan batas waktu penyelesaian, penugasan teknisi, pencatatan tindakan perbaikan, hingga tiket selesai dan ditutup.

Domain ini dipilih karena memiliki batas yang jelas dan tidak mencakup seluruh sistem informasi kampus. Selain itu, domain memiliki lebih dari enam entitas, relasi banyak-ke-banyak, serta beberapa aturan bisnis yang tidak sederhana.

Beberapa aturan bisnis yang terdapat dalam sistem antara lain kuota tiket aktif teknisi, kesesuaian keahlian teknisi dengan kategori masalah, penentuan jatuh tempo berdasarkan SLA, serta perubahan status tiket yang harus dilakukan secara berurutan.

---

# 2. Lingkup Sistem

## 2.1 Cakupan Sistem
Sistem mencakup beberapa proses utama sebagai berikut:

1. **Pendataan Pelapor**
   
   > Sistem menyimpan informasi dasar civitas akademika yang berhak membuat laporan, seperti nomor induk, nama, email, peran, dan status. Data pelapor hanya disimpan seperlunya karena data induk berasal dari sistem kampus.

2. **Pendataan Lokasi dan Fasilitas**
   
   > Sistem mencatat lokasi fasilitas yang berada di lingkungan kampus, termasuk gedung, lantai, ruangan, serta unit fasilitas. Setiap fasilitas memiliki identitas inventaris dan status kelayakan yang dapat digunakan untuk menentukan apakah fasilitas masih dapat dilaporkan sebagai objek kerusakan.

3. **Pembuatan Tiket Kerusakan**
   
   > Pelapor dapat membuat tiket ketika menemukan kerusakan pada suatu fasilitas. Tiket menyimpan informasi seperti nomor tiket, pelapor, fasilitas yang mengalami kerusakan, kategori masalah, judul, deskripsi, prioritas, waktu pelaporan, dan batas waktu penyelesaian.

4. **Klasifikasi Masalah dan SLA**
   
   >Setiap tiket dikategorikan berdasarkan jenis masalah. Setiap kategori memiliki nilai SLA yang menentukan batas waktu penyelesaian tiket. Tiket dengan prioritas darurat memiliki batas waktu yang lebih singkat sesuai aturan yang telah ditentukan.

5. **Penugasan Teknisi**
   
   > Petugas helpdesk dapat menugaskan satu atau lebih teknisi untuk menangani tiket. Sistem memperhatikan peran teknisi dalam penugasan, jumlah tiket aktif yang sedang ditangani, status teknisi, serta kesesuaian keahlian teknisi dengan kategori masalah.

6. **Pencatatan Keahlian Teknisi**
   
   > Sistem menyimpan hubungan antara teknisi dan kategori masalah yang dikuasainya. Setiap keahlian memiliki tingkat kompetensi sehingga dapat digunakan sebagai pertimbangan dalam menentukan teknisi yang sesuai.

7. **Pencatatan Tindakan Perbaikan**
   
   > Teknisi dapat mencatat tindakan yang dilakukan selama proses perbaikan. Setelah pekerjaan selesai, sistem menyimpan waktu penyelesaian, status akhir tiket, serta kondisi fasilitas setelah diperbaiki.

8. **Riwayat Perubahan Status**
   
   > Setiap perubahan status tiket dicatat sebagai riwayat untuk kebutuhan audit. Riwayat tersebut menyimpan status sebelumnya, status baru, pihak yang melakukan perubahan, dan waktu perubahan.

9. **Pemantauan Kepatuhan SLA**
   
   > Data tiket dan waktu penyelesaian dapat digunakan untuk mengetahui apakah tiket diselesaikan sebelum atau setelah batas waktu yang ditentukan. Informasi tersebut dapat digunakan untuk membuat rekapitulasi kepatuhan SLA berdasarkan kategori masalah dan gedung.


## 2.2 Batasan Sistem

Sistem ini hanya berfokus pada pengelolaan laporan kerusakan fasilitas kampus. Sistem tidak menangani seluruh proses manajemen fasilitas kampus secara keseluruhan. Data pelapor dan teknisi tidak menjadi data induk yang dikelola sepenuhnya oleh sistem ini. Informasi tersebut dianggap berasal dari sistem induk kampus dan hanya disimpan seperlunya untuk mendukung proses pelaporan dan penugasan.

Sistem juga tidak menangani proses pengadaan fasilitas baru, pembayaran biaya perbaikan, maupun pengelolaan stok suku cadang. Pengiriman notifikasi melalui email ataupun WhatsApp juga diluar batas kemampuan sistem.

Dengan batas tersebut, maka fokus utama dari sistem yaitu untuk memastikan setiap laporan kerusakan dapat dicatat, dikategorikan, ditugaskan kepada teknisi yang sesuai, ditangani, dan dipantau sampai selesai sesuai dengan aturan layanan yang berlaku.
---

# 3. Ringkasan Kebutuhan Data

Sistem Helpdesk & Pelaporan Fasilitas Kampus memiliki 8 kebutuhan data yang
mendukung proses pelaporan kerusakan dari awal hingga selesai.

| Kode | Kebutuhan Data | Penjelasan Singkat | Prioritas |
|------|----------------|--------------------|-----------|
| KD-01 | Pelapor dan Perannya | Menyimpan identitas pelapor dan perannya. Setiap pelapor memiliki satu peran dan pelapor nonaktif tidak dapat membuat tiket. | Wajib |
| KD-02 | Lokasi dan Fasilitas | Menyimpan data ruangan dan fasilitas. Setiap fasilitas berada pada satu lokasi dan memiliki kode inventaris unik. | Wajib |
| KD-03 | Pembuatan Tiket | Mencatat laporan kerusakan, termasuk pelapor, fasilitas, kategori masalah, deskripsi, status, dan waktu pelaporan. | Wajib |
| KD-04 | Kategori Masalah dan SLA | Menentukan jenis masalah dan batas waktu penyelesaian tiket berdasarkan nilai SLA. | Wajib |
| KD-05 | Penugasan Teknisi | Mencatat teknisi yang menangani tiket dengan mempertimbangkan kuota, status, dan kesesuaian keahlian. | Wajib |
| KD-06 | Keahlian Teknisi | Menyimpan kategori masalah yang dikuasai teknisi beserta tingkat keahliannya. | Penting |
| KD-07 | Penyelesaian Tiket | Mencatat tindakan perbaikan, waktu penyelesaian, dan kondisi fasilitas setelah diperbaiki. | Wajib |
| KD-08 | Riwayat Status dan SLA | Mencatat perubahan status tiket untuk audit serta menghitung kepatuhan terhadap SLA. | Penting |

> Secara keseluruhan terdapat **8 kebutuhan data**, terdiri dari **6 kebutuhan wajib** dan **2 kebutuhan penting**. Kebutuhan tersebut menjadi dasar dalam menentukan entitas, atribut, relasi, serta aturan yang diterapkan pada basis data.

---

# 4. Perancangan dan Penjelasan ERD

ERD dibuat berdasarkan kebutuhan data pada sistem Helpdesk & Pelaporan Fasilitas Kampus.

Entitas utama yang digunakan meliputi:

>- **PELAPOR**, menyimpan identitas pengguna yang dapat membuat tiket.
>
>- **PERAN**, menyimpan jenis peran yang dimiliki pelapor.
>
>- **LOKASI**, menyimpan informasi gedung dan ruangan.
>
>- **FASILITAS**, menyimpan unit fasilitas yang berada pada suatu lokasi.
>
>- **TIKET**, menyimpan laporan kerusakan fasilitas.
>
>- **KATEGORI_MASALAH**, menyimpan jenis masalah dan nilai SLA.
>
>- **TEKNISI**, menyimpan data teknisi yang menangani tiket.
>
>- **PENUGASAN**, menjadi entitas asosiatif antara tiket dan teknisi.
>
>- **KEAHLIAN**, menjadi entitas asosiatif antara teknisi dan kategori masalah.
>
>- **RIWAYAT_STATUS**, menyimpan setiap perubahan status tiket untuk kebutuhan audit.

Relasi banyak-ke-banyak antara **TIKET dan TEKNISI** diuraikan melalui entitas **PENUGASAN**. Sementara itu, relasi banyak-ke-banyak antara **TEKNISI dan KATEGORI_MASALAH** diuraikan melalui entitas **KEAHLIAN**.

ERD tidak memasukkan detail implementasi fisik seperti tipe data, nama indeks, atau detail database lainnya.

---

# 5. Implementasi Migration

Pengelolaan perubahan struktur database dilakukan menggunakan migration dengan Flyway. Migration dibuat secara berversi jadi setiap perubahan schema memiliki urutan dan riwayat yang jelas.

Migration digunakan agar database dapat dibangun kembali dari kondisi kosong berdasarkan file migration yang tersedia.

### 5.1 V1 - Skema Awal

V1 membuat enam tabel awal, yaitu `kategori_masalah`, `lokasi`, `fasilitas`, `peran`, `pelapor`, dan `tiket`.

Tabel `kategori_masalah` menyimpan kode, nama masalah, dan SLA dalam satuan jam. Nilai `sla_jam` harus lebih besar dari 0.

Tabel `lokasi` menyimpan kode ruang, gedung, lantai, dan nama ruang. `kode_ruang` dibuat unik.

Tabel `fasilitas` menyimpan fasilitas yang berada pada suatu lokasi. Tabel ini memiliki foreign key ke `lokasi`, `kode_inventaris` yang unik, serta status fasilitas yang dibatasi menjadi `aktif`, `rusak`, atau `dihapus`.

Tabel `peran` menyimpan kode dan nama peran. Tabel `pelapor` menyimpan data pengguna yang dapat membuat tiket serta memiliki foreign key ke tabel `peran`. Nomor induk dan email dibuat unik.

Tabel `tiket` menjadi tabel utama untuk laporan kerusakan. Tiket memiliki hubungan dengan pelapor, fasilitas, dan kategori masalah. Prioritas dibatasi menjadi `biasa`, `tinggi`, atau `darurat`, sedangkan status dibatasi menjadi `baru`, `ditugaskan`, `diproses`, `selesai`, `ditutup`, atau `dibatalkan`.

> Selain itu, waktu laporan memiliki nilai default dan waktu jatuh tempo harus lebih besar daripada waktu laporan.

### 5.2 V2 - Perubahan Skema

V2 melanjutkan pengembangan struktur database dari skema yang telah dibuat pada V1. Perubahan dilakukan secara bertahap agar kebutuhan sistem dapat ditambahkan tanpa membangun database dari awal.

### 5.3 V3 - Penambahan Kolom

V3 digunakan untuk menambahkan kolom yang diperlukan sebagai bagian dari perubahan schema. Kolom baru ditambahkan terlebih dahulu tanpa constraint `NOT NULL` sehingga tidak langsung bermasalah dengan data yang sudah ada.

### 5.4 V4 - Pengisian Data Lama

V4 digunakan untuk mengisi data pada kolom baru yang masih memiliki nilai `NULL`. Tahap ini dilakukan sebelum constraint `NOT NULL` diterapkan.

### 5.5 V5 - Penerapan Constraint

V5 merupakan tahap terakhir dari pola perubahan kolom. Setelah data lama sudah memiliki nilai, constraint `NOT NULL` dapat diterapkan pada kolom tersebut.

Dengan urutan tersebut, perubahan schema dapat dilakukan secara bertahap dan lebih aman terhadap data yang sudah ada.

---

# 6. Bukti Database Dapat Dibangun Ulang

Database proyek dihapus kemudian dibuat kembali dari kondisi kosong, setelah itu seluruh migration dijalankan ulang dari awal.

Hasil pengujian berhasil membangun kembali skema versi 1 tanpa error. Hal ini dibuktikan melalui `flyway info` yang menunjukkan migration versi 1 kembali berstatus **Success**.

Pengujian ini membuktikan bahwa struktur database dapat dibangun ulang secara keseluruhan hanya berdasarkan file migration yang telah dibuat.

---

# 7. Bukti Pola Tiga Langkah Penambahan Kolom Nullable

Penambahan kolom dengan constraint `NOT NULL` dilakukan melalui tiga langkah.

Pertama, kolom baru ditambahkan tanpa constraint `NOT NULL`. Kedua, data lama yang masih memiliki nilai `NULL` diisi dengan nilai yang sesuai. Ketiga, setelah tidak ada data yang `NULL`, constraint `NOT NULL` diterapkan.

Pola ini digunakan agar penambahan constraint tidak gagal karena adanya data lama yang belum memiliki nilai.

---

# 8. Hasil Seed Data (dijalankan dua kali)

Seed digunakan untuk memasukkan data awal ke dalam database, salah satunya data pada tabel `peran`.

Seed kemudian dijalankan sebanyak dua kali untuk menguji perilaku ketika data yang sama dimasukkan kembali. Pengujian ini menunjukkan bahwa constraint pada database dapat memengaruhi hasil ketika data dengan nilai yang sama dimasukkan kembali.

Pengujian seed juga menunjukkan pentingnya penggunaan data yang memiliki nilai unik serta pengelolaan duplikasi ketika seed dijalankan lebih dari satu kali.

# 9. Eksperimen Locking dan Pengamatan pg_stat_activity

Pengamatan dilakukan menggunakan `pg_stat_activity` pada PostgreSQL untuk melihat aktivitas koneksi dan query yang sedang berjalan.

Dari pengamatan tersebut dapat diketahui koneksi yang sedang aktif beserta aktivitas query pada database. Pengujian ini digunakan untuk melihat kondisi database ketika terdapat proses yang sedang berjalan.

Hasil pengamatan kemudian didokumentasikan pada bagian bukti untuk menunjukkan aktivitas PostgreSQL selama pengujian.

---

# 10. Jawaban Pertanyaan 1–7

**10.1 Mengapa lingkungan pengujian memerlukan basis data sendiri, dan bukan sekadar schema terpisah di dalam basis data yang sama? Jawab dalam sekitar dua kalimat.**

> Lingkungan pengujian butuh database sendiri supaya proses coba-coba tidak mengganggu database lain. Kalau hanya memakai schema yang berbeda, database-nya masih sama dan tetap bisa saling memengaruhi.

**10.2 Pilih satu kebutuhan yang memiliki aturan paling rumit. Menurut kelompok kalian, apakah aturan tersebut lebih tepat ditegakkan menggunakan constraint, trigger, atau kode aplikasi? Berikan satu alasan.**

> Kami memilih KD-05 tentang penugasan teknisi karena harus mengecek beberapa hal, seperti kuota, status, dan keahlian teknisi. Menurut kami lebih cocok menggunakan trigger karena pengecekan tersebut harus dilakukan otomatis saat teknisi ditugaskan.

**10.3 Mengapa Peminjaman dan Unit Alat pada contoh tidak dihubungkan langsung, tetapi melalui Baris Pinjam? Apa yang hilang jika hubungan dibuat langsung?**

> Peminjaman dan Unit Alat menggunakan Baris Pinjam karena satu peminjaman bisa memiliki beberapa unit alat. Kalau langsung dihubungkan, akan sulit menyimpan setiap unit alat yang ikut dalam satu peminjaman.

**10.4. Apa perbedaan antara entitas Alat dan Unit Alat? Sebutkan satu pertanyaan bisnis yang hanya dapat dijawab jika keduanya dipisahkan.**

> Alat adalah jenis alatnya, sedangkan Unit Alat adalah benda atau barang fisik dari alat tersebut. Contohnya, kita bisa mengetahui unit alat mana yang sedang dipinjam jika keduanya dipisahkan.

**10.5 Seorang anggota kelompok mengubah isi V1__skema_awal.sql setelah migration tersebut sudah diterapkan, kemudian melakukan push ke repositori. Apa yang terjadi ketika anggota lain menjalankan migration? Jelaskan penyebab error dan cara memperbaikinya tanpa menghapus riwayat migration.**

> Akan terjadi checksum mismatch karena isi V1 sudah berubah setelah sebelumnya dijalankan. Cara memperbaikinya adalah mengembalikan V1 seperti semula, lalu membuat migration baru untuk perubahan tersebut.

**10.6 Catat apa yang terlihat pada pg_stat_activity. Perintah mana yang menunggu? Apa akibatnya jika kondisi tersebut terjadi pada basis data produksi saat banyak pengguna sedang mengakses sistem?**

> Pada pg_stat_activity, perintah yang terkena lock akan terlihat sedang menunggu, sementara transaksi lain masih berjalan. Kalau terjadi di database produksi, pengguna lain bisa ikut mengalami proses yang lambat atau tertahan.

**10.7 Mengapa seed data tidak diletakkan langsung di dalam migrations/? Sebutkan satu perbedaan sifat antara migration dan seed data.**

> Seed tidak dimasukkan ke migrations/ karena fungsinya berbeda. Migration digunakan untuk mengatur struktur database, sedangkan seed digunakan untuk mengisi data awal dan bisa dijalankan kembali jika diperlukan.

---

### Tautan Repositori Git Tim

> https://github.com/vitermoldy/msbd-2026/tree/main

---

### Daftar Commit Masing-Masing Anggota

| Anggota | Commit |
|---|---|
| **Viter Moldy Kesuma** | `docs:` menyusun kebutuhan sistem helpdesk <br>`feat:` implementasi skema database awal |
| **Gideon Finsus Siburian** | `feat:` melakukan implementasi migration V3-V5 untuk penambahan kolom NOT NULL |
| **Nadine Tantiara Hutagaol** | `docs:` memperbarui laporan dan melengkapi `laporan.md` <br> `feat:` menambahkan seed yang tidak menggandakan data |
| **Rizky Cristian Fero Sihombing** | `feat:` menambahkan migration skema awal dan service flyway |
| **Siti Naifah Batubara** | `docs:` menambahkan ERD sistem helpdesk <br> `docs:` melengkapi bukti screenshot |