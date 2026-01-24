import 'dart:math';

import 'package:shared_preferences/shared_preferences.dart';

class SessionId {
  static const String _storageKey = 'assistant_session_id';

  static Future<String> getOrCreate() async {
    final prefs = await SharedPreferences.getInstance();
    final existing = prefs.getString(_storageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final generated = _generateId();
    await prefs.setString(_storageKey, generated);
    return generated;
  }

  static String _generateId() {
    final random = Random.secure();
    final now = DateTime.now().millisecondsSinceEpoch;
    final partA = random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    final partB = random.nextInt(1 << 32).toRadixString(16).padLeft(8, '0');
    return 'sess_${now}_$partA$partB';
  }
}
