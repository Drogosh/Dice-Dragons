import 'dart:convert';
import 'item.dart';

class Inventory {
  List<Item> items;

  Inventory({List<Item>? items}) : items = items ?? [];

  /// Добавить предмет в инвентарь
  void addItem(Item item) {
    items.add(item);
  }

  /// Удалить предмет из инвентаря
  bool removeItem(Item item) {
    return items.remove(item);
  }

  /// Удалить предмет по индексу
  Item removeItemAt(int index) {
    return items.removeAt(index);
  }

  /// Получить количество предметов
  int getItemCount() {
    return items.length;
  }

  /// Получить все оружие в инвентаре
  List<Item> getWeapons() {
    return items.where((item) => item.type == ItemType.weapon).toList();
  }

  /// Получить всю броню в инвентаре
  List<Item> getArmor() {
    return items.where((item) => item.type == ItemType.armor).toList();
  }

  /// Получить все украшения в инвентаре
  List<Item> getAccessories() {
    return items.where((item) => item.type == ItemType.accessory).toList();
  }

  /// Получить все расходуемые предметы
  List<Item> getConsumables() {
    return items.where((item) => item.type == ItemType.consumable).toList();
  }

  /// Получить предмет по id
  Item? findItemById(String id) {
    try {
      return items.firstWhere((item) => item.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Проверить наличие предмета по id
  bool containsId(String id) {
    return items.any((item) => item.id == id);
  }

  /// Получить предмет по названию
  Item? findItemByName(String name) {
    try {
      return items.firstWhere((item) => item.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Проверить наличие предмета
  bool containsItem(Item item) {
    return items.contains(item);
  }

  /// Очистить инвентарь
  void clear() {
    items.clear();
  }

  /// Получить список всех предметов
  List<Item> getAllItems() {
    return List.from(items);
  }

  /// Для сериализации/десериализации
  List<Map<String, dynamic>> toList() {
    return items.map((item) => item.toMap()).toList();
  }

  factory Inventory.fromList(List<dynamic> list) {
    final inventory = Inventory();
    for (var item in list) {
      inventory.addItem(Item.fromMap(item as Map<String, dynamic>));
    }
    return inventory;
  }

  String toJsonString() {
    return jsonEncode(toList());
  }

  factory Inventory.fromJsonString(String jsonString) {
    final list = jsonDecode(jsonString) as List<dynamic>;
    return Inventory.fromList(list);
  }
}
