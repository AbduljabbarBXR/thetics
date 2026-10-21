import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/bmi.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/nutrition_math.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/surfaces.dart';
import '../profile/models/user_profile.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final _pageController = PageController();
  final _name = TextEditingController();
  final _age = TextEditingController(text: '28');
  final _heightCm = TextEditingController(text: '178');
  final _heightFt = TextEditingController(text: '5');
  final _heightIn = TextEditingController(text: '10');
  final _weight = TextEditingController(text: '80');
  final _targetWeight = TextEditingController();

  int _page = 0;
  Sex _sex = Sex.male;
  UnitSystem _units = UnitSystem.metric;
  Goal _goal = Goal.aesthetics;
  Experience _experience = Experience.beginner;
  ActivityLevel _activity = ActivityLevel.moderate;
  int _trainingDays = 4;
  String? _error;
  bool _saving = false;

  static const _pageCount = 4;

  @override
  void dispose() {
    _pageController.dispose();
    _name.dispose();
    _age.dispose();
    _heightCm.dispose();
    _heightFt.dispose();
    _heightIn.dispose();
    _weight.dispose();
    _targetWeight.dispose();
    super.dispose();
  }

  void _goTo(int page) {
    setState(() {
      _page = page;
      _error = null;
    });
    _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  void _next() {
    HapticFeedback.selectionClick();
    if (_page == 0) {
      _goTo(1);
      return;
    }
    if (!_validateStep(_page)) return;
    if (_page < _pageCount) {
      _goTo(_page + 1);
    }
  }

  bool _validateStep(int page) {
    String? error;
    if (page == 1) {
      if (_name.text.trim().isEmpty) {
        error = 'Give us a name to personalise Thetics.';
      }
      final age = int.tryParse(_age.text.trim());
      if (error == null && (age == null || age < 14 || age > 90)) {
        error = 'Enter an age between 14 and 90.';
      }
    }
    if (page == 2) {
      final height = _heightCmValue();
      final weight = _weightKgValue();
      if (height == null || height < 120 || height > 230) {
        error = 'Enter a height between 120 and 230 cm (3\'11"–7\'7").';
      } else if (weight == null || weight < 30 || weight > 300) {
        error = 'Enter a weight between 30 and 300 kg.';
      }
    }
    if (page == 3) {
      if (_trainingDays < 2 || _trainingDays > 6) {
        error = 'Choose between 2 and 6 training days.';
      }
    }
    setState(() => _error = error);
    return error == null;
  }

  double? _heightCmValue() {
    if (_units == UnitSystem.metric) {
      return _parse(_heightCm.text);
    }
    final feet = _parse(_heightFt.text);
    final inches = _parse(_heightIn.text);
    if (feet == null || inches == null) return null;
    return (feet * 12 + inches) * 2.54;
  }

  double? _weightKgValue() {
    final value = _parse(_weight.text);
    if (value == null) return null;
    return _units == UnitSystem.metric ? value : Fmt.lbToKg(value);
  }

  double? _targetWeightKgValue() {
    final value = _parse(_targetWeight.text);
    if (value == null) return null;
    return _units == UnitSystem.metric ? value : Fmt.lbToKg(value);
  }

  double? _parse(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  void _changeUnits(UnitSystem next) {
    if (next == _units) return;
    final height = _heightCmValue();
    final weight = _weightKgValue();
    final target = _targetWeightKgValue();
    setState(() {
      _units = next;
      if (height != null) {
        if (next == UnitSystem.metric) {
          _heightCm.text = height.round().toString();
        } else {
          final totalInches = Fmt.cmToIn(height);
          _heightFt.text = (totalInches ~/ 12).toString();
          _heightIn.text = (totalInches % 12).round().toString();
        }
      }
      if (weight != null) {
        _weight.text = next == UnitSystem.metric
            ? weight.toStringAsFixed(1)
            : Fmt.kgToLb(weight).toStringAsFixed(1);
      }
      if (target != null) {
        _targetWeight.text = next == UnitSystem.metric
            ? target.toStringAsFixed(1)
            : Fmt.kgToLb(target).toStringAsFixed(1);
      }
    });
  }

  UserProfile _buildProfile() {
    final height = _heightCmValue() ?? 178;
    final weight = _weightKgValue() ?? 80;
    final age = int.tryParse(_age.text.trim()) ?? 28;
    return UserProfile(
      name: _name.text.trim().isEmpty ? 'Athlete' : _name.text.trim(),
      sex: _sex,
      age: age,
      heightCm: height,
      weightKg: weight,
      goal: _goal,
      experience: _experience,
      trainingDays: _trainingDays,
      activity: _activity,
      units: _units,
      createdAt: DateTime.now(),
      targetWeightKg: _targetWeightKgValue(),
    );
  }

  Future<void> _finish() async {
    if (!_validateStep(3)) return;
    setState(() => _saving = true);
    final profile = _buildProfile();
    try {
      await ref
          .read(appControllerProvider.notifier)
          .completeOnboarding(profile, programId: _goal.recommendedProgramId);
      HapticFeedback.mediumImpact();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final pages = <Widget>[
      _IntroPage(onStart: _next),
      _BasicsPage(
        name: _name,
        age: _age,
        sex: _sex,
        onSex: (sex) => setState(() => _sex = sex),
      ),
      _FramePage(
        units: _units,
        heightCm: _heightCm,
        heightFt: _heightFt,
        heightIn: _heightIn,
        weight: _weight,
        targetWeight: _targetWeight,
        onUnits: _changeUnits,
        onChanged: () => setState(() {}),
      ),
      _MissionPage(
        goal: _goal,
        experience: _experience,
        activity: _activity,
        trainingDays: _trainingDays,
        onGoal: (goal) => setState(() => _goal = goal),
        onExperience: (experience) => setState(() => _experience = experience),
        onActivity: (activity) => setState(() => _activity = activity),
        onDays: (days) => setState(() => _trainingDays = days),
      ),
      _BlueprintPage(profile: _buildProfile()),
    ];

    return Scaffold(
      backgroundColor: p.bg,
      body: Stack(
        children: [
          const _OnboardingBackdrop(),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                  child: Row(
                    children: [
                      if (_page > 0)
                        IconButton(
                          onPressed: () => _goTo(_page - 1),
                          icon: const Icon(Icons.arrow_back_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: p.card,
                            side: BorderSide(color: p.line),
                          ),
                        )
                      else
                        const AppMark(size: 38),
                      const SizedBox(width: 10),
                      const Wordmark(fontSize: 22),
                      const Spacer(),
                      if (_page > 0)
                        Text(
                          '${(_page).toString().padLeft(2, '0')} / ${(_pageCount).toString().padLeft(2, '0')}',
                          style: TextStyle(
                            color: p.faint,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.5,
                          ),
                        ),
                    ],
                  ),
                ),
                if (_page > 0)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 6),
                    child: Row(
                      children: List.generate(_pageCount, (index) {
                        final active = index + 1 <= _page;
                        return Expanded(
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            height: 3,
                            margin: EdgeInsets.only(
                              right: index == _pageCount - 1 ? 0 : 5,
                            ),
                            decoration: BoxDecoration(
                              color: active ? p.accent : p.line,
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      }),
                    ),
                  ),
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    children: pages,
                  ),
                ),
                if (_page > 0)
                  _BottomBar(
                    error: _error,
                    isLast: _page == _pageCount,
                    saving: _saving,
                    onPressed: _page == _pageCount ? _finish : _next,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _OnboardingBackdrop extends StatelessWidget {
  const _OnboardingBackdrop();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Positioned(
      top: -180,
      right: -160,
      child: Container(
        width: 420,
        height: 420,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              p.accent.withValues(alpha: p.isDark ? 0.09 : 0.14),
              p.bg.withValues(alpha: 0),
            ],
          ),
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 28, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Eyebrow(
            'Natural physique operating system',
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: text.displayLarge?.copyWith(fontSize: 74, height: 0.86),
              children: [
                const TextSpan(text: 'BUILT.\nNOT\nBOUGHT'),
                TextSpan(
                  text: '.',
                  style: TextStyle(color: p.accent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text(
            'Programs, meals, measurements and progress — one honest system for '
            'the best natural physique you can build.',
            style: text.bodyLarge?.copyWith(color: p.muted, height: 1.5),
          ),
          const SizedBox(height: 28),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              border: Border.symmetric(horizontal: BorderSide(color: p.line)),
            ),
            child: Row(
              children: const [
                _IntroStat(value: '05', label: 'PROGRAMS'),
                _IntroStat(value: '69', label: 'LIFTS'),
                _IntroStat(value: '∞', label: 'POTENTIAL'),
              ],
            ),
          ),
          const SizedBox(height: 28),
          Row(
            children: [
              Expanded(
                child: FilledButton(
                  onPressed: onStart,
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('BUILD MY BLUEPRINT'),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.info_outline_rounded, size: 14, color: p.faint),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'No PEDs. No miracle timelines. Genetic potential is real — '
                  'Thetics helps you max out yours.',
                  style: text.bodySmall?.copyWith(
                    color: p.faint,
                    fontSize: 11,
                    height: 1.45,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IntroStat extends StatelessWidget {
  const _IntroStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .headlineMedium
                ?.copyWith(color: p.accent, fontSize: 34),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: p.faint,
              fontSize: 8.5,
              letterSpacing: 1.4,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StepTitle extends StatelessWidget {
  const _StepTitle({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
  });

  final String eyebrow;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(eyebrow, color: p.accent),
        const SizedBox(height: 10),
        Text(
          title,
          style:
              Theme.of(context).textTheme.displaySmall?.copyWith(fontSize: 42),
        ),
        const SizedBox(height: 10),
        Text(
          subtitle,
          style: Theme.of(context)
              .textTheme
              .bodyMedium
              ?.copyWith(color: p.muted, height: 1.5),
        ),
      ],
    );
  }
}

class _BasicsPage extends StatelessWidget {
  const _BasicsPage({
    required this.name,
    required this.age,
    required this.sex,
    required this.onSex,
  });

  final TextEditingController name;
  final TextEditingController age;
  final Sex sex;
  final ValueChanged<Sex> onSex;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            eyebrow: 'Step 01 · The basics',
            title: 'Who are we\nbuilding?',
            subtitle:
                'Your name and biological sex help personalise calorie math. '
                'Everything stays on this device.',
          ),
          const SizedBox(height: 28),
          const _FieldLabel('YOUR NAME'),
          TextField(
            controller: name,
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(hintText: 'e.g. Abdul'),
          ),
          const SizedBox(height: 20),
          const _FieldLabel('BIOLOGICAL SEX'),
          Row(
            children: Sex.values.map((value) {
              final selected = sex == value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: value == Sex.male ? 10 : 0),
                  child: GestureDetector(
                    onTap: () => onSex(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 18,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? p.accent : p.card,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: selected ? p.accent : p.line),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            value == Sex.male
                                ? Icons.male_rounded
                                : Icons.female_rounded,
                            color: selected ? p.onAccent : p.muted,
                            size: 22,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            value.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: selected ? p.onAccent : p.text,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 20),
          const _FieldLabel('AGE'),
          TextField(
            controller: age,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            decoration: const InputDecoration(suffixText: 'years'),
          ),
          const SizedBox(height: 26),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: p.line),
            ),
            child: Row(
              children: [
                Icon(Icons.lock_outline_rounded, size: 18, color: p.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Local-first. No account, no cloud, no data broker.',
                    style: TextStyle(
                      color: p.muted,
                      fontSize: 11.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FramePage extends StatelessWidget {
  const _FramePage({
    required this.units,
    required this.heightCm,
    required this.heightFt,
    required this.heightIn,
    required this.weight,
    required this.targetWeight,
    required this.onUnits,
    required this.onChanged,
  });

  final UnitSystem units;
  final TextEditingController heightCm;
  final TextEditingController heightFt;
  final TextEditingController heightIn;
  final TextEditingController weight;
  final TextEditingController targetWeight;
  final ValueChanged<UnitSystem> onUnits;
  final VoidCallback onChanged;

  BmiResult? _bmi() {
    final h = units == UnitSystem.metric
        ? double.tryParse(heightCm.text)
        : (double.tryParse(heightFt.text) ?? 0) * 30.48 +
            (double.tryParse(heightIn.text) ?? 0) * 2.54;
    var w = double.tryParse(weight.text);
    if (w == null) return null;
    if (units == UnitSystem.imperial) w = Fmt.lbToKg(w);
    if (h == null || h <= 0) return null;
    return calculateBmi(weightKg: w, heightCm: h);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bmi = _bmi();
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            eyebrow: 'Step 02 · Your frame',
            title: 'Start from\nthe truth.',
            subtitle:
                'No judgement. Just a baseline we can measure progress against.',
          ),
          const SizedBox(height: 24),
          _UnitToggle(units: units, onChanged: onUnits),
          const SizedBox(height: 24),
          const _FieldLabel('HEIGHT'),
          if (units == UnitSystem.metric)
            TextField(
              controller: heightCm,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              onChanged: (_) => onChanged(),
              decoration: const InputDecoration(
                hintText: '178',
                suffixText: 'cm',
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: heightFt,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                    decoration: const InputDecoration(
                      hintText: '5',
                      suffixText: 'ft',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: heightIn,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => onChanged(),
                    decoration: const InputDecoration(
                      hintText: '10',
                      suffixText: 'in',
                    ),
                  ),
                ),
              ],
            ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const _FieldLabel('CURRENT WEIGHT'),
                    TextField(
                      controller: weight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => onChanged(),
                      decoration: InputDecoration(
                        hintText: units == UnitSystem.metric ? '80.0' : '176.4',
                        suffixText: units.weightUnit,
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
                    const _FieldLabel('TARGET'),
                    TextField(
                      controller: targetWeight,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => onChanged(),
                      decoration: InputDecoration(
                        hintText: '—',
                        suffixText: units.weightUnit,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            color: p.cardHigh.withValues(alpha: 0.5),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(
                    Icons.straighten_rounded,
                    color: p.accent,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'BMI PREVIEW',
                        style: TextStyle(
                          color: p.faint,
                          fontSize: 8.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        bmi == null
                            ? 'Enter height and weight'
                            : '${bmi.value.toStringAsFixed(1)}  ·  ${bmi.band.label}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontSize: 14),
                      ),
                    ],
                  ),
                ),
                Text(
                  'Optional target',
                  style: TextStyle(color: p.faint, fontSize: 10),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'BMI is a blunt screening tool. It does not know muscle from fat — '
            'we use the trend, waist and photos to tell the real story.',
            style: TextStyle(color: p.faint, fontSize: 11, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _MissionPage extends StatelessWidget {
  const _MissionPage({
    required this.goal,
    required this.experience,
    required this.activity,
    required this.trainingDays,
    required this.onGoal,
    required this.onExperience,
    required this.onActivity,
    required this.onDays,
  });

  final Goal goal;
  final Experience experience;
  final ActivityLevel activity;
  final int trainingDays;
  final ValueChanged<Goal> onGoal;
  final ValueChanged<Experience> onExperience;
  final ValueChanged<ActivityLevel> onActivity;
  final ValueChanged<int> onDays;

  static const _goalIcons = {
    Goal.aesthetics: Icons.auto_awesome_rounded,
    Goal.muscle: Icons.fitness_center_rounded,
    Goal.fatLoss: Icons.local_fire_department_rounded,
    Goal.strength: Icons.bolt_rounded,
  };

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            eyebrow: 'Step 03 · Your mission',
            title: 'What are we\nbuilding toward?',
            subtitle:
                'Pick the body and the lifestyle. The plan adapts around you.',
          ),
          const SizedBox(height: 24),
          const _FieldLabel('PRIMARY GOAL'),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            children: Goal.values.map((value) {
              final selected = goal == value;
              return GestureDetector(
                onTap: () => onGoal(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: selected ? p.accent : p.card,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: selected ? p.accent : p.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(
                        _goalIcons[value],
                        color: selected ? p.onAccent : p.muted,
                        size: 20,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            value.label,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: selected ? p.onAccent : p.text,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            value.shortLabel,
                            style: TextStyle(
                              fontSize: 10,
                              color: selected
                                  ? p.onAccent.withValues(alpha: 0.6)
                                  : p.faint,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          const _FieldLabel('EXPERIENCE'),
          Row(
            children: Experience.values.map((value) {
              final selected = experience == value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(
                    right: value == Experience.advanced ? 0 : 8,
                  ),
                  child: GestureDetector(
                    onTap: () => onExperience(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? p.text : p.card,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: selected ? p.text : p.line),
                      ),
                      child: Text(
                        value.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: selected ? p.bg : p.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              const Expanded(child: _FieldLabel('TRAINING DAYS / WEEK')),
              Text(
                '$trainingDays days',
                style: TextStyle(
                  color: p.accent,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: List.generate(5, (index) {
              final value = index + 2;
              final selected = trainingDays == value;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 4 ? 0 : 7),
                  child: GestureDetector(
                    onTap: () => onDays(value),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: selected ? p.accent : p.card,
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(color: selected ? p.accent : p.line),
                      ),
                      child: Text(
                        '$value',
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                          color: selected ? p.onAccent : p.muted,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 24),
          const _FieldLabel('DAILY ACTIVITY'),
          DropdownButtonFormField<ActivityLevel>(
            initialValue: activity,
            isExpanded: true,
            dropdownColor: p.surface,
            borderRadius: BorderRadius.circular(16),
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            items: ActivityLevel.values
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            value.label,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            value.description,
                            style: TextStyle(fontSize: 10, color: p.faint),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onActivity(value);
            },
          ),
        ],
      ),
    );
  }
}

class _BlueprintPage extends StatelessWidget {
  const _BlueprintPage({required this.profile});

  final UserProfile profile;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final targets = calculateMacroTargets(profile);
    final bmi = calculateBmi(
      weightKg: profile.weightKg,
      heightCm: profile.heightCm,
    );
    final goal = profile.goal;
    final recommended = switch (goal) {
      Goal.aesthetics => 'PPL Aesthetics',
      Goal.muscle => 'PPL Aesthetics',
      Goal.fatLoss => 'Upper / Lower Recomp',
      Goal.strength => 'Foundation 5×5',
    };
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _StepTitle(
            eyebrow: 'Step 04 · Your blueprint',
            title: 'Numbers, not\nguesswork.',
            subtitle:
                'A starting point built from your stats. Adjust as your body answers back.',
          ),
          const SizedBox(height: 24),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Eyebrow('DAILY CALORIE TARGET'),
                    const Spacer(),
                    Tag(label: goal.shortLabel, color: p.accent),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${targets.calories}',
                      style: Theme.of(context)
                          .textTheme
                          .displayMedium
                          ?.copyWith(fontSize: 58, color: p.accent),
                    ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8, left: 6),
                      child: Text(
                        'kcal',
                        style: TextStyle(
                          color: p.muted,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'BMR ${targets.bmr.round()}',
                          style: TextStyle(color: p.faint, fontSize: 10),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'TDEE ${targets.tdee.round()}',
                          style: TextStyle(color: p.faint, fontSize: 10),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _MacroNumber(
                        label: 'PROTEIN',
                        grams: targets.protein,
                        color: p.accent,
                      ),
                    ),
                    Expanded(
                      child: _MacroNumber(
                        label: 'CARBS',
                        grams: targets.carbs,
                        color: p.sky,
                      ),
                    ),
                    Expanded(
                      child: _MacroNumber(
                        label: 'FAT',
                        grams: targets.fat,
                        color: p.ember,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('YOUR BMI'),
                      const SizedBox(height: 8),
                      Text(
                        bmi.value.toStringAsFixed(1),
                        style: Theme.of(context)
                            .textTheme
                            .headlineMedium
                            ?.copyWith(color: p.text),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        bmi.band.label,
                        style: TextStyle(
                          color:
                              bmi.band == BmiBand.healthy ? p.success : p.muted,
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SurfaceCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Eyebrow('FIRST PROGRAM'),
                      const SizedBox(height: 8),
                      Text(
                        recommended,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontSize: 15, height: 1.15),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${profile.trainingDays} days / week',
                        style: TextStyle(color: p.faint, fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.line),
              color: p.card.withValues(alpha: 0.5),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.auto_awesome_rounded, size: 18, color: p.accent),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'We will adjust from real data. Give the plan two weeks, '
                    'then change one variable at a time. No crash diets, no '
                    'hero sets you cannot recover from.',
                    style: TextStyle(
                      color: p.muted,
                      fontSize: 11.5,
                      height: 1.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'By continuing you acknowledge that Thetics is a fitness tracking tool, '
            'not medical advice. Natural muscle gain takes years, not weeks.',
            style: TextStyle(color: p.faint, fontSize: 10, height: 1.5),
          ),
        ],
      ),
    );
  }
}

class _MacroNumber extends StatelessWidget {
  const _MacroNumber({
    required this.label,
    required this.grams,
    required this.color,
  });

  final String label;
  final int grams;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(width: 18, height: 3, color: color),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '$grams',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: p.text, fontSize: 24),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: 3, left: 2),
              child: Text('g', style: TextStyle(color: p.faint, fontSize: 10)),
            ),
          ],
        ),
        Text(
          label,
          style: TextStyle(
            color: p.faint,
            fontSize: 8,
            letterSpacing: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _BottomBar extends StatelessWidget {
  const _BottomBar({
    required this.error,
    required this.isLast,
    required this.saving,
    required this.onPressed,
  });

  final String? error;
  final bool isLast;
  final bool saving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 14),
      decoration: BoxDecoration(
        color: p.bg,
        border: Border(top: BorderSide(color: p.line)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (error != null) ...[
              Row(
                children: [
                  Icon(Icons.error_outline_rounded, size: 15, color: p.danger),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      error!,
                      style: TextStyle(color: p.danger, fontSize: 11.5),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: saving ? null : onPressed,
                child: saving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(isLast ? 'ENTER THETICS' : 'CONTINUE'),
                          const SizedBox(width: 8),
                          Icon(
                            isLast
                                ? Icons.check_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
              ),
            ),
            if (isLast) ...[
              const SizedBox(height: 7),
              Text(
                'You can change every number later.',
                style: TextStyle(color: p.faint, fontSize: 9.5),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _UnitToggle extends StatelessWidget {
  const _UnitToggle({required this.units, required this.onChanged});

  final UnitSystem units;
  final ValueChanged<UnitSystem> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: UnitSystem.values.map((value) {
          final selected = units == value;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? p.text : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  value.label,
                  style: TextStyle(
                    color: selected ? p.bg : p.muted,
                    fontWeight: FontWeight.w800,
                    fontSize: 11.5,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Text(
        label,
        style: TextStyle(
          color: context.palette.faint,
          fontSize: 9,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}
