import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/models.dart';

class CartController extends ChangeNotifier {
  static const _prefsKey = 'cart_quantities';
  final Map<String, int> _quantities = {};
  final Map<String, FoodItem> _registry = {
    for (final f in FoodItem.seed) f.id: f,
  };

  /// Keeps the cart in sync with the live menu (prices, availability, new
  /// items). Intentionally does not notify listeners — it runs during build.
  void sync(List<FoodItem> menuItems) {
    final juice = menuItems.where((item) => item.id == 'juice').firstOrNull;
    _registry
      ..clear()
      ..addEntries(menuItems.map((f) => MapEntry(f.id, f)));
    if (juice != null) {
      for (final variety in FoodItem.juiceVarieties) {
        final item = juice.asJuiceVariety(variety);
        _registry[item.id] = item;
      }
    }
  }

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefsKey);
    if (raw == null) return;
    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _quantities.addAll(
        decoded.map((k, v) => MapEntry(k, (v as num).toInt())),
      );
      notifyListeners();
    } catch (_) {
      await prefs.remove(_prefsKey);
    }
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, jsonEncode(_quantities));
  }

  Map<FoodItem, int> get items => {
    for (final e in _quantities.entries)
      if (e.value > 0 && _registry[e.key] != null) _registry[e.key]!: e.value,
  };
  int quantityOf(FoodItem item) => _quantities[item.id] ?? 0;
  int get count => items.values.fold(0, (a, b) => a + b);
  double get total =>
      items.entries.fold(0, (sum, e) => sum + e.key.price * e.value);
  void add(FoodItem item, {int quantity = 1}) {
    if (item.isAvailable &&
        item.availability != Availability.soldOut &&
        quantity > 0) {
      _registry[item.id] = item;
      _quantities[item.id] = quantityOf(item) + quantity;
      notifyListeners();
      _save();
    }
  }

  void decrease(FoodItem item) {
    final q = quantityOf(item);
    if (q <= 1) {
      _quantities.remove(item.id);
    } else {
      _quantities[item.id] = q - 1;
    }
    notifyListeners();
    _save();
  }

  void remove(FoodItem item) {
    _quantities.remove(item.id);
    notifyListeners();
    _save();
  }

  void clear() {
    _quantities.clear();
    notifyListeners();
    _save();
  }
}

final cart = CartController();
