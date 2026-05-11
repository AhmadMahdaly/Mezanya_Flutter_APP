class LentEntryEntity {
  final String id;
  final double amount;
  final DateTime lentDate;
  final DateTime expectedReturnDate;
  final String? notes;
  final bool isSettled;
  final DateTime? settledAt;
  final String? settlementTransactionId;

  const LentEntryEntity({
    required this.id,
    required this.amount,
    required this.lentDate,
    required this.expectedReturnDate,
    this.notes,
    this.isSettled = false,
    this.settledAt,
    this.settlementTransactionId,
  });

  LentEntryEntity copyWith({
    String? id,
    double? amount,
    DateTime? lentDate,
    DateTime? expectedReturnDate,
    String? notes,
    bool? isSettled,
    DateTime? settledAt,
    String? settlementTransactionId,
  }) {
    return LentEntryEntity(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      lentDate: lentDate ?? this.lentDate,
      expectedReturnDate: expectedReturnDate ?? this.expectedReturnDate,
      notes: notes ?? this.notes,
      isSettled: isSettled ?? this.isSettled,
      settledAt: settledAt ?? this.settledAt,
      settlementTransactionId: settlementTransactionId ?? this.settlementTransactionId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
      'lentDate': lentDate.toIso8601String(),
      'expectedReturnDate': expectedReturnDate.toIso8601String(),
      'notes': notes,
      'isSettled': isSettled,
      'settledAt': settledAt?.toIso8601String(),
      'settlementTransactionId': settlementTransactionId,
    };
  }

  factory LentEntryEntity.fromMap(Map<String, dynamic> map) {
    return LentEntryEntity(
      id: map['id'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      lentDate: DateTime.tryParse(map['lentDate'] as String? ?? '') ?? DateTime.now(),
      expectedReturnDate: DateTime.tryParse(map['expectedReturnDate'] as String? ?? '') ?? DateTime.now(),
      notes: map['notes'] as String?,
      isSettled: map['isSettled'] as bool? ?? false,
      settledAt: DateTime.tryParse(map['settledAt'] as String? ?? ''),
      settlementTransactionId: map['settlementTransactionId'] as String?,
    );
  }
}