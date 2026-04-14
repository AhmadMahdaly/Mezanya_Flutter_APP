import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_state/domain/entities/app_state_entity.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../domain/entities/goal_entity.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({super.key, required this.cubit});

  final AppCubit cubit;

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.cubit.ensureDefaultSavingsJar();
    });
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStateEntity>(
      stream: widget.cubit.stream,
      initialData: widget.cubit.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? widget.cubit.state;
        final savingsJar = state.budgetSetup.linkedWallets.where((w) => w.id == 'linked-savings-default').toList();
        final jar = savingsJar.isNotEmpty ? savingsJar.first : null;
        final savedAmount = jar?.balance ?? 0;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: FilledButton.icon(
                onPressed: () => _openGoalDialog(state),
                icon: const Icon(Icons.add),
                label: const Text('إضافة هدف'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('حصالة التوفير', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 6),
                    Text(
                      savedAmount.toStringAsFixed(2),
                      style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      jar == null ? 'سيتم إنشاؤها تلقائيا.' : 'الرصيد المتوفر حاليا لتحقيق الأهداف.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            ...state.goals.map((goal) => _goalCard(state, goal, savedAmount)),
            if (state.goals.isEmpty)
              const Card(
                child: ListTile(
                  title: Text('لا توجد أهداف بعد.'),
                  subtitle: Text('ابدأ بإضافة هدفك الأول.'),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _goalCard(AppStateEntity state, GoalEntity goal, double savedAmount) {
    final progress = goal.targetAmount <= 0 ? 0.0 : (savedAmount / goal.targetAmount).clamp(0.0, 1.0);
    final isCompleted = progress >= 1;
    final remaining = (goal.targetAmount - savedAmount).clamp(0.0, goal.targetAmount);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(goal.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                ),
                IconButton(
                  onPressed: () => _openGoalDialog(state, current: goal),
                  icon: const Icon(Icons.edit_outlined),
                ),
              ],
            ),
            Text('الهدف: ${goal.targetAmount.toStringAsFixed(2)}'),
            Text('المتبقي: ${remaining.toStringAsFixed(2)}'),
            Text('المدة: ${DateFormat('d/M/yyyy').format(goal.startDate)} - ${DateFormat('d/M/yyyy').format(goal.endDate)}'),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 9,
                color: isCompleted ? Colors.green : Theme.of(context).colorScheme.primary,
                backgroundColor: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.12),
              ),
            ),
            const SizedBox(height: 8),
            Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => _openAchieveDialog(state, goal),
                icon: const Icon(Icons.emoji_events_outlined),
                label: Text(isCompleted ? 'تحقيق الهدف' : 'تسجيل تحقيق جزئي'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openGoalDialog(AppStateEntity state, {GoalEntity? current}) async {
    final nameController = TextEditingController(text: current?.name ?? '');
    final amountController =
        TextEditingController(text: (current?.targetAmount ?? 0).toStringAsFixed(0));
    final notesController = TextEditingController(text: current?.notes ?? '');
    var startDate = current?.startDate ?? DateTime.now();
    var endDate = current?.endDate ?? DateTime.now().add(const Duration(days: 90));

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(current == null ? 'إضافة هدف' : 'تعديل الهدف'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'اسم الهدف')),
                const SizedBox(height: 8),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'قيمة الهدف'),
                ),
                const SizedBox(height: 8),
                ListTile(
                  title: const Text('بداية الهدف'),
                  subtitle: Text(DateFormat('d/M/yyyy').format(startDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => startDate = picked);
                  },
                ),
                ListTile(
                  title: const Text('نهاية الهدف'),
                  subtitle: Text(DateFormat('d/M/yyyy').format(endDate)),
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: endDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2100),
                    );
                    if (picked != null) setDialogState(() => endDate = picked);
                  },
                ),
                const SizedBox(height: 8),
                TextField(controller: notesController, decoration: const InputDecoration(labelText: 'ملاحظات')),
              ],
            ),
          ),
          actions: [
            if (current != null)
              TextButton(
                onPressed: () async {
                  await widget.cubit.deleteGoal(current.id);
                  if (context.mounted) Navigator.pop(context);
                },
                child: Text('حذف', style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final amount = double.tryParse(amountController.text.trim()) ?? 0;
                if (name.isEmpty || amount <= 0) return;
                if (current == null) {
                  await widget.cubit.addGoal(
                    name: name,
                    targetAmount: amount,
                    startDate: startDate,
                    endDate: endDate,
                    notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                  );
                } else {
                  await widget.cubit.updateGoal(
                    current.copyWith(
                      name: name,
                      targetAmount: amount,
                      startDate: startDate,
                      endDate: endDate,
                      notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
                    ),
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(current == null ? 'إضافة' : 'حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openAchieveDialog(AppStateEntity state, GoalEntity goal) async {
    final savingsJar = state.budgetSetup.linkedWallets.where((w) => w.id == 'linked-savings-default').toList();
    if (savingsJar.isEmpty) return;
    final jar = savingsJar.first;
    final amountController = TextEditingController(
      text: (goal.targetAmount <= jar.balance ? goal.targetAmount : jar.balance).toStringAsFixed(2),
    );
    final notesController = TextEditingController(text: 'تحقيق هدف: ${goal.name}');
    await showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تحقيق الهدف'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('الرصيد الحالي في الحصالة: ${jar.balance.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'المبلغ المستخدم لتحقيق الهدف'),
            ),
            const SizedBox(height: 8),
            TextField(controller: notesController, decoration: const InputDecoration(labelText: 'الوصف')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
          FilledButton(
            onPressed: () async {
              final amount = double.tryParse(amountController.text.trim()) ?? 0;
              if (amount <= 0 || amount > jar.balance) return;
              await widget.cubit.addTransaction(
                type: 'expense',
                walletId: jar.id,
                amount: amount,
                budgetScope: 'outside-budget',
                notes: notesController.text.trim().isEmpty ? 'تحقيق هدف ${goal.name}' : notesController.text.trim(),
              );
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('تسجيل العملية'),
          ),
        ],
      ),
    );
  }
}
