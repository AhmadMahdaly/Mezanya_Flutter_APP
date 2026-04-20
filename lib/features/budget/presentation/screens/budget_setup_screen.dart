import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon_picker_dialog.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../../transactions/domain/entities/recurring_transaction_entity.dart';
import '../../../transactions/presentation/screens/recurring_transaction_composer_screen.dart';
import '../../../wallets/presentation/screens/jar_editor_screen.dart';
import '../../domain/entities/budget_setup_entity.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({
    super.key,
    required this.cubit,
    this.displayMonth,
  });

  final AppCubit cubit;
  final DateTime? displayMonth;

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  late BudgetSetupEntity _budget;
  late DateTime _displayMonth;
  bool _futureMonthNoticeShown = false;

  static const List<String> _weekdayNames = <String>[
    'الإثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  @override
  void initState() {
    super.initState();
    _budget = widget.cubit.state.budgetSetup;
    final initialMonth = widget.displayMonth ?? DateTime.now();
    _displayMonth = DateTime(initialMonth.year, initialMonth.month, 1);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _showFutureMonthNoticeIfNeeded();
    });
  }

  @override
  void dispose() => super.dispose();

  double get _totalIncome => _budget.incomeSources.fold<double>(
        0,
        (sum, income) => sum + (income.isVariable ? 0 : income.amount),
      );

  double get _allocationsTotal => _budget.allocations.fold<double>(
        0,
        (sum, allocation) =>
            sum +
            allocation.funding.fold<double>(0, (s, f) => s + f.plannedAmount),
      );

  double get _linkedTotal => _budget.linkedWallets.fold<double>(
        0,
        (sum, wallet) => sum + wallet.monthlyAmount,
      );

  double get _debtsTotal => _budget.debts.fold<double>(
        0,
        (sum, debt) => sum + debt.amount,
      );

  double get _committed => _allocationsTotal + _linkedTotal + _debtsTotal;

  double get _unallocated => _totalIncome - _committed;

  bool get _isCurrentMonthSetup {
    final now = DateTime.now();
    return _displayMonth.year == now.year && _displayMonth.month == now.month;
  }

  bool get _isFutureMonthSetup {
    final nowMonth = DateTime(DateTime.now().year, DateTime.now().month, 1);
    return _displayMonth.isAfter(nowMonth);
  }

  String get _displayMonthName {
    const monthNames = <String>[
      'يناير',
      'فبراير',
      'مارس',
      'أبريل',
      'مايو',
      'يونيو',
      'يوليو',
      'أغسطس',
      'سبتمبر',
      'أكتوبر',
      'نوفمبر',
      'ديسمبر',
    ];
    return '${monthNames[_displayMonth.month - 1]} ${_displayMonth.year}';
  }

  String get _screenHeading => _isCurrentMonthSetup
      ? 'إعداد الشهر الحالي'
      : 'خطة إعداد شهر $_displayMonthName';

  String get _screenSubheading => _isCurrentMonthSetup
      ? 'هذه الصفحة خاصة بتخطيط ميزانية الشهر الحالي.'
      : 'أنت الآن تعد خطة شهر قادم مسبقًا قبل بداية تنفيذه.';

  Future<void> _showFutureMonthNoticeIfNeeded() async {
    if (!mounted || !_isFutureMonthSetup || _futureMonthNoticeShown) {
      return;
    }
    _futureMonthNoticeShown = true;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('خطة شهر قادم: $_displayMonthName'),
        content: const Text(
          'هذه الصفحة خاصة بإعداد شهر قادم وليست للشهر الحالي. يمكنك المتابعة أو التحويل مباشرة إلى إعداد الشهر الحالي.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              setState(() {
                final now = DateTime.now();
                _displayMonth = DateTime(now.year, now.month, 1);
              });
            },
            child: const Text('خطة الشهر الحالي'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('أوكي'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveBudget(BudgetSetupEntity next) async {
    final normalized = next.copyWith(
      totalIncome: _totalIncomeFrom(next),
      totalAllocated: _committedFrom(next),
      unallocatedAmount: _totalIncomeFrom(next) - _committedFrom(next),
    );
    setState(() => _budget = normalized);
    await widget.cubit.updateBudgetSetup(normalized);
  }

  double _totalIncomeFrom(BudgetSetupEntity setup) {
    return setup.incomeSources.fold<double>(
      0,
      (sum, income) => sum + (income.isVariable ? 0 : income.amount),
    );
  }

  double _committedFrom(BudgetSetupEntity setup) {
    final allocationsTotal = setup.allocations.fold<double>(
      0,
      (sum, allocation) =>
          sum +
          allocation.funding.fold<double>(0, (s, f) => s + f.plannedAmount),
    );
    final linkedTotal = setup.linkedWallets.fold<double>(
      0,
      (sum, wallet) => sum + wallet.monthlyAmount,
    );
    final debtsTotal = setup.debts.fold<double>(
      0,
      (sum, debt) => sum + debt.amount,
    );
    return allocationsTotal + linkedTotal + debtsTotal;
  }

  String _id(String prefix) =>
      '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _openIncomeComposer() async {
    final result =
        await Navigator.of(context).push<RecurringTransactionComposerResult>(
      MaterialPageRoute(
        builder: (_) => RecurringTransactionComposerScreen(
          cubit: widget.cubit,
          initialType: 'income',
          initialWithinBudget: true,
          returnOnSave: true,
        ),
        fullscreenDialog: true,
      ),
    );
    final recurring = result?.recurring;
    if (recurring == null) {
      return;
    }

    final income = IncomeSourceEntity(
      id: _id('income'),
      name: recurring.name,
      amount: recurring.isVariableIncome ? 0 : recurring.amount,
      date: recurring.dayOfMonth.clamp(1, 31),
      type: recurring.isVariableIncome ? 'manual' : recurring.executionType,
      targetWalletId: recurring.walletId,
      isVariable: recurring.isVariableIncome,
      isDefault: false,
    );

    final nextBudget = _budget.copyWith(
      incomeSources: [..._budget.incomeSources, income],
    );
    await _saveBudget(nextBudget);

    await widget.cubit.addRecurringTransaction(
      name: recurring.name,
      type: recurring.type,
      amount: recurring.amount,
      dayOfMonth: recurring.dayOfMonth,
      executionType: recurring.executionType,
      walletId: recurring.walletId,
      budgetScope: 'within-budget',
      recurrencePattern: recurring.recurrencePattern,
      icon: recurring.icon,
      iconColor: recurring.iconColor,
      weekday: recurring.weekday,
      weekdays: recurring.weekdays,
      monthOfYear: recurring.monthOfYear,
      scheduledTime: recurring.scheduledTime,
      reminderLeadDays: recurring.reminderLeadDays,
      incomeSourceId: income.id,
      categoryIds: recurring.categoryIds,
      isVariableIncome: recurring.isVariableIncome,
      isDebtOrSubscription: false,
      notes: recurring.notes,
    );
  }

  Future<void> _showIncomeDialog({IncomeSourceEntity? current}) async {
    if (current == null) {
      await _openIncomeComposer();
      return;
    }

    final wallets = widget.cubit.state.wallets;
    final fallbackWalletId =
        wallets.isNotEmpty ? wallets.first.id : 'wallet-cash-default';
    final linkedRecurring = _linkedRecurringIncome(current.id);
    final draftRecurring = linkedRecurring ??
        RecurringTransactionEntity(
          id: '',
          name: current.name,
          type: 'income',
          amount: current.isVariable ? 0 : current.amount,
          dayOfMonth: current.date.clamp(1, 28),
          executionType: current.isVariable ? 'manual' : current.type,
          walletId: current.targetWalletId.isEmpty
              ? fallbackWalletId
              : current.targetWalletId,
          budgetScope: 'within-budget',
          recurrencePattern: 'monthly',
          icon: 'cash',
          iconColor: '#0f9d7a',
          incomeSourceId: current.id,
          isVariableIncome: current.isVariable,
          isDebtOrSubscription: false,
        );

    final result =
        await Navigator.of(context).push<RecurringTransactionComposerResult>(
      MaterialPageRoute(
        builder: (_) => RecurringTransactionComposerScreen(
          cubit: widget.cubit,
          initialType: 'income',
          initialWithinBudget: true,
          initialRecurring: draftRecurring,
          returnOnSave: true,
          allowDelete: true,
        ),
        fullscreenDialog: true,
      ),
    );

    if (result == null) {
      return;
    }

    if (result.deleteRequested) {
      final linked = widget.cubit.state.recurringTransactions
          .where((r) => r.incomeSourceId == current.id)
          .toList();
      for (final rec in linked) {
        await widget.cubit.deleteRecurringTransaction(rec.id);
      }
      final next = _budget.incomeSources.where((e) => e.id != current.id).toList();
      await _saveBudget(_budget.copyWith(incomeSources: next));
      return;
    }

    final recurring = result.recurring;
    if (recurring == null) {
      return;
    }

    final saved = IncomeSourceEntity(
      id: current.id,
      name: recurring.name,
      amount: recurring.isVariableIncome ? 0 : recurring.amount,
      date: recurring.dayOfMonth.clamp(1, 31),
      type: recurring.isVariableIncome ? 'manual' : recurring.executionType,
      targetWalletId: recurring.walletId,
      isVariable: recurring.isVariableIncome,
      isDefault: current.isDefault,
    );

    final next = _budget.incomeSources
        .map((e) => e.id == current.id ? saved : e)
        .toList();
    await _saveBudget(_budget.copyWith(incomeSources: next));

    if (linkedRecurring == null) {
      await widget.cubit.addRecurringTransaction(
        name: recurring.name,
        type: recurring.type,
        amount: recurring.amount,
        dayOfMonth: recurring.dayOfMonth,
        executionType: recurring.executionType,
        walletId: recurring.walletId,
        budgetScope: recurring.budgetScope,
        recurrencePattern: recurring.recurrencePattern,
        icon: recurring.icon,
        iconColor: recurring.iconColor,
        weekday: recurring.weekday,
        weekdays: recurring.weekdays,
        monthOfYear: recurring.monthOfYear,
        scheduledTime: recurring.scheduledTime,
        reminderLeadDays: recurring.reminderLeadDays,
        incomeSourceId: current.id,
        categoryIds: recurring.categoryIds,
        isVariableIncome: recurring.isVariableIncome,
        isDebtOrSubscription: false,
        notes: recurring.notes,
      );
    } else {
      await widget.cubit.updateRecurringTransaction(
        linkedRecurring.copyWith(
          name: recurring.name,
          type: recurring.type,
          amount: recurring.amount,
          dayOfMonth: recurring.dayOfMonth,
          executionType: recurring.executionType,
          walletId: recurring.walletId,
          budgetScope: recurring.budgetScope,
          recurrencePattern: recurring.recurrencePattern,
          icon: recurring.icon,
          iconColor: recurring.iconColor,
          weekday: recurring.weekday,
          weekdays: recurring.weekdays,
          monthOfYear: recurring.monthOfYear,
          scheduledTime: recurring.scheduledTime,
          reminderLeadDays: recurring.reminderLeadDays,
          incomeSourceId: current.id,
          categoryIds: recurring.categoryIds,
          isVariableIncome: recurring.isVariableIncome,
          isDebtOrSubscription: false,
          notes: recurring.notes,
        ),
      );
    }
  }

  Future<void> _showAllocationDialog({AllocationEntity? current}) async {
    if (_budget.incomeSources.isEmpty) return;
    final allocation = await Navigator.of(context).push<AllocationEntity>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => _AllocationEditorScreen(
          current: current,
          incomeSources: _budget.incomeSources,
          idFactory: _id,
        ),
      ),
    );
    if (allocation == null) {
      return;
    }
    final next = current == null
        ? [..._budget.allocations, allocation]
        : _budget.allocations
            .map((e) => e.id == current.id ? allocation : e)
            .toList();
    await _saveBudget(_budget.copyWith(allocations: next));
  }

  Future<void> _showLinkedDialog({LinkedWalletEntity? current}) async {
    if (_budget.incomeSources.isEmpty) return;
    final result = await Navigator.of(context).push<JarEditorResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => JarEditorScreen(
          current: current,
          incomeSources: _budget.incomeSources,
          idFactory: _id,
        ),
      ),
    );
    if (result == null) {
      return;
    }
    if (result.deleteRequested && current != null) {
      final next = _budget.linkedWallets.where((e) => e.id != current.id).toList();
      await _saveBudget(_budget.copyWith(linkedWallets: next));
      return;
    }
    final entity = result.entity;
    if (entity == null) {
      return;
    }
    final next = current == null
        ? [..._budget.linkedWallets, entity]
        : _budget.linkedWallets
            .map((e) => e.id == current.id ? entity : e)
            .toList();
    await _saveBudget(_budget.copyWith(linkedWallets: next));
  }

  Future<void> _showDebtDialog({DebtEntity? current}) async {
    if (_budget.incomeSources.isEmpty) return;
    final linkedRecurring = current == null ? null : _linkedRecurringDebt(current);
    final draftRecurring = linkedRecurring ??
        RecurringTransactionEntity(
          id: current?.recurringTransactionId ?? '',
          name: current?.name ?? '',
          type: 'expense',
          amount: current?.amount ?? 0,
          dayOfMonth: (current?.executionDay ?? 1).clamp(1, 28),
          executionType: current?.type ?? 'confirm',
          walletId: widget.cubit.state.wallets.isNotEmpty
              ? widget.cubit.state.wallets.first.id
              : '',
          budgetScope: 'within-budget',
          recurrencePattern: 'monthly',
          icon: 'receipt',
          iconColor: '#c65d2e',
          incomeSourceId: null,
          isDebtOrSubscription: true,
        );

    final result =
        await Navigator.of(context).push<RecurringTransactionComposerResult>(
      MaterialPageRoute(
        builder: (_) => RecurringTransactionComposerScreen(
          cubit: widget.cubit,
          initialType: 'expense',
          initialWithinBudget: true,
          initialRecurring: draftRecurring,
          returnOnSave: true,
        ),
        fullscreenDialog: true,
      ),
    );
    final recurring = result?.recurring;
    if (recurring == null) {
      return;
    }

    final recurringId =
        linkedRecurring?.id ?? current?.recurringTransactionId ?? _id('rec');
    final debt = DebtEntity(
      id: current?.id ?? _id('debt'),
      name: recurring.name,
      amount: recurring.amount,
      executionDay: recurring.dayOfMonth.clamp(1, 31),
      type: recurring.executionType,
      fundingSource:
          current?.fundingSource ??
          (_budget.incomeSources.isNotEmpty ? _budget.incomeSources.first.id : ''),
      recurringTransactionId: recurringId,
    );

    final nextDebts = current == null
        ? [..._budget.debts, debt]
        : _budget.debts.map((item) => item.id == current.id ? debt : item).toList();
    await _saveBudget(_budget.copyWith(debts: nextDebts));

    final recurringToSave = recurring.copyWith(
      id: recurringId,
      type: 'expense',
      budgetScope: 'within-budget',
      isDebtOrSubscription: true,
      allocationId: null,
      targetJarId: null,
    );

    if (linkedRecurring == null) {
      await widget.cubit.addRecurringTransaction(
        id: recurringId,
        name: recurringToSave.name,
        type: recurringToSave.type,
        amount: recurringToSave.amount,
        dayOfMonth: recurringToSave.dayOfMonth,
        executionType: recurringToSave.executionType,
        walletId: recurringToSave.walletId,
        budgetScope: recurringToSave.budgetScope,
        recurrencePattern: recurringToSave.recurrencePattern,
        icon: recurringToSave.icon,
        iconColor: recurringToSave.iconColor,
        weekday: recurringToSave.weekday,
        weekdays: recurringToSave.weekdays,
        monthOfYear: recurringToSave.monthOfYear,
        scheduledTime: recurringToSave.scheduledTime,
        reminderLeadDays: recurringToSave.reminderLeadDays,
        isDebtOrSubscription: true,
        notes: recurringToSave.notes,
      );
    } else {
      await widget.cubit.updateRecurringTransaction(recurringToSave);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
          decoration: BoxDecoration(
            color: _isFutureMonthSetup
                ? const Color(0xFFFFF4E8)
                : colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: _isFutureMonthSetup
                  ? const Color(0xFFE6B36A)
                  : colorScheme.outlineVariant.withValues(alpha: 0.45),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _isFutureMonthSetup
                      ? const Color(0xFFF3D4A4)
                      : const Color(0xFFDDEFEA),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isFutureMonthSetup
                      ? Icons.schedule_rounded
                      : Icons.calendar_month_rounded,
                  color: _isFutureMonthSetup
                      ? const Color(0xFF9A5A11)
                      : const Color(0xFF0E5A47),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _screenHeading,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _screenSubheading,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: LinearGradient(
              colors: _unallocated >= 0
                  ? const [Color(0xFF0E5A47), Color(0xFF197C64)]
                  : const [Color(0xFF8F3E2A), Color(0xFFBE5A35)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'غير المخصص',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _unallocated.toStringAsFixed(2),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _summaryMini(
                      label: 'إجمالي الدخل',
                      value: _totalIncome,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _summaryMini(
                      label: 'إجمالي المخصص',
                      value: _committed,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'إعداد الدورة',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'حدد يوم بداية الدورة وطريقة تجديد الخطة ونهاية المبلغ غير المخصص.',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 420;
                  final dayField = TextFormField(
                    initialValue: _budget.startDay.toString(),
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'بداية الدورة',
                      prefixIcon: Icon(Icons.event_rounded),
                    ),
                    onFieldSubmitted: (value) {
                      final day = (int.tryParse(value) ?? 1).clamp(1, 31);
                      _saveBudget(_budget.copyWith(startDay: day));
                    },
                  );
                  final cycleField = DropdownButtonFormField<String>(
                    initialValue: _budget.cycleMode,
                    decoration: const InputDecoration(
                      labelText: 'تجديد الخطة',
                      prefixIcon: Icon(Icons.autorenew_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'auto', child: Text('تلقائي')),
                      DropdownMenuItem(
                        value: 'confirm',
                        child: Text('بعد التأكيد'),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) {
                        _saveBudget(_budget.copyWith(cycleMode: value));
                      }
                    },
                  );

                  if (compact) {
                    return Column(
                      children: [
                        dayField,
                        const SizedBox(height: 8),
                        cycleField,
                      ],
                    );
                  }

                  return Row(
                    children: [
                      Expanded(child: dayField),
                      const SizedBox(width: 8),
                      Expanded(child: cycleField),
                    ],
                  );
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _budget.bufferEndBehavior,
                decoration: const InputDecoration(
                  labelText: 'المبلغ غير المخصص آخر الدورة',
                  prefixIcon: Icon(Icons.savings_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'to-savings', child: Text('يتحول للتوفير')),
                  DropdownMenuItem(
                      value: 'keep', child: Text('يبقى للدورة الجديدة')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    _saveBudget(_budget.copyWith(bufferEndBehavior: value));
                  }
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        _plannerSection(
          title: 'مصادر الدخل',
          subtitle: 'أضف الدخل الثابت أو المتغير الذي يدخل في ميزانيتك الشهرية.',
          icon: Icons.south_west_rounded,
          accent: const Color(0xFF0F9D7A),
          actionLabel: 'إضافة دخل',
          onAction: _openIncomeComposer,
          children: () {
            if (_budget.incomeSources.isEmpty) {
              return <Widget>[_emptyState('أضف أول دخل لتبدأ توزيع الميزانية.')];
            }

            return <Widget>[
              ..._budget.incomeSources.map(
                (income) {
                  return _planTile(
                    title: income.name,
                    subtitle: income.isVariable
                        ? 'دخل متغير يتم تسجيله يدويًا'
                        : '${_incomeTypeLabel(income.type)} • يوم ${income.date} • ${income.amount.toStringAsFixed(2)}',
                    leading: Icons.payments_rounded,
                    tint: const Color(0xFF0F9D7A),
                    onTap: () => _showIncomeDialog(current: income),
                    onDelete: null,
                  );
                },
              ),
            ];
          }(),
        ),
        const SizedBox(height: 14),
        _plannerSection(
          title: 'المخصصات',
          subtitle: 'قسّم ميزانيتك على بنود واضحة قبل بداية الصرف.',
          icon: Icons.grid_view_rounded,
          accent: const Color(0xFF296BFF),
          actionLabel: 'إضافة مخصص',
          onAction: () => _showAllocationDialog(),
          children: _budget.allocations.isEmpty
              ? [_emptyState('أنشئ مخصصات مثل البيت أو الأكل أو المواصلات.')]
              : _budget.allocations
                  .map(
                    (allocation) => _planTile(
                      title: allocation.name,
                      subtitle:
                          '${allocation.funding.fold<double>(0, (s, f) => s + f.plannedAmount).toStringAsFixed(2)} • ${allocation.rolloverBehavior == 'keep' ? 'يرحل للدورة التالية' : 'يرجع للتوفير'}',
                      leading: Icons.inventory_2_rounded,
                      tint: const Color(0xFF296BFF),
                      onTap: () => _showAllocationDialog(current: allocation),
                      onDelete: () {
                        _saveBudget(
                          _budget.copyWith(
                            allocations: _budget.allocations
                                .where((e) => e.id != allocation.id)
                                .toList(),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 14),
        _plannerSection(
          title: 'الحصالات',
          subtitle: 'مبالغ ثابتة تتحول لأهدافك أو محافظك المرتبطة.',
          icon: Icons.savings_rounded,
          accent: const Color(0xFFE09F1F),
          actionLabel: 'إضافة حصالة',
          onAction: () => _showLinkedDialog(),
          children: _budget.linkedWallets.isEmpty
              ? [_emptyState('أضف حصالاتك المرتبطة مثل الطوارئ أو السفر.')]
              : _budget.linkedWallets
                  .map(
                    (wallet) => _planTile(
                      title: wallet.name,
                      subtitle:
                          '${wallet.monthlyAmount.toStringAsFixed(2)} • يوم ${wallet.executionDay}',
                      leading: Icons.account_balance_wallet_rounded,
                      tint: const Color(0xFFE09F1F),
                      onTap: () => _showLinkedDialog(current: wallet),
                      onDelete: () {
                        _saveBudget(
                          _budget.copyWith(
                            linkedWallets: _budget.linkedWallets
                                .where((e) => e.id != wallet.id)
                                .toList(),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 14),
        _plannerSection(
          title: 'الديون والأقساط',
          subtitle: 'التزامات شهرية تحتاج ميعاد واضح ومصدر تمويل محدد.',
          icon: Icons.receipt_long_rounded,
          accent: const Color(0xFFC65D2E),
          actionLabel: 'إضافة دين أو قسط',
          onAction: () => _showDebtDialog(),
          children: _budget.debts.isEmpty
              ? [
                  _emptyState(
                      'سجل الأقساط أو الديون الشهرية حتى تظهر ضمن الالتزامات.')
                ]
              : _budget.debts
                  .map(
                    (debt) => _planTile(
                      title: debt.name,
                      subtitle:
                          '${debt.amount.toStringAsFixed(2)} • يوم ${debt.executionDay}',
                      leading: Icons.credit_card_rounded,
                      tint: const Color(0xFFC65D2E),
                      onTap: () => _showDebtDialog(current: debt),
                      onDelete: () async {
                        final recurring = _linkedRecurringDebt(debt);
                        if (recurring != null) {
                          await widget.cubit.deleteRecurringTransaction(recurring.id);
                        }
                        await _saveBudget(
                          _budget.copyWith(
                            debts: _budget.debts
                                .where((e) => e.id != debt.id)
                                .toList(),
                          ),
                        );
                      },
                    ),
                  )
                  .toList(),
        ),
      ],
    );
  }

  Widget _plannerSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required String actionLabel,
    required VoidCallback onAction,
    required List<Widget> children,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(26),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel),
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _summaryMini({
    required String label,
    required double value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value.toStringAsFixed(2),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _planTile({
    required String title,
    required String subtitle,
    required IconData leading,
    required Color tint,
    required VoidCallback onTap,
    bool emphasize = false,
    Widget? extra,
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: emphasize ? 0.12 : 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: tint.withValues(alpha: emphasize ? 0.30 : 0.14),
          width: emphasize ? 1.6 : 1,
        ),
        boxShadow: emphasize
            ? [
                BoxShadow(
                  color: tint.withValues(alpha: 0.12),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tint.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(leading, color: tint, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(subtitle),
                        if (emphasize) ...[
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: tint.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'دخل معلق يحتاج إجراء',
                              style: TextStyle(
                                color: tint,
                                fontWeight: FontWeight.w800,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Icon(Icons.edit_outlined, color: tint, size: 20),
                  if (onDelete != null)
                    IconButton(
                      onPressed: onDelete,
                      icon: const Icon(Icons.delete_outline),
                    ),
                ],
              ),
              if (extra != null) extra,
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptyState(String text) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color:
            theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: theme.colorScheme.onSurfaceVariant,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _incomeTypeLabel(String type) {
    switch (type) {
      case 'auto':
        return 'تلقائي';
      case 'manual':
        return 'يدوي';
      case 'confirm':
        return 'تأكيد';
      default:
        return type;
    }
  }

  RecurringTransactionEntity? _linkedRecurringIncome(String incomeId) {
    final linked = widget.cubit.state.recurringTransactions.where(
      (item) =>
          item.type == 'income' &&
          item.budgetScope == 'within-budget' &&
          item.incomeSourceId == incomeId,
    );
    if (linked.isEmpty) {
      return null;
    }
    return linked.first;
  }

  RecurringTransactionEntity? _linkedRecurringDebt(DebtEntity debt) {
    final recurringList = widget.cubit.state.recurringTransactions;
    if ((debt.recurringTransactionId ?? '').isNotEmpty) {
      final exact = recurringList.where((item) => item.id == debt.recurringTransactionId);
      if (exact.isNotEmpty) {
        return exact.first;
      }
    }
    final fallback = recurringList.where(
      (item) =>
          item.type == 'expense' &&
          item.budgetScope == 'within-budget' &&
          item.isDebtOrSubscription &&
          item.name == debt.name &&
          item.amount == debt.amount,
    );
    if (fallback.isEmpty) {
      return null;
    }
    return fallback.first;
  }

  DateTime? _parseClockTime(String? value) {
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

  DateTime? _nextOccurrence(RecurringTransactionEntity recurring, DateTime now) {
    final time = _parseClockTime(recurring.scheduledTime) ?? now;
    DateTime atDate(DateTime day) =>
        DateTime(day.year, day.month, day.day, time.hour, time.minute);

    if (recurring.recurrencePattern == 'manual-variable') {
      return null;
    }
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
    if (recurring.recurrencePattern == 'monthly' ||
        recurring.recurrencePattern == 'every_2_months' ||
        recurring.recurrencePattern == 'every_3_months' ||
        recurring.recurrencePattern == 'every_6_months') {
      final interval = switch (recurring.recurrencePattern) {
        'every_2_months' => 2,
        'every_3_months' => 3,
        'every_6_months' => 6,
        _ => 1,
      };
      for (var step = 0; step < 12; step++) {
        final monthDate = DateTime(now.year, now.month + (step * interval));
        final candidate = DateTime(
          monthDate.year,
          monthDate.month,
          recurring.dayOfMonth.clamp(1, 28),
          time.hour,
          time.minute,
        );
        if (candidate.isAfter(now)) {
          return candidate;
        }
      }
    }
    if (recurring.recurrencePattern == 'yearly') {
      final month = recurring.monthOfYear ?? now.month;
      final thisYear = DateTime(
        now.year,
        month,
        recurring.dayOfMonth.clamp(1, 28),
        time.hour,
        time.minute,
      );
      if (thisYear.isAfter(now)) {
        return thisYear;
      }
      return DateTime(
        now.year + 1,
        month,
        recurring.dayOfMonth.clamp(1, 28),
        time.hour,
        time.minute,
      );
    }
    return null;
  }

  Duration _leadDuration(RecurringTransactionEntity recurring) {
    final value = recurring.reminderLeadDays ?? 0;
    if (recurring.recurrencePattern == 'daily' ||
        recurring.recurrencePattern == 'weekly' ||
        recurring.recurrencePattern == 'biweekly' ||
        recurring.recurrencePattern == 'every_3_weeks') {
      return Duration(hours: value.clamp(0, 3));
    }
    return Duration(days: value.clamp(0, 3));
  }
}

class _AllocationEditorScreen extends StatefulWidget {
  const _AllocationEditorScreen({
    required this.current,
    required this.incomeSources,
    required this.idFactory,
  });

  final AllocationEntity? current;
  final List<IncomeSourceEntity> incomeSources;
  final String Function(String prefix) idFactory;

  @override
  State<_AllocationEditorScreen> createState() => _AllocationEditorScreenState();
}

class _AllocationEditorScreenState extends State<_AllocationEditorScreen> {
  late final TextEditingController _nameController;
  late String _selectedIcon;
  late String _selectedColor;
  late String _rolloverBehavior;
  late List<AllocationFundingEntity> _funding;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.current?.name ?? '');
    _selectedIcon = widget.current?.icon ?? 'category';
    _selectedColor = widget.current?.iconColor ?? '#165b47';
    _rolloverBehavior = widget.current?.rolloverBehavior ?? 'to-savings';
    _funding = List<AllocationFundingEntity>.from(
      widget.current?.funding ??
          [
            AllocationFundingEntity(
              id: widget.idFactory('fund'),
              incomeSourceId: widget.incomeSources.first.id,
              plannedAmount: 0,
            ),
          ],
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  double get _totalPlanned => _funding.fold<double>(
        0,
        (sum, item) => sum + item.plannedAmount,
      );

  Future<void> _pickIcon() async {
    final picked = await AppIconPickerDialog.show(
      context,
      initialIconName: _selectedIcon,
      initialColorHex: _selectedColor,
      title: 'اختيار أيقونة المخصص',
    );
    if (picked == null || !mounted) {
      return;
    }
    setState(() {
      _selectedIcon = picked.iconName;
      _selectedColor = picked.colorHex;
    });
  }

  void _addFundingSource() {
    setState(() {
      _funding = [
        ..._funding,
        AllocationFundingEntity(
          id: widget.idFactory('fund'),
          incomeSourceId: widget.incomeSources.first.id,
          plannedAmount: 0,
        ),
      ];
    });
  }

  void _updateFundingSource(String id, {String? incomeSourceId, double? amount}) {
    setState(() {
      _funding = _funding
          .map(
            (item) => item.id == id
                ? AllocationFundingEntity(
                    id: item.id,
                    incomeSourceId: incomeSourceId ?? item.incomeSourceId,
                    plannedAmount: amount ?? item.plannedAmount,
                  )
                : item,
          )
          .toList();
    });
  }

  void _removeFundingSource(String id) {
    if (_funding.length == 1) {
      return;
    }
    setState(() {
      _funding = _funding.where((item) => item.id != id).toList();
    });
  }

  void _save() {
    final name = _nameController.text.trim();
    final cleaned = _funding
        .where((item) => item.incomeSourceId.isNotEmpty && item.plannedAmount > 0)
        .toList();
    if (name.isEmpty) {
      _showMessage('اكتب اسمًا واضحًا للمخصص أولًا.');
      return;
    }
    if (cleaned.isEmpty) {
      _showMessage('أضف مصدر تمويل واحدًا على الأقل بقيمة أكبر من صفر.');
      return;
    }
    Navigator.of(context).pop(
      AllocationEntity(
        id: widget.current?.id ?? widget.idFactory('alloc'),
        name: name,
        icon: _selectedIcon,
        iconColor: _selectedColor,
        rolloverBehavior: _rolloverBehavior,
        funding: cleaned,
        categories: widget.current?.categories ?? const [],
      ),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final accent = _colorFromHex(_selectedColor);

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.current == null ? 'إضافة مخصص' : 'تعديل المخصص'),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
          child: FilledButton(
            onPressed: _save,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
              backgroundColor: accent,
            ),
            child: Text(
              widget.current == null ? 'إضافة المخصص' : 'حفظ التعديلات',
            ),
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(26),
              gradient: LinearGradient(
                colors: [
                  accent.withValues(alpha: 0.95),
                  accent.withValues(alpha: 0.72),
                ],
                begin: Alignment.topRight,
                end: Alignment.bottomLeft,
              ),
              boxShadow: [
                BoxShadow(
                  color: accent.withValues(alpha: 0.22),
                  blurRadius: 24,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Center(
                    child: AppIconPickerDialog.iconWidgetForName(
                      _selectedIcon,
                      color: Colors.white,
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _nameController.text.trim().isEmpty
                            ? 'مخصص جديد'
                            : _nameController.text.trim(),
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _rolloverBehavior == 'keep'
                            ? 'المتبقي يرحل إلى الشهر التالي'
                            : 'المتبقي يتحول إلى التوفير',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'إجمالي التمويل ${_totalPlanned.toStringAsFixed(2)}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          _EditorSection(
            title: 'البيانات الأساسية',
            subtitle: 'سمِّ المخصص واختر له أيقونة واضحة يسهل تمييزها.',
            child: Column(
              children: [
                TextField(
                  controller: _nameController,
                  textDirection: TextDirection.rtl,
                  decoration: const InputDecoration(
                    labelText: 'اسم المخصص',
                    hintText: 'مثل: البيت أو المواصلات أو المصروف اليومي',
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 12),
                InkWell(
                  onTap: _pickIcon,
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.35,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: accent.withValues(alpha: 0.16),
                            borderRadius: BorderRadius.circular(18),
                          ),
                          child: Center(
                            child: AppIconPickerDialog.iconWidgetForName(
                              _selectedIcon,
                              color: accent,
                              size: 26,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'اختيار الأيقونة واللون',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'غيّر شكل المخصص ليظهر بوضوح في شاشة المتابعة.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_left_rounded),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _EditorSection(
            title: 'المتبقي آخر الدورة',
            subtitle: 'اختر كيف تريد التعامل مع الرصيد المتبقي من هذا المخصص.',
            child: Column(
              children: [
                _ChoiceTile(
                  title: 'يرحل إلى الشهر التالي',
                  subtitle: 'يبقى المبلغ المتبقي داخل نفس المخصص في الدورة الجديدة.',
                  selected: _rolloverBehavior == 'keep',
                  onTap: () => setState(() => _rolloverBehavior = 'keep'),
                ),
                const SizedBox(height: 10),
                _ChoiceTile(
                  title: 'يتحول إلى التوفير',
                  subtitle: 'ينتقل المتبقي تلقائيًا إلى التوفير بدل ترحيله.',
                  selected: _rolloverBehavior == 'to-savings',
                  onTap: () => setState(() => _rolloverBehavior = 'to-savings'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _EditorSection(
            title: 'مصادر التمويل',
            subtitle: 'وزّع قيمة هذا المخصص على دخل واحد أو أكثر.',
            trailing: TextButton.icon(
              onPressed: _addFundingSource,
              icon: const Icon(Icons.add_rounded),
              label: const Text('إضافة مصدر'),
            ),
            child: Column(
              children: _funding
                  .map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _FundingCard(
                        item: item,
                        incomeSources: widget.incomeSources,
                        canDelete: _funding.length > 1,
                        onChanged: ({String? incomeSourceId, double? amount}) {
                          _updateFundingSource(
                            item.id,
                            incomeSourceId: incomeSourceId,
                            amount: amount,
                          );
                        },
                        onDelete: () => _removeFundingSource(item.id),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorSection extends StatelessWidget {
  const _EditorSection({
    required this.title,
    required this.subtitle,
    required this.child,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  const _ChoiceTile({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? const Color(0xFF0E5A47).withValues(alpha: 0.10)
              : colorScheme.surfaceContainerHighest.withValues(alpha: 0.26),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected
                ? const Color(0xFF0E5A47)
                : colorScheme.outlineVariant.withValues(alpha: 0.55),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_off_rounded,
              color: selected
                  ? const Color(0xFF0E5A47)
                  : colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }
}

class _FundingCard extends StatelessWidget {
  const _FundingCard({
    required this.item,
    required this.incomeSources,
    required this.canDelete,
    required this.onChanged,
    required this.onDelete,
  });

  final AllocationFundingEntity item;
  final List<IncomeSourceEntity> incomeSources;
  final bool canDelete;
  final void Function({String? incomeSourceId, double? amount}) onChanged;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.28),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        ),
      ),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            initialValue: item.incomeSourceId,
            decoration: const InputDecoration(
              labelText: 'مصدر الدخل',
            ),
            items: incomeSources
                .map(
                  (income) => DropdownMenuItem(
                    value: income.id,
                    child: Text(income.name),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value == null) {
                return;
              }
              onChanged(incomeSourceId: value);
            },
          ),
          const SizedBox(height: 12),
          TextFormField(
            initialValue: item.plannedAmount == 0
                ? ''
                : item.plannedAmount.toStringAsFixed(0),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'المبلغ المخصص',
              hintText: 'اكتب القيمة التي تريد تخصيصها',
            ),
            onChanged: (value) => onChanged(amount: double.tryParse(value) ?? 0),
          ),
          const SizedBox(height: 8),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton.icon(
              onPressed: canDelete ? onDelete : null,
              icon: const Icon(Icons.delete_outline_rounded),
              label: const Text('حذف هذا المصدر'),
            ),
          ),
        ],
      ),
    );
  }
}

Color _colorFromHex(String value) {
  final hex = value.replaceAll('#', '');
  final normalized = hex.length == 6 ? 'FF$hex' : hex;
  final intColor = int.tryParse(normalized, radix: 16) ?? 0xFF165B47;
  return Color(intColor);
}
