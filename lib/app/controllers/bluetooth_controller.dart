import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:get/get.dart';
import 'package:hydronova_mobile/features/sensor/services/sensor_upload_service.dart';
import 'package:permission_handler/permission_handler.dart';

enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
}

class BluetoothController extends GetxController {
  final SensorUploadService _sensorUploadService =
      Get.isRegistered<SensorUploadService>()
          ? Get.find<SensorUploadService>()
          : Get.put(SensorUploadService(), permanent: true);
  final Rx<ConnectionStatus> status = ConnectionStatus.disconnected.obs;
  final Rxn<BluetoothDevice> selectedDevice = Rxn<BluetoothDevice>();
  final RxList<BluetoothDevice> pairedDevices = <BluetoothDevice>[].obs;
  final RxList<String> logs = <String>[].obs;
  final StringBuffer buffer = StringBuffer();
  final Rxn<double> temperature = Rxn<double>();
  final Rxn<double> humidity = Rxn<double>();

  BluetoothConnection? connection;
  StreamSubscription<Uint8List>? inputSubscription;

  String _timestamp() {
    final now = DateTime.now();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(now.hour)}:${two(now.minute)}:${two(now.second)}';
  }

  void log(String message) {
    logs.add('[${_timestamp()}] $message');
  }

  Future<int> _readAndroidSdkInt() async {
    if (!Platform.isAndroid) return 0;
    final info = await DeviceInfoPlugin().androidInfo;
    return int.parse(info.version.sdkInt.toString());
  }

  Future<bool> ensureBtPermissions() async {
    if (!Platform.isAndroid) {
      log('[ERROR] This app is Android-only.');
      return false;
    }

    final sdkInt = await _readAndroidSdkInt();
    log('[INFO] Android SDK: $sdkInt');

    try {
      if (sdkInt >= 31) {
        final scan = await Permission.bluetoothScan.request();
        final connect = await Permission.bluetoothConnect.request();
        if (!scan.isGranted || !connect.isGranted) {
          if (scan.isPermanentlyDenied || connect.isPermanentlyDenied) {
            log('[ERROR] Bluetooth permissions permanently denied. Open Settings.');
            await openAppSettings();
          } else {
            log('[ERROR] Bluetooth permissions denied.');
          }
          return false;
        }
      } else {
        final location = await Permission.location.request();
        if (!location.isGranted) {
          if (location.isPermanentlyDenied) {
            log('[ERROR] Location permission permanently denied. Open Settings.');
            await openAppSettings();
          } else {
            log('[ERROR] Location permission denied.');
          }
          return false;
        }
      }
    } catch (error) {
      log('[ERROR] Permission request failed: $error');
      return false;
    }

    return true;
  }

  Future<void> requestPermissions() async {
    log('[ACTION] Request permissions');
    await ensureBtPermissions();
  }

  Future<void> enableBluetooth() async {
    log('[ACTION] Enable Bluetooth');
    final ready = await ensureBtPermissions();
    if (!ready) return;

    try {
      final enabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (enabled != true) {
        log('[INFO] Bluetooth disabled. Requesting enable...');
        final requested = await FlutterBluetoothSerial.instance.requestEnable();
        if (requested != true) {
          log('[ERROR] Bluetooth enable request denied.');
          return;
        }
      }
      final nowEnabled = await FlutterBluetoothSerial.instance.isEnabled;
      log('[INFO] Bluetooth is ${nowEnabled == true ? 'ON' : 'OFF'}.');
    } catch (error) {
      log('[ERROR] Bluetooth enable failed: $error');
    }
  }

  Future<void> loadPairedDevices() async {
    log('[ACTION] Refresh paired devices');
    final ready = await ensureBtPermissions();
    if (!ready) return;

    try {
      final enabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (enabled != true) {
        log('[ERROR] Bluetooth is off. Enable it first.');
        return;
      }
    } catch (error) {
      log('[ERROR] Bluetooth check failed: $error');
      return;
    }

    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      pairedDevices.assignAll(devices);
      if (selectedDevice.value == null && devices.isNotEmpty) {
        selectedDevice.value = devices.first;
      }
      if (devices.isEmpty) {
        log('[INFO] No paired devices. Pair HC-05 first in Android Bluetooth settings (PIN 1234/0000).');
      } else {
        log('[INFO] Found ${devices.length} paired device(s).');
      }
    } catch (error) {
      log('[ERROR] getBondedDevices failed: $error');
    }
  }

  Future<void> connect(BluetoothDevice device) async {
    if (status.value == ConnectionStatus.connecting) return;
    final ready = await ensureBtPermissions();
    if (!ready) return;

    try {
      final enabled = await FlutterBluetoothSerial.instance.isEnabled;
      if (enabled != true) {
        log('[ERROR] Bluetooth is off. Enable it first.');
        return;
      }
    } catch (error) {
      log('[ERROR] Bluetooth check failed: $error');
      return;
    }

    log('[ACTION] Connect to ${device.name ?? device.address}');
    status.value = ConnectionStatus.connecting;
    selectedDevice.value = device;

    try {
      await disconnect();
      final newConnection =
          await BluetoothConnection.toAddress(device.address);
      connection = newConnection;
      status.value = ConnectionStatus.connected;
      log('[INFO] Connected.');
      startListening(newConnection);
    } catch (error) {
      log('[ERROR] Connection failed: $error');
      status.value = ConnectionStatus.disconnected;
    }
  }

  void startListening(BluetoothConnection connection) {
    inputSubscription = connection.input?.listen(
      (Uint8List data) {
        final text = utf8.decode(data, allowMalformed: true);
        buffer.write(text);
        var bufferText = buffer.toString();
        var newlineIndex = bufferText.indexOf('\n');
        while (newlineIndex != -1) {
          final line = bufferText.substring(0, newlineIndex).trim();
          bufferText = bufferText.substring(newlineIndex + 1);
          _handleLine(line);
          newlineIndex = bufferText.indexOf('\n');
        }
        buffer
          ..clear()
          ..write(bufferText);
      },
      onDone: () {
        log('[INFO] Disconnected.');
        _cleanupConnection();
      },
      onError: (Object error) {
        log('[ERROR] Input error: $error');
        _cleanupConnection();
      },
      cancelOnError: true,
    );
  }

  void _handleLine(String line) {
    if (line.isEmpty) return;
    log('[RAW] $line');
    try {
      final parsed = jsonDecode(line);
      if (parsed is Map) {
        final formatted = parsed.entries
            .map((entry) => '${entry.key}=${entry.value}')
            .join(' ');
        log('[JSON] $formatted');
        _updateReadings(parsed);
        final device = selectedDevice.value;
        final deviceId = device?.address ?? device?.name ?? 'HC-05';
        final payload = Map<String, dynamic>.from(parsed);
        unawaited(
          _sensorUploadService.enqueueAndSend(
            payload,
            deviceId,
            log: log,
          ),
        );
      } else {
        log('[JSON] $parsed');
      }
    } catch (error) {
      log('[ERROR] invalid json: $error');
    }
  }

  void _updateReadings(Map<dynamic, dynamic> data) {
    if (data.containsKey('temp')) {
      temperature.value = _toDouble(data['temp']);
    } else if (data.containsKey('temperature')) {
      temperature.value = _toDouble(data['temperature']);
    }

    if (data.containsKey('hum')) {
      humidity.value = _toDouble(data['hum']);
    } else if (data.containsKey('humidity')) {
      humidity.value = _toDouble(data['humidity']);
    }
  }

  double? _toDouble(Object? value) {
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }
    return null;
  }

  Future<void> disconnect() async {
    await inputSubscription?.cancel();
    inputSubscription = null;
    if (connection != null && connection!.isConnected) {
      await connection!.close();
    }
    connection = null;
    status.value = ConnectionStatus.disconnected;
  }

  void _cleanupConnection() {
    inputSubscription?.cancel();
    inputSubscription = null;
    connection = null;
    status.value = ConnectionStatus.disconnected;
  }

  @override
  void onClose() {
    disconnect();
    super.onClose();
  }
}
