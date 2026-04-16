import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon_picker_dialog.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../../budget/domain/entities/budget_setup_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../domain/entities/recurring_transaction_entity.dart';
import '../../domain/entities/transaction_entity.dart';
import '../../../wallets/domain/entities/wallet_entity.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({
    super.key,
    required this.cubit,
    this.initialTransaction,
    this.recurringMode = false,
    this.recurringType,
    this.initialRecurring,
  });

  final AppCubit cubit;
  final TransactionEntity? initialTransaction;
  final bool recurringMode;
  final String? recurringType;
  final RecurringTransactionEntity? initialRecurring;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  String _type = 'expense';
  String _budgetScope = 'within-budget';
  String _incomeBudgetScope = 'outside-budget';
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _recurringNameController = TextEditingController();
  final _newCategoryController = TextEditingController();
  DateTime _date = DateTime.now();
  TimeOfDay _time = TimeOfDay.now();
  String _walletId = '';
  String _budgetTargetId = '';
  String _incomeSourceId = 'wallet-only';
  String _incomeJarId = '';
  String _recurrencePattern = 'monthly';
  int _recurrenceWeekday = DateTime.now().weekday;
  String _recurringIconName = 'category';
  String _recurringIconColor = '#165b47';
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _amountController.addListener(_refreshAmountPreview);
    final state = widget.cubit.state;
    _walletId = state.wallets.isNotEmpty ? state.wallets.first.id : '';
    _incomeSourceId = 'wallet-only';
    _incomeJarId = state.budgetSetup.linkedWallets.isNotEmpty
        ? state.budgetSetup.linkedWallets.first.id
        : '';
    if (widget.recurringMode) {
      _type = widget.recurringType ?? 'expense';
      final r = widget.initialRecurring;
      if (r != null) {
        _type = r.type;
        _walletId = r.walletId;
        _amountController.text = r.amount.toStringAsFixed(2);
        _notesController.text = r.notes ?? '';
        _recurringNameController.text = r.name;
        _recurrencePattern = r.recurrencePattern;
        _recurrenceWeekday = r.weekday ?? _recurrenceWeekday;
        _recurringIconName = r.icon;
        _recurringIconColor = r.iconColor;
        _budgetScope = r.budgetScope;
        _incomeBudgetScope = r.budgetScope;
        _incomeSourceId = r.incomeSourceId ?? _incomeSourceId;
        _incomeJarId = r.targetJarId ?? _incomeJarId;
        if (r.allocationId != null) {
          _budgetTargetId = 'alloc:${r.allocationId!}';
        } else if (r.targetJarId != null) {
          _budgetTargetId = 'jar:${r.targetJarId!}';
        }
        _date = DateTime(_date.year, _date.month, r.dayOfMonth);
      }
    }
    final t = widget.initialTransaction;
    if (t != null) {
      _type = t.type;
      _date = t.createdAt;
      _time = TimeOfDay(hour: t.createdAt.hour, minute: t.createdAt.minute);
      _walletId = t.walletId ?? _walletId;
      _amountController.text = t.amount.toStringAsFixed(2);
      _notesController.text = t.notes ?? '';
      _incomeSourceId = t.incomeSourceId ?? _incomeSourceId;
      if (t.type == 'expense') {
        _budgetScope = t.budgetScope ?? 'outside-budget';
        if (t.allocationId != null) {
          _budgetTargetId = 'alloc:${t.allocationId!}';
        } else if (t.toWalletId != null) {
          _budgetTargetId = 'jar:${t.toWalletId!}';
        } else {
          _budgetTargetId = '';
        }
      }
      if (t.type == 'income') {
        _incomeBudgetScope = t.budgetScope == 'within-budget'
            ? 'within-budget'
            : 'outside-budget';
        _incomeJarId = t.toWalletId ?? _incomeJarId;
      }
    }
  }

  @override
  void dispose() {
    _amountController.removeListener(_refreshAmountPreview);
    _amountController.dispose();
    _notesController.dispose();
    _recurringNameController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  void _refreshAmountPreview() {
    if (mounted) {
      setState(() {});
    }
  }

  bool get _canSubmit {
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    if (_isSaving || amount <= 0 || _walletId.isEmpty) {
      return false;
    }
    if (_type == 'expense' &&
        _budgetScope == 'within-budget' &&
        _budgetTargetId.isEmpty) {
      return false;
    }
    if (_type == 'income' &&
        _incomeBudgetScope == 'within-budget' &&
        _incomeJarId.isEmpty) {
      return false;
    }
    if (widget.recurringMode && _recurringNameController.text.trim().isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.cubit.state;
    final wallets = state.wallets;
    final budget = state.budgetSetup;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final selectedWallet = wallets.where((w) => w.id == _walletId).toList();
    final selectedWalletName = selectedWallet.isEmpty
        ? 'اختر المحفظة'
        : selectedWallet.first.name;

    final selectedAllocation = budget.allocations
        .where((a) => _budgetTargetId == 'alloc:${a.id}')
        .toList();
    final selectedJar = budget.linkedWallets
        .where((j) => _budgetTargetId == 'jar:${j.id}')
        .toList();
    final selectedAllocationName = _budgetTargetId == 'unallocated'
        ? 'غير المخصص'
        : selectedJar.isNotEmpty
            ? 'حصالة: ${selectedJar.first.name}'
            : selectedAllocation.isEmpty
                ? 'اختر المخصص'
                : selectedAllocation.first.name;
    final selectedIncomeJar =
        budget.linkedWallets.where((j) => j.id == _incomeJarId).toList();
    final selectedIncomeJarName = selectedIncomeJar.isEmpty
        ? 'اختر الحصالة'
        : selectedIncomeJar.first.name;

    final allocationCategories = selectedAllocation.isEmpty
        ? <CategoryEntity>[]
        : selectedAllocation.first.categories;
    final jarCategories =
        selectedJar.isEmpty ? <CategoryEntity>[] : selectedJar.first.categories;
    final generalExpenseCategories = state.categories
        .where((c) => c.scope == 'expense' && c.incomeSourceId == null)
        .toList();
    final visibleCategories = _budgetScope == 'within-budget'
        ? (selectedJar.isNotEmpty ? jarCategories : allocationCategories)
        : generalExpenseCategories;

    final allocationItems = [
      if (budget.unallocatedAmount > 0)
        const DropdownMenuItem(
            value: 'unallocated',
            child: Text('غير المخصص')),
      ...budget.allocations.map(
          (a) => DropdownMenuItem(value: 'alloc:${a.id}', child: Text(a.name))),
      ...budget.linkedWallets.map((j) => DropdownMenuItem(
          value: 'jar:${j.id}',
          child: Text('حصالة: ${j.name}'))),
    ];
    final allocationIds = allocationItems.map((item) => item.value!).toSet();

    if (_type == 'expense' &&
        _budgetScope == 'within-budget' &&
        _budgetTargetId.isEmpty &&
        allocationItems.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _budgetTargetId.isNotEmpty) {
          return;
        }
        setState(() => _budgetTargetId = allocationItems.first.value!);
      });
    }

    if (_budgetTargetId.isNotEmpty &&
        !allocationIds.contains(_budgetTargetId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() => _budgetTargetId = '');
      });
    }

    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.scaffoldBackgroundColor,
            theme.colorScheme.surface,
            theme.colorScheme.secondaryContainer.withValues(alpha: 0.55),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Center(
              child: Container(
                width: 54,
                height: 6,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _typeSegmentedToggle(theme),
            if (widget.recurringMode) ...[
              const SizedBox(height: 10),
              TextField(
                controller: _recurringNameController,
                decoration: const InputDecoration(
                    labelText: 'اسم المعاملة المتكررة'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: _recurrencePattern,
                decoration: const InputDecoration(labelText: 'التكرار'),
                items: const [
                  DropdownMenuItem(
                      value: 'weekly',
                      child: Text('مرة كل أسبوع')),
                  DropdownMenuItem(
                      value: 'biweekly',
                      child: Text('مرة كل أسبوعين')),
                  DropdownMenuItem(
                      value: 'monthly',
                      child: Text('مرة كل شهر')),
                  DropdownMenuItem(
                      value: 'every_2_months',
                      child: Text('مرة كل شهرين')),
                  DropdownMenuItem(
                      value: 'every_3_months',
                      child: Text('مرة كل 3 شهور')),
                  DropdownMenuItem(
                      value: 'every_6_months',
                      child: Text('مرة كل 6 شهور')),
                  DropdownMenuItem(
                      value: 'yearly',
                      child: Text('مرة كل سنة')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _recurrencePattern = v);
                },
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await AppIconPickerDialog.show(
                      context,
                      initialIconName: _recurringIconName,
                      initialColorHex: _recurringIconColor,
                      title: 'اختيار أيقونة المعاملة المتكررة',
                    );
                    if (picked == null) return;
                    setState(() {
                      _recurringIconName = picked.iconName;
                      _recurringIconColor = picked.colorHex;
                    });
                  },
                  icon: const Icon(Icons.palette_outlined),
                  label: const Text('اختيار الأيقونة واللون'),
                ),
              ),
            ],
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
              decoration: const InputDecoration(
                  labelText: 'المبلغ'),
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              tileColor: theme.colorScheme.surface,
              title: const Text('المحفظة'),
              subtitle: Text(selectedWalletName),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => _openWalletPicker(wallets),
            ),
            if (widget.recurringMode &&
                (_recurrencePattern == 'weekly' ||
                    _recurrencePattern == 'biweekly')) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _recurrenceWeekday,
                decoration: const InputDecoration(
                    labelText: 'اليوم في الأسبوع'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('الاثنين')),
                  DropdownMenuItem(value: 2, child: Text('الثلاثاء')),
                  DropdownMenuItem(value: 3, child: Text('الأربعاء')),
                  DropdownMenuItem(value: 4, child: Text('الخميس')),
                  DropdownMenuItem(value: 5, child: Text('الجمعة')),
                  DropdownMenuItem(value: 6, child: Text('السبت')),
                  DropdownMenuItem(value: 7, child: Text('الأحد')),
                ],
                onChanged: (v) {
                  if (v != null) setState(() => _recurrenceWeekday = v);
                },
              ),
            ],
            if (_type == 'expense') ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text(
                        'داخل الميزانية'),
                    const Spacer(),
                    Switch(
                      value: _budgetScope == 'within-budget',
                      onChanged: (v) {
                        setState(() {
                          _budgetScope = v ? 'within-budget' : 'outside-budget';
                          if (!v) _budgetTargetId = '';
                        });
                      },
                    ),
                  ],
                ),
              ),
            ],
            if (_type == 'expense' && _budgetScope == 'within-budget') ...[
              const SizedBox(height: 10),
              ListTile(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
                tileColor: theme.colorScheme.surface,
                title: const Text('المخصص أو الحصالة'),
                subtitle: Text(selectedAllocationName),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => _openAllocationPicker(allocationItems, budget),
              ),
              const SizedBox(height: 10),
              _categoriesBlock(
                title: 'الفئات',
                categories: visibleCategories,
                onAdd:
                    _budgetTargetId.isEmpty && _budgetScope == 'within-budget'
                        ? null
                        : () => _openAddCategoryDialog(
                              budgetScope: _budgetScope,
                              allocationId: _budgetTargetId.startsWith('alloc:')
                                  ? _budgetTargetId.replaceFirst('alloc:', '')
                                  : '',
                              linkedWalletId: _budgetTargetId.startsWith('jar:')
                                  ? _budgetTargetId.replaceFirst('jar:', '')
                                  : '',
                              existing: visibleCategories,
                            ),
              ),
            ],
            if (_type == 'expense' && _budgetScope == 'outside-budget') ...[
              const SizedBox(height: 10),
              _categoriesBlock(
                title: 'الفئات العامة',
                categories: visibleCategories,
                onAdd: () => _openAddCategoryDialog(
                  budgetScope: _budgetScope,
                  allocationId: '',
                  linkedWalletId: '',
                  existing: visibleCategories,
                ),
              ),
            ],
            if (_type == 'income') ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _incomeSourceId,
                decoration: const InputDecoration(
                    labelText: 'مصدر الدخل'),
                items: [
                  const DropdownMenuItem(
                      value: 'wallet-only',
                      child: Text(
                          'إيداع للمحفظة فقط')),
                  ...budget.incomeSources.map((i) =>
                      DropdownMenuItem(value: i.id, child: Text(i.name))),
                ],
                onChanged: (v) =>
                    setState(() => _incomeSourceId = v ?? 'wallet-only'),
              ),
              const SizedBox(height: 10),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Text(
                        'داخل الميزانية'),
                    const Spacer(),
                    Switch(
                      value: _incomeBudgetScope == 'within-budget',
                      onChanged: (v) {
                        setState(
                          () => _incomeBudgetScope =
                              v ? 'within-budget' : 'outside-budget',
                        );
                      },
                    ),
                  ],
                ),
              ),
              if (_incomeBudgetScope == 'within-budget') ...[
                const SizedBox(height: 8),
                ListTile(
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  tileColor: theme.colorScheme.surface,
                  title: const Text('الحصالة'),
                  subtitle: Text(selectedIncomeJarName),
                  trailing: const Icon(Icons.chevron_left),
                  onTap: () => _openIncomeJarPicker(budget),
                ),
              ],
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    title: const Text('التاريخ'),
                    subtitle: Text('${_date.day}/${_date.month}/${_date.year}'),
                    trailing: const Icon(Icons.calendar_month_outlined),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) {
                        setState(() => _date = picked);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color:
                            theme.colorScheme.onSurface.withValues(alpha: 0.1),
                      ),
                    ),
                    title: const Text('الوقت'),
                    subtitle: Text(
                      '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: const Icon(Icons.access_time),
                    onTap: () async {
                      final picked = await showTimePicker(
                        context: context,
                        initialTime: _time,
                      );
                      if (picked != null) {
                        setState(() => _time = picked);
                      }
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'ملاحظات'),
            ),
            const SizedBox(height: 12),
            if (widget.recurringMode && widget.initialRecurring != null)
              TextButton(
                onPressed: () async {
                  await widget.cubit.deleteRecurringTransaction(
                    widget.initialRecurring!.id,
                  );
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                child: Text(
                  'حذف المعاملة المتكررة',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            if (!widget.recurringMode && widget.initialTransaction != null)
              TextButton(
                onPressed: () async {
                  await widget.cubit
                      .deleteTransaction(widget.initialTransaction!.id);
                  if (!context.mounted) return;
                  Navigator.of(context).pop();
                },
                child: Text(
                  'حذف المعاملة',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
              ),
            FilledButton(
              onPressed: !_canSubmit
                  ? null
                  : () async {
                      setState(() => _isSaving = true);
                      try {
                if (amount <= 0) {
                  _showValidationError(
                      'أدخل مبلغًا صحيحًا أكبر من صفر.');
                  return;
                }
                if (_walletId.isEmpty) {
                  _showValidationError('اختر محفظة أولًا.');
                  return;
                }
                if (_type == 'expense' &&
                    _budgetScope == 'within-budget' &&
                    _budgetTargetId.isEmpty) {
                  _showValidationError(
                      'اختر مخصصًا أو حصالة للمعاملة داخل الميزانية.');
                  return;
                }
                if (_budgetTargetId == 'unallocated' &&
                    amount > budget.unallocatedAmount) {
                  _showValidationError(
                      'المبلغ أكبر من المتاح في غير المخصص.');
                  return;
                }
                if (_type == 'income' &&
                    _incomeBudgetScope == 'within-budget' &&
                    _incomeJarId.isEmpty) {
                  _showValidationError(
                      'اختر حصالة للدخل داخل الميزانية.');
                  return;
                }
                if (widget.recurringMode &&
                    _recurringNameController.text.trim().isEmpty) {
                  _showValidationError('اكتب اسم المعاملة المتكررة.');
                  return;
                }

                final selectedJarId = _budgetTargetId.startsWith('jar:')
                    ? _budgetTargetId.replaceFirst('jar:', '')
                    : null;

                if (widget.recurringMode) {
                  final recurring = widget.initialRecurring;
                  final recurringEntity = RecurringTransactionEntity(
                    id: recurring?.id ??
                        'rec-${DateTime.now().microsecondsSinceEpoch}',
                    name: _recurringNameController.text.trim(),
                    type: _type,
                    amount: amount,
                    dayOfMonth: _date.day.clamp(1, 28),
                    executionType: 'confirm',
                    walletId: _walletId,
                    budgetScope:
                        _type == 'expense' ? _budgetScope : _incomeBudgetScope,
                    recurrencePattern: _recurrencePattern,
                    icon: _recurringIconName,
                    iconColor: _recurringIconColor,
                    weekday: (_recurrencePattern == 'weekly' ||
                            _recurrencePattern == 'biweekly')
                        ? _recurrenceWeekday
                        : null,
                    allocationId: _type == 'expense' &&
                            _budgetScope == 'within-budget' &&
                            _budgetTargetId.startsWith('alloc:')
                        ? _budgetTargetId.replaceFirst('alloc:', '')
                        : null,
                    targetJarId: _type == 'income' &&
                            _incomeBudgetScope == 'within-budget'
                        ? _incomeJarId
                        : (_type == 'expense' &&
                                _budgetTargetId.startsWith('jar:')
                            ? selectedJarId
                            : null),
                    incomeSourceId:
                        _type == 'income' && _incomeSourceId != 'wallet-only'
                            ? _incomeSourceId
                            : null,
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                    isActive: recurring?.isActive ?? true,
                  );
                  if (recurring == null) {
                    await widget.cubit.addRecurringTransaction(
                      name: recurringEntity.name,
                      type: recurringEntity.type,
                      amount: recurringEntity.amount,
                      dayOfMonth: recurringEntity.dayOfMonth,
                      executionType: recurringEntity.executionType,
                      walletId: recurringEntity.walletId,
                      budgetScope: recurringEntity.budgetScope,
                      recurrencePattern: recurringEntity.recurrencePattern,
                      icon: recurringEntity.icon,
                      iconColor: recurringEntity.iconColor,
                      weekday: recurringEntity.weekday,
                      allocationId: recurringEntity.allocationId,
                      targetJarId: recurringEntity.targetJarId,
                      incomeSourceId: recurringEntity.incomeSourceId,
                      notes: recurringEntity.notes,
                    );
                  } else {
                    await widget.cubit
                        .updateRecurringTransaction(recurringEntity);
                  }
                } else {
                  if (widget.initialTransaction != null) {
                    await widget.cubit.deleteTransaction(
                      widget.initialTransaction!.id,
                    );
                  }
                  await widget.cubit.addTransaction(
                    walletId: _walletId,
                    toWalletId: _type == 'income' &&
                            _incomeBudgetScope == 'within-budget'
                        ? _incomeJarId
                        : selectedJarId,
                    amount: amount,
                    type: _type,
                    createdAt: DateTime(
                      _date.year,
                      _date.month,
                      _date.day,
                      _time.hour,
                      _time.minute,
                    ),
                    allocationId: _type == 'expense' &&
                            _budgetScope == 'within-budget' &&
                            _budgetTargetId.startsWith('alloc:')
                        ? _budgetTargetId.replaceFirst('alloc:', '')
                        : null,
                    budgetScope: _type == 'expense'
                        ? _budgetScope
                        : _type == 'income'
                            ? _incomeBudgetScope
                            : null,
                    incomeSourceId:
                        _type == 'income' && _incomeSourceId != 'wallet-only'
                            ? _incomeSourceId
                            : null,
                    notes: _notesController.text.trim().isEmpty
                        ? null
                        : _notesController.text.trim(),
                  );
                }
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(widget.recurringMode
                          ? 'تم حفظ المعاملة المتكررة.'
                          : (_type == 'income'
                              ? 'تم تسجيل الدخل.'
                              : 'تم تسجيل المعاملة.'))),
                );
                Navigator.of(context).pop();
                      } finally {
                        if (mounted) {
                          setState(() => _isSaving = false);
                        }
                      }
                    },
              child: Text(
                widget.recurringMode
                    ? (widget.initialRecurring == null
                        ? 'حفظ المعاملة المتكررة'
                        : 'تحديث التكرار')
                    : widget.initialTransaction != null
                        ? 'حفظ التعديل'
                        : (_type == 'income'
                            ? 'تسجيل الدخل'
                            : 'تسجيل المعاملة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeSegmentedToggle(ThemeData theme) {
    final activeOnRight = _type == 'income';
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
        ),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOutCubic,
            alignment:
                activeOnRight ? Alignment.centerRight : Alignment.centerLeft,
            child: Container(
              width: MediaQuery.of(context).size.width > 420 ? 190 : 165,
              margin: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFF1E7F5C),
                borderRadius: BorderRadius.circular(14),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33207B5A),
                    blurRadius: 12,
                    offset: Offset(0, 5),
                  ),
                ],
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: widget.recurringMode
                      ? null
                      : () => setState(() => _type = 'expense'),
                  child: Center(
                    child: Text(
                      'مصروف',
                      style: TextStyle(
                        color: !activeOnRight
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: widget.recurringMode
                      ? null
                      : () => setState(() {
                            _type = 'income';
                            _budgetTargetId = '';
                          }),
                  child: Center(
                    child: Text(
                      'دخل',
                      style: TextStyle(
                        color: activeOnRight
                            ? Colors.white
                            : theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openWalletPicker(List<WalletEntity> wallets) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: wallets
              .map(
                (wallet) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(wallet.name),
                    subtitle: Text(
                        'الرصيد: ${wallet.balance.toStringAsFixed(2)}'),
                    trailing: _walletId == wallet.id
                        ? Icon(Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary)
                        : null,
                    onTap: () {
                      setState(() => _walletId = wallet.id);
                      Navigator.pop(context);
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  void _openAllocationPicker(List<DropdownMenuItem<String>> allocationItems,
      BudgetSetupEntity budget) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: allocationItems.map((item) {
            final id = item.value!;
            if (id == 'unallocated') {
              final ratio = (budget.unallocatedAmount /
                      (budget.totalIncome <= 0 ? 1 : budget.totalIncome))
                  .clamp(0.0, 1.0);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: const Text('غير المخصص'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'المتبقي: ${budget.unallocatedAmount.toStringAsFixed(2)}'),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                          value: ratio.toDouble(), minHeight: 8),
                    ],
                  ),
                  trailing: _budgetTargetId == id
                      ? Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _budgetTargetId = id);
                    Navigator.pop(context);
                  },
                ),
              );
            }
            if (id.startsWith('jar:')) {
              final jar =
                  budget.linkedWallets.firstWhere((j) => 'jar:${j.id}' == id);
              final ratio = (jar.balance /
                      (budget.totalIncome <= 0 ? 1 : budget.totalIncome))
                  .clamp(0.0, 1.0);
              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                child: ListTile(
                  title: Text('حصالة: ${jar.name}'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                          'الرصيد: ${jar.balance.toStringAsFixed(2)}'),
                      const SizedBox(height: 6),
                      LinearProgressIndicator(
                          value: ratio.toDouble(), minHeight: 8),
                    ],
                  ),
                  trailing: _budgetTargetId == id
                      ? Icon(Icons.check_circle,
                          color: Theme.of(context).colorScheme.primary)
                      : null,
                  onTap: () {
                    setState(() => _budgetTargetId = id);
                    Navigator.pop(context);
                  },
                ),
              );
            }
            final allocation =
                budget.allocations.firstWhere((a) => 'alloc:${a.id}' == id);
            final planned = allocation.funding
                .fold<double>(0, (s, f) => s + f.plannedAmount);
            final ratio =
                (planned / (budget.totalIncome <= 0 ? 1 : budget.totalIncome))
                    .clamp(0.0, 1.0);
            return Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: ListTile(
                title: Text(allocation.name),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        'المخطط: ${planned.toStringAsFixed(2)}'),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                        value: ratio.toDouble(), minHeight: 8),
                  ],
                ),
                trailing: _budgetTargetId == id
                    ? Icon(Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary)
                    : null,
                onTap: () {
                  setState(() => _budgetTargetId = id);
                  Navigator.pop(context);
                },
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  void _openIncomeJarPicker(BudgetSetupEntity budget) {
    final jars = budget.linkedWallets;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: jars
              .map(
                (jar) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: ListTile(
                    title: Text(jar.name),
                    subtitle: Text(
                        'الرصيد: ${jar.balance.toStringAsFixed(2)}'),
                    trailing: _incomeJarId == jar.id
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                    onTap: () {
                      setState(() => _incomeJarId = jar.id);
                      Navigator.pop(context);
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ),
    );
  }

  Widget _categoriesBlock({
    required String title,
    required List<CategoryEntity> categories,
    required VoidCallback? onAdd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
            TextButton.icon(
              onPressed: onAdd,
              icon: const Icon(Icons.add, size: 16),
              label: const Text('إضافة فئة'),
            ),
          ],
        ),
        const SizedBox(height: 6),
        if (categories.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              color: Theme.of(context).colorScheme.surface,
            ),
            child: const Text(
                'لا توجد فئات حتى الآن لهذا الجزء.'),
          )
        else
          SizedBox(
            height: 52,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final c = categories[index];
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _parseColor(c.color).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _parseColor(c.color),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: AppIconPickerDialog.iconWidgetForName(
                          c.icon,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        c.name,
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _openAddCategoryDialog({
    required String budgetScope,
    required String allocationId,
    required String linkedWalletId,
    required List<CategoryEntity> existing,
  }) async {
    _newCategoryController.clear();
    var selectedIcon = 'restaurant';
    var selectedColor = '#165b47';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) {
          return AlertDialog(
            title: const Text('إضافة فئة'),
            content: SizedBox(
              width: 500,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('اسم الفئة'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _newCategoryController,
                      decoration: const InputDecoration(
                          hintText: 'اكتب اسم الفئة'),
                      onChanged: (_) => setDialog(() {}),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final picked = await AppIconPickerDialog.show(
                            context,
                            initialIconName: selectedIcon,
                            initialColorHex: selectedColor,
                            title: 'اختيار أيقونة الفئة',
                          );
                          if (picked == null) return;
                          setDialog(() {
                            selectedIcon = picked.iconName;
                            selectedColor = picked.colorHex;
                          });
                        },
                        icon: const Icon(Icons.palette_outlined),
                        label: const Text('اختيار الأيقونة واللون'),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 46,
                            height: 46,
                            decoration: BoxDecoration(
                              color: _parseColor(selectedColor),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: AppIconPickerDialog.iconWidgetForName(
                                selectedIcon,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(_newCategoryController.text.isEmpty
                              ? 'اسم الفئة'
                              : _newCategoryController.text),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('تم'),
              ),
            ],
          );
        },
      ),
    );
    if (ok != true) return;
    final name = _newCategoryController.text.trim();
    if (name.isEmpty) return;

    final category = CategoryEntity(
      id: 'cat-${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      icon: selectedIcon,
      color: selectedColor,
      scope: 'expense',
      allocationId:
          budgetScope == 'within-budget' && allocationId != 'unallocated'
              ? allocationId
              : null,
    );

    if (budgetScope == 'within-budget' &&
        allocationId.isNotEmpty &&
        allocationId != 'unallocated') {
      await widget.cubit.updateAllocationCategories(
        allocationId: allocationId,
        categories: [...existing, category],
      );
    } else if (budgetScope == 'within-budget' && linkedWalletId.isNotEmpty) {
      await widget.cubit.updateLinkedWalletCategories(
        linkedWalletId: linkedWalletId,
        categories: [...existing, category],
      );
    } else {
      final current = widget.cubit.state.categories;
      await widget.cubit.setCategories([...current, category]);
    }

    if (!mounted) return;
    setState(() {});
  }

  Color _parseColor(String hex) {
    final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | value);
  }

  void _showValidationError(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
