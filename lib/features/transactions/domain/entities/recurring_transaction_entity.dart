class RecurringTransactionEntity {
  const RecurringTransactionEntity({
    required this.id,
    required this.name,
    required this.type,
    required this.amount,
    required this.dayOfMonth,
    required this.executionType,
    required this.walletId,
    required this.budgetScope,
    required this.recurrencePattern,
    this.weekday,
    this.allocationId,
    this.targetJarId,
    this.incomeSourceId,
    this.notes,
    this.isActive = true,
  });

  final String id;
  final String name;
  final String type;
  final double amount;
  final int dayOfMonth;
  final String executionType;
  final String walletId;
  final String budgetScope;
  final String recurrencePattern;
  final int? weekday;
  final String? allocationId;
  final String? targetJarId;
  final String? incomeSourceId;
  final String? notes;
  final bool isActive;

  RecurringTransactionEntity copyWith({
    String? id,
    String? name,
    String? type,
    double? amount,
    int? dayOfMonth,
    String? executionType,
    String? walletId,
    String? budgetScope,
    String? recurrencePattern,
    int? weekday,
    String? allocationId,
    String? targetJarId,
    String? incomeSourceId,
    String? notes,
    bool? isActive,
  }) {
    return RecurringTransactionEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      amount: amount ?? this.amount,
      dayOfMonth: dayOfMonth ?? this.dayOfMonth,
      executionType: executionType ?? this.executionType,
      walletId: walletId ?? this.walletId,
      budgetScope: budgetScope ?? this.budgetScope,
      recurrencePattern: recurrencePattern ?? this.recurrencePattern,
      weekday: weekday ?? this.weekday,
      allocationId: allocationId ?? this.allocationId,
      targetJarId: targetJarId ?? this.targetJarId,
      incomeSourceId: incomeSourceId ?? this.incomeSourceId,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'type': type,
      'amount': amount,
      'dayOfMonth': dayOfMonth,
      'executionType': executionType,
      'walletId': walletId,
      'budgetScope': budgetScope,
      'recurrencePattern': recurrencePattern,
      'weekday': weekday,
      'allocationId': allocationId,
      'targetJarId': targetJarId,
      'incomeSourceId': incomeSourceId,
      'notes': notes,
      'isActive': isActive,
    };
  }

  factory RecurringTransactionEntity.fromMap(Map<String, dynamic> map) {
    return RecurringTransactionEntity(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? 'expense',
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      dayOfMonth: (map['dayOfMonth'] as int? ?? 1).clamp(1, 31),
      executionType: map['executionType'] as String? ?? 'confirm',
      walletId: map['walletId'] as String? ?? '',
      budgetScope: map['budgetScope'] as String? ?? 'outside-budget',
      recurrencePattern: map['recurrencePattern'] as String? ?? 'monthly',
      weekday: map['weekday'] as int?,
      allocationId: map['allocationId'] as String?,
      targetJarId: map['targetJarId'] as String?,
      incomeSourceId: map['incomeSourceId'] as String?,
      notes: map['notes'] as String?,
      isActive: map['isActive'] as bool? ?? true,
    );
  }
}
