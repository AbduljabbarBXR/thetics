import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/bmi.dart';
import '../../core/utils/date_x.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/quick_sheets.dart';
import '../../core/widgets/surfaces.dart';
import '../profile/models/user_profile.dart';
import '../training/data/exercise_seed.dart';
import '../training/exercise_detail_screen.dart';
import '../training/models/workout_session.dart';
import 'bmi_screen.dart';
import 'measurements_screen.dart';
import 'models/measurement.dart';
import 'models/progress_photo.dart';
import 'photos_screen.dart';

class ProgressScreen extends ConsumerStatefulWidget {
  const ProgressScreen({super.key});

  @override
  ConsumerState<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends ConsumerState<ProgressScreen> {
  int _range = 90;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final data = ref.watch(appDataProvider);
    final profile = ref.watch(profileProvider);
    final bmi = ref.watch(bmiProvider);
    if (data == null || profile == null) {
      return Center(
        child: CircularProgressIndicator(color: p.accent, strokeWidth: 2),
      );
    }
    final units = profile.units;
    final trend = data.weightTrend(days: _range);
    final latest = data.latestMeasurement;
    final photos = [...data.photos]..sort((a, b) => b.date.compareTo(a.date));
    final prs = data.topPersonalRecords.take(5).toList();
    final sessionsThisWeek = data.completedSessions.where((session) {
      final date = session.completedAt ?? session.startedAt;
      return date.isAfter(DateTime.now().subtract(const Duration(days: 7)));
    }).length;
    final target = profile.targetWeightKg;
    final current = data.currentWeightKg;
    final targetDiff = target == null ? null : target - current;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow('Measured · not imagined', color: p.accent),
                        const SizedBox(height: 7),
                        Text(
                          'PROGRESS.',
                          style: text.displayLarge?.copyWith(
                            fontSize: 52,
                            height: 0.85,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PhotosScreen(),
                        ),
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: p.card,
                      side: BorderSide(color: p.line),
                    ),
                    icon: const Icon(
                      Icons.photo_camera_back_outlined,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MeasurementsScreen(),
                        ),
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: p.accent,
                      foregroundColor: p.onAccent,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'The scale is noisy. The tape is slow. The photos are honest. '
                'Read all three and look at the months, not the days.',
                style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.5),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _TopStat(
                    value: '${data.totalCompletedWorkouts}',
                    label: 'SESSIONS',
                  ),
                  _TopStat(value: '${data.weekStreak}', label: 'WEEK STREAK'),
                  _TopStat(
                    value: Fmt.volume(data.totalVolumeKg, units),
                    label: 'TOTAL LOAD',
                  ),
                  _TopStat(value: '${photos.length}', label: 'PHOTOS'),
                ],
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Body weight',
                eyebrow: 'Rolling ${_range}d trend',
                actionLabel: 'Weigh in',
                onAction: () => showLogWeightSheet(context),
              ),
              const SizedBox(height: 10),
              SurfaceCard(
                padding: const EdgeInsets.fromLTRB(18, 18, 12, 14),
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
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    Fmt.weightValue(current, units),
                                    style: text.displaySmall?.copyWith(
                                      fontSize: 48,
                                      height: 0.82,
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 4,
                                      left: 3,
                                    ),
                                    child: Text(
                                      Fmt.weightLabel(units),
                                      style: TextStyle(
                                        color: p.faint,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Tag(
                                    label:
                                        '${Fmt.signed(units == UnitSystem.imperial ? Fmt.kgToLb(data.weightChangeKg) : data.weightChangeKg, suffix: ' ${Fmt.weightLabel(units)}')} since start',
                                    color: p.muted,
                                    compact: true,
                                  ),
                                  if (target != null) ...[
                                    const SizedBox(width: 6),
                                    Tag(
                                      label:
                                          'TARGET ${Fmt.weightValue(target, units)} ${Fmt.weightLabel(units)}',
                                      color: p.accent,
                                      compact: true,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                        _RangeSelector(
                          value: _range,
                          onChanged: (value) => setState(() => _range = value),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TrendChart(
                      values: trend,
                      labels: [
                        formatShortDate(addDays(DateTime.now(), -(_range - 1))),
                        'Today',
                      ],
                      height: 142,
                      showDots: trend.length < 20,
                    ),
                    if (trend.length < 2) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Log at least two weigh-ins to see a trend. One number '
                        'is a moment; the line is the story.',
                        style: TextStyle(
                          color: p.faint,
                          fontSize: 9.5,
                          height: 1.4,
                        ),
                      ),
                    ],
                    if (target != null && targetDiff != null) ...[
                      const SizedBox(height: 10),
                      Container(height: 1, color: p.line),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            targetDiff.abs() < 0.1
                                ? Icons.check_circle_outline_rounded
                                : Icons.flag_outlined,
                            size: 14,
                            color: p.faint,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            targetDiff.abs() < 0.1
                                ? 'Target weight reached. Now decide what the next standard is.'
                                : '${Fmt.weightValue(targetDiff.abs(), units)} ${Fmt.weightLabel(units)} to target. Keep the weekly rate sane.',
                            style: TextStyle(color: p.faint, fontSize: 9.5),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Measurements',
                eyebrow: latest == null
                    ? 'No tape data yet'
                    : 'Last taken ${relativeDay(latest.date).toLowerCase()}',
                actionLabel: 'All',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const MeasurementsScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              if (latest == null)
                SurfaceCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MeasurementsScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
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
                              'Take your first set of measurements',
                              style: TextStyle(
                                color: p.text,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Waist, chest, shoulders, arms and thighs.',
                              style: TextStyle(color: p.faint, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: p.faint,
                        size: 18,
                      ),
                    ],
                  ),
                )
              else
                _MeasurementsSummary(
                  measurement: latest,
                  units: units,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const MeasurementsScreen(),
                      ),
                    );
                  },
                ),
              const SizedBox(height: 24),
              const SectionHeader(
                title: 'Body composition',
                eyebrow: 'One screening number',
              ),
              const SizedBox(height: 10),
              if (bmi != null)
                SurfaceCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const BmiScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: p.success.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Center(
                          child: Text(
                            bmi.value.toStringAsFixed(1),
                            style: TextStyle(
                              color: p.success,
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'BMI · ${bmi.band.label}',
                              style: TextStyle(
                                color: p.text,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Healthy range: ${Fmt.weightValue(bmi.healthyMinKg, units)}–${Fmt.weightValue(bmi.healthyMaxKg, units)} ${Fmt.weightLabel(units)}. It cannot see muscle.',
                              style: TextStyle(
                                color: p.faint,
                                fontSize: 9.5,
                                height: 1.35,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: p.faint,
                        size: 18,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Progress photos',
                eyebrow: '${photos.length} on device',
                actionLabel: 'All',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const PhotosScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              if (photos.isEmpty)
                SurfaceCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const PhotosScreen(),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: p.lilac.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.photo_camera_back_outlined,
                          color: p.lilac,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'No progress photos yet',
                              style: TextStyle(
                                color: p.text,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'Take a baseline before the lighting changes.',
                              style: TextStyle(color: p.faint, fontSize: 9.5),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        color: p.faint,
                        size: 18,
                      ),
                    ],
                  ),
                )
              else
                SizedBox(
                  height: 158,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.take(6).length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, index) {
                      final photo = photos[index];
                      return _PhotoPreview(
                        photo: photo,
                        units: units,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => const PhotosScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              const SizedBox(height: 24),
              SectionHeader(
                title: 'Strength board',
                eyebrow: prs.isEmpty ? 'No records yet' : 'Top estimated 1RMs',
              ),
              const SizedBox(height: 10),
              if (prs.isEmpty)
                Text(
                  'Finish a session to put your first numbers on the board.',
                  style: TextStyle(color: p.faint, fontSize: 11, height: 1.5),
                )
              else
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 15,
                    vertical: 7,
                  ),
                  child: Column(
                    children: prs.asMap().entries.map((entry) {
                      final index = entry.key;
                      final pr = entry.value;
                      return _PrRow(
                        rank: index + 1,
                        pr: pr,
                        units: units,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => ExerciseDetailScreen(
                                exerciseId: pr.exerciseId,
                              ),
                            ),
                          );
                        },
                      );
                    }).toList(),
                  ),
                ),
              const SizedBox(height: 20),
              if (sessionsThisWeek > 0)
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.06),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: p.accent.withValues(alpha: 0.18)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.bolt_rounded, size: 17, color: p.accent),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          '$sessionsThisWeek session${sessionsThisWeek == 1 ? '' : 's'} in the last 7 days. '
                          'The goal is the next honest week, not a perfect one.',
                          style: TextStyle(
                            color: p.muted,
                            fontSize: 10.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: p.card.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.line),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.science_outlined, size: 16, color: p.ember),
                        const SizedBox(width: 7),
                        Text(
                          'NATURAL MEANS NATURAL',
                          style: TextStyle(
                            color: p.ember,
                            fontSize: 8.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'A good year for most trained natural lifters is roughly '
                      '2–4 kg of lean mass — beginners can do better, advanced '
                      'lifers much less. Social media physiques often involve '
                      'drugs, lighting, pumps and editing. This app will not '
                      'pretend otherwise.\n\n'
                      'Consistency, progressive overload, enough protein, sleep '
                      'and patience remain undefeated. Numbers are feedback, '
                      'not a measure of your worth.',
                      style: TextStyle(
                        color: p.faint,
                        fontSize: 10.5,
                        height: 1.55,
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
  }
}

class _TopStat extends StatelessWidget {
  const _TopStat({required this.value, required this.label});

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 18, height: 1),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: p.faint,
              fontSize: 6.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
        ],
      ),
    );
  }
}

