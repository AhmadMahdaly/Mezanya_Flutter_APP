class LogEntryEntity {
  final String id;
  final String action;
  final String entityType;
  final String entityId;
  final String details;
  final DateTime timestamp;
  final String beforeState;
  final String afterState;
  final bool isReverted;
  final DateTime? modifiedAt;

  const LogEntryEntity({
    required this.id,
    required this.action,
    required this.entityType,
    required this.entityId,
    required this.details,
    required this.timestamp,
    required this.beforeState,
    required this.afterState,
    this.isReverted = false,
    this.modifiedAt,
  });

  LogEntryEntity copyWith({
    String? id,
    String? action,
    String? entityType,
    String? entityId,
    String? details,
    DateTime? timestamp,
    String? beforeState,
    String? afterState,
    bool? isReverted,
    DateTime? modifiedAt,
  }) {
    return LogEntryEntity(
      id: id ?? this.id,
      action: action ?? this.action,
      entityType: entityType ?? this.entityType,
      entityId: entityId ?? this.entityId,
      details: details ?? this.details,
      timestamp: timestamp ?? this.timestamp,
      beforeState: beforeState ?? this.beforeState,
      afterState: afterState ?? this.afterState,
      isReverted: isReverted ?? this.isReverted,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'action': action,
      'entityType': entityType,
      'entityId': entityId,
      'details': details,
      'timestamp': timestamp.toIso8601String(),
      'beforeState': beforeState,
      'afterState': afterState,
      'isReverted': isReverted,
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  factory LogEntryEntity.fromMap(Map<String, dynamic> map) {
    return LogEntryEntity(
      id: map['id'] as String,
      action: map['action'] as String,
      entityType: map['entityType'] as String,
      entityId: map['entityId'] as String,
      details: map['details'] as String,
      timestamp: DateTime.tryParse(map['timestamp'] as String? ?? '') ?? DateTime.now(),
      beforeState: map['beforeState'] as String? ?? '',
      afterState: map['afterState'] as String? ?? '',
      isReverted: map['isReverted'] as bool? ?? false,
      modifiedAt: DateTime.tryParse(map['modifiedAt'] as String? ?? ''),
    );
  }
}