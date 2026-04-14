import 'package:flutter/material.dart';

import '../../../app_state/domain/entities/app_state_entity.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import 'add_transaction_screen.dart';
import '../../domain/entities/recurring_transaction_entity.dart';

class RecurringTransactionsScreen extends StatefulWidget {
  const RecurringTransactionsScreen({super.key, required this.cubit});

  final AppCubit cubit;

  @override
  State<RecurringTransactionsScreen> createState() => _RecurringTransactionsScreenState();
}

class _RecurringTransactionsScreenState extends State<RecurringTransactionsScreen> {
  String _tab = 'income';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStateEntity>(
      stream: widget.cubit.stream,
      initialData: widget.cubit.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? widget.cubit.state;
        final records = state.recurringTransactions.where((e) => e.type == _tab).toList();
        final inBudget = records.where((e) => e.budgetScope == 'within-budget').toList();
        final outBudget = records.where((e) => e.budgetScope != 'within-budget').toList();

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('الدخل'),
                      selected: _tab == 'income',
                      onSelected: (_) => setState(() => _tab = 'income'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('المصروف'),
                      selected: _tab == 'expense',
                      onSelected: (_) => setState(() => _tab = 'expense'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => _openRecurringComposer(mode: _tab),
                icon: const Icon(Icons.add),
                label: Text(_tab == 'income' ? 'إضافة دخل' : 'إضافة مصروف'),
              ),
            ),
            const SizedBox(height: 12),
            _sectionTitle('معاملات متكررة بالميزانية'),
            const SizedBox(height: 8),
            ..._recurringCards(inBudget),
            if (inBudget.isEmpty)
              const Card(child: ListTile(title: Text('لا توجد معاملات في هذا القسم.'))),
            const SizedBox(height: 12),
            _sectionTitle('معاملات خارج الميزانية'),
            const SizedBox(height: 8),
            ..._recurringCards(outBudget),
            if (outBudget.isEmpty)
              const Card(child: ListTile(title: Text('لا توجد معاملات في هذا القسم.'))),
          ],
        );
      },
    );
  }

  Widget _sectionTitle(String title) {
    return Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16));
  }

  List<Widget> _recurringCards(List<RecurringTransactionEntity> records) {
    return records
        .map(
          (record) => Card(
            child: ListTile(
              title: Text(record.name),
              subtitle: Text(
                '${_recurrenceLabel(record)} - ${record.executionType == 'auto' ? 'تلقائي' : record.executionType == 'confirm' ? 'تأكيد' : 'يدوي'}',
              ),
              trailing: Text(record.amount.toStringAsFixed(2)),
              onTap: () => _openDetailsSheet(record),
            ),
          ),
        )
        .toList();
  }

  Future<void> _openDetailsSheet(RecurringTransactionEntity record) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(record.name, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            _row('النوع', record.type == 'income' ? 'دخل' : 'مصروف'),
            _row('المبلغ', record.amount.toStringAsFixed(2)),
            _row('التاريخ الدوري', 'يوم ${record.dayOfMonth} من كل شهر'),
            _row(
              'التنفيذ',
              record.executionType == 'auto'
                  ? 'تلقائي'
                  : record.executionType == 'confirm'
                      ? 'يتطلب تأكيد'
                      : 'يدوي',
            ),
            _row('الميزانية', record.budgetScope == 'within-budget' ? 'داخل الميزانية' : 'خارج الميزانية'),
            if ((record.notes ?? '').trim().isNotEmpty) _row('ملاحظات', record.notes!.trim()),
            const SizedBox(height: 16),
            Center(
              child: FilledButton.icon(
                onPressed: () => _openRecurringComposer(mode: record.type, editing: record),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('تعديل المعاملة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: const TextStyle(fontWeight: FontWeight.w600))],
      ),
    );
  }

  String _recurrenceLabel(RecurringTransactionEntity record) {
    switch (record.recurrencePattern) {
      case 'weekly':
        return 'كل أسبوع (${_weekdayName(record.weekday)})';
      case 'biweekly':
        return 'كل أسبوعين (${_weekdayName(record.weekday)})';
      case 'every_2_months':
        return 'كل شهرين يوم ${record.dayOfMonth}';
      case 'every_3_months':
        return 'كل 3 شهور يوم ${record.dayOfMonth}';
      case 'every_6_months':
        return 'كل 6 شهور يوم ${record.dayOfMonth}';
      case 'yearly':
        return 'سنويًا يوم ${record.dayOfMonth}';
      default:
        return 'شهريًا يوم ${record.dayOfMonth}';
    }
  }

  String _weekdayName(int? day) {
    switch (day) {
      case 1:
        return 'الاثنين';
      case 2:
        return 'الثلاثاء';
      case 3:
        return 'الأربعاء';
      case 4:
        return 'الخميس';
      case 5:
        return 'الجمعة';
      case 6:
        return 'السبت';
      case 7:
        return 'الأحد';
      default:
        return 'غير محدد';
    }
  }

  Future<void> _openRecurringComposer({
    required String mode,
    RecurringTransactionEntity? editing,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => FractionallySizedBox(
        heightFactor: 0.96,
        child: AddTransactionScreen(
          cubit: widget.cubit,
          recurringMode: true,
          recurringType: mode,
          initialRecurring: editing,
        ),
      ),
    );
  }
}
