import 'dart:async';

import 'package:dio/dio.dart';
import 'package:get/get.dart' show GetxService;
import 'package:hydronova_mobile/Core/Network/api_client.dart';

class ApiService extends GetxService {
  ApiService() {
    _dio = ApiClient().dio;
  }

  late final Dio _dio;

  Future<Response<dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
    bool skipAuth = false,
  }) async {
    try {
      return await _dio.post(
        path,
        data: data,
        options: Options(extra: {'skipAuth': skipAuth}),
      );
    } on TimeoutException {
      throw Exception('Connection timeout. Please try again.');
    } on DioException catch (e) {
      if (e.error is String) {
        throw Exception(e.error);
      }
      rethrow;
    }
  }

  Future<Response<dynamic>> get(
    String path, {
    bool skipAuth = false,
  }) async {
    try {
      return await _dio.get(
        path,
        options: Options(extra: {'skipAuth': skipAuth}),
      );
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
