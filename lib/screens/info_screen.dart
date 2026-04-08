import 'package:flutter/material.dart';
import '../models/character.dart';

class InfoScreen extends StatelessWidget {
  final Character character;

  const InfoScreen({
    super.key,
    required this.character,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Информация о персонаже',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInfoRow('Имя:', character.name),
                    _buildInfoRow('Уровень:', '${character.level}'),
                    _buildInfoRow('Опыт:', '${character.level * 1000}'),
                    const Divider(height: 24),
                    _buildInfoRow('ХП:', '${character.hp}'),
                    _buildInfoRow('Класс брони:', '${character.ac}'),
                    _buildInfoRow('Бонус мастерства:', '+${character.proficiencyBonus}'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
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
}

