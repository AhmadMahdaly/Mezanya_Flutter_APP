class GoalEntity {
  final String id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final DateTime startDate;
  final DateTime endDate;
  final String? linkedJarId;
  final bool isCompleted;
  final DateTime createdAt;
  final DateTime? modifiedAt;

  const GoalEntity({
    required this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    required this.startDate,
    required this.endDate,
    this.linkedJarId,
    this.isCompleted = false,
    required this.createdAt,
    this.modifiedAt,
  });

  GoalEntity copyWith({
    String? id,
    String? name,
    double? targetAmount,
    double? currentAmount,
    DateTime? startDate,
    DateTime? endDate,
    String? linkedJarId,
    bool? isCompleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return GoalEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      targetAmount: targetAmount ?? this.targetAmount,
      currentAmount: currentAmount ?? this.currentAmount,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      linkedJarId: linkedJarId ?? this.linkedJarId,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'targetAmount': targetAmount,
      'currentAmount': currentAmount,
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
      'linkedJarId': linkedJarId,
      'isCompleted': isCompleted,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  factory GoalEntity.fromMap(Map<String, dynamic> map) {
    return GoalEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      targetAmount: (map['targetAmount'] as num?)?.toDouble() ?? 0,
      currentAmount: (map['currentAmount'] as num?)?.toDouble() ?? 0,
      startDate: DateTime.tryParse(map['startDate'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(map['endDate'] as String? ?? '') ?? DateTime.now(),
      linkedJarId: map['linkedJarId'] as String?,
      isCompleted: map['isCompleted'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      modifiedAt: DateTime.tryParse(map['modifiedAt'] as String? ?? ''),
    );
  }
}