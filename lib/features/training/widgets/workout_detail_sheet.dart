import 'package:flutter/material.dart';

import '../../../core/theme/app_palette.dart';
import '../../../core/utils/date_x.dart';
import '../../../core/utils/formatters.dart';
import '../../../features/profile/models/user_profile.dart';
import '../../../core/widgets/surfaces.dart';
import '../models/workout_session.dart';

Future<void> showWorkoutDetailSheet(
  BuildContext context, {
  required WorkoutSession session,
  required UnitSystem units,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => _WorkoutDetailSheet(session: session, units: units),
  );
}

class _WorkoutDetailSheet extends StatelessWidget {
  const _WorkoutDetailSheet({required this.session, required this.units});

  final WorkoutSession session;
  final UnitSystem units;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final date = session.completedAt ?? session.startedAt;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (context, controller) {
        return ListView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow(
                        '${session.programName} · ${formatLongDate(date)}',
                      ),
                      const SizedBox(height: 8),
                      Text(session.dayName, style: text.headlineLarge),
                    ],
                  ),
                ),
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(Icons.check_rounded, color: p.accent, size: 21),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  _DetailStat(
                    value: '${session.completedSetCount}',
                    label: 'SETS',
                  ),
                  _Divider(),
                  _DetailStat(
                    value: Fmt.volume(session.volumeKg, units),
                    label: 'VOLUME',
                  ),
                  _Divider(),
                  _DetailStat(
                    value: Fmt.durationWords(session.duration),
                    label: 'DURATION',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            SectionHeader(title: 'The work'),
            const SizedBox(height: 10),
            ...session.exercises.map((exercise) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: SurfaceCard(
                  padding: const EdgeInsets.all(15),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              exercise.name,
                              style: text.titleSmall?.copyWith(fontSize: 13.5),
                            ),
                          ),
                          Tag(
                            label: '${exercise.completedSets} sets',
                            compact: true,
                          ),
                        ],
                      ),
                      if (exercise.finishedSets.isNotEmpty) ...[
                        const SizedBox(height: 10),
                        ...exercise.finishedSets.asMap().entries.map((entry) {
                          final set = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(top: 5),
                            child: Row(
                              children: [
                                Text(
                                  'SET ${entry.key + 1}',
                                  style: TextStyle(
                                    color: p.faint,
                                    fontSize: 8.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.8,
                                  ),
                                ),
                                const Spacer(),
                                Text(
                                  set.weightKg > 0
                                      ? '${Fmt.weightValue(set.weightKg, units)} ${Fmt.weightLabel(units)} × ${set.reps}'
                                      : '${set.reps} reps · bodyweight',
                                  style: TextStyle(
                                    color: p.text,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ] else ...[
                        const SizedBox(height: 8),
                        Text(
                          'No sets completed',
                          style: TextStyle(color: p.faint, fontSize: 11),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }),
            if (session.notes?.trim().isNotEmpty ?? false) ...[
              const SizedBox(height: 6),
              SectionHeader(title: 'Session notes'),
              const SizedBox(height: 8),
              Text(
                session.notes!,
                style: TextStyle(color: p.muted, fontSize: 12.5, height: 1.5),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _DetailStat extends StatelessWidget {
  const _DetailStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: p.faint,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 26, color: context.palette.line);
  }
}
