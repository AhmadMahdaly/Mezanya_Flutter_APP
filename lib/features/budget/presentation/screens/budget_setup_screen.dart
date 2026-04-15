import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon_picker_dialog.dart';
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
    final fallbackWalletId =
        wallets.isNotEmpty ? wallets.first.id : 'wallet-cash-default';
    final nameController = TextEditingController(text: current?.name ?? '');
    final amountController =
        TextEditingController(text: (current?.amount ?? 0).toStringAsFixed(0));
    final dayController = TextEditingController(
        text: (current?.date ?? _budget.startDay).toString());
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
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(labelText: 'اسم الدخل'),
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: isVariable ? 'variable' : 'fixed',
                      decoration:
                          const InputDecoration(labelText: 'طبيعة الدخل'),
                      items: const [
                        DropdownMenuItem(value: 'fixed', child: Text('ثابت')),
                        DropdownMenuItem(
                            value: 'variable', child: Text('غير ثابت')),
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
                        decoration:
                            const InputDecoration(labelText: 'يوم الإضافة'),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: type,
                        decoration:
                            const InputDecoration(labelText: 'نوع التنفيذ'),
                        items: const [
                          DropdownMenuItem(
                              value: 'auto', child: Text('تلقائي')),
                          DropdownMenuItem(
                              value: 'confirm', child: Text('تأكيد')),
                          DropdownMenuItem(
                              value: 'manual', child: Text('يدوي')),
                        ],
                        onChanged: (v) {
                          if (v != null) setDialogState(() => type = v);
                        },
                      ),
                    ],
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: walletId,
                      decoration: const InputDecoration(
                          labelText: 'تنزل في محفظة فعلية'),
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
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
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
              title: Text(current == null ? 'إضافة مخصص جديد' : 'تعديل المخصص'),
              content: SizedBox(
                width: 500,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameController,
                        decoration:
                            const InputDecoration(labelText: 'اسم المخصص'),
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
                              title: 'اختيار أيقونة المخصص',
                            );
                            if (picked == null) return;
                            setDialogState(() {
                              selectedIcon = picked.iconName;
                              selectedColor = picked.colorHex;
                            });
                          },
                          icon: const Icon(Icons.palette_outlined),
                          label: const Text('اختيار الأيقونة واللون'),
                        ),
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        initialValue: rollover,
                        decoration: const InputDecoration(
                            labelText: 'سلوك الباقي آخر الدورة'),
                        items: const [
                          DropdownMenuItem(
                            value: 'keep',
                            child: Text('يستمر للدورة الجديدة'),
                          ),
                          DropdownMenuItem(
                            value: 'to-savings',
                            child: Text('يتحول للتوفير'),
                          ),
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
                                    incomeSourceId:
                                        _budget.incomeSources.first.id,
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
                                      labelText: 'المبلغ'),
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
                  child: const Text('إلغاء'),
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
          title: Text(current == null ? 'إضافة حصالة' : 'تعديل الحصالة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'اسم الحصالة'),
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
                    title: 'اختيار أيقونة الحصالة',
                  );
                  if (picked == null) return;
                  setDialogState(() {
                    selectedIcon = picked.iconName;
                    selectedColor = picked.colorHex;
                  });
                },
                icon: const Icon(Icons.palette_outlined),
                label: const Text('اختيار الأيقونة واللون'),
              ),
            ),
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
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () {
              final name = nameController.text.trim();
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
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
              child: const Text('تم'),
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
              current == null ? 'إضافة دين أو قسط' : 'تعديل الدين أو القسط'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'الاسم'),
              ),
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
              child: const Text('إلغاء'),
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
              child: const Text('تم'),
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
    final unallocatedColor =
        _unallocated >= 0 ? const Color(0xFF0F9D7A) : const Color(0xFFC65D2E);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF123E3A), Color(0xFF1E5D57), Color(0xFF2E7D73)],
              begin: Alignment.topRight,
              end: Alignment.bottomLeft,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF123E3A).withValues(alpha: 0.22),
                blurRadius: 30,
                offset: const Offset(0, 18),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'خطة الميزانية',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'وزّع دخلك بين المخصصات والحصالات والالتزامات، وخلّي الباقي واضح من أول الشهر.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  _metricChip(
                    icon: Icons.account_balance_wallet_rounded,
                    label: 'إجمالي الدخل',
                    value: _totalIncome,
                    textColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                  ),
                  _metricChip(
                    icon: Icons.layers_rounded,
                    label: 'الالتزامات',
                    value: _committed,
                    textColor: Colors.white,
                    backgroundColor: Colors.white.withValues(alpha: 0.12),
                  ),
                  _metricChip(
                    icon: _unallocated >= 0
                        ? Icons.check_circle_rounded
                        : Icons.warning_amber_rounded,
                    label: 'غير المخصص',
                    value: _unallocated,
                    textColor: Colors.white,
                    backgroundColor: unallocatedColor.withValues(alpha: 0.24),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: colorScheme.outlineVariant.withValues(alpha: 0.5),
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
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
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
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _budget.cycleMode,
                      decoration: const InputDecoration(
                        labelText: 'تجديد الخطة',
                        prefixIcon: Icon(Icons.autorenew_rounded),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'auto', child: Text('تلقائي')),
                        DropdownMenuItem(
                            value: 'confirm', child: Text('بعد التأكيد')),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          _saveBudget(_budget.copyWith(cycleMode: value));
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
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
          subtitle: 'كل مصدر دخل يحدد موعد نزوله ومحفظته الفعلية.',
          icon: Icons.south_west_rounded,
          accent: const Color(0xFF0F9D7A),
          actionLabel: 'إضافة دخل',
          onAction: () => _showIncomeDialog(),
          children: _budget.incomeSources.isEmpty
              ? [_emptyState('أضف أول دخل لتبدأ توزيع الميزانية.')]
              : _budget.incomeSources
                  .map(
                    (income) => _planTile(
                      title: income.name,
                      subtitle: income.isVariable
                          ? 'دخل غير ثابت يتم تسجيله يدويًا'
                          : '${_incomeTypeLabel(income.type)} • يوم ${income.date} • ${income.amount.toStringAsFixed(2)}',
                      leading: Icons.payments_rounded,
                      tint: const Color(0xFF0F9D7A),
                      onTap: () => _showIncomeDialog(current: income),
                      onDelete: income.isDefault
                          ? null
                          : () {
                              final next = _budget.incomeSources
                                  .where((e) => e.id != income.id)
                                  .toList();
                              _saveBudget(
                                  _budget.copyWith(incomeSources: next));
                            },
                    ),
                  )
                  .toList(),
        ),
        const SizedBox(height: 14),
        _plannerSection(
          title: 'المخصصات',
          subtitle: 'قسم ميزانيتك على بنود واضحة قبل بداية الصرف.',
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

  Widget _metricChip({
    required IconData icon,
    required String label,
    required double value,
    required Color textColor,
    required Color backgroundColor,
  }) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: textColor, size: 18),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.82),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value.toStringAsFixed(2),
                style: TextStyle(
                  color: textColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
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
    switch (type) {
      case 'auto':
        return 'تلقائي';
      case 'manual':
        return 'يدوي';
      default:
        return 'بعد التأكيد';
    }
  }
}
