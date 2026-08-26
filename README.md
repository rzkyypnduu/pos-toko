# Tokoku - Aplikasi Kasir Toko

Aplikasi Point-of-Sale (POS) / Kasir digital untuk toko retail kecil-menengah di Indonesia. Dibangun dengan Flutter, aplikasi ini berjalan sepenuhnya offline dan mendukung pencetakan struk via Bluetooth ke printer thermal.

---

## Fitur Utama

### Dashboard
- Salam otomatis berdasarkan waktu (pagi/siang/sore/malam)
- Ringkasan penjualan harian dan bulanan (total penjualan, jumlah transaksi, item terjual, laba bersih)
- Navigasi bulan untuk melihat data historis
- Grafik laba bulanan (12 bulan terakhir) menggunakan bar chart
- Grafik laba harian dalam satu bulan menggunakan line chart
- Daftar 5 item terlaris berdasarkan kuantitas
- Peringatan stok menipis (stok <= 5)

### Manajemen Barang (Produk)
- CRUD produk lengkap (Tambah, Edit, Hapus)
- Pemindaian barcode menggunakan kamera perangkat
- Pencarian berdasarkan nama atau kode barcode
- Filter berdasarkan kategori
- Tampilan responsif untuk mobile dan tablet
- Deteksi duplikat barcode (jika barcode sudah ada, form akan terisi otomatis untuk diedit)

### Kasir (POS)
- Pemindaian barcode langsung dari kamera dengan auto-detect
- Pencarian manual produk dengan autocomplete
- Keranjang belanja dengan tombol +/- kuantitas dan input desimal (untuk item timbangan)
- Perhitungan kembalian secara real-time
- Tombol "Uang Pas" untuk pembayaran pas
- Pemrosesan transaksi: pencatatan penjualan, pengurangan stok otomatis
- Cetak struk otomatis atau manual setelah transaksi

### Riwayat Transaksi
- Filter: Semua, Hari Ini, Minggu Ini, Bulan Ini, Rentang Tanggal Kustom
- Detail transaksi lengkap (item, kuantitas, subtotal, total, bayar, kembali)
- Ringkasan jumlah transaksi dan total penjualan

### Pengaturan
- Nama toko (tersimpan otomatis)
- Pengaturan printer Bluetooth:
  - Ukuran kertas (58mm / 80mm)
  - Pencarian dan koneksi perangkat Bluetooth
  - Cetak struk otomatis (auto-print)
  - Cetak uji (test print)

---

## Tech Stack

| Kategori | Teknologi |
|---|---|
| Bahasa | Dart (SDK ^3.12.2) |
| Framework | Flutter (Material 3) |
| State Management | Provider (^6.1.2) |
| Penyimpanan Lokal | JSON files via path_provider |
| Pemindaian Barcode | mobile_scanner (^7.0.0) |
| Cetak Bluetooth | flutter_classic_bluetooth (^1.0.0) - ESC/POS |
| Charting | fl_chart (^0.70.2) |
| Lokalisasi | intl (^0.20.0) - Bahasa Indonesia (id_ID) |
| ID Unique | uuid (^4.5.1) |
| Permissions | permission_handler (^11.3.1) |

---

## Arsitektur Aplikasi

### Struktur Direktori
```
lib/
├── main.dart                    # Entry point, MultiProvider, navigasi utama
├── models/
│   ├── barang.dart              # Model produk
│   └── transaksi.dart           # Model transaksi + item transaksi
├── providers/
│   ├── barang_provider.dart     # Logika CRUD produk
│   ├── transaksi_provider.dart  # Logika keranjang & analitik penjualan
│   └── printer_provider.dart    # Manajemen state printer Bluetooth
├── screens/
│   ├── dashboard_screen.dart    # Dashboard utama
│   ├── barang_screen.dart       # Manajemen produk
│   ├── kasir_screen.dart        # Layar kasir/POS
│   ├── transaksi_screen.dart    # Riwayat transaksi
│   └── pengaturan_screen.dart   # Pengaturan aplikasi
├── services/
│   ├── storage_service.dart     # Baca/tulis file JSON
│   └── printer_service.dart     # Koneksi Bluetooth & ESC/POS
├── utils/
│   ├── formatters.dart          # Format Rupiah, tanggal, input
│   └── paper_size.dart          # Enum ukuran kertas
└── widgets/
    ├── bottom_nav.dart          # Navigasi bawah (mobile)
    ├── sidebar_nav.dart         # Sidebar navigasi (tablet)
    ├── responsive_layout.dart   # Layout responsif mobile/tablet
    └── profit_charts.dart       # Grafik laba (bar & line chart)
```

