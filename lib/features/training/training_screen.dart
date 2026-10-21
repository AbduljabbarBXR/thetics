import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_data.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_x.dart';
import '../../core/widgets/surfaces.dart';
import 'active_workout_screen.dart';
import 'exercise_library_screen.dart';
import 'models/program.dart';
import 'program_detail_screen.dart';
import 'program_utils.dart';
import 'data/program_catalog.dart';
import 'workout_history_screen.dart';

class TrainingScreen extends ConsumerWidget {
  const TrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final selected = ref.watch(selectedProgramProvider);
    final data = ref.watch(appDataProvider);
    final active = ref.watch(activeWorkoutProvider);

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
                        Eyebrow('Programs · Library', color: p.accent),
                        const SizedBox(height: 7),
                        Text(
                          'TRAIN.',
                          style: text.displayLarge?.copyWith(
                            fontSize: 54,
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
                          builder: (_) => const WorkoutHistoryScreen(),
                        ),
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: p.card,
                      side: BorderSide(color: p.line),
                    ),
                    icon: const Icon(Icons.history_rounded, size: 20),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const ExerciseLibraryScreen(),
                        ),
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: p.accent,
                      foregroundColor: p.onAccent,
                    ),
                    icon: const Icon(Icons.search_rounded, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Five honest ways to build the same body. Pick one and repeat it.',
                style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.5),
              ),
              if (active != null) ...[
                const SizedBox(height: 18),
                _LiveSessionCard(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const ActiveWorkoutScreen(),
                      ),
                    );
                  },
                ),
              ],
              if (selected != null) ...[
                const SizedBox(height: 26),
                const SectionHeader(
                  title: 'Your program',
                  eyebrow: 'The current plan',
                ),
                const SizedBox(height: 10),
                _FeaturedProgram(
                  program: selected,
                  data: data,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => ProgramDetailScreen(program: selected),
                      ),
                    );
                  },
                ),
              ],
              const SizedBox(height: 26),
              SectionHeader(
                title: 'All programs',
                eyebrow: '${programCatalog.length} templates',
              ),
              const SizedBox(height: 10),
              ...programCatalog.asMap().entries.map((entry) {
                final index = entry.key;
                final program = entry.value;
                final isSelected = selected?.id == program.id;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _ProgramRow(
                    index: index + 1,
                    program: program,
                    selected: isSelected,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ProgramDetailScreen(program: program),
                        ),
                      );
                    },
                  ),
                );
              }),
              const SizedBox(height: 18),
              _LibraryCard(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => const ExerciseLibraryScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 22),
              if (data != null) _HistoryStrip(data: data),
              const SizedBox(height: 22),
              Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: p.card.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: p.line),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.science_outlined, size: 17, color: p.faint),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        'Programs are educational templates, not medical advice. '
                        'Progress the load, respect recovery, and stop if pain '
                        'is sharp or joint pain persists.',
                        style: TextStyle(
                          color: p.faint,
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
      ),
    );
  }
}

class _LiveSessionCard extends StatelessWidget {
  const _LiveSessionCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final active =
        ProviderScope.containerOf(context).read(activeWorkoutProvider);
    if (active == null) return const SizedBox.shrink();
    return SurfaceCard(
      onTap: onTap,
      borderColor: p.accent.withValues(alpha: 0.45),
      color: p.accent.withValues(alpha: 0.06),
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: p.accent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.bolt_rounded, color: p.onAccent, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'SESSION IN PROGRESS',
                  style: TextStyle(
                    color: p.accent,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${active.dayName} · ${active.completedSetCount}/${active.plannedSetCount} sets',
                  style: TextStyle(
                    color: p.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.play_arrow_rounded, color: p.accent, size: 22),
        ],
      ),
    );
  }
}

class _FeaturedProgram extends StatelessWidget {
  const _FeaturedProgram({
    required this.program,
    required this.data,
    required this.onTap,
  });

