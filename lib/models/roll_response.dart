/// Ответ игрока на запрос броска
class RollResponse {
  final String uid;
  final String displayName;
  final String? characterId;
  final String? characterName;
  final int baseRoll;           // Выбранное значение броска (e.g., 15 на d20)
  final String mode;            // "normal" | "advantage" | "disadvantage"
  final int modifier;           // Автоматически рассчитанный модификатор
  final int total;              // baseRoll + modifier
  final String createdAt;       // ISO 8601 timestamp
  final bool? success;          // null если не применимо, true если total >= targetAc

  RollResponse({
    required this.uid,
    required this.displayName,
    this.characterId,
    this.characterName,
    required this.baseRoll,
    required this.mode,
    required this.modifier,
    required this.total,
    required this.createdAt,
    this.success,
  });

  /// Сохранить в RTDB формате (Map)
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'displayName': displayName,
      'characterId': characterId,
      'characterName': characterName,
      'baseRoll': baseRoll,
      'mode': mode,
      'modifier': modifier,
      'total': total,
      'createdAt': createdAt,
      'success': success,
    };
  }

  /// Создать из RTDB формата (Map)
  factory RollResponse.fromMap(String uid, Map<String, dynamic> map) {
    return RollResponse(
      uid: uid,
      displayName: map['displayName'] as String? ?? 'Unknown',
      characterId: map['characterId'] as String?,
      characterName: map['characterName'] as String?,
      baseRoll: map['baseRoll'] as int? ?? 0,
      mode: map['mode'] as String? ?? 'normal',
      modifier: map['modifier'] as int? ?? 0,
      total: map['total'] as int? ?? 0,
      createdAt: map['createdAt'] as String? ?? DateTime.now().toIso8601String(),
      success: map['success'] as bool?,
    );
  }

  @override
  String toString() {
    return 'RollResponse(uid: $uid, baseRoll: $baseRoll, mode: $mode, total: $total, success: $success)';
  }
}

