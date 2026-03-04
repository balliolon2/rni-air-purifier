import 'dart:async' show StreamSubscription;

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:rni_app/features/bluetooth/services/bluetooth_service.dart';
import 'package:rni_app/features/main/providers/live_chart_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter/foundation.dart';

/// [BluetoothProvider]
///
/// Manages all Bluetooth Low Energy (BLE) states, including:
/// - Connection handling
/// - Data transmission
/// - Adapter state management
/// - Calling BlueService methods
///
/// Acts as the bridge between the UI layer and [BlueService]
/// - UI → Listens and reacts to state changes via [Consumer] or `context.watch`
/// - [BlueService] → Handles BLE logic and raw `flutter_blue_plus` operations
///
/// ---------------------------------------------------------------------------
/// Responsibilities
/// ---------------------------------------------------------------------------
///
/// - Listening to Bluetooth adapter state (on/off/unavailable)
/// - Listening to and parsing incoming data from the ESP32
/// - Sending data to the connected ESP32 device (/TODO)
/// - Forwarding parsed data points to [ChartProvider]
/// - Calling [BlueService] to scan for nearby BLE devices
///   (default filter: `ESP32_BT`)
/// - Calling [BlueService] to connect and disconnect from a BLE device
///
/// ---------------------------------------------------------------------------
/// Provider Registered at main.dart
/// ---------------------------------------------------------------------------
///
/// ```dart
/// ChangeNotifierProxyProvider<ChartProvider, BluetoothProvider>(
///   create: (context) => BluetoothProvider(context.read<ChartProvider>()),
///   update: (context, chart, previous) =>
///     previous ?? BluetoothProvider(chart),
/// )
/// ```
///
/// ---------------------------------------------------------------------------
/// Dependencies
/// ---------------------------------------------------------------------------
///
/// - [BlueService] → Handles raw `flutter_blue_plus` operations
/// - [ChartProvider] → Receives parsed data points for visualization
///

class BluetoothProvider with ChangeNotifier {
  final BlueService _bluetoothService = BlueService();

  ///---STATES---///

  // Self State
  bool _initialized = false; // True if already initialized Listeners
  bool _deviceDisconnecting = false; // Don't log Error if intended

  // Device Connection State
  BluetoothAdapterState _bluetoothAdapterState = BluetoothAdapterState.unknown;
  BluetoothDevice? _connectedDevice;
  StreamSubscription<BluetoothConnectionState>? _connectionStateSubscription;

  // Device Scanning State
  List<ScanResult> _scanResults = [];
  bool _isScanning = false;
  //Stream<String>? _deviceDataStream; // Device found
  StreamSubscription<String>? _dustSubscription;
  StreamSubscription<String>? _tempSubscription;
  StreamSubscription<String>? _humSubscription;

  // ESP32 State
  String _dustData = "";
  String _tempData = "";
  String _humData = "";

  // Error message (For showAlert)
  String? _errorMessage;

  ///---CONSUMERS---///
  final ChartProvider _chartProvider; //For ChartProvider.addPoint()

  BluetoothProvider(this._chartProvider);

  ///---GETTERS---///

  // Connection Getters
  BluetoothAdapterState get bluetoothAdapterState => _bluetoothAdapterState;
  BluetoothDevice? get connectedDevice => _connectedDevice;

  //ESP32 Getters
  String get dustData => _dustData;
  String get tempData => _tempData;
  String get humData => _humData;

  // Device state Getters
  List<ScanResult> get scanResults => _scanResults;
  //String get receivedData => _receivedData;
  bool get isScanning => _isScanning;
  String? get errorMessage => _errorMessage;

  // Initialize Functions
  void init() async {
    if (_initialized) return; // Only initialize once
    _initialized = true;

    await _bluetoothService.init();
    _listenToScanResults();
    _listenToScanningState();
    _listenToAdapter();
  }

  /// ---------------- ///
  /// DEVICE FUNCTIONS ///
  /// ---------------- ///
  // Call BluetoothService to start scanning for bluetooth devices
  Future<void> startScan() async {
    // Check the Adapter state before scanning
    if (_bluetoothAdapterState == BluetoothAdapterState.on) {
      _scanResults.clear();
      await _bluetoothService.startScan();
      notifyListeners();
    } else {
      print("Bluetooth is not enabled");
    }
  }

  // Call BluetoothService to stop scanning for bluetooth devices
  Future<void> stopScan() async {
    await _bluetoothService.stopScan();
    notifyListeners();
  }

