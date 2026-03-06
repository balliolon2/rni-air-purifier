import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

//live_chart_provider
class ChartProvider with ChangeNotifier {
  double _timeStep = 10;
  double get timeStep => _timeStep;

  final List<FlSpot> _graphData = [];
  List<FlSpot> get graphData => _graphData;

  double _average = 0;
  double get average => _average;

  double _max = 0;
  double get max => _max;

  bool _chartOn = false;
  bool get chartOn => _chartOn;

  bool _showDot = true;
  bool get showDot => _showDot;

  bool _fanOn = false;
  bool get fanOn => _fanOn;
  /*
    METHODS:
  */
  void addData(double? newValue) {
    //Do nothing if the chart is Paused
    if (_chartOn == false) {
      return;
    }

    // Shift all points left by 1
    for (int i = 0; i < _graphData.length; i++) {
      _graphData[i] = FlSpot(_graphData[i].x - 1, _graphData[i].y);
    }
    // If no data given, only shift and return
    if (newValue is! double) {
      print("Data is not of type double:$newValue");
      notifyListeners();
      return;
    }
    // Remove oldest point if we exceed size limit
    _graphData.removeWhere((spot) => spot.x < -_timeStep);

    // Add new point at x=0
    _graphData.add(FlSpot(0, newValue));

    // Calculate average, max
    if (_graphData.isNotEmpty) {
      _average =
          _graphData.map((e) => e.y).reduce((a, b) => a + b) /
          _graphData.length;
      _max = _graphData.map((e) => e.y).reduce((a, b) => a > b ? a : b);
    } else {
      _average = 0;
      _max = 0;
    }

    notifyListeners();
  }

  void togglePauseChart() {
    if (_chartOn == true) {
      // Toggle the chart on
      _chartOn = false;
    } else {
      // Reset the chart and start
      _graphData.clear();
      _average = 0;
      _max = 0;
      _chartOn = true;
    }
    notifyListeners();
  }

  void changeChartTime(double newTimeStep) {
    _timeStep = newTimeStep;
    notifyListeners();
  }

  void toggleDot() {
    _showDot = !_showDot;
    notifyListeners();
  }

  void setFanState(bool value) {
    _fanOn = value;
    notifyListeners();
  }
}
