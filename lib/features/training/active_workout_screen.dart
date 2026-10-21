import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_x.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/surfaces.dart';
import '../profile/models/user_profile.dart';
import '../shell/app_shell.dart';
import 'exercise_detail_screen.dart';
import 'models/workout_session.dart';

class ActiveWorkoutScreen extends ConsumerStatefulWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  ConsumerState<ActiveWorkoutScreen> createState() =>
      _ActiveWorkoutScreenState();
}

class _ActiveWorkoutScreenState extends ConsumerState<ActiveWorkoutScreen> {
  Timer? _ticker;
  DateTime? _notifiedRest;
  _Completion? _completion;
  bool _finishing = false;
  late final TextEditingController _notesController;

  @override
  void initState() {
    super.initState();
    final active = ref.read(activeWorkoutProvider);
    _notesController = TextEditingController(text: active?.notes ?? '');
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      _checkRestFinished();
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _notesController.dispose();
    super.dispose();
  }

  void _checkRestFinished() {
    if (_completion != null || !mounted) return;
    final active = ref.read(activeWorkoutProvider);
    final rest = active?.restEndsAt;
    if (rest == null || _notifiedRest == rest) return;
    if (DateTime.now().isBefore(rest)) return;
    _notifiedRest = rest;
    final settings = ref.read(appDataProvider)?.settings;
    if (settings?.restAlerts ?? true) {
      HapticFeedback.heavyImpact();
    }
    if (settings?.haptics ?? true) {
      HapticFeedback.mediumImpact();
    }
    unawaited(_clearRest());
  }

  Future<void> _clearRest() async {
    final active = ref.read(activeWorkoutProvider);
    if (active == null) return;
    await ref
        .read(appControllerProvider.notifier)
        .updateActiveWorkout(active.copyWith(clearRest: true));
  }

  Future<void> _toggleSet({
    required WorkoutSession workout,
    required int exerciseIndex,
    required int setIndex,
    required double weightKg,
    required int reps,
    required bool completed,
  }) async {
    final exercises = [...workout.exercises];
    final exercise = exercises[exerciseIndex];
    if (setIndex >= exercise.sets.length) return;
    final sets = [...exercise.sets];
    final previous = sets[setIndex];
    sets[setIndex] = SetLog(
      weightKg: weightKg,
      reps: reps,
      completed: completed,
      rpe: previous.rpe,
      note: previous.note,
    );
    exercises[exerciseIndex] = exercise.copyWith(
      sets: sets,
      completed: sets.every((set) => set.completed) && sets.isNotEmpty,
    );
    DateTime? restEndsAt;
    if (completed) {
      restEndsAt = DateTime.now().add(Duration(seconds: exercise.restSeconds));
      _notifiedRest = null;
      final haptics = ref.read(appDataProvider)?.settings.haptics ?? true;
      if (haptics) HapticFeedback.mediumImpact();
    }
    await ref.read(appControllerProvider.notifier).updateActiveWorkout(
          workout.copyWith(exercises: exercises, restEndsAt: restEndsAt),
        );
  }

