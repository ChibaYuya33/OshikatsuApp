import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../event/event_screen.dart';
import '../expense/expense_screen.dart';
import '../feed/feed_screen.dart';
import '../goods/goods_list_screen.dart';
import '../home/home_screen.dart';

/// 下部ナビゲーションでタブを切り替えるメイン画面。
class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _index = 0;

  // 初回表示を軽くするため、訪問したタブだけを構築する(遅延ロード)。
  // 未訪問タブは空Widgetにし、グッズ/支出(fl_chart)/イベント(table_calendar)等の
  // 重い構築を必要になるまで遅らせる。一度開けば IndexedStack が状態を保持するので
  // 再表示は高速。
  final Set<int> _loaded = {0};

  static const _tabs = [
    HomeScreen(),
    GoodsListScreen(),
    ExpenseScreen(),
    EventScreen(),
    FeedScreen(),
  ];

  void _select(int i) {
    setState(() {
      _index = i;
      _loaded.add(i);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // 遷移/アニメ中にシェルをレイヤーキャッシュ化し、毎フレームの再ラスタライズを避ける。
      body: RepaintBoundary(
        child: IndexedStack(
          index: _index,
          children: [
            for (var i = 0; i < _tabs.length; i++)
              _loaded.contains(i) ? _tabs[i] : const SizedBox.shrink(),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _select,
        destinations: const [
          NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'ホーム'),
          NavigationDestination(
              icon: Icon(Icons.card_giftcard_outlined),
              selectedIcon: Icon(Icons.card_giftcard),
              label: 'グッズ'),
          NavigationDestination(
              icon: Icon(Icons.savings_outlined),
              selectedIcon: Icon(Icons.savings),
              label: '支出'),
          NavigationDestination(
              icon: Icon(Icons.event_outlined),
              selectedIcon: Icon(Icons.event),
              label: 'イベント'),
          NavigationDestination(
              icon: Icon(Icons.rss_feed_outlined),
              selectedIcon: Icon(Icons.rss_feed),
              label: '情報'),
        ],
      ),
    );
  }
}
