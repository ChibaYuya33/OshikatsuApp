// スクリーンショット/プレビュー用のデモ起動。デモデータを注入して起動する。
// 本番では使用しない（通常は main.dart）。
//   flutter run -t lib/main_demo.dart -d chrome
//   flutter build web -t lib/main_demo.dart

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/db/local_store.dart';
import 'core/db/models.dart';
import 'core/notifications/notification_service.dart';
import 'core/state/app_providers.dart';
import 'core/state/settings_providers.dart';

DbData _demoData() {
  final now = DateTime.now();
  final oshi1 = Oshi(
    id: 'o1',
    name: 'みーちゃん',
    themeColor: 0xFFE0A3AC, // くすみピンク
    birthday: DateTime(2001, now.month, now.day + 12),
    createdAt: DateTime(2026, 1, 1),
  );
  final oshi2 = Oshi(
    id: 'o2',
    name: 'あおい',
    themeColor: 0xFF8FAAC0, // ダスティブルー
    birthday: DateTime(2000, 12, 3),
    createdAt: DateTime(2026, 1, 2),
  );
  return DbData(
    oshis: [oshi1, oshi2],
    goods: [
      Goods(id: 'g1', oshiId: 'o1', name: 'アクリルスタンド', price: 1650,
          purchaseDate: now.subtract(const Duration(days: 5)),
          category: GoodsCategory.acrylic),
      Goods(id: 'g2', oshiId: 'o1', name: '推し色ペンライト', price: 3300,
          purchaseDate: now.subtract(const Duration(days: 12)),
          category: GoodsCategory.penlight),
      Goods(id: 'g3', oshiId: 'o1', name: 'トレカ 第3弾', price: 550,
          purchaseDate: now.subtract(const Duration(days: 20)),
          category: GoodsCategory.photo),
    ],
    expenses: [
      Expense(id: 'e1', oshiId: 'o1', amount: 1650, category: ExpenseCategory.goods, date: now.subtract(const Duration(days: 5))),
      Expense(id: 'e2', oshiId: 'o1', amount: 4500, category: ExpenseCategory.ticket, date: now.subtract(const Duration(days: 8))),
      Expense(id: 'e3', oshiId: 'o1', amount: 2050, category: ExpenseCategory.travel, date: now.subtract(const Duration(days: 8))),
      Expense(id: 'e4', oshiId: 'o2', amount: 3000, category: ExpenseCategory.goods, date: now.subtract(const Duration(days: 3))),
    ],
    goals: [
      SavingGoal(id: 's1', oshiId: 'o1', title: '全国ツアー遠征費', targetAmount: 50000, currentAmount: 32000),
    ],
    events: [
      EventItem(id: 'v1', oshiId: 'o1', title: '春のワンマンライブ', type: EventType.live,
          dateTime: now.add(const Duration(days: 6)), location: '日本武道館'),
      EventItem(id: 'v2', oshiId: 'o1', title: '2nd写真集 発売', type: EventType.release,
          dateTime: now.add(const Duration(days: 18))),
      EventItem(id: 'v3', oshiId: 'o2', title: 'ファンミ チケット販売', type: EventType.ticketSale,
          dateTime: now.add(const Duration(days: 2))),
    ],
    feeds: [
      FeedItem(id: 'f1', oshiId: 'o1', source: FeedSource.youtube, title: '【新曲MV】きらめきデイズ 公開！', url: 'https://example.com/1', publishedAt: now.subtract(const Duration(hours: 5))),
      FeedItem(id: 'f2', oshiId: 'o1', source: FeedSource.web, title: '人気アイドル、初の冠番組がスタート', url: 'https://example.com/2', publishedAt: now.subtract(const Duration(days: 1)), isRead: true),
    ],
  );
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ja_JP');

  final store = LocalStore(MemoryStoreBackend(jsonEncode(_demoData().toJson())));
  await store.load();
  final prefs = await SharedPreferences.getInstance();
  final notifications = NotificationService();

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
