import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/nutrition/models/nutrition_day.dart';
import '../../features/profile/models/user_profile.dart';
import '../../features/training/data/program_catalog.dart';
import '../../features/training/models/program.dart';
import '../../features/training/models/workout_session.dart';
import '../models/app_data.dart';
import '../utils/bmi.dart';
import '../utils/date_x.dart';
import '../utils/nutrition_math.dart';
import 'app_controller.dart';

final appDataProvider = Provider<AppData?>((ref) {
  return ref.watch(appControllerProvider).valueOrNull;
});

final profileProvider = Provider<UserProfile?>((ref) {
  return ref.watch(appDataProvider)?.profile;
});

final selectedProgramProvider = Provider<TrainingProgram?>((ref) {
  final data = ref.watch(appDataProvider);
  if (data == null) return null;
  final id = data.selectedProgramId;
  if (id != null) {
    final program = programById(id);
    if (program != null) return program;
  }
  final goal = data.profile?.goal;
  if (goal != null) return programById(goal.recommendedProgramId);
  return programCatalog.first;
});

final macroTargetsProvider = Provider<MacroTargets?>((ref) {
  final profile = ref.watch(profileProvider);
  if (profile == null) return null;
  return calculateMacroTargets(profile);
});

final nutritionDayProvider = Provider.family<NutritionDay, String>((
  ref,
  dateKeyValue,
) {
  final data = ref.watch(appDataProvider);
  if (data == null) return NutritionDay(date: dateKeyValue);
  return data.nutrition[dateKeyValue] ?? NutritionDay(date: dateKeyValue);
});

final todayKeyProvider = Provider<String>((ref) => dateKey(DateTime.now()));

final todayNutritionProvider = Provider<NutritionDay>((ref) {
  return ref.watch(nutritionDayProvider(ref.watch(todayKeyProvider)));
});

final bmiProvider = Provider<BmiResult?>((ref) {
  final profile = ref.watch(profileProvider);
  final data = ref.watch(appDataProvider);
  if (profile == null) return null;
  final weight = data?.currentWeightKg ?? profile.weightKg;
  return calculateBmi(weightKg: weight, heightCm: profile.heightCm);
});

final activeWorkoutProvider = Provider<WorkoutSession?>((ref) {
  return ref.watch(appDataProvider)?.activeWorkout;
});

final latestWeightProvider = Provider<double?>((ref) {
  return ref.watch(appDataProvider)?.currentWeightKg;
});
