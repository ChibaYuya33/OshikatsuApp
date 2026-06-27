import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/models.dart';
import '../../core/state/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/oshi_picker.dart';

/// 推し活貯金目標の登録・編集。
class GoalEditScreen extends ConsumerStatefulWidget {
  final SavingGoal? goal;
  final String? initialOshiId;
  const GoalEditScreen({super.key, this.goal, this.initialOshiId});

  @override
  ConsumerState<GoalEditScreen> createState() => _GoalEditScreenState();
}

class _GoalEditScreenState extends ConsumerState<GoalEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _target;
  late final TextEditingController _current;
  String? _oshiId;
  DateTime? _deadline;

  bool get _isEdit => widget.goal != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goal;
    _title = TextEditingController(text: g?.title ?? '');
    _target = TextEditingController(text: g?.targetAmount.toString() ?? '');
    _current = TextEditingController(text: g?.currentAmount.toString() ?? '0');
    _oshiId = g?.oshiId ?? widget.initialOshiId;
    _deadline = g?.deadline;
  }

  @override
  void dispose() {
    _title.dispose();
    _target.dispose();
    _current.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(appProvider.notifier);
    final goal = SavingGoal(
      id: widget.goal?.id ?? newId(),
      oshiId: _oshiId!,
      title: _title.text.trim(),
      targetAmount: int.tryParse(_target.text.trim()) ?? 0,
      currentAmount: int.tryParse(_current.text.trim()) ?? 0,
      deadline: _deadline,
    );
    if (_isEdit) {
      await notifier.updateGoal(goal);
    } else {
      await notifier.addGoal(goal);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final oshis = ref.watch(appProvider).oshis;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '貯金目標を編集' : '貯金目標を追加')),
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
                labelText: '目標名 *',
                hintText: '例: 全国ツアー遠征費',
                prefixIcon: Icon(Icons.flag_outlined),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '目標名を入力してください' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _target,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '目標金額 (円) *',
                prefixIcon: Icon(Icons.savings_outlined),
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return '目標金額を入力してください';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _current,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '現在の貯金額 (円)',
                prefixIcon: Icon(Icons.account_balance_wallet_outlined),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.event_outlined),
              title: const Text('期限'),
              subtitle: Text(_deadline == null ? '未設定' : formatDate(_deadline!)),
              trailing: _deadline == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _deadline = null)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _deadline ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime(DateTime.now().year + 10),
                );
                if (picked != null) setState(() => _deadline = picked);
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEdit ? '保存' : '追加'),
            ),
          ],
        ),
      ),
    );
  }
}
