import 'package:flutter_test/flutter_test.dart';
import 'package:thetics/core/utils/bmi.dart';

void main() {
  group('calculateBmi', () {
    test('classifies a mid-range BMI and computes the healthy weight window',
        () {
      final result = calculateBmi(weightKg: 80, heightCm: 180);

      expect(result.value, closeTo(24.69, 0.01));
      expect(result.band, BmiBand.healthy);
      expect(result.healthyMinKg, closeTo(18.5 * 1.8 * 1.8, 0.001));
      expect(result.healthyMaxKg, closeTo(24.9 * 1.8 * 1.8, 0.001));
      expect(result.band.label, 'Healthy range');
    });

    test('uses the expected band boundaries', () {
      expect(
        calculateBmi(weightKg: 18.5 * 1.7 * 1.7, heightCm: 170).band,
        BmiBand.healthy,
      );
      expect(
        calculateBmi(weightKg: 25 * 1.7 * 1.7, heightCm: 170).band,
        BmiBand.overweight,
      );
      expect(
        calculateBmi(weightKg: 30 * 1.7 * 1.7, heightCm: 170).band,
        BmiBand.obese,
      );
      expect(
        calculateBmi(weightKg: 50, heightCm: 170).band,
        BmiBand.underweight,
      );
    });

    test('guards against a zero height', () {
      final result = calculateBmi(weightKg: 80, heightCm: 0);
      expect(result.value, 0);
      expect(result.band, BmiBand.underweight);
      expect(result.healthyMinKg, 0);
    });
  });

  group('leanBodyMassKg', () {
    test('returns a plausible Boer estimate for a male lifter', () {
      expect(
        leanBodyMassKg(weightKg: 80, heightCm: 180, male: true),
        closeTo(61.42, 0.01),
      );
    });

    test('uses the female formula when requested', () {
      expect(
        leanBodyMassKg(weightKg: 65, heightCm: 165, male: false),
        closeTo(46.125, 0.01),
      );
    });
  });
}
