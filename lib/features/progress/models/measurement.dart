class MeasurementEntry {
  const MeasurementEntry({
    required this.id,
    required this.date,
    this.weightKg,
    this.bodyFatPct,
    this.neckCm,
    this.shouldersCm,
    this.chestCm,
    this.waistCm,
    this.hipsCm,
    this.bicepLeftCm,
    this.bicepRightCm,
    this.thighLeftCm,
    this.thighRightCm,
    this.calfLeftCm,
    this.calfRightCm,
    this.note,
  });

  final String id;
  final DateTime date;
  final double? weightKg;
  final double? bodyFatPct;
  final double? neckCm;
  final double? shouldersCm;
  final double? chestCm;
  final double? waistCm;
  final double? hipsCm;
  final double? bicepLeftCm;
  final double? bicepRightCm;
  final double? thighLeftCm;
  final double? thighRightCm;
  final double? calfLeftCm;
  final double? calfRightCm;
  final String? note;

  bool get hasAnyValue =>
      weightKg != null ||
      bodyFatPct != null ||
      neckCm != null ||
      shouldersCm != null ||
      chestCm != null ||
      waistCm != null ||
      hipsCm != null ||
      bicepLeftCm != null ||
      bicepRightCm != null ||
      thighLeftCm != null ||
      thighRightCm != null ||
      calfLeftCm != null ||
      calfRightCm != null;

  double? get bicepAvgCm {
    if (bicepLeftCm == null && bicepRightCm == null) return null;
    return ((bicepLeftCm ?? bicepRightCm!) + (bicepRightCm ?? bicepLeftCm!)) /
        2;
  }

  double? get thighAvgCm {
    if (thighLeftCm == null && thighRightCm == null) return null;
    return ((thighLeftCm ?? thighRightCm!) + (thighRightCm ?? thighLeftCm!)) /
        2;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'bodyFatPct': bodyFatPct,
        'neckCm': neckCm,
        'shouldersCm': shouldersCm,
        'chestCm': chestCm,
        'waistCm': waistCm,
        'hipsCm': hipsCm,
        'bicepLeftCm': bicepLeftCm,
        'bicepRightCm': bicepRightCm,
        'thighLeftCm': thighLeftCm,
        'thighRightCm': thighRightCm,
        'calfLeftCm': calfLeftCm,
        'calfRightCm': calfRightCm,
        'note': note,
      };

  factory MeasurementEntry.fromJson(Map<String, dynamic> json) {
    double? number(String key) => (json[key] as num?)?.toDouble();
    return MeasurementEntry(
      id: json['id'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      weightKg: number('weightKg'),
      bodyFatPct: number('bodyFatPct'),
      neckCm: number('neckCm'),
      shouldersCm: number('shouldersCm'),
      chestCm: number('chestCm'),
      waistCm: number('waistCm'),
      hipsCm: number('hipsCm'),
      bicepLeftCm: number('bicepLeftCm'),
      bicepRightCm: number('bicepRightCm'),
      thighLeftCm: number('thighLeftCm'),
      thighRightCm: number('thighRightCm'),
      calfLeftCm: number('calfLeftCm'),
      calfRightCm: number('calfRightCm'),
      note: json['note'] as String?,
    );
  }
}