  // Connect to ESP32 Device and listen to its connection state
  Future<void> connectToDevice(BluetoothDevice device) async {
    try {
      await _bluetoothService.stopScan();
      await _bluetoothService.connectToDevice(device);

      _connectedDevice = device;

      await _connectionStateSubscription?.cancel();
      _listenToConnectionState(device);

      await _bluetoothService.discoverServices(device);

      // Cancel old subscriptions
      await _dustSubscription?.cancel();
      await _tempSubscription?.cancel();
      await _humSubscription?.cancel();

      // Listen to each sensor separately
      _dustSubscription = _bluetoothService.listenToDust()?.listen((data) {
        _dustData = data;
        final parsed = double.tryParse(data.trim());
        _chartProvider.addData(parsed);
        notifyListeners();
      });

      _tempSubscription = _bluetoothService.listenToTemp()?.listen((data) {
        _tempData = data;
        notifyListeners();
      });

      _humSubscription = _bluetoothService.listenToHum()?.listen((data) {
        _humData = data;
        notifyListeners();
      });

      if (_dustSubscription == null &&
          _tempSubscription == null &&
          _humSubscription == null) {
        print("No characteristics found!");
        return;
      }

      notifyListeners();
    } catch (e) {
      print("Failed to connect: $e");
      notifyListeners();
    }
  }

  // Disconnect from ESP32 device
  Future<void> disconnectDevice() async {
    _deviceDisconnecting = true;

    if (_connectedDevice != null) {
      await _bluetoothService.disconnectDevice(_connectedDevice!);
      _bluetoothService.clearCharacteristics();
      print("Disconnected!");
    }

    await _dustSubscription?.cancel();
    await _tempSubscription?.cancel();
    await _humSubscription?.cancel();
    await _connectionStateSubscription?.cancel();

    _dustSubscription = null;
    _tempSubscription = null;
    _humSubscription = null;
    _connectionStateSubscription = null;

    _connectedDevice = null;
    _dustData = "";
    _tempData = "";
    _humData = "";
    _deviceDisconnecting = false;

    notifyListeners();
  }

  /// --------------- ///
  /// ESP32 FUNCTIONS ///
  /// --------------- ///
  // Send data to ESP32
  Future<void> sendData(String message) async {
    await _bluetoothService.sendData(message);
  }

  // Send data to ESP32 with Ack check
  Future<bool> sendDataWithAck(String message) async {
    return await _bluetoothService.sendDataWithAck(message);
  }

  ///------------///
  /// LISTENERS ///
  ///-----------///

  ///-----------------///
  /// ESP32 LISTENERS ///
  ///-----------------///

  StreamSubscription<BluetoothConnectionState> _listenToConnectionState(
    BluetoothDevice device,
  ) {
    return _connectionStateSubscription = connectionState(device).listen((
      state,
    ) {
      print("Connection state changed: $state");
      if (state == BluetoothConnectionState.disconnected &&
          _deviceDisconnecting == false) {
        _setError(
          "Device disconnected! Please check your device's connection.",
        );
        disconnectDevice();
      }
    });
  }

  Stream<BluetoothConnectionState> connectionState(BluetoothDevice device) {
    return device.connectionState;
  }

  ///-------------------///
  /// DEVICE LISTENERS ///
  ///------------------///
  void _listenToScanningState() async {
    _bluetoothService.isScanning.listen((scanning) {
      print(scanning);
      _isScanning = scanning;
      notifyListeners();
    });
  }

  // Listen to BluetoothService and notify Comsumers on scan results
  void _listenToScanResults() async {
    _bluetoothService.scanResults.listen((results) {
      _scanResults = results;
      notifyListeners();
    });
  }

  void _listenToAdapter() {
    _bluetoothService.adapterState.listen((state) {
      print(state);
      _bluetoothAdapterState = state;
      if (state != BluetoothAdapterState.on) {
        _isScanning = false;
        _scanResults.clear();
        _connectedDevice = null;
      }
      notifyListeners();
    });
  }

  ///---------------------///
  /// PERMISSION HANDLERS ///
  ///---------------------///
  Future<void> requestPermissions() async {
    //TODO: add permission handler for IOS
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      //Permission.location,
    ].request();
  }

  bool deviceIsConnected() {
    if (_connectedDevice != null) {
      return true;
    }
    return false;
  }

  ///----------------///
  /// Error Handlers ///
  ///----------------///
  void _setError(String message) {
    _errorMessage = message;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
