import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/widgets/surfaces.dart';
import 'active_workout_screen.dart';
import 'exercise_detail_screen.dart';
import 'models/program.dart';
import 'program_utils.dart';
import 'data/exercise_seed.dart';

class ProgramDetailScreen extends ConsumerWidget {
  const ProgramDetailScreen({super.key, required this.program});

  final TrainingProgram program;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final data = ref.watch(appDataProvider);
    final active = ref.watch(activeWorkoutProvider);
    final selectedId = data?.selectedProgramId;
    final isSelected = selectedId == program.id;
    final nextDay =
        data == null ? program.days.first : nextDayForProgram(program, data);
    final color = programColor(program.id, p);

    Future<void> startDay(ProgramDay day) async {
      if (active != null) {
        Navigator.of(context).push(
          MaterialPageRoute<void>(builder: (_) => const ActiveWorkoutScreen()),
        );
        return;
      }
      final started = await ref
          .read(appControllerProvider.notifier)
          .startWorkout(program, day);
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
        MaterialPageRoute<void>(builder: (_) => const ActiveWorkoutScreen()),
      );
    }

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('Program'),
        actions: [
          if (!isSelected)
            TextButton(
              onPressed: () async {
                await ref
                    .read(appControllerProvider.notifier)
                    .selectProgram(program.id);
                if (!context.mounted) return;
                showTheticsSnack(
                  context,
                  '${program.name} is now your program.',
                );
              },
              child: const Text('Set active'),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              border: Border.all(color: p.line),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  p.cardHigh,
                  Color.alphaBlend(
                    color.withValues(alpha: p.isDark ? 0.13 : 0.16),
                    p.card,
                  ),
                ],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  right: -14,
                  top: -20,
                  child: Text(
                    program.badge,
                    style: TextStyle(
                      fontFamily: 'BarlowCondensed',
                      fontSize: 92,
                      height: 1,
                      fontWeight: FontWeight.w700,
                      color: color.withValues(alpha: 0.07),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Tag(label: program.badge, color: color),
                          const SizedBox(width: 7),
                          if (isSelected)
                            Tag(
                              label: 'Active program',
                              color: p.accent,
                              compact: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Text(
                        program.name,
                        style: text.displaySmall?.copyWith(
                          fontSize: 42,
                          height: 0.94,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Text(
                        program.tagline,
                        style: TextStyle(
                          color: color,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        program.description,
                        style: TextStyle(
                          color: p.muted,
                          fontSize: 12.5,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          _Meta(
                            value: '${program.daysPerWeek}',
                            label: 'DAYS / WK',
                          ),
                          _MetaDivider(),
                          _Meta(value: '${program.weeks}', label: 'WEEKS'),
                          _MetaDivider(),
                          Expanded(
                            child: _Meta(value: program.level, label: 'LEVEL'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: p.card,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: p.line),
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(Icons.skip_next_rounded, size: 17, color: color),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Next session · ${nextDay.name}',
                        style: TextStyle(
                          color: p.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      '${estimateMinutes(nextDay)} min',
                      style: TextStyle(color: p.faint, fontSize: 10),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => startDay(nextDay),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          active == null
                              ? Icons.bolt_rounded
                              : Icons.play_arrow_rounded,
                          size: 18,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          active == null
                              ? 'START NEXT SESSION'
                              : 'RESUME SESSION',
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 26),
          const SectionHeader(
            title: 'The method',
            eyebrow: 'Principles before sets',
          ),
          const SizedBox(height: 10),
          ...program.principles.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          '${entry.key + 1}',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          entry.value,
                          style: TextStyle(
                            color: p.muted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          const SizedBox(height: 24),
          SectionHeader(
            title: 'Training days',
            eyebrow: '${program.days.length} sessions in the rotation',
          ),
          const SizedBox(height: 10),
          ...program.days.asMap().entries.map(
                (entry) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _DayCard(
                    program: program,
                    day: entry.value,
                    index: entry.key,
                    color: color,
                    onStart: () => startDay(entry.value),
                    initiallyOpen: entry.key == 0,
                  ),
                ),
              ),
          const SizedBox(height: 18),
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
                Icon(Icons.info_outline_rounded, size: 16, color: p.faint),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    program.credit,
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
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
          ),
        ),
      ],
    );
  }
}

class _MetaDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 1,
      height: 25,
      margin: const EdgeInsets.symmetric(horizontal: 14),
      color: context.palette.line,
    );
  }
}

class _DayCard extends StatefulWidget {
  const _DayCard({
    required this.program,
    required this.day,
    required this.index,
    required this.color,
    required this.onStart,
    required this.initiallyOpen,
  });

  final TrainingProgram program;
  final ProgramDay day;
  final int index;
  final Color color;
  final VoidCallback onStart;
  final bool initiallyOpen;

  @override
  State<_DayCard> createState() => _DayCardState();
}

class _DayCardState extends State<_DayCard> {
  late bool _open;

  @override
  void initState() {
    super.initState();
    _open = widget.initiallyOpen;
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => setState(() => _open = !_open),
            child: Padding(
              padding: const EdgeInsets.all(15),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: widget.color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(11),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'D${widget.index + 1}',
                      style: TextStyle(
                        color: widget.color,
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.day.name,
                          style: text.titleSmall?.copyWith(fontSize: 14),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.day.focus,
                          style: TextStyle(color: p.faint, fontSize: 10),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${widget.day.totalSets} sets',
                    style: TextStyle(color: p.muted, fontSize: 9.5),
                  ),
                  const SizedBox(width: 5),
                  AnimatedRotation(
                    turns: _open ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: p.faint,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ),
          AnimatedCrossFade(
            duration: const Duration(milliseconds: 220),
            crossFadeState:
                _open ? CrossFadeState.showFirst : CrossFadeState.showSecond,
            firstChild: Column(
              children: [
                Divider(height: 1, color: p.line),
                Padding(
                  padding: const EdgeInsets.fromLTRB(15, 12, 15, 15),
                  child: Column(
                    children: [
                      ...widget.day.exercises.asMap().entries.map(
                            (entry) => _ExerciseRow(
                              prescription: entry.value,
                              color: widget.color,
                            ),
                          ),
                      if (widget.day.note != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(11),
                          decoration: BoxDecoration(
                            color: p.cardHigh,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Text(
                            widget.day.note!,
                            style: TextStyle(
                              color: p.faint,
                              fontSize: 10,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: widget.onStart,
                          icon: const Icon(Icons.bolt_rounded, size: 16),
                          label: Text('START ${widget.day.name.toUpperCase()}'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            secondChild: const SizedBox(width: double.infinity),
          ),
        ],
      ),
    );
  }
}

class _ExerciseRow extends StatelessWidget {
  const _ExerciseRow({required this.prescription, required this.color});

  final ProgramExercise prescription;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final exercise = exerciseSeed.where(
      (item) => item.id == prescription.exerciseId,
    );
    if (exercise.isEmpty) return const SizedBox.shrink();
    final item = exercise.first;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExerciseDetailScreen(exerciseId: item.id),
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(9),
              child: Image.asset(
                item.imageAsset,
                width: 44,
                height: 44,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: p.text,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${prescription.sets} × ${prescription.reps}${prescription.tempo == null ? '' : ' · ${prescription.tempo}'} · ${prescription.restSeconds}s rest',
                    style: TextStyle(color: p.faint, fontSize: 9),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, size: 16, color: p.faint),
          ],
        ),
      ),
    );
  }
}
