import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_data.dart';
import '../../core/state/app_controller.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_x.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/app_logo.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/quick_sheets.dart';
import '../../core/widgets/surfaces.dart';
import '../profile/models/user_profile.dart';
import '../progress/bmi_screen.dart';
import '../progress/measurements_screen.dart';
import '../shell/app_shell.dart';
import '../training/active_workout_screen.dart';
import '../training/models/program.dart';
import '../training/models/workout_session.dart';
import '../training/program_detail_screen.dart';
import '../training/program_utils.dart';
import '../training/workout_history_screen.dart';
import '../training/widgets/workout_detail_sheet.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final data = ref.watch(appDataProvider);
    final profile = ref.watch(profileProvider);
    final targets = ref.watch(macroTargetsProvider);
    final program = ref.watch(selectedProgramProvider);
    final nutrition = ref.watch(todayNutritionProvider);
    final active = ref.watch(activeWorkoutProvider);

    if (data == null || profile == null || targets == null || program == null) {
      return Center(
        child: CircularProgressIndicator(color: p.accent, strokeWidth: 2),
      );
    }

    final nextDay = active != null
        ? program.dayById(active.dayId) ?? program.days.first
        : nextDayForProgram(program, data);
    final units = profile.units;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Header(profile: profile, streak: data.weekStreak),
              const SizedBox(height: 24),
              _HeroWorkoutCard(
                active: active,
                programName: program.name,
                day: nextDay,
                onStart: () async {
                  if (active != null) {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ActiveWorkoutScreen(),
                      ),
                    );
                    return;
                  }
                  final started = await ref
                      .read(appControllerProvider.notifier)
                      .startWorkout(program, nextDay);
                  if (!context.mounted) return;
                  if (!started) {
                    showTheticsSnack(
                      context,
                      'Finish your current session first.',
                      error: true,
                    );
                    return;
                  }
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ActiveWorkoutScreen(),
                    ),
                  );
                },
                onViewProgram: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => ProgramDetailScreen(program: program),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              _QuickStats(
                calories: nutrition.calories,
                calorieTarget: targets.calories.toDouble(),
                protein: nutrition.protein,
                proteinTarget: targets.protein.toDouble(),
                weightKg: data.currentWeightKg,
                weightChange: data.weightChangeKg,
                units: units,
                onWeightTap: () => showLogWeightSheet(context),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Fuel',
                eyebrow: formatLongDate(DateTime.now()),
                actionLabel: 'Open',
                onAction: () =>
                    ref.read(selectedTabProvider.notifier).state = 2,
              ),
              const SizedBox(height: 10),
              SurfaceCard(
                padding: const EdgeInsets.all(18),
                onTap: () => ref.read(selectedTabProvider.notifier).state = 2,
                child: Row(
                  children: [
                    CalorieRing(
                      value: nutrition.calories,
                      target: targets.calories.toDouble(),
                      size: 124,
                      strokeWidth: 10,
                      center: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${targets.calories - nutrition.calories.round()}',
                            style: Theme.of(context)
                                .textTheme
                                .headlineMedium
                                ?.copyWith(
                                  fontSize: 27,
                                  color: p.text,
                                  height: 1,
                                ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'KCAL LEFT',
                            style: TextStyle(
                              color: p.faint,
                              fontSize: 7.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.9,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 18),
                    Expanded(
                      child: Column(
                        children: [
                          MacroBar(
                            label: 'Protein',
                            value: nutrition.protein,
                            target: targets.protein.toDouble(),
                            color: p.accent,
                            compact: true,
                          ),
                          const SizedBox(height: 12),
                          MacroBar(
                            label: 'Carbs',
                            value: nutrition.carbs,
                            target: targets.carbs.toDouble(),
                            color: p.sky,
                            compact: true,
                          ),
                          const SizedBox(height: 12),
                          MacroBar(
                            label: 'Fat',
                            value: nutrition.fat,
                            target: targets.fat.toDouble(),
                            color: p.ember,
                            compact: true,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Quick actions',
                eyebrow: 'Keep the data honest',
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Weigh in',
                      onTap: () => showLogWeightSheet(context),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.straighten_rounded,
                      label: 'Measure',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const MeasurementsScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _QuickAction(
                      icon: Icons.calculate_outlined,
                      label: 'BMI',
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const BmiScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Weekly workload',
                eyebrow: 'Last 7 days',
                actionLabel: 'History',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WorkoutHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _WeeklyWorkloadCard(data: data, units: units),
              const SizedBox(height: 20),
              _CoachCard(
                message: _coachMessage(
                  data: data,
                  targetsCalories: targets.calories,
                  targetsProtein: targets.protein,
                  calories: nutrition.calories,
                  protein: nutrition.protein,
                  hasFood: nutrition.entries.isNotEmpty,
                ),
              ),
              const SizedBox(height: 26),
              SectionHeader(
                title: 'Recent sessions',
                actionLabel: 'All',
                onAction: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const WorkoutHistoryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              if (data.recentSessions.isEmpty)
                SurfaceCard(
                  child: EmptyState(
                    icon: Icons.fitness_center_rounded,
                    title: 'No sessions yet',
                    message:
                        'Your first workout is the only one that matters today.',
                    actionLabel: 'PICK A PROGRAM',
                    onAction: () =>
                        ref.read(selectedTabProvider.notifier).state = 1,
                    compact: true,
                  ),
                )
              else
                ...data.recentSessions.take(3).map(
                      (session) => Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _RecentSession(
                          name: session.dayName,
                          subtitle:
                              '${session.programName} · ${relativeDay(session.completedAt ?? session.startedAt)}',
                          meta:
                              '${session.completedSetCount} sets · ${Fmt.volume(session.volumeKg, units)}',
                          onTap: () => showWorkoutDetailSheet(
                            context,
                            session: session,
                            units: units,
                          ),
                        ),
                      ),
                    ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.profile, required this.streak});

  final UserProfile profile;
  final int streak;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final now = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const AppMark(size: 32, radius: 9),
            const SizedBox(width: 9),
            const Wordmark(fontSize: 21),
            const Spacer(),
            GestureDetector(
              onTap: () => ProviderScope.containerOf(context)
                  .read(selectedTabProvider.notifier)
                  .state = 4,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.card,
                  shape: BoxShape.circle,
                  border: Border.all(color: p.line),
                ),
                alignment: Alignment.center,
                child: Text(
                  profile.firstName.characters.first.toUpperCase(),
                  style: TextStyle(
                    color: p.accent,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        Text(
          '${weekdayLong(now).toUpperCase()} · ${monthShort(now).toUpperCase()} ${now.day}',
          style: TextStyle(
            color: p.faint,
            fontSize: 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 7),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Text(
                '${greeting()},\n${profile.firstName}.',
                style: Theme.of(context)
                    .textTheme
                    .displaySmall
                    ?.copyWith(fontSize: 43, height: 0.92),
              ),
            ),
            if (streak > 0)
              Padding(
                padding: const EdgeInsets.only(bottom: 3),
                child: Tag(
                  label: '$streak week streak',
                  color: p.ember,
                  icon: Icons.local_fire_department_rounded,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _HeroWorkoutCard extends StatelessWidget {
  const _HeroWorkoutCard({
    required this.active,
    required this.programName,
    required this.day,
    required this.onStart,
    required this.onViewProgram,
  });

  final WorkoutSession? active;
  final String programName;
  final ProgramDay day;
  final VoidCallback onStart;
  final VoidCallback onViewProgram;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final isActive = active != null;
    final duration =
        isActive ? Fmt.clock(active!.duration) : '${estimateMinutes(day)} MIN';
    final setCount = isActive
        ? '${active!.completedSetCount}/${active!.plannedSetCount} SETS'
        : '${day.totalSets} SETS';

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: isActive ? p.accent.withValues(alpha: 0.6) : p.line,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.cardHigh,
            Color.alphaBlend(
              p.accent.withValues(alpha: p.isDark ? 0.08 : 0.12),
              p.card,
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -48,
            top: -58,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: p.accent.withValues(alpha: 0.12),
                  width: 28,
                ),
              ),
            ),
          ),
          Positioned(
            right: 18,
            bottom: -30,
            child: Icon(
              Icons.fitness_center_rounded,
              size: 122,
              color: p.text.withValues(alpha: 0.035),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Tag(
                      label: isActive ? 'Session live' : 'Next up',
                      color: isActive ? p.accent : p.muted,
                      icon: isActive
                          ? Icons.radio_button_checked_rounded
                          : Icons.bolt_rounded,
                    ),
                    const Spacer(),
                    Text(
                      duration,
                      style: TextStyle(
                        color: p.muted,
                        fontSize: 9.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  programName.toUpperCase(),
                  style: TextStyle(
                    color: p.accent,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  isActive ? active!.dayName : day.name,
                  style: text.displaySmall?.copyWith(
                    fontSize: 41,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  isActive
                      ? 'In progress — pick up where you left off.'
                      : day.focus,
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    _HeroMeta(icon: Icons.layers_outlined, label: setCount),
                    const SizedBox(width: 16),
                    _HeroMeta(
                      icon: Icons.timer_outlined,
                      label: isActive
                          ? '${active!.completedSetCount} SETS DONE'
                          : '${estimateMinutes(day)} min',
                    ),
                    const SizedBox(width: 16),
                    const _HeroMeta(
                      icon: Icons.trending_up_rounded,
                      label: 'PROGRESSIVE',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: onStart,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                isActive
                                    ? Icons.play_arrow_rounded
                                    : Icons.bolt_rounded,
                                size: 19,
                              ),
                              const SizedBox(width: 7),
                              Text(
                                isActive ? 'RESUME SESSION' : 'START SESSION',
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    SizedBox(
                      width: 54,
                      height: 54,
                      child: OutlinedButton(
                        onPressed: onViewProgram,
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Icon(Icons.info_outline_rounded, size: 19),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroMeta extends StatelessWidget {
  const _HeroMeta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Row(
      children: [
        Icon(icon, size: 12, color: p.faint),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: p.faint,
            fontSize: 8,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.4,
          ),
        ),
      ],
    );
  }
}

class _QuickStats extends StatelessWidget {
  const _QuickStats({
    required this.calories,
    required this.calorieTarget,
    required this.protein,
    required this.proteinTarget,
    required this.weightKg,
    required this.weightChange,
    required this.units,
    required this.onWeightTap,
  });

  final double calories;
  final double calorieTarget;
  final double protein;
  final double proteinTarget;
  final double weightKg;
  final double weightChange;
  final UnitSystem units;
  final VoidCallback onWeightTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final left = (calorieTarget - calories).round();
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Row(
        children: [
          Expanded(
            child: _StatCell(
              label: 'KCAL LEFT',
              value: '$left',
              sub: left < 0 ? 'over target' : 'today',
              valueColor: left < 0 ? p.ember : p.text,
            ),
          ),
          _StatSeparator(),
          Expanded(
            child: _StatCell(
              label: 'PROTEIN',
              value: '${protein.round()}g',
              sub: 'of ${proteinTarget.round()}g',
              valueColor: p.text,
            ),
          ),
          _StatSeparator(),
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onWeightTap,
              child: _StatCell(
                label: 'BODY WEIGHT',
                value: Fmt.weightValue(weightKg, units),
                sub:
                    '${Fmt.signed(weightChange, suffix: ' ${Fmt.weightLabel(units)}')} trend',
                valueColor: p.text,
                showEdit: true,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatCell extends StatelessWidget {
  const _StatCell({
    required this.label,
    required this.value,
    required this.sub,
    required this.valueColor,
    this.showEdit = false,
  });

  final String label;
  final String value;
  final String sub;
  final Color valueColor;
  final bool showEdit;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  style: TextStyle(
                    color: p.faint,
                    fontSize: 7.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
              if (showEdit) ...[
                const SizedBox(width: 3),
                Icon(Icons.edit_outlined, size: 9, color: p.faint),
              ],
            ],
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.fade,
            softWrap: false,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontSize: 23, color: valueColor, height: 1),
          ),
          const SizedBox(height: 3),
          Text(
            sub,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: p.faint, fontSize: 8.5),
          ),
        ],
      ),
    );
  }
}

class _StatSeparator extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 44, color: context.palette.line);
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(vertical: 14),
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: p.accent, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: p.text,
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyWorkloadCard extends StatelessWidget {
  const _WeeklyWorkloadCard({required this.data, required this.units});

  final AppData data;
  final UnitSystem units;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final values = data.weeklyVolumeKg();
    final sessions = data.completedSessions.where((session) {
      final date = session.completedAt ?? session.startedAt;
      return DateTime.now().difference(date).inDays < 7;
    }).length;
    final total = values.fold<double>(0, (sum, value) => sum + value);
    final days = lastNDays(7);
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    Fmt.volume(total, units),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontSize: 27),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'TOTAL LOAD MOVED',
                    style: TextStyle(
                      color: p.faint,
                      fontSize: 7.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Tag(
                label: Fmt.plural(sessions, 'session'),
                color: sessions > 0 ? p.accent : p.faint,
              ),
            ],
          ),
          const SizedBox(height: 12),
          WeeklyVolumeChart(
            values: values,
            labels:
                days.map((date) => weekdayShort(date).substring(0, 1)).toList(),
            height: 104,
            highlightIndex: 6,
          ),
        ],
      ),
    );
  }
}

class _CoachCard extends StatelessWidget {
  const _CoachCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: p.line),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 35,
            height: 35,
            decoration: BoxDecoration(
              color: p.ember.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.auto_awesome_rounded, color: p.ember, size: 17),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "COACH'S NOTE",
                  style: TextStyle(
                    color: p.faint,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  message,
                  style: TextStyle(
                    color: p.muted,
                    fontSize: 12,
                    height: 1.5,
                    fontWeight: FontWeight.w500,
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

class _RecentSession extends StatelessWidget {
  const _RecentSession({
    required this.name,
    required this.subtitle,
    required this.meta,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final String meta;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 13),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: p.accent.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.check_rounded,
              color: p.accent.withValues(alpha: 0.9),
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: p.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: TextStyle(color: p.faint, fontSize: 10)),
              ],
            ),
          ),
          Text(
            meta,
            style: TextStyle(
              color: p.muted,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 5),
          Icon(Icons.chevron_right_rounded, color: p.faint, size: 18),
        ],
      ),
    );
  }
}

String _coachMessage({
  required AppData data,
  required int targetsCalories,
  required int targetsProtein,
  required double calories,
  required double protein,
  required bool hasFood,
}) {
  final sessions = sessionsInLastDays(data, 28);
  if (sessions == 0) {
    return 'Your first four weeks are about showing up, not maxing out. '
        'Start a program, log every set, and let the data teach you.';
  }
  if (hasFood && protein < targetsProtein - 30) {
    return 'You are ${(targetsProtein - protein).round()} g short on protein. '
        'Add a serving of chicken, Greek yogurt or whey before the day slips away.';
  }
  if (hasFood && calories > targetsCalories + 250) {
    return 'You are ${(calories - targetsCalories).round()} kcal over target. '
        'One meal does not ruin a week — just make the next choice a boring one.';
  }
  if (hasFood && calories < targetsCalories - 500) {
    return 'You are ${(targetsCalories - calories).round()} kcal under target. '
        'That is recovery you are borrowing from tomorrow. Fuel the work.';
  }
  if (data.activeWorkout != null) {
    return 'A session is already live. Finish the work you started before '
        'chasing another program.';
  }
  return '$sessions sessions in the last 28 days. The physique is built in the '
      'boring middle — same lifts, a little more load, enough food, enough sleep.';
}
