import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/character.dart';
import '../models/inventory.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import 'character_screen.dart';
import 'inventory_screen.dart';
import 'info_screen.dart';
import 'spells_screen.dart';
import 'notes_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  final Character character;
  final Inventory inventory;

  const MainNavigationScreen({
    super.key,
    required this.character,
    required this.inventory,
  });

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  late PageController _pageController;
  int _currentIndex = 0;
  late Inventory currentInventory;
  late Character currentCharacter;
  final FirestoreService _firestoreService = FirestoreService();

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    currentInventory = widget.inventory;
    currentCharacter = widget.character;

    // Пересчитываем HP на основе телосложения и класса
    print('📖 MainNavigationScreen.initState()');
    print('   Персонаж: ${currentCharacter.name}');
    print('   HP до пересчета: ${currentCharacter.hp}');
    final recalculatedHP = currentCharacter.recalculateHP();
    if (recalculatedHP != currentCharacter.hp) {
      print('   ⚠️  HP изменено с ${currentCharacter.hp} на $recalculatedHP');
      setState(() {
        currentCharacter.hp = recalculatedHP;
      });
    }

     _loadInventory();
   }

   /// Восстановить надетые предметы из инвентаря
   Future<void> _restoreEquippedItems() async {
     try {
       print('🔄 ВОССТАНАВЛИВАЮ НАДЕТЫЕ ПРЕДМЕТЫ для ${currentCharacter.name}');
       print('   Броня сейчас: ${currentCharacter.equippedArmor?.name ?? "нет"}');
       print('   Щит сейчас: ${currentCharacter.equippedShield?.name ?? "нет"}');
       print('   Оружие: ${currentCharacter.equippedWeapons.map((w) => w?.name ?? "нет").toList()}');
       print('   В инвентаре предметов: ${currentInventory.items.length}');
       
       // Восстанавливаем броню
       if (currentCharacter.equippedArmor != null) {
         print('   🔍 Ищу броню: ${currentCharacter.equippedArmor!.name}');
         bool found = false;
         for (final item in currentInventory.items) {
           if (item.type == ItemType.armor && 
               item.armorType != ArmorType.shield &&
               item.name == currentCharacter.equippedArmor!.name) {
             currentCharacter.equipArmor(item);
             print('   ✅ Восстановлена броня: ${item.name}');
             found = true;
             break;
           }
         }
         if (!found) {
           print('   ❌ Броня не найдена в инвентаре!');
         }
       }
       
       // Восстанавливаем щит
       if (currentCharacter.equippedShield != null) {
         print('   🔍 Ищу щит: ${currentCharacter.equippedShield!.name}');
         bool found = false;
         for (final item in currentInventory.items) {
           if (item.type == ItemType.armor && 
               item.armorType == ArmorType.shield &&
               item.name == currentCharacter.equippedShield!.name) {
             currentCharacter.equipShield(item);
             print('   ✅ Восстановлен щит: ${item.name}');
             found = true;
             break;
           }
         }
         if (!found) {
           print('   ❌ Щит не найден в инвентаре!');
         }
       }
       
       // Восстанавливаем оружие
       for (int i = 0; i < currentCharacter.equippedWeapons.length; i++) {
         if (currentCharacter.equippedWeapons[i] != null) {
           print('   🔍 Ищу оружие ${i+1}: ${currentCharacter.equippedWeapons[i]!.name}');
           bool found = false;
           for (final item in currentInventory.items) {
             if (item.type == ItemType.weapon && 
                 item.name == currentCharacter.equippedWeapons[i]!.name) {
               currentCharacter.equipWeapon(i, item);
               print('   ✅ Восстановлено оружие ${i+1}: ${item.name}');
               found = true;
               break;
             }
           }
           if (!found) {
             print('   ❌ Оружие ${i+1} не найдено в инвентаре!');
           }
         }
       }
     } catch (e) {
       print('❌ ОШИБКА ВОССТАНОВЛЕНИЯ: $e');
     }
   }

  /// Загрузить инвентарь из хранилища (локального и облака)
  Future<void> _loadInventory() async {
    try {
      final charId = currentCharacter.id ?? currentCharacter.name;
      print('🔄 ЗАГРУЖАЮ ИНВЕНТАРЬ для $charId');

      // Сначала пытаемся загрузить локально
      final localInventory = await StorageService.loadInventory(charId);
      if (localInventory != null) {
        setState(() {
          currentInventory = localInventory;
        });
        print('✅ ЗАГРУЖЕНО ЛОКАЛЬНО: ${localInventory.getItemCount()} предметов');
      } else {
        print('ℹ️  Локально не найдено');

        // Если локально нет, пытаемся загрузить из Firestore
        final userId = fb.FirebaseAuth.instance.currentUser?.uid;
        if (userId != null && currentCharacter.id != null) {
          final firestoreInventoryData = await _firestoreService.getInventory(userId, currentCharacter.id!);
          if (firestoreInventoryData != null) {
            final items = firestoreInventoryData['items'] as List<dynamic>? ?? [];
            final inventory = Inventory.fromList(items);
            setState(() {
              currentInventory = inventory;
            });
            // Сохраняем локально
            await StorageService.saveInventory(charId, inventory);
            print('✅ ЗАГРУЖЕНО ИЗ FIRESTORE: ${inventory.getItemCount()} предметов');
          }
        }
       }
     } catch (e) {
       print('❌ ОШИБКА ЗАГРУЗКИ: $e');
     }

     // После загрузки инвентаря - восстанавливаем надетые предметы
     await _restoreEquippedItems();
   }

   /// Сохранить инвентарь (локально и в облаке)
   Future<void> _saveInventory() async {
     try {
       final charId = currentCharacter.id ?? currentCharacter.name;
       final itemCount = currentInventory.getItemCount();
       print('💾 СОХРАНЯЮ ИНВЕНТАРЬ для $charId ($itemCount предметов)');
       print('📋 Предметы: ${currentInventory.getAllItems().map((i) => i.name).toList()}');

       // Логируем надетые предметы
       print('🎖️ Надетые предметы:');
       if (currentCharacter.equippedArmor != null) {
         print('   Броня: ${currentCharacter.equippedArmor!.name}');
       }
       if (currentCharacter.equippedShield != null) {
         print('   Щит: ${currentCharacter.equippedShield!.name}');
       }
       for (int i = 0; i < currentCharacter.equippedWeapons.length; i++) {
         if (currentCharacter.equippedWeapons[i] != null) {
           print('   Оружие ${i+1}: ${currentCharacter.equippedWeapons[i]!.name}');
         }
       }

       // Сохраняем локально
       await StorageService.saveInventory(charId, currentInventory);
       print('✅ СОХРАНЕНО ЛОКАЛЬНО (Hive)');

       // Сохраняем в Firestore
       final userId = fb.FirebaseAuth.instance.currentUser?.uid;
       if (userId != null && currentCharacter.id != null) {
         await _firestoreService.saveInventory(
           userId,
           currentCharacter.id!,
           {
             'items': currentInventory.toList(),
             'updatedAt': DateTime.now().toIso8601String(),
           },
         );
         print('✅ СОХРАНЕНО В FIRESTORE (облако)');

        // Также сохраняем персонажа с надетыми предметами
        await _firestoreService.updateCharacter(
          userId,
          currentCharacter.id!,
          currentCharacter,
        );
        print('✅ ПЕРСОНАЖ ОБНОВЛЕН В FIRESTORE (с надетыми предметами)');

        // Сохраняем также локально
        await StorageService.saveCharacter(currentCharacter);
        print('✅ ПЕРСОНАЖ СОХРАНЕН ЛОКАЛЬНО');
       } else {
         print('⚠️  Не удалось сохранить в Firestore (userId=$userId, charId=${currentCharacter.id})');
       }
     } catch (e) {
       print('❌ ОШИБКА СОХРАНЕНИЯ: $e');
       if (mounted) {
         ScaffoldMessenger.of(context).showSnackBar(
           SnackBar(
             content: Text('❌ Ошибка сохранения: $e'),
             backgroundColor: Colors.red,
           ),
         );
       }
     }
   }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavItemTapped(int index) {
    setState(() {
      _currentIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(currentCharacter.name),
        centerTitle: true,
      ),
       body: PageView(
         controller: _pageController,
         onPageChanged: _onPageChanged,
         children: [
           CharacterScreen(character: currentCharacter),
           InventoryScreen(
             inventory: currentInventory,
             character: currentCharacter,
             onItemChanged: _saveInventory,
           ),
           InfoScreen(character: currentCharacter),
           const SpellsScreen(),
           const NotesScreen(),
         ],
       ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: _onNavItemTapped,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Характеристики',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.backpack),
            label: 'Инвентарь',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.info),
            label: 'Информация',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_awesome),
            label: 'Заклинания',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.note),
            label: 'Заметки',
          ),
        ],
      ),
    );
  }
}






