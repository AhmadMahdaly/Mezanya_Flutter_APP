import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_state/domain/entities/app_state_entity.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../domain/entities/budget_setup_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import 'budget_setup_screen.dart';

class BudgetTrackingScreen extends StatefulWidget {
  const BudgetTrackingScreen({super.key, required this.cubit});

  final AppCubit cubit;

  @override
  State<BudgetTrackingScreen> createState() => _BudgetTrackingScreenState();
}

class _BudgetTrackingScreenState extends State<BudgetTrackingScreen> {
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month, 1);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStateEntity>(
      stream: widget.cubit.stream,
      initialData: widget.cubit.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? widget.cubit.state;
        final budget = _budgetForMonth(state);
        final monthTx = _monthTransactions(state.transactions);
        final incomeTx = monthTx.where((t) => t.type == 'income').toList();
        final expenseTx = monthTx.where((t) => t.type == 'expense').toList();
        final totalIncomeActual = incomeTx.fold<double>(0, (s, t) => s + t.amount);
        final totalExpenseActual = expenseTx.fold<double>(0, (s, t) => s + t.amount);
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
                    Text('الباقي من الدخل الشهري', style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 8),
                    Text(
                      remainingIncome.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                            color: remainingIncome < 0 ? Colors.red : const Color(0xFF0F766E),
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(child: _miniStat('الدخل الكلي', totalIncomeActual)),
                        const SizedBox(width: 10),
                        Expanded(child: _miniStat('المصروف', totalExpenseActual)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            ExpansionTile(
              title: const Text('الدخل الكلي'),
              subtitle: Text(totalIncomeActual.toStringAsFixed(2)),
              children: _incomeTiles(state, budget, incomeTx),
            ),
            const SizedBox(height: 8),
            ...budget.allocations.map((allocation) => _allocationCard(state, allocation, monthTx)),
            const SizedBox(height: 8),
            ...budget.linkedWallets.map((jar) => _jarCard(state, jar, monthTx)),
            const SizedBox(height: 8),
            ExpansionTile(
              title: const Text('الديون الشهرية'),
              subtitle: Text(totalDebts.toStringAsFixed(2)),
              children: budget.debts.map((debt) => _debtTile(state, debt, monthTx)).toList(),
            ),
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
                          ? budget.unallocatedAmount.clamp(0, double.infinity).toDouble()
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
                      appBar: AppBar(title: const Text('تعديل خطة الميزانية')),
                      body: BudgetSetupScreen(cubit: widget.cubit),
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('تعديل خطة الميزانية'),
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
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1, 1)),
              icon: const Icon(Icons.chevron_right),
            ),
            Expanded(
              child: Center(
                child: Text(monthLabel, style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1, 1)),
              icon: const Icon(Icons.chevron_left),
            ),
          ],
        ),
      ),
    );
  }

  List<TransactionEntity> _monthTransactions(List<TransactionEntity> tx) {
    return tx
        .where((t) => t.createdAt.year == _month.year && t.createdAt.month == _month.month)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  BudgetSetupEntity _budgetForMonth(AppStateEntity state) {
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

  Widget _miniStat(String title, double value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, color: Colors.black54)),
          const SizedBox(height: 4),
          Text(value.toStringAsFixed(2), style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  List<Widget> _incomeTiles(
    AppStateEntity state,
    BudgetSetupEntity budget,
    List<TransactionEntity> incomeTx,
  ) {
    final out = <Widget>[];
    for (final source in budget.incomeSources) {
      final sourceTx = incomeTx.where((t) => t.incomeSourceId == source.id).toList();
      final expectedDate = DateTime(_month.year, _month.month, source.date.clamp(1, 28));
      final done = sourceTx.isNotEmpty;
      out.add(
        ListTile(
          title: Text(source.name),
          subtitle: Text(done ? 'تم تسجيل الدخل' : 'بانتظار التأكيد'),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(done ? Icons.check_circle : Icons.schedule,
                  color: done ? Colors.green : Colors.orange),
              const SizedBox(width: 8),
              Text(source.amount.toStringAsFixed(2)),
            ],
          ),
          onTap: () => _openTxSheet(title: source.name, tx: sourceTx),
        ),
      );
      if (!done && expectedDate.isAfter(DateTime.now()) && !source.isVariable) {
        out.add(
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () async {
                  await widget.cubit.addTransaction(
                    walletId: source.targetWalletId,
                    amount: source.amount,
                    type: 'income',
                    incomeSourceId: source.id,
                    notes: 'تأكيد وصول ${source.name} مبكرا',
                    createdAt: DateTime.now(),
                  );
                },
                icon: const Icon(Icons.flash_on, size: 16),
                label: const Text('تأكيد وصول الدخل الآن'),
              ),
            ),
          ),
        );
      }
    }
    out.addAll(
      incomeTx
          .where((t) => t.incomeSourceId == null)
          .map(
            (t) => ListTile(
              title: Text(t.notes?.isNotEmpty == true ? t.notes! : 'دخل إضافي'),
              subtitle: Text(DateFormat('d/M').format(t.createdAt)),
              trailing: Text(t.amount.toStringAsFixed(2)),
            ),
          )
          .toList(),
    );
    if (out.isEmpty) {
      out.add(const ListTile(title: Text('لا توجد معاملات دخل لهذا الشهر.')));
    }
    return out;
  }

  Widget _allocationCard(AppStateEntity state, AllocationEntity allocation, List<TransactionEntity> monthTx) {
    final planned = allocation.funding.fold<double>(0, (s, f) => s + f.plannedAmount);
    final spent = monthTx
        .where((t) => t.type == 'expense' && t.allocationId == allocation.id)
        .fold<double>(0, (s, t) => s + t.amount);
    final remaining = planned - spent;
    final ratio = planned <= 0 ? 0.0 : (spent / planned).clamp(0.0, 1.0);
    final color = ratio < 0.6
        ? const Color(0xFF16A34A)
        : ratio < 0.85
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          final tx = monthTx.where((t) => t.allocationId == allocation.id).toList();
          _openAllocationSheet(allocation, tx);
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(allocation.name, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              _row('المخصص', planned),
              _row('المتبقي', remaining, danger: remaining < 0),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: ratio,
                  minHeight: 9,
                  color: color,
                  backgroundColor: const Color(0xFFE2E8F0),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jarCard(AppStateEntity state, LinkedWalletEntity jar, List<TransactionEntity> monthTx) {
    final tx = monthTx.where((t) => t.walletId == jar.id || t.toWalletId == jar.id || t.fromWalletId == jar.id).toList();
    return Card(
      child: ListTile(
        title: Text(jar.name),
        subtitle: Text('المخصص شهريا: ${jar.monthlyAmount.toStringAsFixed(2)}'),
        trailing: Text(jar.balance.toStringAsFixed(2)),
        onTap: () => _openJarSheet(jar, tx),
      ),
    );
  }

  Widget _debtTile(AppStateEntity state, DebtEntity debt, List<TransactionEntity> monthTx) {
    final matched = monthTx.where((t) => t.notes?.contains(debt.name) == true).toList();
    return ListTile(
      title: Text(debt.name),
      subtitle: Text('اليوم ${debt.executionDay} - ${matched.isEmpty ? 'بانتظار' : 'تم الخصم'}'),
      trailing: Text(debt.amount.toStringAsFixed(2)),
      onTap: () => _openDebtSheet(debt, matched),
    );
  }

  Future<void> _openAllocationSheet(AllocationEntity allocation, List<TransactionEntity> tx) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.8,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(allocation.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            ...tx.map((item) => ListTile(
                  title: Text(item.notes?.isNotEmpty == true ? item.notes! : 'معاملة'),
                  subtitle: Text(DateFormat('d/M - h:mm a', 'ar').format(item.createdAt)),
                  trailing: Text(item.amount.toStringAsFixed(2)),
                )),
            if (tx.isEmpty) const ListTile(title: Text('لا توجد معاملات لهذا الشهر.')),
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
      text: allocation.funding.fold<double>(0, (s, f) => s + f.plannedAmount).toStringAsFixed(2),
    );
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تعديل المخصص'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم')),
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
              final updated = current.allocations.where((a) => a.id != allocation.id).toList();
              await widget.cubit.updateBudgetSetup(current.copyWith(allocations: updated));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حذف', style: TextStyle(color: Colors.red)),
          ),
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final current = widget.cubit.state.budgetSetup;
              final planned = double.tryParse(amountController.text.trim()) ?? 0;
              final list = current.allocations
                  .map(
                    (a) => a.id == allocation.id
                        ? AllocationEntity(
                            id: a.id,
                            name: nameController.text.trim().isEmpty ? a.name : nameController.text.trim(),
                            rolloverBehavior: a.rolloverBehavior,
                            funding: [
                              AllocationFundingEntity(
                                id: a.funding.isNotEmpty ? a.funding.first.id : 'fund-${DateTime.now().millisecondsSinceEpoch}',
                                incomeSourceId: a.funding.isNotEmpty ? a.funding.first.incomeSourceId : '',
                                plannedAmount: planned,
                              )
                            ],
                            categories: a.categories,
                          )
                        : a,
                  )
                  .toList();
              await widget.cubit.updateBudgetSetup(current.copyWith(allocations: list));
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _openJarSheet(LinkedWalletEntity jar, List<TransactionEntity> tx) async {
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
                  title: Text(item.notes?.isNotEmpty == true ? item.notes! : 'معاملة'),
                  subtitle: Text(DateFormat('d/M - h:mm a', 'ar').format(item.createdAt)),
                  trailing: Text(item.amount.toStringAsFixed(2)),
                )),
            if (tx.isEmpty) const ListTile(title: Text('لا توجد معاملات لهذا الشهر.')),
          ],
        ),
      ),
    );
  }

  Future<void> _openDebtSheet(DebtEntity debt, List<TransactionEntity> tx) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(debt.name, style: Theme.of(context).textTheme.titleLarge),
            _row('قيمة الدين', debt.amount),
            _row('يوم الاستحقاق', debt.executionDay.toDouble()),
            _row('عدد المعاملات المسجلة', tx.length.toDouble()),
            const SizedBox(height: 8),
            ...tx.map((item) => ListTile(
                  title: Text(item.notes?.isNotEmpty == true ? item.notes! : 'معاملة'),
                  subtitle: Text(DateFormat('d/M - h:mm a', 'ar').format(item.createdAt)),
                  trailing: Text(item.amount.toStringAsFixed(2)),
                )),
            if (tx.isEmpty) const ListTile(title: Text('لا توجد معاملات لهذا الدين في هذا الشهر.')),
          ],
        ),
      ),
    );
  }

  Future<void> _openTxSheet({required String title, required List<TransactionEntity> tx}) async {
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
                  title: Text(item.notes?.isNotEmpty == true ? item.notes! : 'معاملة'),
                  subtitle: Text(DateFormat('d/M - h:mm a', 'ar').format(item.createdAt)),
                  trailing: Text(item.amount.toStringAsFixed(2)),
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
              color: danger ? Colors.red : null,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
