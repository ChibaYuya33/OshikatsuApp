import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/local_store.dart';
import '../../core/db/models.dart';
import '../../core/db/queries.dart';
import '../../core/state/app_providers.dart';
import '../../core/state/settings_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/decor.dart';
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
                if (selected != null)
                  _hero(context, data, settings, selected, now),
                const SectionHeader('近づいているイベント'),
                ..._upcoming(context, data, oshiMap, now),
                const SizedBox(height: 4),
                _quickActions(context),
              ],
            ),
    );
  }

  Widget _welcome(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    scheme.primaryContainer,
                    scheme.secondaryContainer,
                  ],
                ),
              ),
              child: Icon(Icons.star_rounded,
                  size: 50, color: scheme.primary),
            ),
            const SizedBox(height: 24),
            Text('推し活をはじめましょう',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Text('まずは大切な推しを登録してください',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .bodyMedium
                    ?.copyWith(color: scheme.outline)),
            const SizedBox(height: 28),
            FilledButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OshiEditScreen()),
              ),
              icon: const Icon(Icons.add),
              label: const Text('推しを追加'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, DbData data, AppSettings settings,
      Oshi oshi, DateTime now) {
    final days = daysUntilBirthday(oshi.birthday, now);
    final spent =
        monthlyExpenseTotal(data.expenses, now, oshiId: oshi.id);
    final b = evaluateBudget(spent, settings.monthlyBudget);
    final onGrad = _onGradientColor(AppTheme.muted(Color(oshi.themeColor)));

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: GradientHeader(
        baseColor: Color(oshi.themeColor),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: onGrad.withValues(alpha: 0.6), width: 2),
                  ),
                  child: OshiAvatar(oshi: oshi, radius: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(oshi.name,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  color: onGrad,
                                  fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        days == null
                            ? '誕生日を登録できます'
                            : days == 0
                                ? 'お誕生日おめでとう'
                                : '誕生日まで あと $days 日',
                        style: TextStyle(
                            color: onGrad.withValues(alpha: 0.85),
                            fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.22),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${now.month}月の支出',
                          style: TextStyle(
                              color: onGrad.withValues(alpha: 0.9),
                              fontSize: 13)),
                      const Spacer(),
                      Text(yen(spent),
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(
                                  color: onGrad,
                                  fontWeight: FontWeight.w700)),
                      Text(' / ${yen(b.limit)}',
                          style: TextStyle(
                              color: onGrad.withValues(alpha: 0.8),
                              fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: b.ratio.clamp(0.0, 1.0),
                      minHeight: 8,
                      color: onGrad,
                      backgroundColor: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    b.remaining >= 0
                        ? '残り ${yen(b.remaining)}'
                        : '予算を ${yen(-b.remaining)} 超過',
                    style: TextStyle(
                        color: onGrad.withValues(alpha: 0.9), fontSize: 12),
                  ),
                ],
              ),
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
        SoftCard(
          child: Row(
            children: [
              Icon(Icons.event_available_outlined,
                  color: Theme.of(context).colorScheme.outline),
              const SizedBox(width: 12),
              const Expanded(child: Text('予定されているイベントはありません')),
            ],
          ),
        ),
      ];
    }
    return events.map((e) {
      final oshi = oshiMap[e.oshiId];
      final days = e.dateTime.difference(now).inDays;
      return SoftCard(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => EventDetailScreen(eventId: e.id))),
        child: Row(
          children: [
            if (oshi != null)
              OshiAvatar(oshi: oshi, radius: 22)
            else
              const CircleAvatar(child: Icon(Icons.event)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(e.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${formatDate(e.dateTime)} ・ ${e.type.label}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.outline)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _dayBadge(context, days),
          ],
        ),
      );
    }).toList();
  }

  Widget _dayBadge(BuildContext context, int days) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(days <= 0 ? '本日' : 'あと$days日',
          style: TextStyle(
              color: scheme.onSecondaryContainer,
              fontWeight: FontWeight.w700,
              fontSize: 12)),
    );
  }

  Widget _quickActions(BuildContext context) {
    return SoftCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const OshiListScreen()),
      ),
      child: Row(
        children: [
          Icon(Icons.people_alt_outlined,
              color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 14),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('推しを管理',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                Text('追加・編集・テーマ切替', style: TextStyle(fontSize: 12)),
              ],
            ),
          ),
          const Icon(Icons.chevron_right),
        ],
      ),
    );
  }

  /// グラデ背景上で読みやすい文字色(白か濃色)を明度で判定。
  Color _onGradientColor(Color bg) {
    return bg.computeLuminance() > 0.6 ? const Color(0xFF4A3B3F) : Colors.white;
  }
}
