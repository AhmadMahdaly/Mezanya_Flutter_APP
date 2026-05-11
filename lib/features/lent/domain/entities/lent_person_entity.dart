import 'package:mezanya/features/lent/domain/entities/lent_entry_entity.dart';

class LentPersonEntity {
  final String id;
  final String name;
  final String? walletId;
  final double totalLent;
  final double totalRepaid;
  final bool isArchived;
  final List<LentEntryEntity> entries;
  final DateTime createdAt;
  final DateTime? modifiedAt;

  const LentPersonEntity({
    required this.id,
    required this.name,
    this.walletId,
    this.totalLent = 0,
    this.totalRepaid = 0,
    this.isArchived = false,
    this.entries = const [],
    required this.createdAt,
    this.modifiedAt,
  });

  double get outstandingAmount => totalLent - totalRepaid;
  bool get isSettled => outstandingAmount <= 0.0001;

  LentPersonEntity copyWith({
    String? id,
    String? name,
    String? walletId,
    double? totalLent,
    double? totalRepaid,
    bool? isArchived,
    List<LentEntryEntity>? entries,
    DateTime? createdAt,
    DateTime? modifiedAt,
  }) {
    return LentPersonEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      walletId: walletId ?? this.walletId,
      totalLent: totalLent ?? this.totalLent,
      totalRepaid: totalRepaid ?? this.totalRepaid,
      isArchived: isArchived ?? this.isArchived,
      entries: entries ?? this.entries,
      createdAt: createdAt ?? this.createdAt,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'walletId': walletId,
      'totalLent': totalLent,
      'totalRepaid': totalRepaid,
      'isArchived': isArchived,
      'entries': entries.map((e) => e.toMap()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  factory LentPersonEntity.fromMap(Map<String, dynamic> map) {
    return LentPersonEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      walletId: map['walletId'] as String?,
      totalLent: (map['totalLent'] as num?)?.toDouble() ?? 0,
      totalRepaid: (map['totalRepaid'] as num?)?.toDouble() ?? 0,
      isArchived: map['isArchived'] as bool? ?? false,
      entries: (map['entries'] as List? ?? []).whereType<Map<String, dynamic>>().map(LentEntryEntity.fromMap).toList(),
      createdAt: DateTime.tryParse(map['createdAt'] as String? ?? '') ?? DateTime.now(),
      modifiedAt: DateTime.tryParse(map['modifiedAt'] as String? ?? ''),
    );
  }
}