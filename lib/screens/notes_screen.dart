import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/character.dart';
import '../models/note.dart';
import '../services/notes_service.dart';

class NotesScreen extends StatefulWidget {
  final Character character;

  const NotesScreen({
    super.key,
    required this.character,
  });

  @override
  State<NotesScreen> createState() => _NotesScreenState();
}

class _NotesScreenState extends State<NotesScreen> {
  late List<Note> notes = [];
  final NotesService _notesService = NotesService();
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotes();
  }

  Future<void> _loadNotes() async {
    setState(() => _isLoading = true);

    try {
      final characterId = widget.character.id ?? widget.character.name;

      // Загружаем локально
      final localNotes = await NotesService.loadNotesLocally(characterId);

      // Загружаем из Firestore
      final userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId != null) {
        final firestoreNotes = await _notesService.loadNotesFromFirestore(
          userId,
          characterId,
        );

        // Используем Firestore заметки если они есть
        if (firestoreNotes.isNotEmpty) {
          notes = firestoreNotes;
          // Синхронизируем локально
          await NotesService.saveNotesLocally(characterId, notes);
        } else {
          notes = localNotes;
        }
      } else {
        notes = localNotes;
      }

      if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      print('❌ Ошибка загрузки заметок: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _addNote() async {
    final titleController = TextEditingController();
    final contentController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Новая заметка'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Заголовок',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                hintText: 'Содержание',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
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
              if (titleController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Введите заголовок')),
                );
                return;
              }

              final now = DateTime.now();
              final newNote = Note(
                id: '${now.millisecondsSinceEpoch}',
                characterId: widget.character.id ?? widget.character.name,
                title: titleController.text,
                content: contentController.text,
                createdAt: now,
                updatedAt: now,
              );

              setState(() => notes.add(newNote));

              // Сохраняем локально
              await NotesService.saveNotesLocally(
                widget.character.id ?? widget.character.name,
                notes,
              );

              // Сохраняем в Firestore
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                await _notesService.addNoteToFirestore(
                  userId,
                  widget.character.id ?? widget.character.name,
                  newNote,
                );
              }

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Заметка добавлена')),
                );
              }
            },
            child: const Text('Добавить'),
          ),
        ],
      ),
    );
  }

  Future<void> _editNote(int index) async {
    final note = notes[index];
    final titleController = TextEditingController(text: note.title);
    final contentController = TextEditingController(text: note.content);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Редактировать заметку'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                hintText: 'Заголовок',
                border: OutlineInputBorder(),
              ),
              maxLines: 1,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: contentController,
              decoration: const InputDecoration(
                hintText: 'Содержание',
                border: OutlineInputBorder(),
              ),
              maxLines: 5,
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
              final updatedNote = note.copyWith(
                title: titleController.text,
                content: contentController.text,
                updatedAt: DateTime.now(),
              );

              setState(() => notes[index] = updatedNote);

              // Сохраняем локально
              await NotesService.saveNotesLocally(
                widget.character.id ?? widget.character.name,
                notes,
              );

              // Обновляем в Firestore
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                await _notesService.updateNoteInFirestore(
                  userId,
                  widget.character.id ?? widget.character.name,
                  updatedNote,
                );
              }

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Заметка обновлена')),
                );
              }
            },
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteNote(int index) async {
    final note = notes[index];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить заметку?'),
        content: Text('Заметка "${note.title}" будет удалена безвозвратно.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          ElevatedButton(
            onPressed: () async {
              setState(() => notes.removeAt(index));

              // Сохраняем локально
              await NotesService.saveNotesLocally(
                widget.character.id ?? widget.character.name,
                notes,
              );

              // Удаляем из Firestore
              final userId = FirebaseAuth.instance.currentUser?.uid;
              if (userId != null) {
                await _notesService.deleteNoteFromFirestore(
                  userId,
                  widget.character.id ?? widget.character.name,
                  note.id,
                );
              }

              if (mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('✅ Заметка удалена')),
                );
              }
            },
            child: const Text('Удалить', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/stats_widget/background.png'),
          fit: BoxFit.cover,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: const Text('Заметки'),
          backgroundColor: Colors.grey[800]?.withOpacity(0.9),
          elevation: 0,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : notes.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.note_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Нет заметок',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: notes.length,
                    itemBuilder: (context, index) {
                      final note = notes[index];
                      return Card(
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          title: Text(
                            note.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 6),
                              Text(
                                note.content,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: Colors.grey[600],
                                  fontSize: 14,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _formatDate(note.updatedAt),
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                          trailing: PopupMenuButton(
                            itemBuilder: (context) => [
                              PopupMenuItem(
                                child: const Text('Редактировать'),
                                onTap: () => Future.delayed(
                                  Duration.zero,
                                  () => _editNote(index),
                                ),
                              ),
                              PopupMenuItem(
                                child: const Text('Удалить',
                                    style: TextStyle(color: Colors.red)),
                                onTap: () => Future.delayed(
                                  Duration.zero,
                                  () => _deleteNote(index),
                                ),
                              ),
                            ],
                          ),
                          onTap: () => _editNote(index),
                        ),
                      );
                    },
                  ),
        floatingActionButton: FloatingActionButton(
          onPressed: _addNote,
          tooltip: 'Новая заметка',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return 'Только что';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}м назад';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}ч назад';
    } else if (difference.inDays == 1) {
      return 'Вчера';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}д назад';
    } else {
      return '${date.day}.${date.month}.${date.year}';
    }
  }
}


