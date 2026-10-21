import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/state/app_controller.dart';
import '../../core/state/providers.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/date_x.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/ids.dart';
import '../../core/widgets/surfaces.dart';
import '../profile/models/user_profile.dart';
import 'models/progress_photo.dart';

class PhotosScreen extends ConsumerStatefulWidget {
  const PhotosScreen({super.key});

  @override
  ConsumerState<PhotosScreen> createState() => _PhotosScreenState();
}

class _PhotosScreenState extends ConsumerState<PhotosScreen> {
  bool _picking = false;

  Future<void> _addPhoto() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1800,
        imageQuality: 88,
      );
      if (picked == null || !mounted) return;
      final data = ref.read(appDataProvider);
      final units = data?.profile?.units ?? UnitSystem.metric;
      final currentWeight = data?.currentWeightKg ?? 0;
      final result = await showModalBottomSheet<_PhotoDraft>(
        context: context,
        isScrollControlled: true,
        builder: (_) => _PhotoSheet(
          file: File(picked.path),
          currentWeightKg: currentWeight,
          units: units,
        ),
      );
      if (result == null || !mounted) return;
      await _persistPhoto(File(picked.path), result);
    } catch (error) {
      if (!mounted) return;
      showTheticsSnack(
        context,
        'Could not add that photo. Check storage permissions and try again.',
        error: true,
      );
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _persistPhoto(File source, _PhotoDraft draft) async {
    final root = await getApplicationDocumentsDirectory();
    final folder = Directory(p.join(root.path, 'progress_photos'));
    await folder.create(recursive: true);
    final extension =
        p.extension(source.path).isEmpty ? '.jpg' : p.extension(source.path);
    final destination = p.join(
      folder.path,
      'thetics_${DateTime.now().millisecondsSinceEpoch}$extension',
    );
    final copied = await source.copy(destination);
    final photo = ProgressPhoto(
      id: newId('photo'),
      path: copied.path,
      date: draft.date,
      weightKg: draft.weightKg,
      note: draft.note,
    );
    await ref.read(appControllerProvider.notifier).addProgressPhoto(photo);
    if (!mounted) return;
    showTheticsSnack(context, 'Progress photo saved.');
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final data = ref.watch(appDataProvider);
    final units = ref.watch(profileProvider)?.units ?? UnitSystem.metric;
    final photos = [...(data?.photos ?? const <ProgressPhoto>[])]
      ..sort((a, b) => b.date.compareTo(a.date));

    return Scaffold(
      backgroundColor: p.bg,
      appBar: AppBar(
        title: const Text('Progress photos'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: TextButton.icon(
              onPressed: _picking ? null : _addPhoto,
              icon: _picking
                  ? const SizedBox(
                      width: 15,
                      height: 15,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.add_a_photo_outlined, size: 17),
              label: const Text('Add'),
            ),
          ),
        ],
      ),
      body: photos.isEmpty
          ? EmptyState(
              icon: Icons.photo_camera_back_outlined,
              title: 'The mirror needs a baseline',
              message: 'Take a front, side and back photo in the same light. '
                  'You do not need to look good — you need a starting point.',
              actionLabel: 'ADD FIRST PHOTO',
              onAction: _addPhoto,
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(20, 6, 20, 32),
              children: [
                Text(
                  'RECEIPTS,\nNOT VIBES.',
                  style: text.displaySmall?.copyWith(
                    fontSize: 40,
                    height: 0.88,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Same light. Same pose. Same time of day. The scale can lie '
                  'for weeks; photos keep the long game honest.',
                  style: TextStyle(color: p.muted, fontSize: 12, height: 1.5),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Tag(label: '${photos.length} photos', compact: true),
                    const Spacer(),
                    Text(
                      'Newest first',
                      style: TextStyle(color: p.faint, fontSize: 9.5),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: photos.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    crossAxisSpacing: 7,
                    mainAxisSpacing: 7,
                    childAspectRatio: 0.72,
                  ),
                  itemBuilder: (context, index) {
                    final photo = photos[index];
                    return _PhotoTile(
                      photo: photo,
                      units: units,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => _PhotoViewScreen(
                              photo: photo,
                              units: units,
                              onDelete: () => _deletePhoto(photo),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
                const SizedBox(height: 18),
                GestureDetector(
                  onTap: _addPhoto,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: p.card.withValues(alpha: 0.5),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: p.line),
                    ),
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
                            Icons.add_a_photo_outlined,
                            color: p.accent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Add today’s photo',
                                style: TextStyle(
                                  color: p.text,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Photos stay on this device and are never uploaded.',
                                style: TextStyle(color: p.faint, fontSize: 9.5),
                              ),
                            ],
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: p.faint,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Progress photos are personal. Treat them as data, not a '
                  'referendum on your worth. Natural change is slow; compare '
                  'months, not days.',
                  style: TextStyle(color: p.faint, fontSize: 10, height: 1.5),
                ),
              ],
            ),
    );
  }

  Future<void> _deletePhoto(ProgressPhoto photo) async {
    final confirmed = await confirmAction(
      context,
      title: 'Delete this photo?',
      message:
          'The photo and its note will be removed from this device. This cannot be undone.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed) return;
    await ref
        .read(appControllerProvider.notifier)
        .deleteProgressPhoto(photo.id);
    try {
      final file = File(photo.path);
      if (await file.exists()) await file.delete();
    } catch (_) {
      // If the file is already gone, the record is still removed.
    }
    if (!mounted) return;
    Navigator.of(context).pop();
    showTheticsSnack(context, 'Photo deleted.');
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({
    required this.photo,
    required this.units,
    required this.onTap,
  });

  final ProgressPhoto photo;
  final UnitSystem units;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.file(
              File(photo.path),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: p.cardHigh,
                child: Icon(
                  Icons.broken_image_outlined,
                  color: p.faint,
                  size: 22,
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.78),
                  ],
                  stops: const [0.55, 1],
                ),
              ),
            ),
            Positioned(
              left: 8,
              right: 8,
              bottom: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formatShortDate(photo.date),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (photo.weightKg != null)
                    Text(
                      Fmt.weight(photo.weightKg!, units),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.65),
                        fontSize: 8.5,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoDraft {
  const _PhotoDraft({
    required this.date,
    required this.weightKg,
    required this.note,
  });

  final DateTime date;
  final double? weightKg;
  final String? note;
}

class _PhotoSheet extends StatefulWidget {
  const _PhotoSheet({
    required this.file,
    required this.currentWeightKg,
    required this.units,
  });

  final File file;
  final double currentWeightKg;
  final UnitSystem units;

  @override
  State<_PhotoSheet> createState() => _PhotoSheetState();
}

class _PhotoSheetState extends State<_PhotoSheet> {
  late final TextEditingController _weight;
  late final TextEditingController _note;
  late DateTime _date;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now();
    final displayWeight = widget.units == UnitSystem.imperial
        ? Fmt.kgToLb(widget.currentWeightKg)
        : widget.currentWeightKg;
    _weight = TextEditingController(
      text: widget.currentWeightKg <= 0 ? '' : displayWeight.toStringAsFixed(1),
    );
    _note = TextEditingController();
  }

  @override
  void dispose() {
    _weight.dispose();
    _note.dispose();
    super.dispose();
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

  void _save() {
    final raw = double.tryParse(_weight.text.trim().replaceAll(',', '.'));
    final kg = raw == null
        ? null
        : widget.units == UnitSystem.imperial
            ? Fmt.lbToKg(raw)
            : raw;
    Navigator.of(context).pop(
      _PhotoDraft(
        date: _date,
        weightKg: kg,
        note: _note.text.trim().isEmpty ? null : _note.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.86,
        minChildSize: 0.55,
        maxChildSize: 0.94,
        builder: (context, controller) {
          return ListView(
            controller: controller,
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
            children: [
              Text('Add progress photo', style: text.headlineSmall),
              const SizedBox(height: 5),
              Text(
                'Add the context now. Future you will want the numbers.',
                style: TextStyle(color: p.muted, fontSize: 11),
              ),
              const SizedBox(height: 14),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 250,
                  width: double.infinity,
                  child: Image.file(widget.file, fit: BoxFit.cover),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BODY WEIGHT',
                          style: TextStyle(
                            color: p.faint,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        TextField(
                          controller: _weight,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          decoration: InputDecoration(
                            hintText: 'Optional',
                            suffixText: Fmt.weightLabel(widget.units),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'DATE',
                          style: TextStyle(
                            color: p.faint,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 6),
                        SizedBox(
                          height: 54,
                          child: OutlinedButton(
                            onPressed: _pickDate,
                            child: Text(formatShortDate(_date)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _note,
                maxLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(
                  hintText: 'Lighting, pose, how you feel…',
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _save,
                  child: const Text('SAVE PHOTO'),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Stored privately on this device. You can delete it any time.',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.faint, fontSize: 9),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PhotoViewScreen extends StatelessWidget {
  const _PhotoViewScreen({
    required this.photo,
    required this.units,
    required this.onDelete,
  });

  final ProgressPhoto photo;
  final UnitSystem units;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        title: Text(
          formatDate(photo.date),
          style: const TextStyle(fontSize: 14),
        ),
        actions: [
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete photo',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: InteractiveViewer(
              minScale: 1,
              maxScale: 4,
              child: Center(
                child: Image.file(
                  File(photo.path),
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white38,
                        size: 40,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'This image file is no longer available.',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            color: p.bg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Tag(label: relativeDay(photo.date), color: p.accent),
                    const SizedBox(width: 8),
                    if (photo.weightKg != null)
                      Tag(
                        label: Fmt.weight(photo.weightKg!, units),
                        color: p.muted,
                      ),
                  ],
                ),
                if (photo.note?.trim().isNotEmpty ?? false) ...[
                  const SizedBox(height: 10),
                  Text(
                    photo.note!,
                    style: TextStyle(color: p.muted, fontSize: 12, height: 1.5),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
