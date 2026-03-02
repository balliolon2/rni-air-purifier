import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rni_app/features/bluetooth/providers/bluetooth_provider.dart';

class SendDataButton extends StatefulWidget {
  const SendDataButton({super.key, required this.message});
  final String message;

  @override
  State<SendDataButton> createState() => _SendDataButtonState();
}

class _SendDataButtonState extends State<SendDataButton> {
  bool _isSending = false; //Only send data once

  Future<void> _sendData(BluetoothProvider bluetooth) async {
    if (_isSending) return;
    setState(() => _isSending = true);

    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      await bluetooth.sendDataWithAck(widget.message);
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text("Sent!"),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 1),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 1300));
    } catch (e) {
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text("Could not send: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      await Future.delayed(const Duration(milliseconds: 5300));
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BluetoothProvider>(
      builder: (context, bluetooth, child) {
        return ElevatedButton.icon(
          onPressed: !_isSending ? () => _sendData(bluetooth) : null,
          icon: _isSending
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.send),
          label: Text(_isSending ? "Sending..." : widget.message),
        );
      },
    );
  }
}
