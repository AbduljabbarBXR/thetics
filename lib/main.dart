import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/storage/local_store.dart';
import 'core/theme/app_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: Color(0xFF08090A),
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Paint a Flutter launch screen immediately. Storage initialization then
  // happens behind it, so a slow or broken platform channel can never leave
  // the native splash screen stuck on screen.
  runApp(const _LaunchApp());
  unawaited(_bootstrap());
}

Future<void> _bootstrap() async {
  LocalStore store;
  try {
    store = await LocalStore.openSafely();
  } catch (error, stackTrace) {
    debugPrint('Thetics: bootstrap failed: $error');
    debugPrintStack(stackTrace: stackTrace);
    store = LocalStore.memory();
  }

  runApp(
    ProviderScope(
      overrides: [localStoreProvider.overrideWithValue(store)],
      child: const TheticsApp(),
    ),
  );
}

class _LaunchApp extends StatelessWidget {
  const _LaunchApp();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Thetics',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.dark,
      home: const LaunchScreen(),
    );
  }
}
