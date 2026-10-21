import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_x.dart';
import '../../core/utils/ids.dart';
import '../../core/widgets/surfaces.dart';
import 'custom_food_screen.dart';
import 'data/food_database.dart';
import 'models/food_item.dart';
import 'models/nutrition_day.dart';

class AddFoodScreen extends ConsumerStatefulWidget {
  const AddFoodScreen({
    super.key,
    required this.date,
    required this.initialMeal,
  });

  final DateTime date;
  final MealType initialMeal;

  @override
  ConsumerState<AddFoodScreen> createState() => _AddFoodScreenState();
}

class _AddFoodScreenState extends ConsumerState<AddFoodScreen> {
  final _search = TextEditingController();
  late MealType _meal;
  String _category = 'All';
  String _query = '';

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  List<FoodItem> get _customFoods =>
      ref.watch(appDataProvider)?.customFoods ?? const [];

  Future<void> _openFood(FoodItem food) async {
    final added = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) =>
          _QuantitySheet(food: food, date: widget.date, initialMeal: _meal),
    );
    if (added == true && mounted) {
      setState(() {});
      showTheticsSnack(context, '${food.name} added.');
    }
  }

  Future<void> _createCustomFood() async {
    final food = await Navigator.of(context).push<FoodItem>(
      MaterialPageRoute(builder: (_) => const CustomFoodScreen()),
    );
    if (food == null || !mounted) return;
    await ref.read(appControllerProvider.notifier).addCustomFood(food);
    if (!mounted) return;
    _search.text = food.name;
    setState(() {
      _query = food.name;
      _category = food.category;
    });
    showTheticsSnack(context, '${food.name} added to your foods.');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final data = ref.watch(appDataProvider);
    final foods = searchFoods(
      query: _query,
      category: _category,
      customFoods: _customFoods,
    );
    final recent = <FoodItem>[];
    if (_query.isEmpty && _category == 'All' && data != null) {
      final entries = data.nutritionFor(widget.date).entries.reversed;
      final ids = <String>{};
      for (final entry in entries) {
        if (ids.contains(entry.foodId)) continue;
        FoodItem? custom;
        for (final item in data.customFoods) {
          if (item.id == entry.foodId) {
            custom = item;
            break;
          }
        }
        final food = custom ?? builtInFoodById(entry.foodId);
        if (food != null) {
          ids.add(entry.foodId);
          recent.add(food);
        }
        if (recent.length >= 5) break;
      }
    }

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('Add food'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                relativeDay(widget.date),
                style: TextStyle(color: p.faint, fontSize: 10.5),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'ADD TO',
                  style: TextStyle(
                    color: p.faint,
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: MealType.values.map((meal) {
                    final selected = _meal == meal;
                    return Expanded(
                      child: Padding(
                        padding: EdgeInsets.only(
                          right: meal == MealType.snack ? 0 : 6,
                        ),
                        child: GestureDetector(
                          onTap: () => setState(() => _meal = meal),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: selected ? p.text : p.card,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected ? p.text : p.line,
                              ),
                            ),
                            child: Text(
                              meal.label,
                              style: TextStyle(
                                color: selected ? p.bg : p.muted,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _search,
                  onChanged: (value) => setState(() => _query = value),
                  decoration: InputDecoration(
                    hintText: 'Search ${builtInFoods.length}+ foods',
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: p.faint,
                      size: 20,
                    ),
                    suffixIcon: _query.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () {
                              _search.clear();
                              setState(() => _query = '');
                            },
                            icon: Icon(
                              Icons.close_rounded,
                              color: p.faint,
                              size: 18,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  height: 31,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: foodCategories.map((category) {
                      final selected = _category == category;
                      return GestureDetector(
                        onTap: () => setState(() => _category = category),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 160),
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selected ? p.accent : p.card,
                            borderRadius: BorderRadius.circular(100),
                            border: Border.all(
                              color: selected ? p.accent : p.line,
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              color: selected ? p.onAccent : p.muted,
                              fontSize: 9.5,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: _createCustomFood,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 43),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                  ),
                  icon: Icon(Icons.add_rounded, size: 17, color: p.accent),
                  label: const Text('CREATE A CUSTOM FOOD'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: foods.isEmpty
                ? EmptyState(
                    icon: Icons.no_food_outlined,
                    title: 'No match',
                    message:
                        'Try a shorter search or create the food yourself with '
                        'the values from its label.',
                    actionLabel: 'CREATE CUSTOM FOOD',
                    onAction: _createCustomFood,
                  )
                : CustomScrollView(
                    slivers: [
                      if (recent.isNotEmpty)
                        SliverToBoxAdapter(
                          child: Padding(
                            padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'RECENT',
                                  style: TextStyle(
                                    color: p.faint,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 7),
                                SizedBox(
                                  height: 33,
                                  child: ListView(
                                    scrollDirection: Axis.horizontal,
                                    children: recent
                                        .map(
                                          (food) => Padding(
                                            padding: const EdgeInsets.only(
                                              right: 6,
                                            ),
                                            child: ActionChip(
                                              onPressed: () => _openFood(food),
                                              label: Text(food.name),
                                              avatar: Icon(
                                                Icons.replay_rounded,
                                                size: 13,
                                                color: p.faint,
                                              ),
                                            ),
                                          ),
                                        )
                                        .toList(),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SliverPadding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 26),
                        sliver: SliverList.separated(
                          itemCount: foods.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 7),
                          itemBuilder: (context, index) {
                            final food = foods[index];
                            return _FoodTile(
                              food: food,
                              onTap: () => _openFood(food),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }
}

class _FoodTile extends StatelessWidget {
  const _FoodTile({required this.food, required this.onTap});

  final FoodItem food;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
      radius: 15,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 39,
            height: 39,
            decoration: BoxDecoration(
              color: _categoryColor(food.category, p).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              _categoryIcon(food.category),
              size: 18,
              color: _categoryColor(food.category, p),
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        food.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: p.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    if (!food.verified) ...[
                      const SizedBox(width: 5),
                      Icon(
                        Icons.person_outline_rounded,
                        size: 11,
                        color: p.faint,
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${food.category} · ${food.servingName} (${food.servingGrams.round()} g)',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: p.faint, fontSize: 8.5),
                ),
                const SizedBox(height: 3),
                Text(
                  'P ${food.proteinPer100g.round()}  ·  C ${food.carbsPer100g.round()}  ·  F ${food.fatPer100g.round()}  / 100g',
                  style: TextStyle(color: p.muted, fontSize: 8.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 7),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${food.caloriesPer100g.round()}',
                style: TextStyle(
                  color: p.text,
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
              Text(
                'kcal/100g',
                style: TextStyle(color: p.faint, fontSize: 7.5),
              ),
            ],
          ),
          const SizedBox(width: 4),
          Icon(Icons.add_circle_outline_rounded, color: p.accent, size: 19),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'Protein' => Icons.fitness_center_rounded,
    'Carbs' => Icons.rice_bowl_outlined,
    'Fats' => Icons.opacity_rounded,
    'Fruit' => Icons.apple_rounded,
    'Veg' => Icons.eco_outlined,
    'Dairy' => Icons.local_drink_outlined,
    'Meals' => Icons.restaurant_rounded,
    'Drinks' => Icons.local_cafe_outlined,
    'Snacks' => Icons.cookie_outlined,
    _ => Icons.restaurant_menu_rounded,
  };
}

Color _categoryColor(String category, TheticsPalette p) {
  return switch (category) {
    'Protein' => p.ember,
    'Carbs' => p.sky,
    'Fats' => p.lilac,
    'Fruit' => p.ember,
    'Veg' => p.success,
    'Dairy' => p.sky,
    'Snacks' => p.lilac,
    _ => p.accent,
  };
}

class _QuantitySheet extends ConsumerStatefulWidget {
  const _QuantitySheet({
    required this.food,
    required this.date,
    required this.initialMeal,
  });

  final FoodItem food;
  final DateTime date;
  final MealType initialMeal;

  @override
  ConsumerState<_QuantitySheet> createState() => _QuantitySheetState();
}

class _QuantitySheetState extends ConsumerState<_QuantitySheet> {
  late final TextEditingController _amount;
  late MealType _meal;
  String? _error;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
    _amount = TextEditingController(
      text: widget.food.servingGrams.toStringAsFixed(
        widget.food.servingGrams % 1 == 0 ? 0 : 1,
      ),
    );
  }

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  double get _grams =>
      double.tryParse(_amount.text.trim().replaceAll(',', '.')) ?? 0;

  Future<void> _add() async {
    final grams = _grams;
    if (grams < 1 || grams > 3000) {
      setState(() => _error = 'Enter an amount between 1 and 3000 g.');
      return;
    }
    setState(() {
      _adding = true;
      _error = null;
    });
    final now = DateTime.now();
    final loggedAt = sameDay(widget.date, now)
        ? now
        : DateTime(widget.date.year, widget.date.month, widget.date.day, 12);
    final servings = grams / widget.food.servingGrams;
    final entry = FoodLogEntry(
      id: newId('entry'),
      foodId: widget.food.id,
      name: widget.food.name,
      meal: _meal,
      grams: grams,
      calories: widget.food.caloriesFor(grams),
      protein: widget.food.proteinFor(grams),
      carbs: widget.food.carbsFor(grams),
      fat: widget.food.fatFor(grams),
      loggedAt: loggedAt,
      servingDescription: servings == 1
          ? widget.food.servingName
          : '${servings.toStringAsFixed(servings % 1 == 0 ? 0 : 1)} × ${widget.food.servingName}',
    );
    await ref
        .read(appControllerProvider.notifier)
        .addFoodEntry(widget.date, entry);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final food = widget.food;
    final grams = _grams;
    final calories = food.caloriesFor(grams);
    final protein = food.proteinFor(grams);
    final carbs = food.carbsFor(grams);
    final fat = food.fatFor(grams);
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 4,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(food.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${food.category} · per 100 g: ${food.caloriesPer100g.round()} kcal',
              style: TextStyle(color: p.faint, fontSize: 10),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(
                  child: TextField(
                    controller: _amount,
                    autofocus: true,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    onChanged: (_) => setState(() => _error = null),
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                    ),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      suffixText: 'g',
                      errorText: _error,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    '${(grams / food.servingGrams).toStringAsFixed(2)} × ${food.servingName}',
                    style: TextStyle(color: p.faint, fontSize: 9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                _Preset(
                  label: '1 serving',
                  onTap: () => setState(
                    () => _amount.text = food.servingGrams.toStringAsFixed(
                      food.servingGrams % 1 == 0 ? 0 : 1,
                    ),
                  ),
                ),
                _Preset(
                  label: '100 g',
                  onTap: () => setState(() => _amount.text = '100'),
                ),
                _Preset(
                  label: '150 g',
                  onTap: () => setState(() => _amount.text = '150'),
                ),
                _Preset(
                  label: '200 g',
                  onTap: () => setState(() => _amount.text = '200'),
                ),
                _Preset(
                  label: '2 servings',
                  onTap: () => setState(
                    () => _amount.text =
                        (food.servingGrams * 2).toStringAsFixed(0),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: p.cardHigh,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: p.line),
              ),
              child: Row(
                children: [
                  _QuantityMacro(
                    value: '${calories.round()}',
                    label: 'KCAL',
                    color: p.accent,
                  ),
                  _QuantityMacro(
                    value: '${protein.round()}g',
                    label: 'PROTEIN',
                    color: p.sky,
                  ),
                  _QuantityMacro(
                    value: '${carbs.round()}g',
                    label: 'CARBS',
                    color: p.lilac,
                  ),
                  _QuantityMacro(
                    value: '${fat.round()}g',
                    label: 'FAT',
                    color: p.ember,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              'ADD TO',
              style: TextStyle(
                color: p.faint,
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: MealType.values.map((meal) {
                final selected = _meal == meal;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: meal == MealType.snack ? 0 : 5,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _meal = meal),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? p.accent : p.card,
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: selected ? p.accent : p.line,
                          ),
                        ),
                        child: Text(
                          meal.shortLabel,
                          style: TextStyle(
                            color: selected ? p.onAccent : p.muted,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _adding ? null : _add,
                child: _adding
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text('ADD TO ${_meal.label.toUpperCase()}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Preset extends StatelessWidget {
  const _Preset({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(color: p.line),
        ),
        child: Text(label, style: TextStyle(color: p.muted, fontSize: 9.5)),
      ),
    );
  }
}

class _QuantityMacro extends StatelessWidget {
  const _QuantityMacro({
    required this.value,
    required this.label,
    required this.color,
  });

  final String value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 14, height: 2.5, color: color),
          const SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              color: p.text,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              color: p.faint,
              fontSize: 7,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
