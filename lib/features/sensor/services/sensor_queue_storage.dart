import 'package:get_storage/get_storage.dart';

class SensorQueueEvent {
  SensorQueueEvent({
    required this.id,
    required this.deviceId,
    required this.createdAtMs,
    required this.payload,
  });

  final String id;
  final String deviceId;
  final int createdAtMs;
  final Map<String, dynamic> payload;

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'device_id': deviceId,
      'created_at_ms': createdAtMs,
      'payload': payload,
    };
  }

  static SensorQueueEvent? fromMap(Map<String, dynamic> map) {
    final id = map['id']?.toString();
    final deviceId = map['device_id']?.toString();
    final createdAtMs = map['created_at_ms'];
    final payload = map['payload'];
    if (id == null || id.isEmpty || deviceId == null || deviceId.isEmpty) {
      return null;
    }
    if (createdAtMs is! int) {
      return null;
    }
    if (payload is! Map) {
      return null;
    }
    return SensorQueueEvent(
      id: id,
      deviceId: deviceId,
      createdAtMs: createdAtMs,
      payload: Map<String, dynamic>.from(payload),
    );
  }
}

class SensorQueueStorage {
  static const String queueKey = 'sensor_upload_queue';
  final GetStorage _storage = GetStorage();

  List<SensorQueueEvent> readQueue() {
    final raw = _storage.read(queueKey);
    if (raw is! List) return <SensorQueueEvent>[];
    final events = <SensorQueueEvent>[];
    for (final item in raw) {
      if (item is Map) {
        final event =
            SensorQueueEvent.fromMap(Map<String, dynamic>.from(item));
        if (event != null) {
          events.add(event);
        }
      }
    }
    return events;
  }

  Future<void> saveQueue(List<SensorQueueEvent> events) async {
    final encoded = events.map((event) => event.toMap()).toList();
    await _storage.write(queueKey, encoded);
  }
}
