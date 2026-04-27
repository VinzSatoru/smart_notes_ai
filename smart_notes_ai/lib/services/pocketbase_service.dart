import 'package:pocketbase/pocketbase.dart';

class PocketBaseService {
  // Ganti IP ini dengan IP lokal komputer Anda jika running di real device Android
  // 10.0.2.2 adalah IP localhost komputer host jika dari Android Studio Emulator
  // 127.0.0.1 bisa digunakan jika running di Windows/Web
  static const String baseUrl = 'http://127.0.0.1:8090'; 
  
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
