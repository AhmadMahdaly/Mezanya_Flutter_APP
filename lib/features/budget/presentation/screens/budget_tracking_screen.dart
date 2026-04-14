import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_state/domain/entities/app_state_entity.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/widgets/transaction_details_sheet.dart';
import '../../domain/entities/budget_setup_entity.dart';
import 'budget_setup_screen.dart';

class BudgetTrackingScreen extends StatefulWidget {
  const BudgetTrackingScreen({super.key, required this.cubit});

  final AppCubit cubit;

  @override
  State<BudgetTrackingScreen> createState() => _BudgetTrackingScreenState();
}

class _BudgetTrackingScreenState extends State<BudgetTrackingScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);
  bool _isIncomeExpanded = false;
  bool _isDebtExpanded = false;
  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStateEntity>(
      stream: widget.cubit.stream,
      initialData: widget.cubit.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? widget.cubit.state;
        final budget = _budgetForMonth(state);
        final futureMonth = _isFutureMonth();
        final budgetJars = budget.linkedWallets
            .where((jar) => jar.funding.any((f) => f.plannedAmount > 0))
            .toList();
        final monthTx = _monthTransactions(state.transactions);
        final incomeTx = monthTx.where((t) => t.type == 'income').toList();
        final expenseTx = monthTx.where((t) => t.type == 'expense').toList();
        final totalIncomeActual =
            incomeTx.fold<double>(0, (s, t) => s + t.amount);
        final totalExpenseActual =
            expenseTx.fold<double>(0, (s, t) => s + t.amount);
        final remainingIncome = totalIncomeActual - totalExpenseActual;
        final totalDebts = budget.debts.fold<double>(0, (s, d) => s + d.amount);

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _monthBar(context),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('الباقي من الدخل الشهري',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      remainingIncome.toStringAsFixed(2),
                      style:
                          Theme.of(context).textTheme.headlineSmall?.copyWith(
                                color: remainingIncome < 0
                                    ? Theme.of(context).colorScheme.error
                                    : Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                            child: _miniStat(
                                context, 'الدخل الكلي', totalIncomeActual)),
                        const SizedBox(width: 10),
                        Expanded(
                            child: _miniStat(
                                context, 'المصروف', totalExpenseActual)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _inlineSectionCard(
              title: 'الدخل الكلي',
              subtitle: 'عرض كل مصادر الدخل لهذا الشهر',
              amount: totalIncomeActual,
              isExpanded: _isIncomeExpanded,
              onTap: () =>
                  setState(() => _isIncomeExpanded = !_isIncomeExpanded),
            ),
            if (_isIncomeExpanded) ...[
              const SizedBox(height: 8),
              _sectionCurtainBody(
                  children: _incomeInlineCards(state, budget, incomeTx)),
            ],
            const SizedBox(height: 8),
            ...budget.allocations.map(
                (allocation) => _allocationCard(state, allocation, monthTx)),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'الحصالات',
                      style:
                          TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'الحصالات التي تتلقى تمويلًا شهريًا من الدخل',
                      style: TextStyle(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurface
                            .withValues(alpha: 0.7),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            if (budgetJars.isEmpty)
              const Card(
                child: ListTile(
                  title: Text('لا توجد حصالات ممولة شهريًا في هذا الشهر.'),
                ),
              )
            else
              ...budgetJars.map((jar) => _jarCard(state, jar, monthTx)),
            const SizedBox(height: 8),
            _inlineSectionCard(
              title: 'الديون الشهرية',
              subtitle: 'عرض كل الديون واستحقاقاتها',
              amount: totalDebts,
              isExpanded: _isDebtExpanded,
              onTap: () => setState(() => _isDebtExpanded = !_isDebtExpanded),
            ),
            if (_isDebtExpanded) ...[
              const SizedBox(height: 8),
              _sectionCurtainBody(
                  children: _debtInlineCards(state, budget, monthTx)),
            ],
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _row('المبلغ غير المخصص', budget.unallocatedAmount),
                    _row(
                      'المتوقع التوفير',
                      budget.bufferEndBehavior == 'to-savings'
                          ? budget.unallocatedAmount
                              .clamp(0, double.infinity)
                              .toDouble()
                          : 0,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => Scaffold(
                      appBar: AppBar(
                        title: Text(futureMonth
                            ? 'إعداد خطة الشهر القادم'
                            : 'تعديل خطة الميزانية'),
                      ),
                      body: BudgetSetupScreen(cubit: widget.cubit),
                    ),
                  ),
                );
              },
              icon: Icon(
                  futureMonth ? Icons.add_task_outlined : Icons.edit_outlined),
              label: Text(
                  futureMonth ? 'إعداد خطة الميزانية' : 'تعديل خطة الميزانية'),
            ),
          ],
        );
      },
    );
  }

  Widget _monthBar(BuildContext context) {
    final monthLabel = DateFormat('MMMM yyyy', 'ar').format(_month);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          children: [
            IconButton(
              onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month - 1, 1)),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Center(
                child: Text(monthLabel,
                    style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            IconButton(
              onPressed: () => setState(
                  () => _month = DateTime(_month.year, _month.month + 1, 1)),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionEntity> _monthTransactions(List<TransactionEntity> tx) {
    return tx
        .where((t) =>
            t.createdAt.year == _month.year &&
            t.createdAt.month == _month.month &&
            !_isJarReserveTx(t))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  BudgetSetupEntity _budgetForMonth(AppStateEntity state) {
    final monthKey =
        '${_month.year}-${_month.month.toString().padLeft(2, '0')}';
    final snapshot = state.monthlyBudgetSnapshots[monthKey];
    if (snapshot != null && snapshot.isNotEmpty) {
      return BudgetSetupEntity.fromMap(snapshot);
    }
    final now = DateTime.now();
    final isCurrent = _month.year == now.year && _month.month == now.month;
    if (isCurrent) {
      return state.budgetSetup;
    }
    final end = DateTime(_month.year, _month.month + 1, 0, 23, 59, 59);
    for (final log in state.logs) {
      if (log.timestamp.isAfter(end)) {
        continue;
      }
      try {
        final map = jsonDecode(log.afterState) as Map<String, dynamic>;
        return AppStateEntity.fromMap(map).budgetSetup;
      } catch (_) {
        continue;
      }
    }
    return state.budgetSetup;
  }

  bool _isFutureMonth() {
    final now = DateTime.now();
    final current = DateTime(now.year, now.month, 1);
    return _month.isAfter(current);
  }

  Widget _miniStat(BuildContext context, String title, double value) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: theme.colorScheme.onSurface.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
          const SizedBox(height: 4),
          Text(value.toStringAsFixed(2),
              style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _inlineSectionCard({
    required String title,
    required String subtitle,
    required double amount,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Card(
      child: ListTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(amount.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.w700)),
            Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
            ),
          ],
        ),
        onTap: onTap,
      ),
    );
  }

  Widget _sectionCurtainBody({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(children: children),
    );
  }

  List<Widget> _incomeInlineCards(
    AppStateEntity state,
    BudgetSetupEntity budget,
    List<TransactionEntity> incomeTx,
  ) {
    return [
      ...budget.incomeSources.map((source) {
        final sourceTx =
            incomeTx.where((t) => t.incomeSourceId == source.id).toList();
        final received = sourceTx.fold<double>(0, (s, t) => s + t.amount);
        final planned =
            source.isVariable ? (received <= 0 ? 1 : received) : source.amount;
        final committed = _committedForIncomeSource(budget, source.id);
        final remaining = received - committed;
        final progressBase = (received <= 0 ? planned : received) <= 0
            ? 1.0
            : (remaining / (received <= 0 ? planned : received));
        final progress = progressBase.clamp(0.0, 1.0);
        final dueDate = _incomeDueDateForMonth(source, _month);
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final earlyFrom = dueDate.subtract(const Duration(days: 3));
        final canEarly = !source.isVariable &&
            sourceTx.isEmpty &&
            today.isAfter(earlyFrom.subtract(const Duration(days: 1))) &&
            today.isBefore(dueDate);
        final isDueOrLate =
            !source.isVariable && sourceTx.isEmpty && !today.isBefore(dueDate);
        final isCurrentMonth =
            _month.year == now.year && _month.month == now.month;
        return Card(
          child: ListTile(
            title: Text(source.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('المتبقي: ${remaining.toStringAsFixed(2)}'),
                if (!source.isVariable)
                  Text('الاستحقاق: ${dueDate.day}/${dueDate.month}'),
                if (sourceTx.isEmpty && !source.isVariable)
                  Text(
                    isDueOrLate ? 'الدخل معلّق' : 'لم ينزل بعد',
                    style: TextStyle(
                      color: isDueOrLate
                          ? Theme.of(context).colorScheme.error
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withValues(alpha: 0.65),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: remaining < 0
                        ? Theme.of(context).colorScheme.error
                        : Colors.green,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.12),
                  ),
                ),
                if (isCurrentMonth &&
                    (canEarly || isDueOrLate || source.type == 'manual') &&
                    !source.isVariable) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      if (canEarly)
                        OutlinedButton.icon(
                          onPressed: () =>
                              _recordIncomeFromTracking(source, early: true),
                          icon: const Icon(Icons.trending_up, size: 16),
                          label: const Text('نزل بدري'),
                        ),
                      if (isDueOrLate)
                        FilledButton.icon(
                          onPressed: () => _recordIncomeFromTracking(source),
                          icon:
                              const Icon(Icons.check_circle_outline, size: 16),
                          label: const Text('تأكيد نزول الدخل'),
                        ),
                      if (isDueOrLate)
                        OutlinedButton.icon(
                          onPressed: () => _postponeIncome(source),
                          icon: const Icon(Icons.event_repeat, size: 16),
                          label: const Text('تأجيل'),
                        ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: Text(
                (received <= 0 ? source.amount : received).toStringAsFixed(2)),
            onTap: () => _openIncomeDetailsSheet(source, sourceTx, remaining),
          ),
        );
      }),
      ...incomeTx.where((t) => t.incomeSourceId == null).map(
            (t) => Card(
              child: ListTile(
                title:
                    Text(t.notes?.isNotEmpty == true ? t.notes! : 'دخل إضافي'),
                subtitle:
                    Text(DateFormat('d/M - h:mm a', 'ar').format(t.createdAt)),
                trailing: Text(t.amount.toStringAsFixed(2)),
                onTap: () => _openTxSheet(title: 'دخل إضافي', tx: [t]),
              ),
            ),
          ),
    ];
  }

  Widget _allocationCard(AppStateEntity state, AllocationEntity allocation,
      List<TransactionEntity> monthTx) {
    final planned =
        allocation.funding.fold<double>(0, (s, f) => s + f.plannedAmount);
    final funded = allocation.funding.fold<double>(0, (sum, f) {
      final incomeReceived = monthTx
          .where(
              (t) => t.type == 'income' && t.incomeSourceId == f.incomeSourceId)
          .fold<double>(0, (s, t) => s + t.amount);
      return sum +
          (incomeReceived <= f.plannedAmount
              ? incomeReceived
              : f.plannedAmount);
    });
    final spent = monthTx
        .where((t) => t.type == 'expense' && t.allocationId == allocation.id)
        .fold<double>(0, (s, t) => s + t.amount);
    final remaining = funded - spent;
    final ratio = funded <= 0 ? 0.0 : (spent / funded).clamp(0.0, 1.0);
    final color = ratio < 0.6
        ? Theme.of(context).colorScheme.primary
        : ratio < 0.85
            ? Colors.orange
            : Theme.of(context).colorScheme.error;

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          final tx =
              monthTx.where((t) => t.allocationId == allocation.id).toList();
          _openAllocationSheet(allocation, tx);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(allocation.name,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _row('المخطط', planned),
              _row('المتاح بعد نزول الدخل', funded),
              _row('المتبقي', remaining, danger: remaining < 0),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 9,
                  color: color,
                  backgroundColor: Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jarCard(AppStateEntity state, LinkedWalletEntity jar,
      List<TransactionEntity> monthTx) {
    final tx = monthTx
        .where((t) =>
            t.walletId == jar.id ||
            t.toWalletId == jar.id ||
            t.fromWalletId == jar.id)
        .toList();
    return Card(
      child: ListTile(
        title: Text(jar.name),
        subtitle: Text('المخصص شهريا: ${jar.monthlyAmount.toStringAsFixed(2)}'),
        trailing: Text(jar.balance.toStringAsFixed(2)),
        onTap: () => _openJarSheet(jar, tx),
      ),
    );
  }

  List<Widget> _debtInlineCards(
    AppStateEntity state,
    BudgetSetupEntity budget,
    List<TransactionEntity> monthTx,
  ) {
    return [
      ...budget.debts.map((debt) {
        final tx =
            monthTx.where((t) => t.notes?.contains(debt.name) == true).toList();
        final paid = tx.fold<double>(0, (s, t) => s + t.amount);
        final remaining = (debt.amount - paid).clamp(0.0, debt.amount);
        final progress =
            debt.amount <= 0 ? 0.0 : (remaining / debt.amount).clamp(0.0, 1.0);
        return Card(
          child: ListTile(
            title: Text(debt.name),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'المتبقي: ${remaining.toStringAsFixed(2)} - يوم ${debt.executionDay}'),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    color: Colors.green,
                    backgroundColor: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.12),
                  ),
                ),
              ],
            ),
            trailing: Text(debt.amount.toStringAsFixed(2)),
            onTap: () => _openDebtDetailsSheet(debt, tx, remaining),
          ),
        );
      }),
      if (budget.debts.isEmpty)
        Card(
          child: ListTile(
            title: const Text('لا توجد ديون لهذا الشهر.'),
            subtitle: const Text('تقدر تضيف دين جديد مباشرة.'),
            trailing: FilledButton.icon(
              onPressed: _addDebtDirect,
              icon: const Icon(Icons.add),
              label: const Text('إضافة دين'),
            ),
          ),
        ),
    ];
  }

  Future<void> _openAllocationSheet(
      AllocationEntity allocation, List<TransactionEntity> tx) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(allocation.name,
                style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...tx.map((item) => ListTile(
                  title: Text(
                      item.notes?.isNotEmpty == true ? item.notes! : 'معاملة'),
                  subtitle: Text(
                      DateFormat('d/M - h:mm a', 'ar').format(item.createdAt)),
                  trailing: Text(item.amount.toStringAsFixed(2)),
                  onTap: () => openTransactionDetailsSheet(
                    context,
                    cubit: widget.cubit,
                    transaction: item,
                  ),
                )),
            if (tx.isEmpty)
              const ListTile(title: Text('لا توجد معاملات لهذا الشهر.')),
            const SizedBox(height: 8),
            OutlinedButton.icon(
              onPressed: () => _editAllocation(allocation),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('تعديل المخصص'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editAllocation(AllocationEntity allocation) async {
    final nameController = TextEditingController(text: allocation.name);
    final amountController = TextEditingController(
      text: allocation.funding
          .fold<double>(0, (s, f) => s + f.plannedAmount)
          .toStringAsFixed(2),
    );
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المخصص'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'الاسم')),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () async {
              final current = widget.cubit.state.budgetSetup;
              final updated = current.allocations
                  .where((a) => a.id != allocation.id)
                  .toList();
              await widget.cubit
                  .updateBudgetSetup(current.copyWith(allocations: updated));
              if (context.mounted) Navigator.pop(context);
            },
            child: Text('حذف',
                style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final current = widget.cubit.state.budgetSetup;
              final planned =
                  double.tryParse(amountController.text.trim()) ?? 0;
              final list = current.allocations
                  .map(
                    (a) => a.id == allocation.id
                        ? AllocationEntity(
                            id: a.id,
                            name: nameController.text.trim().isEmpty
                                ? a.name
                                : nameController.text.trim(),
                            rolloverBehavior: a.rolloverBehavior,
                            funding: [
                              AllocationFundingEntity(
                                id: a.funding.isNotEmpty
                                    ? a.funding.first.id
                                    : 'fund-${DateTime.now().millisecondsSinceEpoch}',
                                incomeSourceId: a.funding.isNotEmpty
                                    ? a.funding.first.incomeSourceId
                                    : '',
                                plannedAmount: planned,
                              )
                            ],
                            categories: a.categories,
                          )
                        : a,
                  )
                  .toList();
              await widget.cubit
                  .updateBudgetSetup(current.copyWith(allocations: list));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _openJarSheet(
      LinkedWalletEntity jar, List<TransactionEntity> tx) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(jar.name, style: Theme.of(context).textTheme.titleLarge),
            _row('الرصيد الحالي', jar.balance),
            _row('المخصص الشهري', jar.monthlyAmount),
            const SizedBox(height: 8),
            ...tx.map((item) => ListTile(
                  title: Text(
                      item.notes?.isNotEmpty == true ? item.notes! : 'معاملة'),
                  subtitle: Text(
                      DateFormat('d/M - h:mm a', 'ar').format(item.createdAt)),
                  trailing: Text(item.amount.toStringAsFixed(2)),
                  onTap: () => openTransactionDetailsSheet(
                    context,
                    cubit: widget.cubit,
                    transaction: item,
                  ),
                )),
            if (tx.isEmpty)
              const ListTile(title: Text('لا توجد معاملات لهذا الشهر.')),
          ],
        ),
      ),
    );
  }

  Future<void> _openIncomeDetailsSheet(
    IncomeSourceEntity source,
    List<TransactionEntity> tx,
    double remaining,
  ) async {
    final dueDate = _incomeDueDateForMonth(source, _month);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final earlyFrom = dueDate.subtract(const Duration(days: 3));
    final canEarly = !source.isVariable &&
        tx.isEmpty &&
        today.isAfter(earlyFrom.subtract(const Duration(days: 1))) &&
        today.isBefore(dueDate);
    final isDueOrLate =
        !source.isVariable && tx.isEmpty && !today.isBefore(dueDate);
    final isCurrentMonth = _month.year == now.year && _month.month == now.month;

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.68,
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(source.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      _row('تاريخ الاستحقاق', source.date.toDouble()),
                      _row('المبلغ المخطط', source.amount),
                      _row('المتبقي', remaining),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...tx.map((item) => Card(
                    child: ListTile(
                      title: Text(item.notes?.isNotEmpty == true
                          ? item.notes!
                          : 'معاملة دخل'),
                      subtitle: Text(DateFormat('d/M - h:mm a', 'ar')
                          .format(item.createdAt)),
                      trailing: Text(item.amount.toStringAsFixed(2)),
                      onTap: () => openTransactionDetailsSheet(
                        context,
                        cubit: widget.cubit,
                        transaction: item,
                      ),
                    ),
                  )),
              if (tx.isEmpty)
                const Card(
                    child: ListTile(
                        title: Text('لا توجد معاملات مسجلة لهذا الدخل.'))),
              if (isCurrentMonth &&
                  (canEarly || isDueOrLate || source.type == 'manual') &&
                  !source.isVariable) ...[
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        if (canEarly)
                          OutlinedButton.icon(
                            onPressed: () =>
                                _recordIncomeFromTracking(source, early: true),
                            icon: const Icon(Icons.trending_up, size: 16),
                            label: const Text('نزل بدري'),
                          ),
                        if (isDueOrLate)
                          FilledButton.icon(
                            onPressed: () => _recordIncomeFromTracking(source),
                            icon: const Icon(Icons.check_circle_outline,
                                size: 16),
                            label: const Text('تأكيد نزول الدخل'),
                          ),
                        if (isDueOrLate)
                          OutlinedButton.icon(
                            onPressed: () => _postponeIncome(source),
                            icon: const Icon(Icons.event_repeat, size: 16),
                            label: const Text('تأجيل'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              Center(
                child: FilledButton.icon(
                  onPressed: () => _editIncomeDirect(source),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل الدخل'),
                ),
              ),
            ],
          )),
    );
  }

  Future<void> _openDebtDetailsSheet(
    DebtEntity debt,
    List<TransactionEntity> tx,
    double remaining,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.68,
          child: ListView(
            padding: const EdgeInsets.all(14),
            children: [
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(debt.name,
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 8),
                      _row('تاريخ الاستحقاق', debt.executionDay.toDouble()),
                      _row('قيمة الدين', debt.amount),
                      _row('المتبقي', remaining),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ...tx.map((item) => Card(
                    child: ListTile(
                      title: Text(item.notes?.isNotEmpty == true
                          ? item.notes!
                          : 'معاملة دين'),
                      subtitle: Text(DateFormat('d/M - h:mm a', 'ar')
                          .format(item.createdAt)),
                      trailing: Text(item.amount.toStringAsFixed(2)),
                      onTap: () => openTransactionDetailsSheet(
                        context,
                        cubit: widget.cubit,
                        transaction: item,
                      ),
                    ),
                  )),
              if (tx.isEmpty)
                const Card(
                    child: ListTile(
                        title: Text('لا توجد معاملات سداد حتى الآن.'))),
              const SizedBox(height: 14),
              Center(
                child: FilledButton.icon(
                  onPressed: () => _editDebtDirect(debt),
                  icon: const Icon(Icons.edit_outlined),
                  label: const Text('تعديل الدين'),
                ),
              ),
            ],
          )),
    );
  }

  Future<void> _editIncomeDirect(IncomeSourceEntity current) async {
    final wallets = widget.cubit.state.wallets;
    final nameController = TextEditingController(text: current.name);
    final amountController =
        TextEditingController(text: current.amount.toStringAsFixed(0));
    final dayController = TextEditingController(text: current.date.toString());
    var isVariable = current.isVariable;
    var type = current.type;
    var walletId = current.targetWalletId;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل الدخل'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'الاسم')),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: isVariable ? 'variable' : 'fixed',
                  decoration: const InputDecoration(labelText: 'طبيعة الدخل'),
                  items: const [
                    DropdownMenuItem(value: 'fixed', child: Text('ثابت')),
                    DropdownMenuItem(
                        value: 'variable', child: Text('غير ثابت')),
                  ],
                  onChanged: (v) => setDialogState(() {
                    isVariable = v == 'variable';
                    if (isVariable) type = 'manual';
                  }),
                ),
                if (!isVariable) ...[
                  const SizedBox(height: 8),
                  TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'القيمة')),
                  const SizedBox(height: 8),
                  TextField(
                      controller: dayController,
                      keyboardType: TextInputType.number,
                      decoration:
                          const InputDecoration(labelText: 'يوم الاستحقاق')),
                ],
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: walletId,
                  decoration:
                      const InputDecoration(labelText: 'المحفظة المستهدفة'),
                  items: wallets
                      .map((w) =>
                          DropdownMenuItem(value: w.id, child: Text(w.name)))
                      .toList(),
                  onChanged: (v) =>
                      setDialogState(() => walletId = v ?? walletId),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                final day =
                    (int.tryParse(dayController.text.trim()) ?? current.date)
                        .clamp(1, 31);
                if (name.isEmpty) return;
                final updated = IncomeSourceEntity(
                  id: current.id,
                  name: name,
                  amount: isVariable ? 0 : amount,
                  date: day,
                  type: isVariable ? 'manual' : type,
                  targetWalletId: walletId,
                  isVariable: isVariable,
                  isDefault: current.isDefault,
                );
                final setup = widget.cubit.state.budgetSetup;
                final incomes = setup.incomeSources
                    .map((e) => e.id == current.id ? updated : e)
                    .toList();
                await widget.cubit
                    .updateBudgetSetup(setup.copyWith(incomeSources: incomes));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _editDebtDirect(DebtEntity current) async {
    final setup = widget.cubit.state.budgetSetup;
    final nameController = TextEditingController(text: current.name);
    final amountController =
        TextEditingController(text: current.amount.toStringAsFixed(0));
    final dayController =
        TextEditingController(text: current.executionDay.toString());
    var type = current.type;
    var fundingSource = current.fundingSource;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تعديل الدين'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'الاسم')),
              const SizedBox(height: 8),
              TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'القيمة')),
              const SizedBox(height: 8),
              TextField(
                  controller: dayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'يوم التنفيذ')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('تلقائي')),
                  DropdownMenuItem(value: 'confirm', child: Text('تأكيد')),
                  DropdownMenuItem(value: 'manual', child: Text('يدوي')),
                ],
                onChanged: (v) => setDialogState(() => type = v ?? type),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: fundingSource,
                items: setup.incomeSources
                    .map((s) =>
                        DropdownMenuItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => fundingSource = v ?? fundingSource),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            TextButton(
              onPressed: () async {
                final next =
                    setup.debts.where((d) => d.id != current.id).toList();
                await widget.cubit
                    .updateBudgetSetup(setup.copyWith(debts: next));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حذف', style: TextStyle(color: Colors.red)),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                final day = (int.tryParse(dayController.text.trim()) ??
                        current.executionDay)
                    .clamp(1, 31);
                if (name.isEmpty || amount <= 0) return;
                final updated = DebtEntity(
                  id: current.id,
                  name: name,
                  amount: amount,
                  executionDay: day,
                  type: type,
                  fundingSource: fundingSource,
                );
                final next = setup.debts
                    .map((d) => d.id == current.id ? updated : d)
                    .toList();
                await widget.cubit
                    .updateBudgetSetup(setup.copyWith(debts: next));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _addDebtDirect() async {
    final setup = widget.cubit.state.budgetSetup;
    if (setup.incomeSources.isEmpty) {
      return;
    }
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final dayController = TextEditingController(text: '1');
    var type = 'confirm';
    var fundingSource = setup.incomeSources.first.id;
    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('إضافة دين'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'الاسم')),
              const SizedBox(height: 8),
              TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'القيمة')),
              const SizedBox(height: 8),
              TextField(
                  controller: dayController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'يوم التنفيذ')),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('تلقائي')),
                  DropdownMenuItem(value: 'confirm', child: Text('تأكيد')),
                  DropdownMenuItem(value: 'manual', child: Text('يدوي')),
                ],
                onChanged: (v) => setDialogState(() => type = v ?? type),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: fundingSource,
                items: setup.incomeSources
                    .map((s) =>
                        DropdownMenuItem(value: s.id, child: Text(s.name)))
                    .toList(),
                onChanged: (v) =>
                    setDialogState(() => fundingSource = v ?? fundingSource),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                final day =
                    (int.tryParse(dayController.text.trim()) ?? 1).clamp(1, 31);
                if (name.isEmpty || amount <= 0) return;
                final debt = DebtEntity(
                  id: _id('debt'),
                  name: name,
                  amount: amount,
                  executionDay: day,
                  type: type,
                  fundingSource: fundingSource,
                );
                await widget.cubit.updateBudgetSetup(
                    setup.copyWith(debts: [...setup.debts, debt]));
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('إضافة'),
            ),
          ],
        ),
      ),
    );
  }

  double _committedForIncomeSource(BudgetSetupEntity budget, String sourceId) {
    final alloc = budget.allocations.fold<double>(
      0,
      (sum, allocation) =>
          sum +
          allocation.funding
              .where((f) => f.incomeSourceId == sourceId)
              .fold<double>(0, (s, f) => s + f.plannedAmount),
    );
    final jars = budget.linkedWallets.fold<double>(
      0,
      (sum, jar) =>
          sum +
          jar.funding
              .where((f) => f.incomeSourceId == sourceId)
              .fold<double>(0, (s, f) => s + f.plannedAmount),
    );
    final debts = budget.debts
        .where((d) => d.fundingSource == sourceId)
        .fold<double>(0, (s, d) => s + d.amount);
    return alloc + jars + debts;
  }

  DateTime _incomeDueDateForMonth(IncomeSourceEntity source, DateTime month) {
    final lastDay = DateTime(month.year, month.month + 1, 0).day;
    final day = source.date.clamp(1, lastDay);
    return DateTime(month.year, month.month, day);
  }

  Future<void> _recordIncomeFromTracking(IncomeSourceEntity source,
      {bool early = false}) async {
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
                child: const Text('إلغاء')),
            FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('تأكيد')),
          ],
        ),
      );
      if (ok != true) return;
      amount = double.tryParse(amountController.text.trim()) ?? 0;
      if (amount <= 0) return;
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

  Future<void> _postponeIncome(IncomeSourceEntity source) async {
    final dueDate = _incomeDueDateForMonth(source, _month);
    final picked = await showDatePicker(
      context: context,
      initialDate: dueDate.add(const Duration(days: 1)),
      firstDate: dueDate.add(const Duration(days: 1)),
      lastDate: DateTime(_month.year, _month.month + 1, 28),
    );
    if (picked == null) return;
    final setup = widget.cubit.state.budgetSetup;
    final incomes = setup.incomeSources
        .map(
          (i) => i.id == source.id
              ? IncomeSourceEntity(
                  id: i.id,
                  name: i.name,
                  amount: i.amount,
                  date: picked.day,
                  type: i.type,
                  targetWalletId: i.targetWalletId,
                  isVariable: i.isVariable,
                  isDefault: i.isDefault,
                )
              : i,
        )
        .toList();
    await widget.cubit
        .updateBudgetSetup(setup.copyWith(incomeSources: incomes));
  }

  Future<void> _openTxSheet(
      {required String title, required List<TransactionEntity> tx}) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...tx.map((item) => ListTile(
                  title: Text(
                      item.notes?.isNotEmpty == true ? item.notes! : 'معاملة'),
                  subtitle: Text(
                      DateFormat('d/M - h:mm a', 'ar').format(item.createdAt)),
                  trailing: Text(item.amount.toStringAsFixed(2)),
                  onTap: () => openTransactionDetailsSheet(
                    context,
                    cubit: widget.cubit,
                    transaction: item,
                  ),
                )),
            if (tx.isEmpty) const ListTile(title: Text('لا توجد معاملات.')),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, double value, {bool danger = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value.toStringAsFixed(2),
            style: TextStyle(
              color: danger ? Theme.of(context).colorScheme.error : null,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  bool _isJarReserveTx(TransactionEntity t) {
    return t.transferType == 'jar-allocation' ||
        t.transferType == 'jar-allocation-cancel' ||
        t.transferType == 'jar-allocation-spend';
  }
}
