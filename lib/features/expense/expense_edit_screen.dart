import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/models.dart';
import '../../core/state/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/oshi_picker.dart';

/// 支出の登録・編集。
class ExpenseEditScreen extends ConsumerStatefulWidget {
  final Expense? expense;
  final String? initialOshiId;
  const ExpenseEditScreen({super.key, this.expense, this.initialOshiId});

  @override
  ConsumerState<ExpenseEditScreen> createState() => _ExpenseEditScreenState();
}

class _ExpenseEditScreenState extends ConsumerState<ExpenseEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amount;
  late final TextEditingController _memo;
  String? _oshiId;
  ExpenseCategory _category = ExpenseCategory.goods;
  DateTime _date = DateTime.now();

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    _amount = TextEditingController(text: e?.amount.toString() ?? '');
    _memo = TextEditingController(text: e?.memo ?? '');
    _oshiId = e?.oshiId ?? widget.initialOshiId;
    _category = e?.category ?? ExpenseCategory.goods;
    _date = e?.date ?? DateTime.now();
  }

  @override
  void dispose() {
    _amount.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(appProvider.notifier);
    final expense = Expense(
      id: widget.expense?.id ?? newId(),
      oshiId: _oshiId!,
      amount: int.tryParse(_amount.text.trim()) ?? 0,
      category: _category,
      date: _date,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
    );
    if (_isEdit) {
      await notifier.updateExpense(expense);
    } else {
      await notifier.addExpense(expense);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final oshis = ref.watch(appProvider).oshis;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '支出を編集' : '支出を記録')),
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
              controller: _amount,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '金額 (円) *',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
              validator: (v) {
                final n = int.tryParse((v ?? '').trim());
                if (n == null || n <= 0) return '金額を入力してください';
                return null;
              },
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<ExpenseCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'カテゴリ',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: ExpenseCategory.values
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _category = v ?? ExpenseCategory.other),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('日付'),
              subtitle: Text(formatDate(_date)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _date,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(DateTime.now().year + 1),
                );
                if (picked != null) setState(() => _date = picked);
              },
            ),
            TextFormField(
              controller: _memo,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'メモ',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEdit ? '保存' : '記録'),
            ),
          ],
        ),
      ),
    );
  }
}
