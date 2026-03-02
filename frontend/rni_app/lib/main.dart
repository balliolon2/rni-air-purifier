import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rni_app/features/bluetooth/providers/bluetooth_provider.dart';
import 'package:rni_app/features/main/providers/live_chart_provider.dart';
import 'features/main/providers/theme_provider.dart';
import 'features/main/app.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => ChartProvider()),
        ChangeNotifierProxyProvider<ChartProvider, BluetoothProvider>(
          create: (context) => BluetoothProvider(context.read<ChartProvider>()),
          update: (context, chart, previous) =>
              previous ?? BluetoothProvider(chart)
                ..init(),
        ),
      ],
      child: const App(),
    ),
  );
}
