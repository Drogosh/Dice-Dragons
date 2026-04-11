import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/character.dart';
import 'firestore_character_service.dart';
import 'firestore_inventory_service.dart';
import 'firestore_session_service.dart';

/// Главный сервис Firestore (использует специализированные подсервисы)
/// Оставлен для обратной совместимости
class FirestoreService {
  static final FirestoreService _instance = FirestoreService._internal();
  late final FirestoreCharacterService _characterService;
  late final FirestoreInventoryService _inventoryService;
  late final FirestoreSessionService _sessionService;

  factory FirestoreService() {
    return _instance;
  }

  FirestoreService._internal() {
    _characterService = FirestoreCharacterService();
    _inventoryService = FirestoreInventoryService();
    _sessionService = FirestoreSessionService();
  }

  // ==================== ПЕРСОНАЖИ ====================

  Future<String> saveCharacter(String userId, Character character) async {
    return await _characterService.saveCharacter(userId, character);
  }

  Future<List<Character>> getUserCharacters(String userId) async {
    return await _characterService.getUserCharacters(userId);
  }

  Future<Character?> getCharacterById(String userId, String charId) async {
    return await _characterService.getCharacterById(userId, charId);
  }

  Future<void> updateCharacter(String userId, String charId, Character character) async {
    return await _characterService.updateCharacter(userId, charId, character);
  }

  Future<void> deleteCharacter(String userId, String charId) async {
    return await _characterService.deleteCharacter(userId, charId);
  }

  Stream<List<Character>> getUserCharactersStream(String userId) {
    return _characterService.getUserCharactersStream(userId);
  }

  // ==================== ИНВЕНТАРЬ ====================

  Future<void> saveInventory(
    String userId,
    String charId,
    Map<String, dynamic> inventoryData,
  ) async {
    return await _inventoryService.saveInventory(userId, charId, inventoryData);
  }

  Future<Map<String, dynamic>?> getInventory(String userId, String charId) async {
    return await _inventoryService.getInventory(userId, charId);
  }

  Stream<Map<String, dynamic>?> getInventoryStream(String userId, String charId) {
    return _inventoryService.getInventoryStream(userId, charId);
  }

  Future<void> saveEquippedItems(
    String userId,
    String charId,
    Map<String, dynamic> equippedData,
  ) async {
    return await _inventoryService.saveEquippedItems(userId, charId, equippedData);
  }

  Future<Map<String, dynamic>?> getEquippedItems(String userId, String charId) async {
    return await _inventoryService.getEquippedItems(userId, charId);
  }

  Stream<Map<String, dynamic>?> getEquippedItemsStream(String userId, String charId) {
    return _inventoryService.getEquippedItemsStream(userId, charId);
  }

  // ==================== СЕССИИ ====================

  Future<String> createSession(String dmId, String sessionName) async {
    return await _sessionService.createSession(dmId, sessionName);
  }

  Future<Map<String, dynamic>?> getSession(String sessionId) async {
    return await _sessionService.getSession(sessionId);
  }

  Future<List<Map<String, dynamic>>> getDMSessions(String dmId) async {
    return await _sessionService.getDMSessions(dmId);
  }

  Future<void> addPlayerToSession(String sessionId, String userId) async {
    return await _sessionService.addPlayerToSession(sessionId, userId);
  }

  Future<void> removePlayerFromSession(String sessionId, String userId) async {
    return await _sessionService.removePlayerFromSession(sessionId, userId);
  }

  Future<void> endSession(String sessionId) async {
    return await _sessionService.endSession(sessionId);
  }

  Stream<Map<String, dynamic>?> getSessionStream(String sessionId) {
    return _sessionService.getSessionStream(sessionId);
  }
}

