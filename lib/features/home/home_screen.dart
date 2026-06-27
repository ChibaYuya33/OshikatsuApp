import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/local_store.dart';
import '../../core/db/models.dart';
import '../../core/db/queries.dart';
import '../../core/state/app_providers.dart';
import '../../core/state/settings_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/oshi_switch_action.dart';
import '../event/event_detail_screen.dart';
import '../oshi/oshi_edit_screen.dart';
import '../oshi/oshi_list_screen.dart';
import '../settings/settings_screen.dart';

/// ホーム: カウントダウン・今月支出・直近イベントのダッシュボード。
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    final settings = ref.watch(settingsProvider);
    final selected = ref.watch(selectedOshiProvider);
    final oshiMap = ref.watch(oshiMapProvider);
    final now = DateTime.now();

    return Scaffold(
      appBar: AppBar(
        title: const Text('推し活ホーム'),
        actions: [
          const OshiSwitchAction(),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const SettingsScreen()),
            ),
          ),
        ],
      ),
      body: data.oshis.isEmpty
          ? _welcome(context)
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                if (selected != null) _oshiHeader(context, selected, now),
                const SizedBox(height: 8),
                _budgetSummary(context, data, settings, selected, now),
                const SectionHeader('近づいているイベント'),
                ..._upcoming(context, data, oshiMap, now),
                const SizedBox(height: 8),
                _quickActions(context),
              ],
            ),
    );
  }

  Widget _welcome(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🌸', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text('推し活をはじめましょう',
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            const Text('まずは推しを登録してください',
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OshiEditScreen()),
              ),
              icon: const Icon(Icons.favorite),
              label: const Text('推しを追加'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _oshiHeader(BuildContext context, Oshi oshi, DateTime now) {
    final color = Color(oshi.themeColor);
    final days = daysUntilBirthday(oshi.birthday, now);
    return Card(
      color: color.withValues(alpha: 0.12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            OshiAvatar(oshi: oshi, radius: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(oshi.name,
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  if (days != null)
                    Row(
                      children: [
                        const Text('🎂 '),
                        Text(days == 0
                            ? '今日は誕生日です！おめでとう🎉'
                            : '誕生日まであと $days 日'),
                      ],
                    )
                  else
                    Text('誕生日を登録するとカウントダウンできます',
                        style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _budgetSummary(BuildContext context, DbData data,
      AppSettings settings, Oshi? selected, DateTime now) {
    final spent =
        monthlyExpenseTotal(data.expenses, now, oshiId: selected?.id);
    final b = evaluateBudget(spent, settings.monthlyBudget);
    final scheme = Theme.of(context).colorScheme;
    final color = switch (b.status) {
      BudgetStatus.over => scheme.error,
      BudgetStatus.warning => Colors.orange,
      BudgetStatus.ok => scheme.primary,
    };
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${now.month}月の推し活支出',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(yen(spent),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: color,
                      fontWeight: FontWeight.bold,
                    )),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: b.ratio.clamp(0.0, 1.0),
                minHeight: 8,
                color: color,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              b.remaining >= 0
                  ? '予算 ${yen(b.limit)} / 残り ${yen(b.remaining)}'
                  : '予算 ${yen(b.limit)} を ${yen(-b.remaining)} 超過',
              style: TextStyle(color: color),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _upcoming(BuildContext context, DbData data,
      Map<String, Oshi> oshiMap, DateTime now) {
    final events = upcomingEvents(data.events, now, limit: 5);
    if (events.isEmpty) {
      return [
        const Card(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Text('予定されているイベントはありません'),
          ),
        ),
      ];
    }
    return events.map((e) {
      final oshi = oshiMap[e.oshiId];
      final days = e.dateTime.difference(now).inDays;
      return Card(
        child: ListTile(
          leading: oshi != null
              ? OshiAvatar(oshi: oshi, radius: 20)
              : const CircleAvatar(child: Icon(Icons.event)),
          title: Text(e.title),
          subtitle: Text('${formatDate(e.dateTime)} ・ ${e.type.label}'),
          trailing: Text(days <= 0 ? '本日' : 'あと$days日',
              style: const TextStyle(fontWeight: FontWeight.bold)),
          onTap: () => Navigator.of(context).push(MaterialPageRoute(
              builder: (_) => EventDetailScreen(eventId: e.id))),
        ),
      );
    }).toList();
  }

  Widget _quickActions(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.favorite_outline),
        title: const Text('推しを管理'),
        subtitle: const Text('推しの追加・編集・テーマ切替'),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OshiListScreen()),
        ),
      ),
    );
  }
}
