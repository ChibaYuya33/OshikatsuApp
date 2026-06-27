// アプリ全体のデータモデル。
// ローカル(JSON)保存のため、各モデルは toJson / fromJson を持つ。
// 将来 Isar/Drift 等へ差し替える場合もこのモデル定義を流用できる。

/// 推し。すべての記録(グッズ/支出/イベント/フィード)はこの id に紐づく。
class Oshi {
  final String id;
  final String name;

  /// 推し色 (ARGB int)。テーマカラーに使用。
  final int themeColor;

  /// 誕生日 (任意)。カウントダウンに使用。
  final DateTime? birthday;

  /// プロフィール写真のローカルパス (任意)。
  final String? photoPath;

  /// 次フェーズの自動収集で使う公式サイト/RSS等のURL一覧。
  final List<String> officialUrls;

  /// 次フェーズの YouTube 収集で使うチャンネルID (任意)。
  final String? youtubeChannelId;

  final DateTime createdAt;

  const Oshi({
    required this.id,
    required this.name,
    required this.themeColor,
    this.birthday,
    this.photoPath,
    this.officialUrls = const [],
    this.youtubeChannelId,
    required this.createdAt,
  });

  Oshi copyWith({
    String? name,
    int? themeColor,
    DateTime? birthday,
    bool clearBirthday = false,
    String? photoPath,
    bool clearPhoto = false,
    List<String>? officialUrls,
    String? youtubeChannelId,
  }) {
    return Oshi(
      id: id,
      name: name ?? this.name,
      themeColor: themeColor ?? this.themeColor,
      birthday: clearBirthday ? null : (birthday ?? this.birthday),
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      officialUrls: officialUrls ?? this.officialUrls,
      youtubeChannelId: youtubeChannelId ?? this.youtubeChannelId,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'themeColor': themeColor,
        'birthday': birthday?.toIso8601String(),
        'photoPath': photoPath,
        'officialUrls': officialUrls,
        'youtubeChannelId': youtubeChannelId,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Oshi.fromJson(Map<String, dynamic> j) => Oshi(
        id: j['id'] as String,
        name: j['name'] as String,
        themeColor: j['themeColor'] as int,
        birthday: _parseDate(j['birthday']),
        photoPath: j['photoPath'] as String?,
        officialUrls:
            (j['officialUrls'] as List?)?.map((e) => e as String).toList() ??
                const [],
        youtubeChannelId: j['youtubeChannelId'] as String?,
        createdAt: _parseDate(j['createdAt']) ?? DateTime.now(),
      );
}

/// グッズの種別。
enum GoodsCategory {
  acrylic('アクスタ'),
  photo('写真/ブロマイド'),
  badge('缶バッジ'),
  penlight('ペンライト'),
  clothing('衣類'),
  cd('CD/DVD'),
  book('雑誌/写真集'),
  other('その他');

  const GoodsCategory(this.label);
  final String label;

  static GoodsCategory fromName(String? name) =>
      GoodsCategory.values.firstWhere((e) => e.name == name,
          orElse: () => GoodsCategory.other);
}

/// グッズ。同一推し内で同名のものは登録時に重複警告を出す(「持ってた」防止)。
class Goods {
  final String id;
  final String oshiId;
  final String name;
  final String? photoPath;
  final int price;
  final DateTime purchaseDate;
  final GoodsCategory category;

  /// 所持中か。交換/譲渡で手放した場合 false。
  final bool owned;
  final String? memo;

  const Goods({
    required this.id,
    required this.oshiId,
    required this.name,
    this.photoPath,
    required this.price,
    required this.purchaseDate,
    this.category = GoodsCategory.other,
    this.owned = true,
    this.memo,
  });

  Goods copyWith({
    String? name,
    String? photoPath,
    bool clearPhoto = false,
    int? price,
    DateTime? purchaseDate,
    GoodsCategory? category,
    bool? owned,
    String? memo,
  }) {
    return Goods(
      id: id,
      oshiId: oshiId,
      name: name ?? this.name,
      photoPath: clearPhoto ? null : (photoPath ?? this.photoPath),
      price: price ?? this.price,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      category: category ?? this.category,
      owned: owned ?? this.owned,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'oshiId': oshiId,
        'name': name,
        'photoPath': photoPath,
        'price': price,
        'purchaseDate': purchaseDate.toIso8601String(),
        'category': category.name,
        'owned': owned,
        'memo': memo,
      };

  factory Goods.fromJson(Map<String, dynamic> j) => Goods(
        id: j['id'] as String,
        oshiId: j['oshiId'] as String,
        name: j['name'] as String,
        photoPath: j['photoPath'] as String?,
        price: (j['price'] as num).toInt(),
        purchaseDate: _parseDate(j['purchaseDate']) ?? DateTime.now(),
        category: GoodsCategory.fromName(j['category'] as String?),
        owned: j['owned'] as bool? ?? true,
        memo: j['memo'] as String?,
      );
}

/// 支出の種別。
enum ExpenseCategory {
  goods('グッズ'),
  ticket('チケット'),
  travel('遠征/交通'),
  fanclub('ファンクラブ'),
  other('その他');

  const ExpenseCategory(this.label);
  final String label;

  static ExpenseCategory fromName(String? name) =>
      ExpenseCategory.values.firstWhere((e) => e.name == name,
          orElse: () => ExpenseCategory.other);
}

/// 推し活支出。グッズ登録時に自動連動はせず、独立して記録する。
class Expense {
  final String id;
  final String oshiId;
  final int amount;
  final ExpenseCategory category;
  final DateTime date;
  final String? memo;

  const Expense({
    required this.id,
    required this.oshiId,
    required this.amount,
    this.category = ExpenseCategory.other,
    required this.date,
    this.memo,
  });

  Expense copyWith({
    int? amount,
    ExpenseCategory? category,
    DateTime? date,
    String? memo,
  }) {
    return Expense(
      id: id,
      oshiId: oshiId,
      amount: amount ?? this.amount,
      category: category ?? this.category,
      date: date ?? this.date,
      memo: memo ?? this.memo,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'oshiId': oshiId,
        'amount': amount,
        'category': category.name,
        'date': date.toIso8601String(),
        'memo': memo,
      };

  factory Expense.fromJson(Map<String, dynamic> j) => Expense(
        id: j['id'] as String,
        oshiId: j['oshiId'] as String,
        amount: (j['amount'] as num).toInt(),
        category: ExpenseCategory.fromName(j['category'] as String?),
        date: _parseDate(j['date']) ?? DateTime.now(),
        memo: j['memo'] as String?,
      );
}

/// 推し活貯金の目標。
class SavingGoal {
  final String id;
  final String oshiId;
  final String title;
  final int targetAmount;
  final int currentAmount;
  final DateTime? deadline;

  const SavingGoal({
    required this.id,
    required this.oshiId,
    required this.title,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
  });

  double get progress =>
      targetAmount <= 0 ? 0 : (currentAmount / targetAmount).clamp(0.0, 1.0);

  SavingGoal copyWith({
    String? title,
    int? targetAmount,
    int? currentAmount,
    DateTime? deadline,
    bool clearDeadline = false,
  }) {
    return SavingGoal(
      id: id,
      oshiId: oshiId,
      title: title ?? this.title,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'oshiId': oshiId,
        'title': title,
        'targetAmount': targetAmount,
        'currentAmount': currentAmount,
        'deadline': deadline?.toIso8601String(),
      };

  factory SavingGoal.fromJson(Map<String, dynamic> j) => SavingGoal(
        id: j['id'] as String,
        oshiId: j['oshiId'] as String,
        title: j['title'] as String,
        targetAmount: (j['targetAmount'] as num).toInt(),
        currentAmount: (j['currentAmount'] as num?)?.toInt() ?? 0,
        deadline: _parseDate(j['deadline']),
      );
}

/// イベントの種別。
enum EventType {
  live('ライブ/公演'),
  ticketSale('チケット販売'),
  release('発売/リリース'),
  birthday('誕生日'),
  broadcast('配信/放送'),
  other('その他');

  const EventType(this.label);
  final String label;

  static EventType fromName(String? name) => EventType.values
      .firstWhere((e) => e.name == name, orElse: () => EventType.other);
}

/// イベント。カレンダー表示・通知・参戦記録に使用。
class EventItem {
  final String id;
  final String oshiId;
  final String title;
  final EventType type;
  final DateTime dateTime;
  final String? location;

  /// チケット販売開始日時 (任意)。設定すると通知される。
  final DateTime? ticketSaleDate;

  /// イベント本番の何日前に通知するか (0 で通知しない)。
  final int notifyBeforeDays;

  /// 参戦記録。
  final bool isAttended;
  final String? setlistMemo;
  final String? seat;
  final List<String> photoPaths;

  const EventItem({
    required this.id,
    required this.oshiId,
    required this.title,
    this.type = EventType.other,
    required this.dateTime,
    this.location,
    this.ticketSaleDate,
    this.notifyBeforeDays = 1,
    this.isAttended = false,
    this.setlistMemo,
    this.seat,
    this.photoPaths = const [],
  });

  EventItem copyWith({
    String? title,
    EventType? type,
    DateTime? dateTime,
    String? location,
    DateTime? ticketSaleDate,
    bool clearTicketSale = false,
    int? notifyBeforeDays,
    bool? isAttended,
    String? setlistMemo,
    String? seat,
    List<String>? photoPaths,
  }) {
    return EventItem(
      id: id,
      oshiId: oshiId,
      title: title ?? this.title,
      type: type ?? this.type,
      dateTime: dateTime ?? this.dateTime,
      location: location ?? this.location,
      ticketSaleDate:
          clearTicketSale ? null : (ticketSaleDate ?? this.ticketSaleDate),
      notifyBeforeDays: notifyBeforeDays ?? this.notifyBeforeDays,
      isAttended: isAttended ?? this.isAttended,
      setlistMemo: setlistMemo ?? this.setlistMemo,
      seat: seat ?? this.seat,
      photoPaths: photoPaths ?? this.photoPaths,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'oshiId': oshiId,
        'title': title,
        'type': type.name,
        'dateTime': dateTime.toIso8601String(),
        'location': location,
        'ticketSaleDate': ticketSaleDate?.toIso8601String(),
        'notifyBeforeDays': notifyBeforeDays,
        'isAttended': isAttended,
        'setlistMemo': setlistMemo,
        'seat': seat,
        'photoPaths': photoPaths,
      };

  factory EventItem.fromJson(Map<String, dynamic> j) => EventItem(
        id: j['id'] as String,
        oshiId: j['oshiId'] as String,
        title: j['title'] as String,
        type: EventType.fromName(j['type'] as String?),
        dateTime: _parseDate(j['dateTime']) ?? DateTime.now(),
        location: j['location'] as String?,
        ticketSaleDate: _parseDate(j['ticketSaleDate']),
        notifyBeforeDays: (j['notifyBeforeDays'] as num?)?.toInt() ?? 1,
        isAttended: j['isAttended'] as bool? ?? false,
        setlistMemo: j['setlistMemo'] as String?,
        seat: j['seat'] as String?,
        photoPaths:
            (j['photoPaths'] as List?)?.map((e) => e as String).toList() ??
                const [],
      );
}

/// フィード情報の取得元。次フェーズの自動収集で youtube/rss/web が使われる。
enum FeedSource {
  manual('手動'),
  youtube('YouTube'),
  rss('RSS/ブログ'),
  web('Web/ニュース');

  const FeedSource(this.label);
  final String label;

  static FeedSource fromName(String? name) => FeedSource.values
      .firstWhere((e) => e.name == name, orElse: () => FeedSource.manual);
}

/// 推し情報フィード。MVPは手動URL登録。次フェーズで収集APIの結果を保存。
class FeedItem {
  final String id;
  final String oshiId;
  final FeedSource source;
  final String title;
  final String url;
  final DateTime publishedAt;
  final String? thumbnailUrl;
  final bool isRead;
  final bool isBookmarked;

  const FeedItem({
    required this.id,
    required this.oshiId,
    this.source = FeedSource.manual,
    required this.title,
    required this.url,
    required this.publishedAt,
    this.thumbnailUrl,
    this.isRead = false,
    this.isBookmarked = false,
  });

  FeedItem copyWith({
    String? title,
    String? url,
    FeedSource? source,
    DateTime? publishedAt,
    String? thumbnailUrl,
    bool? isRead,
    bool? isBookmarked,
  }) {
    return FeedItem(
      id: id,
      oshiId: oshiId,
      source: source ?? this.source,
      title: title ?? this.title,
      url: url ?? this.url,
      publishedAt: publishedAt ?? this.publishedAt,
      thumbnailUrl: thumbnailUrl ?? this.thumbnailUrl,
      isRead: isRead ?? this.isRead,
      isBookmarked: isBookmarked ?? this.isBookmarked,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'oshiId': oshiId,
        'source': source.name,
        'title': title,
        'url': url,
        'publishedAt': publishedAt.toIso8601String(),
        'thumbnailUrl': thumbnailUrl,
        'isRead': isRead,
        'isBookmarked': isBookmarked,
      };

  factory FeedItem.fromJson(Map<String, dynamic> j) => FeedItem(
        id: j['id'] as String,
        oshiId: j['oshiId'] as String,
        source: FeedSource.fromName(j['source'] as String?),
        title: j['title'] as String,
        url: j['url'] as String,
        publishedAt: _parseDate(j['publishedAt']) ?? DateTime.now(),
        thumbnailUrl: j['thumbnailUrl'] as String?,
        isRead: j['isRead'] as bool? ?? false,
        isBookmarked: j['isBookmarked'] as bool? ?? false,
      );
}

DateTime? _parseDate(dynamic v) {
  if (v == null) return null;
  return DateTime.tryParse(v as String);
}
