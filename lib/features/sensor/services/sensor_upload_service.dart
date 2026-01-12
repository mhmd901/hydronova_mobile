import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:dio/dio.dart';
import 'package:get/get.dart' hide Response;
import 'package:hydronova_mobile/app/config/api_endpoints.dart';
import 'package:hydronova_mobile/features/auth/services/auth_service.dart';
import 'package:hydronova_mobile/features/sensor/services/sensor_queue_storage.dart';

class SensorUploadService extends GetxService {
  SensorUploadService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiEndpoints.baseUrl,
        connectTimeout: const Duration(seconds: 6),
        receiveTimeout: const Duration(seconds: 10),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final token = _authService?.token;
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final SensorQueueStorage _storage = SensorQueueStorage();
  final List<SensorQueueEvent> _queue = <SensorQueueEvent>[];
  final Random _random = Random.secure();

  late final Dio _dio;
  Timer? _retryTimer;
  bool _queueLoaded = false;
  bool _isFlushing = false;
  void Function(String)? _logger;

  AuthService? get _authService {
    if (Get.isRegistered<AuthService>()) {
      return Get.find<AuthService>();
    }
    return null;
  }

  @override
  void onInit() {
    super.onInit();
    _loadQueueIfNeeded();
    _startRetryTimer();
  }

  @override
  void onClose() {
    _retryTimer?.cancel();
    super.onClose();
  }

  Future<void> enqueueAndSend(
    Map<String, dynamic> payload,
    String deviceId, {
    void Function(String)? log,
  }) async {
    _logger ??= log;
    if (log != null) {
      _logger = log;
    }
    _loadQueueIfNeeded();

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final sanitized = Map<String, dynamic>.from(payload);
    sanitized.putIfAbsent('ts', () => nowMs);
    sanitized.putIfAbsent('device_id', () => deviceId);

    if (!_isJsonEncodable(sanitized)) {
      log?.call('[UPLOAD] failed: payload not serializable');
      return;
    }

    final event = SensorQueueEvent(
      id: _generateId(),
      deviceId: deviceId,
      createdAtMs: nowMs,
      payload: sanitized,
    );

    if (_queue.isNotEmpty) {
      _queue.add(event);
      await _persistQueue();
      log?.call('[UPLOAD] queued');
      _scheduleFlush();
      return;
    }

    final sent = await _trySend(event, log: log);
    if (!sent) {
      _queue.add(event);
      await _persistQueue();
      log?.call('[UPLOAD] queued');
      _scheduleFlush();
    }
  }

  Future<bool> postSensor(
    Map<String, dynamic> payloadMap,
    String deviceId, {
    int? ts,
  }) async {
    final body = {
      'device_id': deviceId,
      'source': 'hc05',
      'ts': ts ?? DateTime.now().millisecondsSinceEpoch,
      'payload': payloadMap,
    };

    final response = await _dio.post('/M_sensor_ingest', data: body);
    if (response.statusCode != 200) return false;
    final data = _normalizeResponse(response.data);
    return data['success'] == true;
  }

  Future<void> flushQueue() async {
    _loadQueueIfNeeded();
    if (_queue.isEmpty || _isFlushing) return;
    _isFlushing = true;
    try {
      var sentCount = 0;
      while (_queue.isNotEmpty && sentCount < 10) {
        final event = _queue.first;
        final sent = await _trySend(event, log: _logger);
        if (!sent) break;
        _queue.removeAt(0);
        await _persistQueue();
        sentCount += 1;
        await _rateLimit();
      }
    } finally {
      _isFlushing = false;
    }
  }

  void _startRetryTimer() {
    _retryTimer ??= Timer.periodic(
      const Duration(seconds: 12),
      (_) => unawaited(flushQueue()),
    );
  }

  void _scheduleFlush() {
    unawaited(flushQueue());
  }

  Future<bool> _trySend(
    SensorQueueEvent event, {
    void Function(String)? log,
  }) async {
    try {
      final ok = await postSensor(
        event.payload,
        event.deviceId,
        ts: event.createdAtMs,
      );
      if (ok) {
        log?.call('[UPLOAD] sent');
      } else {
        log?.call('[UPLOAD] failed: unexpected response');
      }
      return ok;
    } catch (error) {
      log?.call('[UPLOAD] failed: $error');
      return false;
    }
  }

  void _loadQueueIfNeeded() {
    if (_queueLoaded) return;
    _queue.addAll(_storage.readQueue());
    _queueLoaded = true;
  }

  Future<void> _persistQueue() async {
    await _storage.saveQueue(_queue);
  }

  Future<void> _rateLimit() async {
    await Future<void>.delayed(const Duration(seconds: 1));
  }

  bool _isJsonEncodable(Map<String, dynamic> payload) {
    try {
      jsonEncode(payload);
      return true;
    } catch (_) {
      return false;
    }
  }

  String _generateId() {
    String four() =>
        _random.nextInt(1 << 16).toRadixString(16).padLeft(4, '0');
    return '${four()}${four()}-${four()}-${four()}-${four()}-${four()}${four()}${four()}';
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
}
