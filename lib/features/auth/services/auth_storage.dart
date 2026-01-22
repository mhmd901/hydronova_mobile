import 'dart:convert';

import 'package:get_storage/get_storage.dart';

class AuthStorage {
  static const String accessTokenKey = 'access_token';
  static const String refreshTokenKey = 'refresh_token';
  static const String userKey = 'user';
  static const String firebaseIdTokenKey = 'firebase_id_token';

  final GetStorage _storage = GetStorage();

  Future<void> saveAuth({
    required String accessToken,
    required String refreshToken,
    required String userJson,
  }) async {
    await _storage.write(accessTokenKey, accessToken);
    await _storage.write(refreshTokenKey, refreshToken);
    await _storage.write(userKey, userJson);
  }

  Future<void> saveToken(String token) async {
    await _storage.write(accessTokenKey, token);
  }

  Future<void> saveUser(Map<String, dynamic> user) async {
    await _storage.write(userKey, jsonEncode(user));
  }

  Future<void> saveFirebaseIdToken(String token) async {
    await _storage.write(firebaseIdTokenKey, token);
  }

  String? getAccessToken() {
    return _storage.read<String>(accessTokenKey);
  }

  String? getToken() {
    return _storage.read<String>(accessTokenKey);
  }

  String? getRefreshToken() {
    return _storage.read<String>(refreshTokenKey);
  }

  String? getFirebaseIdToken() {
    return _storage.read<String>(firebaseIdTokenKey);
  }

  Map<String, dynamic>? getUser() {
    final raw = _storage.read<String>(userKey);
    if (raw == null || raw.isEmpty) return null;
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    } catch (_) {}
    return null;
  }

  Future<void> clear() async {
    await _storage.remove(accessTokenKey);
    await _storage.remove(refreshTokenKey);
    await _storage.remove(userKey);
    await _storage.remove(firebaseIdTokenKey);
  }

  Future<void> clearToken() async {
    await _storage.remove(accessTokenKey);
  }
}
