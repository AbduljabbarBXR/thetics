import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_x.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ids.dart';
import '../../core/widgets/surfaces.dart';
import '../profile/models/user_profile.dart';
import 'models/measurement.dart';

class MeasurementsScreen extends ConsumerWidget {
  const MeasurementsScreen({super.key});

  Future<void> _openSheet(
    BuildContext context,
    WidgetRef ref, {
    MeasurementEntry? existing,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MeasurementSheet(existing: existing),
    );
    if (saved == true && context.mounted) {
      showTheticsSnack(
        context,
        existing == null ? 'Measurements saved.' : 'Measurements updated.',
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final data = ref.watch(appDataProvider);
    final units = ref.watch(profileProvider)?.units ?? UnitSystem.metric;
    final entries = data?.sortedMeasurements ?? const <MeasurementEntry>[];

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('Measurements'),
        actions: [
          IconButton(
            onPressed: () => _openSheet(context, ref),
            icon: const Icon(Icons.add_rounded),
            tooltip: 'New measurement',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: entries.isEmpty
          ? EmptyState(
              icon: Icons.straighten_rounded,
              title: 'No measurements yet',
              message:
                  'Waist, chest, arms and thighs tell a story the scale cannot. '
                  'Measure under the same conditions every two weeks.',
              actionLabel: 'ADD FIRST MEASUREMENT',
              onAction: () => _openSheet(context, ref),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
              children: [
                Text(
                  'THE TAPE\nDOES NOT LIE.',
                  style: text.displaySmall?.copyWith(
                    fontSize: 40,
                    height: 0.88,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Same time of day, same posture, same tape tension. '
                  'Every two weeks is plenty.',
                  style: TextStyle(color: p.muted, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 16),
                SurfaceCard(
                  padding: const EdgeInsets.all(15),
                  child: Row(
                    children: [
                      Container(
                        width: 38,
                        height: 38,
                        decoration: BoxDecoration(
                          color: p.accent.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: Icon(
                          Icons.straighten_rounded,
                          color: p.accent,
                          size: 19,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Text(
                          '${entries.length} measurement session${entries.length == 1 ? '' : 's'} recorded. '
                          'The newest is at the top.',
                          style: TextStyle(
                            color: p.muted,
                            fontSize: 10.5,
                            height: 1.45,
                          ),
                        ),
                      ),
                      FilledButton.tonal(
                        onPressed: () => _openSheet(context, ref),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 36),
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        child: const Text('ADD'),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                ...entries.asMap().entries.map((item) {
                  final index = item.key;
                  final entry = item.value;
                  final previous =
                      index + 1 < entries.length ? entries[index + 1] : null;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _MeasurementCard(
                      entry: entry,
                      previous: previous,
                      units: units,
                      onTap: () => _openSheet(context, ref, existing: entry),
                      onDelete: () async {
                        final confirmed = await confirmAction(
                          context,
                          title: 'Delete this measurement?',
                          message:
                              'This entry will be removed. Your profile weight '
                              'will fall back to the next most recent reading.',
                          confirmLabel: 'Delete',
                          destructive: true,
                        );
                        if (!confirmed) return;
                        await ref
                            .read(appControllerProvider.notifier)
                            .deleteMeasurement(entry.id);
                        if (!context.mounted) return;
                        showTheticsSnack(context, 'Measurement deleted.');
                      },
                    ),
                  );
                }),
                const SizedBox(height: 12),
                Text(
                  'Measurements are a snapshot, not a scoreboard. A waist that '
                  'moves slowly while your lifts climb is usually the right '
                  'direction — especially in a surplus.',
                  style: TextStyle(color: p.faint, fontSize: 10, height: 1.5),
                ),
              ],
            ),
    );
  }
}

class _MeasurementCard extends StatelessWidget {
  const _MeasurementCard({
    required this.entry,
    required this.previous,
    required this.units,
    required this.onTap,
    required this.onDelete,
  });

  final MeasurementEntry entry;
  final MeasurementEntry? previous;
  final UnitSystem units;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final weightDelta = entry.weightKg != null && previous?.weightKg != null
        ? entry.weightKg! - previous!.weightKg!
        : null;
    final bicep = entry.bicepAvgCm;
    final waistDelta = entry.waistCm != null && previous?.waistCm != null
        ? entry.waistCm! - previous!.waistCm!
        : null;
    return SurfaceCard(
      padding: const EdgeInsets.fromLTRB(15, 13, 9, 13),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 37,
                height: 37,
                decoration: BoxDecoration(
                  color: p.cardHigh,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(color: p.line),
                ),
                alignment: Alignment.center,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '${entry.date.day}',
                      style: TextStyle(
                        color: p.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        height: 1,
                      ),
                    ),
                    Text(
                      monthShort(entry.date).toUpperCase(),
                      style: TextStyle(
                        color: p.accent,
                        fontSize: 6.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      relativeDay(entry.date),
                      style: TextStyle(
                        color: p.text,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      formatDate(entry.date),
                      style: TextStyle(color: p.faint, fontSize: 9),
                    ),
                  ],
                ),
              ),
              if (entry.weightKg != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      Fmt.weight(entry.weightKg!, units),
                      style: TextStyle(
                        color: p.text,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    if (weightDelta != null)
                      Text(
                        '${Fmt.signed(units == UnitSystem.imperial ? Fmt.kgToLb(weightDelta) : weightDelta, suffix: ' ${Fmt.weightLabel(units)}')} vs prior',
                        style: TextStyle(
                          color: weightDelta > 0 ? p.ember : p.success,
                          fontSize: 8,
                        ),
                      ),
                  ],
                ),
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: p.faint, size: 18),
                padding: EdgeInsets.zero,
                onSelected: (value) {
                  if (value == 'edit') onTap();
                  if (value == 'delete') onDelete();
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit entry')),
                  PopupMenuItem(value: 'delete', child: Text('Delete entry')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _MiniMetric(
                label: 'WAIST',
                value:
                    entry.waistCm == null ? '—' : Fmt.cm(entry.waistCm!, units),
                delta: waistDelta,
                units: units,
              ),
              _MiniMetric(
                label: 'CHEST',
                value:
                    entry.chestCm == null ? '—' : Fmt.cm(entry.chestCm!, units),
              ),
              _MiniMetric(
                label: 'BICEP AVG',
                value: bicep == null ? '—' : Fmt.cm(bicep, units),
              ),
              _MiniMetric(
                label: 'BODY FAT',
                value: entry.bodyFatPct == null
                    ? '—'
                    : '${entry.bodyFatPct!.toStringAsFixed(1)}%',
              ),
            ],
          ),
          if (entry.note?.trim().isNotEmpty ?? false) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_rounded, size: 12, color: p.faint),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    entry.note!,
                    style: TextStyle(
                      color: p.faint,
                      fontSize: 9.5,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({
    required this.label,
    required this.value,
    this.delta,
    this.units = UnitSystem.metric,
  });

  final String label;
  final String value;
  final double? delta;
  final UnitSystem units;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: p.faint,
              fontSize: 6.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.7,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Flexible(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: p.text,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              if (delta != null) ...[
                const SizedBox(width: 3),
                Text(
                  Fmt.signed(
                    units == UnitSystem.imperial ? Fmt.cmToIn(delta!) : delta!,
                    decimals: 1,
                  ),
                  style: TextStyle(
                    color: delta! > 0 ? p.ember : p.success,
                    fontSize: 7,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MeasurementSheet extends ConsumerStatefulWidget {
  const _MeasurementSheet({this.existing});

  final MeasurementEntry? existing;

  @override
  ConsumerState<_MeasurementSheet> createState() => _MeasurementSheetState();
}

class _MeasurementSheetState extends ConsumerState<_MeasurementSheet> {
  late UnitSystem _units;
  late DateTime _date;
  late final TextEditingController _weight;
  late final TextEditingController _bodyFat;
  late final TextEditingController _neck;
  late final TextEditingController _shoulders;
  late final TextEditingController _chest;
  late final TextEditingController _waist;
  late final TextEditingController _hips;
  late final TextEditingController _bicepLeft;
  late final TextEditingController _bicepRight;
  late final TextEditingController _thighLeft;
  late final TextEditingController _thighRight;
  late final TextEditingController _calfLeft;
  late final TextEditingController _calfRight;
  late final TextEditingController _note;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    final profile = ref.read(profileProvider);
    _units = profile?.units ?? UnitSystem.metric;
    _date = existing?.date ?? DateTime.now();
    final data = ref.read(appDataProvider);
    final fallbackWeight =
        existing?.weightKg ?? data?.currentWeightKg ?? profile?.weightKg;

    String weightText(double? kg) {
      if (kg == null) return '';
      final value = _units == UnitSystem.imperial ? Fmt.kgToLb(kg) : kg;
      return value.toStringAsFixed(1);
    }

    String lengthText(double? cm) {
      if (cm == null) return '';
      final value = _units == UnitSystem.imperial ? Fmt.cmToIn(cm) : cm;
      return value.toStringAsFixed(1);
    }

    _weight = TextEditingController(text: weightText(fallbackWeight));
    _bodyFat = TextEditingController(
      text: existing?.bodyFatPct?.toStringAsFixed(1) ?? '',
    );
    _neck = TextEditingController(text: lengthText(existing?.neckCm));
    _shoulders = TextEditingController(text: lengthText(existing?.shouldersCm));
    _chest = TextEditingController(text: lengthText(existing?.chestCm));
    _waist = TextEditingController(text: lengthText(existing?.waistCm));
    _hips = TextEditingController(text: lengthText(existing?.hipsCm));
    _bicepLeft = TextEditingController(text: lengthText(existing?.bicepLeftCm));
    _bicepRight = TextEditingController(
      text: lengthText(existing?.bicepRightCm),
    );
    _thighLeft = TextEditingController(text: lengthText(existing?.thighLeftCm));
    _thighRight = TextEditingController(
      text: lengthText(existing?.thighRightCm),
    );
    _calfLeft = TextEditingController(text: lengthText(existing?.calfLeftCm));
    _calfRight = TextEditingController(text: lengthText(existing?.calfRightCm));
    _note = TextEditingController(text: existing?.note ?? '');
  }

  @override
  void dispose() {
    for (final controller in [
      _weight,
      _bodyFat,
      _neck,
      _shoulders,
      _chest,
      _waist,
      _hips,
      _bicepLeft,
      _bicepRight,
      _thighLeft,
      _thighRight,
      _calfLeft,
      _calfRight,
      _note,
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  double? _number(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  double? _weightKg() {
    final raw = _number(_weight);
    if (raw == null) return null;
    return _units == UnitSystem.imperial ? Fmt.lbToKg(raw) : raw;
  }

  double? _lengthCm(TextEditingController controller) {
    final raw = _number(controller);
    if (raw == null) return null;
    return _units == UnitSystem.imperial ? Fmt.inToCm(raw) : raw;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    final weight = _weightKg();
    final bodyFat = _number(_bodyFat);
    final waist = _lengthCm(_waist);
    final chest = _lengthCm(_chest);
    final neck = _lengthCm(_neck);
    final shoulders = _lengthCm(_shoulders);
    final hips = _lengthCm(_hips);
    final bicepLeft = _lengthCm(_bicepLeft);
    final bicepRight = _lengthCm(_bicepRight);
    final thighLeft = _lengthCm(_thighLeft);
    final thighRight = _lengthCm(_thighRight);
    final calfLeft = _lengthCm(_calfLeft);
    final calfRight = _lengthCm(_calfRight);

    if (weight == null &&
        bodyFat == null &&
        waist == null &&
        chest == null &&
        neck == null &&
        shoulders == null &&
        hips == null &&
        bicepLeft == null &&
        bicepRight == null &&
        thighLeft == null &&
        thighRight == null &&
        calfLeft == null &&
        calfRight == null) {
      setState(() => _error = 'Add at least one measurement.');
      return;
    }
    if (weight != null && (weight < 30 || weight > 300)) {
      setState(() => _error = 'Body weight must be between 30 and 300 kg.');
      return;
    }
    if (bodyFat != null && (bodyFat < 2 || bodyFat > 70)) {
      setState(() => _error = 'Body fat must be between 2% and 70%.');
      return;
    }
    final lengths = [
      waist,
      chest,
      neck,
      shoulders,
      hips,
      bicepLeft,
      bicepRight,
      thighLeft,
      thighRight,
      calfLeft,
      calfRight,
    ];
    if (lengths.any((value) => value != null && (value < 5 || value > 250))) {
      setState(() => _error = 'Check the tape measurements and try again.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final entry = MeasurementEntry(
      id: widget.existing?.id ?? newId('m'),
      date: _date,
      weightKg: weight,
      bodyFatPct: bodyFat,
      neckCm: neck,
      shouldersCm: shoulders,
      chestCm: chest,
      waistCm: waist,
      hipsCm: hips,
      bicepLeftCm: bicepLeft,
      bicepRightCm: bicepRight,
      thighLeftCm: thighLeft,
      thighRightCm: thighRight,
      calfLeftCm: calfLeft,
      calfRightCm: calfRight,
      note: _note.text.trim().isEmpty ? null : _note.text.trim(),
    );
    await ref.read(appControllerProvider.notifier).saveMeasurement(entry);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final unitLabel = Fmt.lengthLabel(_units);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.9,
        minChildSize: 0.55,
        maxChildSize: 0.96,
        builder: (context, scrollController) {
          return ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 30),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.existing == null
                          ? 'New measurement'
                          : 'Edit measurement',
                      style: text.headlineSmall,
                    ),
                  ),
                  TextButton.icon(
                    onPressed: _pickDate,
                    icon: Icon(
                      Icons.calendar_today_outlined,
                      size: 14,
                      color: p.accent,
                    ),
                    label: Text(
                      formatDate(_date),
                      style: TextStyle(color: p.text, fontSize: 11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Use the same tape tension each time. Enter only what you '
                'measured; blank fields stay blank.',
                style: TextStyle(color: p.muted, fontSize: 11, height: 1.45),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _MeasurementField(
                      label: 'BODY WEIGHT',
                      controller: _weight,
                      suffix: Fmt.weightLabel(_units),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _MeasurementField(
                      label: 'BODY FAT',
                      controller: _bodyFat,
                      suffix: '%',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const DividerLabel('Upper body'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MeasurementField(
                      label: 'NECK',
                      controller: _neck,
                      suffix: unitLabel,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _MeasurementField(
                      label: 'SHOULDERS',
                      controller: _shoulders,
                      suffix: unitLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _MeasurementField(
                      label: 'CHEST',
                      controller: _chest,
                      suffix: unitLabel,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _MeasurementField(
                      label: 'WAIST (NAVEL)',
                      controller: _waist,
                      suffix: unitLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              _MeasurementField(
                label: 'HIPS',
                controller: _hips,
                suffix: unitLabel,
              ),
              const SizedBox(height: 15),
              const DividerLabel('Arms'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MeasurementField(
                      label: 'BICEP LEFT',
                      controller: _bicepLeft,
                      suffix: unitLabel,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _MeasurementField(
                      label: 'BICEP RIGHT',
                      controller: _bicepRight,
                      suffix: unitLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const DividerLabel('Legs'),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _MeasurementField(
                      label: 'THIGH LEFT',
                      controller: _thighLeft,
                      suffix: unitLabel,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _MeasurementField(
                      label: 'THIGH RIGHT',
                      controller: _thighRight,
                      suffix: unitLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 9),
              Row(
                children: [
                  Expanded(
                    child: _MeasurementField(
                      label: 'CALF LEFT',
                      controller: _calfLeft,
                      suffix: unitLabel,
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _MeasurementField(
                      label: 'CALF RIGHT',
                      controller: _calfRight,
                      suffix: unitLabel,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 15),
              const _SheetFieldLabel('NOTE'),
              const SizedBox(height: 6),
              TextField(
                controller: _note,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Conditions, lighting, how you felt…',
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    Icon(
                      Icons.error_outline_rounded,
                      size: 15,
                      color: p.danger,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        _error!,
                        style: TextStyle(color: p.danger, fontSize: 10.5),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('SAVE MEASUREMENT'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MeasurementField extends StatelessWidget {
  const _MeasurementField({
    required this.label,
    required this.controller,
    required this.suffix,
  });

  final String label;
  final TextEditingController controller;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SheetFieldLabel(label),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
          ],
          decoration: InputDecoration(hintText: '—', suffixText: suffix),
        ),
      ],
    );
  }
}

class _SheetFieldLabel extends StatelessWidget {
  const _SheetFieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.palette.faint,
        fontSize: 8,
        fontWeight: FontWeight.w800,
        letterSpacing: 1,
      ),
    );
  }
}
