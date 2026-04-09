import 'package:flutter/material.dart';
import '../models/item.dart';
import '../models/item_database.dart';
import '../models/inventory.dart';

class ItemDatabaseScreen extends StatefulWidget {
  final Inventory? inventory;

  const ItemDatabaseScreen({
    super.key,
    this.inventory,
  });

  @override
  State<ItemDatabaseScreen> createState() => _ItemDatabaseScreenState();
}

class _ItemDatabaseScreenState extends State<ItemDatabaseScreen> {
  late ItemDatabase itemDatabase;
  late Inventory? inventory;

  @override
  void initState() {
    super.initState();
    itemDatabase = ItemDatabase();
    inventory = widget.inventory;
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
                  Navigator.pop(context);
                  itemDatabase.addItem(newItem);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${newItem.name} добавлен в базу'),
                      duration: const Duration(seconds: 2),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
              child: const Text('Добавить'),
            ),
          ],
        ),
      ),
    );
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
          if (inventory != null)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                inventory!.addItem(item.copy());
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} добавлен в инвентарь'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('В инвентарь'),
            ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              _showEditItemDialog(item);
            },
            icon: const Icon(Icons.edit),
            label: const Text('Редактировать'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              final index = itemDatabase.items.indexOf(item);
              if (index != -1) {
                Navigator.pop(context);
                itemDatabase.removeItemAt(index);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${item.name} удален из базы'),
                    duration: const Duration(seconds: 2),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            icon: const Icon(Icons.delete),
            label: const Text('Удалить'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[400],
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showEditItemDialog(Item item) {
    final index = itemDatabase.items.indexOf(item);
    if (index == -1) return;

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
                final oldName = itemDatabase.items[index].name;
                Navigator.pop(context);
                itemDatabase.updateItem(index, Item(
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
                ));
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
    return ListenableBuilder(
      listenable: itemDatabase,
      builder: (context, _) => Scaffold(
        body: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'База предметов (${itemDatabase.getItemCount()})',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    ElevatedButton.icon(
                      onPressed: _showAddItemDialog,
                      icon: const Icon(Icons.add),
                      label: const Text('Создать'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (itemDatabase.items.isEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Text(
                        'База предметов пуста',
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
                    itemCount: itemDatabase.items.length,
                    itemBuilder: (context, index) {
                      final item = itemDatabase.items[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          onTap: () => _showItemInfoDialog(item),
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
                          trailing: inventory != null
                            ? IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: () {
                                  inventory!.addItem(item.copy());
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('${item.name} добавлен в инвентарь'),
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                tooltip: 'Добавить в инвентарь',
                              )
                            : null,
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
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







