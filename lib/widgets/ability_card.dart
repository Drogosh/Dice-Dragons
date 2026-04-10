import 'package:flutter/material.dart';

class AbilityCard extends StatelessWidget {
  final String backgroundAsset; // путь к фону (напр. 'assets/images/ability_str.png')
  final int abilityScore;       // основная характеристика (21)
  final int modifier;            // модификатор (15)
  final int savingThrow;         // спасбросок (20)
  final VoidCallback? onTap;
  final bool isSelected;

  const AbilityCard({
    super.key,
    required this.backgroundAsset,
    required this.abilityScore,
    required this.modifier,
    required this.savingThrow,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 59,
        height: 162,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(backgroundAsset),
            fit: BoxFit.fill,
          ),
          border: isSelected
              ? Border.all(
                  color: Colors.amber[700]!,
                  width: 2,
                )
              : null,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Stack(
          children: [
            // Основная характеристика (x=21, y=18, размер 16)
            Positioned(
              left: 21,
              top: 18,
              child: Text(
                '$abilityScore',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ),
            // Модификатор (x=15, y=29, размер 25)
            Positioned(
              left: 15,
              top: 29,
              child: Text(
                modifier >= 0 ? '+$modifier' : '$modifier',
                style: TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.bold,
                  color: modifier >= 0 ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
            // Спасбросок (x=20, y=93, размер 16)
            Positioned(
              left: 20,
              top: 93,
              child: Text(
                savingThrow >= 0 ? '+$savingThrow' : '$savingThrow',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: savingThrow >= 0 ? Colors.green[700] : Colors.red[700],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

