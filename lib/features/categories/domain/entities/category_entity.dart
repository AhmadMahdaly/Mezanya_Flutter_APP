class CategoryEntity {
  final String id;
  final String name;
  final String? icon;
  final String? color;
  final String scope;
  final String? allocationId;
  final String? walletId;
  final String? incomeSourceId;
  final DateTime createdAt;
  final DateTime? modifiedAt;

  const CategoryEntity({
    required this.id,
    required this.name,
    this.icon,
    this.color,
    this.scope = 'expense',
    this.allocationId,
    this.walletId,
    this.incomeSourceId,
    required this.createdAt,
    this.modifiedAt,
  });

  CategoryEntity copyWith({
    String? id,
    String? name,
    String? icon,
    String? color,
    String? scope,
    String? allocationId,
    String? walletId,
    String? incomeSourceId,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return CategoryEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      scope: scope ?? this.scope,
      allocationId: allocationId ?? this.allocationId,
      walletId: walletId ?? this.walletId,
      incomeSourceId: incomeSourceId ?? this.incomeSourceId,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'icon': icon,
      'color': color,
      'scope': scope,
      'allocationId': allocationId,
      'walletId': walletId,
      'incomeSourceId': incomeSourceId,
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  factory CategoryEntity.fromMap(Map<String, dynamic> map) {
    return CategoryEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      icon: map['icon'] as String?,
      color: map['color'] as String?,
      scope: map['scope'] as String? ?? 'expense',
      allocationId: map['allocationId'] as String?,
      walletId: map['walletId'] as String?,
      incomeSourceId: map['incomeSourceId'] as String?,
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      modifiedAt: DateTime.tryParse(map['modifiedAt'] as String? ?? ''),
    );
  }
}