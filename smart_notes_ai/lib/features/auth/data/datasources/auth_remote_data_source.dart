import 'package:pocketbase/pocketbase.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../services/pocketbase_service.dart';

abstract class AuthRemoteDataSource {
  Future<RecordModel> login(String email, String password);
  Future<RecordModel> loginWithGoogle();
  Future<RecordModel> register(String name, String email, String password, String passwordConfirm);
  Future<void> logout();
  Future<RecordModel?> getCurrentUser();
  Future<void> requestPasswordReset(String email);
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  final PocketBaseService pbService;

  AuthRemoteDataSourceImpl({required this.pbService});

  @override
  Future<RecordModel> login(String email, String password) async {
    final authRecord = await pbService.pb.collection('users').authWithPassword(email, password);
    return authRecord.record;
  }

  @override
  Future<RecordModel> loginWithGoogle() async {
    // Requires url_launcher
    final authRecord = await pbService.pb.collection('users').authWithOAuth2(
      'google',
      (url) async {
        final uri = Uri.parse(url.toString());
        if (!await launchUrl(uri)) {
          throw Exception('Could not launch $url');
        }
      },
      createData: {
        "tier": "free",
        "ai_quota_used": 0,
      },
    );
    return authRecord.record;
  }

  @override
  Future<RecordModel> register(String name, String email, String password, String passwordConfirm) async {
    final body = <String, dynamic>{
      "name": name,
      "email": email,
      "emailVisibility": true,
      "password": password,
      "passwordConfirm": passwordConfirm,
      "tier": "free",
      "ai_quota_used": 0,
    };

    return await pbService.pb.collection('users').create(body: body);
  }

  @override
  Future<void> logout() async {
    pbService.logout();
  }

  @override
  Future<RecordModel?> getCurrentUser() async {
    if (pbService.isAuthenticated) {
      return pbService.currentUser;
    }
    return null;
  }

  @override
  Future<void> requestPasswordReset(String email) async {
    await pbService.pb.collection('users').requestPasswordReset(email);
  }
}
