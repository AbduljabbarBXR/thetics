import 'dart:math';

final Random _random = Random.secure();

String newId([String prefix = '']) {
  final micros = DateTime.now().microsecondsSinceEpoch.toRadixString(36);
  final noise = _random.nextInt(1 << 32).toRadixString(36);
  return '$prefix${prefix.isEmpty ? '' : '_'}$micros$noise';
}

/// Lowercases a display name into a stable slug.
String slugify(String value) {
  return value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
      .replaceAll(RegExp(r'^_+|_+$'), '');
}
