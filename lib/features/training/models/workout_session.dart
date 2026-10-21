class SetLog {
  const SetLog({
    required this.weightKg,
    required this.reps,
    this.completed = false,
    this.rpe,
    this.note,
  });

  final double weightKg;
  final int reps;
  final bool completed;
  final int? rpe;
  final String? note;

  double get volumeKg => weightKg * reps;

  SetLog copyWith({
    double? weightKg,
    int? reps,
    bool? completed,
    int? rpe,
    String? note,
    bool clearRpe = false,
  }) {
    return SetLog(
      weightKg: weightKg ?? this.weightKg,
      reps: reps ?? this.reps,
      completed: completed ?? this.completed,
      rpe: clearRpe ? null : (rpe ?? this.rpe),
      note: note ?? this.note,
    );
  }

  Map<String, dynamic> toJson() => {
        'weightKg': weightKg,
        'reps': reps,
        'completed': completed,
        'rpe': rpe,
        'note': note,
      };

  factory SetLog.fromJson(Map<String, dynamic> json) {
    return SetLog(
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 0,
      reps: (json['reps'] as num?)?.toInt() ?? 0,
      completed: json['completed'] as bool? ?? false,
      rpe: (json['rpe'] as num?)?.toInt(),
      note: json['note'] as String?,
    );
  }
}

class ExerciseLog {
  const ExerciseLog({
    required this.exerciseId,
    required this.name,
    required this.targetSets,
    required this.repsLabel,
    required this.restSeconds,
    required this.sets,
    this.completed = false,
    this.notes,
    this.tempo,
  });

  final String exerciseId;
  final String name;
  final int targetSets;
  final String repsLabel;
  final int restSeconds;
  final List<SetLog> sets;
  final bool completed;
  final String? notes;
  final String? tempo;

  List<SetLog> get finishedSets =>
      sets.where((set) => set.completed).toList(growable: false);

  int get completedSets => finishedSets.length;

  double get volumeKg =>
      finishedSets.fold(0, (total, set) => total + set.volumeKg);

  double get topWeightKg => finishedSets.isEmpty
      ? 0
      : finishedSets.map((set) => set.weightKg).reduce((a, b) => a > b ? a : b);

  ExerciseLog copyWith({List<SetLog>? sets, bool? completed, String? notes}) {
    return ExerciseLog(
      exerciseId: exerciseId,
      name: name,
      targetSets: targetSets,
      repsLabel: repsLabel,
      restSeconds: restSeconds,
      sets: sets ?? this.sets,
      completed: completed ?? this.completed,
      notes: notes ?? this.notes,
      tempo: tempo,
    );
  }

  Map<String, dynamic> toJson() => {
        'exerciseId': exerciseId,
        'name': name,
        'targetSets': targetSets,
        'repsLabel': repsLabel,
        'restSeconds': restSeconds,
        'sets': sets.map((set) => set.toJson()).toList(),
        'completed': completed,
        'notes': notes,
        'tempo': tempo,
      };

