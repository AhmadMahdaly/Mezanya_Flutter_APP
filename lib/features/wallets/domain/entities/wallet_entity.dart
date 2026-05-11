class WalletEntity {
  final String id;
  final String name;
  final double balance;
  final double reservedForSavings;
  final String? icon;
  final String? iconColor;
  final bool isHighlighted;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? modifiedAt;

  const WalletEntity({
    required this.id,
    required this.name,
    this.balance = 0,
    this.reservedForSavings = 0,
    this.icon,
    this.iconColor,
    this.isHighlighted = false,
    this.isDeleted = false,
    required this.createdAt,
    this.modifiedAt,
  });

  WalletEntity copyWith({
    String? id,
    String? name,
    double? balance,
    double? reservedForSavings,
    String? icon,
    String? iconColor,
    bool? isHighlighted,
    bool? isDeleted,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      reservedForSavings: reservedForSavings ?? this.reservedForSavings,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'reservedForSavings': reservedForSavings,
      'icon': icon,
      'iconColor': iconColor,
      'isHighlighted': isHighlighted,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  factory WalletEntity.fromMap(Map<String, dynamic> map) {
    return WalletEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      reservedForSavings: (map['reservedForSavings'] as num?)?.toDouble() ?? 0,
      icon: map['icon'] as String?,
      iconColor: map['iconColor'] as String?,
      isHighlighted: map['isHighlighted'] as bool? ?? false,
      isDeleted: map['isDeleted'] as bool? ?? false,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      modifiedAt: DateTime.tryParse(map['modifiedAt'] as String? ?? ''),
    );
  }
}