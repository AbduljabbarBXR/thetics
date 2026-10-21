import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_x.dart';
import '../../core/utils/nutrition_math.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/quick_sheets.dart';
import '../../core/widgets/surfaces.dart';
import 'add_food_screen.dart';
import 'models/nutrition_day.dart';

class NutritionScreen extends ConsumerStatefulWidget {
  const NutritionScreen({super.key});

  @override
  ConsumerState<NutritionScreen> createState() => _NutritionScreenState();
}

class _NutritionScreenState extends ConsumerState<NutritionScreen> {
  DateTime _date = DateTime.now();

  bool get _isToday => sameDay(_date, DateTime.now());

  void _shiftDay(int days) {
    final next = addDays(_date, days);
    if (next.isAfter(DateTime.now()) && !_isToday) return;
    setState(() => _date = next);
  }

  Future<void> _openAddFood(MealType meal) async {
    await Navigator.of(context).push(
      MaterialPageRoute<bool>(
        builder: (_) => AddFoodScreen(date: _date, initialMeal: meal),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final data = ref.watch(appDataProvider);
    final profile = ref.watch(profileProvider);
    final targets = ref.watch(macroTargetsProvider);
    final key = dateKey(_date);
    final day = ref.watch(nutritionDayProvider(key));
    if (data == null || profile == null || targets == null) {
      return Center(
        child: CircularProgressIndicator(color: p.accent, strokeWidth: 2),
      );
    }
    final waterTarget = dailyWaterMl(profile.weightKg);
    final remaining = targets.calories - day.calories.round();

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Eyebrow('Calories · Macros · Water', color: p.accent),
                        const SizedBox(height: 7),
                        Text(
                          'FUEL.',
                          style: text.displayLarge?.copyWith(
                            fontSize: 54,
                            height: 0.85,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => showLogWeightSheet(context),
                    style: IconButton.styleFrom(
                      backgroundColor: p.card,
                      side: BorderSide(color: p.line),
                    ),
                    icon: const Icon(Icons.monitor_weight_outlined, size: 20),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () {
                      if (_isToday) {
                        _openAddFood(_mealForNow());
                      } else {
                        _openAddFood(MealType.lunch);
                      }
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: p.accent,
                      foregroundColor: p.onAccent,
                    ),
                    icon: const Icon(Icons.add_rounded, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _DateStrip(
                date: _date,
                isToday: _isToday,
                onPrevious: () => _shiftDay(-1),
                onNext: () => _shiftDay(1),
                onToday: () => setState(() => _date = DateTime.now()),
              ),
              const SizedBox(height: 16),
              SurfaceCard(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Row(
                      children: [
                        CalorieRing(
                          value: day.calories,
                          target: targets.calories.toDouble(),
                          size: 136,
                          strokeWidth: 11,
                          center: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${day.calories.round()}',
                                style: text.headlineMedium?.copyWith(
                                  fontSize: 30,
                                  height: 1,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'OF ${targets.calories}',
                                style: TextStyle(
                                  color: p.faint,
                                  fontSize: 7.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 18),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      remaining >= 0
                                          ? '$remaining'
                                          : '${remaining.abs()}',
                                      style: text.headlineSmall?.copyWith(
                                        fontSize: 25,
                                        color:
                                            remaining < 0 ? p.ember : p.accent,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      remaining >= 0
                                          ? 'kcal left'
                                          : 'kcal over',
                                      style: TextStyle(
                                        color: p.faint,
                                        fontSize: 9.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 11),
                              MacroBar(
                                label: 'Protein',
                                value: day.protein,
                                target: targets.protein.toDouble(),
                                color: p.accent,
                                compact: true,
                              ),
                              const SizedBox(height: 10),
                              MacroBar(
                                label: 'Carbs',
                                value: day.carbs,
                                target: targets.carbs.toDouble(),
                                color: p.sky,
                                compact: true,
                              ),
                              const SizedBox(height: 10),
                              MacroBar(
                                label: 'Fat',
                                value: day.fat,
                                target: targets.fat.toDouble(),
                                color: p.ember,
                                compact: true,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: p.cardHigh,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.auto_awesome_rounded,
                            size: 13,
                            color: p.faint,
                          ),
                          const SizedBox(width: 7),
                          Expanded(
                            child: Text(
                              _fuelNote(day, targets),
                              style: TextStyle(
                                color: p.faint,
                                fontSize: 9.5,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              const SectionHeader(
                title: 'Meals',
                eyebrow: 'Log what actually went in',
              ),
              const SizedBox(height: 10),
              ...MealType.values.map(
                (meal) => Padding(
                  padding: const EdgeInsets.only(bottom: 9),
                  child: _MealCard(
                    meal: meal,
                    entries: day.entriesFor(meal),
                    calories: day.caloriesFor(meal),
                    onAdd: () => _openAddFood(meal),
                    onEntryTap: (entry) => _showEntry(context, entry),
                    onEntryDelete: (entry) async {
                      await ref
                          .read(appControllerProvider.notifier)
                          .removeFoodEntry(_date, entry.id);
                      if (!context.mounted) return;
                      showTheticsSnack(context, '${entry.name} removed.');
                    },
                  ),
                ),
              ),
              const SizedBox(height: 14),
              _WaterCard(
                waterMl: day.waterMl,
                targetMl: waterTarget,
                onAdd: (amount) async {
                  await ref
                      .read(appControllerProvider.notifier)
                      .setWater(_date, day.waterMl + amount);
                },
                onClear: () async {
                  await ref
                      .read(appControllerProvider.notifier)
                      .setWater(_date, 0);
                },
              ),
              const SizedBox(height: 14),
              _PhotoMealCard(onTap: () => _showPhotoMealInfo(context)),
              const SizedBox(height: 20),
              Text(
                'Nutrition values are estimates. Branded products and restaurant '
                'meals can vary. Use the trend and your own measurements, not a '
                'single day of data.',
                style: TextStyle(color: p.faint, fontSize: 10, height: 1.5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showEntry(BuildContext context, FoodLogEntry entry) async {
    final p = context.palette;
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(entry.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '${entry.servingDescription ?? '${entry.grams.round()} g'} · ${entry.meal.label}',
              style: TextStyle(color: p.faint, fontSize: 11),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _EntryMacro(
                  value: '${entry.calories.round()}',
                  label: 'KCAL',
                  color: p.accent,
                ),
                _EntryMacro(
                  value: '${entry.protein.round()}g',
                  label: 'PROTEIN',
                  color: p.sky,
                ),
                _EntryMacro(
                  value: '${entry.carbs.round()}g',
                  label: 'CARBS',
                  color: p.lilac,
                ),
                _EntryMacro(
                  value: '${entry.fat.round()}g',
                  label: 'FAT',
                  color: p.ember,
                ),
              ],
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref
                      .read(appControllerProvider.notifier)
                      .removeFoodEntry(_date, entry.id);
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  showTheticsSnack(context, '${entry.name} removed.');
                },
                icon: Icon(
                  Icons.delete_outline_rounded,
                  color: p.danger,
                  size: 18,
                ),
                label: Text(
                  'REMOVE FROM ${entry.meal.label.toUpperCase()}',
                  style: TextStyle(color: p.danger),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: p.danger.withValues(alpha: 0.4)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  MealType _mealForNow() {
    final hour = DateTime.now().hour;
    if (hour < 11) return MealType.breakfast;
    if (hour < 16) return MealType.lunch;
    if (hour < 21) return MealType.dinner;
    return MealType.snack;
  }

  void _showPhotoMealInfo(BuildContext context) {
    final p = context.palette;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => Padding(
        padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: p.accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.camera_alt_outlined, color: p.accent, size: 22),
            ),
            const SizedBox(height: 16),
            Text(
              'Photo meals are coming',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 8),
            Text(
              'The data model already supports meal photos and per-entry '
              'nutrition. The next step is vision-based food recognition with '
              'a review screen before anything is logged.',
              style: TextStyle(color: p.muted, fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 12),
            Text(
              'Privacy rule: nothing leaves the device until you explicitly '
              'enable an AI provider. You will always be able to edit the '
              'estimate before saving.',
              style: TextStyle(color: p.faint, fontSize: 10.5, height: 1.5),
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('GOT IT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DateStrip extends StatelessWidget {
  const _DateStrip({
    required this.date,
    required this.isToday,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime date;
  final bool isToday;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 6),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: p.line),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onPrevious,
            icon: const Icon(Icons.chevron_left_rounded, size: 20),
            color: p.muted,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          ),
          Expanded(
            child: GestureDetector(
              onTap: isToday ? null : onToday,
              child: Column(
                children: [
                  Text(
                    isToday ? 'TODAY' : relativeDay(date).toUpperCase(),
                    style: TextStyle(
                      color: p.accent,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    formatLongDate(date),
                    style: TextStyle(
                      color: p.text,
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            onPressed: isToday ? null : onNext,
            icon: const Icon(Icons.chevron_right_rounded, size: 20),
            color: isToday ? p.line : p.muted,
            visualDensity: VisualDensity.compact,
            constraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          ),
        ],
      ),
    );
  }
}

class _MealCard extends StatelessWidget {
  const _MealCard({
    required this.meal,
    required this.entries,
    required this.calories,
    required this.onAdd,
    required this.onEntryTap,
    required this.onEntryDelete,
  });

  final MealType meal;
  final List<FoodLogEntry> entries;
  final double calories;
  final VoidCallback onAdd;
  final ValueChanged<FoodLogEntry> onEntryTap;
  final ValueChanged<FoodLogEntry> onEntryDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(15, 12, 15, 12),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: p.cardHigh,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: p.line),
                ),
                child: Icon(_mealIcon(meal), size: 16, color: p.muted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      meal.label,
                      style: TextStyle(
                        color: p.text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    Text(
                      entries.isEmpty
                          ? 'Nothing logged'
                          : '${entries.length} item${entries.length == 1 ? '' : 's'}',
                      style: TextStyle(color: p.faint, fontSize: 9),
                    ),
                  ],
                ),
              ),
              if (entries.isNotEmpty)
                Text(
                  '${calories.round()} kcal',
                  style: TextStyle(
                    color: p.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              const SizedBox(width: 6),
              GestureDetector(
                onTap: onAdd,
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: p.accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Icon(Icons.add_rounded, size: 17, color: p.accent),
                ),
              ),
            ],
          ),
          if (entries.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...entries.map(
              (entry) => Dismissible(
                key: ValueKey(entry.id),
                direction: DismissDirection.endToStart,
                confirmDismiss: (_) async {
                  return confirmAction(
                    context,
                    title: 'Remove ${entry.name}?',
                    message: 'This entry will be removed from ${meal.label}.',
                    confirmLabel: 'Remove',
                    destructive: true,
                  );
                },
                onDismissed: (_) => onEntryDelete(entry),
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 12),
                  margin: const EdgeInsets.symmetric(vertical: 2),
                  decoration: BoxDecoration(
                    color: p.danger.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: p.danger,
                    size: 18,
                  ),
                ),
                child: InkWell(
                  onTap: () => onEntryTap(entry),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 7,
                      horizontal: 2,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                entry.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: p.text,
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                '${entry.servingDescription ?? '${entry.grams.round()} g'} · '
                                'P ${entry.protein.round()} · C ${entry.carbs.round()} · F ${entry.fat.round()}',
                                style: TextStyle(color: p.faint, fontSize: 8.5),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${entry.calories.round()}',
                          style: TextStyle(
                            color: p.muted,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Text(
                          'kcal',
                          style: TextStyle(color: p.faint, fontSize: 8),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

IconData _mealIcon(MealType meal) {
  return switch (meal) {
    MealType.breakfast => Icons.wb_sunny_outlined,
    MealType.lunch => Icons.lunch_dining_outlined,
    MealType.dinner => Icons.nights_stay_outlined,
    MealType.snack => Icons.cookie_outlined,
  };
}

class _WaterCard extends StatelessWidget {
  const _WaterCard({
    required this.waterMl,
    required this.targetMl,
    required this.onAdd,
    required this.onClear,
  });

  final int waterMl;
  final int targetMl;
  final ValueChanged<int> onAdd;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final progress = targetMl <= 0 ? 0.0 : (waterMl / targetMl).clamp(0.0, 1.0);
    return SurfaceCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 35,
                height: 35,
                decoration: BoxDecoration(
                  color: p.sky.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(Icons.water_drop_outlined, color: p.sky, size: 17),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'WATER',
                      style: TextStyle(
                        color: p.faint,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${(waterMl / 1000).toStringAsFixed(2)} / ${(targetMl / 1000).toStringAsFixed(1)} L',
                      style: TextStyle(
                        color: p.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: () => onAdd(250),
                style: TextButton.styleFrom(
                  foregroundColor: p.sky,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('+250'),
              ),
              TextButton(
                onPressed: () => onAdd(500),
                style: TextButton.styleFrom(
                  foregroundColor: p.sky,
                  minimumSize: const Size(0, 32),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: const Text('+500'),
              ),
              IconButton(
                onPressed: onClear,
                icon: Icon(Icons.refresh_rounded, size: 16, color: p.faint),
                visualDensity: VisualDensity.compact,
                tooltip: 'Reset water',
              ),
            ],
          ),
          const SizedBox(height: 8),
          SegmentedProgress(value: progress, color: p.sky, height: 5),
        ],
      ),
    );
  }
}

class _PhotoMealCard extends StatelessWidget {
  const _PhotoMealCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return SurfaceCard(
      padding: const EdgeInsets.all(15),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  p.lilac.withValues(alpha: 0.3),
                  p.accent.withValues(alpha: 0.16),
                ],
              ),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(Icons.camera_alt_outlined, color: p.lilac, size: 18),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Photo meals',
                      style: TextStyle(
                        color: p.text,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Tag(label: 'Soon', color: p.lilac, compact: true),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  'Snap a plate. Review the estimate. Log it.',
                  style: TextStyle(color: p.faint, fontSize: 9.5),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: p.faint, size: 18),
        ],
      ),
    );
  }
}

class _EntryMacro extends StatelessWidget {
  const _EntryMacro({
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
          const SizedBox(height: 6),
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
              fontSize: 7.5,
              letterSpacing: 0.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _fuelNote(NutritionDay day, MacroTargets targets) {
  if (day.entries.isEmpty) {
    return 'Log your first meal. Accuracy beats perfection — start with what you '
        'actually ate.';
  }
  if (day.protein < targets.protein * 0.65) {
    return 'Protein is behind. Anchor the next meal around a palm-sized serving '
        'of a lean source.';
  }
  if (day.fat < targets.fat * 0.5) {
    return 'Fat is low. Add some olive oil, nuts or avocado — hormones need it.';
  }
  if (day.calories > targets.calories + 300) {
    return 'Over target today. Do not punish yourself; return to the plan at the '
        'next meal.';
  }
  return 'Solid work. Hit protein first, let carbs fuel training, and keep the '
      'weekly average in range.';
}
