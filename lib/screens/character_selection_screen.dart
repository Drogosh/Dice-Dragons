import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb;
import '../models/character.dart';
import '../models/inventory.dart';
import '../services/firestore_service.dart';
import '../services/auth_service.dart';
import 'main_navigation_screen.dart';
import 'character_creation_screen.dart';

class CharacterSelectionScreen extends StatefulWidget {
  const CharacterSelectionScreen({super.key});

  @override
  State<CharacterSelectionScreen> createState() => _CharacterSelectionScreenState();
}

class _CharacterSelectionScreenState extends State<CharacterSelectionScreen> {
  final _firestoreService = FirestoreService();
  final _authService = AuthService();
  late String _userId;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _userId = fb.FirebaseAuth.instance.currentUser!.uid;
    _loadCharacters();
  }

  Future<void> _loadCharacters() async {
    // Загружаем персонажей, если они есть
    setState(() => _isLoading = false);
  }

   void _selectCharacter(Character character) async {
     // Обновляем currentCharacterId в User профиле
     await _authService.updateUserProfile(
       uid: _userId,
       currentCharacterId: character.id,
     );

     if (!mounted) return;

     // Переходим на главный экран
     Navigator.of(context).pushAndRemoveUntil(
       MaterialPageRoute(
         builder: (context) => MainNavigationScreen(
           character: character,
           inventory: Inventory(),
         ),
       ),
       (route) => false,
     );
   }

   Future<void> _deleteCharacter(Character character) async {
     final confirmed = await showDialog<bool>(
       context: context,
       builder: (context) => AlertDialog(
         title: const Text('Удалить персонажа?'),
         content: Text('Вы действительно хотите удалить ${character.name}? Это действие необратимо.'),
         actions: [
           TextButton(
             onPressed: () => Navigator.pop(context, false),
             child: const Text('Отмена'),
           ),
           TextButton(
             onPressed: () => Navigator.pop(context, true),
             child: const Text('Удалить', style: TextStyle(color: Colors.red)),
           ),
         ],
       ),
     );

     if (confirmed == true && mounted) {
       try {
         await _firestoreService.deleteCharacter(_userId, character.id!);
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('Персонаж удален')),
           );
         }
       } catch (e) {
         if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             SnackBar(content: Text('Ошибка: $e')),
           );
         }
       }
     }
   }

  void _goToCharacterCreation() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => const CharacterCreationScreen(),
      ),
    ).then((newCharacter) {
      if (newCharacter != null && newCharacter is Character) {
        _selectCharacter(newCharacter);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        title: const Text('Выбор персонажа'),
        backgroundColor: Colors.grey[800],
        actions: [
          // Кнопка выхода
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : StreamBuilder<List<Character>>(
              stream: _firestoreService.getUserCharactersStream(_userId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text(
                          'Ошибка: ${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white),
                        ),
                      ],
                    ),
                  );
                }

                final characters = snapshot.data ?? [];

                if (characters.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.person, size: 64, color: Colors.grey[600]),
                        const SizedBox(height: 16),
                        Text(
                          'У вас нет персонажей',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                color: Colors.white,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Создайте своего первого персонажа',
                          style: TextStyle(color: Colors.grey[400]),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _goToCharacterCreation,
                          icon: const Icon(Icons.add),
                          label: const Text('Создать персонажа'),
                        ),
                      ],
                    ),
                  );
                }

                return SafeArea(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: characters.length,
                        itemBuilder: (context, index) {
                             final character = characters[index];
                             return Padding(
                               padding: const EdgeInsets.only(bottom: 12),
                               child: Card(
                                 color: Colors.grey[800],
                                 child: ListTile(
                                   leading: const Icon(Icons.person, color: Colors.blue),
                                   title: Text(
                                     character.name,
                                     style: const TextStyle(
                                       color: Colors.white,
                                       fontWeight: FontWeight.bold,
                                     ),
                                   ),
                                   subtitle: Text(
                                     'Уровень ${character.level} • HP: ${character.hp} • AC: ${character.ac}',
                                     style: TextStyle(color: Colors.grey[400]),
                                   ),
                                   trailing: PopupMenuButton(
                                     itemBuilder: (context) => [
                                       PopupMenuItem(
                                         onTap: () => _selectCharacter(character),
                                         child: const Text('Выбрать'),
                                       ),
                                       PopupMenuItem(
                                         onTap: () => _deleteCharacter(character),
                                         child: const Text(
                                           'Удалить',
                                           style: TextStyle(color: Colors.red),
                                         ),
                                       ),
                                     ],
                                   ),
                                   onTap: () => _selectCharacter(character),
                                 ),
                               ),
                             );
                           },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            onPressed: _goToCharacterCreation,
                            icon: const Icon(Icons.add),
                            label: const Text('Создать нового персонажа'),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}


