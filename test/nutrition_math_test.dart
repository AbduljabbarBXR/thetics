import 'package:flutter_test/flutter_test.dart';
import 'package:thetics/core/utils/nutrition_math.dart';
import 'package:thetics/features/profile/models/user_profile.dart';

UserProfile _profile({
  Goal goal = Goal.muscle,
  Sex sex = Sex.male,
  double weightKg = 80,
  int age = 30,
  ActivityLevel activity = ActivityLevel.moderate,
}) {
  return UserProfile(
    name: 'Test Lifter',
    sex: sex,
    age: age,
    heightCm: 180,
    weightKg: weightKg,
    goal: goal,
    experience: Experience.intermediate,
    trainingDays: 4,
    activity: activity,
    units: UnitSystem.metric,
    createdAt: DateTime(2026, 1, 1),
  );
}

void main() {
  group('calculateMacroTargets', () {
    test('computes BMR, TDEE and a muscle-gain plan', () {
      final targets = calculateMacroTargets(_profile());

      expect(targets.bmr, closeTo(1780, 0.001));
      expect(targets.tdee, closeTo(2759, 0.001));
      expect(targets.calories, 3090);
      expect(targets.protein, 160);
      expect(targets.carbs, 420);
      expect(targets.fat, 85);
      expect(targets.isCustom, isFalse);
    });

    test('applies a fat-loss deficit without dropping below the floor', () {
      final targets = calculateMacroTargets(_profile(goal: Goal.fatLoss));

      expect(targets.calories, lessThan(targets.tdee));
      expect(targets.calories, greaterThanOrEqualTo(1500));
      expect(targets.protein, 175);
    });

    test('honours manual overrides and marks them as custom', () {
      final profile = _profile().copyWith(
        calorieOverride: 2500,
        proteinOverride: 180,
        carbsOverride: 250,
        fatOverride: 70,
      );
      final targets = calculateMacroTargets(profile);

      expect(targets.calories, 2500);
      expect(targets.protein, 180);
      expect(targets.carbs, 250);
      expect(targets.fat, 70);
      expect(targets.isCustom, isTrue);
      expect(targets.bmr, closeTo(1780, 0.001));
    });

    test('clearing custom targets restores calculated values', () {
      final custom = _profile().copyWith(calorieOverride: 1234);
      final cleared = custom.copyWith(clearCustomTargets: true);
      final targets = calculateMacroTargets(cleared);

      expect(cleared.hasCustomTargets, isFalse);
      expect(targets.isCustom, isFalse);
      expect(targets.calories, 3090);
    });

    test('macro percentages add up to roughly 100%', () {
      final targets = calculateMacroTargets(_profile());
      final total = targets.proteinPct + targets.carbsPct + targets.fatPct;
      expect(total, closeTo(1, 0.02));
    });
  });

  test('water guidance scales with body weight', () {
    expect(dailyWaterMl(80), 2800);
  });
}