  Future<void> _discard() async {
    final confirmed = await confirmAction(
      context,
      title: 'Discard this session?',
      message:
          'Every set logged in this session will be removed. This cannot be undone.',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    await ref.read(appControllerProvider.notifier).discardActiveWorkout();
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _openFinish(WorkoutSession workout) async {
    final data = ref.read(appDataProvider);
    if (workout.completedSetCount == 0) {
      showTheticsSnack(
        context,
        'Complete at least one set before finishing.',
        error: true,
      );
      return;
    }
    final shouldFinish = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FinishSheet(
        workout: workout,
        notesController: _notesController,
        units: data?.profile?.units ?? UnitSystem.metric,
      ),
    );
    if (shouldFinish != true || !mounted) return;
    setState(() => _finishing = true);
    try {
      final result = await ref
          .read(appControllerProvider.notifier)
          .finishActiveWorkout(notes: _notesController.text.trim());
      if (!mounted || result == null) return;
      setState(() {
        _completion = _Completion(workout: result.workout, prs: result.prs);
      });
    } finally {
      if (mounted) setState(() => _finishing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final data = ref.watch(appDataProvider);
    final active = data?.activeWorkout;
    final units = data?.profile?.units ?? UnitSystem.metric;

    if (_completion != null) {
      return _CompletionView(
        completion: _completion!,
        units: units,
        onDone: () {
          ref.read(selectedTabProvider.notifier).state = 0;
          Navigator.of(context).pop();
        },
      );
    }

    if (active == null) {
      return Scaffold(
        backgroundColor: p.bg,
        appBar: AppBar(title: const Text('Workout')),
        body: Center(
          child: EmptyState(
            icon: Icons.fitness_center_rounded,
            title: 'No active session',
            message: 'Start a workout from the dashboard or a program.',
            actionLabel: 'GO BACK',
            onAction: () => Navigator.of(context).pop(),
          ),
        ),
      );
    }

    final restRemaining = _restRemaining(active);
    ExerciseLog? nextExercise;
    for (final exercise in active.exercises) {
      if (exercise.completedSets < exercise.targetSets) {
        nextExercise = exercise;
        break;
      }
    }
    final settings = data?.settings;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 26),
          tooltip: 'Minimise workout',
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              active.dayName,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
            ),
            Text(
              '${active.programName} · ${Fmt.clock(active.duration)}',
              style: TextStyle(
                color: p.faint,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: p.danger.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(100),
                border: Border.all(color: p.danger.withValues(alpha: 0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: p.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'LIVE',
                    style: TextStyle(
                      color: p.danger,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.more_horiz_rounded, color: p.muted),
            onSelected: (value) {
              if (value == 'discard') _discard();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'discard',
                child: Text('Discard workout'),
              ),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              children: [
                _SessionSummary(workout: active),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Text(
                      'EXERCISES',
                      style: TextStyle(
                        color: p.faint,
                        fontSize: 8.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Check a set to bank it',
                      style: TextStyle(color: p.faint, fontSize: 9.5),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...active.exercises.asMap().entries.map((entry) {
                  final exercise = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 11),
                    child: _ExerciseLogCard(
                      key: ValueKey(exercise.exerciseId),
                      exercise: exercise,
                      exerciseIndex: entry.key,
                      units: units,
                      isNext: nextExercise?.exerciseId == exercise.exerciseId,
                      onToggle: (setIndex, weight, reps, completed) =>
                          _toggleSet(
                        workout: active,
                        exerciseIndex: entry.key,
                        setIndex: setIndex,
                        weightKg: weight,
                        reps: reps,
                        completed: completed,
                      ),
                      onOpenExercise: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => ExerciseDetailScreen(
                              exerciseId: exercise.exerciseId,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                }),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.card.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: p.line),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.tips_and_updates_outlined,
                        size: 16,
                        color: p.faint,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Keep 1–2 reps in reserve unless the program says '
                          'otherwise. Stop the set when form breaks — not when '
                          'the weight stops moving.',
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
          Container(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            decoration: BoxDecoration(
              color: p.surface,
              border: Border(top: BorderSide(color: p.line)),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (restRemaining > 0)
                    _RestBar(
                      remaining: restRemaining,
                      totalSeconds: nextExercise?.restSeconds ??
                          active.exercises.first.restSeconds,
                      onAdd: () async {
                        final current = ref.read(activeWorkoutProvider);
                        if (current == null) return;
                        final base = current.restEndsAt ?? DateTime.now();
                        await ref
                            .read(appControllerProvider.notifier)
                            .updateActiveWorkout(
                              current.copyWith(
                                restEndsAt: base.add(
                                  const Duration(seconds: 30),
                                ),
                              ),
                            );
                        _notifiedRest = null;
                      },
                      onSkip: _clearRest,
                    ),
                  if (restRemaining > 0) const SizedBox(height: 9),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _finishing ? null : () => _openFinish(active),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 50),
                        backgroundColor: p.accent,
                      ),
                      child: _finishing
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_rounded, size: 19),
                                const SizedBox(width: 8),
                                Text(
                                  'FINISH SESSION · ${active.completedSetCount}/${active.plannedSetCount}',
                                ),
                              ],
                            ),
                    ),
                  ),
                  if (settings?.restAlerts ?? true)
                    Padding(
                      padding: const EdgeInsets.only(top: 6),
                      child: Text(
                        'Rest timer starts automatically after each set.',
                        style: TextStyle(color: p.faint, fontSize: 8.5),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  int _restRemaining(WorkoutSession workout) {
    final end = workout.restEndsAt;
    if (end == null) return 0;
    final seconds = end.difference(DateTime.now()).inSeconds + 1;
    return seconds > 0 ? seconds : 0;
  }
}

class _SessionSummary extends StatelessWidget {
  const _SessionSummary({required this.workout});

  final WorkoutSession workout;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = workout.plannedSetCount == 0
        ? 0.0
        : workout.completedSetCount / workout.plannedSetCount;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            p.cardHigh,
            Color.alphaBlend(
              p.accent.withValues(alpha: p.isDark ? 0.07 : 0.1),
              p.card,
            ),
          ],
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: p.line),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SETS COMPLETE',
                      style: TextStyle(
                        color: p.faint,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${workout.completedSetCount}',
                          style: Theme.of(context)
                              .textTheme
                              .displaySmall
                              ?.copyWith(fontSize: 40, height: 0.9),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4, left: 3),
                          child: Text(
                            '/ ${workout.plannedSetCount}',
                            style: TextStyle(color: p.faint, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Container(width: 1, height: 36, color: p.line),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VOLUME',
                      style: TextStyle(
                        color: p.faint,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${(workout.volumeKg / 1000).toStringAsFixed(1)}k',
                      style: Theme.of(context)
                          .textTheme
                          .displaySmall
                          ?.copyWith(fontSize: 34, height: 0.95),
                    ),
                    Text(
                      'kg moved',
                      style: TextStyle(color: p.faint, fontSize: 9),
                    ),
                  ],
                ),
              ),
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: p.accent.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  '${(progress * 100).round()}%',
                  style: TextStyle(
                    color: p.accent,
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SegmentedProgress(value: progress, height: 6),
        ],
      ),
    );
  }
}

