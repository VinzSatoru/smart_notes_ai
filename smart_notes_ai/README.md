# Smart Notes AI 📝✨

Smart Notes AI adalah aplikasi pencatatan modern berbasis Flutter yang ditenagai oleh kecerdasan buatan (Groq AI). Aplikasi ini dirancang untuk memaksimalkan produktivitas Anda melalui fitur pengenalan suara (Speech-to-Text), perangkum otomatis, dan penerjemah multibahasa dengan kecepatan instan.

## Fitur Utama 🚀

- **Smart AI Voice-to-Text**: Rekam suara Anda (hingga 5 menit untuk pengguna PRO) dan AI Whisper Groq akan mengubahnya menjadi teks catatan dengan sangat akurat dalam hitungan detik.
- **AI Text Summarizer**: Rangkum teks catatan yang panjang menjadi ringkasan poin-poin penting.
- **AI Translator**: Terjemahkan catatan Anda ke berbagai bahasa populer di seluruh dunia secara instan.
- **DOKU Premium Payment Gateway**: Sistem langganan paket PRO terintegrasi dengan DOKU API v2. Mendukung pembayaran instan melalui Virtual Account (BCA, Mandiri, BNI, BRI) dengan status sinkronisasi otomatis (auto-polling) tanpa membuka WebView eksternal.
- **PocketBase Backend**: Menggunakan arsitektur backend-in-a-box PocketBase untuk autentikasi user yang aman, penyimpanan data catatan, sinkronisasi cloud, dan manajemen kuota AI.

## Tech Stack 🛠️

- **Frontend:** Flutter & Dart
- **State Management:** BLoC (Business Logic Component) Pattern + Clean Architecture
- **Backend (BaaS):** PocketBase
- **AI Engine:** Groq API (`whisper-large-v3` & `llama-3.1-8b-instant`)
- **Payment Gateway:** DOKU (Direct API v2 Server-to-Server)

## Cara Menjalankan Aplikasi Lokal

1. Klon repositori ini.
2. Pastikan backend PocketBase berjalan di lokal (`./pocketbase serve --http=0.0.0.0:8090`).
3. Buat file `.env` di *root* proyek Flutter dan tambahkan konfigurasi berikut:
   ```env
   GROQ_API_KEY=gsk_xxxxxxxxxxxxxxxxxxxx
   DOKU_CLIENT_ID=MCH-xxxx-xxxxxxxxx
   DOKU_SECRET_KEY=SK-xxxxxxxxxxxxxxxxxxxx
   ```
4. Jalankan `flutter pub get`.
5. Jalankan `flutter run`.

## Pembaruan Terkini (v1.0) 🎉
- Mengganti Midtrans dengan integrasi **DOKU Payment Gateway v2** yang lebih bersih dan fleksibel untuk UI kustom.
- Perbaikan *bug* OS Cache saat perekaman panjang, memastikan pengenalan suara stabil lebih dari 1 menit.
- Perbaikan 403 Access Denied dari Cloudflare Groq.

Dibuat dengan ❤️ untuk produktivitas Anda.
