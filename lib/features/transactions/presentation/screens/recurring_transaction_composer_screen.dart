import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon_picker_dialog.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../../budget/domain/entities/budget_setup_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../domain/entities/recurring_transaction_entity.dart';

class RecurringTransactionComposerScreen extends StatefulWidget {
  const RecurringTransactionComposerScreen({
    super.key,
    required this.cubit,
    required this.initialType,
    this.initialRecurring,
  });

  final AppCubit cubit;
  final String initialType;
  final RecurringTransactionEntity? initialRecurring;

  @override
  State<RecurringTransactionComposerScreen> createState() =>
      _RecurringTransactionComposerScreenState();
}

class _RecurringTransactionComposerScreenState
    extends State<RecurringTransactionComposerScreen> {
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();

  late String _type;
  late String _walletId;
  late bool _withinBudget;
  late String _executionType;
  late String _recurrencePattern;
  late String _iconName;
  late String _iconColor;

  bool _isVariableIncome = false;
  bool _isDebtOrSubscription = true;
  bool _isSaving = false;
  int _monthlyDay = 1;
  int _yearlyMonth = 1;
  int _yearlyDay = 1;
  int _reminderLeadDays = 0;
  TimeOfDay _selectedTime = const TimeOfDay(hour: 9, minute: 0);
  final Set<int> _selectedWeekdays = <int>{};
  final Set<String> _selectedCategoryIds = <String>{};
  String? _allocationId;
  String? _targetJarId;

  @override
  void initState() {
    super.initState();
    final state = widget.cubit.state;
    final recurring = widget.initialRecurring;
    _type = recurring?.type ?? widget.initialType;
    _walletId = recurring?.walletId ??
        (state.wallets.isNotEmpty ? state.wallets.first.id : '');
    _withinBudget =
        (recurring?.budgetScope ?? 'outside-budget') == 'within-budget';
    _executionType = recurring?.executionType ?? 'confirm';
    _recurrencePattern = recurring?.recurrencePattern ?? 'monthly';
    _iconName = recurring?.icon ?? (_type == 'income' ? 'cash' : 'category');
    _iconColor =
        recurring?.iconColor ?? (_type == 'income' ? '#0f9d7a' : '#c65d2e');
    _nameController.text = recurring?.name ?? '';
    _amountController.text = recurring == null
        ? ''
        : recurring.amount <= 0
            ? ''
            : recurring.amount.toStringAsFixed(2);
    _notesController.text = recurring?.notes ?? '';
    _isVariableIncome = recurring?.isVariableIncome ?? false;
    _isDebtOrSubscription = recurring?.isDebtOrSubscription ?? true;
    _monthlyDay = (recurring?.dayOfMonth ?? 1).clamp(1, 28);
    _yearlyDay = (recurring?.dayOfMonth ?? 1).clamp(1, 28);
    _yearlyMonth = (recurring?.monthOfYear ?? DateTime.now().month).clamp(1, 12);
    _reminderLeadDays = recurring?.reminderLeadDays ?? 0;
    _allocationId = recurring?.allocationId;
    _targetJarId = recurring?.targetJarId;
    _selectedCategoryIds.addAll(recurring?.categoryIds ?? const <String>[]);
    _selectedWeekdays.addAll(
      recurring?.weekdays.isNotEmpty == true
          ? recurring!.weekdays
          : recurring?.weekday != null
              ? <int>{recurring!.weekday!}
              : <int>{DateTime.now().weekday},
    );
    _selectedTime = _parseStoredTime(recurring?.scheduledTime);

    if (_type == 'income' && _withinBudget && _isVariableIncome) {
      _executionType = 'manual';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _showAmount => !(_type == 'income' && _withinBudget && _isVariableIncome);

  bool get _showRecurrenceDetails =>
      !(_type == 'income' && _withinBudget && _isVariableIncome);

  bool get _isWeekPattern =>
      _recurrencePattern == 'weekly' ||
      _recurrencePattern == 'biweekly' ||
      _recurrencePattern == 'every_3_weeks';

  bool get _isMonthPattern =>
      _recurrencePattern == 'monthly' ||
      _recurrencePattern == 'every_2_months' ||
      _recurrencePattern == 'every_3_months' ||
      _recurrencePattern == 'every_6_months';

  bool get _canSave {
    if (_isSaving || _nameController.text.trim().isEmpty || _walletId.isEmpty) {
      return false;
    }
    if (_showAmount &&
        (double.tryParse(_amountController.text.trim()) ?? 0) <= 0) {
      return false;
    }
    if (_type == 'expense' &&
        _withinBudget &&
        !_isDebtOrSubscription &&
        _allocationId == null &&
        _targetJarId == null) {
      return false;
    }
    if (_showRecurrenceDetails && _isWeekPattern && _selectedWeekdays.isEmpty) {
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final state = widget.cubit.state;
    final budget = state.budgetSetup;
    final wallets = state.wallets;
    final visibleCategories = _visibleCategories(state.categories, budget);

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      appBar: AppBar(
        title: Text(widget.initialRecurring == null
            ? 'إضافة معاملة متكررة'
            : 'تعديل معاملة متكررة'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            _typeSwitcher(theme),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'اسم المعاملة',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 12),
            if (_type == 'income' && _withinBudget) ...[
              _surfaceSection(
                child: SwitchListTile.adaptive(
                  value: _isVariableIncome,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('دخل متغير'),
                  subtitle: const Text(
                    'الدخل المتغير يكون يدويًا ولا يحتاج مبلغ أو توقيت ثابت',
                  ),
                  onChanged: (value) {
                    setState(() {
                      _isVariableIncome = value;
                      if (value) {
                        _executionType = 'manual';
                        _amountController.clear();
                      }
                    });
                  },
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_showAmount) ...[
              TextField(
                controller: _amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'المبلغ',
                  prefixIcon: Icon(Icons.payments_rounded),
                ),
              ),
              const SizedBox(height: 12),
            ],
            DropdownButtonFormField<String>(
              value: _walletId.isEmpty ? null : _walletId,
              decoration: const InputDecoration(
                labelText: 'المحفظة',
                prefixIcon: Icon(Icons.account_balance_wallet_rounded),
              ),
              items: wallets
                  .map(
                    (wallet) => DropdownMenuItem<String>(
                      value: wallet.id,
                      child: Text(wallet.name),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _walletId = value);
                }
              },
            ),
            const SizedBox(height: 12),
            _surfaceSection(
              child: SwitchListTile.adaptive(
                value: _withinBudget,
                contentPadding: EdgeInsets.zero,
                title: const Text('داخل الميزانية'),
                subtitle: Text(
                  _withinBudget
                      ? 'المعاملة ستدخل في تخطيط الميزانية'
                      : 'المعاملة ستبقى خارج حسابات الميزانية',
                ),
                onChanged: (value) {
                  setState(() {
                    _withinBudget = value;
                    if (!value) {
                      _allocationId = null;
                      _targetJarId = null;
                      _isDebtOrSubscription = false;
                      _isVariableIncome = false;
                    } else if (_type == 'expense') {
                      _isDebtOrSubscription = true;
                    }
                  });
                },
              ),
            ),
            const SizedBox(height: 12),
            if (_withinBudget) ...[
              _surfaceSection(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('الأيقونة واللون'),
                  subtitle: const Text('تظهر داخل التخطيط والميزانية'),
                  leading: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: _parseColor(_iconColor).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: AppIconPickerDialog.iconWidgetForName(
                      _iconName,
                      color: _parseColor(_iconColor),
                      size: 22,
                    ),
                  ),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: _pickIcon,
                ),
              ),
              const SizedBox(height: 12),
            ],
            if (_type == 'expense' && _withinBudget) ...[
              _budgetTargetSection(budget),
              const SizedBox(height: 12),
            ],
            _categorySection(visibleCategories),
            const SizedBox(height: 12),
            if (_showRecurrenceDetails) ...[
              DropdownButtonFormField<String>(
                value: _recurrencePattern,
                decoration: const InputDecoration(
                  labelText: 'نوع التكرار',
                  prefixIcon: Icon(Icons.repeat_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'daily', child: Text('يومي')),
                  DropdownMenuItem(value: 'weekly', child: Text('أسبوعي')),
                  DropdownMenuItem(value: 'biweekly', child: Text('كل أسبوعين')),
                  DropdownMenuItem(value: 'every_3_weeks', child: Text('كل 3 أسابيع')),
                  DropdownMenuItem(value: 'monthly', child: Text('شهري')),
                  DropdownMenuItem(value: 'every_2_months', child: Text('كل شهرين')),
                  DropdownMenuItem(value: 'every_3_months', child: Text('كل 3 شهور')),
                  DropdownMenuItem(value: 'every_6_months', child: Text('كل 6 شهور')),
                  DropdownMenuItem(value: 'yearly', child: Text('سنوي')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _recurrencePattern = value);
                  }
                },
              ),
              const SizedBox(height: 12),
              _recurrenceDetails(),
              const SizedBox(height: 12),
            ],
            if (_type == 'income' && _withinBudget && _isVariableIncome)
              _surfaceSection(
                child: const ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(Icons.info_outline_rounded),
                  title: Text('دخل متغير'),
                  subtitle: Text(
                    'سيتم تسجيله يدويًا فقط بدون تاريخ أو تكرار ثابت',
                  ),
                ),
              )
            else ...[
              DropdownButtonFormField<String>(
                value: _executionType,
                decoration: const InputDecoration(
                  labelText: 'طريقة التنفيذ',
                  prefixIcon: Icon(Icons.bolt_rounded),
                ),
                items: const [
                  DropdownMenuItem(value: 'auto', child: Text('تلقائي')),
                  DropdownMenuItem(value: 'confirm', child: Text('يحتاج تأكيد')),
                ],
                onChanged: (value) {
                  if (value != null) {
                    setState(() => _executionType = value);
                  }
                },
              ),
              if (_executionType == 'confirm') ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  value: _reminderLeadDays,
                  decoration: const InputDecoration(
                    labelText: 'وقت الإشعار',
                    prefixIcon: Icon(Icons.notifications_active_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('في نفس اليوم')),
                    DropdownMenuItem(value: 1, child: Text('مبكر بيوم')),
                    DropdownMenuItem(value: 2, child: Text('مبكر بيومين')),
                    DropdownMenuItem(value: 3, child: Text('مبكر بـ 3 أيام')),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _reminderLeadDays = value);
                    }
                  },
                ),
              ],
            ],
            const SizedBox(height: 12),
            TextField(
              controller: _notesController,
              minLines: 3,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'ملاحظات',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 18),
            FilledButton(
              onPressed: _canSave ? _save : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Text(_isSaving
                    ? 'جارٍ الحفظ...'
                    : widget.initialRecurring == null
                        ? 'حفظ المعاملة المتكررة'
                        : 'تحديث المعاملة المتكررة'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeSwitcher(ThemeData theme) {
    final isIncome = _type == 'income';
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Expanded(
            child: _switcherItem(
              selected: !isIncome,
              label: 'مصروف',
              icon: Icons.arrow_outward_rounded,
              onTap: () {
                setState(() {
                  _type = 'expense';
                  if (_withinBudget) {
                    _isDebtOrSubscription = true;
                  }
                });
              },
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _switcherItem(
              selected: isIncome,
              label: 'دخل',
              icon: Icons.arrow_downward_rounded,
              onTap: () {
                setState(() {
                  _type = 'income';
                  _allocationId = null;
                  _targetJarId = null;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _switcherItem({
    required bool selected,
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    return Material(
      color: selected ? theme.colorScheme.primary : Colors.transparent,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Icon(icon, color: selected ? Colors.white : theme.colorScheme.onSurface),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : theme.colorScheme.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _surfaceSection({required Widget child}) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.45),
        ),
      ),
      child: child,
    );
  }
