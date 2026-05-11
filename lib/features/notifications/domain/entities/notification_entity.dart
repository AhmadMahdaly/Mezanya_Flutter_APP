class NotificationEntity {
  final String id;
  final String title;
  final String message;
  final DateTime createdAt;
  final bool isRead;
  final String type;
  final String? relatedLogId;
  final DateTime? modifiedAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.message,
    required this.createdAt,
    this.isRead = false,
    required this.type,
    this.relatedLogId,
    this.modifiedAt,
  });

  NotificationEntity copyWith({
    String? id,
    String? title,
    String? message,
    DateTime? createdAt,
    bool? isRead,
    String? type,
    String? relatedLogId,
    DateTime? modifiedAt,
  }) {
    return NotificationEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      isRead: isRead ?? this.isRead,
      type: type ?? this.type,
      relatedLogId: relatedLogId ?? this.relatedLogId,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'type': type,
      'relatedLogId': relatedLogId,
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  factory NotificationEntity.fromMap(Map<String, dynamic> map) {
    return NotificationEntity(
      id: map['id'] as String,
      title: map['title'] as String,
      message: map['message'] as String,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      isRead: map['isRead'] as bool? ?? false,
      type: map['type'] as String,
      relatedLogId: map['relatedLogId'] as String?,
      modifiedAt: DateTime.tryParse(map['modifiedAt'] as String? ?? ''),
    );
  }
}