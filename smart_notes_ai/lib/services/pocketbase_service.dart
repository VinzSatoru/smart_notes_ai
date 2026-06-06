import 'package:pocketbase/pocketbase.dart';

class PocketBaseService {
  // Gunakan 10.0.2.2 untuk Emulator Android Studio. 
  // Jika menggunakan HP Fisik, ganti kembali ke 127.0.0.1 dan jalankan `adb reverse tcp:8090 tcp:8090`
  static const String baseUrl = 'http://10.0.2.2:8090'; 
  
  late final PocketBase pb;

  PocketBaseService() {
    pb = PocketBase(baseUrl);
  }

  // Cek apakah user sudah login
  bool get isAuthenticated => pb.authStore.isValid;

  // Mendapatkan data user yang sedang login
  RecordModel? get currentUser => pb.authStore.record;

  // Logout
  void logout() {
    pb.authStore.clear();
  }
}