class _ExerciseLogCard extends StatefulWidget {
  const _ExerciseLogCard({
    super.key,
    required this.exercise,
    required this.exerciseIndex,
    required this.units,
    required this.isNext,
    required this.onToggle,
    required this.onOpenExercise,
  });

  final ExerciseLog exercise;
  final int exerciseIndex;
  final UnitSystem units;
  final bool isNext;
  final Future<void> Function(
    int setIndex,
    double weightKg,
    int reps,
    bool completed,
  ) onToggle;
  final VoidCallback onOpenExercise;

  @override
  State<_ExerciseLogCard> createState() => _ExerciseLogCardState();
}

class _ExerciseLogCardState extends State<_ExerciseLogCard> {
  late List<TextEditingController> _weights;
  late List<TextEditingController> _reps;

  @override
  void initState() {
    super.initState();
    _buildControllers();
  }

  void _buildControllers() {
    _weights = widget.exercise.sets.map((set) {
      if (set.weightKg <= 0) return TextEditingController();
      final display = widget.units == UnitSystem.imperial
          ? Fmt.kgToLb(set.weightKg)
          : set.weightKg;
      return TextEditingController(
        text: display.toStringAsFixed(display % 1 == 0 ? 0 : 1),
      );
    }).toList();
    _reps = widget.exercise.sets
        .map(
          (set) =>
              TextEditingController(text: set.reps > 0 ? '${set.reps}' : ''),
        )
        .toList();
  }

