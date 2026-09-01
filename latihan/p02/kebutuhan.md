# Kebutuhan Data — Sistem Helpdesk & Pelaporan Fasilitas Kampus

Mata kuliah : TIF2104 — Manajemen Sistem Basis Data
Pertemuan   : 2 — Dari Kebutuhan ke Skema Berversi
Kelompok    : (isi nama kelompok)
Anggota     : Viter Moldy Kesuma (251402079), Siti Naifah Batubara (251402067),
              Rizky Cristian Fero Sihombing (251402056),
              Nadine Tantiara Hutagaol (251402050), Gideon Finsus Siburian (251402038)
Penyusun    : Viter Moldy Kesuma

---

## Domain

Sistem pencatatan laporan kerusakan fasilitas kampus (helpdesk). Sistem menangani
seluruh siklus hidup satu tiket kerusakan: mulai dari laporan yang dibuat civitas
akademika, klasifikasi masalah dan penetapan batas waktu penyelesaian, penugasan
teknisi, pencatatan tindakan perbaikan, sampai tiket dinyatakan selesai dan ditutup.

### Alasan pemilihan domain

1. **Batasnya jelas.** Sistem hanya mengurus siklus hidup tiket kerusakan, bukan
   seluruh manajemen aset atau sistem informasi kampus. Domain ini tidak melebar
   seperti marketplace atau sistem informasi akademik lengkap.
2. **Memenuhi syarat jumlah entitas.** Terdapat 10 entitas, melebihi syarat minimal 6.
3. **Memiliki relasi banyak-ke-banyak.** Ada dua: TIKET–TEKNISI (diuraikan menjadi
   entitas asosiatif PENUGASAN) dan TEKNISI–KATEGORI_MASALAH (diuraikan menjadi KEAHLIAN).
4. **Memiliki aturan bisnis yang tidak sederhana.** Kuota tiket aktif per teknisi,
   penetapan jatuh tempo berdasarkan SLA kategori, kesesuaian keahlian teknisi dengan
   kategori masalah, dan transisi status tiket yang harus berurutan.

---

## Lingkup

| Termasuk                                              | Tidak termasuk                              |
|-------------------------------------------------------|---------------------------------------------|
| Katalog lokasi dan unit fasilitas beserta kelayakannya | Pengadaan dan pembelian fasilitas baru      |
| Pembuatan tiket laporan kerusakan oleh civitas         | Penganggaran dan pembayaran biaya perbaikan |
| Klasifikasi masalah dan penetapan batas waktu (SLA)    | Data induk kepegawaian dan kemahasiswaan    |
| Penugasan teknisi serta pencatatan tindakan perbaikan  | Manajemen stok suku cadang gudang           |
| Riwayat perubahan status tiket untuk keperluan audit   | Jadwal kuliah dan penjadwalan pemakaian ruang |
| Rekapitulasi kepatuhan SLA per kategori dan per gedung | Notifikasi email / WhatsApp ke pelapor      |

Catatan batas: data pelapor dan teknisi **disalin** dari sistem induk kampus, bukan
dikelola di sini. Sistem ini hanya menyimpan identitas seperlunya untuk keperluan tiket.

---

## Kebutuhan Data

### KD-01 Pendataan pelapor dan perannya
- Deskripsi : sistem menyimpan identitas civitas yang berhak membuat tiket
- Data      : nomor_induk, nama, email, peran, status, tgl_terdaftar
- Aturan    : nomor_induk dan email bersifat unik;
              satu pelapor memiliki tepat satu peran;
              pelapor berstatus nonaktif tidak boleh membuat tiket baru
- Volume    : ±8.000 pelapor, bertambah ±1.500 per tahun
- Sumber    : data dasar SIAKAD dan kepegawaian
- Prioritas : wajib

### KD-02 Pendataan lokasi dan fasilitas
- Deskripsi : petugas mendata ruang dan setiap unit fasilitas yang ada di dalamnya
- Data      : kode_ruang, gedung, lantai, nama_ruang, kode_inventaris,
              nama_fasilitas, status_fasilitas, tgl_perolehan
- Aturan    : kode_ruang dan kode_inventaris bersifat unik;
              satu unit fasilitas berada tepat di satu lokasi;
              fasilitas berstatus 'dihapus' tidak dapat menjadi objek tiket baru
- Volume    : ±300 lokasi dan ±2.500 unit fasilitas
- Sumber    : daftar inventaris bagian umum
- Prioritas : wajib

### KD-03 Pembuatan tiket laporan kerusakan
- Deskripsi : pelapor mencatat kerusakan yang ditemukan pada satu unit fasilitas
- Data      : nomor_tiket, pelapor, fasilitas, kategori_masalah, judul,
              deskripsi, prioritas, dilaporkan_pada, jatuh_tempo
- Aturan    : nomor_tiket bersifat unik;
              jatuh_tempo harus lebih besar daripada dilaporkan_pada;
              tiket baru selalu berstatus 'baru';
              satu unit fasilitas tidak boleh memiliki dua tiket terbuka
              dengan kategori masalah yang sama
- Volume    : ±40 tiket per hari kerja
- Sumber    : hasil wawancara petugas helpdesk
- Prioritas : wajib

