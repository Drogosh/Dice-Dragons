import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/inventory.dart';
import '../models/item.dart';
import 'item_database_screen.dart';

class InventoryScreen extends StatefulWidget {
  final Inventory inventory;
  final Character character;

  const InventoryScreen({
    super.key,
    required this.inventory,
    required this.character,
  });

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  late Inventory inventory;
  late Character character;

  @override
  void initState() {
    super.initState();
    inventory = widget.inventory;
    character = widget.character;
  }

  void _showAddItemDialog() {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final damageController = TextEditingController();
    final bonusController = TextEditingController();
    final acController = TextEditingController();

    ItemType selectedType = ItemType.miscellaneous;
    DamageType? selectedDamageType = DamageType.slashing;
    ArmorType? selectedArmorType = ArmorType.light;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Добавить предмет'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название предмета',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButton<ItemType>(
                  value: selectedType,
                  isExpanded: true,
                  items: ItemType.values.map((type) {
                    String label = _getTypeLabel(type);
                    return DropdownMenuItem(
                      value: type,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Поля для оружия
                if (selectedType == ItemType.weapon) ...[
                  TextField(
                    controller: damageController,
                    decoration: const InputDecoration(
                      labelText: 'Урон (например: 1d8)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Тип урона:'),
                  DropdownButton<DamageType>(
                    value: selectedDamageType,
                    isExpanded: true,
                    items: DamageType.values.map((type) {
                      String label = _getDamageTypeLabel(type);
                      return DropdownMenuItem(
                        value: type,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedDamageType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Поля для брони
                if (selectedType == ItemType.armor) ...[
                  TextField(
                    controller: acController,
                    decoration: const InputDecoration(
                      labelText: 'Класс брони',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text('Тип брони:'),
                  DropdownButton<ArmorType>(
                    value: selectedArmorType,
                    isExpanded: true,
                    items: ArmorType.values.map((type) {
                      String label = _getArmorTypeLabel(type);
                      return DropdownMenuItem(
                        value: type,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedArmorType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Бонус для всех
                TextField(
                  controller: bonusController,
                  decoration: const InputDecoration(
                    labelText: 'Бонус (опционально)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                if (nameController.text.isNotEmpty) {
                  final newItem = Item(
                    name: nameController.text,
                    type: selectedType,
                    description: descriptionController.text,
                    bonus: int.tryParse(bonusController.text) ?? 0,
                    damage: selectedType == ItemType.weapon
                        ? damageController.text.isNotEmpty
                            ? damageController.text
                            : null
                        : null,
                    damageType: selectedType == ItemType.weapon
                        ? selectedDamageType
                        : null,
                    armorClass: selectedType == ItemType.armor
                        ? int.tryParse(acController.text)
                        : null,
                    armorType: selectedType == ItemType.armor
                        ? selectedArmorType
                        : null,
                  );
                  setState(() {
                    inventory.addItem(newItem);
                  });
                  Navigator.pop(context);
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
  }

  void _equipUnequipItem(Item item) {
    if (item.type == ItemType.weapon) {
      // Проверяем надеты ли это оружие
      bool isEquipped = character.equippedWeapons.contains(item);

      if (isEquipped) {
        // Снимаем оружие
        final slotIndex = character.equippedWeapons.indexOf(item);
        character.unequipWeapon(slotIndex);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.name} снято'),
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // Ищем свободный слот
        final emptySlot = character.equippedWeapons.indexWhere((w) => w == null);
        if (emptySlot != -1) {
          character.equipWeapon(emptySlot, item);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} надено (слот ${emptySlot + 1})'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Все слоты для оружия заняты'),
              duration: Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
          return;
        }
      }
    } else if (item.type == ItemType.armor) {
      if (item.armorType == ArmorType.shield) {
        // Щит
        if (character.equippedShield == item) {
          character.equipShield(null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} снято'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          character.equipShield(item);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} надено'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        // Броня
        if (character.equippedArmor == item) {
          character.equipArmor(null);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} снято'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          character.equipArmor(item);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} надено (AC: ${character.getCalculatedAC()})'),
              duration: const Duration(seconds: 2),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    setState(() {});
  }

  bool _isItemEquipped(Item item) {
    if (item.type == ItemType.weapon) {
      return character.equippedWeapons.contains(item);
    } else if (item.type == ItemType.armor) {
      if (item.armorType == ArmorType.shield) {
        return character.equippedShield == item;
      } else {
        return character.equippedArmor == item;
      }
    }
    return false;
  }

  void _showItemInfoDialog(Item item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(item.name),
            ),
            Container(
              decoration: BoxDecoration(
                color: _getTypeColor(item.type),
                borderRadius: BorderRadius.circular(4),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 6,
              ),
              child: Text(
                _getTypeLabel(item.type),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Описание
              if (item.description.isNotEmpty) ...[
                const Text(
                  'Описание:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.maxFinite,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(item.description),
                ),
                const SizedBox(height: 16),
              ],

              // Для оружия
              if (item.type == ItemType.weapon) ...[
                if (item.damage != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Урон:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.red[200]!),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          item.damage!,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (item.damageType != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Тип урона:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_getDamageTypeLabel(item.damageType!)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],

              // Для брони
              if (item.type == ItemType.armor) ...[
                if (item.armorClass != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Класс брони:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.blue[50],
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: Colors.blue[200]!),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        child: Text(
                          '${item.armorClass}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[900],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                if (item.armorType != null) ...[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Тип брони:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(_getArmorTypeLabel(item.armorType!)),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
              ],

              // Бонус
              if (item.bonus != 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Бонус:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 4,
                      ),
                      child: Text(
                        '${item.bonus > 0 ? '+' : ''}${item.bonus}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.green[900],
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
          if (item.type == ItemType.weapon || item.type == ItemType.armor)
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                _equipUnequipItem(item);
              },
              child: Text(
                _isItemEquipped(item) ? 'Снять' : 'Надеть',
              ),
            ),
        ],
      ),
    );
  }

  void _showEditItemDialog(int index) {
    final item = inventory.items[index];
    final nameController = TextEditingController(text: item.name);
    final descriptionController = TextEditingController(text: item.description);
    final damageController = TextEditingController(text: item.damage ?? '');
    final bonusController = TextEditingController(text: item.bonus.toString());
    final acController = TextEditingController(
      text: item.armorClass?.toString() ?? '',
    );

    ItemType selectedType = item.type;
    DamageType? selectedDamageType = item.damageType ?? DamageType.slashing;
    ArmorType? selectedArmorType = item.armorType ?? ArmorType.light;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Редактировать предмет'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Название предмета',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Описание',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                DropdownButton<ItemType>(
                  value: selectedType,
                  isExpanded: true,
                  items: ItemType.values.map((type) {
                    String label = _getTypeLabel(type);
                    return DropdownMenuItem(
                      value: type,
                      child: Text(label),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() {
                        selectedType = value;
                      });
                    }
                  },
                ),
                const SizedBox(height: 16),

                // Поля для оружия
                if (selectedType == ItemType.weapon) ...[
                  TextField(
                    controller: damageController,
                    decoration: const InputDecoration(
                      labelText: 'Урон (например: 1d8)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Тип урона:'),
                  DropdownButton<DamageType>(
                    value: selectedDamageType,
                    isExpanded: true,
                    items: DamageType.values.map((type) {
                      String label = _getDamageTypeLabel(type);
                      return DropdownMenuItem(
                        value: type,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedDamageType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Поля для брони
                if (selectedType == ItemType.armor) ...[
                  TextField(
                    controller: acController,
                    decoration: const InputDecoration(
                      labelText: 'Класс брони',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),
                  const Text('Тип брони:'),
                  DropdownButton<ArmorType>(
                    value: selectedArmorType,
                    isExpanded: true,
                    items: ArmorType.values.map((type) {
                      String label = _getArmorTypeLabel(type);
                      return DropdownMenuItem(
                        value: type,
                        child: Text(label),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedArmorType = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Бонус для всех
                TextField(
                  controller: bonusController,
                  decoration: const InputDecoration(
                    labelText: 'Бонус',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Отмена'),
            ),
            ElevatedButton(
              onPressed: () {
                final oldName = inventory.items[index].name;
                // Закрываем диалог
                Navigator.pop(context);
                // Обновляем предмет с автообновлением UI
                this.setState(() {
                  inventory.items[index] = Item(
                    name: nameController.text,
                    type: selectedType,
                    description: descriptionController.text,
                    bonus: int.tryParse(bonusController.text) ?? 0,
                    damage: selectedType == ItemType.weapon
                        ? damageController.text.isNotEmpty
                            ? damageController.text
                            : null
                        : null,
                    damageType: selectedType == ItemType.weapon
                        ? selectedDamageType
                        : null,
                    armorClass: selectedType == ItemType.armor
                        ? int.tryParse(acController.text)
                        : null,
                    armorType: selectedType == ItemType.armor
                        ? selectedArmorType
                        : null,
                  );
                });
                // Показываем сообщение об успехе
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$oldName обновлен'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              child: const Text('Сохранить'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Инвентарь (${inventory.getItemCount()})',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ItemDatabaseScreen(inventory: inventory),
                      ),
                    );
                  },
                  icon: const Icon(Icons.library_books),
                  label: const Text('База'),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Список предметов
            if (inventory.items.isEmpty)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Text(
                    'Инвентарь пуст',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: inventory.items.length,
                itemBuilder: (context, index) {
                   // Сортируем так, чтобы надетые предметы были в верху
                   final sortedItems = List<Item>.from(inventory.items);
                   sortedItems.sort((a, b) {
                     final aEquipped = _isItemEquipped(a) ? 0 : 1;
                     final bEquipped = _isItemEquipped(b) ? 0 : 1;
                     return aEquipped.compareTo(bEquipped);
                   });
                   
                    final item = sortedItems[index];
                    final actualIndex = inventory.items.indexOf(item);
                    return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        color: _isItemEquipped(item) ? Colors.blue[50] : null,
                        child: ListTile(
                          onTap: () => _showItemInfoDialog(item),
                          leading: _isItemEquipped(item)
                              ? Tooltip(
                                  message: 'Надевено',
                                  child: Icon(
                                    Icons.check_circle,
                                    color: Colors.green[700],
                                  ),
                                )
                              : null,
                          title: Text(
                            item.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Row(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: _getTypeColor(item.type),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                child: Text(
                                  _getItemTypeDisplay(item),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ),
                             if (item.bonus > 0) ...[
                               const SizedBox(width: 8),
                               Container(
                                 decoration: BoxDecoration(
                                   color: Colors.green[100],
                                   borderRadius: BorderRadius.circular(4),
                                 ),
                                 padding: const EdgeInsets.symmetric(
                                   horizontal: 8,
                                   vertical: 4,
                                 ),
                                 child: Text(
                                   '+${item.bonus}',
                                   style: TextStyle(
                                     fontSize: 11,
                                     color: Colors.green[900],
                                     fontWeight: FontWeight.w500,
                                   ),
                                 ),
                               ),
                             ],
                           ],
                         ),
                         trailing: PopupMenuButton(
                           itemBuilder: (context) => [
                             if (item.type == ItemType.weapon || item.type == ItemType.armor)
                               PopupMenuItem(
                                 onTap: () => _equipUnequipItem(item),
                                 child: Text(_isItemEquipped(item) ? 'Снять' : 'Надеть'),
                               ),
                             PopupMenuItem(
                               onTap: () => _showEditItemDialog(actualIndex),
                               child: const Text('Редактировать'),
                             ),
                              PopupMenuItem(
                                onTap: () {
                                  final itemName = inventory.items[actualIndex].name;
                                  setState(() {
                                    inventory.removeItemAt(actualIndex);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('$itemName удален из инвентаря'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                child: const Text('Удалить'),
                              ),
                           ],
                         ),
                       ),
                     );
                 },
              ),
          ],
        ),
      ),
    );
  }

  String _getItemTypeDisplay(Item item) {
    switch (item.type) {
      case ItemType.weapon:
        if (item.damage != null) {
          return '⚔️ Оружие: ${item.damage}';
        }
        return 'Оружие';
      case ItemType.armor:
        if (item.armorClass != null) {
          String armorTypeLabel = item.armorType != null
              ? _getArmorTypeLabel(item.armorType!)
              : '';
          return '🛡️ Броня($armorTypeLabel): ${item.armorClass}';
        }
        return 'Броня';
      case ItemType.accessory:
        return 'Украшение';
      case ItemType.consumable:
        return 'Расходник';
      case ItemType.miscellaneous:
        return 'Прочее';
    }
  }

  String _getTypeLabel(ItemType type) {
    switch (type) {
      case ItemType.weapon:
        return 'Оружие';
      case ItemType.armor:
        return 'Броня';
      case ItemType.accessory:
        return 'Украшение';
      case ItemType.consumable:
        return 'Расходник';
      case ItemType.miscellaneous:
        return 'Прочее';
    }
  }

  Color _getTypeColor(ItemType type) {
    switch (type) {
      case ItemType.weapon:
        return Colors.red[400]!;
      case ItemType.armor:
        return Colors.blue[400]!;
      case ItemType.accessory:
        return Colors.purple[400]!;
      case ItemType.consumable:
        return Colors.green[400]!;
      case ItemType.miscellaneous:
        return Colors.grey[400]!;
    }
  }

  String _getDamageTypeLabel(DamageType type) {
    switch (type) {
      case DamageType.slashing:
        return 'Рубящий';
      case DamageType.piercing:
        return 'Колющий';
      case DamageType.bludgeoning:
        return 'Дробящий';
      case DamageType.fire:
        return 'Огонь';
      case DamageType.cold:
        return 'Холод';
      case DamageType.lightning:
        return 'Молния';
      case DamageType.poison:
        return 'Яд';
      case DamageType.psychic:
        return 'Психический';
      case DamageType.radiant:
        return 'Лучистый';
      case DamageType.necrotic:
        return 'Некротический';
      case DamageType.force:
        return 'Силовое поле';
    }
  }

  String _getArmorTypeLabel(ArmorType type) {
    switch (type) {
      case ArmorType.light:
        return 'Легкая';
      case ArmorType.medium:
        return 'Средняя';
      case ArmorType.heavy:
        return 'Тяжелая';
      case ArmorType.shield:
        return 'Щит';
    }
  }
}

