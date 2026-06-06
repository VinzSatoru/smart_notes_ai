import 'package:pocketbase/pocketbase.dart';

class PocketBaseService {
  // Menggunakan IP lokal WiFi PC agar bisa diakses dari HP fisik di jaringan yang sama
  static const String baseUrl = 'http://192.168.0.105:8090'; 
  
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
