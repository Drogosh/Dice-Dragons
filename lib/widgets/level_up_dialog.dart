import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/character_class.dart';
import '../services/rules_engine.dart';

/// Диалог для повышения уровня персонажа
class LevelUpDialog extends StatefulWidget {
  final Character character;
  final CharacterClass? characterClass;
  final Function(int newHP) onConfirm;

  const LevelUpDialog({
    super.key,
    required this.character,
    this.characterClass,
    required this.onConfirm,
  });

  @override
  State<LevelUpDialog> createState() => _LevelUpDialogState();
}

class _LevelUpDialogState extends State<LevelUpDialog> {
  late TextEditingController _diceResultController;
  late int _conModifier;
  late String _hitDiceString;
  int? _calculatedHP;

  @override
  void initState() {
    super.initState();
    _diceResultController = TextEditingController();
    _conModifier = RulesEngine.calculateAbilityModifier(widget.character.constitution);
    
    if (widget.characterClass != null) {
      _hitDiceString = RulesEngine.getHitDiceString(widget.characterClass!);
    } else {
      _hitDiceString = 'd8'; // По умолчанию
    }
  }

  @override
  void dispose() {
    _diceResultController.dispose();
    super.dispose();
  }

  void _calculateHP() {
    final diceResult = int.tryParse(_diceResultController.text);
    
    if (diceResult == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Введите число')),
      );
      return;
    }

    // Валидация результата кубика
    final maxDice = int.parse(_hitDiceString.replaceAll('d', ''));
    if (diceResult < 1 || diceResult > maxDice) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Результат должен быть от 1 до $maxDice')),
      );
      return;
    }

    final hpGain = RulesEngine.calculateHPGain(diceResult, _conModifier);
    final newHP = widget.character.hp + hpGain;

    setState(() => _calculatedHP = newHP);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        'Повышение уровня ${widget.character.level} → ${widget.character.level + 1}',
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Информация о текущем HP
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Текущий HP: ${widget.character.hp}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Модификатор Телосложения: ${_conModifier >= 0 ? '+' : ''}$_conModifier',
                    style: TextStyle(
                      color: _conModifier >= 0 ? Colors.green : Colors.red,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Инструкция по кубику
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.amber.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Киньте кубик: $_hitDiceString',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Формула: результат кубика + модификатор Телосложения',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Поле ввода результата
            TextField(
              controller: _diceResultController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Введите результат кубика',
                border: const OutlineInputBorder(),
                labelText: 'Результат $_hitDiceString',
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 16,
                ),
              ),
              onChanged: (_) {
                setState(() => _calculatedHP = null);
              },
            ),
            const SizedBox(height: 12),

            // Кнопка расчёта
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _calculateHP,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                child: const Text(
                  'Рассчитать',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Результат расчёта
            if (_calculatedHP != null) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Результат:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'HP увеличится на: ${_calculatedHP! - widget.character.hp}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.green[700],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Новый HP: $_calculatedHP',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Отмена'),
        ),
        ElevatedButton(
          onPressed: _calculatedHP == null
              ? null
              : () {
                  widget.onConfirm(_calculatedHP!);
                  Navigator.pop(context);
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            disabledBackgroundColor: Colors.grey,
          ),
          child: const Text(
            'Подтвердить',
            style: TextStyle(color: Colors.white),
          ),
        ),
      ],
    );
  }
}

