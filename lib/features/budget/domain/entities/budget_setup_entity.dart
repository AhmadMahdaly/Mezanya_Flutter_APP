import '../../../categories/domain/entities/category_entity.dart';

class IncomeSourceEntity {
  const IncomeSourceEntity({
    required this.id,
    required this.name,
    required this.amount,
    required this.date,
    required this.type,
    required this.targetWalletId,
    this.isVariable = false,
    this.isDefault = false,
  });

  final String id;
  final String name;
  final double amount;
  final int date;
  final String type;
  final String targetWalletId;
  final bool isVariable;
  final bool isDefault;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'date': date,
        'type': type,
        'targetWalletId': targetWalletId,
        'isVariable': isVariable,
        'isDefault': isDefault,
      };

  factory IncomeSourceEntity.fromMap(Map<String, dynamic> map) => IncomeSourceEntity(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        date: map['date'] as int? ?? 1,
        type: map['type'] as String? ?? 'confirm',
        targetWalletId: map['targetWalletId'] as String? ?? '',
        isVariable: map['isVariable'] as bool? ?? false,
        isDefault: map['isDefault'] as bool? ?? false,
      );
}

class AllocationFundingEntity {
  const AllocationFundingEntity({
    required this.id,
    required this.incomeSourceId,
    required this.plannedAmount,
  });

  final String id;
  final String incomeSourceId;
  final double plannedAmount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'incomeSourceId': incomeSourceId,
        'plannedAmount': plannedAmount,
      };

  factory AllocationFundingEntity.fromMap(Map<String, dynamic> map) => AllocationFundingEntity(
        id: map['id'] as String? ?? '',
        incomeSourceId: map['incomeSourceId'] as String? ?? '',
        plannedAmount: (map['plannedAmount'] as num?)?.toDouble() ?? 0,
      );
}

class AllocationEntity {
  const AllocationEntity({
    required this.id,
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.rolloverBehavior,
    required this.funding,
    required this.categories,
  });

