import 'package:flutter/material.dart';

class SkillItemWidget extends StatelessWidget {
  final String name;
  final int bonus;
  final bool isProficient;
  final bool isEditing;
  final String? ability;
  final VoidCallback? onToggle;

  const SkillItemWidget({
    super.key,
    required this.name,
    required this.bonus,
    required this.isProficient,
    required this.isEditing,
    this.ability,
    this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final bgImage = isProficient
        ? 'assets/stats_widget/skill_on.png'
        : 'assets/stats_widget/skill_off.png';

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6), // 🔥 расстояние между строками
      child: AspectRatio(
        aspectRatio: 13, // 🔥 подгони под картинку
        child: LayoutBuilder(
          builder: (context, constraints) {
            final w = constraints.maxWidth;
            final h = constraints.maxHeight;

            return GestureDetector(
              onTap: isEditing ? onToggle : null,
              child: Stack(
                children: [
                  // 🔥 ФОН
                  Positioned.fill(
                    child: Image.asset(
                      bgImage,
                      fit: BoxFit.fill,
                    ),
                  ),

                  // 📝 НАЗВАНИЕ НАВЫКА
                  Positioned(
                    left: w * 0.18,
                    top: h * 0.1,
                    child: SizedBox(
                      width: w * 0.5,
                      child: Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: w * 0.05,
                          fontFamily: 'Tagesschrift Cyrillic',
                          color: const Color(0xFF3E2C1C),
                        ),
                      ),
                    ),
                  ),

                  // 🔤 ХАРАКТЕРИСТИКА
                  if (ability != null)
                    Positioned(
                      right: w * 0.04,
                      top: h * 0.15,
                      child: Text(
                        ability!,
                        style: TextStyle(
                          fontSize: w * 0.04,
                          fontFamily: 'Tagesschrift Cyrillic',
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),

                  // 🔢 БОНУС (в табличке)
                  Positioned(
                    right: w * 0.815,
                    top: h * 0.014,
                    child: SizedBox(
                      width: w * 0.15,
                      child: Center(
                        child: Text(
                          bonus >= 0 ? '+$bonus' : '$bonus',
                          style: TextStyle(
                            fontSize: w * 0.05,
                            fontWeight: FontWeight.bold,
                            color: bonus >= 0
                                ? Colors.green[900]
                                : Colors.red[900],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
