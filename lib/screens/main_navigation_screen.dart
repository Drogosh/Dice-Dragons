import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/character.dart';
import '../models/inventory.dart';
import '../models/item.dart';
import '../services/firestore_service.dart';
import '../services/storage_service.dart';
import '../services/session_service.dart';
import 'character_screen.dart';
import 'inventory_screen.dart';
import 'info_screen.dart';
import 'spells_screen.dart';
import 'notes_screen.dart';
import 'sessions_list_screen.dart';
import 'session_screen.dart';

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
  late final SessionService _sessionService;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _sessionService = SessionService();
    currentInventory = widget.inventory;
    currentCharacter = widget.character;
    // ...existing code...
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

    /// Восстановить надетые предметы из инвентаря по ID
    Future<void> _restoreEquippedItems() async {
      try {
      debugPrint('🔄 ВОССТАНАВЛИВАЮ НАДЕТЫЕ ПРЕДМЕТЫ для ${currentCharacter.name}');
        debugPrint('   Броня ID: ${currentCharacter.equippedArmorId ?? "нет"}');
        debugPrint('   Щит ID: ${currentCharacter.equippedShieldId ?? "нет"}');
        debugPrint('   Оружие IDs: ${currentCharacter.equippedWeaponIds.toList()}');
        debugPrint('   В инвентаре предметов: ${currentInventory.items.length}');

        // Восстанавливаем броню по ID
        if (currentCharacter.equippedArmorId != null) {
          final armorId = currentCharacter.equippedArmorId!;
          debugPrint('   🔍 Ищу броню с ID: $armorId');
          final armorItem = currentInventory.findItemById(armorId);
          if (armorItem != null) {
            currentCharacter.equipArmor(armorItem);
            debugPrint('   ✅ Восстановлена броня: ${armorItem.name}');
          } else {
            debugPrint('   ❌ Броня не найдена в инвентаре!');
            currentCharacter.equipArmor(null);
          }
        }

        // Восстанавливаем щит по ID
        if (currentCharacter.equippedShieldId != null) {
          final shieldId = currentCharacter.equippedShieldId!;
          debugPrint('   🔍 Ищу щит с ID: $shieldId');
          final shieldItem = currentInventory.findItemById(shieldId);
          if (shieldItem != null) {
            currentCharacter.equipShield(shieldItem);
            debugPrint('   ✅ Восстановлен щит: ${shieldItem.name}');
          } else {
            debugPrint('   ❌ Щит не найден в инвентаре!');
            currentCharacter.equipShield(null);
          }
        }

        // Восстанавливаем оружие по ID
        for (int i = 0; i < currentCharacter.equippedWeaponIds.length; i++) {
          if (currentCharacter.equippedWeaponIds[i] != null) {
            final weaponId = currentCharacter.equippedWeaponIds[i]!;
            debugPrint('   🔍 Ищу оружие ${i+1} с ID: $weaponId');
            final weaponItem = currentInventory.findItemById(weaponId);
            if (weaponItem != null) {
              currentCharacter.equipWeapon(i, weaponItem);
              debugPrint('   ✅ Восстановлено оружие ${i+1}: ${weaponItem.name}');
            } else {
              debugPrint('   ❌ Оружие ${i+1} не найдено в инвентаре!');
              currentCharacter.unequipWeapon(i);
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

  void _showCreateSessionDialog() {
    final nameController = TextEditingController();
    final maxPlayersController = TextEditingController();
    final campaignController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Создать сессию',
          style: TextStyle(color: Colors.white),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Название сессии',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[700],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: campaignController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Название кампании (опционально)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[700],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: maxPlayersController,
                keyboardType: TextInputType.number,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Макс игроков (0 = без лимита)',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[700],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите название сессии')),
                );
                return;
              }

              try {
                final session = await _sessionService.createSession(
                  name: nameController.text,
                  campaignName:
                      campaignController.text.isEmpty ? null : campaignController.text,
                  maxPlayers: int.tryParse(maxPlayersController.text) ?? 0,
                );

                if (mounted) {
                  Navigator.pop(context);

                  // Показать код присоединения
                  _showJoinCodeDialog(session);
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _showJoinCodeDialog(dynamic session) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Сессия создана!',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Поделитесь этим кодом с игроками:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                session.joinCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Закрыть'),
          ),
        ],
      ),
    );
  }

  void _showJoinSessionDialog() {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[850],
        title: const Text(
          'Присоединиться к сессии',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Введите код присоединения:',
              style: TextStyle(color: Colors.white),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: codeController,
              style: const TextStyle(color: Colors.white),
              inputFormatters: [UpperCaseTextFormatter()],
              decoration: InputDecoration(
                hintText: 'например: AB12CD',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[700],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              maxLength: 6,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (codeController.text.length != 6) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите правильный код (6 символов)')),
                );
                return;
              }

              try {
                final session = await _sessionService.joinSessionByCode(
                  codeController.text,
                );

                if (mounted) {
                  Navigator.pop(context);

                  // Перейти в сессию
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SessionScreen(session: session),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Ошибка: $e')),
                  );
                }
              }
            },
            child: const Text('Присоединиться'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(currentCharacter.name),
        centerTitle: true,
        actions: [
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Создать сессию'),
                onTap: () => _showCreateSessionDialog(),
              ),
              PopupMenuItem(
                child: const Text('Присоединиться'),
                onTap: () => _showJoinSessionDialog(),
              ),
            ],
          ),
        ],
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

/// Форматер для преобразования текста в прописные буквы
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(
      text: newValue.text.toUpperCase(),
    );
  }
}