  @override
  void didUpdateWidget(covariant _ExerciseLogCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.exercise.sets.length != widget.exercise.sets.length ||
        oldWidget.units != widget.units) {
      for (final controller in _weights) {
        controller.dispose();
      }
      for (final controller in _reps) {
        controller.dispose();
      }
      _buildControllers();
    }
  }

  @override
  void dispose() {
    for (final controller in _weights) {
      controller.dispose();
    }
    for (final controller in _reps) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _toggle(int index) async {
    final set = widget.exercise.sets[index];
    final rawWeight = double.tryParse(
      _weights[index].text.trim().replaceAll(',', '.'),
    );
    final weightKg = rawWeight == null
        ? 0.0
        : widget.units == UnitSystem.imperial
            ? Fmt.lbToKg(rawWeight)
            : rawWeight;
    final reps = int.tryParse(_reps[index].text.trim()) ?? 0;
    if (!set.completed) {
      if (reps <= 0) {
        showTheticsSnack(context, 'Enter the reps for this set.', error: true);
        return;
      }
      if (weightKg < 0) {
        showTheticsSnack(context, 'Enter a valid load.', error: true);
        return;
      }
    }
    await widget.onToggle(index, weightKg, reps, !set.completed);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final exercise = widget.exercise;
    final allDone = exercise.completedSets >= exercise.targetSets;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: widget.isNext
              ? p.accent.withValues(alpha: 0.38)
              : allDone
                  ? p.success.withValues(alpha: 0.25)
                  : p.line,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color:
                      allDone ? p.success.withValues(alpha: 0.12) : p.cardHigh,
                  borderRadius: BorderRadius.circular(9),
                ),
                alignment: Alignment.center,
                child: Text(
                  '${widget.exerciseIndex + 1}',
                  style: TextStyle(
                    color: allDone ? p.success : p.muted,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      exercise.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall?.copyWith(
                        fontSize: 13,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${exercise.repsLabel} · ${exercise.restSeconds}s rest${exercise.tempo == null ? '' : ' · ${exercise.tempo}'}',
                      style: TextStyle(color: p.faint, fontSize: 9),
                    ),
                  ],
                ),
              ),
              if (allDone)
                Icon(Icons.check_circle_rounded, color: p.success, size: 20)
              else
                Text(
                  '${exercise.completedSets}/${exercise.targetSets}',
                  style: TextStyle(
                    color: p.faint,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(width: 3),
              IconButton(
                onPressed: widget.onOpenExercise,
                icon: Icon(
                  Icons.info_outline_rounded,
                  size: 16,
                  color: p.faint,
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
              ),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              const SizedBox(width: 29),
              Expanded(
                flex: 5,
                child: Text(
                  'WEIGHT (${Fmt.weightLabel(widget.units).toUpperCase()})',
                  style: TextStyle(
                    color: p.faint,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                flex: 4,
                child: Text(
                  'REPS',
                  style: TextStyle(
                    color: p.faint,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 38),
            ],
          ),
          const SizedBox(height: 4),
          ...exercise.sets.asMap().entries.map((entry) {
            final index = entry.key;
            final set = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 5),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: set.completed
                      ? p.accent.withValues(alpha: 0.055)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 29,
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: set.completed ? p.accent : p.faint,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 5,
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _weights[index],
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: set.completed ? p.text : p.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: p.cardHigh.withValues(alpha: 0.6),
                            hintText: 'BW',
                            suffixText: Fmt.weightLabel(widget.units),
                            suffixStyle: TextStyle(
                              color: p.faint,
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide(color: p.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide(color: p.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide(color: p.accent, width: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      flex: 4,
                      child: SizedBox(
                        height: 38,
                        child: TextField(
                          controller: _reps[index],
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: set.completed ? p.text : p.muted,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                          decoration: InputDecoration(
                            isDense: true,
                            filled: true,
                            fillColor: p.cardHigh.withValues(alpha: 0.6),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 10,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide(color: p.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide(color: p.line),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(9),
                              borderSide: BorderSide(color: p.accent, width: 1),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    GestureDetector(
                      onTap: () => _toggle(index),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: set.completed ? p.accent : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: set.completed ? p.accent : p.line,
                            width: 1.3,
                          ),
                        ),
                        child: Icon(
                          Icons.check_rounded,
                          size: 17,
                          color: set.completed ? p.onAccent : p.faint,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _RestBar extends StatelessWidget {
  const _RestBar({
    required this.remaining,
    required this.totalSeconds,
    required this.onAdd,
    required this.onSkip,
  });

  final int remaining;
  final int totalSeconds;
  final VoidCallback onAdd;
  final VoidCallback onSkip;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: p.cardHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.accent.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: totalSeconds == 0
                      ? 0
                      : (remaining / totalSeconds).clamp(0.0, 1.0),
                  strokeWidth: 2.5,
                  backgroundColor: p.line,
                  color: p.accent,
                ),
                Icon(Icons.timer_outlined, size: 13, color: p.accent),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'REST',
                style: TextStyle(
                  color: p.faint,
                  fontSize: 7.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Text(
                Fmt.clock(Duration(seconds: remaining)),
                style: TextStyle(
                  color: p.text,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const Spacer(),
          TextButton(
            onPressed: onAdd,
            style: TextButton.styleFrom(
              foregroundColor: p.accent,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('+30s'),
          ),
          TextButton(
            onPressed: onSkip,
            style: TextButton.styleFrom(
              foregroundColor: p.muted,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              minimumSize: const Size(0, 36),
            ),
            child: const Text('Skip'),
          ),
        ],
      ),
    );
  }
}

class _FinishSheet extends StatelessWidget {
  const _FinishSheet({
    required this.workout,
    required this.notesController,
    required this.units,
  });

  final WorkoutSession workout;
  final TextEditingController notesController;
  final UnitSystem units;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Finish this session?', style: text.headlineSmall),
            const SizedBox(height: 6),
            Text(
              '${workout.dayName} · ${workout.programName}',
              style: TextStyle(color: p.muted, fontSize: 12),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _FinishStat(
                    value: '${workout.completedSetCount}',
                    label: 'SETS',
                  ),
                ),
                Expanded(
                  child: _FinishStat(
                    value: Fmt.volume(workout.volumeKg, units),
                    label: 'VOLUME',
                  ),
                ),
                Expanded(
                  child: _FinishStat(
                    value: Fmt.clock(workout.duration),
                    label: 'TIME',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              'SESSION NOTES',
              style: TextStyle(
                color: p.faint,
                fontSize: 8.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: notesController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                hintText: 'Energy, form cues, what to beat next time…',
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.check_rounded, size: 19),
                label: const Text('FINISH & SAVE'),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('KEEP TRAINING'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FinishStat extends StatelessWidget {
  const _FinishStat({required this.value, required this.label});

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
          style: Theme.of(context)
              .textTheme
              .headlineMedium
              ?.copyWith(fontSize: 22),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: p.faint,
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
      ],
    );
  }
}

class _Completion {
  const _Completion({required this.workout, required this.prs});

  final WorkoutSession workout;
  final List<PersonalRecord> prs;
}

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.completion,
    required this.units,
    required this.onDone,
  });

  final _Completion completion;
  final UnitSystem units;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final workout = completion.workout;
    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 36, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: p.accent,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: p.accent.withValues(alpha: 0.25),
                      blurRadius: 30,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: Icon(Icons.check_rounded, color: p.onAccent, size: 34),
              ),
              const SizedBox(height: 26),
              const Eyebrow('Session complete', color: Colors.white38),
              const SizedBox(height: 8),
              Text(
                'WORK\nBANKED.',
                style: text.displayLarge?.copyWith(
                  fontSize: 64,
                  height: 0.85,
                  color: p.text,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                '${workout.dayName} · ${workout.programName}\n'
                '${formatLongDate(workout.completedAt ?? DateTime.now())}',
                style: TextStyle(color: p.muted, fontSize: 12, height: 1.5),
              ),
              const SizedBox(height: 24),
              SurfaceCard(
                child: Column(
                  children: [
                    Row(
                      children: [
                        _CompletionStat(
                          value: '${workout.completedSetCount}',
                          label: 'SETS',
                        ),
                        _CompletionDivider(),
                        _CompletionStat(
                          value: Fmt.volume(workout.volumeKg, units),
                          label: 'VOLUME',
                        ),
                        _CompletionDivider(),
                        _CompletionStat(
                          value: Fmt.durationWords(workout.duration),
                          label: 'TIME',
                        ),
                      ],
                    ),
                    if (completion.prs.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Divider(color: p.line),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.emoji_events_outlined,
                            size: 16,
                            color: p.ember,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            '${completion.prs.length} NEW PERSONAL RECORD${completion.prs.length == 1 ? '' : 'S'}',
                            style: TextStyle(
                              color: p.ember,
                              fontSize: 8.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ...completion.prs.map(
                        (pr) => Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  pr.exerciseName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: p.muted,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                              Text(
                                '${Fmt.weight(pr.weightKg, units)} × ${pr.reps}',
                                style: TextStyle(
                                  color: p.text,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (workout.notes?.trim().isNotEmpty ?? false)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: p.card.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: p.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SESSION NOTES',
                        style: TextStyle(
                          color: p.faint,
                          fontSize: 8,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1,
                        ),
                      ),
                      const SizedBox(height: 5),
                      Text(
                        workout.notes!,
                        style: TextStyle(
                          color: p.muted,
                          fontSize: 11.5,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: onDone,
                  child: const Text('BACK TO HOME'),
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Text(
                  'Recover like it matters. It does.',
                  style: TextStyle(color: p.faint, fontSize: 10),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompletionStat extends StatelessWidget {
  const _CompletionStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            maxLines: 1,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: context.palette.faint,
              fontSize: 7.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompletionDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 28, color: context.palette.line);
  }
}
