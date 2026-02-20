import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
  bool pause = false;
  @override
  Widget build(BuildContext context) {
    return FloatingActionButton(
      onPressed: () {
        setState(() {
          context.read<ChartProvider>().togglePauseChart();
          pause = !pause;
        });
      },
      tooltip: 'Chart Toggle',
      child: pause ? Icon(Icons.pause) : Icon(Icons.loop),
    );
  }
}
