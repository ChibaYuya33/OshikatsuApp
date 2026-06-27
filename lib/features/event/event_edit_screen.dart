import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/models.dart';
import '../../core/state/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/oshi_picker.dart';

/// イベントの登録・編集。チケット販売日と通知設定を含む。
class EventEditScreen extends ConsumerStatefulWidget {
  final EventItem? event;
  final String? initialOshiId;
  final DateTime? initialDate;
  const EventEditScreen(
      {super.key, this.event, this.initialOshiId, this.initialDate});

  @override
  ConsumerState<EventEditScreen> createState() => _EventEditScreenState();
}

class _EventEditScreenState extends ConsumerState<EventEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _location;
  String? _oshiId;
  EventType _type = EventType.live;
  late DateTime _dateTime;
  DateTime? _ticketSaleDate;
  int _notifyBeforeDays = 1;

  bool get _isEdit => widget.event != null;

  @override
  void initState() {
    super.initState();
    final e = widget.event;
    _title = TextEditingController(text: e?.title ?? '');
    _location = TextEditingController(text: e?.location ?? '');
    _oshiId = e?.oshiId ?? widget.initialOshiId;
    _type = e?.type ?? EventType.live;
    _dateTime = e?.dateTime ?? widget.initialDate ?? DateTime.now();
    _ticketSaleDate = e?.ticketSaleDate;
    _notifyBeforeDays = e?.notifyBeforeDays ?? 1;
  }

  @override
  void dispose() {
    _title.dispose();
    _location.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime(DateTime initial) async {
    final d = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime(DateTime.now().year + 5),
    );
    if (d == null) return null;
    if (!mounted) return null;
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    return DateTime(d.year, d.month, d.day, t?.hour ?? 0, t?.minute ?? 0);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(appProvider.notifier);
    final event = EventItem(
      id: widget.event?.id ?? newId(),
      oshiId: _oshiId!,
      title: _title.text.trim(),
      type: _type,
      dateTime: _dateTime,
      location: _location.text.trim().isEmpty ? null : _location.text.trim(),
      ticketSaleDate: _ticketSaleDate,
      notifyBeforeDays: _notifyBeforeDays,
      // 参戦記録は詳細画面側で編集するため、既存値を維持。
      isAttended: widget.event?.isAttended ?? false,
      setlistMemo: widget.event?.setlistMemo,
      seat: widget.event?.seat,
      photoPaths: widget.event?.photoPaths ?? const [],
    );
    if (_isEdit) {
      await notifier.updateEvent(event);
    } else {
      await notifier.addEvent(event);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final oshis = ref.watch(appProvider).oshis;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'イベントを編集' : 'イベントを追加')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            OshiDropdown(
              oshis: oshis,
              selectedId: _oshiId,
              onChanged: (v) => setState(() => _oshiId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'イベント名 *',
                prefixIcon: Icon(Icons.event_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '名前を入力してください' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<EventType>(
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: '種別',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: EventType.values
                  .map((t) =>
                      DropdownMenuItem(value: t, child: Text(t.label)))
                  .toList(),
              onChanged: (v) => setState(() => _type = v ?? EventType.other),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('日時 *'),
              subtitle: Text(formatDateTime(_dateTime)),
              onTap: () async {
                final picked = await _pickDateTime(_dateTime);
                if (picked != null) setState(() => _dateTime = picked);
              },
            ),
            TextFormField(
              controller: _location,
              decoration: const InputDecoration(
                labelText: '会場/場所',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const Divider(height: 32),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.confirmation_number_outlined),
              title: const Text('チケット販売日'),
              subtitle: Text(_ticketSaleDate == null
                  ? '設定すると当日に通知します'
                  : formatDateTime(_ticketSaleDate!)),
              trailing: _ticketSaleDate == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () =>
                          setState(() => _ticketSaleDate = null)),
              onTap: () async {
                final picked =
                    await _pickDateTime(_ticketSaleDate ?? DateTime.now());
                if (picked != null) setState(() => _ticketSaleDate = picked);
              },
            ),
            const SizedBox(height: 8),
            Text('リマインド通知', style: Theme.of(context).textTheme.titleSmall),
            Wrap(
              spacing: 8,
              children: [0, 1, 3, 7].map((d) {
                return ChoiceChip(
                  label: Text(d == 0 ? 'なし' : '$d日前'),
                  selected: _notifyBeforeDays == d,
                  onSelected: (_) => setState(() => _notifyBeforeDays = d),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEdit ? '保存' : '追加'),
            ),
            const SizedBox(height: 8),
            Text(
              '※ 通知はスマホ端末内で動作します(サーバー不要)。Webでは通知は無効です。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
