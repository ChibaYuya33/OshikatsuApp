import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/models.dart';
import '../../core/db/queries.dart';
import '../../core/state/app_providers.dart';
import '../../core/state/settings_providers.dart';
import '../../shared/widgets/common.dart';
import 'oshi_edit_screen.dart';

/// 推しの一覧・選択・管理画面。
class OshiListScreen extends ConsumerWidget {
  const OshiListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    final selected = ref.watch(selectedOshiProvider);
    final oshis = data.oshis;

    return Scaffold(
      appBar: AppBar(title: const Text('推し一覧')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OshiEditScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('推しを追加'),
      ),
      body: oshis.isEmpty
          ? const EmptyState(
              icon: Icons.star_outline_rounded,
              message: '推しを登録しましょう',
              hint: '右下のボタンから最初の推しを追加できます',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 88),
              itemCount: oshis.length,
              itemBuilder: (context, i) {
                final o = oshis[i];
                final isSelected = selected?.id == o.id;
                final days = daysUntilBirthday(o.birthday, DateTime.now());
                return Card(
                  child: ListTile(
                    leading: OshiAvatar(oshi: o, radius: 26),
                    title: Text(o.name,
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(days == null
                        ? 'タップでテーマに設定'
                        : days == 0
                            ? '🎂 今日は誕生日！'
                            : '誕生日まであと$days日'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (isSelected)
                          Chip(
                            label: const Text('テーマ中'),
                            visualDensity: VisualDensity.compact,
                            backgroundColor: Color(o.themeColor)
                                .withValues(alpha: 0.2),
                          ),
                        PopupMenuButton<String>(
                          onSelected: (v) async {
                            if (v == 'edit') {
                              Navigator.of(context).push(MaterialPageRoute(
                                  builder: (_) => OshiEditScreen(oshi: o)));
                            } else if (v == 'delete') {
                              _confirmDelete(context, ref, o);
                            }
                          },
                          itemBuilder: (_) => const [
                            PopupMenuItem(value: 'edit', child: Text('編集')),
                            PopupMenuItem(
                                value: 'delete', child: Text('削除')),
                          ],
                        ),
                      ],
                    ),
                    onTap: () => ref
                        .read(settingsProvider.notifier)
                        .setSelectedOshi(o.id),
                  ),
                );
              },
            ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Oshi o) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('「${o.name}」を削除'),
        content: const Text(
            'この推しに紐づくグッズ・支出・イベント・情報もすべて削除されます。よろしいですか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          FilledButton(
            onPressed: () async {
              await ref.read(appProvider.notifier).deleteOshi(o.id);
              final settings = ref.read(settingsProvider);
              if (settings.selectedOshiId == o.id) {
                await ref
                    .read(settingsProvider.notifier)
                    .setSelectedOshi(null);
              }
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }
}
