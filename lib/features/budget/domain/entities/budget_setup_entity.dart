class BudgetSetupEntity {
  final int startDay;
  final String cycleMode;
  final String bufferEndBehavior;
  final List<IncomeSourceEntity> incomeSources;
  final List<AllocationEntity> allocations;
  final List<LinkedWalletEntity> linkedWallets;
  final List<DebtEntity> debts;
  final DateTime? modifiedAt;

  const BudgetSetupEntity({
    required this.startDay,
    required this.cycleMode,
    required this.bufferEndBehavior,
    required this.incomeSources,
    required this.allocations,
    required this.linkedWallets,
    required this.debts,
    this.modifiedAt,
  });

  double get totalIncome => incomeSources.fold(0.0, (s, i) => s + i.amount);

  double get totalAllocated {
    final jarTotal = linkedWallets.fold(0.0, (s, j) => s + j.monthlyAmount);
    final allocTotal = allocations.fold(0.0, (s, a) => s + a.balance);
    final debtTotal = debts.fold(0.0, (s, d) => s + d.amount);
    return jarTotal + allocTotal + debtTotal;
  }

  double get unallocatedAmount => (totalIncome - totalAllocated).clamp(0.0, double.infinity);

  factory BudgetSetupEntity.initial() {
    return BudgetSetupEntity(
      startDay: 1,
      cycleMode: 'confirm',
      bufferEndBehavior: 'to-savings',
      incomeSources: const [],
      allocations: const [],
      linkedWallets: const [],
      debts: const [],
      modifiedAt: DateTime.now(),
    );
  }

  BudgetSetupEntity copyWith({
    int? startDay,
    String? cycleMode,
    String? bufferEndBehavior,
    List<IncomeSourceEntity>? incomeSources,
    List<AllocationEntity>? allocations,
    List<LinkedWalletEntity>? linkedWallets,
    List<DebtEntity>? debts,
    DateTime? modifiedAt,
  }) {
    return BudgetSetupEntity(
      startDay: startDay ?? this.startDay,
      cycleMode: cycleMode ?? this.cycleMode,
      bufferEndBehavior: bufferEndBehavior ?? this.bufferEndBehavior,
      incomeSources: incomeSources ?? this.incomeSources,
      allocations: allocations ?? this.allocations,
      linkedWallets: linkedWallets ?? this.linkedWallets,
      debts: debts ?? this.debts,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'startDay': startDay,
      'cycleMode': cycleMode,
      'bufferEndBehavior': bufferEndBehavior,
      'incomeSources': incomeSources.map((e) => e.toMap()).toList(),
      'allocations': allocations.map((e) => e.toMap()).toList(),
      'linkedWallets': linkedWallets.map((e) => e.toMap()).toList(),
      'debts': debts.map((e) => e.toMap()).toList(),
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  factory BudgetSetupEntity.fromMap(Map<String, dynamic> map) {
    return BudgetSetupEntity(
      startDay: map['startDay'] as int? ?? 1,
      cycleMode: map['cycleMode'] as String? ?? 'confirm',
      bufferEndBehavior: map['bufferEndBehavior'] as String? ?? 'to-savings',
      incomeSources: (map['incomeSources'] as List? ?? []).whereType<Map<String, dynamic>>().map(IncomeSourceEntity.fromMap).toList(),
      allocations: (map['allocations'] as List? ?? []).whereType<Map<String, dynamic>>().map(AllocationEntity.fromMap).toList(),
      linkedWallets: (map['linkedWallets'] as List? ?? []).whereType<Map<String, dynamic>>().map(LinkedWalletEntity.fromMap).toList(),
      debts: (map['debts'] as List? ?? []).whereType<Map<String, dynamic>>().map(DebtEntity.fromMap).toList(),
      modifiedAt: DateTime.tryParse(map['modifiedAt'] as String? ?? ''),
    );
  }

  DateTime cycleStartFor(DateTime now) {
    final thisMonth = DateTime(now.year, now.month, startDay.clamp(1, 28));
    return now.isBefore(thisMonth) ? DateTime(now.year, now.month - 1, startDay.clamp(1, 28)) : thisMonth;
  }

  DateTime cycleEndFor(DateTime now) {
    final start = cycleStartFor(now);
    return DateTime(start.year, start.month + 1, start.day).subtract(const Duration(days: 1));
  }

  String cycleKeyFor(DateTime now) {
    final s = cycleStartFor(now);
    return '${s.year}-${s.month.toString().padLeft(2, '0')}-${s.day.toString().padLeft(2, '0')}';
  }
}

class IncomeSourceEntity {
  final String id;
  final String name;
  final double amount;
  final String? snoozedUntil;
  final DateTime? modifiedAt;

  const IncomeSourceEntity({required this.id, required this.name, required this.amount, this.snoozedUntil, this.modifiedAt});

  bool get isSnoozed {
    if (snoozedUntil == null || snoozedUntil!.isEmpty) return false;
    final until = DateTime.tryParse(snoozedUntil!);
    if (until == null) return false;
    return DateTime.now().toUtc().isBefore(until.toUtc());
  }

  IncomeSourceEntity copyWith({String? id, String? name, double? amount, String? snoozedUntil, DateTime? modifiedAt}) {
    return IncomeSourceEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      snoozedUntil: snoozedUntil ?? this.snoozedUntil,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {'id': id, 'name': name, 'amount': amount, 'snoozedUntil': snoozedUntil, 'modifiedAt': modifiedAt?.toIso8601String()};
  }

  factory IncomeSourceEntity.fromMap(Map<String, dynamic> map) {
    return IncomeSourceEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      snoozedUntil: map['snoozedUntil'] as String?,
      modifiedAt: DateTime.tryParse(map['modifiedAt'] as String? ?? ''),
    );
  }
}

class AllocationEntity {
  final String id;
  final String name;
  final double balance;
  final double monthlyAmount;
  final List<AllocationFundingEntity> funding;
  final Map<String, double> walletBalances;
  final String automationType;
  final double pendingDistribution;
  final String pendingDistributionWalletId;
  final String pendingDistributionSourceId;
  final DateTime? modifiedAt;

  const AllocationEntity({
    required this.id,
    required this.name,
    this.balance = 0,
    this.monthlyAmount = 0,
    this.funding = const [],
    this.walletBalances = const {},
    this.automationType = 'manual',
    this.pendingDistribution = 0,
    this.pendingDistributionWalletId = '',
    this.pendingDistributionSourceId = '',
    this.modifiedAt,
  });

  AllocationEntity copyWith({
    String? id,
    String? name,
    double? balance,
    double? monthlyAmount,
    List<AllocationFundingEntity>? funding,
    Map<String, double>? walletBalances,
    String? automationType,
    double? pendingDistribution,
    String? pendingDistributionWalletId,
    String? pendingDistributionSourceId,
    DateTime? modifiedAt,
  }) {
    return AllocationEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      funding: funding ?? this.funding,
      walletBalances: walletBalances ?? this.walletBalances,
      automationType: automationType ?? this.automationType,
      pendingDistribution: pendingDistribution ?? this.pendingDistribution,
      pendingDistributionWalletId: pendingDistributionWalletId ?? this.pendingDistributionWalletId,
      pendingDistributionSourceId: pendingDistributionSourceId ?? this.pendingDistributionSourceId,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'monthlyAmount': monthlyAmount,
      'funding': funding.map((e) => e.toMap()).toList(),
      'walletBalances': walletBalances,
      'automationType': automationType,
      'pendingDistribution': pendingDistribution,
      'pendingDistributionWalletId': pendingDistributionWalletId,
      'pendingDistributionSourceId': pendingDistributionSourceId,
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  factory AllocationEntity.fromMap(Map<String, dynamic> map) {
    return AllocationEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      monthlyAmount: (map['monthlyAmount'] as num?)?.toDouble() ?? 0,
      funding: (map['funding'] as List? ?? []).whereType<Map<String, dynamic>>().map(AllocationFundingEntity.fromMap).toList(),
      walletBalances: (map['walletBalances'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
      automationType: map['automationType'] as String? ?? 'manual',
      pendingDistribution: (map['pendingDistribution'] as num?)?.toDouble() ?? 0,
      pendingDistributionWalletId: map['pendingDistributionWalletId'] as String? ?? '',
      pendingDistributionSourceId: map['pendingDistributionSourceId'] as String? ?? '',
      modifiedAt: DateTime.tryParse(map['modifiedAt'] as String? ?? ''),
    );
  }
}

class AllocationFundingEntity {
  final String incomeSourceId;
  final double plannedAmount;
  const AllocationFundingEntity({required this.incomeSourceId, required this.plannedAmount});
  AllocationFundingEntity copyWith({String? incomeSourceId, double? plannedAmount}) {
    return AllocationFundingEntity(incomeSourceId: incomeSourceId ?? this.incomeSourceId, plannedAmount: plannedAmount ?? this.plannedAmount);
  }
  Map<String, dynamic> toMap() => {'incomeSourceId': incomeSourceId, 'plannedAmount': plannedAmount};
  factory AllocationFundingEntity.fromMap(Map<String, dynamic> map) {
    return AllocationFundingEntity(incomeSourceId: map['incomeSourceId'] as String, plannedAmount: (map['plannedAmount'] as num?)?.toDouble() ?? 0);
  }
}

class LinkedWalletEntity {
  final String id;
  final String name;
  final double balance;
  final double monthlyAmount;
  final double reservedForSavings;
  final List<LinkedWalletEntityFunding> funding;
  final Map<String, double> walletBalances;
  final List<JarWalletSource> walletSources;
  final String automationType;
  final double pendingDistribution;
  final String pendingDistributionWalletId;
  final String pendingDistributionSourceId;
  final DateTime? modifiedAt;

  const LinkedWalletEntity({
    required this.id,
    required this.name,
    this.balance = 0,
    this.monthlyAmount = 0,
    this.reservedForSavings = 0,
    this.funding = const [],
    this.walletBalances = const {},
    this.walletSources = const [],
    this.automationType = 'manual',
    this.pendingDistribution = 0,
    this.pendingDistributionWalletId = '',
    this.pendingDistributionSourceId = '',
    this.modifiedAt,
  });

  LinkedWalletEntity copyWith({
    String? id,
    String? name,
    double? balance,
    double? monthlyAmount,
    double? reservedForSavings,
    List<LinkedWalletEntityFunding>? funding,
    Map<String, double>? walletBalances,
    List<JarWalletSource>? walletSources,
    String? automationType,
    double? pendingDistribution,
    String? pendingDistributionWalletId,
    String? pendingDistributionSourceId,
    DateTime? modifiedAt,
  }) {
    return LinkedWalletEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      balance: balance ?? this.balance,
      monthlyAmount: monthlyAmount ?? this.monthlyAmount,
      reservedForSavings: reservedForSavings ?? this.reservedForSavings,
      funding: funding ?? this.funding,
      walletBalances: walletBalances ?? this.walletBalances,
      walletSources: walletSources ?? this.walletSources,
      automationType: automationType ?? this.automationType,
      pendingDistribution: pendingDistribution ?? this.pendingDistribution,
      pendingDistributionWalletId: pendingDistributionWalletId ?? this.pendingDistributionWalletId,
      pendingDistributionSourceId: pendingDistributionSourceId ?? this.pendingDistributionSourceId,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'balance': balance,
      'monthlyAmount': monthlyAmount,
      'reservedForSavings': reservedForSavings,
      'funding': funding.map((e) => e.toMap()).toList(),
      'walletBalances': walletBalances,
      'walletSources': walletSources.map((e) => e.toMap()).toList(),
      'automationType': automationType,
      'pendingDistribution': pendingDistribution,
      'pendingDistributionWalletId': pendingDistributionWalletId,
      'pendingDistributionSourceId': pendingDistributionSourceId,
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  factory LinkedWalletEntity.fromMap(Map<String, dynamic> map) {
    return LinkedWalletEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      balance: (map['balance'] as num?)?.toDouble() ?? 0,
      monthlyAmount: (map['monthlyAmount'] as num?)?.toDouble() ?? 0,
      reservedForSavings: (map['reservedForSavings'] as num?)?.toDouble() ?? 0,
      funding: (map['funding'] as List? ?? []).whereType<Map<String, dynamic>>().map(LinkedWalletEntityFunding.fromMap).toList(),
      walletBalances: (map['walletBalances'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, (v as num).toDouble())) ?? {},
      walletSources: (map['walletSources'] as List? ?? []).whereType<Map<String, dynamic>>().map(JarWalletSource.fromMap).toList(),
      automationType: map['automationType'] as String? ?? 'manual',
      pendingDistribution: (map['pendingDistribution'] as num?)?.toDouble() ?? 0,
      pendingDistributionWalletId: map['pendingDistributionWalletId'] as String? ?? '',
      pendingDistributionSourceId: map['pendingDistributionSourceId'] as String? ?? '',
      modifiedAt: DateTime.tryParse(map['modifiedAt'] as String? ?? ''),
    );
  }
}

class LinkedWalletEntityFunding {
  final String incomeSourceId;
  final double plannedAmount;
  const LinkedWalletEntityFunding({required this.incomeSourceId, required this.plannedAmount});
  LinkedWalletEntityFunding copyWith({String? incomeSourceId, double? plannedAmount}) {
    return LinkedWalletEntityFunding(incomeSourceId: incomeSourceId ?? this.incomeSourceId, plannedAmount: plannedAmount ?? this.plannedAmount);
  }
  Map<String, dynamic> toMap() => {'incomeSourceId': incomeSourceId, 'plannedAmount': plannedAmount};
  factory LinkedWalletEntityFunding.fromMap(Map<String, dynamic> map) {
    return LinkedWalletEntityFunding(incomeSourceId: map['incomeSourceId'] as String, plannedAmount: (map['plannedAmount'] as num?)?.toDouble() ?? 0);
  }
}

class JarWalletSource {
  final String walletId;
  final String label;
  const JarWalletSource({required this.walletId, required this.label});
  JarWalletSource copyWith({String? walletId, String? label}) {
    return JarWalletSource(walletId: walletId ?? this.walletId, label: label ?? this.label);
  }
  Map<String, dynamic> toMap() => {'walletId': walletId, 'label': label};
  factory JarWalletSource.fromMap(Map<String, dynamic> map) {
    return JarWalletSource(walletId: map['walletId'] as String, label: map['label'] as String);
  }
}

class DebtEntity {
  final String id;
  final String name;
  final double amount;
  final String? recurringTransactionId;
  final DateTime? modifiedAt;

  const DebtEntity({required this.id, required this.name, required this.amount, this.recurringTransactionId, this.modifiedAt});

  DebtEntity copyWith({String? id, String? name, double? amount, String? recurringTransactionId, DateTime? modifiedAt}) {
    return DebtEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      amount: amount ?? this.amount,
      recurringTransactionId: recurringTransactionId ?? this.recurringTransactionId,
      modifiedAt: modifiedAt ?? this.modifiedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'amount': amount,
      'recurringTransactionId': recurringTransactionId,
      'modifiedAt': modifiedAt?.toIso8601String(),
    };
  }

  factory DebtEntity.fromMap(Map<String, dynamic> map) {
    return DebtEntity(
      id: map['id'] as String,
      name: map['name'] as String,
      amount: (map['amount'] as num?)?.toDouble() ?? 0,
      recurringTransactionId: map['recurringTransactionId'] as String?,
      modifiedAt: DateTime.tryParse(map['modifiedAt'] as String? ?? ''),
    );
  }
}