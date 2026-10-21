import '../../features/nutrition/models/food_item.dart';
import '../../features/nutrition/models/nutrition_day.dart';
import '../../features/profile/models/user_profile.dart';
import '../../features/progress/models/measurement.dart';
import '../../features/progress/models/progress_photo.dart';
import '../../features/training/models/workout_session.dart';
import '../utils/date_x.dart';
import 'app_settings.dart';

class AppData {
  AppData({
    this.profile,
    this.settings = const AppSettings(),
    List<WorkoutSession>? sessions,
    Map<String, NutritionDay>? nutrition,
    List<MeasurementEntry>? measurements,
    List<ProgressPhoto>? photos,
    List<FoodItem>? customFoods,
    this.activeWorkout,
    this.selectedProgramId,
  })  : sessions = sessions ?? <WorkoutSession>[],
        nutrition = nutrition ?? <String, NutritionDay>{},
        measurements = measurements ?? <MeasurementEntry>[],
        photos = photos ?? <ProgressPhoto>[],
        customFoods = customFoods ?? <FoodItem>[];

  factory AppData.fresh() => AppData();

  UserProfile? profile;
  AppSettings settings;
  List<WorkoutSession> sessions;
  Map<String, NutritionDay> nutrition;
  List<MeasurementEntry> measurements;
  List<ProgressPhoto> photos;
  List<FoodItem> customFoods;
  WorkoutSession? activeWorkout;
  String? selectedProgramId;

  /// New top-level object so Riverpod listeners are notified after mutations.
  AppData copy() {
    return AppData(
      profile: profile,
      settings: settings,
      sessions: List<WorkoutSession>.from(sessions),
      nutrition: Map<String, NutritionDay>.from(nutrition),
      measurements: List<MeasurementEntry>.from(measurements),
      photos: List<ProgressPhoto>.from(photos),
      customFoods: List<FoodItem>.from(customFoods),
      activeWorkout: activeWorkout,
      selectedProgramId: selectedProgramId,
    );
  }

  bool get hasProfile => profile != null;

  List<WorkoutSession> get completedSessions {
    final result =
        sessions.where((session) => session.completedAt != null).toList();
    result.sort((a, b) {
      final aDate = a.completedAt ?? a.startedAt;
      final bDate = b.completedAt ?? b.startedAt;
      return bDate.compareTo(aDate);
    });
    return result;
  }

  List<WorkoutSession> get recentSessions =>
      completedSessions.take(20).toList();

  List<MeasurementEntry> get sortedMeasurements {
    final result = [...measurements]..sort((a, b) => b.date.compareTo(a.date));
    return result;
  }

  MeasurementEntry? get latestMeasurement =>
      sortedMeasurements.isEmpty ? null : sortedMeasurements.first;

  double get currentWeightKg {
    for (final entry in sortedMeasurements) {
      if (entry.weightKg != null) return entry.weightKg!;
    }
    return profile?.weightKg ?? 0;
  }

