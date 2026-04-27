import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';

class NoteProvider extends ChangeNotifier {
  final PocketBaseService _pbService = PocketBaseService();
  
  bool _isLoading = false;
  String _errorMessage = '';
  
  List<RecordModel> _notes = [];
  List<RecordModel> _categories = [];
  
  // Fitur Filter
  String _selectedCategoryId = 'all'; // 'all' untuk semua catatan
  
  // Fitur View Mode
  bool _isGridView = true;

  bool get isLoading => _isLoading;
  String get errorMessage => _errorMessage;
  List<RecordModel> get notes => _notes;
  List<RecordModel> get categories => _categories;
  String get selectedCategoryId => _selectedCategoryId;
  bool get isGridView => _isGridView;

  // Mengubah view mode
  void toggleViewMode() {
    _isGridView = !_isGridView;
    notifyListeners();
  }

  // Mengubah kategori aktif
  void setCategory(String categoryId) {
    _selectedCategoryId = categoryId;
    fetchNotes(); // Ambil ulang data sesuai filter
  }

  // Mengambil kategori dari server
  Future<void> fetchCategories() async {
    if (!_pbService.isAuthenticated) return;
    
    try {
      final user = _pbService.currentUser;
      if (user == null) return;

      final records = await _pbService.pb.collection('categories').getFullList(
        filter: 'user_id = "${user.id}"',
        sort: '-created',
      );
      
      _categories = records;
      notifyListeners();
    } catch (e) {
      debugPrint("Error fetching categories: $e");
    }
  }

  // Mengambil catatan dari server
  Future<void> fetchNotes() async {
    if (!_pbService.isAuthenticated) return;
    
    _isLoading = true;
    _errorMessage = '';
    notifyListeners();

    try {
      final user = _pbService.currentUser;
      if (user == null) throw Exception("User not found");

      String filterStr = 'user_id = "${user.id}"';
      
      // Tambahkan filter kategori jika bukan 'all'
      if (_selectedCategoryId != 'all') {
        filterStr += ' && category_id = "$_selectedCategoryId"';
      }

      final records = await _pbService.pb.collection('notes').getFullList(
        filter: filterStr,
        sort: '-is_pinned,-created', // Pin di atas, lalu urut dari yang terbaru
      );
      
      _notes = records;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Gagal memuat catatan: ${e.toString()}';
      notifyListeners();
    }
  }
  
  // Menghapus catatan
  Future<bool> deleteNote(String noteId) async {
    try {
      await _pbService.pb.collection('notes').delete(noteId);
      _notes.removeWhere((note) => note.id == noteId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("Error deleting note: $e");
      return false;
    }
  }

  // Toggle Pinned
  Future<bool> togglePin(RecordModel note) async {
    try {
      final isPinned = note.getBoolValue('is_pinned');
      await _pbService.pb.collection('notes').update(note.id, body: {
        'is_pinned': !isPinned,
      });
      // Panggil ulang dari server agar sortirannya benar (Pinned di atas)
      await fetchNotes();
      return true;
    } catch (e) {
      debugPrint("Error toggling pin: $e");
      return false;
    }
  }
}
