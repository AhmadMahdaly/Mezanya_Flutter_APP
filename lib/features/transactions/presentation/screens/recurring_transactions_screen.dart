import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon_picker_dialog.dart';
import '../../../app_state/domain/entities/app_state_entity.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import 'recurring_transaction_composer_screen.dart';
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
                      label: const Text('ط§ظ„ط¯ط®ظ„'),
                      selected: _tab == 'income',
                      onSelected: (_) => setState(() => _tab = 'income'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('ط§ظ„ظ…طµط±ظˆظپ'),
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
                label: Text(_tab == 'income' ? 'ط¥ط¶ط§ظپط© ط¯ط®ظ„' : 'ط¥ط¶ط§ظپط© ظ…طµط±ظˆظپ'),
              ),
            ),
            const SizedBox(height: 12),
            _sectionTitle('ظ…ط¹ط§ظ…ظ„ط§طھ ظ…طھظƒط±ط±ط© ط¨ط§ظ„ظ…ظٹط²ط§ظ†ظٹط©'),
            const SizedBox(height: 8),
            ..._recurringCards(inBudget),
            if (inBudget.isEmpty)
              const Card(child: ListTile(title: Text('ظ„ط§ طھظˆط¬ط¯ ظ…ط¹ط§ظ…ظ„ط§طھ ظپظٹ ظ‡ط°ط§ ط§ظ„ظ‚ط³ظ….'))),
            const SizedBox(height: 12),
            _sectionTitle('ظ…ط¹ط§ظ…ظ„ط§طھ ط®ط§ط±ط¬ ط§ظ„ظ…ظٹط²ط§ظ†ظٹط©'),
            const SizedBox(height: 8),
            ..._recurringCards(outBudget),
            if (outBudget.isEmpty)
              const Card(child: ListTile(title: Text('ظ„ط§ طھظˆط¬ط¯ ظ…ط¹ط§ظ…ظ„ط§طھ ظپظٹ ظ‡ط°ط§ ط§ظ„ظ‚ط³ظ….'))),
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
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _parseColor(record.iconColor),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: AppIconPickerDialog.iconWidgetForName(
                  record.icon,
                  color: Colors.white,
                  size: 18,
                ),
              ),
              title: Text(record.name),
              subtitle: Text(
                '${_recurrenceLabel(record)} - ${record.executionType == 'auto' ? 'طھظ„ظ‚ط§ط¦ظٹ' : record.executionType == 'confirm' ? 'طھط£ظƒظٹط¯' : 'ظٹط¯ظˆظٹ'}',
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
            _row('ط§ظ„ظ†ظˆط¹', record.type == 'income' ? 'ط¯ط®ظ„' : 'ظ…طµط±ظˆظپ'),
            _row('ط§ظ„ظ…ط¨ظ„ط؛', record.amount.toStringAsFixed(2)),
            _row('ط§ظ„طھط§ط±ظٹط® ط§ظ„ط¯ظˆط±ظٹ', _recurrenceLabel(record)),
            _row(
              'ط§ظ„طھظ†ظپظٹط°',
              record.executionType == 'auto'
                  ? 'طھظ„ظ‚ط§ط¦ظٹ'
                  : record.executionType == 'confirm'
                      ? 'ظٹطھط·ظ„ط¨ طھط£ظƒظٹط¯'
                      : 'ظٹط¯ظˆظٹ',
            ),
            _row('ط§ظ„ظ…ظٹط²ط§ظ†ظٹط©', record.budgetScope == 'within-budget' ? 'ط¯ط§ط®ظ„ ط§ظ„ظ…ظٹط²ط§ظ†ظٹط©' : 'ط®ط§ط±ط¬ ط§ظ„ظ…ظٹط²ط§ظ†ظٹط©'),
            if ((record.notes ?? '').trim().isNotEmpty) _row('ظ…ظ„ط§ط­ط¸ط§طھ', record.notes!.trim()),
            const SizedBox(height: 16),
            Center(
              child: FilledButton.icon(
                onPressed: () => _openRecurringComposer(mode: record.type, editing: record),
                icon: const Icon(Icons.edit_outlined),
                label: const Text('طھط¹ط¯ظٹظ„ ط§ظ„ظ…ط¹ط§ظ…ظ„ط©'),
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
    final timeSuffix =
        (record.scheduledTime ?? '').isEmpty ? '' : ' - ${record.scheduledTime}';
    final weekdayLabel = record.weekdays.isNotEmpty
        ? record.weekdays.map(_weekdayName).join('، ')
        : _weekdayName(record.weekday);
    switch (record.recurrencePattern) {
      case 'daily':
        return 'يومي$timeSuffix';
      case 'weekly':
        return 'أسبوعي ($weekdayLabel)$timeSuffix';
      case 'biweekly':
        return 'كل أسبوعين ($weekdayLabel)$timeSuffix';
      case 'every_3_weeks':
        return 'كل 3 أسابيع ($weekdayLabel)$timeSuffix';
      case 'every_2_months':
        return 'كل شهرين يوم ${record.dayOfMonth}$timeSuffix';
      case 'every_3_months':
        return 'كل 3 شهور يوم ${record.dayOfMonth}$timeSuffix';
      case 'every_6_months':
        return 'كل 6 شهور يوم ${record.dayOfMonth}$timeSuffix';
      case 'yearly':
        return 'سنوي ${record.dayOfMonth}/${record.monthOfYear ?? 1}$timeSuffix';
      case 'manual-variable':
        return 'دخل متغير يدوي';
      default:
        return 'شهري يوم ${record.dayOfMonth}$timeSuffix';
    }
  }

  String _weekdayName(int? day) {
    switch (day) {
      case 1:
        return 'الإثنين';
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

  Color _parseColor(String hex) {
    final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | value);
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
        child: RecurringTransactionComposerScreen(
          cubit: widget.cubit,
          initialType: mode,
          initialRecurring: editing,
        ),
      ),
    );
  }
}

