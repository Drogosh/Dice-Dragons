import 'package:flutter/material.dart';
import 'models/character.dart';
import 'models/inventory.dart';
import 'models/item.dart';
import 'screens/main_navigation_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    // Создаем тестового персонажа
    final testCharacter = Character(
      name: 'Артур Пенбраун',
      level: 3,
      hp: 27,
      ac: 15,
      strength: 16,
      dexterity: 14,
      constitution: 15,
      intelligence: 13,
      wisdom: 12,
      charisma: 10,
    );

    // Создаем инвентарь с тестовыми предметами
    final inventory = Inventory();
    inventory.addItem(Item(
      name: 'Длинный меч',
      type: ItemType.weapon,
      description: 'Классическое оружие ближнего боя',
      bonus: 1,
      damage: '1d8',
      damageType: DamageType.slashing,
    ));
    inventory.addItem(Item(
      name: 'Кожаная броня',
      type: ItemType.armor,
      description: 'Легкая защита из кожи',
      bonus: 0,
      armorClass: 11,
      armorType: ArmorType.light,
    ));

    return MaterialApp(
      title: 'Dice & Dragons',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: MainNavigationScreen(
        character: testCharacter,
        inventory: inventory,
      ),
    );
  }
}

// Удалены неиспользуемые классы MyHomePage и _MyHomePageState
