import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:provider/provider.dart';
import 'package:rni_app/features/bluetooth/providers/bluetooth_provider.dart';
import 'package:rni_app/features/main/providers/live_chart_provider.dart';

/*
  Show live value of PM2.5 readings as graph, including average
  Listen to LiveChartProvider
*/
class LivePMChart extends StatefulWidget {
  const LivePMChart({super.key});

  @override
  State<LivePMChart> createState() => _LivePMChartState();
}

class _LivePMChartState extends State<LivePMChart> {
  @override
  Widget build(BuildContext context) {
    return Consumer<ChartProvider>(
      builder: (context, chartProvider, _) {
        final graphData = chartProvider.graphData; //Points data
        final maxY = (chartProvider.max <= 0 ? 1 : chartProvider.max * 1.1)
            .ceilToDouble(); //Dynamic chart height
        final average = chartProvider.average;
        final size = chartProvider.timeStep;
        final chartOn = chartProvider.chartOn;
        final online =
            chartOn && context.watch<BluetoothProvider>().deviceIsConnected();
        return Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.blue, width: 1.5),
            borderRadius: BorderRadius.circular(12),
          ),
          height: 280,
          width: 800,
          child: Row(
            children: [
              const Gap(15),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'Status: ',
                            style: TextStyle(fontSize: 24),
                            textAlign: TextAlign.center,
                          ),
                          Text(
                            online ? "ON" : "OFF",
                            style: TextStyle(
                              color: online ? Colors.green : Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: _buildChart(
                        graphData: graphData,
                        maxY: maxY,
                        timeStep: size,
                        average: average,
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(15),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChart({
    required List<FlSpot> graphData,
    required double maxY,
    required double timeStep,
    required double average,
  }) {
    // If no data yet, show placeholder (Not ready to render)
    if (graphData.isEmpty) {
      return Center(
        child: Text(
          'Waiting for data...',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    // If only one data point (Not ready to render)
    if (graphData.length < 2) {
      return Center(
        child: Text(
          'Collecting data... (${graphData.length}/2)',
          style: TextStyle(color: Colors.grey[600], fontSize: 16),
        ),
      );
    }

    // Chart is ready to render
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Expanded(
          child: LineChart(
            LineChartData(
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),

                // Y AXIS
                leftTitles: AxisTitles(
                  axisNameWidget: const Text('Dust (µg/m³)'),
                  axisNameSize: 30,
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: maxY / 5,
                    reservedSize: 50,
                    getTitlesWidget: (value, meta) {
                      return TitleText(value: value);
                    },
                  ),
                ),

                // X AXIS
                bottomTitles: AxisTitles(
                  sideTitleAlignment: SideTitleAlignment.outside,
                  axisNameWidget: const Text('Time (seconds)'),
                  axisNameSize: 30,
                  sideTitles: SideTitles(
                    showTitles: true,
                    interval: (timeStep / 10).roundToDouble(),
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return TitleText(value: value);
                    },
                  ),
                ),
              ),

              minX: -timeStep,
              maxX: 3,
              minY: 0,
              maxY: maxY,

              gridData: FlGridData(
                show: true,
                drawVerticalLine: true,
                horizontalInterval: maxY / 5,
                verticalInterval: timeStep / 5,
              ),

              lineBarsData: [
                LineChartBarData(
                  color: Colors.green,
                  spots: graphData,
                  barWidth: 2,
                  isStrokeCapRound: true,
                  dotData: context.read<ChartProvider>().showDot
                      ? const FlDotData(show: true)
                      : const FlDotData(show: false),
                ),
              ],
            ),
          ),
        ),
        const Gap(2),
        Row(
          children: [
            Text(
              'Average dust (in $timeStep seconds): ',
              style: const TextStyle(fontSize: 16),
            ),
            Text(
              average.toStringAsFixed(2),
              style: const TextStyle(fontSize: 18, color: Colors.blue),
            ),
          ],
        ),
        const Gap(6),
      ],
    );
  }
}

class TitleText extends StatelessWidget {
  final double value;

  const TitleText({super.key, required this.value});

  @override
  Widget build(BuildContext context) {
    return Text(value.toStringAsFixed(0), style: const TextStyle(fontSize: 14));
  }
}
