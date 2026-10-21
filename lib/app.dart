import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/models/app_settings.dart';
import 'core/state/app_controller.dart';
import 'core/theme/app_palette.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/app_logo.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'features/shell/app_shell.dart';

class TheticsApp extends ConsumerWidget {
  const TheticsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(appControllerProvider);
    final settings = asyncData.valueOrNull?.settings;
    final themeMode = switch (settings?.theme ?? ThemeChoice.dark) {
      ThemeChoice.dark => ThemeMode.dark,
      ThemeChoice.light => ThemeMode.light,
      ThemeChoice.system => ThemeMode.system,
    };

    return MaterialApp(
      title: 'Thetics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: themeMode,
      home: asyncData.when(
        loading: () => const _BootScreen(),
        error: (error, stackTrace) => _BootError(error: error),
        data: (data) {
          if (data.profile == null) return const OnboardingScreen();
          return const AppShell();
        },
      ),
    );
  }
}

class _BootScreen extends StatelessWidget {
  const _BootScreen();

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const AppMark(size: 82),
            const SizedBox(height: 20),
            const Wordmark(fontSize: 34, subtitle: 'Train · Track · Transform'),
            const SizedBox(height: 30),
            SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2, color: p.accent),
            ),
          ],
        ),
      ),
    );
  }
}

class _BootError extends StatelessWidget {
  const _BootError({required this.error});

  final Object error;

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      body: Padding(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.warning_amber_rounded, color: p.ember, size: 42),
              const SizedBox(height: 16),
              Text(
                'Could not open your data',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              Text(
                '$error',
                textAlign: TextAlign.center,
                style: TextStyle(color: p.muted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
