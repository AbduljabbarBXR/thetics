import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/surfaces.dart';
import '../profile/models/user_profile.dart';
import 'data/exercise_seed.dart';
import 'models/exercise.dart';

class ExerciseDetailScreen extends ConsumerWidget {
  const ExerciseDetailScreen({super.key, required this.exerciseId});

  final String exerciseId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final matches = exerciseSeed.where((exercise) => exercise.id == exerciseId);
    if (matches.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Exercise')),
        body: const EmptyState(
          icon: Icons.search_off_rounded,
          title: 'Exercise not found',
          message: 'This movement is not in the current library.',
        ),
      );
    }
    final exercise = matches.first;
    final data = ref.watch(appDataProvider);
    final units = data?.profile?.units ?? UnitSystem.metric;
    final pr = data?.prFor(exercise.id);

    return Scaffold(
      backgroundColor: p.bg,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 280,
            backgroundColor: p.bg,
            leading: Padding(
              padding: const EdgeInsets.all(6),
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.black.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(Icons.arrow_back_rounded, size: 20),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(exercise.imageAsset, fit: BoxFit.cover),
                  DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.05),
                          Colors.black.withValues(alpha: 0.82),
                        ],
                        stops: const [0.3, 1],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 20,
                    right: 20,
                    bottom: 22,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _ImageTag(exercise.group),
                            const SizedBox(width: 6),
                            _ImageTag(exercise.equipmentLabel),
                            if (exercise.hasAnimation) ...[
                              const SizedBox(width: 6),
                              const _ImageTag('GIF loop'),
                            ],
                          ],
                        ),
                        const SizedBox(height: 10),
                        Text(
                          exercise.name,
                          style: text.displaySmall?.copyWith(
                            color: Colors.white,
                            fontSize: 34,
                            height: 0.98,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          exercise.muscleSummary,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 32),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Row(
                  children: [
                    Expanded(
                      child: _InfoCell(
                        label: 'EQUIPMENT',
                        value: exercise.equipmentLabel,
                      ),
                    ),
                    Expanded(
                      child: _InfoCell(label: 'LEVEL', value: exercise.level),
                    ),
                    Expanded(
                      child: _InfoCell(
                        label: 'MECHANIC',
                        value: _titleCase(exercise.mechanic ?? '—'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                if (exercise.cue != null) ...[
                  Container(
                    padding: const EdgeInsets.all(17),
                    decoration: BoxDecoration(
                      color: p.accent.withValues(alpha: p.isDark ? 0.07 : 0.12),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: p.accent.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: p.accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.tips_and_updates_rounded,
                            color: p.onAccent,
                            size: 17,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "COACH'S CUE",
                                style: TextStyle(
                                  color: p.accent,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                exercise.cue!,
                                style: TextStyle(
                                  color: p.text,
                                  fontSize: 12.5,
                                  height: 1.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                if (exercise.animationAsset != null) ...[
                  SectionHeader(
                    title: 'Form loop',
                    eyebrow: 'Animated reference',
                  ),
                  const SizedBox(height: 10),
                  _FormLoopCard(exercise: exercise),
                  const SizedBox(height: 18),
                ],
                if (pr != null) ...[
                  SurfaceCard(
                    padding: const EdgeInsets.all(15),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: p.ember.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: Icon(
                            Icons.emoji_events_outlined,
                            color: p.ember,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'YOUR PERSONAL RECORD',
                                style: TextStyle(
                                  color: p.faint,
                                  fontSize: 8,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                '${Fmt.weight(pr.weightKg, units)} × ${pr.reps} reps',
                                style: TextStyle(
                                  color: p.text,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '~${Fmt.weightValue(pr.estimatedOneRepMax, units, decimals: 0)} ${Fmt.weightLabel(units)}',
                              style: TextStyle(
                                color: p.accent,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                            Text(
                              'est. 1RM',
                              style: TextStyle(color: p.faint, fontSize: 8),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                ],
                SectionHeader(
                  title: 'Execution',
                  eyebrow: '${exercise.instructions.length} steps',
                ),
                const SizedBox(height: 10),
                ...exercise.instructions.asMap().entries.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: p.card,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: p.line),
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${entry.key + 1}',
                                style: TextStyle(
                                  color: p.accent,
                                  fontSize: 9.5,
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
                                  height: 1.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: p.card.withValues(alpha: 0.45),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: p.line),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.photo_library_outlined,
                        size: 14,
                        color: p.faint,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Demonstration imagery, animated form loops and '
                          'execution notes from the free-exercise-db project '
                          '(Unlicense).',
                          style: TextStyle(
                            color: p.faint,
                            fontSize: 9.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

String _titleCase(String value) {
  if (value.isEmpty || value == '—') return value;
  return value
      .split(' ')
      .map(
        (word) => word.isEmpty
            ? word
            : '${word[0].toUpperCase()}${word.substring(1)}',
      )
      .join(' ');
}

class _FormLoopCard extends StatelessWidget {
  const _FormLoopCard({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final animation = exercise.animationAsset;
    if (animation == null) return const SizedBox.shrink();

    return SurfaceCard(
      padding: EdgeInsets.zero,
      radius: 20,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(19)),
            child: AspectRatio(
              aspectRatio: 3 / 2,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  Image.asset(
                    animation,
                    fit: BoxFit.cover,
                    gaplessPlayback: true,
                    filterQuality: FilterQuality.medium,
                    semanticLabel: '${exercise.name} animated form loop',
                    errorBuilder: (context, error, stackTrace) {
                      return Image.asset(
                        exercise.imageAsset,
                        fit: BoxFit.cover,
                        semanticLabel: exercise.name,
                      );
                    },
                  ),
                  Positioned(
                    top: 10,
                    left: 10,
                    child: _ImageTag('Form loop'),
                  ),
                ],
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 13),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.swap_horiz_rounded, size: 16, color: p.accent),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Start and finish positions from two public-domain '
                    'reference frames. Watch the transition, then own the '
                    'lowering phase.',
                    style: TextStyle(
                      color: p.faint,
                      fontSize: 9.5,
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

class _ImageTag extends StatelessWidget {
  const _ImageTag(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.7,
        ),
      ),
    );
  }
}

class _InfoCell extends StatelessWidget {
  const _InfoCell({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: p.faint,
            fontSize: 7.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 1,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: p.text,
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}
