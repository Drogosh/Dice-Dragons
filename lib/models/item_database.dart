import 'package:flutter/foundation.dart';
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
  }

  void removeItem(Item item) {
    items.remove(item);
    notifyListeners();
  }

  void removeItemAt(int index) {
    items.removeAt(index);
    notifyListeners();
  }

  void updateItem(int index, Item item) {
    items[index] = item;
    notifyListeners();
  }

  List<Item> getAllItems() {
    return List.from(items);
  }

  int getItemCount() {
    return items.length;
  }
}

