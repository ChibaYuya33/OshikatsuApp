import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/state/app_providers.dart';
import 'core/state/settings_providers.dart';
import 'core/theme/app_theme.dart';
import 'features/shell/main_shell.dart';

class OshikatsuApp extends ConsumerWidget {
  const OshikatsuApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final selectedOshi = ref.watch(selectedOshiProvider);
    final seed = resolveSeedColor(selectedOshi);

    return MaterialApp(
      title: '推し活アプリ',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: AppTheme.light(seed),
      darkTheme: AppTheme.dark(seed),
      home: const MainShell(),
    );
  }
}
