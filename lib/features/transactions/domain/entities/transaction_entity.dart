class TransactionEntity {
  final String id;
  final String? walletId;
  final String? fromWalletId;
  final String? toWalletId;
  final String? fromType;
  final String? toType;
  final String? allocationId;
  final String? toAllocationId;
  final String? incomeSourceId;
  final String? categoryId;
  final double amount;
  final String type;
  final String budgetScope;
  final String? transferType;
  final String? notes;
  final DateTime createdAt;
  final DateTime? modifiedAt;

  const TransactionEntity({
    required this.id,
    this.walletId,
    this.fromWalletId,
    this.toWalletId,
    this.fromType,
    this.toType,
    this.allocationId,
    this.toAllocationId,
    this.incomeSourceId,
    this.categoryId,
    required this.amount,
    required this.type,
    this.budgetScope = 'outside-budget',
    this.transferType,
    this.notes,
    required this.createdAt,
    this.modifiedAt,
  });

  TransactionEntity copyWith({
    String? id,
    String? walletId,
    String? fromWalletId,
    String? toWalletId,
    String? fromType,
    String? toType,
    String? allocationId,
    String? toAllocationId,
    String? incomeSourceId,
    String? categoryId,
    double? amount,
    String? type,
    String? budgetScope,
    String? transferType,
    String? notes,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return TransactionEntity(
      id: id ?? this.id,
      walletId: walletId ?? this.walletId,
      fromWalletId: fromWalletId ?? this.fromWalletId,
      toWalletId: toWalletId ?? this.toWalletId,
      fromType: fromType ?? this.fromType,
      toType: toType ?? this.toType,
      allocationId: allocationId ?? this.allocationId,
      toAllocationId: toAllocationId ?? this.toAllocationId,
      incomeSourceId: incomeSourceId ?? this.incomeSourceId,
      categoryId: categoryId ?? this.categoryId,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      budgetScope: budgetScope ?? this.budgetScope,
      transferType: transferType ?? this.transferType,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'walletId': walletId,
      'fromWalletId': fromWalletId,
      'toWalletId': toWalletId,
      'fromType': fromType,
      'toType': toType,
      'allocationId': allocationId,
      'toAllocationId': toAllocationId,
      'incomeSourceId': incomeSourceId,
      'categoryId': categoryId,
      'amount': amount,
      'type': type,
      'budgetScope': budgetScope,
      'transferType': transferType,
      'notes': notes,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  factory TransactionEntity.fromMap(Map<String, dynamic> map) {
    return TransactionEntity(
      id: map['id'] as String,
      walletId: map['walletId'] as String?,
      fromWalletId: map['fromWalletId'] as String?,
      toWalletId: map['toWalletId'] as String?,
      fromType: map['fromType'] as String?,
      toType: map['toType'] as String?,
      allocationId: map['allocationId'] as String?,
      toAllocationId: map['toAllocationId'] as String?,
      incomeSourceId: map['incomeSourceId'] as String?,
      categoryId: map['categoryId'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      type: map['type'] as String? ?? 'expense',
      budgetScope: map['budgetScope'] as String? ?? 'outside-budget',
      transferType: map['transferType'] as String?,
      notes: map['notes'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      modifiedAt: DateTime.tryParse(map['modifiedAt'] as String? ?? ''),
    );
  }
}