  final String id;
  final String name;
  final String icon;
  final String iconColor;
  final String rolloverBehavior;
  final List<AllocationFundingEntity> funding;
  final List<CategoryEntity> categories;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'icon': icon,
        'iconColor': iconColor,
        'rolloverBehavior': rolloverBehavior,
        'funding': funding.map((e) => e.toMap()).toList(),
        'categories': categories.map((e) => e.toMap()).toList(),
      };

  factory AllocationEntity.fromMap(Map<String, dynamic> map) => AllocationEntity(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        icon: map['icon'] as String? ?? 'category',
        iconColor: map['iconColor'] as String? ?? '#165b47',
        rolloverBehavior: map['rolloverBehavior'] as String? ?? 'to-savings',
        funding: (map['funding'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AllocationFundingEntity.fromMap)
            .toList(),
        categories: (map['categories'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CategoryEntity.fromMap)
            .toList(),
      );
}

class LinkedWalletEntityFunding {
  const LinkedWalletEntityFunding({
    required this.id,
    required this.incomeSourceId,
    required this.plannedAmount,
  });

  final String id;
  final String incomeSourceId;
  final double plannedAmount;

  Map<String, dynamic> toMap() => {
        'id': id,
        'incomeSourceId': incomeSourceId,
        'plannedAmount': plannedAmount,
      };

  factory LinkedWalletEntityFunding.fromMap(Map<String, dynamic> map) => LinkedWalletEntityFunding(
        id: map['id'] as String? ?? '',
        incomeSourceId: map['incomeSourceId'] as String? ?? '',
        plannedAmount: (map['plannedAmount'] as num?)?.toDouble() ?? 0,
      );
}

class LinkedWalletEntity {
  const LinkedWalletEntity({
    required this.id,
    required this.name,
    required this.balance,
    required this.monthlyAmount,
    required this.executionDay,
    required this.fundingSource,
    required this.funding,
    required this.icon,
    required this.iconColor,
    required this.automationType,
    required this.categories,
  });

  final String id;
  final String name;
  final double balance;
  final double monthlyAmount;
  final int executionDay;
  final String fundingSource;
  final List<LinkedWalletEntityFunding> funding;
  final String icon;
  final String iconColor;
  final String automationType;
  final List<CategoryEntity> categories;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'balance': balance,
        'monthlyAmount': monthlyAmount,
        'executionDay': executionDay,
        'fundingSource': fundingSource,
        'funding': funding.map((e) => e.toMap()).toList(),
        'icon': icon,
        'iconColor': iconColor,
        'automationType': automationType,
        'categories': categories.map((e) => e.toMap()).toList(),
      };

  factory LinkedWalletEntity.fromMap(Map<String, dynamic> map) => LinkedWalletEntity(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        balance: (map['balance'] as num?)?.toDouble() ?? 0,
        monthlyAmount: (map['monthlyAmount'] as num?)?.toDouble() ?? 0,
        executionDay: map['executionDay'] as int? ?? 1,
        fundingSource: map['fundingSource'] as String? ?? '',
        funding: (map['funding'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(LinkedWalletEntityFunding.fromMap)
            .toList(),
        icon: map['icon'] as String? ?? 'PiggyBank',
        iconColor: map['iconColor'] as String? ?? '#0f766e',
        automationType: map['automationType'] as String? ?? 'confirm',
        categories: (map['categories'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(CategoryEntity.fromMap)
            .toList(),
      );
}

class DebtEntity {
  const DebtEntity({
    required this.id,
    required this.name,
    required this.amount,
    required this.executionDay,
    required this.type,
    required this.fundingSource,
  });

  final String id;
  final String name;
  final double amount;
  final int executionDay;
  final String type;
  final String fundingSource;

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'amount': amount,
        'executionDay': executionDay,
        'type': type,
        'fundingSource': fundingSource,
      };

  factory DebtEntity.fromMap(Map<String, dynamic> map) => DebtEntity(
        id: map['id'] as String? ?? '',
        name: map['name'] as String? ?? '',
        amount: (map['amount'] as num?)?.toDouble() ?? 0,
        executionDay: map['executionDay'] as int? ?? 1,
        type: map['type'] as String? ?? 'confirm',
        fundingSource: map['fundingSource'] as String? ?? '',
      );
}

class BudgetSetupEntity {
  const BudgetSetupEntity({
    required this.startDay,
    required this.cycleMode,
    required this.bufferEndBehavior,
    required this.incomeSources,
    required this.allocations,
    required this.linkedWallets,
    required this.debts,
    required this.totalIncome,
    required this.totalAllocated,
    required this.unallocatedAmount,
  });

  final int startDay;
  final String cycleMode;
  final String bufferEndBehavior;
  final List<IncomeSourceEntity> incomeSources;
  final List<AllocationEntity> allocations;
  final List<LinkedWalletEntity> linkedWallets;
  final List<DebtEntity> debts;
  final double totalIncome;
  final double totalAllocated;
  final double unallocatedAmount;

  factory BudgetSetupEntity.initial(String walletId) => BudgetSetupEntity(
        startDay: 1,
        cycleMode: 'confirm',
        bufferEndBehavior: 'to-savings',
        incomeSources: [
          IncomeSourceEntity(
            id: 'salary-default',
            name: 'الراتب',
            amount: 0,
            date: 1,
            type: 'confirm',
            targetWalletId: walletId,
            isDefault: true,
          ),
        ],
        allocations: const [],
        linkedWallets: const [],
        debts: const [],
        totalIncome: 0,
        totalAllocated: 0,
        unallocatedAmount: 0,
      );

  BudgetSetupEntity copyWith({
    int? startDay,
    String? cycleMode,
    String? bufferEndBehavior,
    List<IncomeSourceEntity>? incomeSources,
    List<AllocationEntity>? allocations,
    List<LinkedWalletEntity>? linkedWallets,
    List<DebtEntity>? debts,
    double? totalIncome,
    double? totalAllocated,
    double? unallocatedAmount,
  }) {
    return BudgetSetupEntity(
      startDay: startDay ?? this.startDay,
      cycleMode: cycleMode ?? this.cycleMode,
      bufferEndBehavior: bufferEndBehavior ?? this.bufferEndBehavior,
      incomeSources: incomeSources ?? this.incomeSources,
      allocations: allocations ?? this.allocations,
      linkedWallets: linkedWallets ?? this.linkedWallets,
      debts: debts ?? this.debts,
      totalIncome: totalIncome ?? this.totalIncome,
      totalAllocated: totalAllocated ?? this.totalAllocated,
      unallocatedAmount: unallocatedAmount ?? this.unallocatedAmount,
    );
  }

  Map<String, dynamic> toMap() => {
        'startDay': startDay,
        'cycleMode': cycleMode,
        'bufferEndBehavior': bufferEndBehavior,
        'incomeSources': incomeSources.map((e) => e.toMap()).toList(),
        'allocations': allocations.map((e) => e.toMap()).toList(),
        'linkedWallets': linkedWallets.map((e) => e.toMap()).toList(),
        'debts': debts.map((e) => e.toMap()).toList(),
        'totalIncome': totalIncome,
        'totalAllocated': totalAllocated,
        'unallocatedAmount': unallocatedAmount,
      };

  factory BudgetSetupEntity.fromMap(Map<String, dynamic> map) => BudgetSetupEntity(
        startDay: map['startDay'] as int? ?? 1,
        cycleMode: map['cycleMode'] as String? ?? 'confirm',
        bufferEndBehavior: map['bufferEndBehavior'] as String? ?? 'to-savings',
        incomeSources: (map['incomeSources'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(IncomeSourceEntity.fromMap)
            .toList(),
        allocations: (map['allocations'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(AllocationEntity.fromMap)
            .toList(),
        linkedWallets: (map['linkedWallets'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(LinkedWalletEntity.fromMap)
            .toList(),
        debts: (map['debts'] as List<dynamic>? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DebtEntity.fromMap)
            .toList(),
        totalIncome: (map['totalIncome'] as num?)?.toDouble() ?? 0,
        totalAllocated: (map['totalAllocated'] as num?)?.toDouble() ?? 0,
        unallocatedAmount: (map['unallocatedAmount'] as num?)?.toDouble() ?? 0,
      );
}
