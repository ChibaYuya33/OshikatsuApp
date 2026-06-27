import 'package:flutter_test/flutter_test.dart';
import 'package:oshikatsu_app/core/db/models.dart';
import 'package:oshikatsu_app/core/db/queries.dart';

Goods _goods(String oshiId, String name) => Goods(
      id: '$oshiId-$name',
      oshiId: oshiId,
      name: name,
      price: 1000,
      purchaseDate: DateTime(2026, 6, 1),
    );

Expense _expense(String oshiId, int amount, DateTime date,
        [ExpenseCategory cat = ExpenseCategory.goods]) =>
    Expense(
      id: '$oshiId-${date.day}-$amount',
      oshiId: oshiId,
      amount: amount,
      date: date,
      category: cat,
    );

void main() {
  group('重複グッズ検知 (持ってた防止)', () {
    final goods = [_goods('o1', 'アクスタA'), _goods('o2', 'アクスタA')];

    test('同一推し内の同名は重複と判定', () {
      expect(hasDuplicateGoods(goods, 'o1', 'アクスタA'), isTrue);
    });

    test('大文字小文字・前後空白を無視', () {
      expect(hasDuplicateGoods(goods, 'o1', '  アクスタA '), isTrue);
    });

    test('別の推しの同名は重複としない', () {
      expect(hasDuplicateGoods(goods, 'o3', 'アクスタA'), isFalse);
    });

    test('編集時は自分自身を除外できる', () {
      expect(
        hasDuplicateGoods(goods, 'o1', 'アクスタA', excludeId: 'o1-アクスタA'),
        isFalse,
      );
    });
  });

  group('月予算の判定', () {
    test('上限超過で over', () {
      final r = evaluateBudget(12000, 10000);
      expect(r.status, BudgetStatus.over);
      expect(r.remaining, -2000);
    });

    test('80%以上で warning', () {
      expect(evaluateBudget(8500, 10000).status, BudgetStatus.warning);
    });

    test('80%未満は ok', () {
      expect(evaluateBudget(5000, 10000).status, BudgetStatus.ok);
    });
  });

  group('支出集計', () {
    final now = DateTime(2026, 6, 15);
    final expenses = [
      _expense('o1', 3000, DateTime(2026, 6, 1)),
      _expense('o1', 2000, DateTime(2026, 6, 10), ExpenseCategory.ticket),
      _expense('o2', 5000, DateTime(2026, 6, 5)),
      _expense('o1', 9999, DateTime(2026, 5, 20)), // 前月
    ];

    test('指定月・指定推しの合計', () {
      expect(monthlyExpenseTotal(expenses, now, oshiId: 'o1'), 5000);
    });

    test('指定月の全推し合算', () {
      expect(monthlyExpenseTotal(expenses, now), 10000);
    });

    test('推し別累計 (お布施累計)', () {
      final totals = totalByOshi(expenses);
      expect(totals['o1'], 14999);
      expect(totals['o2'], 5000);
    });

    test('カテゴリ別集計', () {
      final byCat = totalByCategory(expenses, now, oshiId: 'o1');
      expect(byCat[ExpenseCategory.goods], 3000);
      expect(byCat[ExpenseCategory.ticket], 2000);
    });
  });

  group('誕生日カウントダウン', () {
    test('今日が誕生日なら0', () {
      final now = DateTime(2026, 6, 27);
      expect(daysUntilBirthday(DateTime(2000, 6, 27), now), 0);
    });

    test('数日後の誕生日までの日数', () {
      final now = DateTime(2026, 6, 27);
      expect(daysUntilBirthday(DateTime(2000, 6, 30), now), 3);
    });

    test('過ぎた誕生日は翌年で計算', () {
      final now = DateTime(2026, 6, 27);
      expect(daysUntilBirthday(DateTime(2000, 6, 20), now), greaterThan(300));
    });
  });
}
