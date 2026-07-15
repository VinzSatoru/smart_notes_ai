import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class PocketBaseService {
  late final String baseUrl;
  late final PocketBase pb;

  PocketBaseService() {
    baseUrl = dotenv.env['POCKETBASE_URL'] ?? 'https://api-smartnotes.uwangku.web.id';
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
