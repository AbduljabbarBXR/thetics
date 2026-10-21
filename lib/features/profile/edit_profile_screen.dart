import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/surfaces.dart';
import 'models/user_profile.dart';

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});

  @override
  ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _heightCm;
  late final TextEditingController _heightFt;
  late final TextEditingController _heightIn;
  late final TextEditingController _weight;
  late final TextEditingController _targetWeight;
  late UnitSystem _units;
  late Sex _sex;
  late Goal _goal;
  late Experience _experience;
  late ActivityLevel _activity;
  late int _trainingDays;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final profile = ref.read(profileProvider)!;
    _units = profile.units;
    _sex = profile.sex;
    _goal = profile.goal;
    _experience = profile.experience;
    _activity = profile.activity;
    _trainingDays = profile.trainingDays;
    _name = TextEditingController(text: profile.name);
    _age = TextEditingController(text: '${profile.age}');
    _heightCm = TextEditingController(
      text: profile.heightCm.toStringAsFixed(0),
    );
    final totalInches = Fmt.cmToIn(profile.heightCm);
    _heightFt = TextEditingController(text: '${totalInches ~/ 12}');
    _heightIn = TextEditingController(
      text: (totalInches % 12).toStringAsFixed(1),
    );

    String weightText(double kg) => _units == UnitSystem.metric
        ? kg.toStringAsFixed(1)
        : Fmt.kgToLb(kg).toStringAsFixed(1);

    _weight = TextEditingController(text: weightText(profile.weightKg));
    _targetWeight = TextEditingController(
      text: profile.targetWeightKg == null
          ? ''
          : weightText(profile.targetWeightKg!),
    );
  }

  @override
  void dispose() {
    for (final controller in [
      _name,
      _age,
      _heightCm,
      _heightFt,
      _heightIn,
      _weight,
      _targetWeight,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _parse(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  double? _heightCmValue() {
    if (_units == UnitSystem.metric) return _parse(_heightCm);
    final feet = _parse(_heightFt);
    final inches = _parse(_heightIn);
    if (feet == null || inches == null) return null;
    return (feet * 12 + inches) * 2.54;
  }

  double? _weightKgValue() {
    final raw = _parse(_weight);
    if (raw == null) return null;
    return _units == UnitSystem.imperial ? Fmt.lbToKg(raw) : raw;
  }

  double? _targetKgValue() {
    final raw = _parse(_targetWeight);
    if (raw == null) return null;
    return _units == UnitSystem.imperial ? Fmt.lbToKg(raw) : raw;
  }

  void _changeUnits(UnitSystem next) {
    if (next == _units) return;
    final heightCm = _heightCmValue();
    final weightKg = _weightKgValue();
    final targetKg = _targetKgValue();
    setState(() {
      _units = next;
      if (heightCm != null) {
        _heightCm.text = heightCm.toStringAsFixed(0);
        final totalInches = Fmt.cmToIn(heightCm);
        _heightFt.text = '${totalInches ~/ 12}';
        _heightIn.text = (totalInches % 12).toStringAsFixed(1);
      }
      if (weightKg != null) {
        _weight.text = next == UnitSystem.metric
            ? weightKg.toStringAsFixed(1)
            : Fmt.kgToLb(weightKg).toStringAsFixed(1);
      }
      if (targetKg != null) {
        _targetWeight.text = next == UnitSystem.metric
            ? targetKg.toStringAsFixed(1)
            : Fmt.kgToLb(targetKg).toStringAsFixed(1);
      }
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final age = int.tryParse(_age.text.trim());
    final height = _heightCmValue();
    final weight = _weightKgValue();
    final target = _targetKgValue();
    if (name.isEmpty) {
      setState(() => _error = 'Name cannot be empty.');
      return;
    }
    if (age == null || age < 14 || age > 90) {
      setState(() => _error = 'Age must be between 14 and 90.');
      return;
    }
    if (height == null || height < 120 || height > 230) {
      setState(() => _error = 'Height must be between 120 and 230 cm.');
      return;
    }
    if (weight == null || weight < 30 || weight > 300) {
      setState(() => _error = 'Weight must be between 30 and 300 kg.');
      return;
    }
    if (target != null && (target < 30 || target > 300)) {
      setState(() => _error = 'Target weight must be between 30 and 300 kg.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final profile = ref.read(profileProvider)!;
    final updated = profile.copyWith(
      name: name,
      age: age,
      sex: _sex,
      heightCm: height,
      weightKg: weight,
      goal: _goal,
      experience: _experience,
      trainingDays: _trainingDays,
      activity: _activity,
      units: _units,
      targetWeightKg: target,
      clearTargetWeight: target == null,
    );
    await ref.read(appControllerProvider.notifier).updateProfile(updated);
    if ((profile.weightKg - weight).abs() > 0.05) {
      await ref.read(appControllerProvider.notifier).logBodyWeight(weight);
    }
    if (!mounted) return;
    showTheticsSnack(context, 'Profile updated.');
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('Edit profile'),
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
          Eyebrow('The baseline', color: p.accent),
          const SizedBox(height: 7),
          Text(
            'KEEP IT\nHONEST.',
            style: text.displaySmall?.copyWith(fontSize: 42, height: 0.88),
          ),
          const SizedBox(height: 8),
          Text(
            'These details feed calorie targets, BMI and the way loads are '
            'displayed. Change them when the facts change.',
            style: TextStyle(color: p.muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Label('NAME'),
                TextField(
                  controller: _name,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(hintText: 'Your name'),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('AGE'),
                          TextField(
                            controller: _age,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            decoration: const InputDecoration(
                              suffixText: 'yrs',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('SEX'),
                          Row(
                            children: [
                              Expanded(
                                child: _SmallChoice(
                                  label: 'Male',
                                  selected: _sex == Sex.male,
                                  onTap: () => setState(() => _sex = Sex.male),
                                ),
                              ),
                              const SizedBox(width: 5),
                              Expanded(
                                child: _SmallChoice(
                                  label: 'Female',
                                  selected: _sex == Sex.female,
                                  onTap: () =>
                                      setState(() => _sex = Sex.female),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Label('UNITS'),
                Row(
                  children: [
                    Expanded(
                      child: _SmallChoice(
                        label: 'Metric · kg / cm',
                        selected: _units == UnitSystem.metric,
                        onTap: () => _changeUnits(UnitSystem.metric),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: _SmallChoice(
                        label: 'Imperial · lb / in',
                        selected: _units == UnitSystem.imperial,
                        onTap: () => _changeUnits(UnitSystem.imperial),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _Label('HEIGHT'),
                if (_units == UnitSystem.metric)
                  TextField(
                    controller: _heightCm,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(suffixText: 'cm'),
                  )
                else
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _heightFt,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(suffixText: 'ft'),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: TextField(
                          controller: _heightIn,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          decoration: const InputDecoration(suffixText: 'in'),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('CURRENT WEIGHT'),
                          TextField(
                            controller: _weight,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              suffixText: Fmt.weightLabel(_units),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _Label('TARGET WEIGHT'),
                          TextField(
                            controller: _targetWeight,
                            keyboardType: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            decoration: InputDecoration(
                              hintText: 'Optional',
                              suffixText: Fmt.weightLabel(_units),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Your mission',
            eyebrow: 'Drives the program and calories',
          ),
          const SizedBox(height: 10),
          ...Goal.values.map((goal) {
            final selected = _goal == goal;
            return Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: GestureDetector(
                onTap: () => setState(() => _goal = goal),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 170),
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: selected ? p.accent.withValues(alpha: 0.07) : p.card,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: selected ? p.accent : p.line),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 18,
                        height: 18,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: selected ? p.accent : p.faint,
                            width: 1.5,
                          ),
                        ),
                        padding: const EdgeInsets.all(3),
                        child: selected
                            ? Container(
                                decoration: BoxDecoration(
                                  color: p.accent,
                                  shape: BoxShape.circle,
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.label,
                              style: TextStyle(
                                color: p.text,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              goal.description,
                              style: TextStyle(
                                color: p.faint,
                                fontSize: 9.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Experience',
            eyebrow: 'Be honest — the plan adapts',
          ),
          const SizedBox(height: 9),
          Row(
            children: Experience.values.map((experience) {
              final selected = _experience == experience;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: experience == Experience.advanced ? 0 : 6,
                  ),
                  child: _SmallChoice(
                    label: experience.label,
                    selected: selected,
                    onTap: () => setState(() => _experience = experience),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 7),
          Text(
            _experience.description,
            style: TextStyle(color: p.faint, fontSize: 10),
          ),
          const SizedBox(height: 18),
          const SectionHeader(title: 'Activity', eyebrow: 'Outside the gym'),
          const SizedBox(height: 9),
          ...ActivityLevel.values.map((activity) {
            final selected = _activity == activity;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: GestureDetector(
                onTap: () => setState(() => _activity = activity),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: selected ? p.accent.withValues(alpha: 0.07) : p.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: selected ? p.accent : p.line),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        selected
                            ? Icons.radio_button_checked_rounded
                            : Icons.radio_button_off_rounded,
                        size: 16,
                        color: selected ? p.accent : p.faint,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          activity.label,
                          style: TextStyle(
                            color: p.text,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Text(
                        activity.description,
                        style: TextStyle(color: p.faint, fontSize: 8.5),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 18),
          const SectionHeader(
            title: 'Training days',
            eyebrow: 'Days per week you can actually repeat',
          ),
          const SizedBox(height: 9),
          Row(
            children: [2, 3, 4, 5, 6].map((days) {
              final selected = _trainingDays == days;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: days == 6 ? 0 : 6),
                  child: GestureDetector(
                    onTap: () => setState(() => _trainingDays = days),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? p.accent : p.card,
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(color: selected ? p.accent : p.line),
                      ),
                      child: Text(
                        '$days',
                        style: TextStyle(
                          color: selected ? p.onAccent : p.muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          if (_error != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(11),
              decoration: BoxDecoration(
                color: p.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: p.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 15, color: p.danger),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: p.danger, fontSize: 10.5),
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
                  : const Text('SAVE PROFILE'),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Changing current weight records a new weigh-in for today.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.faint, fontSize: 9),
          ),
        ],
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: TextStyle(
          color: context.palette.faint,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 1,
        ),
      ),
    );
  }
}

class _SmallChoice extends StatelessWidget {
  const _SmallChoice({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? p.accent : p.card,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: selected ? p.accent : p.line),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: selected ? p.onAccent : p.muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