  final TrainingProgram program;
  final AppData? data;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final day =
        data == null ? program.days.first : nextDayForProgram(program, data!);
    final color = programColor(program.id, p);
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: p.line),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.cardHigh,
            Color.alphaBlend(
              color.withValues(alpha: p.isDark ? 0.1 : 0.14),
              p.card,
            ),
          ],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -26,
            child: Text(
              program.badge,
              style: TextStyle(
                fontFamily: 'BarlowCondensed',
                fontSize: 96,
                height: 1,
                fontWeight: FontWeight.w700,
                color: color.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(19),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Tag(label: program.badge, color: color),
                    const SizedBox(width: 7),
                    Tag(label: 'ACTIVE', color: p.accent, compact: true),
                    const Spacer(),
                    Icon(Icons.arrow_outward_rounded, color: p.muted, size: 18),
                  ],
                ),
                const SizedBox(height: 18),
                Text(
                  program.name,
                  style: text.displaySmall?.copyWith(fontSize: 34, height: 1),
                ),
                const SizedBox(height: 4),
                Text(
                  program.tagline,
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: p.bg.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: p.line),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.skip_next_rounded, size: 15, color: color),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          'NEXT: ${day.name.toUpperCase()}',
                          style: TextStyle(
                            color: p.text,
                            fontSize: 9.5,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                      Text(
                        '${day.totalSets} sets',
                        style: TextStyle(color: p.faint, fontSize: 9.5),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _MetaItem(
                      icon: Icons.calendar_today_outlined,
                      label: '${program.daysPerWeek} days/wk',
                    ),
                    const SizedBox(width: 14),
                    _MetaItem(
                      icon: Icons.hourglass_bottom_rounded,
                      label: '${program.weeks} weeks',
                    ),
                    const SizedBox(width: 14),
                    _MetaItem(
                      icon: Icons.signal_cellular_alt_rounded,
                      label: program.level.split('–').first,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    onPressed: onTap,
                    style: FilledButton.styleFrom(
                      backgroundColor: p.text.withValues(alpha: 0.07),
                      foregroundColor: p.text,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('VIEW PROGRAM'),
                        const SizedBox(width: 7),
                        const Icon(Icons.arrow_forward_rounded, size: 17),
                      ],
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

class _MetaItem extends StatelessWidget {
  const _MetaItem({required this.icon, required this.label});

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
            color: p.muted,
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ProgramRow extends StatelessWidget {
  const _ProgramRow({
    required this.index,
    required this.program,
    required this.selected,
    required this.onTap,
  });

  final int index;
  final TrainingProgram program;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = programColor(program.id, p);
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      onTap: onTap,
      borderColor: selected ? color.withValues(alpha: 0.45) : p.line,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 50,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                index.toString().padLeft(2, '0'),
                style: TextStyle(
                  fontFamily: 'BarlowCondensed',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        program.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.text,
                          fontSize: 13.5,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (selected) ...[
                      const SizedBox(width: 6),
                      Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: p.accent,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 3),
                Text(
                  program.tagline,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.faint, fontSize: 10),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Text(
                      '${program.daysPerWeek} days',
                      style: TextStyle(
                        color: p.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(width: 3, height: 3, color: p.faint),
                    const SizedBox(width: 8),
                    Text(
                      program.level,
                      style: TextStyle(
                        color: p.muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.faint, size: 19),
        ],
      ),
    );
  }
}

class _LibraryCard extends StatelessWidget {
  const _LibraryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 104,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: p.line),
        ),
        child: Row(
          children: [
            SizedBox(
              width: 106,
              height: 104,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    'assets/exercises/barbell_bench_press_medium_grip.jpg',
                    fit: BoxFit.cover,
                  ),
                  Container(
                    color: p.isDark
                        ? Colors.black.withValues(alpha: 0.35)
                        : Colors.white.withValues(alpha: 0.15),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'MOVEMENT LIBRARY',
                    style: TextStyle(
                      color: p.accent,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '69 exercises, explained.',
                    style: TextStyle(
                      color: p.text,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Photos, cues and step-by-step technique.',
                    style: TextStyle(color: p.faint, fontSize: 10),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Icon(
                Icons.arrow_forward_rounded,
                color: p.muted,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryStrip extends StatelessWidget {
  const _HistoryStrip({required this.data});

  final AppData data;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final sessions = data.completedSessions;
    final last = sessions.isEmpty ? null : sessions.first;
    return SurfaceCard(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const WorkoutHistoryScreen()),
        );
      },
      padding: const EdgeInsets.all(15),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: p.cardHigh,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: p.line),
            ),
            child: Icon(Icons.history_rounded, color: p.muted, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Workout history',
                  style: TextStyle(
                    color: p.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  sessions.isEmpty
                      ? 'No sessions logged yet'
                      : '${sessions.length} sessions · last ${relativeDay(last!.completedAt ?? last.startedAt).toLowerCase()}',
                  style: TextStyle(color: p.faint, fontSize: 10),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.faint, size: 19),
        ],
      ),
    );
  }
}
