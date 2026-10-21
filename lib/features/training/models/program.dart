class ProgramExercise {
  const ProgramExercise({
    required this.exerciseId,
    required this.sets,
    required this.reps,
    required this.restSeconds,
    this.tempo,
    this.note,
  });

  final String exerciseId;
  final int sets;
  final String reps;
  final int restSeconds;
  final String? tempo;
  final String? note;

  String get prescription {
    final tempoPart = tempo == null ? '' : '  ·  $tempo';
    return '$sets × $reps$tempoPart';
  }
}

class ProgramDay {
  const ProgramDay({
    required this.id,
    required this.name,
    required this.focus,
    required this.exercises,
    this.note,
  });

  final String id;
  final String name;
  final String focus;
  final List<ProgramExercise> exercises;
  final String? note;

  int get totalSets =>
      exercises.fold(0, (total, exercise) => total + exercise.sets);
}

class TrainingProgram {
  const TrainingProgram({
    required this.id,
    required this.name,
    required this.badge,
    required this.tagline,
    required this.description,
    required this.level,
    required this.goal,
    required this.daysPerWeek,
    required this.weeks,
    required this.equipment,
    required this.principles,
    required this.days,
    required this.credit,
    this.heroTag,
  });

  final String id;
  final String name;
  final String badge;
  final String tagline;
  final String description;
  final String level;
  final String goal;
  final int daysPerWeek;
  final int weeks;
  final String equipment;
  final List<String> principles;
  final List<ProgramDay> days;
  final String credit;
  final String? heroTag;

  ProgramDay? dayById(String id) {
    for (final day in days) {
      if (day.id == id) return day;
    }
    return null;
  }
}
