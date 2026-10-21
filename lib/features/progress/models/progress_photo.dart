class ProgressPhoto {
  const ProgressPhoto({
    required this.id,
    required this.path,
    required this.date,
    this.weightKg,
    this.note,
  });

  final String id;
  final String path;
  final DateTime date;
  final double? weightKg;
  final String? note;

  Map<String, dynamic> toJson() => {
        'id': id,
        'path': path,
        'date': date.toIso8601String(),
        'weightKg': weightKg,
        'note': note,
      };

  factory ProgressPhoto.fromJson(Map<String, dynamic> json) {
    return ProgressPhoto(
      id: json['id'] as String? ?? '',
      path: json['path'] as String? ?? '',
      date: DateTime.tryParse(json['date'] as String? ?? '') ?? DateTime.now(),
      weightKg: (json['weightKg'] as num?)?.toDouble(),
      note: json['note'] as String?,
    );
  }
}
