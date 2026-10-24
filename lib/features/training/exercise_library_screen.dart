import 'package:flutter/material.dart';

import '../../core/theme/app_palette.dart';
import '../../core/widgets/surfaces.dart';
import 'exercise_detail_screen.dart';
import 'models/exercise.dart';
import 'data/exercise_seed.dart';

class ExerciseLibraryScreen extends StatefulWidget {
  const ExerciseLibraryScreen({super.key});

  @override
  State<ExerciseLibraryScreen> createState() => _ExerciseLibraryScreenState();
}

class _ExerciseLibraryScreenState extends State<ExerciseLibraryScreen> {
  final _search = TextEditingController();
  String _group = 'All';
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<Exercise> get _filtered {
    final query = _query.trim().toLowerCase();
    return exerciseSeed.where((exercise) {
      final groupMatch = _group == 'All' || exercise.group == _group;
      final queryMatch = query.isEmpty ||
          exercise.name.toLowerCase().contains(query) ||
          exercise.muscleSummary.toLowerCase().contains(query) ||
          exercise.equipment.toLowerCase().contains(query);
      return groupMatch && queryMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final exercises = _filtered;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('Exercise library'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Tag(
              label: '${exerciseSeed.length} movements',
              compact: true,
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'KNOW THE\nMOVEMENT.',
                    style: text.displaySmall?.copyWith(
                      fontSize: 38,
                      height: 0.9,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Technique first. Load second. Every exercise includes '
                    'step-by-step execution and a practical cue.',
                    style: TextStyle(color: p.muted, fontSize: 12, height: 1.5),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _search,
                    onChanged: (value) => setState(() => _query = value),
                    decoration: InputDecoration(
                      hintText: 'Search exercise, muscle or equipment',
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: p.faint,
                        size: 20,
                      ),
                      suffixIcon: _query.isEmpty
                          ? null
                          : IconButton(
                              onPressed: () {
                                _search.clear();
                                setState(() => _query = '');
                              },
                              icon: Icon(
                                Icons.close_rounded,
                                color: p.faint,
                                size: 18,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _FilterChip(
                          label: 'All',
                          selected: _group == 'All',
                          onTap: () => setState(() => _group = 'All'),
                        ),
                        ...muscleGroups.map(
                          (group) => _FilterChip(
                            label: group,
                            selected: _group == group,
                            onTap: () => setState(() => _group = group),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Text(
                        '${exercises.length} exercises',
                        style: TextStyle(
                          color: p.faint,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const Spacer(),
                      if (_query.isNotEmpty)
                        Text(
                          'Search: “$_query”',
                          style: TextStyle(color: p.faint, fontSize: 9.5),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
          if (exercises.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: EmptyState(
                icon: Icons.search_off_rounded,
                title: 'No exercises found',
                message: 'Try another muscle group or clear the search.',
                actionLabel: 'CLEAR FILTERS',
                onAction: () {
                  _search.clear();
                  setState(() {
                    _query = '';
                    _group = 'All';
                  });
                },
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              sliver: SliverList.separated(
                itemCount: exercises.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final exercise = exercises[index];
                  return _ExerciseTile(exercise: exercise);
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? p.accent : p.card,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: selected ? p.accent : p.line),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: selected ? p.onAccent : p.muted,
            fontSize: 10.5,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({required this.exercise});

  final Exercise exercise;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      padding: const EdgeInsets.all(9),
      radius: 16,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ExerciseDetailScreen(exerciseId: exercise.id),
          ),
        );
      },
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(11),
            child: Image.asset(
              exercise.imageAsset,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  exercise.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.text,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${exercise.group} · ${exercise.equipmentLabel}',
                  style: TextStyle(color: p.faint, fontSize: 9.5),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Tag(
                      label: exercise.level,
                      compact: true,
                      color: exercise.level == 'Beginner'
                          ? p.success
                          : exercise.level == 'Expert'
                              ? p.ember
                              : p.sky,
                    ),
                    if (exercise.hasAnimation) ...[
                      const SizedBox(width: 5),
                      Tag(
                        label: 'GIF',
                        icon: Icons.gif_box_rounded,
                        compact: true,
                        color: p.accent,
                      ),
                    ],
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        exercise.muscleSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: p.faint, fontSize: 8.5),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.faint, size: 18),
        ],
      ),
    );
  }
}