### Model Data

#### Barang (Produk)
| Field | Tipe | Keterangan |
|---|---|---|
| id | String | UUID unik (8 karakter) |
| kode | String | Kode barcode |
| nama | String | Nama produk |
| hargaBeli | double | Harga beli/modal |
| hargaJual | double | Harga jual |
| stok | int | Jumlah stok |
| kategori | String | Kategori produk |
| createdAt | DateTime | Waktu pembuatan |

#### Transaksi
| Field | Tipe | Keterangan |
|---|---|---|
| id | String | UUID unik (8 karakter, huruf besar) |
| items | List\<TransaksiItem\> | Item-item dalam transaksi |
| total | double | Total belanja |
| bayar | double | Jumlah bayar |
| kembalian | double | Kembalian |
| timestamp | DateTime | Waktu transaksi |

#### Settings
| Field | Tipe | Keterangan |
|---|---|---|
| autoPrint | bool | Cetak struk otomatis |
| namaToko | String | Nama toko |
| paperSize | String | Ukuran kertas (mm58/mm80) |
| selectedAddress | String | Alamat MAC printer Bluetooth |
| selectedName | String | Nama printer Bluetooth |

---

## Navigasi

Aplikasi menggunakan 5 tab navigasi:

| Tab | Ikon | Layar |
|---|---|---|
| Beranda | dashboard | DashboardScreen |
| Barang | inventory_2 | BarangScreen |
| Kasir | point_of_sale | KasirScreen |
| Riwayat | receipt_long | TransaksiScreen |
| Pengaturan | settings | PengaturanScreen |

- **Mobile** (< 600px): BottomNavigationBar
- **Tablet** (>= 600px): Sidebar vertical

---

## Printer Bluetooth

Mendukung cetak struk ke printer thermal via Bluetooth Classic menggunakan protokol ESC/POS:
- Lebar kertas: 58mm atau 80mm (32 karakter)
- Format struk: nama toko, tanggal/waktu, daftar item, total, bayar, kembali, ucapan terima kasih
- Pemotongan kertas otomatis (GS V 0)

---

## Penyimpanan Data

Semua data disimpan sebagai file JSON di direktori documents aplikasi:

| File | Isi |
|---|---|
| barang.json | Semua data produk |
| transaksi.json | Semua data transaksi |
| settings.json | Pengaturan aplikasi & printer |

---

## Persyaratan Platform

- **Android** (primary target): Izin Bluetooth, Kamera, Lokasi
- **iOS**: Tersedia (mungkin perlu konfigurasi tambahan)
- **Desktop** (Linux, macOS, Windows): Tersedia

---

## Memulai

```bash
# Install dependencies
flutter pub get

# Jalankan di Android
flutter run

# Build APK release
flutter build apk --release
```

---

## Izin yang Diperlukan (Android)

- `BLUETOOTH` / `BLUETOOTH_ADMIN` - Koneksi printer
- `BLUETOOTH_SCAN` / `BLUETOOTH_CONNECT` / `BLUETOOTH_ADVERTISE` - Bluetooth API level 31+
- `CAMERA` - Pemindaian barcode
- `ACCESS_FINE_LOCATION` / `ACCESS_COARSE_LOCATION` - Diperlukan untuk Bluetooth scan

---

## Catatan

- Aplikasi berjalan sepenuhnya offline tanpa koneksi internet
- Mendukung kuantitas desimal untuk item berbasis timbangan
- Stok dikurangi otomatis saat transaksi diproses
- Tidak ada fitur login/autentikasi
