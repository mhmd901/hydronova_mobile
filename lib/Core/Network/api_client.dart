import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/app/routes/app_routes.dart';
import 'package:hydronova_mobile/features/auth/services/auth_service.dart';
import 'package:hydronova_mobile/features/auth/services/auth_storage.dart';

class ApiClient {
  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 20),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    )..interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) async {
            final skipAuth = options.extra['skipAuth'] == true;
            final isProtected = options.path.startsWith('/M_');
            String? token;
            if (!skipAuth && isProtected) {
              token = AuthStorage().getToken();
              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }
            }
            if (kDebugMode) {
              final hasToken = token != null && token.isNotEmpty;
              final authHeader =
                  options.headers['Authorization']?.toString() ?? '';
              final authHeaderPresent = authHeader.isNotEmpty;
              final authPrefix = authHeaderPresent
                  ? _maskAuthHeader(authHeader)
                  : 'none';
              debugPrint(
                '[ApiClient] ${options.method} ${options.uri} '
                '| token_present: $hasToken '
                '| auth_header_present: $authHeaderPresent '
                '| auth_header_prefix: $authPrefix',
              );
            }
            handler.next(options);
          },
          onResponse: (response, handler) async {
            if (_isUnauthenticated(response.statusCode, response.data)) {
              await _handleUnauthenticated();
            }
            handler.next(response);
          },
          onError: (error, handler) async {
            if (_isUnauthenticated(
              error.response?.statusCode,
              error.response?.data,
            )) {
              await _handleUnauthenticated();
            }
            handler.next(error);
          },
        ),
      );
  }

  static final ApiClient _instance = ApiClient._internal();
  static const String _baseUrl = 'https://hydronova.multydo.com';

  factory ApiClient() => _instance;

  late final Dio _dio;
  static bool _handlingUnauthenticated = false;

  Dio get dio => _dio;

  bool _isUnauthenticated(int? statusCode, dynamic data) {
    if (statusCode == 401) return true;
    if (data is Map) {
      final rawMessage = data['message'] ?? data['error'];
      final message = rawMessage?.toString().toLowerCase();
      if (message != null && message.contains('unauthenticated')) {
        return true;
      }
    }
    if (data is String) {
      final message = data.toLowerCase();
      if (message.contains('unauthenticated')) {
        return true;
      }
    }
    return false;
  }

  String _maskAuthHeader(String header) {
    if (!header.startsWith('Bearer ')) {
      return header.length <= 12 ? header : '${header.substring(0, 12)}...';
    }
    final token = header.substring(7);
    if (token.isEmpty) {
      return 'Bearer ';
    }
    final prefixLength = token.length >= 12 ? 12 : token.length;
    final tokenPrefix = token.substring(0, prefixLength);
    return 'Bearer $tokenPrefix...';
  }

  Future<void> _handleUnauthenticated() async {
    if (_handlingUnauthenticated) return;
    _handlingUnauthenticated = true;
    try {
      if (Get.isRegistered<AuthService>()) {
        await Get.find<AuthService>().logout();
      } else {
        await AuthStorage().clearToken();
        if (Get.currentRoute != AppRoutes.login) {
          Get.offAllNamed(AppRoutes.login);
        }
      }
      Get.snackbar('Unauthenticated', 'Unauthenticated, please login again');
    } finally {
      _handlingUnauthenticated = false;
    }
  }
}
