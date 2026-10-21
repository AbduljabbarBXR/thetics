enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
  String get label => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snacks',
      };

  String get shortLabel => switch (this) {
        MealType.breakfast => 'Breakfast',
        MealType.lunch => 'Lunch',
        MealType.dinner => 'Dinner',
        MealType.snack => 'Snack',
      };
}

class FoodLogEntry {
  const FoodLogEntry({
    required this.id,
    required this.foodId,
    required this.name,
    required this.meal,
    required this.grams,
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    required this.loggedAt,
    this.imagePath,
    this.note,
    this.servingDescription,
  });

  final String id;
  final String foodId;
  final String name;
  final MealType meal;
  final double grams;
  final double calories;
  final double protein;
  final double carbs;
  final double fat;
  final DateTime loggedAt;
  final String? imagePath;
  final String? note;
  final String? servingDescription;

  Map<String, dynamic> toJson() => {
        'id': id,
        'foodId': foodId,
        'name': name,
        'meal': meal.name,
        'grams': grams,
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'loggedAt': loggedAt.toIso8601String(),
        'imagePath': imagePath,
        'note': note,
        'servingDescription': servingDescription,
      };

  factory FoodLogEntry.fromJson(Map<String, dynamic> json) {
    final mealName = json['meal'] as String?;
    return FoodLogEntry(
      id: json['id'] as String? ?? '',
      foodId: json['foodId'] as String? ?? '',
      name: json['name'] as String? ?? 'Food',
      meal: MealType.values.firstWhere(
        (meal) => meal.name == mealName,
        orElse: () => MealType.snack,
      ),
      grams: (json['grams'] as num?)?.toDouble() ?? 0,
      calories: (json['calories'] as num?)?.toDouble() ?? 0,
      protein: (json['protein'] as num?)?.toDouble() ?? 0,
      carbs: (json['carbs'] as num?)?.toDouble() ?? 0,
      fat: (json['fat'] as num?)?.toDouble() ?? 0,
      loggedAt: DateTime.tryParse(json['loggedAt'] as String? ?? '') ??
          DateTime.now(),
      imagePath: json['imagePath'] as String?,
      note: json['note'] as String?,
      servingDescription: json['servingDescription'] as String?,
    );
  }
}

class NutritionDay {
  const NutritionDay({
    required this.date,
    this.entries = const [],
    this.waterMl = 0,
  });

  final String date;
  final List<FoodLogEntry> entries;
  final int waterMl;

  double get calories =>
      entries.fold(0, (total, entry) => total + entry.calories);

  double get protein =>
      entries.fold(0, (total, entry) => total + entry.protein);

  double get carbs => entries.fold(0, (total, entry) => total + entry.carbs);

  double get fat => entries.fold(0, (total, entry) => total + entry.fat);

  bool get isEmpty => entries.isEmpty && waterMl == 0;

  List<FoodLogEntry> entriesFor(MealType meal) {
    final result = entries.where((entry) => entry.meal == meal).toList();
    result.sort((a, b) => a.loggedAt.compareTo(b.loggedAt));
    return result;
  }

  double caloriesFor(MealType meal) =>
      entriesFor(meal).fold(0, (total, entry) => total + entry.calories);

  NutritionDay copyWith({List<FoodLogEntry>? entries, int? waterMl}) {
    return NutritionDay(
      date: date,
      entries: entries ?? this.entries,
      waterMl: waterMl ?? this.waterMl,
    );
  }

  Map<String, dynamic> toJson() => {
        'date': date,
        'entries': entries.map((entry) => entry.toJson()).toList(),
        'waterMl': waterMl,
      };

  factory NutritionDay.fromJson(Map<String, dynamic> json) {
    return NutritionDay(
      date: json['date'] as String? ?? '',
      entries: (json['entries'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(FoodLogEntry.fromJson)
          .toList(),
      waterMl: (json['waterMl'] as num?)?.toInt() ?? 0,
    );
  }
}
