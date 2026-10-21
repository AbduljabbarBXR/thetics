import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_x.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/surfaces.dart';
import '../profile/models/user_profile.dart';
import '../shell/app_shell.dart';
import 'models/workout_session.dart';
import 'widgets/workout_detail_sheet.dart';

class WorkoutHistoryScreen extends ConsumerWidget {
  const WorkoutHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final data = ref.watch(appDataProvider);
    if (data == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('History')),
        body: const SizedBox.shrink(),
      );
    }
    final units = data.profile?.units ?? UnitSystem.metric;
    final sessions = data.completedSessions;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('Training history'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Tag(label: '${sessions.length} sessions', compact: true),
          ),
        ],
      ),
      body: sessions.isEmpty
          ? EmptyState(
              icon: Icons.history_rounded,
              title: 'No history yet',
              message:
                  'Your logged sessions will live here — every set, every load, '
                  'every small win.',
              actionLabel: 'BROWSE PROGRAMS',
              onAction: () {
                ref.read(selectedTabProvider.notifier).state = 1;
                Navigator.of(context).pop();
              },
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
              children: [
                Text(
                  'THE RECEIPTS.',
                  style: text.displaySmall?.copyWith(fontSize: 40, height: 0.9),
                ),
                const SizedBox(height: 7),
                Text(
                  'No hype. Just the work you have actually banked.',
                  style: TextStyle(color: p.muted, fontSize: 12),
                ),
                const SizedBox(height: 18),
                SurfaceCard(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      _HistoryStat(
                        value: '${data.totalCompletedWorkouts}',
                        label: 'SESSIONS',
                      ),
                      _HistoryDivider(),
                      _HistoryStat(
                        value: Fmt.volume(data.totalVolumeKg, units),
                        label: 'TOTAL VOLUME',
                      ),
                      _HistoryDivider(),
                      _HistoryStat(
                        value: '${data.weekStreak}',
                        label: 'WEEK STREAK',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SectionHeader(title: 'Sessions', eyebrow: 'Most recent first'),
                const SizedBox(height: 10),
                ...sessions.map(
                  (session) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _HistoryRow(
                      session: session,
                      units: units,
                      onTap: () => showWorkoutDetailSheet(
                        context,
                        session: session,
                        units: units,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    border: Border.all(color: p.line),
                    borderRadius: BorderRadius.circular(14),
                    color: p.card.withValues(alpha: 0.4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.show_chart_rounded, size: 17, color: p.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'The trend beats the single session. Beat last '
                          'week’s numbers by a little, not by everything.',
                          style: TextStyle(
                            color: p.faint,
                            fontSize: 10.5,
                            height: 1.45,
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

class _HistoryStat extends StatelessWidget {
  const _HistoryStat({required this.value, required this.label});

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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontSize: 15, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              color: p.faint,
              fontSize: 7,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.9,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 27, color: context.palette.line);
  }
}

class _HistoryRow extends StatelessWidget {
  const _HistoryRow({
    required this.session,
    required this.units,
    required this.onTap,
  });

  final WorkoutSession session;
  final UnitSystem units;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final date = session.completedAt ?? session.startedAt;
    return SurfaceCard(
      padding: const EdgeInsets.all(12),
      radius: 16,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 48,
            decoration: BoxDecoration(
              color: p.cardHigh,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: p.line),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '${date.day}',
                  style: TextStyle(
                    color: p.text,
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    height: 1,
                  ),
                ),
                Text(
                  monthShort(date).toUpperCase(),
                  style: TextStyle(
                    color: p.accent,
                    fontSize: 7,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  session.dayName,
                  style: TextStyle(
                    color: p.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${session.programName} · ${Fmt.clock(session.duration)}',
                  style: TextStyle(color: p.faint, fontSize: 9.5),
                ),
                const SizedBox(height: 3),
                Text(
                  '${session.completedSetCount} sets · ${session.exerciseCount} exercises',
                  style: TextStyle(color: p.muted, fontSize: 9.5),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Fmt.volume(session.volumeKg, units),
                style: TextStyle(
                  color: p.text,
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                relativeDay(date),
                style: TextStyle(color: p.faint, fontSize: 8.5),
              ),
            ],
          ),
          const SizedBox(width: 3),
          Icon(Icons.chevron_right_rounded, size: 17, color: p.faint),
        ],
      ),
    );
  }
}
