import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/models.dart';
import '../../core/db/queries.dart';
import '../../core/state/app_providers.dart';
import '../../core/state/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/oshi_switch_action.dart';
import '../oshi/oshi_list_screen.dart';
import 'expense_edit_screen.dart';
import 'goal_edit_screen.dart';

/// 支出管理: 月予算アラート・グラフ・貯金目標。
class ExpenseScreen extends ConsumerStatefulWidget {
  const ExpenseScreen({super.key});

  @override
  ConsumerState<ExpenseScreen> createState() => _ExpenseScreenState();
}

class _ExpenseScreenState extends ConsumerState<ExpenseScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _allOshi = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appProvider);
    final settings = ref.watch(settingsProvider);
    final selected = ref.watch(selectedOshiProvider);

    if (data.oshis.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('支出')),
        body: const EmptyState(
          icon: Icons.savings_outlined,
          message: 'まず推しを登録しましょう',
          hint: '支出は推しごとに記録できます',
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OshiListScreen()),
          ),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('推しを追加'),
        ),
      );
    }

    final filterOshiId = _allOshi ? null : selected?.id;
    final spent =
        monthlyExpenseTotal(data.expenses, _month, oshiId: filterOshiId);
    final budget = evaluateBudget(spent, settings.monthlyBudget);
    final monthly =
        monthlyTotals(data.expenses, DateTime.now(), oshiId: filterOshiId);
    final byCategory =
        totalByCategory(data.expenses, _month, oshiId: filterOshiId);
    final monthExpenses = data.expenses
        .where((e) =>
            e.date.year == _month.year &&
            e.date.month == _month.month &&
            (filterOshiId == null || e.oshiId == filterOshiId))
        .toList()
      ..sort((a, b) => b.date.compareTo(a.date));
    final goals = data.goals
        .where((g) => filterOshiId == null || g.oshiId == filterOshiId)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('支出'),
        actions: const [OshiSwitchAction()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => ExpenseEditScreen(initialOshiId: selected?.id),
        )),
        icon: const Icon(Icons.add),
        label: const Text('支出を記録'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          Row(
            children: [
              FilterChip(
                label: const Text('全推し合算'),
                selected: _allOshi,
                onSelected: (v) => setState(() => _allOshi = v),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _budgetCard(budget),
          const SizedBox(height: 8),
          _monthlyChartCard(monthly),
          if (byCategory.isNotEmpty) ...[
            const SizedBox(height: 8),
            _categoryCard(byCategory),
          ],
          const SectionHeader('貯金目標'),
          _goalsSection(goals, selected?.id),
          SectionHeader('${monthLabel(_month)}の支出'),
          if (monthExpenses.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: Text('この月の支出はまだありません')),
            )
          else
            ...monthExpenses.map(_expenseTile),
        ],
      ),
    );
  }

  Widget _monthNav() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => setState(() =>
              _month = DateTime(_month.year, _month.month - 1)),
        ),
        Text('${_month.year}年${_month.month}月',
            style: Theme.of(context).textTheme.titleMedium),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => setState(() =>
              _month = DateTime(_month.year, _month.month + 1)),
        ),
      ],
    );
  }

  Widget _budgetCard(BudgetResult b) {
    final scheme = Theme.of(context).colorScheme;
    final color = switch (b.status) {
      BudgetStatus.over => scheme.error,
      BudgetStatus.warning => const Color(0xFFC68A4E), // くすみアンバー
      BudgetStatus.ok => scheme.primary,
    };
    final msg = switch (b.status) {
      BudgetStatus.over => '予算オーバー！',
      BudgetStatus.warning => '予算の80%を超えています',
      BudgetStatus.ok => '予算内です',
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _monthNav(),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(yen(b.spent),
                    style: Theme.of(context)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(color: color, fontWeight: FontWeight.bold)),
                const SizedBox(width: 8),
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text('/ ${yen(b.limit)}',
                      style: Theme.of(context).textTheme.bodyMedium),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: b.ratio.clamp(0.0, 1.0),
                minHeight: 10,
                color: color,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                    b.status == BudgetStatus.ok
                        ? Icons.check_circle_outline
                        : Icons.warning_amber_rounded,
                    size: 18,
                    color: color),
                const SizedBox(width: 6),
                Text(msg, style: TextStyle(color: color)),
                const Spacer(),
                Text(
                    b.remaining >= 0
                        ? '残り ${yen(b.remaining)}'
                        : '超過 ${yen(-b.remaining)}',
                    style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _monthlyChartCard(List<MonthlyTotal> monthly) {
    final maxY = monthly.fold<int>(0, (m, e) => e.total > m ? e.total : m);
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(left: 8),
              child: Text('月別の支出',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  maxY: (maxY == 0 ? 1000 : maxY * 1.2).toDouble(),
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false)),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= monthly.length) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(monthLabel(monthly[i].month),
                                style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: [
                    for (var i = 0; i < monthly.length; i++)
                      BarChartGroupData(x: i, barRods: [
                        BarChartRodData(
                          toY: monthly[i].total.toDouble(),
                          color: scheme.primary,
                          width: 18,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(6)),
                        ),
                      ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _categoryCard(Map<ExpenseCategory, int> byCategory) {
    final entries = byCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = entries.fold<int>(0, (s, e) => s + e.value);
    final colors = AppTheme.mutedChartColors;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('カテゴリ別',
                style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  height: 120,
                  child: PieChart(
                    PieChartData(
                      centerSpaceRadius: 28,
                      sections: [
                        for (var i = 0; i < entries.length; i++)
                          PieChartSectionData(
                            value: entries[i].value.toDouble(),
                            color: colors[i % colors.length],
                            title: '',
                            radius: 26,
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: [
                      for (var i = 0; i < entries.length; i++)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: colors[i % colors.length],
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(child: Text(entries[i].key.label)),
                              Text(
                                  '${(entries[i].value / total * 100).round()}%'),
                              const SizedBox(width: 8),
                              Text(yen(entries[i].value),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _goalsSection(List<SavingGoal> goals, String? defaultOshiId) {
    return Column(
      children: [
        ...goals.map((g) => Card(
              child: ListTile(
                title: Text(g.title),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: g.progress,
                        minHeight: 8,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                        '${yen(g.currentAmount)} / ${yen(g.targetAmount)} (${(g.progress * 100).round()}%)'),
                  ],
                ),
                onTap: () => Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => GoalEditScreen(goal: g))),
                onLongPress: () =>
                    ref.read(appProvider.notifier).deleteGoal(g.id),
              ),
            )),
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => GoalEditScreen(initialOshiId: defaultOshiId),
            )),
            icon: const Icon(Icons.add),
            label: const Text('貯金目標を追加'),
          ),
        ),
      ],
    );
  }

  Widget _expenseTile(Expense e) {
    final oshi = ref.read(oshiMapProvider)[e.oshiId];
    return Card(
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 18,
          backgroundColor:
              (oshi != null ? Color(oshi.themeColor) : Colors.grey)
                  .withValues(alpha: 0.2),
          child: Icon(Icons.payments_outlined,
              size: 18,
              color: oshi != null ? Color(oshi.themeColor) : Colors.grey),
        ),
        title: Text(e.category.label),
        subtitle: Text(
            '${formatDate(e.date)}${e.memo != null ? ' ・ ${e.memo}' : ''}'),
        trailing: Text(yen(e.amount),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => ExpenseEditScreen(expense: e))),
        onLongPress: () => ref.read(appProvider.notifier).deleteExpense(e.id),
      ),
    );
  }
}
