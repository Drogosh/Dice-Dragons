import 'package:flutter/material.dart';
import '../models/character.dart';
import '../models/inventory.dart';
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

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
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
        title: Text(widget.character.name),
        centerTitle: true,
      ),
       body: PageView(
         controller: _pageController,
         onPageChanged: _onPageChanged,
         children: [
           CharacterScreen(character: widget.character),
           InventoryScreen(inventory: widget.inventory, character: widget.character),
           InfoScreen(character: widget.character),
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





