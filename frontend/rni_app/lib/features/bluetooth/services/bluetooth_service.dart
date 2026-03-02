import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';

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
  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;

  //TODO: remove Hardcode UUID (Maybe not)
  String serviceUUID = "6e400001-b5a3-f393-e0a9-e50e24dcca9e";
  String txUUID = "6e400003-b5a3-f393-e0a9-e50e24dcca9e";
  String rxUUID = "6e400002-b5a3-f393-e0a9-e50e24dcca9e";

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

  Stream<String>? listenToDevice(BluetoothDevice device) {
    try {
      if (_txCharacteristic == null) return null;

      _txCharacteristic!.setNotifyValue(true);

      return _txCharacteristic!.onValueReceived.map((value) {
        return String.fromCharCodes(value);
      });
    } catch (e) {
      throw Exception("Failed to listen to device: $e");
    }
  }

  Future<void> sendData(String message) async {
    try {
      await _rxCharacteristic!.write(message.codeUnits);
    } catch (e) {
      throw Exception('Failed to send data: $e');
    }
  }

  Future<bool> sendDataWithAck(
    String message, {
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      await _rxCharacteristic!.write(message.codeUnits, withoutResponse: false);

      // Wait for ESP32 to notify back within timeout
      final response = await _txCharacteristic!.onValueReceived
          .timeout(timeout)
          .first;

      return String.fromCharCodes(response).isNotEmpty;
    } on TimeoutException {
      throw Exception('ESP32 did not respond in time');
    } catch (e) {
      throw Exception('Failed: $e');
    }
  }

  Future<void> discoverServices(BluetoothDevice device) async {
    try {
      _txCharacteristic = null;
      _rxCharacteristic = null;

      final List<BluetoothService> services = await device.discoverServices();
      print("Found ${services.length} services");

      for (BluetoothService service in services) {
        print("Service: ${service.uuid}");
        if (service.uuid.toString().toLowerCase() == serviceUUID) {
          for (BluetoothCharacteristic c in service.characteristics) {
            print("Characteristic: ${c.uuid}");
            if (c.uuid.toString().toLowerCase() == txUUID) {
              _txCharacteristic = c;
              print("TX found");
            }
            if (c.uuid.toString().toLowerCase() == rxUUID) {
              _rxCharacteristic = c;
              print("RX found");
            }
          }
        }
      }

      if (_txCharacteristic == null) {
        throw Exception("TX characteristic not found, check if UUIDs == ESP32");
      }
    } catch (e) {
      throw Exception('Failed to discover services: $e');
    }
  }
}
