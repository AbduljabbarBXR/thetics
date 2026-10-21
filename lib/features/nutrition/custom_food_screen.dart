import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_palette.dart';
import '../../core/utils/ids.dart';
import '../../core/widgets/surfaces.dart';
import 'models/food_item.dart';

class CustomFoodScreen extends StatefulWidget {
  const CustomFoodScreen({super.key});

  @override
  State<CustomFoodScreen> createState() => _CustomFoodScreenState();
}

class _CustomFoodScreenState extends State<CustomFoodScreen> {
  final _name = TextEditingController();
  final _brand = TextEditingController();
  final _servingName = TextEditingController(text: 'serving');
  final _servingGrams = TextEditingController(text: '100');
  final _calories = TextEditingController();
  final _protein = TextEditingController();
  final _carbs = TextEditingController();
  final _fat = TextEditingController();
  String _category = 'Protein';
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _brand.dispose();
    _servingName.dispose();
    _servingGrams.dispose();
    _calories.dispose();
    _protein.dispose();
    _carbs.dispose();
    _fat.dispose();
    super.dispose();
  }

  double _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.')) ?? 0;

  void _save() {
    final name = _name.text.trim();
    final servingGrams = _number(_servingGrams);
    if (name.isEmpty) {
      setState(() => _error = 'Give the food a name.');
      return;
    }
    if (servingGrams <= 0) {
      setState(() => _error = 'Serving size must be greater than zero.');
      return;
    }
    if (_number(_calories) < 0 ||
        _number(_protein) < 0 ||
        _number(_carbs) < 0 ||
        _number(_fat) < 0) {
      setState(() => _error = 'Nutrition values cannot be negative.');
      return;
    }
    final food = FoodItem(
      id: newId('custom'),
      name: name,
      brand: _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      category: _category,
      servingName: _servingName.text.trim().isEmpty
          ? 'serving'
          : _servingName.text.trim(),
      servingGrams: servingGrams,
      caloriesPer100g: _number(_calories),
      proteinPer100g: _number(_protein),
      carbsPer100g: _number(_carbs),
      fatPer100g: _number(_fat),
    );
    Navigator.of(context).pop(food);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final servingGrams = _number(_servingGrams);
    final calories = _number(_calories) * servingGrams / 100;
    final protein = _number(_protein) * servingGrams / 100;
    final carbs = _number(_carbs) * servingGrams / 100;
    final fat = _number(_fat) * servingGrams / 100;

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(title: const Text('Custom food')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        children: [
          Text(
            'YOUR LABEL,\nYOUR NUMBERS.',
            style: text.displaySmall?.copyWith(fontSize: 36, height: 0.92),
          ),
          const SizedBox(height: 8),
          Text(
            'Enter the values exactly as they appear on the label, per 100 g. '
            'We will scale them to whatever amount you log.',
            style: TextStyle(color: p.muted, fontSize: 12, height: 1.5),
          ),
          const SizedBox(height: 20),
          _Field(
            label: 'FOOD NAME',
            child: TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                hintText: 'e.g. Chicken shawarma',
              ),
            ),
          ),
          _Field(
            label: 'BRAND (OPTIONAL)',
            child: TextField(
              controller: _brand,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(hintText: 'e.g. Local deli'),
            ),
          ),
          _Field(
            label: 'CATEGORY',
            child: DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              dropdownColor: p.surface,
              items: foodCategories
                  .where((category) => category != 'All')
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(category),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) setState(() => _category = value);
              },
            ),
          ),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _Field(
                  label: 'SERVING NAME',
                  child: TextField(
                    controller: _servingName,
                    decoration: const InputDecoration(hintText: 'serving'),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: _Field(
                  label: 'GRAMS / SERVING',
                  child: TextField(
                    controller: _servingGrams,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                    ],
                    decoration: const InputDecoration(suffixText: 'g'),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const DividerLabel('per 100 g'),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'CALORIES',
                  child: _NumberField(
                    controller: _calories,
                    hint: '0',
                    suffix: 'kcal',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Field(
                  label: 'PROTEIN',
                  child: _NumberField(
                    controller: _protein,
                    hint: '0',
                    suffix: 'g',
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: _Field(
                  label: 'CARBS',
                  child: _NumberField(
                    controller: _carbs,
                    hint: '0',
                    suffix: 'g',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _Field(
                  label: 'FAT',
                  child: _NumberField(controller: _fat, hint: '0', suffix: 'g'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SurfaceCard(
            padding: const EdgeInsets.all(15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Eyebrow('PER SERVING PREVIEW'),
                const SizedBox(height: 9),
                Text(
                  '${calories.round()} kcal',
                  style: text.headlineSmall?.copyWith(fontSize: 25),
                ),
                const SizedBox(height: 3),
                Text(
                  'P ${protein.round()} g  ·  C ${carbs.round()} g  ·  F ${fat.round()} g'
                  '${servingGrams > 0 ? '  ·  ${servingGrams.toStringAsFixed(servingGrams % 1 == 0 ? 0 : 1)} g' : ''}',
                  style: TextStyle(color: p.muted, fontSize: 10.5),
                ),
              ],
            ),
          ),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.error_outline_rounded, size: 15, color: p.danger),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _error!,
                    style: TextStyle(color: p.danger, fontSize: 11),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 18),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              child: const Text('SAVE CUSTOM FOOD'),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Custom foods stay on this device and appear in search instantly.',
            textAlign: TextAlign.center,
            style: TextStyle(color: p.faint, fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.hint,
    required this.suffix,
  });

  final TextEditingController controller;
  final String hint;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      decoration: InputDecoration(hintText: hint, suffixText: suffix),
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: context.palette.faint,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 6),
          child,
        ],
      ),
    );
  }
}
