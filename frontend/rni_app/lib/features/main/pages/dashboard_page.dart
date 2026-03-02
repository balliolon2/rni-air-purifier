import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rni_app/features/bluetooth/providers/bluetooth_provider.dart';
import 'package:rni_app/features/bluetooth/widgets/sendDatabutton.dart';
import 'package:rni_app/features/main/widgets/live_pm_chart.dart';
import 'package:rni_app/features/main/widgets/toggle_pm_chart_button.dart';

/*
Index 1: Dashboard Page
  Contain Graphs, Charts and device controls
*/
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});
  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        elevation: 0,
      ),
      body: Center(
        child: Column(
          children: [
            const LivePMChart(),
            context.watch<BluetoothProvider>().deviceIsConnected()
                ? const SendDataButton(
                    message: "Fan toggle",
                  ) // TODO: sync fan status and change the widget from Button to Switch
                : const SizedBox.shrink(), // Show nada
          ],
        ),
      ),
      floatingActionButton: const TogglePMChartButton(),
    );
  }
}
