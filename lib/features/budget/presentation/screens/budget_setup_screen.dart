import 'package:flutter/material.dart';

import '../../../app_state/presentation/cubits/app_cubit.dart';
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

  double get _totalIncome => _budget.incomeSources.fold(
      0, (sum, income) => sum + (income.isVariable ? 0 : income.amount));
  double get _allocationsTotal => _budget.allocations.fold(
      0, (sum, allocation) => sum + allocation.funding.fold(0, (s, f) => s + f.plannedAmount));
  double get _linkedTotal => _budget.linkedWallets.fold(0, (sum, wallet) => sum + wallet.monthlyAmount);
  double get _debtsTotal => _budget.debts.fold(0, (sum, debt) => sum + debt.amount);
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
    return setup.incomeSources.fold<double>(0, (sum, income) => sum + (income.isVariable ? 0 : income.amount));
  }

  double _committedFrom(BudgetSetupEntity setup) {
    final allocationsTotal = setup.allocations.fold<double>(
      0,
      (sum, allocation) => sum + allocation.funding.fold<double>(0, (s, f) => s + f.plannedAmount),
    );
    final linkedTotal = setup.linkedWallets.fold<double>(0, (sum, wallet) => sum + wallet.monthlyAmount);
    final debtsTotal = setup.debts.fold<double>(0, (sum, debt) => sum + debt.amount);
    return allocationsTotal + linkedTotal + debtsTotal;
  }

  String _id(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Future<void> _showIncomeDialog({IncomeSourceEntity? current}) async {
    final wallets = widget.cubit.state.wallets;
    final fallbackWalletId = wallets.isNotEmpty ? wallets.first.id : 'wallet-cash-default';
    final nameController = TextEditingController(text: current?.name ?? '');
    final amountController = TextEditingController(text: (current?.amount ?? 0).toStringAsFixed(0));
    final dayController = TextEditingController(text: (current?.date ?? _budget.startDay).toString());
    var isVariable = current?.isVariable ?? false;
    var type = current?.type ?? 'confirm';
    var walletId = current?.targetWalletId ?? fallbackWalletId;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(current == null ? 'إضافة دخل جديد' : 'تعديل الدخل'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الدخل')),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: isVariable ? 'variable' : 'fixed',
                      decoration: const InputDecoration(labelText: 'طبيعة الدخل'),
                      items: const [
                        DropdownMenuItem(value: 'fixed', child: Text('ثابت')),
                        DropdownMenuItem(value: 'variable', child: Text('غير ثابت')),
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
                        decoration: const InputDecoration(labelText: 'القيمة'),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: dayController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(labelText: 'يوم الإضافة'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration: const InputDecoration(labelText: 'نوع التنفيذ'),
                        items: const [
                          DropdownMenuItem(value: 'auto', child: Text('تلقائي')),
                          DropdownMenuItem(value: 'confirm', child: Text('تأكيد')),
                          DropdownMenuItem(value: 'manual', child: Text('يدوي')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => type = v);
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: walletId,
                      decoration: const InputDecoration(labelText: 'تنزل في محفظة فعلية'),
                      items: wallets
                          .map((wallet) => DropdownMenuItem(value: wallet.id, child: Text(wallet.name)))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) setDialogState(() => walletId = v);
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final amount = double.tryParse(amountController.text.trim()) ?? 0;
                    final day = (int.tryParse(dayController.text.trim()) ?? _budget.startDay).clamp(1, 31);
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
                        : _budget.incomeSources.map((e) => e.id == current.id ? saved : e).toList();
                    _saveBudget(_budget.copyWith(incomeSources: next));
                    Navigator.pop(context);
                  },
                  child: const Text('تم'),
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
    var rollover = current?.rolloverBehavior ?? 'to-savings';
    var funding = List<AllocationFundingEntity>.from(
      current?.funding ??
          [AllocationFundingEntity(id: _id('fund'), incomeSourceId: _budget.incomeSources.first.id, plannedAmount: 0)],
    );

    await showDialog<void>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(current == null ? 'إضافة مخصص جديد' : 'تعديل المخصص'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم المخصص')),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: rollover,
                        decoration: const InputDecoration(labelText: 'سلوك الباقي آخر الدورة'),
                        items: const [
                          DropdownMenuItem(value: 'keep', child: Text('يستمر للدورة الجديدة')),
                          DropdownMenuItem(value: 'to-savings', child: Text('يتحول للتوفير')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => rollover = v);
                        },
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Expanded(child: Text('مصادر التمويل')),
                          TextButton(
                            onPressed: () {
                              setDialogState(() {
                                funding = [
                                  ...funding,
                                  AllocationFundingEntity(
                                    id: _id('fund'),
                                    incomeSourceId: _budget.incomeSources.first.id,
                                    plannedAmount: 0,
                                  ),
                                ];
                              });
                            },
                            child: const Text('إضافة مصدر'),
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
                                      .map((income) => DropdownMenuItem(value: income.id, child: Text(income.name)))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    setDialogState(() {
                                      funding = funding
                                          .map((f) => f.id == item.id
                                              ? AllocationFundingEntity(
                                                  id: f.id, incomeSourceId: v, plannedAmount: f.plannedAmount)
                                              : f)
                                          .toList();
                                    });
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  initialValue: item.plannedAmount.toStringAsFixed(0),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(labelText: 'المبلغ'),
                                  onChanged: (v) {
                                    final n = double.tryParse(v) ?? 0;
                                    setDialogState(() {
                                      funding = funding
                                          .map((f) => f.id == item.id
                                              ? AllocationFundingEntity(
                                                  id: f.id, incomeSourceId: f.incomeSourceId, plannedAmount: n)
                                              : f)
                                          .toList();
                                    });
                                  },
                                ),
                              ),
                              IconButton(
                                onPressed: funding.length == 1
                                    ? null
                                    : () => setDialogState(() {
                                          funding = funding.where((f) => f.id != item.id).toList();
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
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
                FilledButton(
                  onPressed: () {
                    final name = nameController.text.trim();
                    final cleaned = funding.where((f) => f.incomeSourceId.isNotEmpty && f.plannedAmount > 0).toList();
                    if (name.isEmpty || cleaned.isEmpty) return;
                    final allocation = AllocationEntity(
                      id: current?.id ?? _id('alloc'),
                      name: name,
                      rolloverBehavior: rollover,
                      funding: cleaned,
                      categories: current?.categories ?? const [],
                    );
                    final next = current == null
                        ? [..._budget.allocations, allocation]
                        : _budget.allocations.map((e) => e.id == current.id ? allocation : e).toList();
                    _saveBudget(_budget.copyWith(allocations: next));
                    Navigator.pop(context);
                  },
                  child: const Text('تم'),
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
    final amountController =
        TextEditingController(text: (current?.monthlyAmount ?? 0).toStringAsFixed(0));
    final dayController = TextEditingController(text: (current?.executionDay ?? 1).toString());
    var fundingSource = current?.fundingSource ?? _budget.incomeSources.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(current == null ? 'إضافة حصالة' : 'تعديل الحصالة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الحصالة')),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'التمويل الشهري'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: dayController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'يوم التنفيذ'),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: fundingSource,
              decoration: const InputDecoration(labelText: 'مصدر التمويل'),
              items: _budget.incomeSources
                  .map((income) => DropdownMenuItem(value: income.id, child: Text(income.name)))
                  .toList(),
              onChanged: (v) {
                if (v != null) fundingSource = v;
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              final day = (int.tryParse(dayController.text.trim()) ?? 1).clamp(1, 31);
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
                icon: current?.icon ?? 'PiggyBank',
                iconColor: current?.iconColor ?? '#0f766e',
                automationType: current?.automationType ?? 'confirm',
                categories: current?.categories ?? const [],
              );
              final next = current == null
                  ? [..._budget.linkedWallets, entity]
                  : _budget.linkedWallets.map((e) => e.id == current.id ? entity : e).toList();
              _saveBudget(_budget.copyWith(linkedWallets: next));
              Navigator.pop(context);
            },
            child: const Text('تم'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDebtDialog({DebtEntity? current}) async {
    if (_budget.incomeSources.isEmpty) return;
    final nameController = TextEditingController(text: current?.name ?? '');
    final amountController = TextEditingController(text: (current?.amount ?? 0).toStringAsFixed(0));
    final dayController = TextEditingController(text: (current?.executionDay ?? 1).toString());
    var type = current?.type ?? 'confirm';
    var fundingSource = current?.fundingSource ?? _budget.incomeSources.first.id;

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(current == null ? 'إضافة دين أو قسط' : 'تعديل الدين أو القسط'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'الاسم')),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'القيمة الشهرية'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: dayController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'يوم التنفيذ'),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: type,
                decoration: const InputDecoration(labelText: 'نوع التنفيذ'),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('تلقائي')),
                  DropdownMenuItem(value: 'confirm', child: Text('تأكيد')),
                  DropdownMenuItem(value: 'manual', child: Text('يدوي')),
                ],
                onChanged: (v) {
                  if (v != null) setDialogState(() => type = v);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: fundingSource,
                decoration: const InputDecoration(labelText: 'يمول من'),
                items: _budget.incomeSources
                    .map((income) => DropdownMenuItem(value: income.id, child: Text(income.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialogState(() => fundingSource = v);
                },
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text.trim()) ?? 0;
                final day = (int.tryParse(dayController.text.trim()) ?? 1).clamp(1, 31);
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
                    : _budget.debts.map((e) => e.id == current.id ? entity : e).toList();
                _saveBudget(_budget.copyWith(debts: next));
                Navigator.pop(context);
              },
              child: const Text('تم'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                _stat('إجمالي الدخل', _totalIncome),
                _stat('إجمالي الالتزامات', _committed),
                _stat('غير المخصص', _unallocated),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: _budget.startDay.toString(),
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'بداية الدورة', border: OutlineInputBorder()),
                onFieldSubmitted: (value) {
                  final day = (int.tryParse(value) ?? 1).clamp(1, 31);
                  _saveBudget(_budget.copyWith(startDay: day));
                },
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<String>(
                initialValue: _budget.cycleMode,
                decoration: const InputDecoration(labelText: 'تجديد الخطة', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('تلقائي')),
                  DropdownMenuItem(value: 'confirm', child: Text('يحتاج تأكيد')),
                ],
                onChanged: (value) {
                  if (value != null) _saveBudget(_budget.copyWith(cycleMode: value));
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _sectionTitle('الدخل'),
        FilledButton(
          onPressed: () => _showIncomeDialog(),
          child: const Text('إضافة دخل'),
        ),
        ..._budget.incomeSources.map(
          (income) => ListTile(
            onTap: () => _showIncomeDialog(current: income),
            title: Text(income.name),
            subtitle: Text(
              income.isVariable
                  ? 'دخل غير ثابت'
                  : '${income.type == 'auto' ? 'تلقائي' : income.type == 'confirm' ? 'تأكيد' : 'يدوي'} - يوم ${income.date} - ${income.amount.toStringAsFixed(2)}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_outlined, size: 18),
                if (!income.isDefault)
                  IconButton(
                    onPressed: () {
                      final next = _budget.incomeSources.where((e) => e.id != income.id).toList();
                      _saveBudget(_budget.copyWith(incomeSources: next));
                    },
                    icon: const Icon(Icons.delete_outline),
                  ),
              ],
            ),
          ),
        ),
        const Divider(height: 28),
        _sectionTitle('المخصصات'),
        FilledButton(
          onPressed: () => _showAllocationDialog(),
          child: const Text('إضافة مخصص'),
        ),
        ..._budget.allocations.map(
          (allocation) => ListTile(
            onTap: () => _showAllocationDialog(current: allocation),
            title: Text(allocation.name),
            subtitle: Text(
              '${allocation.funding.fold<double>(0, (s, f) => s + f.plannedAmount).toStringAsFixed(2)} - ${allocation.rolloverBehavior == 'keep' ? 'يستمر' : 'للتوفير'}',
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.edit_outlined, size: 18),
                IconButton(
                  onPressed: () {
                    _saveBudget(
                      _budget.copyWith(allocations: _budget.allocations.where((e) => e.id != allocation.id).toList()),
                    );
                  },
                  icon: const Icon(Icons.delete_outline),
                ),
              ],
            ),
          ),
        ),
        const Divider(height: 28),
        _sectionTitle('الحصالات'),
        FilledButton(
          onPressed: () => _showLinkedDialog(),
          child: const Text('إضافة حصالة'),
        ),
        ..._budget.linkedWallets.map(
          (wallet) => ListTile(
            onTap: () => _showLinkedDialog(current: wallet),
            title: Text(wallet.name),
            subtitle: Text('${wallet.monthlyAmount.toStringAsFixed(2)} - يوم ${wallet.executionDay}'),
            trailing: IconButton(
              onPressed: () {
                _saveBudget(
                  _budget.copyWith(
                    linkedWallets: _budget.linkedWallets.where((e) => e.id != wallet.id).toList(),
                  ),
                );
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ),
        const Divider(height: 28),
        _sectionTitle('الديون والأقساط'),
        FilledButton(
          onPressed: () => _showDebtDialog(),
          child: const Text('إضافة دين/قسط'),
        ),
        ..._budget.debts.map(
          (debt) => ListTile(
            onTap: () => _showDebtDialog(current: debt),
            title: Text(debt.name),
            subtitle: Text('${debt.amount.toStringAsFixed(2)} - يوم ${debt.executionDay}'),
            trailing: IconButton(
              onPressed: () {
                _saveBudget(_budget.copyWith(debts: _budget.debts.where((e) => e.id != debt.id).toList()));
              },
              icon: const Icon(Icons.delete_outline),
            ),
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: _budget.bufferEndBehavior,
          decoration: const InputDecoration(labelText: 'غير المخصص آخر الدورة', border: OutlineInputBorder()),
          items: const [
            DropdownMenuItem(value: 'to-savings', child: Text('يتحول للتوفير')),
            DropdownMenuItem(value: 'keep', child: Text('يفضل للدورة الجديدة')),
          ],
          onChanged: (value) {
            if (value != null) _saveBudget(_budget.copyWith(bufferEndBehavior: value));
          },
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
    );
  }

  Widget _stat(String title, double value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title),
          Text(value.toStringAsFixed(2)),
        ],
      ),
    );
  }
}
