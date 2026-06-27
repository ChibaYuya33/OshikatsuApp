import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/state/app_providers.dart';
import '../../core/state/settings_providers.dart';
import '../../features/oshi/oshi_list_screen.dart';
import 'common.dart';

/// AppBar 右上に置く「推し切替」アクション。
/// 現在テーマ中の推しを表示し、タップで切替シートを開く。
class OshiSwitchAction extends ConsumerWidget {
  const OshiSwitchAction({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    final selected = ref.watch(selectedOshiProvider);

    if (data.oshis.isEmpty) {
      return IconButton(
        icon: const Icon(Icons.person_add_alt),
        tooltip: '推しを追加',
        onPressed: () => Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const OshiListScreen()),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: () => _openSheet(context, ref),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected != null) OshiAvatar(oshi: selected, radius: 16),
              const Icon(Icons.arrow_drop_down),
            ],
          ),
        ),
      ),
    );
  }

  void _openSheet(BuildContext context, WidgetRef ref) {
    final data = ref.read(appProvider);
    final selected = ref.read(selectedOshiProvider);
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const ListTile(
              title: Text('推しを切替',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
            ...data.oshis.map((o) => ListTile(
                  leading: OshiAvatar(oshi: o, radius: 18),
                  title: Text(o.name),
                  trailing: selected?.id == o.id
                      ? const Icon(Icons.check)
                      : null,
                  onTap: () {
                    ref.read(settingsProvider.notifier).setSelectedOshi(o.id);
                    Navigator.pop(context);
                  },
                )),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.settings_outlined),
              title: const Text('推しを管理 / 追加'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(
                  MaterialPageRoute(
                      builder: (_) => const OshiListScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
