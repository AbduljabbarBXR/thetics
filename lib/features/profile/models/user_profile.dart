enum Sex { male, female }

enum Goal { aesthetics, muscle, fatLoss, strength }

enum Experience { beginner, intermediate, advanced }

enum ActivityLevel { sedentary, light, moderate, high, veryHigh }

enum UnitSystem { metric, imperial }

extension SexX on Sex {
  String get label => this == Sex.male ? 'Male' : 'Female';
}

extension GoalX on Goal {
  String get label => switch (this) {
        Goal.aesthetics => 'Aesthetics',
        Goal.muscle => 'Muscle gain',
        Goal.fatLoss => 'Fat loss',
        Goal.strength => 'Strength',
      };

  String get shortLabel => switch (this) {
        Goal.aesthetics => 'Look better',
        Goal.muscle => 'Build mass',
        Goal.fatLoss => 'Get lean',
        Goal.strength => 'Get stronger',
      };

  String get description => switch (this) {
        Goal.aesthetics =>
          'Build a balanced, V-taper physique while staying lean.',
        Goal.muscle => 'Maximise natural muscle with a controlled surplus.',
        Goal.fatLoss => 'Drop body fat while holding on to hard-earned muscle.',
        Goal.strength => 'Prioritise heavy compounds and measurable strength.',
      };

  String get recommendedProgramId => switch (this) {
        Goal.aesthetics => 'ppl_aesthetics',
        Goal.muscle => 'ppl_aesthetics',
        Goal.fatLoss => 'upper_lower_recomp',
        Goal.strength => 'foundation_5x5',
      };
}

extension ExperienceX on Experience {
  String get label => switch (this) {
        Experience.beginner => 'Beginner',
        Experience.intermediate => 'Intermediate',
        Experience.advanced => 'Advanced',
      };

  String get description => switch (this) {
        Experience.beginner => 'Under 1 year of consistent lifting',
        Experience.intermediate => '1–3 years, comfortable with the basics',
        Experience.advanced => '3+ years, know your body and your numbers',
      };
}

extension ActivityLevelX on ActivityLevel {
  String get label => switch (this) {
        ActivityLevel.sedentary => 'Sedentary',
        ActivityLevel.light => 'Lightly active',
        ActivityLevel.moderate => 'Moderately active',
        ActivityLevel.high => 'Very active',
        ActivityLevel.veryHigh => 'Athlete / physical job',
      };

  String get description => switch (this) {
        ActivityLevel.sedentary => 'Desk job, little walking',
        ActivityLevel.light => 'Light walking, 1–3 workouts a week',
        ActivityLevel.moderate => '3–5 workouts or active most days',
        ActivityLevel.high => '6–7 hard sessions or on your feet all day',
        ActivityLevel.veryHigh => 'Two-a-days, labour or endurance training',
      };

  double get factor => switch (this) {
        ActivityLevel.sedentary => 1.2,
        ActivityLevel.light => 1.375,
        ActivityLevel.moderate => 1.55,
        ActivityLevel.high => 1.725,
        ActivityLevel.veryHigh => 1.9,
      };
}

extension UnitSystemX on UnitSystem {
  String get label => this == UnitSystem.metric ? 'Metric' : 'Imperial';
  String get weightUnit => this == UnitSystem.metric ? 'kg' : 'lb';
  String get lengthUnit => this == UnitSystem.metric ? 'cm' : 'in';
}

class UserProfile {
  const UserProfile({
    required this.name,
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.goal,
    required this.experience,
    required this.trainingDays,
    required this.activity,
    required this.units,
    required this.createdAt,
    this.targetWeightKg,
    this.calorieOverride,
    this.proteinOverride,
    this.carbsOverride,
    this.fatOverride,
  });

  final String name;
  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final Goal goal;
  final Experience experience;
  final int trainingDays;
  final ActivityLevel activity;
  final UnitSystem units;
  final DateTime createdAt;
  final double? targetWeightKg;
  final int? calorieOverride;
  final int? proteinOverride;
  final int? carbsOverride;
  final int? fatOverride;

  bool get hasCustomTargets =>
      calorieOverride != null ||
      proteinOverride != null ||
      carbsOverride != null ||
      fatOverride != null;

  String get firstName {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return 'Athlete';
    return trimmed.split(RegExp(r'\s+')).first;
  }

  UserProfile copyWith({
    String? name,
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    Goal? goal,
    Experience? experience,
    int? trainingDays,
    ActivityLevel? activity,
    UnitSystem? units,
    DateTime? createdAt,
    double? targetWeightKg,
    int? calorieOverride,
    int? proteinOverride,
    int? carbsOverride,
    int? fatOverride,
    bool clearCustomTargets = false,
    bool clearTargetWeight = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      sex: sex ?? this.sex,
      age: age ?? this.age,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goal: goal ?? this.goal,
      experience: experience ?? this.experience,
      trainingDays: trainingDays ?? this.trainingDays,
      activity: activity ?? this.activity,
      units: units ?? this.units,
      createdAt: createdAt ?? this.createdAt,
      targetWeightKg:
          clearTargetWeight ? null : (targetWeightKg ?? this.targetWeightKg),
      calorieOverride:
          clearCustomTargets ? null : (calorieOverride ?? this.calorieOverride),
      proteinOverride:
          clearCustomTargets ? null : (proteinOverride ?? this.proteinOverride),
      carbsOverride:
          clearCustomTargets ? null : (carbsOverride ?? this.carbsOverride),
      fatOverride:
          clearCustomTargets ? null : (fatOverride ?? this.fatOverride),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'sex': sex.name,
        'age': age,
        'heightCm': heightCm,
        'weightKg': weightKg,
        'goal': goal.name,
        'experience': experience.name,
        'trainingDays': trainingDays,
        'activity': activity.name,
        'units': units.name,
        'createdAt': createdAt.toIso8601String(),
        'targetWeightKg': targetWeightKg,
        'calorieOverride': calorieOverride,
        'proteinOverride': proteinOverride,
        'carbsOverride': carbsOverride,
        'fatOverride': fatOverride,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
      for (final value in values) {
        if (value.name == name) return value;
      }
      return fallback;
    }

    return UserProfile(
      name: (json['name'] as String?) ?? 'Athlete',
      sex: enumByName(Sex.values, json['sex'] as String?, Sex.male),
      age: (json['age'] as num?)?.toInt() ?? 25,
      heightCm: (json['heightCm'] as num?)?.toDouble() ?? 178,
      weightKg: (json['weightKg'] as num?)?.toDouble() ?? 80,
      goal: enumByName(Goal.values, json['goal'] as String?, Goal.aesthetics),
      experience: enumByName(
        Experience.values,
        json['experience'] as String?,
        Experience.beginner,
      ),
      trainingDays: (json['trainingDays'] as num?)?.toInt() ?? 4,
      activity: enumByName(
        ActivityLevel.values,
        json['activity'] as String?,
        ActivityLevel.moderate,
      ),
      units: enumByName(
        UnitSystem.values,
        json['units'] as String?,
        UnitSystem.metric,
      ),
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
      calorieOverride: (json['calorieOverride'] as num?)?.toInt(),
      proteinOverride: (json['proteinOverride'] as num?)?.toInt(),
      carbsOverride: (json['carbsOverride'] as num?)?.toInt(),
      fatOverride: (json['fatOverride'] as num?)?.toInt(),
    );
  }
}
