import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:rni_app/features/bluetooth/providers/bluetooth_provider.dart';
import 'package:rni_app/features/bluetooth/widgets/connected_device_print_screen.dart';

class ConnectedDevicePage extends StatelessWidget {
  const ConnectedDevicePage({super.key, required this.device});
  final BluetoothDevice device;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          device.platformName.isEmpty ? "Unknown" : device.platformName,
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_disabled),
            onPressed: () {
              context.read<BluetoothProvider>().disconnect();
            },
          ),
        ],
      ),
      body: const SafeArea(child: ConnectedDevicePrintScreen()),
    );
  }
}
