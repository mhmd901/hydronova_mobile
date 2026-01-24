import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

class AssistantService {
  AssistantService({Dio? dio}) : _dio = dio ?? _buildDio();

  static const String _baseUrl = 'https://n8n.multydo.com';
  static const String _endpoint = '/webhook/M_hydronova';
  static const String _appKey = 'hydronova-mobile';

  final Dio _dio;

  static Dio _buildDio() {
    final dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        connectTimeout: const Duration(seconds: 10),
        receiveTimeout: const Duration(seconds: 30),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
          'X-APP-KEY': _appKey,
        },
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          if (kDebugMode) {
            debugPrint(
              '[Assistant] -> ${options.method} ${options.uri} '
              '| headers: ${options.headers}',
            );
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[Assistant] <- ${response.statusCode} ${response.requestOptions.uri} '
              '| data: ${response.data}',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint(
              '[Assistant] !! ${error.requestOptions.uri} '
              '| ${error.type} ${error.message}',
            );
          }
          handler.next(error);
        },
      ),
    );
    return dio;
  }

  Future<String?> sendMessage({
    required String message,
    required String sessionId,
  }) async {
    final payload = {
      'message': message,
      'session_id': sessionId,
      'platform': 'flutter',
      'app': 'hydronova_mobile',
      'ts': DateTime.now().millisecondsSinceEpoch,
    };

    try {
      final response = await _dio.post(_endpoint, data: payload);
      final data = response.data;
      final directReply = _extractReply(data);
      if (directReply != null) {
        return directReply;
      }

      final pendingInfo = _extractPending(data);
      if (pendingInfo != null) {
        return await _pollForReply(
          sessionId: sessionId,
          jobId: pendingInfo.jobId,
          threadId: pendingInfo.threadId,
        );
      }

      if (_isDone(data)) {
        final doneReply = _extractReply(data);
        if (doneReply != null) return doneReply;
      }

      return null;
    } on DioException catch (e) {
      throw Exception(_mapDioError(e));
    } catch (e) {
      throw Exception(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<String?> _pollForReply({
    required String sessionId,
    String? jobId,
    String? threadId,
  }) async {
    final stopwatch = Stopwatch()..start();
    while (stopwatch.elapsedMilliseconds < 25000) {
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      final query = <String, dynamic>{
        'poll': 'true',
        'session_id': sessionId,
      };
      if (jobId != null && jobId.isNotEmpty) {
        query['job_id'] = jobId;
      }
      if (threadId != null && threadId.isNotEmpty) {
        query['threadId'] = threadId;
      }

      try {
        final response = await _dio.get(_endpoint, queryParameters: query);
        final data = response.data;
        final reply = _extractReply(data);
        if (reply != null) {
          return reply;
        }
        if (_isDone(data)) {
          final doneReply = _extractReply(data);
          if (doneReply != null) return doneReply;
          return null;
        }
      } on DioException {
        // ignore transient polling errors
      }
    }
    return 'Still working... please try again.';
  }

  String? _extractReply(dynamic data) {
    if (data == null) return null;
    if (data is String) {
      final trimmed = data.trim();
      return trimmed.isNotEmpty ? trimmed : null;
    }
    if (data is Map) {
      final direct = _readString(data['reply']) ??
          _readString(data['message']) ??
          _readString(data['output']) ??
          _readString(data['text']);
      if (direct != null) return direct;
      if (data['success'] == true && data['data'] is Map) {
        final inner = data['data'] as Map;
        return _readString(inner['reply']) ??
            _readString(inner['message']) ??
            _readString(inner['output']) ??
            _readString(inner['text']);
      }
    }
    return null;
  }

  _PendingInfo? _extractPending(dynamic data) {
    if (data is Map) {
      final status = data['status']?.toString().toLowerCase();
      final jobId = data['job_id']?.toString();
      final threadId = data['threadId']?.toString();
      if (status == 'pending' || status == 'queued') {
        return _PendingInfo(jobId: jobId, threadId: threadId);
      }
      if ((jobId != null && jobId.isNotEmpty) ||
          (threadId != null && threadId.isNotEmpty)) {
        return _PendingInfo(jobId: jobId, threadId: threadId);
      }
    }
    return null;
  }

  bool _isDone(dynamic data) {
    if (data is Map) {
      final status = data['status']?.toString().toLowerCase();
      return status == 'done' || status == 'completed';
    }
    return false;
  }

  String? _readString(dynamic value) {
    if (value == null) return null;
    final text = value.toString().trim();
    return text.isNotEmpty ? text : null;
  }

  String _mapDioError(DioException error) {
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Connection timeout. Please try again.';
    }
    final status = error.response?.statusCode ?? 0;
    if (status >= 500) {
      return 'Server error. Please try again.';
    }
    final data = error.response?.data;
    final message = _extractReply(data);
    if (message != null) return message;
    return 'Request failed. Please try again.';
  }
}

class _PendingInfo {
  _PendingInfo({this.jobId, this.threadId});

  final String? jobId;
  final String? threadId;
}
