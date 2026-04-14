class WalletEntity {
  const WalletEntity({
    required this.id,
    required this.name,
    required this.balance,
    this.icon,
    this.iconColor,
  });

  final String id;
  final String name;
  final double balance;
  final String? icon;
  final String? iconColor;

  WalletEntity copyWith({
    String? id,
    String? name,
    double? balance,
    String? icon,
    String? iconColor,
  }) {
    return WalletEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      icon: icon ?? this.icon,
      iconColor: iconColor ?? this.iconColor,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      'balance': balance,
      'icon': icon,
      'iconColor': iconColor,
    };
  }

  factory WalletEntity.fromMap(Map<String, dynamic> map) {
    return WalletEntity(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? '',
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      icon: map['icon'] as String?,
      iconColor: map['iconColor'] as String?,
    );
  }
}
