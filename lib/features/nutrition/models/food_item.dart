class FoodItem {
  const FoodItem({
    required this.id,
    required this.name,
    required this.category,
    required this.servingName,
    required this.servingGrams,
    required this.caloriesPer100g,
    required this.proteinPer100g,
    required this.carbsPer100g,
    required this.fatPer100g,
    this.brand,
    this.verified = false,
  });

  final String id;
  final String name;
  final String category;
  final String servingName;
  final double servingGrams;
  final double caloriesPer100g;
  final double proteinPer100g;
  final double carbsPer100g;
  final double fatPer100g;
  final String? brand;
  final bool verified;

  double caloriesFor(double grams) => caloriesPer100g * grams / 100;

  double proteinFor(double grams) => proteinPer100g * grams / 100;

  double carbsFor(double grams) => carbsPer100g * grams / 100;

  double fatFor(double grams) => fatPer100g * grams / 100;

  FoodItem copyWith({
    String? id,
    String? name,
    String? category,
    String? servingName,
    double? servingGrams,
    double? caloriesPer100g,
    double? proteinPer100g,
    double? carbsPer100g,
    double? fatPer100g,
    String? brand,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      servingName: servingName ?? this.servingName,
      servingGrams: servingGrams ?? this.servingGrams,
      caloriesPer100g: caloriesPer100g ?? this.caloriesPer100g,
      proteinPer100g: proteinPer100g ?? this.proteinPer100g,
      carbsPer100g: carbsPer100g ?? this.carbsPer100g,
      fatPer100g: fatPer100g ?? this.fatPer100g,
      brand: brand ?? this.brand,
      verified: verified,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'category': category,
        'servingName': servingName,
        'servingGrams': servingGrams,
        'caloriesPer100g': caloriesPer100g,
        'proteinPer100g': proteinPer100g,
        'carbsPer100g': carbsPer100g,
        'fatPer100g': fatPer100g,
        'brand': brand,
        'verified': verified,
      };

  factory FoodItem.fromJson(Map<String, dynamic> json) {
    return FoodItem(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Custom food',
      category: json['category'] as String? ?? 'Custom',
      servingName: json['servingName'] as String? ?? 'serving',
      servingGrams: (json['servingGrams'] as num?)?.toDouble() ?? 100,
      caloriesPer100g: (json['caloriesPer100g'] as num?)?.toDouble() ?? 0,
      proteinPer100g: (json['proteinPer100g'] as num?)?.toDouble() ?? 0,
      carbsPer100g: (json['carbsPer100g'] as num?)?.toDouble() ?? 0,
      fatPer100g: (json['fatPer100g'] as num?)?.toDouble() ?? 0,
      brand: json['brand'] as String?,
      verified: json['verified'] as bool? ?? false,
    );
  }
}

const foodCategories = <String>[
  'All',
  'Protein',
  'Carbs',
  'Fats',
  'Fruit',
  'Veg',
  'Dairy',
  'Meals',
  'Drinks',
  'Snacks',
];
