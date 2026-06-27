import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/db/local_store.dart';
import 'core/notifications/notification_service.dart';
import 'core/state/app_providers.dart';
import 'core/state/settings_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');

  final prefs = await SharedPreferences.getInstance();

  // ローカルデータ読み込み(SharedPreferences に保存。iOS/Android/Web共通)。
  final store = LocalStore(PrefsStoreBackend(prefs));
  await store.load();

  // 通知初期化(Webや失敗時は安全にスキップ)。
  final notifications = NotificationService();
  await notifications.init();

  runApp(
    ProviderScope(
      overrides: [
        localStoreProvider.overrideWithValue(store),
        sharedPrefsProvider.overrideWithValue(prefs),
        notificationServiceProvider.overrideWithValue(notifications),
      ],
      child: const OshikatsuApp(),
    ),
  );
}