  factory ExerciseLog.fromJson(Map<String, dynamic> json) {
    return ExerciseLog(
      exerciseId: json['exerciseId'] as String? ?? '',
      name: json['name'] as String? ?? '',
      targetSets: (json['targetSets'] as num?)?.toInt() ?? 0,
      repsLabel: json['repsLabel'] as String? ?? '',
      restSeconds: (json['restSeconds'] as num?)?.toInt() ?? 90,
      sets: (json['sets'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(SetLog.fromJson)
          .toList(),
      completed: json['completed'] as bool? ?? false,
      notes: json['notes'] as String?,
      tempo: json['tempo'] as String?,
    );
  }
}

class WorkoutSession {
  const WorkoutSession({
    required this.id,
    required this.programId,
    required this.programName,
    required this.dayId,
    required this.dayName,
    required this.startedAt,
    required this.exercises,
    this.completedAt,
    this.notes,
    this.restEndsAt,
  });

  final String id;
  final String programId;
  final String programName;
  final String dayId;
  final String dayName;
  final DateTime startedAt;
  final DateTime? completedAt;
  final List<ExerciseLog> exercises;
  final String? notes;

  /// Set while a rest timer is running in an active workout.
  final DateTime? restEndsAt;

  bool get isActive => completedAt == null;

  Duration get duration {
    final end = completedAt ?? DateTime.now();
    final value = end.difference(startedAt);
    return value.isNegative ? Duration.zero : value;
  }

  int get completedSetCount =>
      exercises.fold(0, (total, exercise) => total + exercise.completedSets);

  int get plannedSetCount =>
      exercises.fold(0, (total, exercise) => total + exercise.targetSets);

  double get volumeKg =>
      exercises.fold(0, (total, exercise) => total + exercise.volumeKg);

  double get topWeightKg {
    if (exercises.isEmpty) return 0;
    return exercises
        .map((exercise) => exercise.topWeightKg)
        .reduce((a, b) => a > b ? a : b);
  }

  int get exerciseCount => exercises.where((e) => e.completedSets > 0).length;

  WorkoutSession copyWith({
    List<ExerciseLog>? exercises,
    DateTime? completedAt,
    DateTime? restEndsAt,
    String? notes,
    bool clearRest = false,
  }) {
    return WorkoutSession(
      id: id,
      programId: programId,
      programName: programName,
      dayId: dayId,
      dayName: dayName,
      startedAt: startedAt,
      exercises: exercises ?? this.exercises,
      completedAt: completedAt ?? this.completedAt,
      notes: notes ?? this.notes,
      restEndsAt: clearRest ? null : (restEndsAt ?? this.restEndsAt),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'programId': programId,
        'programName': programName,
        'dayId': dayId,
        'dayName': dayName,
        'startedAt': startedAt.toIso8601String(),
        'completedAt': completedAt?.toIso8601String(),
        'exercises': exercises.map((exercise) => exercise.toJson()).toList(),
        'notes': notes,
        'restEndsAt': restEndsAt?.toIso8601String(),
      };

  factory WorkoutSession.fromJson(Map<String, dynamic> json) {
    return WorkoutSession(
      id: json['id'] as String? ?? '',
      programId: json['programId'] as String? ?? '',
      programName: json['programName'] as String? ?? 'Workout',
      dayId: json['dayId'] as String? ?? '',
      dayName: json['dayName'] as String? ?? 'Session',
      startedAt: DateTime.tryParse(json['startedAt'] as String? ?? '') ??
          DateTime.now(),
      completedAt: DateTime.tryParse(json['completedAt'] as String? ?? ''),
      exercises: (json['exercises'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ExerciseLog.fromJson)
          .toList(),
      notes: json['notes'] as String?,
      restEndsAt: DateTime.tryParse(json['restEndsAt'] as String? ?? ''),
    );
  }
}

class PersonalRecord {
  const PersonalRecord({
    required this.exerciseId,
    required this.exerciseName,
    required this.weightKg,
    required this.reps,
    required this.date,
  });

  final String exerciseId;
  final String exerciseName;
  final double weightKg;
  final int reps;
  final DateTime date;

  double get estimatedOneRepMax => weightKg * (1 + reps / 30);
}

/// Epley estimate for a single set.
double estimateOneRepMax(double weightKg, int reps) {
  if (reps <= 0 || weightKg <= 0) return 0;
  if (reps == 1) return weightKg;
  return weightKg * (1 + reps / 30);
}

/// Best estimated 1RM across completed sets and saved sessions.
PersonalRecord? findPersonalRecord(
  String exerciseId,
  Iterable<WorkoutSession> sessions,
) {
  PersonalRecord? best;
  for (final session in sessions) {
    for (final exercise in session.exercises) {
      if (exercise.exerciseId != exerciseId) continue;
      for (final set in exercise.finishedSets) {
        final estimate = estimateOneRepMax(set.weightKg, set.reps);
        if (estimate <= 0) continue;
        final candidate = PersonalRecord(
          exerciseId: exerciseId,
          exerciseName: exercise.name,
          weightKg: set.weightKg,
          reps: set.reps,
          date: session.completedAt ?? session.startedAt,
        );
        if (best == null ||
            candidate.estimatedOneRepMax > best.estimatedOneRepMax) {
          best = candidate;
        }
      }
    }
  }
  return best;
}

/// Highest completed weight for a given exercise, most recent first.
double? lastWorkingWeight(
  String exerciseId,
  Iterable<WorkoutSession> completedSessions,
) {
  final sorted = completedSessions.toList()
    ..sort((a, b) {
      final aDate = a.completedAt ?? a.startedAt;
      final bDate = b.completedAt ?? b.startedAt;
      return bDate.compareTo(aDate);
    });
  for (final session in sorted) {
    for (final exercise in session.exercises) {
      if (exercise.exerciseId == exerciseId && exercise.topWeightKg > 0) {
        return exercise.topWeightKg;
      }
    }
  }
  return null;
}
