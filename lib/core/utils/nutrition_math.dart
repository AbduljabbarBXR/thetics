import '../../features/profile/models/user_profile.dart';

class MacroTargets {
  const MacroTargets({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.bmr,
    required this.tdee,
    required this.isCustom,
  });

  final int calories;
  final int protein;
  final int carbs;
  final int fat;
  final double bmr;
  final double tdee;
  final bool isCustom;

  double get proteinCalories => protein * 4;
  double get carbsCalories => carbs * 4;
  double get fatCalories => fat * 9;

  double get proteinPct =>
      calories == 0 ? 0 : (proteinCalories / calories).clamp(0, 1);
  double get carbsPct =>
      calories == 0 ? 0 : (carbsCalories / calories).clamp(0, 1);
  double get fatPct => calories == 0 ? 0 : (fatCalories / calories).clamp(0, 1);

  double get maintenanceCalories => tdee;

  MacroTargets copyWith({
    int? calories,
    int? protein,
    int? carbs,
    int? fat,
    bool? isCustom,
  }) {
    return MacroTargets(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbs: carbs ?? this.carbs,
      fat: fat ?? this.fat,
      bmr: bmr,
      tdee: tdee,
      isCustom: isCustom ?? this.isCustom,
    );
  }
}

int _roundTo(int value, int step) => (value / step).round() * step;

MacroTargets calculateMacroTargets(UserProfile profile) {
  final bmr = switch (profile.sex) {
    Sex.male =>
      10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age + 5,
    Sex.female =>
      10 * profile.weightKg + 6.25 * profile.heightCm - 5 * profile.age - 161,
  };
  final tdee = bmr * profile.activity.factor;

  var adjustment = switch (profile.goal) {
    Goal.fatLoss => -0.20,
    Goal.aesthetics => -0.06,
    Goal.muscle => 0.12,
    Goal.strength => 0.08,
  };
  var targetCalories = tdee * (1 + adjustment);
  final floor = profile.sex == Sex.male ? 1500.0 : 1200.0;
  if (targetCalories < floor) targetCalories = floor;

  final proteinPerKg = switch (profile.goal) {
    Goal.fatLoss => 2.2,
    Goal.aesthetics => 2.2,
    Goal.muscle => 2.0,
    Goal.strength => 1.9,
  };
  var protein = (profile.weightKg * proteinPerKg).round();
  var fat = (targetCalories * 0.25 / 9).round();
  final minFat = (profile.weightKg * 0.6).round();
  if (fat < minFat) fat = minFat;

  var proteinCalories = protein * 4;
  var fatCalories = fat * 9;
  var carbCalories = targetCalories - proteinCalories - fatCalories;
  if (carbCalories < 50 * 4) {
    // Keep enough carbohydrate for training; trim fat slightly first.
    fat = (fat - 5).clamp(30, 300);
    fatCalories = fat * 9;
    carbCalories = targetCalories - proteinCalories - fatCalories;
  }
  var carbs = (carbCalories / 4).clamp(0, 1000).round();

  var calories = _roundTo(protein * 4 + carbs * 4 + fat * 9, 10);
  protein = _roundTo(protein, 5);
  carbs = _roundTo(carbs, 5);
  fat = _roundTo(fat, 5);

  if (profile.hasCustomTargets) {
    return MacroTargets(
      calories: profile.calorieOverride ?? calories,
      protein: profile.proteinOverride ?? protein,
      carbs: profile.carbsOverride ?? carbs,
      fat: profile.fatOverride ?? fat,
      bmr: bmr,
      tdee: tdee,
      isCustom: true,
    );
  }

  return MacroTargets(
    calories: calories,
    protein: protein,
    carbs: carbs,
    fat: fat,
    bmr: bmr,
    tdee: tdee,
    isCustom: false,
  );
}

/// Simple protein/water guidance used across the app.
int dailyWaterMl(double weightKg) => (weightKg * 35).round();

int dailyFiberTargetG(double weightKg) =>
    (weightKg * 0.14 * 1000 / 100).round();
