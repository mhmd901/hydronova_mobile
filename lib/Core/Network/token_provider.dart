import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/features/auth/services/auth_storage.dart';

class UnauthenticatedException implements Exception {
  UnauthenticatedException(this.message);

  final String message;

  @override
  String toString() => message;
}

class TokenProvider extends GetxService {
  static const String unauthenticatedMessage =
      'Unauthenticated, please login again';

  final AuthStorage _storage = AuthStorage();

  Future<String> getToken() async {
    final cached = _storage.getFirebaseIdToken();
    if (cached != null && cached.isNotEmpty) {
      return cached;
    }

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw UnauthenticatedException(unauthenticatedMessage);
      }
      final token = await user.getIdToken(false);
      if (token == null || token.isEmpty) {
        throw UnauthenticatedException(unauthenticatedMessage);
      }
      await _storage.saveFirebaseIdToken(token);
      return token;
    } catch (_) {
      throw UnauthenticatedException(unauthenticatedMessage);
    }
  }

  Future<void> clearToken() async {
    await _storage.saveFirebaseIdToken('');
  }
}
