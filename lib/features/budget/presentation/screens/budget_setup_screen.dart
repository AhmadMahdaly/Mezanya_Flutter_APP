import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon_picker_dialog.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../../transactions/domain/entities/recurring_transaction_entity.dart';
import '../../domain/entities/budget_setup_entity.dart';

class BudgetSetupScreen extends StatefulWidget {
  const BudgetSetupScreen({super.key, required this.cubit});

  final AppCubit cubit;

  @override
  State<BudgetSetupScreen> createState() => _BudgetSetupScreenState();
}

class _BudgetSetupScreenState extends State<BudgetSetupScreen> {
  late BudgetSetupEntity _budget;

  @override
  void initState() {
    super.initState();
    _budget = widget.cubit.state.budgetSetup;
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

  Future<void> _showIncomeDialog({IncomeSourceEntity? current}) async {
    final wallets = widget.cubit.state.wallets;
    final recurringList = widget.cubit.state.recurringTransactions;
    final fallbackWalletId =
        wallets.isNotEmpty ? wallets.first.id : 'wallet-cash-default';
    final linkedRecurring = current == null
        ? null
        : recurringList.where((r) => r.incomeSourceId == current.id).isNotEmpty
            ? recurringList.firstWhere((r) => r.incomeSourceId == current.id)
            : null;
    final nameController = TextEditingController(text: current?.name ?? '');
    final amountController =
        TextEditingController(text: (current?.amount ?? 0).toStringAsFixed(0));
    final dayController = TextEditingController(
        text: (current?.date ?? _budget.startDay).toString());
    final timeController = TextEditingController(
      text: linkedRecurring?.notes?.startsWith('time:') == true
          ? linkedRecurring!.notes!.replaceFirst('time:', '')
          : '09:00',
    );
    var isVariable = current?.isVariable ?? false;
    var type = current?.type ?? 'confirm';
    var walletId = current?.targetWalletId ?? fallbackWalletId;
    var recurrencePattern = linkedRecurring?.recurrencePattern ?? 'monthly';
    var recurrenceWeekday = linkedRecurring?.weekday ?? DateTime.now().weekday;
    var selectedIcon = linkedRecurring?.icon ?? 'cash';
    var selectedColor = linkedRecurring?.iconColor ?? '#0f9d7a';

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(current == null ? 'ط¥ط¶ط§ظپط© ط¯ط®ظ„ ط¬ط¯ظٹط¯' : 'طھط¹ط¯ظٹظ„ ط§ظ„ط¯ط®ظ„'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'ط§ط³ظ… ط§ظ„ط¯ط®ظ„'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: isVariable ? 'variable' : 'fixed',
                      decoration:
                          const InputDecoration(labelText: 'ط·ط¨ظٹط¹ط© ط§ظ„ط¯ط®ظ„'),
                      items: const [
                        DropdownMenuItem(value: 'fixed', child: Text('ط«ط§ط¨طھ')),
                        DropdownMenuItem(
                            value: 'variable', child: Text('ط؛ظٹط± ط«ط§ط¨طھ')),
                      ],
                      onChanged: (v) {
                        if (v == null) return;
                        setDialogState(() {
                          isVariable = v == 'variable';
                          if (isVariable) type = 'manual';
                        });
                      },
                    ),
                    if (!isVariable) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: amountController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'ط§ظ„ظ‚ظٹظ…ط©'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: dayController,
                        keyboardType: TextInputType.number,
                        decoration:
                            const InputDecoration(labelText: 'ظٹظˆظ… ط§ظ„ط¥ط¶ط§ظپط©'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: recurrencePattern,
                        decoration: const InputDecoration(
                          labelText: 'ط§ظ„طھظƒط±ط§ط±',
                        ),
                        items: const [
                          DropdownMenuItem(
                              value: 'weekly', child: Text('ظ…ط±ط© ظƒظ„ ط£ط³ط¨ظˆط¹')),
                          DropdownMenuItem(
                              value: 'biweekly', child: Text('ظ…ط±ط© ظƒظ„ ط£ط³ط¨ظˆط¹ظٹظ†')),
                          DropdownMenuItem(
                              value: 'monthly', child: Text('ظ…ط±ط© ظƒظ„ ط´ظ‡ط±')),
                          DropdownMenuItem(
                              value: 'every_2_months',
                              child: Text('ظ…ط±ط© ظƒظ„ ط´ظ‡ط±ظٹظ†')),
                          DropdownMenuItem(
                              value: 'every_3_months',
                              child: Text('ظ…ط±ط© ظƒظ„ 3 ط´ظ‡ظˆط±')),
                          DropdownMenuItem(
                              value: 'every_6_months',
                              child: Text('ظ…ط±ط© ظƒظ„ 6 ط´ظ‡ظˆط±')),
                          DropdownMenuItem(
                              value: 'yearly', child: Text('ظ…ط±ط© ظƒظ„ ط³ظ†ط©')),
                        ],
                        onChanged: (v) {
                          if (v != null) {
                            setDialogState(() => recurrencePattern = v);
                          }
                        },
                      ),
                      if (recurrencePattern == 'weekly' ||
                          recurrencePattern == 'biweekly') ...[
                        const SizedBox(height: 8),
                        DropdownButtonFormField<int>(
                          initialValue: recurrenceWeekday,
                          decoration: const InputDecoration(
                              labelText: 'ط§ظ„ظٹظˆظ… ظپظٹ ط§ظ„ط£ط³ط¨ظˆط¹'),
                          items: const [
                            DropdownMenuItem(value: 1, child: Text('ط§ظ„ط§ط«ظ†ظٹظ†')),
                            DropdownMenuItem(value: 2, child: Text('ط§ظ„ط«ظ„ط§ط«ط§ط،')),
                            DropdownMenuItem(value: 3, child: Text('ط§ظ„ط£ط±ط¨ط¹ط§ط،')),
                            DropdownMenuItem(value: 4, child: Text('ط§ظ„ط®ظ…ظٹط³')),
                            DropdownMenuItem(value: 5, child: Text('ط§ظ„ط¬ظ…ط¹ط©')),
                            DropdownMenuItem(value: 6, child: Text('ط§ظ„ط³ط¨طھ')),
                            DropdownMenuItem(value: 7, child: Text('ط§ظ„ط£ط­ط¯')),
                          ],
                          onChanged: (v) {
                            if (v != null) {
                              setDialogState(() => recurrenceWeekday = v);
                            }
                          },
                        ),
                      ],
                      const SizedBox(height: 8),
                      TextField(
                        controller: timeController,
                        decoration: const InputDecoration(
                          labelText: 'ط§ظ„ظˆظ‚طھ (ط§ط®طھظٹط§ط±ظٹ)',
                          hintText: '09:00',
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration:
                            const InputDecoration(labelText: 'ظ†ظˆط¹ ط§ظ„طھظ†ظپظٹط°'),
                        items: const [
                          DropdownMenuItem(
                              value: 'auto', child: Text('طھظ„ظ‚ط§ط¦ظٹ')),
                          DropdownMenuItem(
                              value: 'confirm', child: Text('طھط£ظƒظٹط¯')),
                          DropdownMenuItem(
                              value: 'manual', child: Text('ظٹط¯ظˆظٹ')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => type = v);
                        },
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await AppIconPickerDialog.show(
                              context,
                              initialIconName: selectedIcon,
                              initialColorHex: selectedColor,
                              title: 'ط§ط®طھظٹط§ط± ط£ظٹظ‚ظˆظ†ط© ظ…طµط¯ط± ط§ظ„ط¯ط®ظ„',
                            );
                            if (picked == null) return;
                            setDialogState(() {
                              selectedIcon = picked.iconName;
                              selectedColor = picked.colorHex;
                            });
                          },
                          icon: const Icon(Icons.palette_outlined),
                          label: const Text('ط§ط®طھظٹط§ط± ط§ظ„ط£ظٹظ‚ظˆظ†ط© ظˆط§ظ„ظ„ظˆظ†'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: walletId,
                      decoration: const InputDecoration(
                          labelText: 'طھظ†ط²ظ„ ظپظٹ ظ…ط­ظپط¸ط© ظپط¹ظ„ظٹط©'),
                      items: wallets
                          .map(
                            (wallet) => DropdownMenuItem(
                                value: wallet.id, child: Text(wallet.name)),
                          )
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => walletId = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ط¥ظ„ط؛ط§ط،'),
                ),
                FilledButton(
                  onPressed: () async {
                    final name = nameController.text.trim();
                    final amount =
                        double.tryParse(amountController.text.trim()) ?? 0;
                    final day = (int.tryParse(dayController.text.trim()) ??
                            _budget.startDay)
                        .clamp(1, 31);
                    if (name.isEmpty) return;
                    if (!isVariable && amount <= 0) return;

                    final saved = IncomeSourceEntity(
                      id: current?.id ?? _id('income'),
                      name: name,
                      amount: isVariable ? 0 : amount,
                      date: day,
                      type: isVariable ? 'manual' : type,
                      targetWalletId: walletId,
                      isVariable: isVariable,
                      isDefault: current?.isDefault ?? false,
                    );
                    final next = current == null
                        ? [..._budget.incomeSources, saved]
                        : _budget.incomeSources
                            .map((e) => e.id == current.id ? saved : e)
                            .toList();
                    await _saveBudget(_budget.copyWith(incomeSources: next));

                    final recurringEntity = RecurringTransactionEntity(
                      id: linkedRecurring?.id ?? _id('rec'),
                      name: name,
                      type: 'income',
                      amount: isVariable ? 0 : amount,
                      dayOfMonth: day.clamp(1, 28),
                      executionType: isVariable ? 'manual' : type,
                      walletId: walletId,
                      budgetScope: 'within-budget',
                      recurrencePattern:
                          isVariable ? 'monthly' : recurrencePattern,
                      icon: selectedIcon,
                      iconColor: selectedColor,
                      weekday: (recurrencePattern == 'weekly' ||
                              recurrencePattern == 'biweekly')
                          ? recurrenceWeekday
                          : null,
                      incomeSourceId: saved.id,
                      notes: timeController.text.trim().isEmpty
                          ? null
                          : 'time:${timeController.text.trim()}',
                    );
                    if (linkedRecurring == null) {
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
                        incomeSourceId: recurringEntity.incomeSourceId,
                        notes: recurringEntity.notes,
                      );
                    } else {
                      await widget.cubit
                          .updateRecurringTransaction(recurringEntity);
                    }
                    if (!mounted) return;
                    Navigator.of(this.context).pop();
                  },
                  child: const Text('طھظ…'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showAllocationDialog({AllocationEntity? current}) async {
    if (_budget.incomeSources.isEmpty) return;
    final nameController = TextEditingController(text: current?.name ?? '');
    var selectedIcon = current?.icon ?? 'category';
    var selectedColor = current?.iconColor ?? '#165b47';
    var rollover = current?.rolloverBehavior ?? 'to-savings';
    var funding = List<AllocationFundingEntity>.from(
      current?.funding ??
          [
            AllocationFundingEntity(
              id: _id('fund'),
              incomeSourceId: _budget.incomeSources.first.id,
              plannedAmount: 0,
            ),
          ],
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(current == null ? 'ط¥ط¶ط§ظپط© ظ…ط®طµطµ ط¬ط¯ظٹط¯' : 'طھط¹ط¯ظٹظ„ ط§ظ„ظ…ط®طµطµ'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'ط§ط³ظ… ط§ظ„ظ…ط®طµطµ'),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final picked = await AppIconPickerDialog.show(
                              context,
                              initialIconName: selectedIcon,
                              initialColorHex: selectedColor,
                              title: 'ط§ط®طھظٹط§ط± ط£ظٹظ‚ظˆظ†ط© ط§ظ„ظ…ط®طµطµ',
                            );
                            if (picked == null) return;
                            setDialogState(() {
                              selectedIcon = picked.iconName;
                              selectedColor = picked.colorHex;
                            });
                          },
                          icon: const Icon(Icons.palette_outlined),
                          label: const Text('ط§ط®طھظٹط§ط± ط§ظ„ط£ظٹظ‚ظˆظ†ط© ظˆط§ظ„ظ„ظˆظ†'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: rollover,
                        decoration: const InputDecoration(
                            labelText: 'ط³ظ„ظˆظƒ ط§ظ„ط¨ط§ظ‚ظٹ ط¢ط®ط± ط§ظ„ط¯ظˆط±ط©'),
                        items: const [
                          DropdownMenuItem(
                            value: 'keep',
                            child: Text('ظٹط³طھظ…ط± ظ„ظ„ط¯ظˆط±ط© ط§ظ„ط¬ط¯ظٹط¯ط©'),
                          ),
                          DropdownMenuItem(
                            value: 'to-savings',
                            child: Text('ظٹطھط­ظˆظ„ ظ„ظ„طھظˆظپظٹط±'),
                          ),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => rollover = v);
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Expanded(child: Text('ظ…طµط§ط¯ط± ط§ظ„طھظ…ظˆظٹظ„')),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                funding = [
                                  ...funding,
                                  AllocationFundingEntity(
                                    id: _id('fund'),
                                    incomeSourceId:
                                        _budget.incomeSources.first.id,
                                    plannedAmount: 0,
                                  ),
                                ];
                              });
                            },
                            child: const Text('ط¥ط¶ط§ظپط© ظ…طµط¯ط±'),
                          ),
                        ],
                      ),
                      ...funding.map(
                        (item) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: DropdownButtonFormField<String>(
                                  initialValue: item.incomeSourceId,
                                  items: _budget.incomeSources
                                      .map(
                                        (income) => DropdownMenuItem(
                                          value: income.id,
                                          child: Text(income.name),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setDialogState(() {
                                      funding = funding
                                          .map(
                                            (f) => f.id == item.id
                                                ? AllocationFundingEntity(
                                                    id: f.id,
                                                    incomeSourceId: v,
                                                    plannedAmount:
                                                        f.plannedAmount,
                                                  )
                                                : f,
                                          )
                                          .toList();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue:
                                      item.plannedAmount.toStringAsFixed(0),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                      labelText: 'ط§ظ„ظ…ط¨ظ„ط؛'),
                                  onChanged: (v) {
                                    final n = double.tryParse(v) ?? 0;
                                    setDialogState(() {
                                      funding = funding
                                          .map(
                                            (f) => f.id == item.id
                                                ? AllocationFundingEntity(
                                                    id: f.id,
                                                    incomeSourceId:
                                                        f.incomeSourceId,
                                                    plannedAmount: n,
                                                  )
                                                : f,
                                          )
                                          .toList();
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: funding.length == 1
                                    ? null
                                    : () => setDialogState(() {
                                          funding = funding
                                              .where((f) => f.id != item.id)
                                              .toList();
                                        }),
                                icon: const Icon(Icons.delete_outline),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('ط¥ظ„ط؛ط§ط،'),
                ),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final cleaned = funding
                        .where((f) =>
                            f.incomeSourceId.isNotEmpty && f.plannedAmount > 0)
                        .toList();
                    if (name.isEmpty || cleaned.isEmpty) return;
                    final allocation = AllocationEntity(
                      id: current?.id ?? _id('alloc'),
                      name: name,
                      icon: selectedIcon,
                      iconColor: selectedColor,
                      rolloverBehavior: rollover,
                      funding: cleaned,
                      categories: current?.categories ?? const [],
                    );
                    final next = current == null
                        ? [..._budget.allocations, allocation]
                        : _budget.allocations
                            .map((e) => e.id == current.id ? allocation : e)
                            .toList();
                    _saveBudget(_budget.copyWith(allocations: next));
                    Navigator.pop(context);
                  },
                  child: const Text('طھظ…'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showLinkedDialog({LinkedWalletEntity? current}) async {
    if (_budget.incomeSources.isEmpty) return;
    final nameController = TextEditingController(text: current?.name ?? '');
    var selectedIcon = current?.icon ?? 'savings';
    var selectedColor = current?.iconColor ?? '#0f766e';
    final amountController = TextEditingController(
        text: (current?.monthlyAmount ?? 0).toStringAsFixed(0));
    final dayController =
        TextEditingController(text: (current?.executionDay ?? 1).toString());
    var fundingSource =
        current?.fundingSource ?? _budget.incomeSources.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(current == null ? 'ط¥ط¶ط§ظپط© ط­طµط§ظ„ط©' : 'طھط¹ط¯ظٹظ„ ط§ظ„ط­طµط§ظ„ط©'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'ط§ط³ظ… ط§ظ„ط­طµط§ظ„ط©'),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final picked = await AppIconPickerDialog.show(
                      context,
                      initialIconName: selectedIcon,
                      initialColorHex: selectedColor,
                      title: 'ط§ط®طھظٹط§ط± ط£ظٹظ‚ظˆظ†ط© ط§ظ„ط­طµط§ظ„ط©',
                    );
                    if (picked == null) return;
                    setDialogState(() {
                      selectedIcon = picked.iconName;
                      selectedColor = picked.colorHex;
                    });
                  },
                  icon: const Icon(Icons.palette_outlined),
                  label: const Text('ط§ط®طھظٹط§ط± ط§ظ„ط£ظٹظ‚ظˆظ†ط© ظˆط§ظ„ظ„ظˆظ†'),
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ط§ظ„طھظ…ظˆظٹظ„ ط§ظ„ط´ظ‡ط±ظٹ'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ظٹظˆظ… ط§ظ„طھظ†ظپظٹط°'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: fundingSource,
                decoration: const InputDecoration(labelText: 'ظ…طµط¯ط± ط§ظ„طھظ…ظˆظٹظ„'),
                items: _budget.incomeSources
                    .map(
                      (income) => DropdownMenuItem(
                          value: income.id, child: Text(income.name)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => fundingSource = v);
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ط¥ظ„ط؛ط§ط،'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                final day =
                    (int.tryParse(dayController.text.trim()) ?? 1).clamp(1, 31);
                if (name.isEmpty || amount <= 0) return;
                final entity = LinkedWalletEntity(
                  id: current?.id ?? _id('linked'),
                  name: name,
                  balance: current?.balance ?? 0,
                  monthlyAmount: amount,
                  executionDay: day,
                  fundingSource: fundingSource,
                  funding: current?.funding ??
                      [
                        LinkedWalletEntityFunding(
                          id: _id('fund-linked'),
                          incomeSourceId: fundingSource,
                          plannedAmount: amount,
                        ),
                      ],
                  icon: selectedIcon,
                  iconColor: selectedColor,
                  automationType: current?.automationType ?? 'confirm',
                  categories: current?.categories ?? const [],
                );
                final next = current == null
                    ? [..._budget.linkedWallets, entity]
                    : _budget.linkedWallets
                        .map((e) => e.id == current.id ? entity : e)
                        .toList();
                _saveBudget(_budget.copyWith(linkedWallets: next));
                Navigator.pop(context);
              },
              child: const Text('طھظ…'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDebtDialog({DebtEntity? current}) async {
    if (_budget.incomeSources.isEmpty) return;
    final nameController = TextEditingController(text: current?.name ?? '');
    final amountController =
        TextEditingController(text: (current?.amount ?? 0).toStringAsFixed(0));
    final dayController =
        TextEditingController(text: (current?.executionDay ?? 1).toString());
    var type = current?.type ?? 'confirm';
    var fundingSource =
        current?.fundingSource ?? _budget.incomeSources.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(
              current == null ? 'ط¥ط¶ط§ظپط© ط¯ظٹظ† ط£ظˆ ظ‚ط³ط·' : 'طھط¹ط¯ظٹظ„ ط§ظ„ط¯ظٹظ† ط£ظˆ ط§ظ„ظ‚ط³ط·'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'ط§ظ„ط§ط³ظ…'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ط§ظ„ظ‚ظٹظ…ط© ط§ظ„ط´ظ‡ط±ظٹط©'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'ظٹظˆظ… ط§ظ„طھظ†ظپظٹط°'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'ظ†ظˆط¹ ط§ظ„طھظ†ظپظٹط°'),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('طھظ„ظ‚ط§ط¦ظٹ')),
                  DropdownMenuItem(value: 'confirm', child: Text('طھط£ظƒظٹط¯')),
                  DropdownMenuItem(value: 'manual', child: Text('ظٹط¯ظˆظٹ')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => type = v);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: fundingSource,
                decoration: const InputDecoration(labelText: 'ظٹظ…ظˆظ„ ظ…ظ†'),
                items: _budget.incomeSources
                    .map(
                      (income) => DropdownMenuItem(
                          value: income.id, child: Text(income.name)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => fundingSource = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ط¥ظ„ط؛ط§ط،'),
            ),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                final day =
                    (int.tryParse(dayController.text.trim()) ?? 1).clamp(1, 31);
                if (name.isEmpty || amount <= 0) return;
                final entity = DebtEntity(
                  id: current?.id ?? _id('debt'),
                  name: name,
                  amount: amount,
                  executionDay: day,
                  type: type,
                  fundingSource: fundingSource,
                );
                final next = current == null
                    ? [..._budget.debts, entity]
                    : _budget.debts
                        .map((e) => e.id == current.id ? entity : e)
                        .toList();
                _saveBudget(_budget.copyWith(debts: next));
                Navigator.pop(context);
              },
              child: const Text('طھظ…'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
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
                '??? ??????',
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
                      label: '?????? ?????',
                      value: _totalIncome,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _summaryMini(
                      label: '?????? ??????',
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
                '????? ??????',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '??? ??? ????? ?????? ?????? ????? ????? ?????? ?????? ??? ??????.',
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
                      labelText: '????? ??????',
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
                      labelText: '????? ?????',
                      prefixIcon: Icon(Icons.autorenew_rounded),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'auto', child: Text('??????')),
                      DropdownMenuItem(
                        value: 'confirm',
                        child: Text('??? ???????'),
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
                  labelText: '?????? ??? ?????? ??? ??????',
                  prefixIcon: Icon(Icons.savings_rounded),
                ),
                items: const [
                  DropdownMenuItem(
                      value: 'to-savings', child: Text('????? ???????')),
                  DropdownMenuItem(
                      value: 'keep', child: Text('???? ?????? ???????')),
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
          title: '????? ?????',
          subtitle: '?? ???? ??? ???? ???? ????? ??????? ???????.',
          icon: Icons.south_west_rounded,
          accent: const Color(0xFF0F9D7A),
          actionLabel: '????? ???',
          onAction: () => _showIncomeDialog(),
          children: _budget.incomeSources.isEmpty
              ? [_emptyState('??? ??? ??? ????? ????? ?????????.')]
              : _budget.incomeSources
                  .map(
                    (income) => _planTile(
                      title: income.name,
                      subtitle: income.isVariable
                          ? '??? ??? ???? ??? ?????? ??????'
                          : '${_incomeTypeLabel(income.type)} ? ??? ${income.date} ? ${income.amount.toStringAsFixed(2)}',
                      leading: Icons.payments_rounded,
                      tint: const Color(0xFF0F9D7A),
                      onTap: () => _showIncomeDialog(current: income),
                      onDelete: income.isDefault
                          ? null
                          : () async {
                              final linked = widget
                                  .cubit.state.recurringTransactions
                                  .where((r) => r.incomeSourceId == income.id)
                                  .toList();
                              for (final rec in linked) {
                                await widget.cubit
                                    .deleteRecurringTransaction(rec.id);
                              }
                              final next = _budget.incomeSources
                                  .where((e) => e.id != income.id)
                                  .toList();
                              await _saveBudget(
                                  _budget.copyWith(incomeSources: next));
                            },
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 14),
        _plannerSection(
          title: '????????',
          subtitle: '??? ???????? ??? ???? ????? ??? ????? ?????.',
          icon: Icons.grid_view_rounded,
          accent: const Color(0xFF296BFF),
          actionLabel: '????? ????',
          onAction: () => _showAllocationDialog(),
          children: _budget.allocations.isEmpty
              ? [_emptyState('???? ?????? ??? ????? ?? ????? ?? ?????????.')]
              : _budget.allocations
                  .map(
                    (allocation) => _planTile(
                      title: allocation.name,
                      subtitle:
                          '${allocation.funding.fold<double>(0, (s, f) => s + f.plannedAmount).toStringAsFixed(2)} ? ${allocation.rolloverBehavior == 'keep' ? '???? ?????? ???????' : '???? ???????'}',
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
          title: '????????',
          subtitle: '????? ????? ????? ??????? ?? ?????? ????????.',
          icon: Icons.savings_rounded,
          accent: const Color(0xFFE09F1F),
          actionLabel: '????? ?????',
          onAction: () => _showLinkedDialog(),
          children: _budget.linkedWallets.isEmpty
              ? [_emptyState('??? ??????? ???????? ??? ??????? ?? ?????.')]
              : _budget.linkedWallets
                  .map(
                    (wallet) => _planTile(
                      title: wallet.name,
                      subtitle:
                          '${wallet.monthlyAmount.toStringAsFixed(2)} ? ??? ${wallet.executionDay}',
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
          title: '?????? ????????',
          subtitle: '???????? ????? ????? ????? ???? ????? ????? ????.',
          icon: Icons.receipt_long_rounded,
          accent: const Color(0xFFC65D2E),
          actionLabel: '????? ??? ?? ???',
          onAction: () => _showDebtDialog(),
          children: _budget.debts.isEmpty
              ? [
                  _emptyState(
                      '??? ??????? ?? ?????? ??????? ??? ???? ??? ??????????.')
                ]
              : _budget.debts
                  .map(
                    (debt) => _planTile(
                      title: debt.name,
                      subtitle:
                          '${debt.amount.toStringAsFixed(2)} ? ??? ${debt.executionDay}',
                      leading: Icons.credit_card_rounded,
                      tint: const Color(0xFFC65D2E),
                      onTap: () => _showDebtDialog(current: debt),
                      onDelete: () {
                        _saveBudget(
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
    VoidCallback? onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: tint.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: tint.withValues(alpha: 0.14)),
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: tint.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(leading, color: tint, size: 20),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(subtitle),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.edit_outlined, color: tint, size: 20),
            if (onDelete != null)
              IconButton(
                onPressed: onDelete,
                icon: const Icon(Icons.delete_outline),
              ),
          ],
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
        return '??????';
      case 'auto':
        return '????';
      case 'manual':
        return '??? ???????';
      default:
        return 'ط¨ط¹ط¯ ط§ظ„طھط£ظƒظٹط¯';
    }
  }
}
