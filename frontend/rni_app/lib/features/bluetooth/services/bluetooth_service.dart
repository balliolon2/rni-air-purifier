import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rni_app/features/main/providers/live_chart_provider.dart';

/// [BlueService] (Not to be confused with `BluetoothService` from `flutter_blue_plus` package)
///
/// A [singleton] (only one instance) service responsible for handling Bluetooth Low Energy (BLE)
/// communication logic using the `flutter_blue_plus` package. Works closely with [BluetoothProvider],
/// which consumes this service to expose reactive state to the UI.
///
/// This service is responsible for:
/// - Scanning for nearby BLE devices
/// - Connecting and disconnecting from a BLE device
/// - Discovering BLE services and characteristics
/// - Subscribing to incoming notifications from the ESP32 (TX)
/// - Writing outgoing data to the ESP32 (RX)
///
/// ## Singleton Pattern
/// [BlueService] is implemented as a singleton to ensure only one instance
/// manages the BLE adapter and characteristics at any time.
///
/// ```dart
/// final service = BlueService(); // Always returns the same instance
/// ```
///
/// ## BLE Communication Model
/// ```
/// Flutter (RX Write) ──► ESP32 RX Characteristic (6E400002)
/// Flutter (TX Notify) ◄── ESP32 TX Characteristic (6E400003)
///                         └── Both under Nordic UART Service (6E400001)
/// ```
/// ---------------------------------------------------------------------------
/// Dependencies
/// ---------------------------------------------------------------------------
///
/// - [BluetoothProvider] → Handles incoming/ongoing data and state managements
///

class BlueService {
  // Init as Singleton service for managing Bluetooth operations
  static final BlueService instance = BlueService._internal();

  factory BlueService() {
    return instance;
  }

  BlueService._internal();
  // ...

  // FlutterBluePlus Getters
  Stream<List<ScanResult>> get scanResults => FlutterBluePlus.onScanResults;
  Stream<BluetoothAdapterState> get adapterState =>
      FlutterBluePlus.adapterState;
  Stream<bool> get isScanning => FlutterBluePlus.isScanning;

  //BLE characteristic
  BluetoothCharacteristic? _dustCharacteristic;
  BluetoothCharacteristic? _tempCharacteristic;
  BluetoothCharacteristic? _humCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;
  BluetoothCharacteristic? _responseCharacteristic;

  String serviceUUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  String rxUUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";
  String dustTxUUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e"; // Dust Sensor
  String tempTxUUID = "6e400004-b5a3-f393-e0a9-e50e24dcca9e"; // Temp Sensor
  String humTxUUID = "6e400005-b5a3-f393-e0a9-e50e24dcca9e"; // Humidity Sensor
  String responseUUID =
      "6e400006-b5a3-f393-e0a9-e50e24dcca9e"; // Listen to ESP32 Response

  Stream<String>? listenToDust() =>
      _createStream(_dustCharacteristic); // Listen to Dust sensor Readings
  Stream<String>? listenToTemp() =>
      _createStream(_tempCharacteristic); // Listen to DHT22 Temp Readings
  Stream<String>? listenToHum() =>
      _createStream(_humCharacteristic); // Listen to DHT22 Humidity Readings
  Stream<String>? listenToResponse() =>
      _createStream(_responseCharacteristic); // Listen to ACK Response

  Stream<String>? _createStream(BluetoothCharacteristic? characteristic) {
    if (characteristic == null) return null;
    characteristic.setNotifyValue(true);
    return characteristic.onValueReceived.map(
      (value) => String.fromCharCodes(value),
    );
  }

  // Called from BluetoothProvider.init(). Only check if the class is initialized correctly
  Future<void> init() async {
    if (await FlutterBluePlus.isSupported == false) {
      throw Exception('Bluetooth is not supported by this device');
    }
  }

  Future<void> startScan({
    Duration timeout = const Duration(seconds: 60),
    List<String> keywords = const ["ESP32_BT"], //Default Device Name
  }) async {
    try {
      await FlutterBluePlus.startScan(
        timeout: timeout,
        androidLegacy: true,
        withKeywords: keywords,
      );
    } catch (e) {
      throw Exception("Failed to start scan: $e");
    }
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      throw Exception("Failed to stop scan: $e");
    }
  }

  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      // Connect to chosen device
      await device.connect(license: License.free);
    } catch (e) {
      throw Exception('Failed to connect: $e');
    }
  }

  Future<void> disconnectDevice(BluetoothDevice device) async {
    try {
      await device.disconnect();
    } catch (e) {
      throw Exception("Couldn't disconnect: $e");
    }
  }

  Future<void> sendData(String message) async {
    try {
      await _rxCharacteristic!.write(message.codeUnits);
    } catch (e) {
      throw Exception('Failed to send data: $e');
    }
  }

  Future<String> sendDataWithAck(
    String message, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    if (_rxCharacteristic == null) throw Exception('RX not found');
    if (_responseCharacteristic == null) throw Exception('Response not found');

    final responseFuture = _responseCharacteristic!.onValueReceived
        .timeout(timeout, onTimeout: (sink) => sink.add([]))
        .first;

    await _rxCharacteristic!.write(message.codeUnits, withoutResponse: false);

    try {
      final response = await responseFuture;
      if (response.isEmpty) throw Exception('ESP32 did not respond in time');
      return String.fromCharCodes(response);
    } catch (e) {
      throw Exception('Failed awaiting response: $e');
    }
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    try {
      clearCharacteristics();

      final List<BluetoothService> services = await device.discoverServices();
      print("Found ${services.length} services");

      for (BluetoothService service in services) {
        if (service.uuid.toString().toLowerCase() == serviceUUID) {
          for (BluetoothCharacteristic c in service.characteristics) {
            final uuid = c.uuid.toString().toLowerCase();
            print("Characteristic: $uuid");

            if (uuid == dustTxUUID.toLowerCase()) {
              _dustCharacteristic = c;
              print("Dust TX found");
            } else if (uuid == tempTxUUID.toLowerCase()) {
              _tempCharacteristic = c;
              print("Temp TX found");
            } else if (uuid == humTxUUID.toLowerCase()) {
              _humCharacteristic = c;
              print("Hum TX found");
            } else if (uuid == rxUUID.toLowerCase()) {
              _rxCharacteristic = c;
              print("RX found");
            } else if (uuid == responseUUID.toLowerCase()) {
              _responseCharacteristic = c;
              await _responseCharacteristic!.setNotifyValue(true);
              print("Response(ACK) found");
            }
          }
        }
      }

      if (_dustCharacteristic == null &&
          _tempCharacteristic == null &&
          _humCharacteristic == null) {
        throw Exception(
          "No TX characteristics found — check UUIDs match ESP32",
        );
      }
    } catch (e) {
      throw Exception('Failed to discover services: $e');
    }
  }

  void clearCharacteristics() {
    _dustCharacteristic = null;
    _tempCharacteristic = null;
    _humCharacteristic = null;
    _rxCharacteristic = null;
    _responseCharacteristic = null;
  }
}
