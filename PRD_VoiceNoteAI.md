# Product Requirements Document (PRD) - VoiceNote AI

## 1. Identitas Proyek
- **Nama Aplikasi:** VoiceNote AI (atau sesuai pilihan)
- **Konteks:** Proyek Akhir Mata Kuliah Pemrograman Mobile
- **Tech Stack:** Flutter (Frontend Mobile), PocketBase (Backend Database & Auth), OpenRouter/Groq (AI API).

## 2. Tujuan Aplikasi
Membangun aplikasi pencatatan modern yang menggabungkan kemudahan input suara (AI Speech-to-Text) dengan fitur personalisasi dan visualisasi ala *Easy Notes*, serta dilengkapi dengan sistem monetisasi (Freemium) dan dasbor pemantauan admin.

## 3. Fitur Utama Aplikasi (Functional Requirements)

### A. Fitur Inti (Core Features)
1. **AI Voice Transcription (Speech-to-Text):** Mengubah rekaman suara menjadi teks secara instan menggunakan API AI yang murah (seperti Groq Whisper).
2. **Note Management:** Membuat, membaca, mengedit, menghapus, dan menyematkan (*pin*) catatan penting.
3. **Kategorisasi (Tabs):** Pengguna dapat membuat kategori khusus untuk mengelompokkan catatan (misal: "Pekerjaan", "Kuliah").
4. **View Toggle:** Opsi untuk menampilkan daftar catatan dalam mode *List* (Daftar) atau *Grid* (Kotak-kotak).
5. **Mode Kalender:** Menampilkan kalender visual di mana pengguna bisa melihat catatan berdasarkan tanggal pembuatannya.

### B. Fitur Multimedia & Visual (Easy Notes Style)
1. **Drawing Canvas (Coretan Tangan):** Pengguna dapat menggambar atau menulis tangan secara langsung di aplikasi, dan menyimpannya sebagai bagian dari catatan.
2. **Colored Notes & Backgrounds:** Kustomisasi warna kartu catatan atau menggunakan gambar sebagai latar belakang catatan.
3. **Custom Themes:** Pilihan tema warna aplikasi secara keseluruhan (Dark Mode, Light Mode, Tema Pastel, dll).

### C. Fitur Keamanan & AI Tambahan (Premium/Advanced)
1. **Magic Format (AI Text):** Tombol cerdas untuk merapikan hasil transkrip yang berantakan menjadi poin-poin yang terstruktur.
2. **Privacy Lock:** Mengunci catatan rahasia menggunakan PIN, Sidik Jari (Fingerprint), atau FaceID.

## 4. Strategi Monetisasi (Freemium Model)
Sistem pembatasan dilakukan secara otomatis melalui *rules* di PocketBase.
- **Pengguna Gratis (Free Tier):** Batas pembuatan catatan (misal: 30 catatan), kuota AI transkrip 10 menit/bulan, tanpa akses kunci privasi dan tema kustom.
- **Pengguna Premium (Pro Tier):** Catatan tak terbatas, kuota AI hingga 300 menit/bulan, akses penuh fitur Magic Format, Privacy Lock, dan kustomisasi tema tanpa batas.

## 5. Skema Database (PocketBase Collections)

Sistem menggunakan 5 Collection utama:

### 1. `users`
- `tier` (Select: free/pro)
- `ai_quota_used` (Number - Detik STT)
- `theme_preference` (Text)

### 2. `categories`
- `user_id` (Relation ke Users)
- `name` (Text - misal: "Ide Bisnis")
- `color_hex` (Text)

### 3. `notes`
- `user_id` (Relation ke Users)
- `category_id` (Relation ke Categories - Opsional)
- `title` (Text)
- `content` (Text/HTML)
- `color_or_bg` (Text)
- `is_pinned` (Boolean)
- `is_locked` (Boolean)
- `is_ai_generated` (Boolean)

### 4. `attachments` (Untuk Drawing & Media)
- `note_id` (Relation ke Notes)
- `file` (File - Gambar/Audio)
- `type` (Select: drawing, image, audio)

### 5. `api_usage_logs` (Untuk Dasbor Admin)
- `user_id` (Relation ke Users)
- `endpoint` (Text - stt/format)
- `duration_seconds` (Number)
- `created` (Date)

## 6. Admin Dashboard
- Dapat menggunakan antarmuka bawaan PocketBase untuk manajemen CRUD.
- Untuk metrik spesifik, admin dapat memantau jumlah pengguna *Pro* vs *Free*, serta memantau tabel `api_usage_logs` untuk memastikan biaya penggunaan AI tetap terkendali.
