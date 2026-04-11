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
    debugPrint('📖 MainNavigationScreen.initState()');
    debugPrint('   Персонаж: ${currentCharacter.name}');
    debugPrint('   HP до пересчета: ${currentCharacter.hp}');
    final recalculatedHP = currentCharacter.recalculateHP();
    if (recalculatedHP != currentCharacter.hp) {
      debugPrint('   ⚠️  HP изменено с ${currentCharacter.hp} на $recalculatedHP');
      setState(() {
        currentCharacter.hp = recalculatedHP;
      });
    }

     _loadInventory();
   }

    /// Восстановить надетые предметы из инвентаря
    Future<void> _restoreEquippedItems() async {
      try {
      debugPrint('🔄 ВОССТАНАВЛИВАЮ НАДЕТЫЕ ПРЕДМЕТЫ для ${currentCharacter.name}');
        debugPrint('   Броня сейчас: ${currentCharacter.equippedArmor?.name ?? "нет"}');
        debugPrint('   Щит сейчас: ${currentCharacter.equippedShield?.name ?? "нет"}');
        debugPrint('   Оружие: ${currentCharacter.equippedWeapons.map((w) => w?.name ?? "нет").toList()}');
        debugPrint('   В инвентаре предметов: ${currentInventory.items.length}');

        // Восстанавливаем броню
        if (currentCharacter.equippedArmor != null) {
          debugPrint('   🔍 Ищу броню: ${currentCharacter.equippedArmor!.name}');
          bool found = false;
          for (final item in currentInventory.items) {
            if (item.type == ItemType.armor &&
                item.armorType != ArmorType.shield &&
                item.name == currentCharacter.equippedArmor!.name) {
              currentCharacter.equipArmor(item);
              debugPrint('   ✅ Восстановлена броня: ${item.name}');
              found = true;
              break;
            }
          }
          if (!found) {
            debugPrint('   ❌ Броня не найдена в инвентаре!');
          }
        }

        // Восстанавливаем щит
        if (currentCharacter.equippedShield != null) {
          debugPrint('   🔍 Ищу щит: ${currentCharacter.equippedShield!.name}');
          bool found = false;
          for (final item in currentInventory.items) {
            if (item.type == ItemType.armor &&
                item.armorType == ArmorType.shield &&
                item.name == currentCharacter.equippedShield!.name) {
              currentCharacter.equipShield(item);
              debugPrint('   ✅ Восстановлен щит: ${item.name}');
              found = true;
              break;
            }
          }
          if (!found) {
            debugPrint('   ❌ Щит не найден в инвентаре!');
          }
        }

        // Восстанавливаем оружие
        for (int i = 0; i < currentCharacter.equippedWeapons.length; i++) {
          if (currentCharacter.equippedWeapons[i] != null) {
            debugPrint('   🔍 Ищу оружие ${i+1}: ${currentCharacter.equippedWeapons[i]!.name}');
            bool found = false;
            for (final item in currentInventory.items) {
              if (item.type == ItemType.weapon &&
                  item.name == currentCharacter.equippedWeapons[i]!.name) {
                currentCharacter.equipWeapon(i, item);
                debugPrint('   ✅ Восстановлено оружие ${i+1}: ${item.name}');
                found = true;
                break;
              }
            }
            if (!found) {
              debugPrint('   ❌ Оружие ${i+1} не найдено в инвентаре!');
            }
          }
        }
      } catch (e) {
        debugPrint('❌ ОШИБКА ВОССТАНОВЛЕНИЯ: $e');
      }
    }

   /// Загрузить инвентарь из хранилища (локального и облака)
   Future<void> _loadInventory() async {
     try {
       final charId = currentCharacter.id ?? currentCharacter.name;
       debugPrint('🔄 ЗАГРУЖАЮ ИНВЕНТАРЬ для $charId');

       // Сначала пытаемся загрузить локально
       final localInventory = await StorageService.loadInventory(charId);
       if (localInventory != null) {
         setState(() {
           currentInventory = localInventory;
         });
         debugPrint('✅ ЗАГРУЖЕНО ЛОКАЛЬНО: ${localInventory.getItemCount()} предметов');
       } else {
         debugPrint('ℹ️  Локально не найдено');

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
             debugPrint('✅ ЗАГРУЖЕНО ИЗ FIRESTORE: ${inventory.getItemCount()} предметов');
           }
         }
        }
      } catch (e) {
        debugPrint('❌ ОШИБКА ЗАГРУЗКИ: $e');
      }

      // После загрузки инвентаря - восстанавливаем надетые предметы
      await _restoreEquippedItems();
    }

    /// Сохранить инвентарь (локально и в облаке)
    Future<void> _saveInventory() async {
      try {
        final charId = currentCharacter.id ?? currentCharacter.name;
        final itemCount = currentInventory.getItemCount();
        debugPrint('💾 СОХРАНЯЮ ИНВЕНТАРЬ для $charId ($itemCount предметов)');
        debugPrint('📋 Предметы: ${currentInventory.getAllItems().map((i) => i.name).toList()}');

        // Логируем надетые предметы
        debugPrint('🎖️ Надетые предметы:');
        if (currentCharacter.equippedArmor != null) {
          debugPrint('   Броня: ${currentCharacter.equippedArmor!.name}');
        }
        if (currentCharacter.equippedShield != null) {
          debugPrint('   Щит: ${currentCharacter.equippedShield!.name}');
        }
        for (int i = 0; i < currentCharacter.equippedWeapons.length; i++) {
          if (currentCharacter.equippedWeapons[i] != null) {
            debugPrint('   Оружие ${i+1}: ${currentCharacter.equippedWeapons[i]!.name}');
          }
        }

        // Сохраняем локально
        await StorageService.saveInventory(charId, currentInventory);
        debugPrint('✅ СОХРАНЕНО ЛОКАЛЬНО (Hive)');

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
          debugPrint('✅ СОХРАНЕНО В FIRESTORE (облако)');

         // Также сохраняем персонажа с надетыми предметами
         await _firestoreService.updateCharacter(
           userId,
           currentCharacter.id!,
           currentCharacter,
         );
         debugPrint('✅ ПЕРСОНАЖ ОБНОВЛЕН В FIRESTORE (с надетыми предметами)');

         // Сохраняем также локально
         await StorageService.saveCharacter(currentCharacter);
         debugPrint('✅ ПЕРСОНАЖ СОХРАНЕН ЛОКАЛЬНО');
        } else {
          debugPrint('⚠️  Не удалось сохранить в Firestore (userId=$userId, charId=${currentCharacter.id})');
        }
      } catch (e) {
        debugPrint('❌ ОШИБКА СОХРАНЕНИЯ: $e');
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
            NotesScreen(character: currentCharacter),
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






