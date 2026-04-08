import 'package:flutter/material.dart';
import '../models/item.dart';

class ItemCard extends StatelessWidget {
  final Item item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const ItemCard({
    super.key,
    required this.item,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с названием и типом
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
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
                          _getTypeLabel(item.type),
                          style: const TextStyle(
                            fontSize: 11,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: const Text('Редактировать'),
                      onTap: onEdit,
                    ),
                    PopupMenuItem(
                      child: const Text('Удалить'),
                      onTap: onDelete,
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Описание
            if (item.description.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Описание:',
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    item.description,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),

            // Информация об оружии
            if (item.type == ItemType.weapon && item.damage != null)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow(context, 'Урон:', item.damage!),
                  if (item.damageType != null)
                    _buildInfoRow(
                      context,
                      'Тип урона:',
                      _getDamageTypeLabel(item.damageType!),
                    ),
                  const SizedBox(height: 12),
                ],
              ),

            // Информация о броне
            if (item.type == ItemType.armor)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (item.armorClass != null)
                    _buildInfoRow(context, 'Класс брони:', '${item.armorClass}'),
                  if (item.armorType != null)
                    _buildInfoRow(
                      context,
                      'Тип брони:',
                      _getArmorTypeLabel(item.armorType!),
                    ),
                  const SizedBox(height: 12),
                ],
              ),

            // Бонус
            if (item.bonus > 0)
              _buildBonusRow(context, 'Бонус:', '+${item.bonus}'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildBonusRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(4),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Text(
              value,
              style: TextStyle(
                color: Colors.green[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
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

