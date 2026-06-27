import 'package:flutter_test/flutter_test.dart';
import 'package:oshikatsu_app/core/db/local_store.dart';
import 'package:oshikatsu_app/core/db/models.dart';

void main() {
  test('DbData は JSON 往復で内容を保持する', () {
    final data = DbData(
      oshis: [
        Oshi(
          id: 'o1',
          name: 'みーちゃん',
          themeColor: 0xFFFF6FA5,
          createdAt: DateTime(2026, 1, 1),
        ),
      ],
      goods: [
        Goods(
          id: 'g1',
          oshiId: 'o1',
          name: 'アクスタ',
          price: 1500,
          purchaseDate: DateTime(2026, 6, 1),
          category: GoodsCategory.acrylic,
        ),
      ],
    );

    final restored = DbData.fromJson(data.toJson());
    expect(restored.oshis.single.name, 'みーちゃん');
    expect(restored.goods.single.category, GoodsCategory.acrylic);
    expect(restored.goods.single.price, 1500);
  });

  test('LocalStore は import/export でデータを復元できる', () async {
    final store = LocalStore(MemoryStoreBackend());
    await store.load();
    store.data.oshis.add(Oshi(
      id: 'o1',
      name: 'テスト推し',
      themeColor: 0xFF42A5F5,
      createdAt: DateTime(2026, 1, 1),
    ));
    await store.save();

    final json = store.exportJson();

    final store2 = LocalStore(MemoryStoreBackend());
    await store2.importJson(json);
    expect(store2.data.oshis.single.name, 'テスト推し');
  });
}
