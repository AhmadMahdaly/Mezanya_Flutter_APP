class RecurringTransactionEntity {
  final String id;
  final String name;
  final double amount;
  final String type;  // 'income' | 'expense'
  final String recurrencePattern;  // 'daily' | 'weekly' | 'monthly' | 'yearly'
  final int dayOfMonth;
  final String budgetScope;  // 'within-budget' | 'outside-budget'
  final String? incomeSourceId;
  final String? walletId;
  final String executionType;  // 'auto' | 'confirm' | 'manual'
  final int? reminderLeadDays;
  final DateTime startDate;
  final DateTime? endDate;
  final bool isActive;
  final DateTime? modifiedAt;

  const RecurringTransactionEntity({
    required this.id,
    required this.name,
    required this.amount,
    required this.type,
    required this.recurrencePattern,
    this.dayOfMonth = 1,
    this.budgetScope = 'within-budget',
    this.incomeSourceId,
    this.walletId,
    this.executionType = 'confirm',
    this.reminderLeadDays,
    required this.startDate,
    this.endDate,
    this.isActive = true,
    this.modifiedAt,
  });

  // ... copyWith, toMap, fromMap ...
}