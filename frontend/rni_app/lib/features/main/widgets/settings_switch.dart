import 'package:flutter/material.dart';

//Reusable Switch Widget
class SettingsSwitch extends StatelessWidget {
  final String text;
  final bool value;
  final ValueChanged<bool> onChanged;

  const SettingsSwitch({
    super.key,
    required this.text,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Switch(value: value, onChanged: onChanged),
      title: Text(text, style: const TextStyle(fontSize: 18)),
    );
  }
}
