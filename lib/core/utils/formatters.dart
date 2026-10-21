import '../../features/profile/models/user_profile.dart';

class Fmt {
  const Fmt._();

  static double kgToLb(double kg) => kg * 2.2046226218;

  static double lbToKg(double lb) => lb / 2.2046226218;

  static double cmToIn(double cm) => cm / 2.54;

  static double inToCm(double inches) => inches * 2.54;

  static String weight(double kg, UnitSystem units, {int decimals = 1}) {
    if (units == UnitSystem.imperial) {
      return '${kgToLb(kg).toStringAsFixed(decimals)} lb';
    }
    return '${kg.toStringAsFixed(decimals)} kg';
  }

  static String weightValue(double kg, UnitSystem units, {int decimals = 1}) {
    return units == UnitSystem.imperial
        ? kgToLb(kg).toStringAsFixed(decimals)
        : kg.toStringAsFixed(decimals);
  }

  static String weightLabel(UnitSystem units) =>
      units == UnitSystem.imperial ? 'lb' : 'kg';

  static String cm(double value, UnitSystem units, {int decimals = 1}) {
    if (units == UnitSystem.imperial) {
      return '${cmToIn(value).toStringAsFixed(decimals)} in';
    }
    return '${value.toStringAsFixed(decimals)} cm';
  }

  static String cmValue(double value, UnitSystem units, {int decimals = 1}) {
    return units == UnitSystem.imperial
        ? cmToIn(value).toStringAsFixed(decimals)
        : value.toStringAsFixed(decimals);
  }

  static String lengthLabel(UnitSystem units) =>
      units == UnitSystem.imperial ? 'in' : 'cm';

  static String height(double cmValue, UnitSystem units) {
    if (units == UnitSystem.metric) {
      return '${cmValue.round()} cm';
    }
    final totalInches = cmToIn(cmValue);
    final feet = totalInches ~/ 12;
    final inches = totalInches - (feet * 12);
    return "$feet'${inches.round()}\"";
  }

  static String volume(double kg, UnitSystem units) {
    final value = units == UnitSystem.imperial ? kgToLb(kg) : kg;
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}k ${weightLabel(units)}';
    }
    return '${value.round()} ${weightLabel(units)}';
  }

  static String calories(num value) => value.round().toString();

  static String macros(num grams) => '${grams.round()}g';

  static String signed(num value, {int decimals = 1, String suffix = ''}) {
    final abs = value.abs().toStringAsFixed(decimals);
    final sign = value > 0 ? '+' : (value < 0 ? '−' : '');
    return '$sign$abs$suffix';
  }

  static String clock(Duration duration) {
    final total = duration.inSeconds;
    final h = total ~/ 3600;
    final m = (total % 3600) ~/ 60;
    final s = total % 60;
    if (h > 0) {
      return '$h:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  static String durationWords(Duration duration) {
    final h = duration.inHours;
    final m = duration.inMinutes.remainder(60);
    if (h > 0) return '$h h $m min';
    return '$m min';
  }

  static String plural(int count, String word, [String? pluralWord]) =>
      '$count ${count == 1 ? word : (pluralWord ?? '${word}s')}';

  static String ordinal(int value) {
    if (value % 100 >= 11 && value % 100 <= 13) return '${value}th';
    switch (value % 10) {
      case 1:
        return '${value}st';
      case 2:
        return '${value}nd';
      case 3:
        return '${value}rd';
      default:
        return '${value}th';
    }
  }
}
