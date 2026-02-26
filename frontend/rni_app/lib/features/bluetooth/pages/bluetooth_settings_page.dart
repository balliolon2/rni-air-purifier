import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rni_app/features/bluetooth/pages/bluetooth_scanning_page.dart';
import 'package:rni_app/features/bluetooth/providers/bluetooth_provider.dart';

/*
Index 2: Bluetooth Settings
  There is a device connected:
  false: Bluetooth Scanning Page
  true: Connected Device Page
*/
class BluetoothSettingsPage extends StatefulWidget {
  const BluetoothSettingsPage({super.key});

  @override
  State<BluetoothSettingsPage> createState() => _BluetoothSettingsPageState();
}

class _BluetoothSettingsPageState extends State<BluetoothSettingsPage> {
  @override
  void initState() {
    super.initState();
    // Initialize BluetoothProvider when page loads
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BluetoothProvider>().init();
    });
  }

  @override
  // Choose to show Device Page or Scanning Page
  Widget build(BuildContext context) {
    return const BluetoothScanningPage();
  }
}
