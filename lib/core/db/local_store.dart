import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

import 'models.dart';

/// アプリ内の全データを保持するコンテナ。JSONで丸ごと保存する。
/// 個人利用想定(各エンティティ数百件程度)のため、全件メモリ保持で十分。
class DbData {
  List<Oshi> oshis;
  List<Goods> goods;
  List<Expense> expenses;
  List<SavingGoal> goals;
  List<EventItem> events;
  List<FeedItem> feeds;

  DbData({
    List<Oshi>? oshis,
    List<Goods>? goods,
    List<Expense>? expenses,
    List<SavingGoal>? goals,
    List<EventItem>? events,
    List<FeedItem>? feeds,
  })  : oshis = oshis ?? [],
        goods = goods ?? [],
        expenses = expenses ?? [],
        goals = goals ?? [],
        events = events ?? [],
        feeds = feeds ?? [];

  Map<String, dynamic> toJson() => {
        'version': 1,
        'oshis': oshis.map((e) => e.toJson()).toList(),
        'goods': goods.map((e) => e.toJson()).toList(),
        'expenses': expenses.map((e) => e.toJson()).toList(),
        'goals': goals.map((e) => e.toJson()).toList(),
        'events': events.map((e) => e.toJson()).toList(),
        'feeds': feeds.map((e) => e.toJson()).toList(),
      };

  factory DbData.fromJson(Map<String, dynamic> j) => DbData(
        oshis: _list(j['oshis'], Oshi.fromJson),
        goods: _list(j['goods'], Goods.fromJson),
        expenses: _list(j['expenses'], Expense.fromJson),
        goals: _list(j['goals'], SavingGoal.fromJson),
        events: _list(j['events'], EventItem.fromJson),
        feeds: _list(j['feeds'], FeedItem.fromJson),
      );

  static List<T> _list<T>(
      dynamic raw, T Function(Map<String, dynamic>) fromJson) {
    if (raw is! List) return [];
    return raw
        .whereType<Map>()
        .map((e) => fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}

/// 永続化の差し替えポイント。
/// 実機/Webでは [FileStoreBackend]、テストでは [MemoryStoreBackend] を使う。
abstract class StoreBackend {
  Future<String?> read();
  Future<void> write(String data);
}

/// アプリのドキュメント領域に1ファイルで保存する実装。
class FileStoreBackend implements StoreBackend {
  static const _fileName = 'oshikatsu_db.json';

  Future<File> _file() async {
    final dir = await getApplicationDocumentsDirectory();
    return File('${dir.path}/$_fileName');
  }

  @override
  Future<String?> read() async {
    try {
      final f = await _file();
      if (!await f.exists()) return null;
      return await f.readAsString();
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> write(String data) async {
    final f = await _file();
    await f.writeAsString(data, flush: true);
  }
}

/// テスト/フォールバック用のインメモリ実装。
class MemoryStoreBackend implements StoreBackend {
  String? _data;
  MemoryStoreBackend([this._data]);

  @override
  Future<String?> read() async => _data;

  @override
  Future<void> write(String data) async => _data = data;
}

/// JSONバックエンドを使ったローカルストア。
class LocalStore {
  LocalStore(this._backend);

  final StoreBackend _backend;
  DbData _data = DbData();

  DbData get data => _data;

  Future<void> load() async {
    final raw = await _backend.read();
    if (raw == null || raw.isEmpty) {
      _data = DbData();
      return;
    }
    try {
      _data = DbData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      _data = DbData();
    }
  }

  Future<void> save() async {
    await _backend.write(jsonEncode(_data.toJson()));
  }

  /// バックアップ用: 全データをJSON文字列で書き出す。
  String exportJson() => jsonEncode(_data.toJson());

  /// バックアップ復元: JSON文字列を読み込み、保存する。失敗時は例外。
  Future<void> importJson(String raw) async {
    _data = DbData.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    await save();
  }
}
