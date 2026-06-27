import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/models.dart';
import '../../core/state/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_storage.dart';
import '../../shared/widgets/common.dart';
import 'event_edit_screen.dart';

/// イベント詳細＋参戦記録(セトリ・座席・写真・参戦済み)。
class EventDetailScreen extends ConsumerWidget {
  final String eventId;
  const EventDetailScreen({super.key, required this.eventId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final data = ref.watch(appProvider);
    EventItem? found;
    for (final e in data.events) {
      if (e.id == eventId) {
        found = e;
        break;
      }
    }
    if (found == null) {
      return const Scaffold(body: Center(child: Text('イベントが見つかりません')));
    }
    final event = found;
    final oshi = ref.watch(oshiMapProvider)[event.oshiId];
    final notifier = ref.read(appProvider.notifier);
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('イベント詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => Navigator.of(context).push(MaterialPageRoute(
                builder: (_) => EventEditScreen(event: event))),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: () async {
              await notifier.deleteEvent(event.id);
              if (context.mounted) Navigator.pop(context);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            children: [
              if (oshi != null) OshiAvatar(oshi: oshi, radius: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(event.title,
                        style: Theme.of(context).textTheme.titleLarge),
                    Text('${event.type.label} ・ ${oshi?.name ?? ''}'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.schedule),
                  title: const Text('日時'),
                  subtitle: Text(formatDateTime(event.dateTime)),
                ),
                if (event.location != null)
                  ListTile(
                    leading: const Icon(Icons.place_outlined),
                    title: const Text('会場'),
                    subtitle: Text(event.location!),
                  ),
                if (event.ticketSaleDate != null)
                  ListTile(
                    leading: const Icon(Icons.confirmation_number_outlined),
                    title: const Text('チケット販売日'),
                    subtitle: Text(formatDateTime(event.ticketSaleDate!)),
                  ),
              ],
            ),
          ),
          const SectionHeader('参戦記録'),
          SwitchListTile(
            title: const Text('参戦済み'),
            value: event.isAttended,
            onChanged: (v) =>
                notifier.updateEvent(event.copyWith(isAttended: v)),
          ),
          _EditableField(
            icon: Icons.event_seat_outlined,
            label: '座席',
            value: event.seat,
            onSave: (v) => notifier.updateEvent(event.copyWith(seat: v)),
          ),
          _EditableField(
            icon: Icons.queue_music_outlined,
            label: 'セットリスト / 感想',
            value: event.setlistMemo,
            multiline: true,
            onSave: (v) =>
                notifier.updateEvent(event.copyWith(setlistMemo: v)),
          ),
          const SectionHeader('写真'),
          _PhotoGrid(event: event),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () async {
                final path = await pickAndStoreImage();
                if (path != null) {
                  notifier.updateEvent(event.copyWith(
                      photoPaths: [...event.photoPaths, path]));
                }
              },
              icon: const Icon(Icons.add_a_photo_outlined),
              label: const Text('写真を追加'),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      floatingActionButton: event.isAttended
          ? null
          : FloatingActionButton.extended(
              backgroundColor: scheme.primaryContainer,
              onPressed: () =>
                  notifier.updateEvent(event.copyWith(isAttended: true)),
              icon: const Icon(Icons.celebration_outlined),
              label: const Text('参戦した！'),
            ),
    );
  }
}

class _EditableField extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool multiline;
  final ValueChanged<String> onSave;
  const _EditableField({
    required this.icon,
    required this.label,
    required this.value,
    required this.onSave,
    this.multiline = false,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(label),
      subtitle: Text(value == null || value!.isEmpty ? '未記入' : value!),
      trailing: const Icon(Icons.edit_outlined, size: 18),
      onTap: () async {
        final controller = TextEditingController(text: value);
        final result = await showDialog<String>(
          context: context,
          builder: (_) => AlertDialog(
            title: Text(label),
            content: TextField(
              controller: controller,
              autofocus: true,
              minLines: multiline ? 3 : 1,
              maxLines: multiline ? 8 : 1,
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('キャンセル')),
              FilledButton(
                  onPressed: () =>
                      Navigator.pop(context, controller.text.trim()),
                  child: const Text('保存')),
            ],
          ),
        );
        if (result != null) onSave(result);
      },
    );
  }
}

class _PhotoGrid extends StatelessWidget {
  final EventItem event;
  const _PhotoGrid({required this.event});

  @override
  Widget build(BuildContext context) {
    if (event.photoPaths.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(8),
        child: Text('まだ写真がありません'),
      );
    }
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      children: event.photoPaths
          .map((p) => LocalImage(path: p, size: 100, radius: 12))
          .toList(),
    );
  }
}
