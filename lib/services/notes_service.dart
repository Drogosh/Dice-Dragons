import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/note.dart';

class NotesService {
  static const String _notesBoxName = 'notes';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Получить заметки из Hive (использует стабильный ID)
  static Future<List<Note>> loadNotesLocally(String characterId) async {
    try {
      final box = await Hive.openBox(_notesBoxName);
      final notesJson = box.get(characterId) as List?;
      
      if (notesJson == null) {
        debugPrint('📝 Локально заметок не найдено для $characterId');
        return [];
      }

      final notes = (notesJson as List)
          .cast<Map<dynamic, dynamic>>()
          .map((note) => Note.fromMap(
            Map<String, dynamic>.from(note),
          ))
          .toList();

      debugPrint('✅ ЗАГРУЖЕНО ЛОКАЛЬНО: ${notes.length} заметок');
      return notes;
    } catch (e) {
      debugPrint('❌ Ошибка при загрузке заметок локально: $e');
      return [];
    }
  }

  // Получить заметки из Firestore
  Future<List<Note>> loadNotesFromFirestore(String userId, String characterId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(characterId)
          .collection('notes')
          .orderBy('updatedAt', descending: true)
          .get();

      final notes = snapshot.docs.map((doc) => Note.fromFirestore(doc)).toList();
      debugPrint('✅ ЗАГРУЖЕНО ИЗ FIRESTORE: ${notes.length} заметок');
      return notes;
    } catch (e) {
      debugPrint('❌ Ошибка при загрузке заметок из Firestore: $e');
      return [];
    }
  }

  // Сохранить заметки локально
  static Future<void> saveNotesLocally(String characterId, List<Note> notes) async {
    try {
      final box = await Hive.openBox(_notesBoxName);
      final notesJson = notes.map((note) => note.toMap()).toList();
      await box.put(characterId, notesJson);
      debugPrint('✅ Заметки сохранены локально');
    } catch (e) {
      debugPrint('❌ Ошибка при сохранении заметок локально: $e');
    }
  }

  // Сохранить заметку в Firestore
  Future<void> addNoteToFirestore(
    String userId,
    String characterId,
    Note note,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(characterId)
          .collection('notes')
          .doc(note.id)
          .set(note.toFirestore());
      debugPrint('✅ Заметка добавлена в Firestore');
    } catch (e) {
      debugPrint('❌ Ошибка при добавлении заметки в Firestore: $e');
    }
  }

  // Обновить заметку в Firestore
  Future<void> updateNoteInFirestore(
    String userId,
    String characterId,
    Note note,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(characterId)
          .collection('notes')
          .doc(note.id)
          .update(note.toFirestore());
      debugPrint('✅ Заметка обновлена в Firestore');
    } catch (e) {
      debugPrint('❌ Ошибка при обновлении заметки в Firestore: $e');
    }
  }

  // Удалить заметку из Firestore
  Future<void> deleteNoteFromFirestore(
    String userId,
    String characterId,
    String noteId,
  ) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('characters')
          .doc(characterId)
          .collection('notes')
          .doc(noteId)
          .delete();
      debugPrint('✅ Заметка удалена из Firestore');
    } catch (e) {
      debugPrint('❌ Ошибка при удалении заметки из Firestore: $e');
    }
  }
}

