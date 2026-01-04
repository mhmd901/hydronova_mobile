import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide Response;
import 'package:hydronova_mobile/app/config/api_endpoints.dart';
import 'package:hydronova_mobile/features/auth/services/auth_service.dart';

class ApiService extends GetxService {
  ApiService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 12),
        sendTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) =>
            status != null && status >= 200 && status < 300,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _authService?.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          if (kDebugMode) {
            debugPrint('Request: ${options.method} ${options.uri}');
            debugPrint('Request data: ${options.data}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint('Response status: ${response.statusCode}');
            debugPrint('Response data: ${response.data}');
          }
          handler.next(response);
        },
        onError: (DioException error, handler) {
          if (kDebugMode) {
            debugPrint('Dio error: ${error.type}');
            debugPrint('Dio error response: ${error.response?.data}');
          }
          final data = error.response?.data;
          if (data is String &&
              (data.trimLeft().startsWith('<!DOCTYPE html>') ||
                  data.trimLeft().startsWith('<html'))) {
            handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                response: error.response,
                type: error.type,
                error: 'Wrong endpoint or server returned HTML',
              ),
            );
            return;
          }
          handler.next(error);
        },
      ),
    );
  }

  late final Dio _dio;
  AuthService? get _authService {
    if (Get.isRegistered<AuthService>()) {
      return Get.find<AuthService>();
    }
    return null;
  }

  Future<Response<dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      return await _dio.post(path, data: data);
    } on TimeoutException {
      throw Exception('Connection timeout. Please try again.');
    } on DioException catch (e) {
      if (e.error is String) {
        throw Exception(e.error);
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> get(String path) async {
    try {
      return await _dio.get(path);
    } on TimeoutException {
      throw Exception('Connection timeout. Please try again.');
    } on DioException catch (e) {
      if (e.error is String) {
        throw Exception(e.error);
      }
      rethrow;
    }
  }

  void clearAuthHeader() {
    _dio.options.headers.remove('Authorization');
  }
}
