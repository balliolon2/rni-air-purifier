import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:rni_app/features/bluetooth/providers/bluetooth_provider.dart';

class LiveSensorSummary extends StatefulWidget {
  const LiveSensorSummary({super.key});

  @override
  State<LiveSensorSummary> createState() => _LiveSensorSummaryState();
}

class _LiveSensorSummaryState extends State<LiveSensorSummary> {
  @override
  Widget build(BuildContext context) {
    final deviceConnected = context
        .watch<BluetoothProvider>()
        .deviceIsConnected();
    return (deviceConnected)
        ? SizedBox(
            width: 220,
            child: Consumer<BluetoothProvider>(
              builder: (context, bluetooth, _) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 30,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Live Sensor Data",
                        style: TextStyle(
                          fontSize: 14,
                          letterSpacing: 1,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const Text(
                        "Dust",
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        "${bluetooth.dustData} µg/m³",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4),
                      const Text(
                        "Temperature",
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        "${bluetooth.tempData} °C",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(4),
                      const Text(
                        "Humidity",
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                      Text(
                        "${bluetooth.humData} %",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          )
        : const SizedBox.shrink();
  }
}
