import 'package:flutter/material.dart';

/// Виджет для отображения характеристики Интеллекта (INT)
class IntelligenceCard extends StatelessWidget {
  final int intelligence;
  final int modifier;
  final int savingThrow;

  const IntelligenceCard({
    super.key,
    required this.intelligence,
    required this.modifier,
    required this.savingThrow,
  });

  @override
  Widget build(BuildContext context) {
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
                  image: AssetImage('assets/stats_widget/intelligence.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),
          Positioned(
            left: 21,
            top: 13,
            child: Text(
              '$intelligence',
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

