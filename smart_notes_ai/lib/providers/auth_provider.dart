import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';

class AuthProvider extends ChangeNotifier {
  final PocketBaseService _pbService = PocketBaseService();
  
  bool _isLoading = false;
  String _errorMessage = '';

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  bool get isAuthenticated => _pbService.isAuthenticated;
  RecordModel? get currentUser => _pbService.currentUser;

  // Clear error message
  void clearError() {
    _errorMessage = '';
    notifyListeners();
  }

  // Fungsi Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      await _pbService.pb.collection('users').authWithPassword(email, password);
      _isLoading = false;
      notifyListeners();
      return true;
    } on ClientException catch (e) {
      _isLoading = false;
      _errorMessage = e.response['message'] ?? 'Login gagal. Periksa email dan password Anda.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan tidak terduga.';
      notifyListeners();
      return false;
    }
  }

  // Fungsi Register
  Future<bool> register(String name, String email, String password, String passwordConfirm) async {
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      // 1. Buat akun baru
      final body = <String, dynamic>{
        "name": name,
        "email": email,
        "emailVisibility": true,
        "password": password,
        "passwordConfirm": passwordConfirm,
        "tier": "free", // Default tier
        "ai_quota_used": 0,
      };

      await _pbService.pb.collection('users').create(body: body);

      // 2. Langsung login setelah sukses register
      await login(email, password);
      
      return true;
    } on ClientException catch (e) {
      _isLoading = false;
      _errorMessage = e.response['message'] ?? 'Gagal mendaftar. Pastikan email belum digunakan.';
      notifyListeners();
      return false;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Terjadi kesalahan tidak terduga.';
      notifyListeners();
      return false;
    }
  }

  // Fungsi Logout
  void logout() {
    _pbService.logout();
    notifyListeners();
  }
}
