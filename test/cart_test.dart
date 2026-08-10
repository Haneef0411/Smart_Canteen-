import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smart_canteen_app/models/models.dart';
import 'package:smart_canteen_app/state/app_state.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late CartController controller;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    controller = CartController();
  });

  FoodItem menuItem(
    String id, {
    Availability availability = Availability.available,
  }) => FoodItem(
    id: id,
    name: id,
    description: 'test',
    category: 'Meals',
    price: 100,
    minutes: 5,
    icon: Icons.rice_bowl,
    availability: availability,
  );

  test('add increases count and total', () async {
    final a = menuItem('a'), b = menuItem('b');
    controller.sync([a, b]);
    controller.add(a);
    controller.add(a);
    controller.add(b);
    expect(controller.count, 3);
    expect(controller.total, 300);
    expect(controller.items[a], 2);
  });

  test('add accepts a selected quantity', () {
    final item = menuItem('quantity-item');
    controller.sync([item]);
    controller.add(item, quantity: 4);
    expect(controller.quantityOf(item), 4);
    expect(controller.total, 400);
  });

  test('sold out items cannot be added', () {
    final item = menuItem('a', availability: Availability.soldOut);
    controller.add(item);
    expect(controller.count, 0);
    expect(controller.items, isEmpty);
  });

  test('fresh juice varieties remain separate cart lines after sync', () {
    final juice = FoodItem.seed.firstWhere((item) => item.id == 'juice');
    controller.sync([juice]);
    final mango = juice.asJuiceVariety('Mango');
    final orange = juice.asJuiceVariety('Orange');

    controller.add(mango);
    controller.add(orange);
    controller.sync([juice]);

    expect(controller.count, 2);
    expect(
      controller.items.entries
          .where((entry) => entry.key.name == 'Mango Juice')
          .single
          .value,
      1,
    );
    expect(
      controller.items.entries
          .where((entry) => entry.key.name == 'Orange Juice')
          .single
          .value,
      1,
    );
  });

  test('decrease removes item at quantity one', () {
    controller.sync([menuItem('a')]);
    final item = menuItem('a');
    controller.add(item);
    controller.decrease(item);
    expect(controller.count, 0);
    expect(controller.items, isEmpty);
  });

  test('decrease decrements quantity above one', () {
    controller.sync([menuItem('a')]);
    final item = menuItem('a');
    controller.add(item);
    controller.add(item);
    controller.decrease(item);
    expect(controller.count, 1);
  });

  test('remove and clear empty the cart', () {
    controller.sync([menuItem('a'), menuItem('b')]);
    final item = menuItem('a');
    controller.add(item);
    controller.add(menuItem('b'));
    controller.remove(item);
    expect(controller.count, 1);
    controller.clear();
    expect(controller.count, 0);
    expect(controller.items, isEmpty);
  });

  test('quantities survive a restore from storage', () async {
    controller.sync([menuItem('a')]);
    final item = menuItem('a');
    controller.add(item);
    controller.add(item);

    final restored = CartController();
    restored.sync([menuItem('a')]);
    await restored.restore();
    expect(restored.count, 2);
    expect(restored.total, 200);
  });

  test('quantities for items not on the menu are ignored', () async {
    final item = menuItem('ghost');
    controller.add(item);
    controller.sync([menuItem('a')]);
    expect(controller.items, isEmpty);
    expect(controller.count, 0);
  });

  test('sync updates prices from the live menu', () {
    final item = menuItem('a');
    controller.add(item);
    controller.sync([
      FoodItem(
        id: 'a',
        name: 'a',
        description: 'test',
        category: 'Meals',
        price: 250,
        minutes: 5,
        icon: Icons.rice_bowl,
      ),
    ]);
    expect(controller.total, 250);
  });
}
