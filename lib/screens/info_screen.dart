import 'package:flutter/material.dart';
import '../models/character.dart';
import 'character_selection_screen.dart';

class InfoScreen extends StatefulWidget {
  final Character character;

  const InfoScreen({
    super.key,
    required this.character,
  });

  @override
  State<InfoScreen> createState() => _InfoScreenState();
}

class _InfoScreenState extends State<InfoScreen> {
  late int displayedHP;

  @override
  void initState() {
    super.initState();
    // Пересчитываем HP при открытии экрана
    print('📖 InfoScreen.initState()');
    final recalculatedHP = widget.character.recalculateHP();
    displayedHP = recalculatedHP;

    // Если HP отличается, обновляем в character
    if (recalculatedHP != widget.character.hp) {
      print('   ⚠️  HP изменено с ${widget.character.hp} на $recalculatedHP');
      widget.character.hp = recalculatedHP;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Используем отображаемое HP (которое может быть пересчитано)
    final displayHP = widget.character.hp;
    final calculatedAC = widget.character.getCalculatedAC();

    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Заголовок с кнопкой смены персонажа
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Осн. информация:',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz),
                  tooltip: 'Сменить персонажа',
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (context) => const CharacterSelectionScreen(),
                      ),
                      (route) => false,
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Имя:', widget.character.name),
                    _buildInfoRow('Уровень:', '${widget.character.level}'),
                    _buildInfoRow('Опыт:', '${widget.character.level * 1000}'),
                    const Divider(height: 24),
                    _buildInfoRow('ХП:', '${displayHP}'),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Текущий КБ:', style: TextStyle(fontWeight: FontWeight.w500)),
                        GestureDetector(
                          onTap: () => _showACCalculation(),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.blue[50],
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: Colors.blue[200]!),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            child: Row(
                              children: [
                                Text(
                                  '$calculatedAC',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.blue[900],
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(
                                  Icons.info_outline,
                                  size: 16,
                                  color: Colors.blue[700],
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    _buildEquippedItemsInfo(),
                    const Divider(height: 24),
                    _buildInfoRow('Бонус мастерства:', '+${widget.character.proficiencyBonus}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEquippedItemsInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Надетые предметы:',
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 12),
        ),
        const SizedBox(height: 4),
        if (widget.character.equippedArmor != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4),
            child: Text(
              '🛡️ Броня: ${widget.character.equippedArmor!.name} (AC ${widget.character.equippedArmor!.armorClass})',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        if (widget.character.equippedShield != null)
          Padding(
            padding: const EdgeInsets.only(left: 8.0, top: 4),
            child: Text(
              '⚔️ Щит: ${widget.character.equippedShield!.name}',
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ...widget.character.equippedWeapons
            .where((w) => w != null)
            .map((w) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 4),
                  child: Text(
                    '🔱 ${w!.name}${w.damage != null ? ' (${w.damage})' : ''}',
                    style: const TextStyle(fontSize: 12),
                  ),
                )),
        if (widget.character.equippedArmor == null &&
            widget.character.equippedShield == null &&
            widget.character.equippedWeapons.every((w) => w == null))
          const Padding(
            padding: EdgeInsets.only(left: 8.0, top: 4),
            child: Text(
              'Нет надетых предметов',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  void _showACCalculation() {
    final acDetails = widget.character.getACCalculationDetails();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          acDetails,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
          ),
        ),
        duration: const Duration(seconds: 3),
        backgroundColor: Colors.grey[800],
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

