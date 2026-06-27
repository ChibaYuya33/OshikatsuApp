import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../db/queries.dart';

/// 起動時に取得済みの [SharedPreferences] を注入する。main() で override。
final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPrefsProvider must be overridden'),
);

class AppSettings {
  final ThemeMode themeMode;
  final String? selectedOshiId;
  final int monthlyBudget;

  /// 自動収集サーバー(任意)。空文字 = 未設定でローカル(手動登録)運用。
  /// 例: https://example.xsrv.jp/oshikatsu/api
  final String feedApiBaseUrl;
  final String feedApiToken;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.selectedOshiId,
    this.monthlyBudget = kDefaultMonthlyBudget,
    this.feedApiBaseUrl = '',
    this.feedApiToken = '',
  });

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? selectedOshiId,
    bool clearSelectedOshi = false,
    int? monthlyBudget,
    String? feedApiBaseUrl,
    String? feedApiToken,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      selectedOshiId:
          clearSelectedOshi ? null : (selectedOshiId ?? this.selectedOshiId),
      monthlyBudget: monthlyBudget ?? this.monthlyBudget,
      feedApiBaseUrl: feedApiBaseUrl ?? this.feedApiBaseUrl,
      feedApiToken: feedApiToken ?? this.feedApiToken,
    );
  }
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

class SettingsNotifier extends Notifier<AppSettings> {
  static const _kThemeMode = 'themeMode';
  static const _kSelectedOshi = 'selectedOshiId';
  static const _kMonthlyBudget = 'monthlyBudget';
  static const _kFeedApiBaseUrl = 'feedApiBaseUrl';
  static const _kFeedApiToken = 'feedApiToken';

  late final SharedPreferences _prefs;

  @override
  AppSettings build() {
    _prefs = ref.read(sharedPrefsProvider);
    return AppSettings(
      themeMode: ThemeMode.values[
          (_prefs.getInt(_kThemeMode) ?? ThemeMode.system.index)
              .clamp(0, ThemeMode.values.length - 1)],
      selectedOshiId: _prefs.getString(_kSelectedOshi),
      monthlyBudget: _prefs.getInt(_kMonthlyBudget) ?? kDefaultMonthlyBudget,
      feedApiBaseUrl: _prefs.getString(_kFeedApiBaseUrl) ?? '',
      feedApiToken: _prefs.getString(_kFeedApiToken) ?? '',
    );
  }

  /// 自動収集サーバーの設定を保存する。URL末尾の `/` は除去して正規化。
  Future<void> setFeedApi(String baseUrl, String token) async {
    final url = baseUrl.trim().replaceAll(RegExp(r'/+$'), '');
    final tok = token.trim();
    state = state.copyWith(feedApiBaseUrl: url, feedApiToken: tok);
    await _prefs.setString(_kFeedApiBaseUrl, url);
    await _prefs.setString(_kFeedApiToken, tok);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setInt(_kThemeMode, mode.index);
  }

  Future<void> setSelectedOshi(String? id) async {
    state = state.copyWith(selectedOshiId: id, clearSelectedOshi: id == null);
    if (id == null) {
      await _prefs.remove(_kSelectedOshi);
    } else {
      await _prefs.setString(_kSelectedOshi, id);
    }
  }

  Future<void> setMonthlyBudget(int yen) async {
    state = state.copyWith(monthlyBudget: yen);
    await _prefs.setInt(_kMonthlyBudget, yen);
  }
}
