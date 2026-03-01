import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:rni_app/features/main/dialog/show_error_dialog.dart';
import 'package:rni_app/features/bluetooth/providers/bluetooth_provider.dart';

class BluetoothScanButton extends StatelessWidget {
  const BluetoothScanButton({super.key});

  @override
  Widget build(BuildContext context) {
    final bluetooth = context.watch<BluetoothProvider>();

    return FloatingActionButton(
      onPressed: () {
        if (bluetooth.bluetoothAdapterState == BluetoothAdapterState.on) {
          bluetooth.isScanning ? bluetooth.stopScan() : bluetooth.startScan();
        } else {
          showAlert(
            context,
            title: "Bluetooth Disabled",
            message: "Please enable Bluetooth in your device settings",
          );
        }
      },
      child: Icon(bluetooth.isScanning ? Icons.stop : Icons.search),
    );
  }
}
