import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/db/models.dart';
import '../../core/state/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/oshi_switch_action.dart';
import '../oshi/oshi_list_screen.dart';
import 'feed_edit_screen.dart';
import 'feed_repository.dart';

/// 推し情報フィード。MVP は手動URL登録。次フェーズで自動収集APIと統合。
class FeedScreen extends ConsumerStatefulWidget {
  const FeedScreen({super.key});

  @override
  ConsumerState<FeedScreen> createState() => _FeedScreenState();
}

enum _Filter { all, unread, bookmarked }

class _FeedScreenState extends ConsumerState<FeedScreen> {
  _Filter _filter = _Filter.all;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appProvider);
    final selected = ref.watch(selectedOshiProvider);
    final repo = ref.watch(feedRepositoryProvider);

    if (data.oshis.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('情報')),
        body: const EmptyState(
          icon: Icons.rss_feed,
          message: 'まず推しを登録しましょう',
          hint: '推しの情報をここに集約できます',
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const OshiListScreen()),
          ),
          icon: const Icon(Icons.person_add_alt),
          label: const Text('推しを追加'),
        ),
      );
    }

    var feeds =
        data.feeds.where((f) => f.oshiId == selected?.id).toList()
          ..sort((a, b) => b.publishedAt.compareTo(a.publishedAt));
    feeds = switch (_filter) {
      _Filter.all => feeds,
      _Filter.unread => feeds.where((f) => !f.isRead).toList(),
      _Filter.bookmarked => feeds.where((f) => f.isBookmarked).toList(),
    };

    return Scaffold(
      appBar: AppBar(
        title: const Text('情報'),
        actions: [
          IconButton(
            tooltip: '自動収集で更新',
            icon: const Icon(Icons.refresh),
            onPressed: () => _refresh(repo, selected),
          ),
          const OshiSwitchAction(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => FeedEditScreen(initialOshiId: selected?.id),
        )),
        icon: const Icon(Icons.add),
        label: const Text('情報を登録'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Row(
              children: [
                _filterChip('すべて', _Filter.all),
                const SizedBox(width: 8),
                _filterChip('未読', _Filter.unread),
                const SizedBox(width: 8),
                _filterChip('保存済み', _Filter.bookmarked),
              ],
            ),
          ),
          if (!repo.supportsAutoFetch)
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: _AutoFetchNotice(),
            ),
          Expanded(
            child: feeds.isEmpty
                ? const EmptyState(
                    icon: Icons.rss_feed,
                    message: 'まだ情報がありません',
                    hint: '公式情報や記事のURLを登録しておけます',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
                    itemCount: feeds.length,
                    itemBuilder: (context, i) => _feedTile(feeds[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, _Filter f) {
    return ChoiceChip(
      label: Text(label),
      selected: _filter == f,
      onSelected: (_) => setState(() => _filter = f),
    );
  }

  Widget _feedTile(FeedItem f) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor:
              Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Icon(_sourceIcon(f.source), size: 20),
        ),
        title: Text(
          f.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontWeight: f.isRead ? FontWeight.normal : FontWeight.bold,
          ),
        ),
        subtitle: Text('${f.source.label} ・ ${formatDate(f.publishedAt)}'),
        trailing: IconButton(
          icon: Icon(
            f.isBookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: f.isBookmarked
                ? Theme.of(context).colorScheme.primary
                : null,
          ),
          onPressed: () => ref
              .read(appProvider.notifier)
              .updateFeed(f.copyWith(isBookmarked: !f.isBookmarked)),
        ),
        onTap: () => _open(f),
        onLongPress: () => _menu(f),
      ),
    );
  }

  Future<void> _open(FeedItem f) async {
    if (!f.isRead) {
      ref.read(appProvider.notifier).updateFeed(f.copyWith(isRead: true));
    }
    final uri = Uri.tryParse(f.url);
    if (uri != null) {
      try {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (_) {
        _toast('リンクを開けませんでした');
      }
    }
  }

  void _menu(FeedItem f) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('編集'),
              onTap: () {
                Navigator.pop(context);
                Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => FeedEditScreen(feed: f)));
              },
            ),
            ListTile(
              leading: Icon(f.isRead
                  ? Icons.mark_email_unread_outlined
                  : Icons.mark_email_read_outlined),
              title: Text(f.isRead ? '未読にする' : '既読にする'),
              onTap: () {
                ref
                    .read(appProvider.notifier)
                    .updateFeed(f.copyWith(isRead: !f.isRead));
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete_outline),
              title: const Text('削除'),
              onTap: () {
                ref.read(appProvider.notifier).deleteFeed(f.id);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _refresh(FeedRepository repo, Oshi? oshi) async {
    if (!repo.supportsAutoFetch) {
      _toast('自動収集は次フェーズで有効になります(今は手動登録のみ)');
      return;
    }
    if (oshi == null) return;
    try {
      final items = await repo.fetchNew(oshi);
      final notifier = ref.read(appProvider.notifier);
      for (final item in items) {
        await notifier.addFeed(item);
      }
      _toast('${items.length}件の新着を取得しました');
    } catch (e) {
      _toast('取得に失敗しました');
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  IconData _sourceIcon(FeedSource s) => switch (s) {
        FeedSource.youtube => Icons.smart_display_outlined,
        FeedSource.rss => Icons.article_outlined,
        FeedSource.web => Icons.public,
        FeedSource.manual => Icons.bookmark_outline,
      };
}

class _AutoFetchNotice extends StatelessWidget {
  const _AutoFetchNotice();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: 18, color: scheme.onSecondaryContainer),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '自動収集(YouTube/RSS/Web検索)は次フェーズで有効化されます。今は情報を手動登録できます。',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}
