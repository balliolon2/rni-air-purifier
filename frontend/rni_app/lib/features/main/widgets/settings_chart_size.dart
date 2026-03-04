import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:rni_app/features/main/providers/live_chart_provider.dart';

class SettingsChartSize extends StatelessWidget {
  const SettingsChartSize({super.key});

  @override
  Widget build(BuildContext context) {
    return const InputForm();
  }
}

class InputForm extends StatefulWidget {
  const InputForm({super.key});

  @override
  State<InputForm> createState() => _InputFormState();
}

class _InputFormState extends State<InputForm> {
  final TextEditingController controller = TextEditingController();
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  String? forceErrorText;
  bool isLoading = false;
  bool isSuccess = false;

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  // Validate the input value is a positive double and not empty.
  String? validator(String? value) {
    if (value == null || value.isEmpty) {
      return 'This field is required';
    }
    final double? valueToDouble = double.tryParse(value);
    if (valueToDouble == null) {
      return 'Please input numbers';
    }
    if (valueToDouble <= 0) {
      return 'Invalid value';
    }
    return null;
  }

  // Clear error state when the input changes.
  void onChanged(String value) {
    // Nullify forceErrorText if the input changed.
    if (forceErrorText != null || isSuccess) {
      setState(() {
        forceErrorText = null;
        isSuccess = false;
      });
    }
  }

  // Save the input value to the provider if it's valid, and show a success indicator.
  Future<void> onSave() async {
    // Providing a default value in case this was called on the
    // first frame, the [fromKey.currentState] will be null.
    final bool isValid = formKey.currentState?.validate() ?? false;

    if (!isValid) {
      return;
    }
    context.read<ChartProvider>().changeChartTime(
      double.parse(controller.text),
    );
    await displaySuccessIcon();
  }

  // Show a success indicator for 1.5 seconds after saving the value.
  Future<void> displaySuccessIcon() async {
    // Notify that the operation is completed for 1.5 seconds
    setState(() {
      isSuccess = true;
    });
    await Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) {
        setState(() {
          isSuccess = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Form(
        key: formKey,
        child: Row(
          children: [
            SizedBox(
              width: 200,
              child: TextFormField(
                forceErrorText: forceErrorText,
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Chart Time Steps (seconds)',
                  hintStyle: TextStyle(fontSize: 14, color: Colors.grey),
                ),
                validator: validator,
                onChanged: onChanged,
              ),
            ),
            if (isSuccess)
              const Icon(Icons.check, color: Colors.green)
            else
              TextButton(onPressed: onSave, child: const Text('Save')),
          ],
        ),
      ),
    );
  }
}
