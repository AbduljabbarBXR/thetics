import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/bmi.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/quick_sheets.dart';
import '../../core/widgets/surfaces.dart';
import '../profile/edit_profile_screen.dart';
import '../profile/models/user_profile.dart';
import 'measurements_screen.dart';

class BmiScreen extends ConsumerWidget {
  const BmiScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final data = ref.watch(appDataProvider);
    final profile = ref.watch(profileProvider);
    final bmi = ref.watch(bmiProvider);
    if (data == null || profile == null || bmi == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('BMI & frame')),
        body: Center(
          child: CircularProgressIndicator(color: p.accent, strokeWidth: 2),
        ),
      );
    }
    final units = profile.units;
    final latest = data.latestMeasurement;
    final bodyFat = latest?.bodyFatPct;
    final weight = data.currentWeightKg;
    final lean = bodyFat == null
        ? leanBodyMassKg(
            weightKg: weight,
            heightCm: profile.heightCm,
            male: profile.sex == Sex.male,
          )
        : weight * (1 - bodyFat / 100);
    final fatMass = (weight - lean).clamp(0.0, weight);
    final waist = latest?.waistCm;
    final waistRatio = waist == null || profile.heightCm <= 0
        ? null
        : waist / profile.heightCm;
    final healthyMin = units == UnitSystem.imperial
        ? Fmt.kgToLb(bmi.healthyMinKg)
        : bmi.healthyMinKg;
    final healthyMax = units == UnitSystem.imperial
        ? Fmt.kgToLb(bmi.healthyMaxKg)
        : bmi.healthyMaxKg;
    final currentDisplay =
        units == UnitSystem.imperial ? Fmt.kgToLb(weight) : weight;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('BMI & frame'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const EditProfileScreen(),
                ),
              );
            },
            child: const Text('Edit'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Eyebrow('Screening tool · not a verdict', color: p.accent),
          const SizedBox(height: 7),
          Text(
            'KNOW THE\nNUMBER.',
            style: text.displaySmall?.copyWith(fontSize: 46, height: 0.87),
          ),
          const SizedBox(height: 10),
          Text(
            'BMI compares weight to height. It is useful for population trends '
            'and almost useless for judging a single lifter. Use it as one data '
            'point, never the whole story.',
            style: TextStyle(color: p.muted, fontSize: 12, height: 1.55),
          ),
          const SizedBox(height: 20),
          SurfaceCard(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bmi.value.toStringAsFixed(1),
                            style: text.displayLarge?.copyWith(
                              fontSize: 68,
                              height: 0.82,
                              color: _bandColor(bmi.band, p),
                            ),
                          ),
                          const SizedBox(height: 7),
                          Tag(
                            label: bmi.band.label,
                            color: _bandColor(bmi.band, p),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          Fmt.height(profile.heightCm, units),
                          style: TextStyle(
                            color: p.text,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          Fmt.weight(weight, units),
                          style: TextStyle(color: p.faint, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                _BmiScale(value: bmi.value),
                const SizedBox(height: 15),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.cardHigh,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: _bandColor(bmi.band, p),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          bmi.band.note,
                          style: TextStyle(
                            color: p.muted,
                            fontSize: 10.5,
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
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => showLogWeightSheet(context),
                  icon: const Icon(Icons.monitor_weight_outlined, size: 18),
                  label: const Text('LOG WEIGHT'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MeasurementsScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.straighten_rounded, size: 17),
                  label: const Text('MEASURE'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Healthy weight range',
            eyebrow: 'Statistical, not personal',
          ),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: p.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.balance_rounded,
                    color: p.success,
                    size: 19,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${healthyMin.toStringAsFixed(1)} – ${healthyMax.toStringAsFixed(1)} ${Fmt.weightLabel(units)}',
                        style: TextStyle(
                          color: p.text,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        currentDisplay < healthyMin
                            ? 'You are ${(healthyMin - currentDisplay).toStringAsFixed(1)} ${Fmt.weightLabel(units)} below the range.'
                            : currentDisplay > healthyMax
                                ? 'You are ${(currentDisplay - healthyMax).toStringAsFixed(1)} ${Fmt.weightLabel(units)} above the range.'
                                : 'Your weight sits inside the range.',
                        style: TextStyle(color: p.faint, fontSize: 10),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const SectionHeader(
            title: 'Frame estimate',
            eyebrow: 'Rough, but useful',
          ),
          const SizedBox(height: 10),
          SurfaceCard(
            child: Column(
              children: [
                Row(
                  children: [
                    _FrameStat(
                      label: 'LEAN MASS',
                      value: Fmt.weight(lean, units),
                      color: p.accent,
                    ),
                    _FrameDivider(),
                    _FrameStat(
                      label: 'FAT MASS',
                      value: Fmt.weight(fatMass, units),
                      color: p.ember,
                    ),
                    _FrameDivider(),
                    _FrameStat(
                      label: 'BODY FAT',
                      value: bodyFat == null
                          ? '—'
                          : '${bodyFat.toStringAsFixed(1)}%',
                      color: p.sky,
                    ),
                  ],
                ),
                const SizedBox(height: 13),
                Divider(color: p.line),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.science_outlined, size: 14, color: p.faint),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        bodyFat == null
                            ? 'Lean mass is estimated with the Boer formula. '
                                'Add a body-fat measurement for a better estimate.'
                            : 'Lean mass is based on your latest body-fat '
                                'measurement. Calipers and smart scales are '
                                'estimates, not lab results.',
                        style: TextStyle(
                          color: p.faint,
                          fontSize: 9.5,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (waistRatio != null) ...[
            const SizedBox(height: 14),
            SurfaceCard(
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: (waistRatio < 0.5 ? p.success : p.ember)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.straighten_rounded,
                      color: waistRatio < 0.5 ? p.success : p.ember,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Waist-to-height ratio · ${waistRatio.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: p.text,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          waistRatio < 0.5
                              ? 'Below 0.5 is a useful health marker for most adults.'
                              : 'Above 0.5 warrants attention over time. Track the trend, not one measurement.',
                          style: TextStyle(color: p.faint, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 22),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: p.card.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: p.line),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 17, color: p.ember),
                    const SizedBox(width: 7),
                    Text(
                      'WHAT BMI CANNOT SEE',
                      style: TextStyle(
                        color: p.ember,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'A lean, muscular athlete can be classified “overweight.” '
                  'A sedentary person can have a “healthy” BMI with high visceral '
                  'fat. Waist circumference, training performance, progress '
                  'photos and long-term trends tell a more honest story.\n\n'
                  'This is education, not medical advice. If a number worries '
                  'you, speak with a qualified clinician.',
                  style: TextStyle(
                    color: p.muted,
                    fontSize: 10.5,
                    height: 1.55,
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

Color _bandColor(BmiBand band, TheticsPalette p) {
  return switch (band) {
    BmiBand.underweight => p.sky,
    BmiBand.healthy => p.success,
    BmiBand.overweight => p.ember,
    BmiBand.obese => p.danger,
  };
}

class _BmiScale extends StatelessWidget {
  const _BmiScale({required this.value});

  final double value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final position = ((value - 15) / 20).clamp(0.0, 1.0);
    return Column(
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final x = width * position;
            return SizedBox(
              height: 26,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: 0,
                    right: 0,
                    top: 7,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(100),
                      child: Row(
                        children: [
                          Expanded(
                            flex: 35,
                            child: Container(height: 11, color: p.sky),
                          ),
                          Expanded(
                            flex: 65,
                            child: Container(height: 11, color: p.success),
                          ),
                          Expanded(
                            flex: 50,
                            child: Container(height: 11, color: p.ember),
                          ),
                          Expanded(
                            flex: 50,
                            child: Container(height: 11, color: p.danger),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (x - 1).clamp(0.0, width - 2),
                    top: 1,
                    child: Container(
                      width: 2,
                      height: 23,
                      decoration: BoxDecoration(
                        color: p.text,
                        borderRadius: BorderRadius.circular(100),
                        boxShadow: [
                          BoxShadow(
                            color: p.text.withValues(alpha: 0.3),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: (x - 5).clamp(0.0, width - 10),
                    top: -3,
                    child: Icon(
                      Icons.arrow_drop_down_rounded,
                      color: p.text,
                      size: 11,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 5),
        Row(
          children: [
            _ScaleLabel('Under 18.5', p.sky),
            _ScaleLabel('Healthy 18.5–25', p.success),
            _ScaleLabel('Over 25', p.ember),
            _ScaleLabel('Obese 30+', p.danger),
          ],
        ),
      ],
    );
  }
}

class _ScaleLabel extends StatelessWidget {
  const _ScaleLabel(this.label, this.color);

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: color,
          fontSize: 7.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _FrameStat extends StatelessWidget {
  const _FrameStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 16, height: 2.5, color: color),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: p.text,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
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
    );
  }
}

class _FrameDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 34,
      margin: const EdgeInsets.symmetric(horizontal: 10),
      color: context.palette.line,
    );
  }
}
