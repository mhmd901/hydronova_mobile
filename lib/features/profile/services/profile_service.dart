import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hydronova_mobile/Core/Network/api_client.dart';
import 'package:hydronova_mobile/app/config/api_endpoints.dart';
import 'package:hydronova_mobile/features/auth/services/auth_storage.dart';

class ProfileResult<T> {
  ProfileResult({
    required this.success,
    required this.message,
    this.data,
  });

  final bool success;
  final String message;
  final T? data;

  factory ProfileResult.success(T data, {String message = ''}) {
    return ProfileResult<T>(success: true, message: message, data: data);
  }

  factory ProfileResult.failure(String message) {
    return ProfileResult<T>(success: false, message: message);
  }
}

class ProfileService {
  ProfileService({ApiClient? client}) : _client = client ?? ApiClient();

  final ApiClient _client;
  final AuthStorage _storage = AuthStorage();

  Dio get _dio => _client.dio;

  Future<ProfileResult<Map<String, dynamic>>> updateProfile({
    required String name,
    required String email,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.updateProfilePath,
        data: {
          'name': name,
          'email': email,
        },
      );
      final data = _normalizeResponse(response.data);
      if (data['success'] == true) {
        final userMap = _extractUser(data) ?? {
          'name': name,
          'email': email,
        };
        await _storage.saveUser(userMap);
        return ProfileResult.success(
          userMap,
          message: _extractMessage(data) ?? 'Profile updated',
        );
      }
      final message = _extractMessage(data) ?? 'Unable to update profile';
      return ProfileResult.failure(message);
    } on DioException catch (e) {
      return ProfileResult.failure(_mapDioError(e));
    } catch (e) {
      return ProfileResult.failure(_stringifyError(e));
    }
  }

  Future<ProfileResult<void>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmation,
  }) async {
    try {
      final response = await _dio.post(
        ApiEndpoints.changePasswordPath,
        data: {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': confirmation,
        },
      );
      final data = _normalizeResponse(response.data);
      if (data['success'] == true) {
        return ProfileResult.success(
          null,
          message: _extractMessage(data) ?? 'Password updated',
        );
      }
      final message = _extractMessage(data) ?? 'Unable to update password';
      return ProfileResult.failure(message);
    } on DioException catch (e) {
      return ProfileResult.failure(_mapDioError(e));
    } catch (e) {
      return ProfileResult.failure(_stringifyError(e));
    }
  }

  String _mapDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    if (statusCode == 401) {
      return 'Unauthenticated, please login again';
    }
    final data = _normalizeResponse(error.response?.data);
    if (statusCode == 422) {
      return _extractValidationError(data) ??
          _extractMessage(data) ??
          'Validation error';
    }
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Connection timeout. Please try again.';
    }
    if (statusCode == 500) {
      return 'Server error. Please try again.';
    }
    return _extractMessage(data) ?? 'Request failed';
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

  Map<String, dynamic>? _extractUser(Map<String, dynamic> data) {
    final user = data['user'] ??
        (data['data'] is Map ? (data['data'] as Map)['user'] : null);
    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }
    return null;
  }

  String? _extractMessage(Map<String, dynamic> data) {
    final message = data['message'] ??
        (data['data'] is Map ? (data['data'] as Map)['message'] : null);
    return message?.toString();
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

  String _stringifyError(Object? error) {
    if (error == null) return 'Request failed';
    return error.toString().replaceFirst('Exception: ', '');
  }
}
