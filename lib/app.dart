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
        loading: () => const LaunchScreen(),
        error: (error, stackTrace) => _BootError(error: error),
        data: (data) {
          if (data.profile == null) return const OnboardingScreen();
          return const AppShell();
        },
      ),
    );
  }
}

class LaunchScreen extends StatelessWidget {
  const LaunchScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return Scaffold(
      backgroundColor: p.bg,
      body: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(0, -0.18),
            radius: 1.05,
            colors: [
              Color.lerp(p.bg, p.accent, 0.065)!,
              p.bg,
            ],
            stops: const [0, 0.72],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(96 * 0.24),
                        boxShadow: [
                          BoxShadow(
                            color: p.accent.withValues(alpha: 0.16),
                            blurRadius: 52,
                            spreadRadius: 8,
                          ),
                        ],
                      ),
                      child: const AppMark(size: 96),
                    ),
                    const SizedBox(height: 28),
                    const Wordmark(
                      fontSize: 42,
                      subtitle: 'TRAIN · TRACK · TRANSFORM',
                    ),
                    const SizedBox(height: 34),
                    SizedBox(
                      width: 132,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          minHeight: 2,
                          color: p.accent,
                          backgroundColor: p.line,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Positioned(
                left: 24,
                right: 24,
                bottom: 28,
                child: Text(
                  'LOCAL-FIRST  ·  NO ACCOUNT  ·  NO ADS',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Manrope',
                    fontWeight: FontWeight.w700,
                    fontSize: 9.5,
                    letterSpacing: 1.3,
                    color: p.faint,
                  ),
                ),
              ),
            ],
          ),
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
