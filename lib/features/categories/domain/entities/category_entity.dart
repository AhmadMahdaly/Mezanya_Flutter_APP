class CategoryEntity {
  const CategoryEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.scope,
    this.allocationId,
    this.walletId,
    this.incomeSourceId,
  });

  final String id;
  final String name;
  final String icon;
  final String color;
  final String scope;
  final String? allocationId;
  final String? walletId;
  final String? incomeSourceId;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'color': color,
        'scope': scope,
        'allocationId': allocationId,
        'walletId': walletId,
        'incomeSourceId': incomeSourceId,
      };

  factory CategoryEntity.fromMap(Map<String, dynamic> map) => CategoryEntity(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        icon: map['icon'] as String? ?? 'UtensilsCrossed',
        color: map['color'] as String? ?? '#165b47',
        scope: map['scope'] as String? ?? 'expense',
        allocationId: map['allocationId'] as String?,
        walletId: map['walletId'] as String?,
        incomeSourceId: map['incomeSourceId'] as String?,
      );
}
