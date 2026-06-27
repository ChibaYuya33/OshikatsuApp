import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../db/local_store.dart';
import '../db/models.dart';
import '../notifications/notification_service.dart';
import 'settings_providers.dart';

const _uuid = Uuid();
String newId() => _uuid.v4();

/// 起動時に load 済みの [LocalStore] を注入する。main() で override する。
final localStoreProvider = Provider<LocalStore>(
  (ref) => throw UnimplementedError('localStoreProvider must be overridden'),
);

/// 通知サービス。main() で override する(テストでは no-op を注入可能)。
final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// アプリの全データを保持する Notifier。state を差し替えて UI を再構築する。
final appProvider =
    NotifierProvider<AppNotifier, DbData>(AppNotifier.new);

class AppNotifier extends Notifier<DbData> {
  late final LocalStore _store;
  late final NotificationService _notifications;

  @override
  DbData build() {
    _store = ref.read(localStoreProvider);
    _notifications = ref.read(notificationServiceProvider);
    return _snapshot();
  }

  DbData _snapshot() {
    final d = _store.data;
    return DbData(
      oshis: List.of(d.oshis),
      goods: List.of(d.goods),
      expenses: List.of(d.expenses),
      goals: List.of(d.goals),
      events: List.of(d.events),
      feeds: List.of(d.feeds),
    );
  }

  Future<void> _commit() async {
    state = _snapshot();
    await _store.save();
  }

  // ---- Oshi ----
  Future<Oshi> addOshi({
    required String name,
    required int themeColor,
    DateTime? birthday,
    String? photoPath,
    List<String> officialUrls = const [],
    String? youtubeChannelId,
  }) async {
    final oshi = Oshi(
      id: newId(),
      name: name,
      themeColor: themeColor,
      birthday: birthday,
      photoPath: photoPath,
      officialUrls: officialUrls,
      youtubeChannelId: youtubeChannelId,
      createdAt: DateTime.now(),
    );
    _store.data.oshis.add(oshi);
    await _commit();
    return oshi;
  }

  Future<void> updateOshi(Oshi oshi) async {
    final i = _store.data.oshis.indexWhere((e) => e.id == oshi.id);
    if (i >= 0) _store.data.oshis[i] = oshi;
    await _commit();
  }

  /// 推し削除。紐づくグッズ/支出/イベント/フィード/目標も連動削除する。
  Future<void> deleteOshi(String oshiId) async {
    final d = _store.data;
    d.oshis.removeWhere((e) => e.id == oshiId);
    d.goods.removeWhere((e) => e.oshiId == oshiId);
    d.expenses.removeWhere((e) => e.oshiId == oshiId);
    d.goals.removeWhere((e) => e.oshiId == oshiId);
    for (final ev in d.events.where((e) => e.oshiId == oshiId)) {
      await _notifications.cancelForEvent(ev.id);
    }
    d.events.removeWhere((e) => e.oshiId == oshiId);
    d.feeds.removeWhere((e) => e.oshiId == oshiId);
    await _commit();
  }

  Oshi? oshiById(String? id) {
    if (id == null) return null;
    for (final o in _store.data.oshis) {
      if (o.id == id) return o;
    }
    return null;
  }

  // ---- Goods ----
  Future<void> addGoods(Goods g) async {
    _store.data.goods.add(g);
    await _commit();
  }

  Future<void> updateGoods(Goods g) async {
    final i = _store.data.goods.indexWhere((e) => e.id == g.id);
    if (i >= 0) _store.data.goods[i] = g;
    await _commit();
  }

  Future<void> deleteGoods(String id) async {
    _store.data.goods.removeWhere((e) => e.id == id);
    await _commit();
  }

  // ---- Expense ----
  Future<void> addExpense(Expense e) async {
    _store.data.expenses.add(e);
    await _commit();
  }

  Future<void> updateExpense(Expense e) async {
    final i = _store.data.expenses.indexWhere((x) => x.id == e.id);
    if (i >= 0) _store.data.expenses[i] = e;
    await _commit();
  }

  Future<void> deleteExpense(String id) async {
    _store.data.expenses.removeWhere((e) => e.id == id);
    await _commit();
  }

  // ---- SavingGoal ----
  Future<void> addGoal(SavingGoal g) async {
    _store.data.goals.add(g);
    await _commit();
  }

  Future<void> updateGoal(SavingGoal g) async {
    final i = _store.data.goals.indexWhere((e) => e.id == g.id);
    if (i >= 0) _store.data.goals[i] = g;
    await _commit();
  }

  Future<void> deleteGoal(String id) async {
    _store.data.goals.removeWhere((e) => e.id == id);
    await _commit();
  }

  // ---- EventItem ----
  Future<void> addEvent(EventItem e) async {
    _store.data.events.add(e);
    await _notifications.scheduleForEvent(e);
    await _commit();
  }

  Future<void> updateEvent(EventItem e) async {
    final i = _store.data.events.indexWhere((x) => x.id == e.id);
    if (i >= 0) _store.data.events[i] = e;
    await _notifications.cancelForEvent(e.id);
    await _notifications.scheduleForEvent(e);
    await _commit();
  }

  Future<void> deleteEvent(String id) async {
    _store.data.events.removeWhere((e) => e.id == id);
    await _notifications.cancelForEvent(id);
    await _commit();
  }

  // ---- FeedItem ----
  Future<void> addFeed(FeedItem f) async {
    _store.data.feeds.add(f);
    await _commit();
  }

  Future<void> updateFeed(FeedItem f) async {
    final i = _store.data.feeds.indexWhere((e) => e.id == f.id);
    if (i >= 0) _store.data.feeds[i] = f;
    await _commit();
  }

  Future<void> deleteFeed(String id) async {
    _store.data.feeds.removeWhere((e) => e.id == id);
    await _commit();
  }

  // ---- Backup ----
  String exportJson() => _store.exportJson();

  Future<void> importJson(String raw) async {
    await _store.importJson(raw);
    await _commit();
  }
}

/// 現在テーマに使う「選択中の推し」。設定の selectedOshiId に対応。
final selectedOshiProvider = Provider<Oshi?>((ref) {
  final data = ref.watch(appProvider);
  final selectedId = ref.watch(settingsProvider).selectedOshiId;
  final list = data.oshis;
  if (list.isEmpty) return null;
  for (final o in list) {
    if (o.id == selectedId) return o;
  }
  return list.first;
});

/// 推しを id 引きするための簡易マップ。
final oshiMapProvider = Provider<Map<String, Oshi>>((ref) {
  final data = ref.watch(appProvider);
  return {for (final o in data.oshis) o.id: o};
});

/// 推し色 (選択中の推しが無ければ既定のニュートラルなネイビー)。
Color resolveSeedColor(Oshi? oshi) =>
    oshi != null ? Color(oshi.themeColor) : const Color(0xFF44597A);
