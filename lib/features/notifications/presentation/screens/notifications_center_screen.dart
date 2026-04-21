import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_state/domain/entities/app_state_entity.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../../budget/domain/entities/budget_setup_entity.dart';
import '../../../logs/domain/entities/log_entry_entity.dart';
import '../../../transactions/domain/entities/recurring_transaction_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../domain/entities/notification_entity.dart';
import '../widgets/notification_center_widgets.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.cubit});

  final AppCubit cubit;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _selectedTab = 'new';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStateEntity>(
      stream: widget.cubit.stream,
      initialData: widget.cubit.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? widget.cubit.state;
        final pendingCards = _pendingNotificationCards(state);
        final historyItems = _historyNotifications(state);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            NotificationsTabSelector(
              selectedTab: _selectedTab,
              pendingCount: pendingCards.length,
              historyCount: historyItems.length,
              onTabChanged: (value) => setState(() => _selectedTab = value),
            ),
            const SizedBox(height: 12),
            if (_selectedTab == 'new') ...[
              if (pendingCards.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('لا توجد إشعارات تحتاج إجراء الآن.'),
                  ),
                )
              else
                ...pendingCards,
            ] else ...[
              if (historyItems.isEmpty)
                const Card(
                  child: ListTile(
                    title: Text('سجل الإشعارات فارغ.'),
                  ),
                )
              else
                ...historyItems.map((item) => _buildHistoryTile(state, item)),
            ],
          ],
        );
      },
    );
  }

  List<Widget> _pendingNotificationCards(AppStateEntity state) {
    final cards = <Widget>[];
    final budget = state.budgetSetup;
    final month = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final monthTransactions = state.transactions.where((transaction) {
      return transaction.createdAt.year == month.year &&
          transaction.createdAt.month == month.month;
    }).toList();
    final incomeTransactions = monthTransactions
        .where((transaction) => transaction.type == 'income')
        .toList();

    for (final source in budget.incomeSources) {
      final sourceTransactions = incomeTransactions
          .where((transaction) => transaction.incomeSourceId == source.id)
          .toList();
      final pendingMeta = _incomePendingMeta(
        state,
        source,
        sourceTransactions,
        month,
      );
      if (pendingMeta == null) {
        continue;
      }

      cards.add(
        PendingNotificationCard(
          accent: pendingMeta.isDueOrLate
              ? const Color(0xFF0F9D7A)
              : const Color(0xFF4C8BF5),
          title: source.name,
          subtitle: pendingMeta.status,
          amount: source.amount,
          actions: [
            if (pendingMeta.canEarly)
              PendingNotificationAction(
                label: 'بكر',
                filled: false,
                onPressed: () => _recordIncome(source, early: true),
              ),
            if (pendingMeta.isDueOrLate)
              PendingNotificationAction(
                label: 'نزول',
                onPressed: () => _recordIncome(source),
              ),
            if (pendingMeta.isDueOrLate)
              PendingNotificationAction(
                label: 'تأجيل',
                filled: false,
                onPressed: () => _postponeIncome(source, month),
              ),
          ],
        ),
      );
    }

    for (final debt in budget.debts) {
      final recurring = _linkedRecurringDebt(state, debt);
      final paidAmount = monthTransactions
          .where((transaction) => transaction.notes?.contains(debt.name) == true)
          .fold<double>(0, (sum, transaction) => sum + transaction.amount);
      final remaining = (debt.amount - paidAmount).clamp(0.0, debt.amount);
      final pendingMeta = _expensePendingMeta(recurring);
      if (remaining <= 0 || pendingMeta == null || !pendingMeta.pending) {
        continue;
      }

      cards.add(
        PendingNotificationCard(
          accent: const Color(0xFFC65D2E),
          title: debt.name,
          subtitle: pendingMeta.status,
          amount: remaining,
          actions: [
            PendingNotificationAction(
              label: 'نزول',
              onPressed: () => _recordDebt(
                debt,
                recurring!,
                pendingMeta.occurrence,
              ),
            ),
            PendingNotificationAction(
              label: 'تأجيل',
              filled: false,
              onPressed: () => _snoozeRecurringExpense(
                recurring!,
                pendingMeta.occurrence,
              ),
            ),
          ],
        ),
      );
    }

    return cards;
  }

  List<NotificationEntity> _historyNotifications(AppStateEntity state) {
    final items = state.notifications.where((item) {
      if (item.relatedLogId == null) {
        return false;
      }
      final text = '${item.title} ${item.message}';
      return text.contains('دخل') ||
          text.contains('دين') ||
          text.contains('تأجيل') ||
          text.contains('التراجع');
    }).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return items;
  }

  Widget _buildHistoryTile(AppStateEntity state, NotificationEntity item) {
    final relatedLog = state.logs.where((log) => log.id == item.relatedLogId).toList();
    final log = relatedLog.isEmpty ? null : relatedLog.first;

    return NotificationHistoryTile(
      title: item.title,
      subtitle: item.message,
      trailing: DateFormat('d/M HH:mm', 'ar').format(item.createdAt),
      onTap: () => _openHistorySheet(item, log),
    );
  }

  Future<void> _openHistorySheet(
    NotificationEntity item,
    LogEntryEntity? log,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.62,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(item.title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(item.message),
            const SizedBox(height: 8),
            Text(
              'الوقت: ${DateFormat('d/M/yyyy - HH:mm', 'ar').format(item.createdAt)}',
            ),
            if (log != null) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () async {
                  await widget.cubit.toggleLogRevert(log.id);
                  if (context.mounted) {
                    Navigator.pop(context);
                  }
                },
                icon: Icon(
                  log.isReverted ? Icons.redo_rounded : Icons.undo_rounded,
                ),
                label: Text(
                  log.isReverted ? 'إلغاء التراجع' : 'التراجع عن الإجراء',
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  RecurringTransactionEntity? _linkedRecurringIncome(
    AppStateEntity state,
    IncomeSourceEntity source,
  ) {
    final linked = state.recurringTransactions.where(
      (item) =>
          item.type == 'income' &&
          item.budgetScope == 'within-budget' &&
          (item.incomeSourceId == source.id ||
              ((item.incomeSourceId ?? '').isEmpty &&
                  item.name == source.name &&
                  item.walletId == source.targetWalletId)),
    );
    return linked.isEmpty ? null : linked.first;
  }

  _IncomePendingMeta? _incomePendingMeta(
    AppStateEntity state,
    IncomeSourceEntity source,
    List<TransactionEntity> sourceTransactions,
    DateTime month,
  ) {
    if (source.isVariable || sourceTransactions.isNotEmpty) {
      return null;
    }

    final recurring = _linkedRecurringIncome(state, source);
    final dueDate = _incomeDueDateForMonth(source, month);
    final reminderLeadDays = (recurring?.reminderLeadDays ?? 0).clamp(0, 3);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final reminderDate = dueDate.subtract(Duration(days: reminderLeadDays));
    final canEarly = reminderLeadDays > 0 &&
        !today.isBefore(reminderDate) &&
        today.isBefore(dueDate);
    final isDueOrLate = !today.isBefore(dueDate);
    if (!canEarly && !isDueOrLate) {
      return null;
    }

    final dateLabel = '${dueDate.day}/${dueDate.month}';
    final timeLabel = recurring?.scheduledTime?.isNotEmpty == true
        ? recurring!.scheduledTime!
        : null;

    return _IncomePendingMeta(
      canEarly: canEarly,
      isDueOrLate: isDueOrLate,
      status: isDueOrLate
          ? 'مستحق الآن • $dateLabel${timeLabel == null ? '' : ' • $timeLabel'}'
          : 'بكر • $dateLabel${timeLabel == null ? '' : ' • $timeLabel'}',
    );
  }

  RecurringTransactionEntity? _linkedRecurringDebt(
    AppStateEntity state,
    DebtEntity debt,
  ) {
    final recurring = state.recurringTransactions.where(
      (item) =>
          item.type == 'expense' &&
          item.budgetScope == 'within-budget' &&
          item.isDebtOrSubscription &&
          (((debt.recurringTransactionId ?? '').isNotEmpty &&
                  item.id == debt.recurringTransactionId) ||
              (item.name == debt.name)),
    );
    return recurring.isEmpty ? null : recurring.first;
  }

  _ExpensePendingMeta? _expensePendingMeta(
    RecurringTransactionEntity? recurring,
  ) {
    if (recurring == null || recurring.executionType != 'confirm') {
      return null;
    }

    final occurrence = _nextRecurringOccurrence(recurring, DateTime.now());
    if (occurrence == null) {
      return null;
    }

    final snoozedUntil = recurring.snoozedUntil == null ||
            recurring.snoozedUntil!.isEmpty
        ? null
        : DateTime.tryParse(recurring.snoozedUntil!);
    final reminderAt = _notificationMoment(recurring, occurrence);
    final now = DateTime.now();
    if (snoozedUntil != null && now.isBefore(snoozedUntil)) {
      return _ExpensePendingMeta(
        pending: false,
        status: 'مؤجل حتى ${DateFormat('d/M HH:mm', 'ar').format(snoozedUntil)}',
        occurrence: occurrence,
      );
    }
    if (now.isBefore(reminderAt)) {
      return null;
    }

    return _ExpensePendingMeta(
      pending: true,
      status: now.isBefore(occurrence)
          ? 'مستحق قريبًا • ${DateFormat('d/M HH:mm', 'ar').format(occurrence)}'
          : 'مستحق الآن • ${DateFormat('d/M HH:mm', 'ar').format(occurrence)}',
      occurrence: occurrence,
    );
  }

  DateTime _incomeDueDateForMonth(IncomeSourceEntity source, DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final day = source.date.clamp(1, lastDay);
    return DateTime(month.year, month.month, day);
  }

  DateTime _notificationMoment(
    RecurringTransactionEntity recurring,
    DateTime occurrence,
  ) {
    final lead = recurring.reminderLeadDays ?? 0;
    if (recurring.recurrencePattern == 'daily' ||
        recurring.recurrencePattern == 'weekly' ||
        recurring.recurrencePattern == 'biweekly' ||
        recurring.recurrencePattern == 'every_3_weeks') {
      return occurrence.subtract(Duration(hours: lead));
    }
    return occurrence.subtract(Duration(days: lead));
  }

  DateTime? _parseRecurringTime(String? value) {
    if (value == null || value.isEmpty || !value.contains(':')) {
      return null;
    }
    final parts = value.split(':');
    if (parts.length != 2) {
      return null;
    }
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) {
      return null;
    }
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day, hour, minute);
  }

  DateTime? _nextRecurringOccurrence(
    RecurringTransactionEntity recurring,
    DateTime now,
  ) {
    final time = _parseRecurringTime(recurring.scheduledTime) ?? now;
    DateTime atDate(DateTime day) =>
        DateTime(day.year, day.month, day.day, time.hour, time.minute);

    if (recurring.recurrencePattern == 'daily') {
      final today = atDate(now);
      return today.isAfter(now) ? today : today.add(const Duration(days: 1));
    }
    if (recurring.weekdays.isNotEmpty) {
      for (var offset = 0; offset <= 21; offset++) {
        final day = now.add(Duration(days: offset));
        if (recurring.weekdays.contains(day.weekday)) {
          final candidate = atDate(day);
          if (candidate.isAfter(now)) {
            return candidate;
          }
        }
      }
    }

    final candidate = DateTime(
      now.year,
      now.month,
      recurring.dayOfMonth.clamp(1, 28),
      time.hour,
      time.minute,
    );
    if (candidate.isAfter(now)) {
      return candidate;
    }
    return DateTime(
      now.year,
      now.month + 1,
      recurring.dayOfMonth.clamp(1, 28),
      time.hour,
      time.minute,
    );
  }

  Future<void> _recordIncome(IncomeSourceEntity source, {bool early = false}) async {
    double amount = source.amount;
    if (source.isVariable || amount <= 0) {
      final amountController = TextEditingController();
      final ok = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('تسجيل دخل ${source.name}'),
          content: TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'المبلغ'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('تأكيد'),
            ),
          ],
        ),
      );
      if (ok != true) {
        return;
      }
      amount = double.tryParse(amountController.text.trim()) ?? 0;
      if (amount <= 0) {
        return;
      }
    }

    final now = DateTime.now();
    await widget.cubit.addTransaction(
      walletId: source.targetWalletId,
      amount: amount,
      type: 'income',
      incomeSourceId: source.id,
      budgetScope: 'within-budget',
      createdAt: DateTime(now.year, now.month, now.day, 12),
      notes: early
          ? 'تسجيل دخل مبكر: ${source.name}'
          : 'تأكيد نزول دخل: ${source.name}',
    );
  }

  Future<void> _postponeIncome(IncomeSourceEntity source, DateTime month) async {
    final dueDate = _incomeDueDateForMonth(source, month);
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate.add(const Duration(days: 1)),
      firstDate: dueDate.add(const Duration(days: 1)),
      lastDate: DateTime(month.year, month.month + 1, 28),
    );
    if (picked == null) {
      return;
    }

    final setup = widget.cubit.state.budgetSetup;
    final incomes = setup.incomeSources
        .map(
          (income) => income.id == source.id
              ? IncomeSourceEntity(
                  id: income.id,
                  name: income.name,
                  amount: income.amount,
                  date: picked.day,
                  type: income.type,
                  targetWalletId: income.targetWalletId,
                  isVariable: income.isVariable,
                  isDefault: income.isDefault,
                )
              : income,
        )
        .toList();
    await widget.cubit.updateBudgetSetup(setup.copyWith(incomeSources: incomes));
  }

  Future<void> _recordDebt(
    DebtEntity debt,
    RecurringTransactionEntity recurring,
    DateTime occurrence,
  ) async {
    await widget.cubit.addTransaction(
      walletId: recurring.walletId,
      amount: debt.amount,
      type: 'expense',
      budgetScope: 'within-budget',
      createdAt: DateTime.now(),
      notes: 'سداد دين: ${debt.name}',
    );
    await widget.cubit.updateRecurringTransaction(
      recurring.copyWith(
        lastHandledOccurrenceAt: occurrence.toIso8601String(),
        snoozedUntil: '',
      ),
    );
  }

  Future<void> _snoozeRecurringExpense(
    RecurringTransactionEntity recurring,
    DateTime occurrence,
  ) async {
    final now = DateTime.now();
    final delayed = now.add(const Duration(hours: 1));
    final nextSnooze = delayed.isAfter(occurrence) ? occurrence : delayed;
    await widget.cubit.updateRecurringTransaction(
      recurring.copyWith(snoozedUntil: nextSnooze.toIso8601String()),
    );
  }
}

class _IncomePendingMeta {
  const _IncomePendingMeta({
    required this.canEarly,
    required this.isDueOrLate,
    required this.status,
  });

  final bool canEarly;
  final bool isDueOrLate;
  final String status;
}

class _ExpensePendingMeta {
  const _ExpensePendingMeta({
    required this.pending,
    required this.status,
    required this.occurrence,
  });

  final bool pending;
  final String status;
  final DateTime occurrence;
}
