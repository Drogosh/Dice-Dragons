import 'package:flutter/material.dart';

class SpellsScreen extends StatefulWidget {
  const SpellsScreen({super.key});

  @override
  State<SpellsScreen> createState() => _SpellsScreenState();
}

class _SpellsScreenState extends State<SpellsScreen> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/stats_widget/background.png'),
          fit: BoxFit.cover,
          opacity: 1,
        ),
      ),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Заклинания',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 16),
              Center(
                child: Text(
                  'Функция в разработке',
                  style: TextStyle(color: Colors.grey[600]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

