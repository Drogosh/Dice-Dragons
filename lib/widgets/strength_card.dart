import 'package:flutter/material.dart';

/// Виджет для отображения характеристики Силы (STR)
/// Отображает: характеристику, модификатор и спасбросок
class StrengthCard extends StatelessWidget {
  final int strength;        // 16
  final int modifier;        // +3
  final int savingThrow;     // +5

  const StrengthCard({
    super.key,
    required this.strength,
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
          // Фоновое изображение
          Positioned(
            left: 0,
            top: 0,
            child: Container(
              width: 59.12,
              height: 126,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/stats_widget/strength.png'),
                  fit: BoxFit.fill,
                ),
              ),
            ),
          ),

          // Основная характеристика (верхнее значение)
          Positioned(
            left: 21,
            top: 18,
            child: Text(
              '$strength',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color(0xFF452414),
                fontSize: 16,
                fontFamily: 'Tagesschrift Cyrillic',
                fontWeight: FontWeight.w400,
              ),
            ),
          ),

          // Модификатор (большое число в центре)
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

          // Спасбросок (нижнее значение)
          Positioned(
            left: 20,
            top: 93,
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

