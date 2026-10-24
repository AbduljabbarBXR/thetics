import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/nutrition/models/food_item.dart';
import '../../features/nutrition/models/nutrition_day.dart';
import '../../features/profile/models/user_profile.dart';
import '../../features/progress/models/measurement.dart';
import '../../features/progress/models/progress_photo.dart';
import '../../features/training/data/exercise_seed.dart';
import '../../features/training/models/program.dart';
import '../../features/training/models/workout_session.dart';
import '../demo/demo_seed.dart';
import '../models/app_data.dart';
import '../models/app_settings.dart';
import '../storage/local_store.dart';
import '../utils/date_x.dart';
import '../utils/ids.dart';

final appControllerProvider = AsyncNotifierProvider<AppController, AppData>(
  AppController.new,
);

class AppController extends AsyncNotifier<AppData> {
  Future<void> _writeQueue = Future<void>.value();

  AppData get _data => state.valueOrNull ?? AppData.fresh();

  @override
  Future<AppData> build() async {
    final store = ref.watch(localStoreProvider);
    String? raw;
    try {
      raw = await store.readRaw();
    } catch (error, stackTrace) {
      debugPrint('Thetics: could not read saved data: $error');
      debugPrintStack(stackTrace: stackTrace);
      return AppData.fresh();
    }
    if (raw == null || raw.isEmpty) return AppData.fresh();
    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return AppData.fromJson(decoded);
      }
    } on FormatException {
      // Corrupt local payload: start clean rather than trapping the user.
    }
    return AppData.fresh();
  }

  Future<void> _persist() {
    _writeQueue = _writeQueue.then((_) async {
      final current = state.valueOrNull;
      if (current == null) return;
      try {
        await ref
            .read(localStoreProvider)
            .writeRaw(jsonEncode(current.toJson()));
      } catch (error, stackTrace) {
        // A broken disk/database must not poison the write queue or block the
        // UI. State stays usable in memory for this session.
        debugPrint('Thetics: could not persist data: $error');
        debugPrintStack(stackTrace: stackTrace);
      }
    });
    return _writeQueue;
  }

  Future<void> _commit(AppData data) async {
    state = AsyncData(data.copy());
    await _persist();
  }

  Future<void> _mutate(void Function(AppData data) change) async {
    final data = _data;
    change(data);
    await _commit(data);
  }

  // ---------------------------------------------------------------- profile

  Future<void> completeOnboarding(
    UserProfile profile, {
    String? programId,
  }) async {
    final data = _data;
    data.profile = profile;
    data.selectedProgramId = programId ?? profile.goal.recommendedProgramId;
    if (!data.measurements.any((entry) => entry.weightKg != null)) {
      data.measurements.add(
        MeasurementEntry(
          id: newId('m'),
          date: DateTime.now(),
          weightKg: profile.weightKg,
        ),
      );
    }
    await _commit(data);
  }

  Future<void> updateProfile(UserProfile profile) async {
    await _mutate((data) => data.profile = profile);
  }

  Future<void> setUnits(UnitSystem units) async {
    final profile = _data.profile;
    if (profile == null) return;
    await updateProfile(profile.copyWith(units: units));
  }

  Future<void> setTheme(ThemeChoice theme) async {
    await _mutate(
      (data) => data.settings = data.settings.copyWith(theme: theme),
    );
  }

  Future<void> setHaptics(bool enabled) async {
    await _mutate(
      (data) => data.settings = data.settings.copyWith(haptics: enabled),
    );
  }

  Future<void> setRestAlerts(bool enabled) async {
    await _mutate(
      (data) => data.settings = data.settings.copyWith(restAlerts: enabled),
    );
  }

  Future<void> setAiFoodBeta(bool enabled) async {
    await _mutate(
      (data) => data.settings = data.settings.copyWith(aiFoodBeta: enabled),
    );
  }

  Future<void> selectProgram(String programId) async {
    await _mutate((data) => data.selectedProgramId = programId);
  }

  // -------------------------------------------------------------- nutrition

  Future<void> addFoodEntry(DateTime date, FoodLogEntry entry) async {
    final key = dateKey(date);
    final data = _data;
    final day = data.nutrition[key] ?? NutritionDay(date: key);
    final updated = day.copyWith(entries: [...day.entries, entry]);
    data.nutrition[key] = updated;
    await _commit(data);
  }

  Future<void> removeFoodEntry(DateTime date, String entryId) async {
    final key = dateKey(date);
    final data = _data;
    final day = data.nutrition[key];
    if (day == null) return;
    final updated = day.copyWith(
      entries: day.entries.where((entry) => entry.id != entryId).toList(),
    );
    data.nutrition[key] = updated;
    await _commit(data);
  }

  Future<void> setWater(DateTime date, int millilitres) async {
    final key = dateKey(date);
    final data = _data;
    final day = data.nutrition[key] ?? NutritionDay(date: key);
    data.nutrition[key] = day.copyWith(waterMl: millilitres.clamp(0, 10000));
    await _commit(data);
  }

  Future<void> addCustomFood(FoodItem food) async {
    await _mutate((data) {
      final index = data.customFoods.indexWhere((item) => item.id == food.id);
      if (index >= 0) {
        data.customFoods[index] = food;
      } else {
        data.customFoods.add(food);
      }
    });
  }

  Future<void> deleteCustomFood(String foodId) async {
    await _mutate(
      (data) => data.customFoods.removeWhere((food) => food.id == foodId),
    );
  }

  // ---------------------------------------------------------------- progress

  Future<void> saveMeasurement(MeasurementEntry entry) async {
    final data = _data;
    final entryDay = dateKey(entry.date);
    final index = data.measurements.indexWhere(
      (existing) => dateKey(existing.date) == entryDay,
    );
    if (index >= 0) {
      final existing = data.measurements[index];
      data.measurements[index] = MeasurementEntry(
        id: existing.id,
        date: entry.date,
        weightKg: entry.weightKg ?? existing.weightKg,
        bodyFatPct: entry.bodyFatPct ?? existing.bodyFatPct,
        neckCm: entry.neckCm ?? existing.neckCm,
        shouldersCm: entry.shouldersCm ?? existing.shouldersCm,
        chestCm: entry.chestCm ?? existing.chestCm,
        waistCm: entry.waistCm ?? existing.waistCm,
        hipsCm: entry.hipsCm ?? existing.hipsCm,
        bicepLeftCm: entry.bicepLeftCm ?? existing.bicepLeftCm,
        bicepRightCm: entry.bicepRightCm ?? existing.bicepRightCm,
        thighLeftCm: entry.thighLeftCm ?? existing.thighLeftCm,
        thighRightCm: entry.thighRightCm ?? existing.thighRightCm,
        calfLeftCm: entry.calfLeftCm ?? existing.calfLeftCm,
        calfRightCm: entry.calfRightCm ?? existing.calfRightCm,
        note: entry.note ?? existing.note,
      );
    } else {
      data.measurements.add(entry);
    }
    _syncProfileWeight(data);
    await _commit(data);
  }

  Future<void> logBodyWeight(double weightKg, {DateTime? date}) async {
    await saveMeasurement(
      MeasurementEntry(
        id: newId('m'),
        date: date ?? DateTime.now(),
        weightKg: weightKg,
      ),
    );
  }

  Future<void> deleteMeasurement(String id) async {
    final data = _data;
    data.measurements.removeWhere((entry) => entry.id == id);
    _syncProfileWeight(data);
    await _commit(data);
  }

  void _syncProfileWeight(AppData data) {
    final profile = data.profile;
    if (profile == null) return;
    final weighted = data.measurements.where((m) => m.weightKg != null).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    if (weighted.isEmpty) return;
    data.profile = profile.copyWith(weightKg: weighted.first.weightKg);
  }

  Future<void> addProgressPhoto(ProgressPhoto photo) async {
    await _mutate((data) => data.photos.add(photo));
  }

  Future<void> deleteProgressPhoto(String id) async {
    await _mutate((data) => data.photos.removeWhere((photo) => photo.id == id));
  }

  // ---------------------------------------------------------------- training

  Future<bool> startWorkout(TrainingProgram program, ProgramDay day) async {
    final data = _data;
    if (data.activeWorkout != null) return false;
    final exercisesById = {
      for (final exercise in exerciseSeed) exercise.id: exercise,
    };
    final logs = <ExerciseLog>[];
    for (final prescription in day.exercises) {
      final exercise = exercisesById[prescription.exerciseId];
      if (exercise == null) continue;
      final previous = lastWorkingWeight(
        prescription.exerciseId,
        data.completedSessions,
      );
      final targetReps = _targetReps(prescription.reps);
      logs.add(
        ExerciseLog(
          exerciseId: exercise.id,
          name: exercise.name,
          targetSets: prescription.sets,
          repsLabel: prescription.reps,
          restSeconds: prescription.restSeconds,
          tempo: prescription.tempo,
          sets: List<SetLog>.generate(
            prescription.sets,
            (_) => SetLog(
              weightKg: previous ?? 0,
              reps: targetReps,
              completed: false,
            ),
          ),
        ),
      );
    }
    data.activeWorkout = WorkoutSession(
      id: newId('w'),
      programId: program.id,
      programName: program.name,
      dayId: day.id,
      dayName: day.name,
      startedAt: DateTime.now(),
      exercises: logs,
    );
    data.selectedProgramId = program.id;
    await _commit(data);
    return true;
  }

  Future<void> updateActiveWorkout(WorkoutSession workout) async {
    final data = _data;
    if (data.activeWorkout == null) return;
    data.activeWorkout = workout;
    await _commit(data);
  }

  Future<({WorkoutSession workout, List<PersonalRecord> prs})?>
      finishActiveWorkout({String? notes}) async {
    final data = _data;
    final active = data.activeWorkout;
    if (active == null) return null;
    final finished = active.copyWith(
      completedAt: DateTime.now(),
      clearRest: true,
      notes: notes ?? active.notes,
    );

    final previousBests = <String, double>{};
    for (final session in data.completedSessions) {
      for (final exercise in session.exercises) {
        for (final set in exercise.finishedSets) {
          final estimate = estimateOneRepMax(set.weightKg, set.reps);
          final current = previousBests[exercise.exerciseId] ?? 0;
          if (estimate > current) {
            previousBests[exercise.exerciseId] = estimate;
          }
        }
      }
    }

    final prs = <PersonalRecord>[];
    for (final exercise in finished.exercises) {
      SetLog? bestSet;
      var bestEstimate = 0.0;
      for (final set in exercise.finishedSets) {
        final estimate = estimateOneRepMax(set.weightKg, set.reps);
        if (estimate > bestEstimate) {
          bestEstimate = estimate;
          bestSet = set;
        }
      }
      if (bestSet == null || bestEstimate <= 0) continue;
      if (bestEstimate > (previousBests[exercise.exerciseId] ?? 0) + 0.01) {
        prs.add(
          PersonalRecord(
            exerciseId: exercise.exerciseId,
            exerciseName: exercise.name,
            weightKg: bestSet.weightKg,
            reps: bestSet.reps,
            date: finished.completedAt!,
          ),
        );
      }
    }

    data.sessions.add(finished);
    data.activeWorkout = null;
    await _commit(data);
    return (workout: finished, prs: prs);
  }

  Future<void> discardActiveWorkout() async {
    await _mutate((data) => data.activeWorkout = null);
  }

  // ------------------------------------------------------------------ data

  Future<bool> loadDemoData() async {
    final data = _data;
    final profile = data.profile;
    if (profile == null || data.sessions.isNotEmpty) return false;
    final seed = buildDemoSeed(profile);
    data.sessions.addAll(seed.sessions);
    final existingDays = data.measurements.map((m) => dateKey(m.date)).toSet();
    data.measurements.addAll(
      seed.measurements.where((m) => !existingDays.contains(dateKey(m.date))),
    );
    final todayKey = dateKey(DateTime.now());
    if (data.nutrition[todayKey]?.entries.isEmpty ?? true) {
      data.nutrition[todayKey] = seed.nutrition[todayKey]!;
    }
    _syncProfileWeight(data);
    await _commit(data);
    return true;
  }

  Future<void> resetAll() async {
    await ref.read(localStoreProvider).clear();
    state = AsyncData(AppData.fresh());
  }

  String exportJson() {
    return const JsonEncoder.withIndent('  ').convert(_data.toJson());
  }

  Future<void> importJson(String raw) async {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('The backup is not a valid Thetics file.');
    }
    final imported = AppData.fromJson(decoded);
    if (imported.profile == null) {
      throw const FormatException('The backup does not contain a profile.');
    }
    state = AsyncData(imported);
    await _persist();
  }

  int _targetReps(String label) {
    final match = RegExp(r'\d+').firstMatch(label);
    final value = int.tryParse(match?.group(0) ?? '') ?? 8;
    return value.clamp(1, 30);
  }
}