  double get startingWeightKg {
    final sorted = [...measurements.where((e) => e.weightKg != null)]
      ..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.isNotEmpty) return sorted.first.weightKg!;
    return profile?.weightKg ?? 0;
  }

  double get weightChangeKg => currentWeightKg - startingWeightKg;

  NutritionDay nutritionFor(DateTime date) {
    final key = dateKey(date);
    return nutrition[key] ?? NutritionDay(date: key);
  }

  NutritionDay nutritionForToday() => nutritionFor(DateTime.now());

  List<DateTime> get workoutDates => completedSessions
      .map((session) => session.completedAt ?? session.startedAt)
      .toList();

  int get weekStreak => weekStreakFromDates(workoutDates);

  int weekStreakFromDates(List<DateTime> dates) {
    if (dates.isEmpty) return 0;
    final activeWeeks = dates.map((date) => dateKey(startOfWeek(date))).toSet();
    var cursor = startOfWeek(DateTime.now());
    if (!activeWeeks.contains(dateKey(cursor))) {
      cursor = addDays(cursor, -7);
    }
    var streak = 0;
    while (activeWeeks.contains(dateKey(cursor))) {
      streak++;
      cursor = addDays(cursor, -7);
    }
    return streak;
  }

  PersonalRecord? prFor(String exerciseId) =>
      findPersonalRecord(exerciseId, completedSessions);

  List<PersonalRecord> get topPersonalRecords {
    final ids = <String>{};
    for (final session in sessions) {
      for (final exercise in session.exercises) {
        if (exercise.completedSets > 0) ids.add(exercise.exerciseId);
      }
    }
    final records = <PersonalRecord>[];
    for (final id in ids) {
      final record = prFor(id);
      if (record != null) records.add(record);
    }
    records.sort(
      (a, b) => b.estimatedOneRepMax.compareTo(a.estimatedOneRepMax),
    );
    return records;
  }

  int get totalCompletedWorkouts => completedSessions.length;

  double get totalVolumeKg =>
      completedSessions.fold(0.0, (total, session) => total + session.volumeKg);

  /// Total volume per week day for the last seven days, oldest first.
  List<double> weeklyVolumeKg({DateTime? now}) {
    final days = lastNDays(7, end: now);
    return days.map((day) {
      final daySessions = completedSessions.where((session) {
        final date = session.completedAt ?? session.startedAt;
        return sameDay(date, day);
      });
      return daySessions.fold(
          0.0, (total, session) => total + session.volumeKg);
    }).toList();
  }

  List<double> weightTrend({int days = 30, DateTime? now}) {
    final anchor = dayStart(now ?? DateTime.now());
    final sorted = [...measurements.where((entry) => entry.weightKg != null)]
      ..sort((a, b) => a.date.compareTo(b.date));
    if (sorted.isEmpty) return const [];
    final points = <({DateTime date, double value})>[];
    for (final entry in sorted) {
      final date = dayStart(entry.date);
      if (date.isBefore(addDays(anchor, -(days - 1)))) continue;
      points.add((date: date, value: entry.weightKg!));
    }
    return points.map((point) => point.value).toList();
  }

  String? get activeProgramId => selectedProgramId;

  Map<String, dynamic> toJson() => {
        'schemaVersion': 1,
        'profile': profile?.toJson(),
        'settings': settings.toJson(),
        'sessions': sessions.map((session) => session.toJson()).toList(),
        'nutrition':
            nutrition.map((key, value) => MapEntry(key, value.toJson())),
        'measurements': measurements.map((entry) => entry.toJson()).toList(),
        'photos': photos.map((photo) => photo.toJson()).toList(),
        'customFoods': customFoods.map((food) => food.toJson()).toList(),
        'activeWorkout': activeWorkout?.toJson(),
        'selectedProgramId': selectedProgramId,
      };

  factory AppData.fromJson(Map<String, dynamic> json) {
    final rawProfile = json['profile'];
    final rawSettings = json['settings'];
    final rawNutrition = json['nutrition'];
    final rawActive = json['activeWorkout'];
    return AppData(
      profile: rawProfile is Map<String, dynamic>
          ? UserProfile.fromJson(rawProfile)
          : null,
      settings: rawSettings is Map<String, dynamic>
          ? AppSettings.fromJson(rawSettings)
          : const AppSettings(),
      sessions: (json['sessions'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(WorkoutSession.fromJson)
          .toList(),
      nutrition: rawNutrition is Map<String, dynamic>
          ? rawNutrition.map(
              (key, value) => MapEntry(
                key,
                NutritionDay.fromJson(value as Map<String, dynamic>),
              ),
            )
          : <String, NutritionDay>{},
      measurements: (json['measurements'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MeasurementEntry.fromJson)
          .toList(),
      photos: (json['photos'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(ProgressPhoto.fromJson)
          .toList(),
      customFoods: (json['customFoods'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FoodItem.fromJson)
          .toList(),
      activeWorkout: rawActive is Map<String, dynamic>
          ? WorkoutSession.fromJson(rawActive)
          : null,
      selectedProgramId: json['selectedProgramId'] as String?,
    );
  }
}
