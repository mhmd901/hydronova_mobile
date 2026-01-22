import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart' hide Response;
import 'package:hydronova_mobile/Core/Network/api_service.dart';
import 'package:hydronova_mobile/app/config/api_endpoints.dart';
import 'package:hydronova_mobile/app/routes/app_routes.dart';
import 'package:hydronova_mobile/features/auth/services/auth_storage.dart';

class AuthResult {
  AuthResult({
    required this.accessToken,
    required this.refreshToken,
    required this.user,
    required this.message,
  });

  final String accessToken;
  final String refreshToken;
  final dynamic user;
  final String message;
}

class AuthService extends GetxService {
  final AuthStorage _storage = AuthStorage();
  ApiService get _apiService => Get.find<ApiService>();

  String _accessToken = '';
  String _refreshToken = '';

  String? get token => _accessToken.isNotEmpty ? _accessToken : null;

  bool get isLoggedIn => _accessToken.isNotEmpty;

  Future<String?> getIdToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }
      return await user.getIdToken(false);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to fetch Firebase ID token: $e');
      }
      return null;
    }
  }

  Future<String?> getFreshIdToken() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        return null;
      }
      return await user.getIdToken(true);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('Failed to refresh Firebase ID token: $e');
      }
      return null;
    }
  }

  Future<void> loadToken() async {
    _accessToken = _storage.getAccessToken() ?? '';
    _refreshToken = _storage.getRefreshToken() ?? '';
  }

  Future<AuthResult> register({
    required String name,
    required String email,
    required String password,
    String? passwordConfirmation,
  }) async {
    try {
      final confirmation = (passwordConfirmation == null ||
              passwordConfirmation.trim().isEmpty)
          ? password
          : passwordConfirmation.trim();
      final response = await _apiService.post(
        ApiEndpoints.registerPath,
        data: {
          'name': name,
          'email': email,
          'password': password,
          'password_confirmation': confirmation,
        },
        skipAuth: true,
      );

      _logResponse('Register', response);

      final data = _normalizeResponse(response.data);
      _throwIfHtml(response.data);

      final accessToken = _extractAccessToken(data);
      final refreshToken = _extractRefreshToken(data);
      final message = _extractMessage(data);

      if (accessToken.isEmpty) {
        debugPrint('Register response missing access_token: $data');
        throw Exception('Token missing from response');
      }

      await _saveTokens(accessToken, refreshToken, _extractUser(data));

      return AuthResult(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: _extractUser(data),
        message: message ?? '',
      );
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.loginPath,
        data: {
          'email': email,
          'password': password,
        },
        skipAuth: true,
      );

      _logResponse('Login', response);

      final data = _normalizeResponse(response.data);
      _throwIfHtml(response.data);

      final accessToken = _extractAccessToken(data);
      final refreshToken = _extractRefreshToken(data);
      final message = _extractMessage(data);

      if (accessToken.isEmpty) {
        debugPrint('Login response missing access_token: $data');
        throw Exception('Token missing from response');
      }

      await _saveTokens(accessToken, refreshToken, _extractUser(data));

      return AuthResult(
        accessToken: accessToken,
        refreshToken: refreshToken,
        user: _extractUser(data),
        message: message ?? '',
      );
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    }
  }

  Future<void> logout() async {
    _accessToken = '';
    _refreshToken = '';
    await _storage.clear();
    if (Get.isRegistered<ApiService>()) {
      Get.find<ApiService>().clearAuthHeader();
    }
    Get.offAllNamed(AppRoutes.login);
  }

  Future<void> clearAuth() async {
    _accessToken = '';
    _refreshToken = '';
    await _storage.clear();
    if (Get.isRegistered<ApiService>()) {
      Get.find<ApiService>().clearAuthHeader();
    }
  }

  Future<void> _saveTokens(
    String accessToken,
    String refreshToken,
    dynamic user,
  ) async {
    _accessToken = accessToken;
    _refreshToken = refreshToken;
    await _storage.saveAuth(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userJson: _encodeUser(user),
    );
  }

  void _logResponse(String label, Response response) {
    if (kDebugMode) {
      debugPrint('$label status: ${response.statusCode}');
      debugPrint('$label data: ${response.data}');
    }
  }

  void _throwIfHtml(dynamic data) {
    if (data is String) {
      final trimmed = data.trimLeft();
      if (trimmed.startsWith('<!DOCTYPE html>') || trimmed.startsWith('<html')) {
        throw Exception('Wrong endpoint or server returned HTML');
      }
    }
  }

  Map<String, dynamic> _normalizeResponse(dynamic data) {
    if (data == null) return <String, dynamic>{};
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) {
          return Map<String, dynamic>.from(decoded);
        }
      } catch (_) {}
    }
    return <String, dynamic>{};
  }

  String _extractAccessToken(Map<String, dynamic> data) {
    final token = data['access_token'] ??
        data['token'] ??
        (data['data'] is Map ? (data['data'] as Map)['access_token'] : null);
    return token?.toString() ?? '';
  }

  String _extractRefreshToken(Map<String, dynamic> data) {
    final token = data['refresh_token'] ??
        (data['data'] is Map ? (data['data'] as Map)['refresh_token'] : null);
    return token?.toString() ?? '';
  }

  dynamic _extractUser(Map<String, dynamic> data) {
    return data['user'] ??
        (data['data'] is Map ? (data['data'] as Map)['user'] : null);
  }

  String? _extractMessage(Map<String, dynamic> data) {
    final message = data['message'] ??
        (data['data'] is Map ? (data['data'] as Map)['message'] : null);
    return message?.toString();
  }

  String _mapDioError(DioException error) {
    if (error.error is String) {
      return error.error.toString();
    }
    if (error.type == DioExceptionType.connectionTimeout) {
      return 'Server is slow. Please try again.';
    }
    final statusCode = error.response?.statusCode ?? 0;
    final rawData = error.response?.data;
    if (rawData is String &&
        rawData.trimLeft().startsWith('<!DOCTYPE html>')) {
      return 'Wrong endpoint or server returned HTML';
    }
    if (statusCode == 422) {
      final data = _normalizeResponse(rawData);
      return _extractMessage(data) ??
          _extractValidationError(data) ??
          'Validation error';
    }
    if (statusCode == 500) {
      return 'Server error';
    }
    final data = _normalizeResponse(rawData);
    return _extractMessage(data) ?? 'Unable to authenticate at this time';
  }

  String? _extractValidationError(Map<String, dynamic> data) {
    final errors = data['errors'];
    if (errors is Map) {
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          return value.first.toString();
        }
        if (value != null) {
          return value.toString();
        }
      }
    }
    return null;
  }

  String _encodeUser(dynamic userJson) {
    if (userJson == null) return '{}';
    if (userJson is String) return userJson;
    try {
      return jsonEncode(userJson);
    } catch (_) {
      return '{}';
    }
  }
}
