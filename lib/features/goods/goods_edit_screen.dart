import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/models.dart';
import '../../core/db/queries.dart';
import '../../core/state/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_storage.dart';
import '../../shared/widgets/oshi_picker.dart';

/// グッズの登録・編集。同一推し内で同名のものがあると警告する(持ってた防止)。
class GoodsEditScreen extends ConsumerStatefulWidget {
  final Goods? goods;
  final String? initialOshiId;
  const GoodsEditScreen({super.key, this.goods, this.initialOshiId});

  @override
  ConsumerState<GoodsEditScreen> createState() => _GoodsEditScreenState();
}

class _GoodsEditScreenState extends ConsumerState<GoodsEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _memo;
  String? _oshiId;
  GoodsCategory _category = GoodsCategory.other;
  DateTime _purchaseDate = DateTime.now();
  bool _owned = true;
  String? _photoPath;

  bool get _isEdit => widget.goods != null;

  @override
  void initState() {
    super.initState();
    final g = widget.goods;
    _name = TextEditingController(text: g?.name ?? '');
    _price = TextEditingController(text: g?.price.toString() ?? '');
    _memo = TextEditingController(text: g?.memo ?? '');
    _oshiId = g?.oshiId ?? widget.initialOshiId;
    _category = g?.category ?? GoodsCategory.other;
    _purchaseDate = g?.purchaseDate ?? DateTime.now();
    _owned = g?.owned ?? true;
    _photoPath = g?.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _memo.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await pickAndStoreImage();
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final data = ref.read(appProvider);
    final notifier = ref.read(appProvider.notifier);

    // 重複チェック(持ってた防止)。
    final dups = duplicateGoods(
      data.goods,
      _oshiId!,
      _name.text,
      excludeId: widget.goods?.id,
    );
    if (dups.isNotEmpty) {
      final proceed = await _showDuplicateDialog(dups);
      if (proceed != true) return;
    }

    final goods = Goods(
      id: widget.goods?.id ?? newId(),
      oshiId: _oshiId!,
      name: _name.text.trim(),
      photoPath: _photoPath,
      price: int.tryParse(_price.text.trim()) ?? 0,
      purchaseDate: _purchaseDate,
      category: _category,
      owned: _owned,
      memo: _memo.text.trim().isEmpty ? null : _memo.text.trim(),
    );

    if (_isEdit) {
      await notifier.updateGoods(goods);
    } else {
      await notifier.addGoods(goods);
    }
    if (mounted) Navigator.of(context).pop();
  }

  Future<bool?> _showDuplicateDialog(List<Goods> dups) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded),
        title: const Text('もう持っているかも？'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('同じ名前のグッズが既に登録されています:'),
            const SizedBox(height: 8),
            ...dups.map((g) => Text(
                '・${g.name} (${formatDate(g.purchaseDate)} / ${yen(g.price)})')),
            const SizedBox(height: 8),
            const Text('それでも登録しますか？'),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('やめる')),
          FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('登録する')),
        ],
      ),
    );
  }

  ImageProvider? get _photoImage {
    if (kIsWeb || _photoPath == null) return null;
    return FileImage(File(_photoPath!));
  }

  @override
  Widget build(BuildContext context) {
    final oshis = ref.watch(appProvider).oshis;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'グッズを編集' : 'グッズを追加')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(20),
                    image: _photoImage != null
                        ? DecorationImage(
                            image: _photoImage!, fit: BoxFit.cover)
                        : null,
                  ),
                  child: _photoImage == null
                      ? const Icon(Icons.add_a_photo_outlined, size: 32)
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 20),
            OshiDropdown(
              oshis: oshis,
              selectedId: _oshiId,
              onChanged: (v) => setState(() => _oshiId = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: 'グッズ名 *',
                prefixIcon: Icon(Icons.label_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '名前を入力してください' : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<GoodsCategory>(
              initialValue: _category,
              decoration: const InputDecoration(
                labelText: 'カテゴリ',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: GoodsCategory.values
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c.label)))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _category = v ?? GoodsCategory.other),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _price,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '金額 (円)',
                prefixIcon: Icon(Icons.payments_outlined),
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.calendar_today_outlined),
              title: const Text('購入日'),
              subtitle: Text(formatDate(_purchaseDate)),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _purchaseDate,
                  firstDate: DateTime(2000),
                  lastDate: DateTime(DateTime.now().year + 1),
                );
                if (picked != null) setState(() => _purchaseDate = picked);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('所持中'),
              subtitle: const Text('交換・譲渡した場合はオフに'),
              value: _owned,
              onChanged: (v) => setState(() => _owned = v),
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
              label: Text(_isEdit ? '保存' : '追加'),
            ),
          ],
        ),
      ),
    );
  }
}