### KD-04 Klasifikasi masalah dan batas waktu penyelesaian (SLA)
- Deskripsi : setiap tiket digolongkan ke kategori masalah yang menentukan batas waktu
- Data      : kode_kategori, nama_kategori, sla_jam
- Aturan    : sla_jam harus lebih besar dari nol;
              jatuh_tempo tiket = dilaporkan_pada + sla_jam milik kategorinya;
              prioritas 'darurat' memangkas SLA menjadi setengahnya
- Volume    : ±10 kategori, jarang berubah
- Sumber    : SOP layanan fasilitas bagian umum
- Prioritas : wajib

### KD-05 Penugasan teknisi ke tiket
- Deskripsi : petugas helpdesk menugaskan satu atau lebih teknisi untuk menangani tiket
- Data      : tiket, teknisi, peran_penugasan, ditugaskan_pada, selesai_pada,
              catatan_tindakan
- Aturan    : satu tiket hanya boleh memiliki satu teknisi berperan 'utama';
              seorang teknisi tidak boleh ditugaskan dua kali pada tiket yang sama;
              teknisi hanya boleh menerima tiket bila jumlah tiket aktifnya masih
              di bawah kuota dan keahliannya sesuai kategori masalah tiket;
              teknisi berstatus 'cuti' atau 'nonaktif' tidak dapat ditugaskan
- Volume    : ±60 penugasan per hari kerja
- Sumber    : hasil wawancara koordinator teknisi
- Prioritas : wajib

### KD-06 Keahlian teknisi terhadap kategori masalah
- Deskripsi : sistem menyimpan kategori masalah apa saja yang dikuasai tiap teknisi
- Data      : teknisi, kategori_masalah, level_kompetensi
- Aturan    : pasangan teknisi–kategori tidak boleh berulang;
              level_kompetensi bernilai 1 sampai 3;
              teknisi tanpa keahlian pada suatu kategori tidak dapat menjadi
              teknisi utama untuk tiket kategori tersebut
- Volume    : ±25 teknisi, masing-masing menguasai 2–4 kategori
- Sumber    : data sertifikasi dan penugasan bagian umum
- Prioritas : penting

### KD-07 Pencatatan tindakan dan penyelesaian tiket
- Deskripsi : teknisi mencatat tindakan perbaikan dan menyatakan tiket selesai
- Data      : tiket, catatan_tindakan, diselesaikan_pada, status_akhir,
              status_fasilitas_setelah_perbaikan
- Aturan    : hanya tiket berstatus 'diproses' yang dapat berubah menjadi 'selesai';
              diselesaikan_pada tidak boleh mendahului dilaporkan_pada;
              tiket yang diselesaikan melewati jatuh_tempo ditandai melanggar SLA;
              fasilitas yang tidak dapat diperbaiki berpindah ke status 'rusak'
- Volume    : ±40 penyelesaian per hari kerja
- Sumber    : hasil wawancara teknisi lapangan
- Prioritas : wajib

### KD-08 Riwayat perubahan status dan rekapitulasi SLA
- Deskripsi : setiap perubahan status tiket dicatat untuk audit dan laporan bulanan
- Data      : tiket, status_lama, status_baru, diubah_oleh, diubah_pada
- Aturan    : setiap perubahan status wajib menghasilkan tepat satu baris riwayat;
              baris riwayat bersifat append-only, tidak boleh diubah atau dihapus;
              rekap bulanan menghitung persentase tiket yang selesai sebelum
              jatuh_tempo, dikelompokkan per kategori dan per gedung
- Volume    : ±150 baris riwayat per hari kerja
- Sumber    : kebutuhan pelaporan pimpinan bagian umum
- Prioritas : penting

---

## Ringkasan Kebutuhan

| Kode  | Judul                                          | Prioritas |
|-------|------------------------------------------------|-----------|
| KD-01 | Pendataan pelapor dan perannya                 | wajib     |
| KD-02 | Pendataan lokasi dan fasilitas                 | wajib     |
| KD-03 | Pembuatan tiket laporan kerusakan              | wajib     |
| KD-04 | Klasifikasi masalah dan batas waktu (SLA)      | wajib     |
| KD-05 | Penugasan teknisi ke tiket                     | wajib     |
| KD-06 | Keahlian teknisi terhadap kategori masalah     | penting   |
| KD-07 | Pencatatan tindakan dan penyelesaian tiket     | wajib     |
| KD-08 | Riwayat perubahan status dan rekapitulasi SLA  | penting   |

Total: 8 kebutuhan data (6 wajib, 2 penting).

---

## Catatan Penegakan Aturan

Tidak semua aturan di atas ditegakkan dengan cara yang sama:

- **Constraint** — untuk aturan yang cukup dilihat dari satu baris atau satu indeks,
  misalnya keunikan nomor_tiket, jatuh_tempo > dilaporkan_pada, dan satu teknisi
  utama per tiket (unique partial index).
- **Trigger** — untuk aturan yang harus menghitung baris lain, misalnya kuota tiket
  aktif teknisi pada KD-05 dan pencatatan otomatis riwayat status pada KD-08.
- **Kode aplikasi** — sebagai validasi awal agar pengguna menerima pesan yang ramah,
  bukan sebagai satu-satunya penjaga aturan.
