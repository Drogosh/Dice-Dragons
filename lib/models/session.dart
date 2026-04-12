import 'package:cloud_firestore/cloud_firestore.dart';

/// Роль участника в сессии
enum SessionRole {
  dm,     // Dungeon Master (ведущий)
  player, // Игрок
}

/// Статус сессии
enum SessionStatus {
  active,  // Активная сессия
  ended,   // Завершённая сессия
  paused,  // На паузе
}

/// Участник сессии
class SessionMember {
  final String uid;
  final SessionRole role;
  final String displayName;
  final String? characterId; // Опционально: ID персонажа игрока
  final DateTime joinedAt;

  SessionMember({
    required this.uid,
    required this.role,
    required this.displayName,
    this.characterId,
    DateTime? joinedAt,
  }) : joinedAt = joinedAt ?? DateTime.now();

  /// Сериализация
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'role': role.name,
      'displayName': displayName,
      'characterId': characterId,
      'joinedAt': Timestamp.fromDate(joinedAt),
    };
  }

  /// Десериализация
  factory SessionMember.fromMap(String uid, Map<String, dynamic> map) {
    return SessionMember(
      uid: uid,
      role: SessionRole.values.firstWhere(
        (e) => e.name == map['role'],
        orElse: () => SessionRole.player,
      ),
      displayName: map['displayName'] as String? ?? 'Player',
      characterId: map['characterId'] as String?,
      joinedAt: (map['joinedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Копирование с изменениями
  SessionMember copyWith({
    String? uid,
    SessionRole? role,
    String? displayName,
    String? characterId,
    DateTime? joinedAt,
  }) {
    return SessionMember(
      uid: uid ?? this.uid,
      role: role ?? this.role,
      displayName: displayName ?? this.displayName,
      characterId: characterId ?? this.characterId,
      joinedAt: joinedAt ?? this.joinedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SessionMember &&
          runtimeType == other.runtimeType &&
          uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}

/// Сессия D&D
class Session {
  final String id;
  final String dmId; // UID ведущего (owner)
  final String name;
  final String joinCode; // Короткий код для присоединения (6 символов)
  final SessionStatus status;
  final Map<String, SessionMember> members; // uid -> member
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? description; // Опционально
  final String? campaignName; // Опционально: название кампании
  final int maxPlayers; // Максимум игроков (0 = бесконечно)

  Session({
    required this.id,
    required this.dmId,
    required this.name,
    required this.joinCode,
    this.status = SessionStatus.active,
    Map<String, SessionMember>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    this.description,
    this.campaignName,
    this.maxPlayers = 0,
  })  : members = members ?? {},
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  /// Получить всех игроков (не DM)
  List<SessionMember> getPlayers() {
    return members.values
        .where((m) => m.role == SessionRole.player)
        .toList();
  }

  /// Получить DM
  SessionMember? getDM() {
    try {
      return members.values.firstWhere((m) => m.role == SessionRole.dm);
    } catch (e) {
      return null;
    }
  }

  /// Проверить, есть ли свободные места
  bool hasAvailableSpots() {
    if (maxPlayers <= 0) return true; // Бесконечно мест
    final playerCount = getPlayers().length;
    return playerCount < maxPlayers;
  }

  /// Количество членов сессии
  int getMemberCount() => members.length;

  /// Проверить, является ли пользователь DM
  bool isDM(String uid) => dmId == uid;

  /// Проверить, участвует ли пользователь в сессии
  bool hasMember(String uid) => members.containsKey(uid);

  /// Сериализация
  Map<String, dynamic> toMap() {
    return {
      'dmId': dmId,
      'name': name,
      'joinCode': joinCode,
      'status': status.name,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': Timestamp.fromDate(updatedAt),
      'description': description,
      'campaignName': campaignName,
      'maxPlayers': maxPlayers,
    };
  }

  /// Сохранение в Firestore (отдельно члены в подколлекции)
  Map<String, dynamic> toFirestore() {
    return toMap();
  }

  /// Десериализация
  factory Session.fromMap(
    String id,
    Map<String, dynamic> map, {
    Map<String, SessionMember>? members,
  }) {
    return Session(
      id: id,
      dmId: map['dmId'] as String,
      name: map['name'] as String,
      joinCode: map['joinCode'] as String,
      status: SessionStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => SessionStatus.active,
      ),
      members: members,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate(),
      updatedAt: (map['updatedAt'] as Timestamp?)?.toDate(),
      description: map['description'] as String?,
      campaignName: map['campaignName'] as String?,
      maxPlayers: map['maxPlayers'] as int? ?? 0,
    );
  }

  /// Загрузка из Firestore с членами
  factory Session.fromFirestore(
    DocumentSnapshot doc, {
    Map<String, SessionMember>? members,
  }) {
    final data = doc.data() as Map<String, dynamic>;
    return Session.fromMap(doc.id, data, members: members);
  }

  /// Копирование с изменениями
  Session copyWith({
    String? id,
    String? dmId,
    String? name,
    String? joinCode,
    SessionStatus? status,
    Map<String, SessionMember>? members,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? description,
    String? campaignName,
    int? maxPlayers,
  }) {
    return Session(
      id: id ?? this.id,
      dmId: dmId ?? this.dmId,
      name: name ?? this.name,
      joinCode: joinCode ?? this.joinCode,
      status: status ?? this.status,
      members: members ?? this.members,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      description: description ?? this.description,
      campaignName: campaignName ?? this.campaignName,
      maxPlayers: maxPlayers ?? this.maxPlayers,
    );
  }

  @override
  String toString() {
    return 'Session(id: $id, name: $name, code: $joinCode, status: $status, members: ${members.length})';
  }
}

