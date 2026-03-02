import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rni_app/features/main/dialog/show_error_dialog.dart';
import 'package:rni_app/features/bluetooth/providers/bluetooth_provider.dart';
import 'package:rni_app/features/main/providers/live_chart_provider.dart';

/*
  Toggle LivePMChart on/off
*/
class TogglePMChartButton extends StatefulWidget {
  const TogglePMChartButton({super.key});

  @override
  State<TogglePMChartButton> createState() => _TogglePMChartButtonState();
}

class _TogglePMChartButtonState extends State<TogglePMChartButton> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChartProvider>(
      builder: (context, chart, _) {
        final online =
            chart.chartOn &&
            context.watch<BluetoothProvider>().deviceIsConnected();
        return FloatingActionButton(
          onPressed: () {
            if (context.read<BluetoothProvider>().deviceIsConnected()) {
              chart.togglePauseChart();
            } else {
              showAlert(
                context,
                title: "Device is not connected",
                message: "Please connect to ESP32 device first",
              );
            }
          },
          tooltip: 'Chart Toggle',
          child: online ? const Icon(Icons.stop) : const Icon(Icons.play_arrow),
        );
      },
    );
  }
}
