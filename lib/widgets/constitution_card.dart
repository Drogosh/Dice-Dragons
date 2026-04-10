import 'package:flutter/material.dart';

/// Виджет для отображения характеристики Телосложения (CON)
class ConstitutionCard extends StatelessWidget {
  final int constitution;
  final int modifier;
  final int savingThrow;
  final bool isSelected;

  const ConstitutionCard({
    super.key,
    required this.constitution,
    required this.modifier,
    required this.savingThrow,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgImage = isSelected
        ? 'assets/stats_widget/physique_on.png'
        : 'assets/stats_widget/physique.png';

    return Container(
      width: 59.12,
      height: 126,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 59.12,
              height: 126,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(bgImage),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          Positioned(
            left: 21,
            top: 13,
            child: Text(
              '$constitution',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF452414),
                fontSize: 16,
                fontFamily: 'Tagesschrift Cyrillic',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Positioned(
            left: 15,
            top: 29,
            child: Text(
              modifier >= 0 ? '+$modifier' : '$modifier',
              style: TextStyle(
                color: const Color(0xFF452414),
                fontSize: 24.75,
                fontFamily: 'Tagesschrift Cyrillic',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
          Positioned(
            left: 20,
            top: 90,
            child: Text(
              savingThrow >= 0 ? '+$savingThrow' : '$savingThrow',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF452414),
                fontSize: 16,
                fontFamily: 'Tagesschrift Cyrillic',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

