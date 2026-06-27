import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/models.dart';

/// 推し情報の取得元を抽象化する。
///
/// - MVP: [LocalFeedRepository] (手動登録のみ。自動取得は何もしない)
/// - 次フェーズ: [RemoteFeedRepository] に差し替え、Xserver(共用) の PHP REST API
///   (`GET /feed?oshi=...&since=...`) から YouTube/RSS/Web検索の収集結果を取得。
abstract class FeedRepository {
  /// 指定推しの新着フィードを取得する。MVP では空を返す。
  Future<List<FeedItem>> fetchNew(Oshi oshi, {DateTime? since});

  /// 自動収集に対応しているか(UI 表示の出し分け用)。
  bool get supportsAutoFetch;
}

/// MVP 用。自動取得は行わず、手動登録のみ運用する。
class LocalFeedRepository implements FeedRepository {
  @override
  bool get supportsAutoFetch => false;

  @override
  Future<List<FeedItem>> fetchNew(Oshi oshi, {DateTime? since}) async => const [];
}

/// 次フェーズで有効化するリモート実装の雛形。
/// baseUrl に Xserver 上の API ディレクトリ(例: https://example.xsrv.jp/oshikatsu/api)
/// を設定し、差し替えるだけで動く。サーバー側は server/ 配下を参照。
class RemoteFeedRepository implements FeedRepository {
  RemoteFeedRepository(this.baseUrl, {this.apiToken, Dio? dio})
      : _dio = dio ?? Dio();

  final String baseUrl;
  final String? apiToken;
  final Dio _dio;

  @override
  bool get supportsAutoFetch => true;

  @override
  Future<List<FeedItem>> fetchNew(Oshi oshi, {DateTime? since}) async {
    final res = await _dio.get(
      '$baseUrl/feed.php',
      queryParameters: {
        'oshi': oshi.id,
        if (since != null) 'since': since.toIso8601String(),
      },
      options: apiToken == null
          ? null
          : Options(headers: {'X-Api-Token': apiToken}),
    );
    final list = (res.data as List?) ?? const [];
    return list
        .whereType<Map>()
        .map((e) => FeedItem.fromJson(e.cast<String, dynamic>()))
        .toList();
  }
}

/// 現在使用するリポジトリ。次フェーズでは RemoteFeedRepository に override する。
final feedRepositoryProvider =
    Provider<FeedRepository>((ref) => LocalFeedRepository());
