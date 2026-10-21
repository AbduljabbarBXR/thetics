import 'package:flutter_test/flutter_test.dart';
import 'package:thetics/core/models/app_data.dart';
import 'package:thetics/core/utils/date_x.dart';
import 'package:thetics/features/profile/models/user_profile.dart';
import 'package:thetics/features/progress/models/measurement.dart';
import 'package:thetics/features/training/models/workout_session.dart';

UserProfile _profile() => UserProfile(
      name: 'Test Lifter',
      sex: Sex.male,
      age: 30,
      heightCm: 180,
      weightKg: 80,
      goal: Goal.aesthetics,
      experience: Experience.intermediate,
      trainingDays: 4,
      activity: ActivityLevel.moderate,
      units: UnitSystem.metric,
      createdAt: DateTime(2026, 1, 1),
    );

MeasurementEntry _measurement({
  required String id,
  required DateTime date,
  double? weight,
  double? waist,
}) {
  return MeasurementEntry(
    id: id,
    date: date,
    weightKg: weight,
    waistCm: waist,
  );
}

ExerciseLog _log(List<SetLog> sets) {
  return ExerciseLog(
    exerciseId: 'barbell_bench_press_medium_grip',
    name: 'Barbell Bench Press',
    targetSets: sets.length,
    repsLabel: '5',
    restSeconds: 120,
    sets: sets,
  );
}

WorkoutSession _session({
  required String id,
  required DateTime completedAt,
  required List<SetLog> sets,
}) {
  return WorkoutSession(
    id: id,
    programId: 'foundation_5x5',
    programName: 'Foundation 5×5',
    dayId: 'a',
    dayName: 'Full body A',
    startedAt: completedAt.subtract(const Duration(hours: 1)),
    completedAt: completedAt,
    exercises: [_log(sets)],
  );
}

void main() {
  group('body-weight aggregates', () {
    test('current weight uses the newest weigh-in and tracks change', () {
      final now = DateTime.now();
      final data = AppData(
        profile: _profile(),
        measurements: [
          _measurement(
            id: 'old',
            date: now.subtract(const Duration(days: 14)),
            weight: 82,
          ),
          _measurement(
            id: 'new',
            date: now.subtract(const Duration(days: 1)),
            weight: 79.5,
            waist: 82,
          ),
        ],
      );

      expect(data.currentWeightKg, 79.5);
      expect(data.startingWeightKg, 82);
      expect(data.weightChangeKg, closeTo(-2.5, 0.001));
      expect(data.latestMeasurement?.id, 'new');
      expect(data.latestMeasurement?.waistCm, 82);
    });

    test('falls back to the profile weight when there are no weigh-ins', () {
      final data = AppData(profile: _profile());
      expect(data.currentWeightKg, 80);
      expect(data.latestMeasurement, isNull);
    });

    test('weight trend stays inside the requested window and sorts ascending',
        () {
      final data = AppData(
        measurements: [
          _measurement(
            id: 'b',
            date: DateTime.now().subtract(const Duration(days: 2)),
            weight: 79,
          ),
          _measurement(
            id: 'a',
            date: DateTime.now().subtract(const Duration(days: 10)),
            weight: 81,
          ),
          _measurement(
            id: 'old',
            date: DateTime.now().subtract(const Duration(days: 80)),
            weight: 90,
          ),
        ],
      );

      expect(data.weightTrend(days: 30), [81, 79]);
      expect(data.weightTrend(days: 120), [90, 81, 79]);
    });
  });

  group('training aggregates', () {
    test('counts only completed sessions and sums finished volume', () {
      final now = DateTime.now();
      final data = AppData(
        sessions: [
          _session(
            id: 'done',
            completedAt: now,
            sets: const [
              SetLog(weightKg: 100, reps: 5, completed: true),
              SetLog(weightKg: 100, reps: 5, completed: true),
              SetLog(weightKg: 100, reps: 5, completed: false),
            ],
          ),
          WorkoutSession(
            id: 'active',
            programId: 'foundation_5x5',
            programName: 'Foundation 5×5',
            dayId: 'a',
            dayName: 'Full body A',
            startedAt: now,
            exercises: const [],
          ),
        ],
      );

      expect(data.completedSessions, hasLength(1));
      expect(data.totalCompletedWorkouts, 1);
      expect(data.totalVolumeKg, 1000);
      expect(data.weeklyVolumeKg(), hasLength(7));
      expect(data.weeklyVolumeKg().last, 1000);
    });

    test('detects the best estimated one-rep max', () {
      final now = DateTime.now();
      final data = AppData(
        sessions: [
          _session(
            id: 'one',
            completedAt: now,
            sets: const [
              SetLog(weightKg: 100, reps: 5, completed: true),
            ],
          ),
          _session(
            id: 'two',
            completedAt: now.subtract(const Duration(days: 7)),
            sets: const [
              SetLog(weightKg: 95, reps: 8, completed: true),
            ],
          ),
        ],
      );

      final pr = data.prFor('barbell_bench_press_medium_grip');
      expect(pr, isNotNull);
      expect(pr!.weightKg, 95);
      expect(pr.reps, 8);
      expect(pr.estimatedOneRepMax, closeTo(120.33, 0.01));
      expect(data.topPersonalRecords, hasLength(1));
    });

    test('week streak counts consecutive active weeks', () {
      final thisWeek = startOfWeek(DateTime.now());
      final data = AppData(
        sessions: [
          _session(
            id: 'this',
            completedAt: thisWeek.add(const Duration(days: 1)),
            sets: const [SetLog(weightKg: 100, reps: 5, completed: true)],
          ),
          _session(
            id: 'last',
            completedAt: thisWeek.subtract(const Duration(days: 5)),
            sets: const [SetLog(weightKg: 100, reps: 5, completed: true)],
          ),
        ],
      );
      expect(data.weekStreak, 2);
    });
  });

  group('persistence', () {
    test('round-trips the full data model through JSON', () {
      final now = DateTime.now();
      final original = AppData(
        profile: _profile(),
        measurements: [
          _measurement(id: 'm1', date: now, weight: 79.5, waist: 82),
        ],
        sessions: [
          _session(
            id: 's1',
            completedAt: now,
            sets: const [SetLog(weightKg: 100, reps: 5, completed: true)],
          ),
        ],
      );
      original.selectedProgramId = 'foundation_5x5';

      final restored = AppData.fromJson(original.toJson());

      expect(restored.profile?.name, 'Test Lifter');
      expect(restored.profile?.goal, Goal.aesthetics);
      expect(restored.measurements, hasLength(1));
      expect(restored.sessions, hasLength(1));
      expect(restored.selectedProgramId, 'foundation_5x5');
      expect(restored.totalVolumeKg, 500);
      expect(restored.currentWeightKg, 79.5);
    });
  });
}
