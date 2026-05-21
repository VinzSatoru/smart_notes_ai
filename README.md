# Smart Notes AI

Smart Notes AI adalah aplikasi pencatatan modern berbasis Flutter yang mengimplementasikan **Clean Architecture** dan **BLoC** (Business Logic Component) untuk manajemen *state*. Aplikasi ini menggunakan **PocketBase** sebagai layanan *backend* (BaaS) lokal.

## 🚀 Fitur Utama
- **Autentikasi Pengguna**: Login dan Registrasi akun (dengan penyimpanan sesi token lokal).
- **Manajemen Catatan**: Tulis, baca, edit, sematkan (pin), dan hapus catatan.
- **Kategori Catatan**: Mengelompokkan catatan berdasarkan kategori (Semua, Pekerjaan, Pribadi, dll).
- **Tampilan Modern**: Antarmuka *Glassmorphism*, *Hero animations*, tipografi `Poppins`, dan desain *card* bergaya premium.
- **AI Ready**: (Akan datang) Integrasi Speech-to-Text dan format teks otomatis menggunakan AI.

---

## 🏗 Arsitektur

Aplikasi ini telah direfaktor untuk menggunakan **Clean Architecture** dengan pemisahan struktur berdasarkan fitur (*feature-based folder structure*). Hal ini bertujuan untuk mempermudah pengerjaan tim, *testing*, dan memastikan skalabilitas jangka panjang.

### Struktur Direktori (`lib/`)
```text
lib/
├── core/                   # Utilitas inti (error handling, use cases dasar, themes)
├── features/               # Fitur utama aplikasi
│   ├── auth/               # Modul Autentikasi (Login/Register)
│   │   ├── data/           # Remote Data Sources & Repositories Impl (PocketBase calls)
│   │   ├── domain/         # Entities, Repositories Interfaces, & Use Cases
│   │   └── presentation/   # BLoC, Events, States, & UI Screens
│   │
│   └── notes/              # Modul Manajemen Catatan
│       ├── data/           # Remote Data Sources & Repositories Impl
│       ├── domain/         # Entities (Note, Category), Repositories Interfaces, & Use Cases
│       └── presentation/   # Notes BLoC & UI Screens (Home, Note Editor)
│
├── services/               # Konfigurasi layanan eksternal (PocketBase Client)
├── injection_container.dart# Setup Dependency Injection (GetIt)
└── main.dart               # Entry point aplikasi (Inisialisasi BLoC & Routing)
```

### Stack Teknologi
- **Frontend**: Flutter & Dart
- **State Management**: `flutter_bloc`
- **Dependency Injection**: `get_it`
- **Error Handling**: `dartz` (Either: Right/Left pattern)
- **Backend**: PocketBase (berjalan secara lokal)

---

## 🛠 Persiapan & Instalasi (Untuk Tim)

Berikut adalah langkah-langkah untuk menjalankan *project* ini di mesin lokal Anda.