class _RangeSelector extends StatelessWidget {
  const _RangeSelector({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: p.bg.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [30, 90, 180].map((days) {
          final selected = value == days;
          return GestureDetector(
            onTap: () => onChanged(days),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 160),
              width: 38,
              padding: const EdgeInsets.symmetric(vertical: 5),
              margin: const EdgeInsets.only(bottom: 2),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? p.accent : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                '${days}D',
                style: TextStyle(
                  color: selected ? p.onAccent : p.faint,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _MeasurementsSummary extends StatelessWidget {
  const _MeasurementsSummary({
    required this.measurement,
    required this.units,
    required this.onTap,
  });

  final MeasurementEntry measurement;
  final UnitSystem units;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final bicep = measurement.bicepAvgCm;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
      onTap: onTap,
      child: Column(
        children: [
          Row(
            children: [
              _SummaryMetric(
                label: 'WAIST',
                value: measurement.waistCm == null
                    ? '—'
                    : Fmt.cmValue(measurement.waistCm!, units),
                unit: Fmt.lengthLabel(units),
              ),
              _SummaryMetric(
                label: 'CHEST',
                value: measurement.chestCm == null
                    ? '—'
                    : Fmt.cmValue(measurement.chestCm!, units),
                unit: Fmt.lengthLabel(units),
              ),
              _SummaryMetric(
                label: 'BICEP AVG',
                value: bicep == null ? '—' : Fmt.cmValue(bicep, units),
                unit: Fmt.lengthLabel(units),
              ),
              _SummaryMetric(
                label: 'BODY FAT',
                value: measurement.bodyFatPct == null
                    ? '—'
                    : measurement.bodyFatPct!.toStringAsFixed(1),
                unit: '%',
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                'Updated ${relativeDay(measurement.date).toLowerCase()}',
                style: TextStyle(color: p.faint, fontSize: 9),
              ),
              const Spacer(),
              Text(
                'All measurements',
                style: TextStyle(
                  color: p.accent,
                  fontSize: 9.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Icon(Icons.arrow_forward_rounded, size: 13, color: p.accent),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.unit,
  });

  final String label;
  final String value;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: p.faint,
              fontSize: 6.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 3),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: p.text,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              if (value != '—')
                Padding(
                  padding: const EdgeInsets.only(bottom: 1, left: 1),
                  child: Text(
                    unit,
                    style: TextStyle(color: p.faint, fontSize: 7.5),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PhotoPreview extends StatelessWidget {
  const _PhotoPreview({
    required this.photo,
    required this.units,
    required this.onTap,
  });

  final ProgressPhoto photo;
  final UnitSystem units;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 116,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.file(
                File(photo.path),
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: p.cardHigh,
                  child: Icon(
                    Icons.broken_image_outlined,
                    color: p.faint,
                    size: 20,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withValues(alpha: 0.75),
                    ],
                    stops: const [0.5, 1],
                  ),
                ),
              ),
              Positioned(
                left: 9,
                right: 9,
                bottom: 9,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatShortDate(photo.date),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (photo.weightKg != null)
                      Text(
                        Fmt.weight(photo.weightKg!, units),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 8,
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
  }
}

class _PrRow extends StatelessWidget {
  const _PrRow({
    required this.rank,
    required this.pr,
    required this.units,
    required this.onTap,
  });

  final int rank;
  final PersonalRecord pr;
  final UnitSystem units;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final exercise =
        exerciseSeed.where((item) => item.id == pr.exerciseId).toList();
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 18,
              child: Text(
                '$rank',
                style: TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: rank == 1 ? p.ember : p.faint,
                ),
              ),
            ),
            if (exercise.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(9),
                child: Image.asset(
                  exercise.first.imageAsset,
                  width: 38,
                  height: 38,
                  fit: BoxFit.cover,
                ),
              )
            else
              Icon(Icons.fitness_center_rounded, color: p.faint, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pr.exerciseName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.text,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    relativeDay(pr.date),
                    style: TextStyle(color: p.faint, fontSize: 8.5),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  Fmt.weight(pr.weightKg, units),
                  style: TextStyle(
                    color: p.text,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  '${pr.reps} reps · ~${Fmt.weightValue(pr.estimatedOneRepMax, units, decimals: 0)} 1RM',
                  style: TextStyle(color: p.faint, fontSize: 8),
                ),
              ],
            ),
            Icon(Icons.chevron_right_rounded, size: 15, color: p.faint),
          ],
        ),
      ),
    );
  }
}
