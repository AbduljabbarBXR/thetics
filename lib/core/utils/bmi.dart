enum BmiBand { underweight, healthy, overweight, obese }

extension BmiBandX on BmiBand {
  String get label => switch (this) {
        BmiBand.underweight => 'Underweight',
        BmiBand.healthy => 'Healthy range',
        BmiBand.overweight => 'Overweight',
        BmiBand.obese => 'Obese range',
      };

  String get note => switch (this) {
        BmiBand.underweight =>
          'A BMI below 18.5 can mean you are under-fuelled. Build up slowly.',
        BmiBand.healthy =>
          'A BMI in this range is statistically associated with lower health risk.',
        BmiBand.overweight =>
          'BMI does not distinguish muscle from fat. Use waist and trend data too.',
        BmiBand.obese =>
          'Prioritise sustainable fat loss and speak with a clinician for guidance.',
      };
}

class BmiResult {
  const BmiResult({
    required this.value,
    required this.band,
    required this.healthyMinKg,
    required this.healthyMaxKg,
  });

  final double value;
  final BmiBand band;
  final double healthyMinKg;
  final double healthyMaxKg;
}

BmiResult calculateBmi({required double weightKg, required double heightCm}) {
  final heightM = heightCm / 100;
  final value = heightM <= 0 ? 0.0 : weightKg / (heightM * heightM);
  final band = value < 18.5
      ? BmiBand.underweight
      : value < 25
          ? BmiBand.healthy
          : value < 30
              ? BmiBand.overweight
              : BmiBand.obese;
  return BmiResult(
    value: value,
    band: band,
    healthyMinKg: 18.5 * heightM * heightM,
    healthyMaxKg: 24.9 * heightM * heightM,
  );
}

double leanBodyMassKg({
  required double weightKg,
  required double heightCm,
  required bool male,
}) {
  // Boer formula.
  return male
      ? 0.407 * weightKg + 0.267 * heightCm - 19.2
      : 0.252 * weightKg + 0.473 * heightCm - 48.3;
}