### 1. Prasyarat Sistem
Pastikan Anda sudah menginstal:
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (versi 3.24.x atau terbaru)
- [Dart SDK](https://dart.dev/get-dart)
- Emulator Android / iOS atau perangkat fisik yang terhubung (USB Debugging aktif).

### 2. Konfigurasi Backend (PocketBase)
Karena aplikasi ini mengandalkan *backend* lokal, Anda harus menjalankan PocketBase terlebih dahulu sebelum me-*run* Flutter.

1. Buka folder *backend* di terminal (berada di luar folder `smart_notes_ai`):
   ```bash
   cd ../backend
   ```
2. Jalankan _server_ PocketBase:
   ```bash
   # Di Windows
   .\pocketbase.exe serve
   
   # Di Mac/Linux
   ./pocketbase serve
   ```
3. Pastikan *server* berjalan di `http://127.0.0.1:8090`. (Jika IP berbeda, sesuaikan _base URL_ pada `lib/services/pocketbase_service.dart`).
4. Buka URL `http://127.0.0.1:8090/_/` di browser untuk mengakses *Admin UI* dari PocketBase jika diperlukan.

### 3. Konfigurasi Frontend (Flutter)
1. Buka tab terminal baru, lalu navigasi ke direktori *project* Flutter:
   ```bash
   cd smart_notes_ai
   ```
2. Unduh semua *dependencies*:
   ```bash
   flutter pub get
   ```
3. Jalankan aplikasi ke emulator atau *device*:
   ```bash
   flutter run
   ```

---

## 🤝 Alur Kerja Pengembangan (Team Workflow)

Untuk menjaga *codebase* tetap bersih dan terhindar dari konflik (mengingat ini *project* tim), harap ikuti panduan berikut saat menambah fitur baru:

1. **Gunakan Clean Architecture**: Jangan memanggil API (*PocketBase*) langsung dari UI (*Screens*).
   - Buat/gunakan antarmuka (*Interface*) **Repository** di folder `domain`.
   - Buat implementasi **Remote Data Source** di folder `data`.
   - Gunakan **Use Case** di folder `domain` sebagai perantara ke BLoC.
2. **State Management BLoC**:
   - Daftarkan *Event* yang merepresentasikan aksi (*User Interaction*).
   - Kembalikan *State* yang merepresentasikan status (Loading, Success, Failure).
   - Selalu gunakan `BlocBuilder` untuk me-render UI, dan `BlocConsumer` / `BlocListener` jika Anda butuh aksi sampingan (*side-effects*) seperti `SnackBar` atau Navigasi.
3. **Dependency Injection**:
   - Jika Anda membuat *Use Case* atau *BLoC* baru, pastikan Anda mendaftarkannya di dalam file `lib/injection_container.dart` agar dapat digunakan secara global.

---

## 📝 Catatan Penting
- **Skema PocketBase**: Pada tabel `notes`, *field* teks isi catatan bernama **`content`** (bukan `content_text`). Ini sudah di-*mapping* dengan benar di *model*. Harap jangan mengubah skema PocketBase ini secara sepihak tanpa koordinasi tim.
- **Aesthetics & UI**: Harap gunakan komponen standar yang sudah disiapkan atau mengacu pada *Color Scheme* yang ada (`#4F64F2` sebagai *primary*) saat menambahkan layar baru agar UI tetap seragam dan memiliki nuansa modern.

---

## 🔄 Sinkronisasi Git (Pembaruan Kode Tim)

Karena ini adalah proyek kolaborasi, Anda harus menggunakan **Git** agar pekerjaan Anda terhubung dengan *repository* utama dan anggota tim lainnya mendapatkan *update* terbaru.

### 1. Mengirim (Push) Perubahan Anda ke GitHub
Setelah Anda menyelesaikan sebuah fitur atau perbaikan (contoh: refaktor Clean Architecture), jalankan perintah berikut di terminal:

```bash
# 1. Tambahkan semua file yang berubah
git add .

# 2. Buat "checkpoint" dengan pesan yang jelas
git commit -m "Refactor: Implementasi Clean Architecture & Notes BLoC"

# 3. Kirim ke GitHub
git push origin main
```
> *Catatan: Jika branch tim Anda bukan `main`, ganti kata `main` dengan nama branch yang disepakati (misalnya `dev` atau `feature/notes`).*

### 2. Mengambil (Pull) Perubahan dari Anggota Tim Lain
Sebelum Anda mulai mengetik kode (kapan pun Anda baru membuka laptop), **biasakan untuk selalu menarik data terbaru** dari GitHub agar kode Anda tidak bentrok (*conflict*) dengan kode yang dikerjakan teman Anda:

```bash
git pull origin main
```

Selamat *ngoding* bersama tim! 🚀

---

## 📜 Log Pembaruan (Changelog)

### Update Pada tgl 15 Mei 2026 oleh Ahmad Novian
**Integrasi Fitur AI Voice-to-Text & Sistem Monetisasi (Kuota Harian):**
*   **Groq Whisper AI**: Integrasi layanan transkripsi audio canggih menggunakan model `whisper-large-v3` via API Groq dengan arsitektur bersih (*Clean Architecture*).
*   **Perekaman Suara Lokal**: Perekaman audio menggunakan package `record` dan `path_provider` yang stabil di emulator maupun perangkat fisik.
*   **Sistem Pembatasan Kuota & Paywall**: Pengecekan batas penggunaan harian (maksimal 3 kali rekaman gratis per hari, durasi maksimal 10 menit) yang dicatat langsung ke tabel `api_usage_logs` di PocketBase. Jika kuota habis, muncul dialog *paywall* "Upgrade ke Pro".
*   **Polesan Visual & Animasi**: Tombol mikrofon dinamis dengan efek denyut (*pulsing glow* menggunakan `avatar_glow`), *staggered animation* (`animate_do`), dan latar belakang *Mesh Gradient* serta *Glassmorphism* yang memanjakan mata.

### Update Pada tgl 16 Mei 2026 oleh Revi Arda
**Modernisasi Frontend & Perombakan UI/UX Total:**
*   **Cinematic Splash Screen**: Implementasi animasi pembuka yang modern dengan efek pendaran (*glowing logo*) dan transisi bertahap.
*   **Auth Overhaul**: Redesain halaman Login & Register menggunakan tema profesional **Blue & White**, termasuk pemulihan fitur Facebook Login.
*   **HomeScreen Transformation**: 
    *   Pemindahan bilah pencarian ke bagian atas untuk navigasi yang lebih bersih.
    *   Implementasi **Sidebar (Drawer) Premium** dengan banner promo dan menu berkelompok.
    *   Integrasi akses cepat Kalender Pintar dan filter kategori bergaya pill.
*   **Note Editor Pro**:
    *   Sistem latar belakang kertas dinamis (**Garis-garis, Kotak-kotak, Polos**).
    *   Palet warna pastel yang bisa dikustomisasi untuk kenyamanan membaca.
    *   Bilah alat (*toolbar*) lengkap di bagian bawah untuk format dan lampiran.
    *   Fitur **Voice AI** yang ditingkatkan dengan posisi ergonomis dan sistem limitasi kuota (3x penggunaan gratis).
*   **NoteCard Design**: Menghapus ikon emoji buku dan menggantinya dengan gaya kartu yang lebih minimalis, bersih, dan profesional.

### Update Pada tgl 18 Mei 2026 oleh Ahmad Novian
**Integrasi Fitur Text AI (Rangkuman & Terjemahan Multibahasa):**
*   **Magic AI (LLaMA 3.1)**: Penambahan fitur pemrosesan teks canggih menggunakan model `llama-3.1-8b-instant` dari Groq.
*   **Fitur Rangkuman Otomatis**: Memungkinkan pengguna untuk mendapatkan inti dari catatan panjang mereka. Dibatasi 5x per hari dengan validasi kuota pada tabel `api_usage_logs` di PocketBase.
*   **Terjemahan Multibahasa Dinamis**: Pengguna dapat menerjemahkan catatan secara gratis dan tanpa batas ke berbagai bahasa (English, Indonesia, Jepang, Korea, Arab, Spanyol, Prancis, Jerman).
*   **Pemisahan UI Hasil AI**: Hasil Rangkuman dan Terjemahan tidak lagi ditumpuk di editor utama untuk menjaga kebersihan teks. Hasil disajikan dalam *Bottom Sheet* khusus yang interaktif, dan dapat diakses kapan pun melalui tombol "Lihat Rangkuman / Terjemahan" di bawah editor. Data ini tersimpan aman di kolom baru (`ai_summary` dan `ai_translation`) pada database PocketBase.

### Update Pada tgl 21 Mei 2026 oleh Revi Arda
**Fitur Kategori Kustom & Manajemen Semua Catatan:**
*   **Kategori Kustom Dinamis**: Pengguna kini dapat membuat kategori baru (mis. "Ide Bisnis") langsung dari panel saat membuat atau mengedit catatan.
*   **Seeding Kategori Cerdas**: Aplikasi secara otomatis membuatkan kategori dasar ("Meeting" & "Materi") bagi pengguna baru jika database masih kosong, mencegah kekosongan tampilan.
*   **Layar Manajemen Semua Catatan (`AllNotesManagementScreen`)**: 
    *   Membuka kunci akses menu *sidebar* "Semua Catatan" menuju layar manajemen khusus.
    *   Implementasi sistem **Multi-select** (pilih jamak) menggunakan interaksi *long press* (tekan & tahan).
    *   Aksi penghapusan massal (*Bulk Delete*) catatan dengan sinkronisasi ke backend PocketBase secara paralel.
    *   Desain kartu yang diperkaya dengan **Label Kategori** bergaya pil biru dan presisi **Tanggal Pembuatan**.
    *   Tombol *toggle* untuk beralih antara tampilan *List* dan *Grid* (*Masonry*) tanpa menghilangkan fitur manajemen.
    *   Penanganan *layout overflow* tingkat lanjut saat beralih antara mode seleksi dan grid.
