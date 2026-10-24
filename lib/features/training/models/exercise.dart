class Exercise {
  const Exercise({
    required this.id,
    required this.name,
    required this.group,
    required this.primaryMuscles,
    required this.secondaryMuscles,
    required this.equipment,
    required this.level,
    required this.instructions,
    required this.imageAsset,
    this.animationAsset,
    this.force,
    this.mechanic,
    this.cue,
  });

  final String id;
  final String name;
  final String group;
  final List<String> primaryMuscles;
  final List<String> secondaryMuscles;
  final String equipment;
  final String level;
  final String? force;
  final String? mechanic;
  final List<String> instructions;
  final String imageAsset;

  /// Optional animated GIF loop bundled for this movement.
  final String? animationAsset;
  final String? cue;

  bool get hasAnimation => animationAsset != null;

  String get muscleSummary {
    final parts = <String>[...primaryMuscles, ...secondaryMuscles.take(2)];
    return parts.map(_titleCase).join(' · ');
  }

  String get equipmentLabel => _titleCase(equipment);

  static String _titleCase(String value) {
    return value
        .split(' ')
        .map(
          (word) => word.isEmpty
              ? word
              : '${word[0].toUpperCase()}${word.substring(1)}',
        )
        .join(' ');
  }
}

const muscleGroups = <String>[
  'Chest',
  'Back',
  'Shoulders',
  'Arms',
  'Legs',
  'Glutes',
  'Calves',
  'Core',
];
