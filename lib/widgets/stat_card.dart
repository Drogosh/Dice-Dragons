import 'package:flutter/material.dart';

class StatCard extends StatelessWidget {
  final String name;
  final String abbreviation;
  final int value;
  final int modifier;
  final VoidCallback? onTap;
  final bool isSelected;

  const StatCard({
    super.key,
    required this.name,
    required this.abbreviation,
    required this.value,
    required this.modifier,
    this.onTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final modifierColor = modifier >= 0 ? Colors.green : Colors.red;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        color: isSelected ? Colors.amber[50] : null,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: isSelected
                ? Colors.amber[700]!
                : Theme.of(context).colorScheme.primary,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name,
                style: const TextStyle(fontSize: 12),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(6),
                ),
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: '$value',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onPrimaryContainer,
                        ),
                      ),
                      TextSpan(
                        text: ' (${modifier >= 0 ? '+' : ''}$modifier)',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: modifierColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


