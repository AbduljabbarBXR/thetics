import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/profile/models/user_profile.dart';
import '../state/app_controller.dart';
import '../state/providers.dart';
import '../theme/app_palette.dart';
import '../utils/formatters.dart';
import 'surfaces.dart';

Future<void> showLogWeightSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _LogWeightSheet(),
  );
}

class _LogWeightSheet extends ConsumerStatefulWidget {
  const _LogWeightSheet();

  @override
  ConsumerState<_LogWeightSheet> createState() => _LogWeightSheetState();
}

class _LogWeightSheetState extends ConsumerState<_LogWeightSheet> {
  late final TextEditingController _controller;
  late final UnitSystem _units;
  String? _error;

  @override
  void initState() {
    super.initState();
    final data = ref.read(appDataProvider);
    _units = data?.profile?.units ?? UnitSystem.metric;
    final current = data?.currentWeightKg ?? 0;
    _controller = TextEditingController(
      text: current <= 0
          ? ''
          : _units == UnitSystem.metric
              ? current.toStringAsFixed(1)
              : Fmt.kgToLb(current).toStringAsFixed(1),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final raw = double.tryParse(_controller.text.trim().replaceAll(',', '.'));
    if (raw == null) {
      setState(() => _error = 'Enter a valid number.');
      return;
    }
    final kg = _units == UnitSystem.metric ? raw : Fmt.lbToKg(raw);
    if (kg < 30 || kg > 300) {
      setState(() => _error = 'Enter a realistic body weight.');
      return;
    }
    await ref.read(appControllerProvider.notifier).logBodyWeight(kg);
    if (!mounted) return;
    Navigator.of(context).pop();
    showTheticsSnack(context, 'Body weight logged.');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 6,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Log today’s weight',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 6),
          Text(
            'Same time, same conditions. We care about the weekly trend, not a single reading.',
            style: TextStyle(color: p.muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
            ],
            decoration: InputDecoration(
              hintText: '0.0',
              suffixText: _units.weightUnit,
              errorText: _error,
            ),
            onSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('SAVE WEIGH-IN'),
            ),
          ),
        ],
      ),
    );
  }
}
