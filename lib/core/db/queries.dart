// 集計・判定ロジックを純粋関数として集約。
// Flutter に依存しないため、単体テストで直接検証できる。

import 'models.dart';

/// 既定の月予算 (円)。要望の「月¥10,000まで」。
const int kDefaultMonthlyBudget = 10000;

/// 予算に対する警告を出し始める割合 (80%)。
const double kBudgetWarnRatio = 0.8;

/// 文字列を比較用に正規化(前後空白除去 + 小文字化)。
String normalizeName(String s) => s.trim().toLowerCase();

/// 同一推し内に同名グッズが既に存在するか(「持ってた」防止)。
/// [excludeId] を渡すと編集時に自分自身を除外できる。
bool hasDuplicateGoods(
  List<Goods> goods,
  String oshiId,
  String name, {
  String? excludeId,
}) {
  final target = normalizeName(name);
  if (target.isEmpty) return false;
  return goods.any((g) =>
      g.id != excludeId &&
      g.oshiId == oshiId &&
      normalizeName(g.name) == target);
}

/// 指定推し内で名前が重複する既存グッズを返す(なければ空)。
List<Goods> duplicateGoods(
  List<Goods> goods,
  String oshiId,
  String name, {
  String? excludeId,
}) {
  final target = normalizeName(name);
  if (target.isEmpty) return const [];
  return goods
      .where((g) =>
          g.id != excludeId &&
          g.oshiId == oshiId &&
          normalizeName(g.name) == target)
      .toList();
}

bool _sameMonth(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month;

/// 指定月の支出合計。[oshiId] が null なら全推し合算。
int monthlyExpenseTotal(
  List<Expense> expenses,
  DateTime month, {
  String? oshiId,
}) {
  return expenses
      .where((e) =>
          _sameMonth(e.date, month) && (oshiId == null || e.oshiId == oshiId))
      .fold(0, (sum, e) => sum + e.amount);
}

/// 予算の状態。
enum BudgetStatus { ok, warning, over }

class BudgetResult {
  final int spent;
  final int limit;
  final BudgetStatus status;
  const BudgetResult(this.spent, this.limit, this.status);

  int get remaining => limit - spent;
  double get ratio => limit <= 0 ? 0 : spent / limit;
}

/// 月予算の判定。上限超過で over、警告割合超えで warning。
BudgetResult evaluateBudget(int spent, int limit) {
  if (limit <= 0) return BudgetResult(spent, limit, BudgetStatus.ok);
  if (spent > limit) return BudgetResult(spent, limit, BudgetStatus.over);
  if (spent >= limit * kBudgetWarnRatio) {
    return BudgetResult(spent, limit, BudgetStatus.warning);
  }
  return BudgetResult(spent, limit, BudgetStatus.ok);
}

/// 推し別の支出合計(全期間)。お布施累計に使用。表示はマップで返す。
Map<String, int> totalByOshi(List<Expense> expenses) {
  final map = <String, int>{};
  for (final e in expenses) {
    map[e.oshiId] = (map[e.oshiId] ?? 0) + e.amount;
  }
  return map;
}

/// カテゴリ別の支出合計(指定月)。円グラフに使用。
Map<ExpenseCategory, int> totalByCategory(
  List<Expense> expenses,
  DateTime month, {
  String? oshiId,
}) {
  final map = <ExpenseCategory, int>{};
  for (final e in expenses.where((e) =>
      _sameMonth(e.date, month) &&
      (oshiId == null || e.oshiId == oshiId))) {
    map[e.category] = (map[e.category] ?? 0) + e.amount;
  }
  return map;
}

/// 直近 [months] か月分の月別支出合計を、古い順のリストで返す(棒グラフ用)。
List<MonthlyTotal> monthlyTotals(
  List<Expense> expenses,
  DateTime now, {
  int months = 6,
  String? oshiId,
}) {
  final result = <MonthlyTotal>[];
  for (var i = months - 1; i >= 0; i--) {
    final m = DateTime(now.year, now.month - i, 1);
    result.add(MonthlyTotal(m, monthlyExpenseTotal(expenses, m, oshiId: oshiId)));
  }
  return result;
}

class MonthlyTotal {
  final DateTime month;
  final int total;
  const MonthlyTotal(this.month, this.total);
}

/// 今日から見た次回の誕生日までの日数(誕生日当日は0)。
int? daysUntilBirthday(DateTime? birthday, DateTime now) {
  if (birthday == null) return null;
  final today = DateTime(now.year, now.month, now.day);
  var next = DateTime(today.year, birthday.month, birthday.day);
  if (next.isBefore(today)) {
    next = DateTime(today.year + 1, birthday.month, birthday.day);
  }
  return next.difference(today).inDays;
}

/// 指定日時以降の直近イベントを日付順で返す。
List<EventItem> upcomingEvents(
  List<EventItem> events,
  DateTime now, {
  String? oshiId,
  int limit = 5,
}) {
  final list = events
      .where((e) =>
          e.dateTime.isAfter(now) && (oshiId == null || e.oshiId == oshiId))
      .toList()
    ..sort((a, b) => a.dateTime.compareTo(b.dateTime));
  return list.take(limit).toList();
}
