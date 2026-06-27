import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/models.dart';
import '../../core/state/app_providers.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/image_storage.dart';

/// 推しの新規作成・編集画面。
class OshiEditScreen extends ConsumerStatefulWidget {
  final Oshi? oshi;
  const OshiEditScreen({super.key, this.oshi});

  @override
  ConsumerState<OshiEditScreen> createState() => _OshiEditScreenState();
}

class _OshiEditScreenState extends ConsumerState<OshiEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _youtube;
  late final TextEditingController _urls;
  late int _color;
  DateTime? _birthday;
  String? _photoPath;

  bool get _isEdit => widget.oshi != null;

  @override
  void initState() {
    super.initState();
    final o = widget.oshi;
    _name = TextEditingController(text: o?.name ?? '');
    _youtube = TextEditingController(text: o?.youtubeChannelId ?? '');
    _urls = TextEditingController(text: o?.officialUrls.join('\n') ?? '');
    _color = o?.themeColor ?? AppTheme.presetColors.first.toARGB32();
    _birthday = o?.birthday;
    _photoPath = o?.photoPath;
  }

  @override
  void dispose() {
    _name.dispose();
    _youtube.dispose();
    _urls.dispose();
    super.dispose();
  }

  Future<void> _pickPhoto() async {
    final path = await pickAndStoreImage();
    if (path != null) setState(() => _photoPath = path);
  }

  Future<void> _pickBirthday() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 20, 1, 1),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year + 1),
      helpText: '誕生日を選択',
    );
    if (picked != null) setState(() => _birthday = picked);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(appProvider.notifier);
    final urls = _urls.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
    final youtube = _youtube.text.trim().isEmpty ? null : _youtube.text.trim();

    if (_isEdit) {
      await notifier.updateOshi(widget.oshi!.copyWith(
        name: _name.text.trim(),
        themeColor: _color,
        birthday: _birthday,
        clearBirthday: _birthday == null,
        photoPath: _photoPath,
        clearPhoto: _photoPath == null,
        officialUrls: urls,
        youtubeChannelId: youtube,
      ));
    } else {
      await notifier.addOshi(
        name: _name.text.trim(),
        themeColor: _color,
        birthday: _birthday,
        photoPath: _photoPath,
        officialUrls: urls,
        youtubeChannelId: youtube,
      );
    }
    if (mounted) Navigator.of(context).pop();
  }

  ImageProvider? get _photoImage {
    if (kIsWeb || _photoPath == null) return null;
    return FileImage(File(_photoPath!));
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '推しを編集' : '推しを追加')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Center(
              child: GestureDetector(
                onTap: _pickPhoto,
                child: Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 48,
                      backgroundColor: Color(_color).withValues(alpha: 0.25),
                      backgroundImage: _photoImage,
                      child: _photoImage == null
                          ? Icon(Icons.add_a_photo_outlined,
                              color: Color(_color))
                          : null,
                    ),
                    if (_photoPath != null)
                      GestureDetector(
                        onTap: () => setState(() => _photoPath = null),
                        child: CircleAvatar(
                          radius: 14,
                          backgroundColor: scheme.errorContainer,
                          child: Icon(Icons.close,
                              size: 16, color: scheme.onErrorContainer),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _name,
              decoration: const InputDecoration(
                labelText: '推しの名前 *',
                prefixIcon: Icon(Icons.person_outline),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? '名前を入力してください' : null,
            ),
            const SizedBox(height: 20),
            Text('推し色', style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            _ColorPicker(
              selected: _color,
              onSelected: (c) => setState(() => _color = c),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.cake_outlined),
              title: const Text('誕生日'),
              subtitle: Text(_birthday == null
                  ? '未設定 (カウントダウンに使用)'
                  : formatDate(_birthday!)),
              trailing: _birthday == null
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _birthday = null),
                    ),
              onTap: _pickBirthday,
            ),
            const Divider(height: 32),
            Text('自動収集の設定 (次フェーズで使用)',
                style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 4),
            Text(
              'サーバー側の自動情報収集を有効化した際の取得元です。今は登録だけしておけます。',
              style: Theme.of(context)
                  .textTheme
                  .bodySmall
                  ?.copyWith(color: scheme.outline),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _youtube,
              decoration: const InputDecoration(
                labelText: 'YouTube チャンネルID',
                hintText: 'UCxxxxxxxx',
                prefixIcon: Icon(Icons.smart_display_outlined),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _urls,
              minLines: 2,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: '公式サイト/RSS のURL (1行に1つ)',
                prefixIcon: Icon(Icons.link),
              ),
            ),
            const SizedBox(height: 32),
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

class _ColorPicker extends StatelessWidget {
  final int selected;
  final ValueChanged<int> onSelected;
  const _ColorPicker({required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: AppTheme.presetColors.map((c) {
        final value = c.toARGB32();
        final isSel = value == selected;
        return GestureDetector(
          onTap: () => onSelected(value),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: c,
              shape: BoxShape.circle,
              border: isSel
                  ? Border.all(
                      color: Theme.of(context).colorScheme.onSurface, width: 3)
                  : null,
            ),
            child: isSel
                ? const Icon(Icons.check, color: Colors.white, size: 20)
                : null,
          ),
        );
      }).toList(),
    );
  }
}
