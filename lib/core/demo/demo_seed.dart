import '../../features/nutrition/data/food_database.dart';
import '../../features/nutrition/models/nutrition_day.dart';
import '../../features/profile/models/user_profile.dart';
import '../../features/progress/models/measurement.dart';
import '../../features/training/data/exercise_seed.dart';
import '../../features/training/data/program_catalog.dart';
import '../../features/training/models/workout_session.dart';
import '../utils/date_x.dart';
import '../utils/ids.dart';

class DemoSeed {
  const DemoSeed({
    required this.sessions,
    required this.measurements,
    required this.nutrition,
  });

  final List<WorkoutSession> sessions;
  final List<MeasurementEntry> measurements;
  final Map<String, NutritionDay> nutrition;
}

DemoSeed buildDemoSeed(UserProfile profile) {
  final now = DateTime.now();
  final program = programById('ppl_aesthetics') ?? programCatalog.first;
  final dayIds = ['push_a', 'pull_a', 'legs_a'];
  final exerciseNames = {
    for (final exercise in exerciseSeed) exercise.id: exercise.name,
  };
  final baseWeights = <String, double>{
    'incline_dumbbell_press': 28,
    'machine_bench_press': 70,
    'side_lateral_raise': 10,
    'cable_crossover': 15,
    'triceps_pushdown_rope_attachment': 25,
    'cable_rope_overhead_triceps_extension': 20,
    'pullups': 0,
    'seated_cable_rows': 65,
    'face_pull': 20,
    'incline_dumbbell_curl': 14,
    'alternate_hammer_curl': 16,
    'barbell_squat': 95,
    'romanian_deadlift': 80,
    'leg_press': 160,
    'lying_leg_curls': 40,
    'standing_calf_raises': 70,
    'hanging_leg_raise': 0,
  };

  final sessions = <WorkoutSession>[];
  for (var week = 4; week >= 0; week--) {
    for (var i = 0; i < dayIds.length; i++) {
      final day = program.dayById(dayIds[i]);
      if (day == null) continue;
      final date = DateTime(
        now.year,
        now.month,
        now.day - (week * 7) + (i * 2) - 1,
        18,
        10,
      );
      if (date.isAfter(now)) continue;
      final progress = (4 - week) * 0.035;
      final logs = <ExerciseLog>[];
      for (final prescription in day.exercises) {
        final base = baseWeights[prescription.exerciseId] ?? 20;
        final workingWeight = base == 0
            ? 0.0
            : (base * (1 + progress) / 2.5).roundToDouble() * 2.5;
        final reps = _targetReps(prescription.reps);
        final setCount = prescription.sets.clamp(2, 4);
        final sets = <SetLog>[];
        for (var s = 0; s < setCount; s++) {
          sets.add(
            SetLog(
              weightKg: workingWeight,
              reps: reps - (s > 1 ? 1 : 0),
              completed: true,
            ),
          );
        }
        logs.add(
          ExerciseLog(
            exerciseId: prescription.exerciseId,
            name: exerciseNames[prescription.exerciseId] ?? 'Exercise',
            targetSets: prescription.sets,
            repsLabel: prescription.reps,
            restSeconds: prescription.restSeconds,
            sets: sets,
            completed: true,
            tempo: prescription.tempo,
          ),
        );
      }
      sessions.add(
        WorkoutSession(
          id: newId('demo'),
          programId: program.id,
          programName: program.name,
          dayId: day.id,
          dayName: day.name,
          startedAt: date,
          completedAt: date.add(const Duration(minutes: 64)),
          exercises: logs,
        ),
      );
    }
  }

  final measurements = <MeasurementEntry>[];
  final weeklyShift = switch (profile.goal) {
    Goal.fatLoss => -0.28,
    Goal.aesthetics => -0.12,
    Goal.muscle => 0.16,
    Goal.strength => 0.1,
  };
  for (var week = 5; week >= 0; week--) {
    final date = DateTime(now.year, now.month, now.day - (week * 7), 7, 20);
    final weight = profile.weightKg - (weeklyShift * (5 - week));
    measurements.add(
      MeasurementEntry(
        id: newId('demo_m'),
        date: date,
        weightKg: double.parse(weight.toStringAsFixed(1)),
        waistCm: 84 - ((5 - week) * 0.15),
        chestCm: 104 + ((5 - week) * 0.08),
        bicepLeftCm: 37.5 + ((5 - week) * 0.04),
        bicepRightCm: 37.8 + ((5 - week) * 0.04),
      ),
    );
  }

  final nutrition = <String, NutritionDay>{};
  final todayKey = dateKey(now);
  final today = NutritionDay(
    date: todayKey,
    waterMl: 2000,
    entries: [
      _mealEntry('oats', 80, MealType.breakfast, now, 1),
      _mealEntry('whey', 30, MealType.breakfast, now, 2),
      _mealEntry('banana', 118, MealType.breakfast, now, 3),
      _mealEntry('chicken_breast', 180, MealType.lunch, now, 4),
      _mealEntry('white_rice', 220, MealType.lunch, now, 5),
      _mealEntry('broccoli', 120, MealType.lunch, now, 6),
      _mealEntry('greek_yogurt', 170, MealType.snack, now, 7),
      _mealEntry('almonds', 25, MealType.snack, now, 8),
      _mealEntry('salmon', 160, MealType.dinner, now, 9),
      _mealEntry('basmati_rice', 180, MealType.dinner, now, 10),
    ],
  );
  nutrition[todayKey] = today;

  return DemoSeed(
    sessions: sessions,
    measurements: measurements,
    nutrition: nutrition,
  );
}

FoodLogEntry _mealEntry(
  String foodId,
  double grams,
  MealType meal,
  DateTime now,
  int minutesAgo,
) {
  final food = builtInFoodById(foodId)!;
  return FoodLogEntry(
    id: newId('demo_f'),
    foodId: food.id,
    name: food.name,
    meal: meal,
    grams: grams,
    calories: food.caloriesFor(grams),
    protein: food.proteinFor(grams),
    carbs: food.carbsFor(grams),
    fat: food.fatFor(grams),
    loggedAt: now.subtract(Duration(minutes: minutesAgo * 30)),
    servingDescription: '${grams.round()} g',
  );
}

int _targetReps(String label) {
  final match = RegExp(r'\d+').firstMatch(label);
  final value = int.tryParse(match?.group(0) ?? '') ?? 8;
  return value.clamp(1, 30);
}
