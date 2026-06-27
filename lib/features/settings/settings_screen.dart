import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/db/queries.dart';
import '../../core/state/app_providers.dart';
import '../../core/state/settings_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/common.dart';

/// 設定: テーマ・月予算・お布施累計・バックアップ。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final data = ref.watch(appProvider);
    final oshiMap = ref.watch(oshiMapProvider);
    final totals = totalByOshi(data.expenses);

    return Scaffold(
      appBar: AppBar(title: const Text('設定')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const SectionHeader('表示'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.brightness_6_outlined),
                  title: const Text('テーマ'),
                  subtitle: Text(switch (settings.themeMode) {
                    ThemeMode.system => '端末に合わせる',
                    ThemeMode.light => 'ライト',
                    ThemeMode.dark => 'ダーク',
                  }),
                  trailing: SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(
                          value: ThemeMode.system,
                          icon: Icon(Icons.brightness_auto)),
                      ButtonSegment(
                          value: ThemeMode.light,
                          icon: Icon(Icons.light_mode)),
                      ButtonSegment(
                          value: ThemeMode.dark,
                          icon: Icon(Icons.dark_mode)),
                    ],
                    selected: {settings.themeMode},
                    onSelectionChanged: (s) => ref
                        .read(settingsProvider.notifier)
                        .setThemeMode(s.first),
                  ),
                ),
              ],
            ),
          ),
          const SectionHeader('予算'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet_outlined),
              title: const Text('月の予算上限'),
              subtitle: Text(yen(settings.monthlyBudget)),
              trailing: const Icon(Icons.edit_outlined),
              onTap: () => _editBudget(context, ref, settings.monthlyBudget),
            ),
          ),
          const SectionHeader('お布施累計 (推し別)'),
          if (totals.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text('まだ支出の記録がありません'),
              ),
            )
          else
            Card(
              child: Column(
                children: (totals.entries.toList()
                      ..sort((a, b) => b.value.compareTo(a.value)))
                    .map((e) {
                  final oshi = oshiMap[e.key];
                  return ListTile(
                    leading: oshi != null
                        ? OshiAvatar(oshi: oshi, radius: 18)
                        : const CircleAvatar(child: Icon(Icons.person)),
                    title: Text(oshi?.name ?? '(削除済み)'),
                    trailing: Text(yen(e.value),
                        style:
                            const TextStyle(fontWeight: FontWeight.bold)),
                  );
                }).toList(),
              ),
            ),
          const SectionHeader('バックアップ'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.upload_file_outlined),
                  title: const Text('データを書き出す'),
                  subtitle: const Text('機種変更時の引き継ぎ用 (JSON)'),
                  onTap: () => _export(context, ref),
                ),
                const Divider(height: 1),
                ListTile(
                  leading: const Icon(Icons.download_outlined),
                  title: const Text('データを読み込む'),
                  subtitle: const Text('書き出したJSONから復元 (現在のデータは置換)'),
                  onTap: () => _import(context, ref),
                ),
              ],
            ),
          ),
          const SectionHeader('このアプリについて'),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'データはすべて端末内に保存され、外部に送信されません。\n'
                '推しの情報・グッズ・支出・イベントをまとめて管理できる推し活アプリです。',
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _editBudget(BuildContext context, WidgetRef ref, int current) {
    final controller = TextEditingController(text: current.toString());
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('月の予算上限'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          autofocus: true,
          decoration: const InputDecoration(
            prefixText: '¥ ',
            hintText: '10000',
          ),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          FilledButton(
            onPressed: () {
              final v = int.tryParse(controller.text.trim());
              if (v != null && v >= 0) {
                ref.read(settingsProvider.notifier).setMonthlyBudget(v);
              }
              Navigator.pop(context);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  Future<void> _export(BuildContext context, WidgetRef ref) async {
    final json = ref.read(appProvider.notifier).exportJson();
    final messenger = ScaffoldMessenger.of(context);
    try {
      if (kIsWeb) {
        await SharePlus.instance.share(
          ShareParams(text: json, subject: 'oshikatsu_backup.json'),
        );
        return;
      }
      final dir = await getTemporaryDirectory();
      final file = File(
          '${dir.path}/oshikatsu_backup_${DateTime.now().millisecondsSinceEpoch}.json');
      await file.writeAsString(json);
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          subject: '推し活アプリ バックアップ',
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
          const SnackBar(content: Text('書き出しに失敗しました')));
    }
  }

  Future<void> _import(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('データを読み込む'),
        content: const Text('現在のデータはすべて置き換えられます。よろしいですか？'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('キャンセル')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('読み込む')),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );
      if (result == null) return;
      final bytes = result.files.single.bytes;
      final path = result.files.single.path;
      final String content;
      if (bytes != null) {
        content = utf8.decode(bytes);
      } else if (path != null) {
        content = await File(path).readAsString();
      } else {
        return;
      }
      await ref.read(appProvider.notifier).importJson(content);
      messenger
          .showSnackBar(const SnackBar(content: Text('データを復元しました')));
    } catch (e) {
      messenger.showSnackBar(
          const SnackBar(content: Text('読み込みに失敗しました(ファイル形式を確認してください)')));
    }
  }
}
