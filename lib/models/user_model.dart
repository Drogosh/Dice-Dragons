import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  player,  // Игрок
  dm,      // Мастер игры
}

class User {
  final String uid;
  final String email;
  final String username;
  final DateTime createdAt;
  final String? photoURL;
  final String? currentCharacterId; // ID выбранного персонажа

  User({
    required this.uid,
    required this.email,
    required this.username,
    required this.createdAt,
    this.photoURL,
    this.currentCharacterId,
  });

  /// Конвертировать в JSON для Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'createdAt': createdAt,
      'photoURL': photoURL,
      'currentCharacterId': currentCharacterId,
    };
  }

  /// Создать User из Firestore документа
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      uid: map['uid'] ?? '',
      email: map['email'] ?? '',
      username: map['username'] ?? '',
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      photoURL: map['photoURL'],
      currentCharacterId: map['currentCharacterId'],
    );
  }

  /// Создать User из FirebaseUser
  factory User.fromFirebase(
    String uid,
    String email,
    String username,
  ) {
    return User(
      uid: uid,
      email: email,
      username: username,
      createdAt: DateTime.now(),
    );
  }

  /// Копирование с изменениями
  User copyWith({
    String? uid,
    String? email,
    String? username,
    DateTime? createdAt,
    String? photoURL,
    String? currentCharacterId,
  }) {
    return User(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      createdAt: createdAt ?? this.createdAt,
      photoURL: photoURL ?? this.photoURL,
      currentCharacterId: currentCharacterId ?? this.currentCharacterId,
    );
  }

  @override
  String toString() => 'User(uid: $uid, email: $email, username: $username)';
}

