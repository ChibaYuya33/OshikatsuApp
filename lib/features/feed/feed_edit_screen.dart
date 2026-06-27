import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/models.dart';
import '../../core/state/app_providers.dart';
import '../../shared/widgets/oshi_picker.dart';

/// 情報フィードの手動登録・編集(URLブックマーク)。
class FeedEditScreen extends ConsumerStatefulWidget {
  final FeedItem? feed;
  final String? initialOshiId;
  const FeedEditScreen({super.key, this.feed, this.initialOshiId});

  @override
  ConsumerState<FeedEditScreen> createState() => _FeedEditScreenState();
}

class _FeedEditScreenState extends ConsumerState<FeedEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _title;
  late final TextEditingController _url;
  String? _oshiId;

  bool get _isEdit => widget.feed != null;

  @override
  void initState() {
    super.initState();
    final f = widget.feed;
    _title = TextEditingController(text: f?.title ?? '');
    _url = TextEditingController(text: f?.url ?? '');
    _oshiId = f?.oshiId ?? widget.initialOshiId;
  }

  @override
  void dispose() {
    _title.dispose();
    _url.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final notifier = ref.read(appProvider.notifier);
    final feed = FeedItem(
      id: widget.feed?.id ?? newId(),
      oshiId: _oshiId!,
      source: widget.feed?.source ?? FeedSource.manual,
      title: _title.text.trim(),
      url: _url.text.trim(),
      publishedAt: widget.feed?.publishedAt ?? DateTime.now(),
      isRead: widget.feed?.isRead ?? false,
      isBookmarked: widget.feed?.isBookmarked ?? false,
    );
    if (_isEdit) {
      await notifier.updateFeed(feed);
    } else {
      await notifier.addFeed(feed);
    }
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final oshis = ref.watch(appProvider).oshis;
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? '情報を編集' : '情報を登録')),
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
                labelText: 'タイトル *',
                prefixIcon: Icon(Icons.title),
              ),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'タイトルを入力してください' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: const InputDecoration(
                labelText: 'URL *',
                hintText: 'https://...',
                prefixIcon: Icon(Icons.link),
              ),
              validator: (v) {
                final s = (v ?? '').trim();
                if (s.isEmpty) return 'URLを入力してください';
                if (Uri.tryParse(s)?.hasScheme != true) {
                  return '正しいURLを入力してください';
                }
                return null;
              },
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEdit ? '保存' : '登録'),
            ),
          ],
        ),
      ),
    );
  }
}
