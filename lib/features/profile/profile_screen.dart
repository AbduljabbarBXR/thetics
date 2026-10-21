import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/models/app_settings.dart';
import '../../core/state/app_controller.dart';
import '../../core/state/providers.dart';
import '../../core/storage/local_store.dart';
import '../../core/theme/app_palette.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/surfaces.dart';
import '../progress/bmi_screen.dart';
import '../progress/measurements_screen.dart';
import '../progress/photos_screen.dart';
import 'about_screen.dart';
import 'edit_profile_screen.dart';
import 'models/user_profile.dart';
import 'targets_screen.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  Future<void> _copyBackup(BuildContext context, WidgetRef ref) async {
    final json = ref.read(appControllerProvider.notifier).exportJson();
    await Clipboard.setData(ClipboardData(text: json));
    if (!context.mounted) return;
    showTheticsSnack(
      context,
      'Backup JSON copied to clipboard. Paste it somewhere private.',
    );
  }

  Future<void> _importBackup(BuildContext context, WidgetRef ref) async {
    final imported = await showDialog<bool>(
      context: context,
      builder: (_) => const _ImportBackupDialog(),
    );
    if (imported == true && context.mounted) {
      showTheticsSnack(context, 'Backup restored.');
    }
  }

  Future<void> _reset(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: 'Reset Thetics?',
      message:
          'This deletes your profile, workouts, nutrition logs, measurements '
          'and progress photos from this device. There is no cloud copy unless '
          'you exported one. This cannot be undone.',
      confirmLabel: 'Delete everything',
      destructive: true,
    );
    if (!confirmed) return;
    await ref.read(appControllerProvider.notifier).resetAll();
  }

  Future<void> _loadDemo(BuildContext context, WidgetRef ref) async {
    final confirmed = await confirmAction(
      context,
      title: 'Load demo history?',
      message:
          'This adds sample workouts, weigh-ins and meals so you can explore '
          'the app with data. It only works on an empty training history.',
      confirmLabel: 'Load demo data',
    );
    if (!confirmed) return;
    final loaded =
        await ref.read(appControllerProvider.notifier).loadDemoData();
    if (!context.mounted) return;
    showTheticsSnack(
      context,
      loaded
          ? 'Demo history loaded. Explore away.'
          : 'Demo data needs an empty training history.',
      error: !loaded,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final p = context.palette;
    final text = Theme.of(context).textTheme;
    final data = ref.watch(appDataProvider);
    final profile = ref.watch(profileProvider);
    if (data == null || profile == null) {
      return Center(
        child: CircularProgressIndicator(color: p.accent, strokeWidth: 2),
      );
    }
    final storage = ref.watch(localStoreProvider);
    final settings = data.settings;
    final units = profile.units;
    final weeks = DateTime.now().difference(profile.createdAt).inDays ~/ 7;
    final memberLabel =
        weeks < 1 ? 'Just started' : '$weeks week${weeks == 1 ? '' : 's'} in';
    final hasHistory = data.sessions.isNotEmpty;

    return Scaffold(
      backgroundColor: p.bg,
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Eyebrow('Local profile · no account', color: p.accent),
                      const SizedBox(height: 7),
                      Text(
                        'YOU.',
                        style: text.displayLarge?.copyWith(
                          fontSize: 52,
                          height: 0.85,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const EditProfileScreen(),
                      ),
                    );
                  },
                  style: IconButton.styleFrom(
                    backgroundColor: p.card,
                    side: BorderSide(color: p.line),
                  ),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  tooltip: 'Edit profile',
                ),
              ],
            ),
            if (!storage.isPersistent) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: p.ember.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: p.ember.withValues(alpha: 0.35),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: p.ember,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Storage is unavailable this session. Changes will not '
                        'survive an app restart.',
                        style: TextStyle(
                          color: p.ember,
                          fontSize: 10.5,
                          height: 1.35,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SurfaceCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(19),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [p.accent, p.accent.withValues(alpha: 0.55)],
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      profile.firstName.characters.first.toUpperCase(),
                      style: TextStyle(
                        fontFamily: 'BarlowCondensed',
                        color: p.onAccent,
                        fontSize: 32,
                        fontWeight: FontWeight.w700,
                        height: 1,
                      ),
                    ),
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.headlineSmall?.copyWith(fontSize: 21),
                        ),
                        const SizedBox(height: 5),
                        Wrap(
                          spacing: 5,
                          runSpacing: 5,
                          children: [
                            Tag(
                              label: profile.goal.label,
                              color: p.accent,
                              compact: true,
                            ),
                            Tag(
                              label: profile.experience.label,
                              color: p.muted,
                              compact: true,
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '$memberLabel · ${profile.trainingDays} days/week · ${profile.units.label}',
                          style: TextStyle(color: p.faint, fontSize: 9),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                _ProfileStat(
                  value: '${data.totalCompletedWorkouts}',
                  label: 'SESSIONS',
                ),
                _ProfileStat(value: '${data.weekStreak}', label: 'WEEK STREAK'),
                _ProfileStat(
                  value: '${data.sortedMeasurements.length}',
                  label: 'MEASUREMENTS',
                ),
                _ProfileStat(
                  value: Fmt.volume(data.totalVolumeKg, units),
                  label: 'TOTAL LOAD',
                ),
              ],
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Your body',
              eyebrow: 'The numbers behind the mirror',
            ),
            const SizedBox(height: 9),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Edit profile & units',
                    subtitle: 'Name, height, goals, experience, kg/cm or lb/in',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const EditProfileScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuDivider(),
                  _MenuTile(
                    icon: Icons.tune_rounded,
                    title: 'Nutrition targets',
                    subtitle: 'Calories, protein, carbs and fat',
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const TargetsScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuDivider(),
                  _MenuTile(
                    icon: Icons.monitor_weight_outlined,
                    title: 'BMI & frame',
                    subtitle: 'Screening numbers with context',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const BmiScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuDivider(),
                  _MenuTile(
                    icon: Icons.straighten_rounded,
                    title: 'Measurements',
                    subtitle: 'Waist, chest, arms, thighs and body fat',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const MeasurementsScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuDivider(),
                  _MenuTile(
                    icon: Icons.photo_library_outlined,
                    title: 'Progress photos',
                    subtitle:
                        '${data.photos.length} stored privately on device',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const PhotosScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'Preferences', eyebrow: 'Make it yours'),
            const SizedBox(height: 9),
            SurfaceCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.contrast_rounded, size: 17, color: p.muted),
                      const SizedBox(width: 9),
                      Text(
                        'Appearance',
                        style: TextStyle(
                          color: p.text,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 9),
                  Row(
                    children: ThemeChoice.values.map((choice) {
                      final selected = settings.theme == choice;
                      return Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: choice == ThemeChoice.system ? 0 : 6,
                          ),
                          child: GestureDetector(
                            onTap: () => ref
                                .read(appControllerProvider.notifier)
                                .setTheme(choice),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 160),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: selected ? p.accent : p.cardHigh,
                                borderRadius: BorderRadius.circular(9),
                                border: Border.all(
                                  color: selected ? p.accent : p.line,
                                ),
                              ),
                              child: Text(
                                choice.label,
                                style: TextStyle(
                                  color: selected ? p.onAccent : p.muted,
                                  fontSize: 9.5,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 8),
                  Divider(color: p.line),
                  TheticsSwitch(
                    title: 'Haptic feedback',
                    subtitle: 'A small tap when a set is completed.',
                    value: settings.haptics,
                    onChanged: (value) => ref
                        .read(appControllerProvider.notifier)
                        .setHaptics(value),
                    icon: Icons.vibration_rounded,
                  ),
                  TheticsSwitch(
                    title: 'Rest timer alerts',
                    subtitle:
                        'Notify you when the rest timer reaches zero inside a workout.',
                    value: settings.restAlerts,
                    onChanged: (value) => ref
                        .read(appControllerProvider.notifier)
                        .setRestAlerts(value),
                    icon: Icons.timer_outlined,
                  ),
                  TheticsSwitch(
                    title: 'AI food photos · beta',
                    subtitle:
                        'Reserved for the opt-in photo-to-food feature. Nothing '
                        'is uploaded today; logging stays manual.',
                    value: settings.aiFoodBeta,
                    onChanged: (value) => ref
                        .read(appControllerProvider.notifier)
                        .setAiFoodBeta(value),
                    icon: Icons.auto_awesome_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const SectionHeader(
              title: 'Data & privacy',
              eyebrow: 'No account · no cloud',
            ),
            const SizedBox(height: 9),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.copy_all_outlined,
                    title: 'Copy backup JSON',
                    subtitle:
                        'Export everything to the clipboard and store it safely',
                    onTap: () => _copyBackup(context, ref),
                  ),
                  _MenuDivider(),
                  _MenuTile(
                    icon: Icons.upload_file_outlined,
                    title: 'Import backup',
                    subtitle: 'Restore from a previously copied backup',
                    onTap: () => _importBackup(context, ref),
                  ),
                  _MenuDivider(),
                  _MenuTile(
                    icon: Icons.auto_graph_rounded,
                    title: 'Load demo history',
                    subtitle: hasHistory
                        ? 'Available only on a clean training history'
                        : 'Preview the app with sample workouts and meals',
                    onTap: hasHistory ? null : () => _loadDemo(context, ref),
                    enabled: !hasHistory,
                  ),
                  _MenuDivider(),
                  _MenuTile(
                    icon: Icons.delete_forever_outlined,
                    title: 'Reset Thetics',
                    subtitle: 'Delete all local data and start over',
                    onTap: () => _reset(context, ref),
                    danger: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Data never leaves this device unless you export it. Backups are '
              'plain JSON — treat them like a diary, because that is what they '
              'are.',
              style: TextStyle(color: p.faint, fontSize: 9.5, height: 1.45),
            ),
            const SizedBox(height: 24),
            const SectionHeader(title: 'The rest'),
            const SizedBox(height: 9),
            SurfaceCard(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Column(
                children: [
                  _MenuTile(
                    icon: Icons.info_outline_rounded,
                    title: 'About Thetics',
                    subtitle: 'Philosophy, credits, privacy and disclaimers',
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const AboutScreen(),
                        ),
                      );
                    },
                  ),
                  _MenuDivider(),
                  _MenuTile(
                    icon: Icons.favorite_border_rounded,
                    title: 'The promise',
                    subtitle:
                        'No fake naturals, no crash diets, no “10x gains” nonsense',
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('The Thetics promise'),
                          content: const Text(
                            'We will not sell you a fictional physique. Natural '
                            'training is slow, repeatable and worth it. You get '
                            'honest plans, honest math, honest disclaimers and '
                            'complete ownership of your data.',
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Fair enough'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Center(
              child: Column(
                children: [
                  Text(
                    'THETICS 1.0.1',
                    style: TextStyle(
                      color: p.faint,
                      fontSize: 8.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.4,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Built for the long game. Not medical advice.',
                    style: TextStyle(color: p.faint, fontSize: 8.5),
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

class _ProfileStat extends StatelessWidget {
  const _ProfileStat({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 10),
          decoration: BoxDecoration(
            color: p.card,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: p.line),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.text,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: p.faint,
                  fontSize: 6,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.danger = false,
    this.enabled = true,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final color = danger ? p.danger : p.text;
    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(12),
      child: Opacity(
        opacity: enabled ? 1 : 0.45,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: (danger ? p.danger : p.muted).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 17, color: danger ? p.danger : p.muted),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: color,
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        color: p.faint,
                        fontSize: 9,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right_rounded, size: 17, color: p.faint),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 58),
      child: Divider(color: context.palette.line, height: 1),
    );
  }
}

class _ImportBackupDialog extends ConsumerStatefulWidget {
  const _ImportBackupDialog();

  @override
  ConsumerState<_ImportBackupDialog> createState() =>
      _ImportBackupDialogState();
}

class _ImportBackupDialogState extends ConsumerState<_ImportBackupDialog> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final value = await Clipboard.getData(Clipboard.kTextPlain);
    if (value?.text == null || !mounted) return;
    _controller.text = value!.text!;
  }

  Future<void> _import() async {
    final raw = _controller.text.trim();
    if (raw.isEmpty) {
      setState(() => _error = 'Paste a Thetics backup first.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await ref.read(appControllerProvider.notifier).importJson(raw);
      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error =
            'That does not look like a valid Thetics backup. Nothing was changed.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AlertDialog(
      title: const Text('Import backup'),
      content: SizedBox(
        width: double.maxFinite,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Paste the JSON backup exactly as it was exported. Importing '
                'replaces the data currently on this device.',
                style: TextStyle(color: p.muted, fontSize: 11, height: 1.45),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _controller,
                maxLines: 7,
                style: TextStyle(
                  color: p.text,
                  fontSize: 10,
                  fontFamily: 'monospace',
                ),
                decoration: const InputDecoration(
                  hintText: '{ "profile": ... }',
                ),
              ),
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: _paste,
                  icon: const Icon(Icons.content_paste_rounded, size: 15),
                  label: const Text('Paste'),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 4),
                Text(
                  _error!,
                  style: TextStyle(color: p.danger, fontSize: 10.5),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _import,
          child: _busy
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Import'),
        ),
      ],
    );
  }
}
