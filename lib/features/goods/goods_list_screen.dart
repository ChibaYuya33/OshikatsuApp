import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/db/models.dart';
import '../../core/state/app_providers.dart';
import '../../core/utils/formatters.dart';
import '../../shared/widgets/common.dart';
import '../../shared/widgets/oshi_switch_action.dart';
import '../oshi/oshi_list_screen.dart';
import 'goods_edit_screen.dart';

/// グッズ一覧。テーマ中の推しのグッズを表示する。
class GoodsListScreen extends ConsumerStatefulWidget {
  const GoodsListScreen({super.key});

  @override
  ConsumerState<GoodsListScreen> createState() => _GoodsListScreenState();
}

class _GoodsListScreenState extends ConsumerState<GoodsListScreen> {
  bool _ownedOnly = false;

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(appProvider);
    final selected = ref.watch(selectedOshiProvider);

    if (data.oshis.isEmpty) {
      return _noOshiScaffold(context);
    }

    var goods =
        data.goods.where((g) => g.oshiId == selected?.id).toList()
          ..sort((a, b) => b.purchaseDate.compareTo(a.purchaseDate));
    if (_ownedOnly) goods = goods.where((g) => g.owned).toList();

    final ownedCount = goods.where((g) => g.owned).length;
    final total = goods.fold<int>(0, (s, g) => s + g.price);

    return Scaffold(
      appBar: AppBar(
        title: const Text('グッズ'),
        actions: const [OshiSwitchAction()],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GoodsEditScreen(initialOshiId: selected?.id),
        )),
        icon: const Icon(Icons.add),
        label: const Text('グッズを追加'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: Row(
              children: [
                _stat('点数', '${goods.length}'),
                _stat('所持', '$ownedCount'),
                _stat('合計', yen(total)),
                const Spacer(),
                FilterChip(
                  label: const Text('所持のみ'),
                  selected: _ownedOnly,
                  onSelected: (v) => setState(() => _ownedOnly = v),
                ),
              ],
            ),
          ),
          Expanded(
            child: goods.isEmpty
                ? const EmptyState(
                    icon: Icons.card_giftcard_outlined,
                    message: 'まだグッズがありません',
                    hint: '右下のボタンから追加できます。同名は重複警告でお知らせします',
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(8, 8, 8, 88),
                    itemCount: goods.length,
                    itemBuilder: (context, i) =>
                        _goodsCard(context, goods[i]),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _goodsCard(BuildContext context, Goods g) {
    return Card(
      child: ListTile(
        leading: LocalImage(path: g.photoPath, size: 52),
        title: Text(g.name,
            maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
            '${g.category.label} ・ ${formatDate(g.purchaseDate)}${g.owned ? '' : ' ・ 手放し済'}'),
        trailing: Text(yen(g.price),
            style: const TextStyle(fontWeight: FontWeight.bold)),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (_) => GoodsEditScreen(goods: g),
        )),
        onLongPress: () => _confirmDelete(context, g),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Goods g) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('「${g.name}」を削除'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('キャンセル')),
          FilledButton(
            onPressed: () {
              ref.read(appProvider.notifier).deleteGoods(g.id);
              Navigator.pop(context);
            },
            child: const Text('削除'),
          ),
        ],
      ),
    );
  }

  Widget _noOshiScaffold(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('グッズ')),
      body: EmptyState(
        icon: Icons.favorite_border,
        message: 'まず推しを登録しましょう',
        hint: 'グッズは推しごとに管理します',
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
}
