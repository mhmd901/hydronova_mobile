import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
}

class BluetoothController extends GetxController {
  final RxList<String> logs = <String>[].obs;
  final RxList<BluetoothDevice> pairedDevices = <BluetoothDevice>[].obs;
  final Rxn<BluetoothDevice> selectedDevice = Rxn<BluetoothDevice>();
  final Rx<ConnectionStatus> status =
      ConnectionStatus.disconnected.obs;
  final RxnDouble temperature = RxnDouble();
  final RxnDouble humidity = RxnDouble();
  final RxnDouble waterLevel = RxnDouble();
  final Rxn<DateTime> lastUpdate = Rxn<DateTime>();

  final StringBuffer _buffer = StringBuffer();
  BluetoothConnection? _connection;
  StreamSubscription<Uint8List>? _inputSubscription;

  @override
  void onInit() {
    super.onInit();
    _log('Bluetooth controller ready.');
  }

  String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }

  void _log(String message) {
    logs.add('[${_timestamp()}] $message');
  }

  Future<int> _readAndroidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return int.parse(info.version.sdkInt.toString());
  }

  Future<bool> ensureBtPermissions() async {
    if (!Platform.isAndroid) {
      _log('[ERROR] This app is Android-only.');
      return false;
    }

    final sdkInt = await _readAndroidSdkInt();
    _log('[INFO] Android SDK: $sdkInt');

    try {
      if (sdkInt >= 31) {
        final scan = await Permission.bluetoothScan.request();
        final connect = await Permission.bluetoothConnect.request();
        if (!scan.isGranted || !connect.isGranted) {
          if (scan.isPermanentlyDenied || connect.isPermanentlyDenied) {
            _log('[ERROR] Bluetooth permissions permanently denied. Open Settings.');
            await openAppSettings();
          } else {
            _log('[ERROR] Bluetooth permissions denied.');
          }
          return false;
        }
      } else {
        final location = await Permission.location.request();
        if (!location.isGranted) {
          if (location.isPermanentlyDenied) {
            _log('[ERROR] Location permission permanently denied. Open Settings.');
            await openAppSettings();
          } else {
            _log('[ERROR] Location permission denied.');
          }
          return false;
        }
      }
    } catch (error) {
      _log('[ERROR] Permission request failed: $error');
      return false;
    }

    return true;
  }

  Future<void> requestPermissions() async {
    _log('[ACTION] Request permissions');
    await ensureBtPermissions();
  }

  Future<void> enableBluetooth() async {
    _log('[ACTION] Enable Bluetooth');
    final ready = await ensureBtPermissions();
    if (!ready) return;

    try {
      final enabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (enabled != true) {
        _log('[INFO] Bluetooth disabled. Requesting enable...');
        final requested = await FlutterBluetoothSerial.instance.requestEnable();
        if (requested != true) {
          _log('[ERROR] Bluetooth enable request denied.');
          return;
        }
      }
      final nowEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      _log('[INFO] Bluetooth is ${nowEnabled == true ? 'ON' : 'OFF'}.');
    } catch (error) {
      _log('[ERROR] Bluetooth enable failed: $error');
    }
  }

  Future<void> loadPairedDevices() async {
    _log('[ACTION] Refresh paired devices');
    final ready = await ensureBtPermissions();
    if (!ready) return;

    try {
      final enabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (enabled != true) {
        _log('[ERROR] Bluetooth is off. Enable it first.');
        return;
      }
    } catch (error) {
      _log('[ERROR] Bluetooth check failed: $error');
      return;
    }

    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      pairedDevices.assignAll(devices);
      if (selectedDevice.value == null && devices.isNotEmpty) {
        selectedDevice.value = devices.first;
      }
      if (devices.isEmpty) {
        _log('[INFO] No paired devices. Pair HC-05 first in Android Bluetooth settings (PIN 1234/0000).');
      } else {
        _log('[INFO] Found ${devices.length} paired device(s).');
      }
    } catch (error) {
      _log('[ERROR] getBondedDevices failed: $error');
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    if (status.value == ConnectionStatus.connecting) return;
    final ready = await ensureBtPermissions();
    if (!ready) return;

    try {
      final enabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (enabled != true) {
        _log('[ERROR] Bluetooth is off. Enable it first.');
        return;
      }
    } catch (error) {
      _log('[ERROR] Bluetooth check failed: $error');
      return;
    }

    _log('[ACTION] Connect to ${device.name ?? device.address}');
    status.value = ConnectionStatus.connecting;
    selectedDevice.value = device;

    try {
      await disconnect();
      final connection = await BluetoothConnection.toAddress(device.address);
      _connection = connection;
      status.value = ConnectionStatus.connected;
      _log('[INFO] Connected.');
      _startListening(connection);
    } catch (error) {
      _log('[ERROR] Connection failed: $error');
      status.value = ConnectionStatus.disconnected;
    }
  }

  void _startListening(BluetoothConnection connection) {
    _inputSubscription?.cancel();
    _inputSubscription = connection.input?.listen(
      (Uint8List data) {
        final text = utf8.decode(data, allowMalformed: true);
        _buffer.write(text);
        var bufferText = _buffer.toString();
        var newlineIndex = bufferText.indexOf('\n');
        while (newlineIndex != -1) {
          final line = bufferText.substring(0, newlineIndex).trim();
          bufferText = bufferText.substring(newlineIndex + 1);
          _handleLine(line);
          newlineIndex = bufferText.indexOf('\n');
        }
        _buffer
          ..clear()
          ..write(bufferText);
      },
      onDone: () {
        _log('[INFO] Disconnected.');
        _cleanupConnection();
      },
      onError: (Object error) {
        _log('[ERROR] Input error: $error');
        _cleanupConnection();
      },
      cancelOnError: true,
    );
  }

  void _handleLine(String line) {
    if (line.isEmpty) return;
    _log('[RAW] $line');
    try {
      final parsed = jsonDecode(line);
      if (parsed is Map) {
        _log('[JSON] ${parsed.entries.map((entry) => '${entry.key}=${entry.value}').join(' ')}');
        _updateSensorValues(parsed);
      } else {
        _log('[JSON] $parsed');
      }
    } catch (error) {
      if (_tryParsePlainPayload(line)) {
        return;
      }
      _log('[ERROR] invalid json: $error');
    }
  }

  bool _tryParsePlainPayload(String line) {
    final match = RegExp(
      r'(-?\d+(?:\.\d+)?)\s*[cC]\s*,?\s*(-?\d+(?:\.\d+)?)\s*%?',
    ).firstMatch(line);
    final levelMatch = RegExp(
      r'level\s*[:=]\s*(-?\d+(?:\.\d+)?)\s*%?',
      caseSensitive: false,
    ).firstMatch(line);
    if (match == null) return false;
    final temp = double.tryParse(match.group(1) ?? '');
    final hum = double.tryParse(match.group(2) ?? '');
    final level = levelMatch == null
        ? null
        : double.tryParse(levelMatch.group(1) ?? '');
    if (temp == null && hum == null && level == null) return false;
    if (temp != null) {
      temperature.value = temp;
    }
    if (hum != null) {
      humidity.value = hum;
    }
    if (level != null) {
      waterLevel.value = level;
    }
    lastUpdate.value = DateTime.now();
    _log('[PARSED] temp=$temp hum=$hum level=$level');
    return true;
  }

  void _updateSensorValues(Map<dynamic, dynamic> parsed) {
    final temp = _pickNumber(parsed, const ['temp', 'temperature', 't']);
    final hum = _pickNumber(parsed, const ['humidity', 'hum', 'h']);
    final level =
        _pickNumber(parsed, const ['level', 'water', 'waterlevel', 'wl']);
    if (temp != null) {
      temperature.value = temp;
    }
    if (hum != null) {
      humidity.value = hum;
    }
    if (level != null) {
      waterLevel.value = level;
    }
    if (temp != null || hum != null || level != null) {
      lastUpdate.value = DateTime.now();
    }
  }

  double? _pickNumber(Map<dynamic, dynamic> parsed, List<String> keys) {
    final matchKeys = keys.map((key) => key.toLowerCase()).toSet();
    for (final entry in parsed.entries) {
      final entryKey = entry.key.toString().toLowerCase();
      if (!matchKeys.contains(entryKey)) continue;
      final value = entry.value;
      if (value is num) return value.toDouble();
      if (value is String) {
        final parsedValue = double.tryParse(value);
        if (parsedValue != null) return parsedValue;
      }
    }
    return null;
  }

  Future<void> disconnect() async {
    await _inputSubscription?.cancel();
    _inputSubscription = null;
    if (_connection != null && _connection!.isConnected) {
      await _connection!.close();
    }
    _connection = null;
    status.value = ConnectionStatus.disconnected;
  }

  void _cleanupConnection() {
    _inputSubscription?.cancel();
    _inputSubscription = null;
    _connection = null;
    status.value = ConnectionStatus.disconnected;
  }

  Color statusColor() {
    switch (status.value) {
      case ConnectionStatus.connected:
        return const Color(0xFF2E7D32);
      case ConnectionStatus.connecting:
        return const Color(0xFFFF8F00);
      case ConnectionStatus.disconnected:
        return const Color(0xFFC62828);
    }
  }

  String statusText() {
    switch (status.value) {
      case ConnectionStatus.connected:
        return 'CONNECTED';
      case ConnectionStatus.connecting:
        return 'CONNECTING';
      case ConnectionStatus.disconnected:
        return 'DISCONNECTED';
    }
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
