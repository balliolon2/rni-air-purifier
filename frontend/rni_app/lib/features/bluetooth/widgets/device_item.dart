import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:provider/provider.dart';
import 'package:rni_app/features/bluetooth/providers/bluetooth_provider.dart';

class DeviceItem extends StatefulWidget {
  const DeviceItem({
    super.key,
    required this.name,
    required this.device,
    required this.rssi,
  });

  final String name;
  final BluetoothDevice device;
  final int rssi;

  @override
  State<DeviceItem> createState() => _DeviceItemState();
}

class _DeviceItemState extends State<DeviceItem> {
  bool _isConnecting = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        onTap: _isConnecting
            ? null // Disable tap while connecting
            : () async {
                setState(() => _isConnecting = true);
                try {
                  await context.read<BluetoothProvider>().connectToDevice(
                    widget.device,
                  );
                } catch (e) {
                  print("Connection failed: $e");
                }
              },
        leading: _isConnecting
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.bluetooth, color: Colors.blue),
        title: Text(widget.name),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('ID: ${widget.device.remoteId}'),
            Text('RSSI: ${widget.rssi} dBm'),
          ],
        ),
        trailing: _isConnecting ? const Text("Connecting...") : null,
      ),
    );
  }
}
