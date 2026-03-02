import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rni_app/features/main/dialog/show_error_dialog.dart';
import 'package:rni_app/features/bluetooth/providers/bluetooth_provider.dart';

/*
Green - ESP32 Device connected
Red - ESP32 Device not found/connected
*/

class DeviceConnectionState extends StatefulWidget {
  const DeviceConnectionState({super.key});

  @override
  State<DeviceConnectionState> createState() => _DeviceConnectionStateState();
}

class _DeviceConnectionStateState extends State<DeviceConnectionState> {
  @override
  // Show alert when error message is when ESP32 connection is lost
  void didChangeDependencies() {
    super.didChangeDependencies();

    final bluetooth = context.watch<BluetoothProvider>();
    if (bluetooth.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        showAlert(
          context,
          title: "Disconnected!",
          message: bluetooth.errorMessage!,
        );
        bluetooth.clearError();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, bluetooth, _) {
        final isConnected = bluetooth.deviceIsConnected();

        return GestureDetector(
          onTap: () {
            showAlert(
              context,
              title: "Device State",
              message: isConnected
                  ? "The device is currently connected."
                  : "The device is not connected. Ensure that ESP32 is connected correctly.",
            );
          },
          child: Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isConnected ? Colors.green : Colors.red,
            ),
          ),
        );
      },
    );
  }
}
