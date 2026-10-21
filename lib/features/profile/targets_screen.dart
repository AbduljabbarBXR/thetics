import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/nutrition_math.dart';
import '../../core/widgets/surfaces.dart';
import 'models/user_profile.dart';

class TargetsScreen extends ConsumerStatefulWidget {
  const TargetsScreen({super.key});

  @override
  ConsumerState<TargetsScreen> createState() => _TargetsScreenState();
}

class _TargetsScreenState extends ConsumerState<TargetsScreen> {
  late MacroTargets _auto;
  late bool _custom;
  late final TextEditingController _calories;
  late final TextEditingController _protein;
  late final TextEditingController _carbs;
  late final TextEditingController _fat;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider)!;
    _auto = calculateMacroTargets(profile.copyWith(clearCustomTargets: true));
    _custom = profile.hasCustomTargets;
    _calories = TextEditingController(
      text: '${profile.calorieOverride ?? _auto.calories}',
    );
    _protein = TextEditingController(
      text: '${profile.proteinOverride ?? _auto.protein}',
    );
    _carbs = TextEditingController(
      text: '${profile.carbsOverride ?? _auto.carbs}',
    );
    _fat = TextEditingController(text: '${profile.fatOverride ?? _auto.fat}');
  }

  @override
  void dispose() {
    for (final controller in [_calories, _protein, _carbs, _fat]) {
      controller.dispose();
    }
    super.dispose();
  }

  int? _value(TextEditingController controller) =>
      int.tryParse(controller.text.trim());

  void _toggleCustom(bool value) {
    setState(() {
      _custom = value;
      if (value) {
        _calories.text = '${_auto.calories}';
        _protein.text = '${_auto.protein}';
        _carbs.text = '${_auto.carbs}';
        _fat.text = '${_auto.fat}';
      }
      _error = null;
    });
  }

  Future<void> _resetAuto() async {
    final confirmed = await confirmAction(
      context,
      title: 'Reset to calculated targets?',
      message: 'Your manual calorie and macro targets will be removed. The app '
          'will calculate from your profile, goal and activity again.',
      confirmLabel: 'Reset',
    );
    if (!confirmed) return;
    final profile = ref.read(profileProvider)!;
    await ref
        .read(appControllerProvider.notifier)
        .updateProfile(profile.copyWith(clearCustomTargets: true));
    if (!mounted) return;
    setState(() {
      _custom = false;
      _calories.text = '${_auto.calories}';
      _protein.text = '${_auto.protein}';
      _carbs.text = '${_auto.carbs}';
      _fat.text = '${_auto.fat}';
    });
    showTheticsSnack(context, 'Targets reset to the calculated plan.');
  }

  Future<void> _save() async {
    final profile = ref.read(profileProvider)!;
    if (!_custom) {
      setState(() => _saving = true);
      await ref
          .read(appControllerProvider.notifier)
          .updateProfile(profile.copyWith(clearCustomTargets: true));
      if (!mounted) return;
      Navigator.of(context).pop(true);
      return;
    }
    final calories = _value(_calories);
    final protein = _value(_protein);
    final carbs = _value(_carbs);
    final fat = _value(_fat);
    if (calories == null || calories < 1000 || calories > 8000) {
      setState(() => _error = 'Calories must be between 1,000 and 8,000.');
      return;
    }
    if (protein == null || protein < 0 || protein > 500) {
      setState(() => _error = 'Protein must be between 0 and 500 g.');
      return;
    }
    if (carbs == null || carbs < 0 || carbs > 1000) {
      setState(() => _error = 'Carbs must be between 0 and 1,000 g.');
      return;
    }
    if (fat == null || fat < 20 || fat > 400) {
      setState(() => _error = 'Fat must be between 20 and 400 g.');
      return;
    }
    final macroCalories = protein * 4 + carbs * 4 + fat * 9;
    if ((macroCalories - calories).abs() > 250) {
      setState(
        () => _error =
            'Macros add up to ${macroCalories.round()} kcal, which is more '
                'than 250 kcal away from your calorie target. Adjust one of them.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    await ref.read(appControllerProvider.notifier).updateProfile(
          profile.copyWith(
            calorieOverride: calories,
            proteinOverride: protein,
            carbsOverride: carbs,
            fatOverride: fat,
          ),
        );
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final profile = ref.watch(profileProvider);
    if (profile == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Nutrition targets')),
        body: Center(
          child: CircularProgressIndicator(color: p.accent, strokeWidth: 2),
        ),
      );
    }
    final goalAdjustment = switch (profile.goal) {
      Goal.fatLoss => '−20%',
      Goal.aesthetics => '−6%',
      Goal.muscle => '+12%',
      Goal.strength => '+8%',
    };
    final shownCalories =
        _custom ? _value(_calories) ?? _auto.calories : _auto.calories;
    final shownProtein =
        _custom ? _value(_protein) ?? _auto.protein : _auto.protein;
    final shownCarbs = _custom ? _value(_carbs) ?? _auto.carbs : _auto.carbs;
    final shownFat = _custom ? _value(_fat) ?? _auto.fat : _auto.fat;
    final macroCalories = shownProtein * 4 + shownCarbs * 4 + shownFat * 9;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('Nutrition targets'),
        actions: [
          TextButton(
            onPressed: _saving ? null : _save,
            child: const Text('Save'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Eyebrow('Mifflin–St Jeor + honest math', color: p.accent),
          const SizedBox(height: 7),
          Text(
            'FUEL THE\\nWORK.',
            style: text.displaySmall?.copyWith(fontSize: 42, height: 0.88),
          ),
          const SizedBox(height: 8),
          Text(
            'Targets are a starting estimate, not a law. Track weight, lifts, '
            'hunger and energy for two to three weeks, then adjust based on '
            'what actually happens.',
            style: TextStyle(color: p.muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 18),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 15),
            child: Column(
              children: [
                Row(
                  children: [
                    _EnergyStat(
                      label: 'BMR',
                      value: '${_auto.bmr.round()}',
                      note: 'at rest',
                      color: p.sky,
                    ),
                    _EnergyStat(
                      label: 'TDEE',
                      value: '${_auto.tdee.round()}',
                      note: 'maintenance',
                      color: p.lilac,
                    ),
                    _EnergyStat(
                      label: 'TARGET',
                      value: '$shownCalories',
                      note: goalAdjustment,
                      color: p.accent,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  padding: const EdgeInsets.all(11),
                  decoration: BoxDecoration(
                    color: p.cardHigh,
                    borderRadius: BorderRadius.circular(11),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.calculate_outlined, size: 15, color: p.faint),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${profile.goal.label} applies a $goalAdjustment energy '
                          'adjustment. BMR and TDEE are estimates from age, sex, '
                          'height, weight and activity — not metabolic testing.',
                          style: TextStyle(
                            color: p.faint,
                            fontSize: 9.5,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Macro split',
            eyebrow:
                _custom ? 'Your manual numbers' : 'Calculated for your goal',
          ),
          const SizedBox(height: 10),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
            child: Column(
              children: [
                _MacroRow(
                  label: 'Protein',
                  grams: shownProtein,
                  calories: shownProtein * 4,
                  totalCalories: shownCalories,
                  color: p.accent,
                ),
                const SizedBox(height: 12),
                _MacroRow(
                  label: 'Carbohydrate',
                  grams: shownCarbs,
                  calories: shownCarbs * 4,
                  totalCalories: shownCalories,
                  color: p.sky,
                ),
                const SizedBox(height: 12),
                _MacroRow(
                  label: 'Fat',
                  grams: shownFat,
                  calories: shownFat * 9,
                  totalCalories: shownCalories,
                  color: p.ember,
                ),
                const SizedBox(height: 12),
                Divider(color: p.line),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Macros total',
                      style: TextStyle(color: p.muted, fontSize: 10.5),
                    ),
                    const Spacer(),
                    Text(
                      '$macroCalories kcal',
                      style: TextStyle(
                        color: (macroCalories - shownCalories).abs() <= 100
                            ? p.success
                            : p.ember,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(16, 5, 16, 5),
            child: TheticsSwitch(
              title: 'Custom targets',
              subtitle:
                  'Override the calculated plan. Useful when a coach gives you '
                  'numbers or you have tracked your own maintenance for weeks.',
              value: _custom,
              onChanged: _toggleCustom,
              icon: Icons.tune_rounded,
            ),
          ),
          if (_custom) ...[
            const SizedBox(height: 12),
            SurfaceCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _MacroField(
                          label: 'CALORIES',
                          controller: _calories,
                          suffix: 'kcal',
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _MacroField(
                          label: 'PROTEIN',
                          controller: _protein,
                          suffix: 'g',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 11),
                  Row(
                    children: [
                      Expanded(
                        child: _MacroField(
                          label: 'CARBS',
                          controller: _carbs,
                          suffix: 'g',
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: _MacroField(
                          label: 'FAT',
                          controller: _fat,
                          suffix: 'g',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      onPressed: _resetAuto,
                      icon: const Icon(Icons.restart_alt_rounded, size: 16),
                      label: const Text('RESET TO CALCULATED'),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: p.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.error_outline_rounded, size: 15, color: p.danger),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: p.danger,
                        fontSize: 10.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      _custom
                          ? 'SAVE CUSTOM TARGETS'
                          : 'USE CALCULATED TARGETS',
                    ),
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.card.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: p.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline_rounded, size: 16, color: p.accent),
                    const SizedBox(width: 7),
                    Text(
                      'RATES, NOT MIRACLES',
                      style: TextStyle(
                        color: p.accent,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'A sensible fat-loss rate is roughly 0.5–1% of body weight per '
                  'week. A lean gain phase is far slower: about 0.25–0.5% per '
                  'week, or 1–2 kg per month for many people. Faster is usually '
                  'water, glycogen, gut contents or muscle loss — not magic.\\n\\n'
                  'These numbers are general education, not medical or dietetic '
                  'advice. If you have a health condition, history of disordered '
                  'eating or specific dietary needs, work with a qualified '
                  'professional.\\n\\n'
                  'Daily targets never need to be perfect. A weekly average '
                  'that is close beats a single “perfect” day.',
                  style: TextStyle(color: p.faint, fontSize: 10, height: 1.55),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Protein: ${Fmt.macros(_auto.protein)} · Carbs: ${Fmt.macros(_auto.carbs)} · Fat: ${Fmt.macros(_auto.fat)}',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.faint, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _EnergyStat extends StatelessWidget {
  const _EnergyStat({
    required this.label,
    required this.value,
    required this.note,
    required this.color,
  });

  final String label;
  final String value;
  final String note;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 14, height: 2.5, color: color),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: p.faint,
                  fontSize: 7,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 23, height: 1),
          ),
          const SizedBox(height: 2),
          Text(note, style: TextStyle(color: p.faint, fontSize: 8.5)),
        ],
      ),
    );
  }
}

class _MacroRow extends StatelessWidget {
  const _MacroRow({
    required this.label,
    required this.grams,
    required this.calories,
    required this.totalCalories,
    required this.color,
  });

  final String label;
  final int grams;
  final int calories;
  final int totalCalories;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pct =
        totalCalories <= 0 ? 0.0 : (calories / totalCalories).clamp(0.0, 1.0);
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: TextStyle(
                color: p.text,
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              '${grams}g',
              style: TextStyle(
                color: p.text,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 7),
            SizedBox(
              width: 53,
              child: Text(
                '${(pct * 100).round()}% · $calories kcal',
                textAlign: TextAlign.right,
                maxLines: 1,
                style: TextStyle(color: p.faint, fontSize: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: LinearProgressIndicator(
            value: pct,
            minHeight: 5,
            backgroundColor: p.line,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }
}

class _MacroField extends StatelessWidget {
  const _MacroField({
    required this.label,
    required this.controller,
    required this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: context.palette.faint,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: InputDecoration(suffixText: suffix),
        ),
      ],
    );
  }
}
