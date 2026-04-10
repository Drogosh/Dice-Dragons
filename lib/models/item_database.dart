import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'item.dart';

class ItemDatabase extends ChangeNotifier {
  static final ItemDatabase _instance = ItemDatabase._internal();

  late List<Item> items;

  factory ItemDatabase() {
    return _instance;
  }

  ItemDatabase._internal() {
    items = [];
    _initializeDefaultItems();
  }

  void _initializeDefaultItems() {
    // Добавляем несколько предметов по умолчанию
    items.addAll([
      Item(
        name: 'Длинный меч',
        type: ItemType.weapon,
        description: 'Классическое оружие ближнего боя',
        damage: '1d8',
        damageType: DamageType.slashing,
        bonus: 0,
      ),
      Item(
        name: 'Кожаная броня',
        type: ItemType.armor,
        description: 'Легкая защита из кожи',
        armorClass: 11,
        armorType: ArmorType.light,
        bonus: 0,
      ),
      Item(
        name: 'Деревянный щит',
        type: ItemType.armor,
        description: 'Простой деревянный щит',
        armorClass: 2,
        armorType: ArmorType.shield,
        bonus: 0,
      ),
    ]);
  }

  void addItem(Item item) {
    items.add(item);
    notifyListeners();
    _saveDatabase();
  }

  void removeItem(Item item) {
    items.remove(item);
    notifyListeners();
    _saveDatabase();
  }

  void removeItemAt(int index) {
    items.removeAt(index);
    notifyListeners();
    _saveDatabase();
  }

  void updateItem(int index, Item item) {
    items[index] = item;
    notifyListeners();
    _saveDatabase();
  }

  List<Item> getAllItems() {
    return List.from(items);
  }

  int getItemCount() {
    return items.length;
  }

  // ==================== СОХРАНЕНИЕ И ЗАГРУЗКА ====================

  /// Сохранить базу предметов в JSON
  String toJsonString() {
    final itemsList = items.map((item) => item.toMap()).toList();
    return jsonEncode(itemsList);
  }

  /// Загрузить базу предметов из JSON
  void fromJsonString(String jsonString) {
    try {
      final list = jsonDecode(jsonString) as List<dynamic>;
      items.clear();
      for (var item in list) {
        items.add(Item.fromMap(item as Map<String, dynamic>));
      }
      notifyListeners();
      print('✅ База предметов загружена (${items.length} предметов)');
    } catch (e) {
      print('❌ Ошибка загрузки базы предметов: $e');
    }
  }

  /// Сохранить базу предметов локально (внутренняя логика)
  void _saveDatabase() {
    // Будет вызвано из StorageService
    print('💾 ItemDatabase._saveDatabase(): ${items.length} предметов');
  }
}

