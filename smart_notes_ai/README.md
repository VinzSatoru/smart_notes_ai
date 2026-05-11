# Smart Notes AI 🧠

Smart Notes AI is a mobile application built with Flutter and powered by PocketBase as the backend. This app allows users to manage notes efficiently with AI capabilities.

## 🚀 Getting Started

Follow these steps to set up and run the project locally.

### 📋 Prerequisites

- **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
- **PocketBase**: The backend executable is included in the `/backend` folder.

---

### 🔧 1. Backend Setup (PocketBase)

1. Open your terminal and navigate to the backend directory:
   ```powershell
   cd backend
   ```
2. Run the PocketBase server:
   ```powershell
   .\pocketbase serve
   ```
3. Access the Admin UI at [http://127.0.0.1:8090/_/](http://127.0.0.1:8090/_/) to manage your database and users.
   > **Note:** If this is your first time, you will be prompted to create an admin account.

---

### 📱 2. Frontend Setup (Flutter)

1. Navigate to the Flutter project directory:
   ```powershell
   cd smart_notes_ai
   ```
2. Install dependencies:
   ```powershell
   flutter pub get
   ```
3. **Configuration (Optional):**
   If you are running on a physical Android device, open `lib/services/pocketbase_service.dart` and update the `baseUrl` with your computer's local IP address.
   ```dart
   static const String baseUrl = 'http://YOUR_LOCAL_IP:8090';
   ```
   *For Android Emulators, use the default `http://10.0.2.2:8090`.*

4. Run the application:
   ```powershell
   flutter run
   ```

---

## 🛠 Features

- [x] Authentication with PocketBase
- [x] CRUD Notes
- [ ] AI Integration (Coming Soon)
- [ ] Rich Text Editor

## 📄 License

This project is licensed under the MIT License.

