import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon_picker_dialog.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../../app_state/domain/entities/app_state_entity.dart';
import '../../domain/entities/category_entity.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.cubit});

  final AppCubit cubit;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  String _tab = 'expense';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStateEntity>(
      stream: widget.cubit.stream,
      initialData: widget.cubit.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? widget.cubit.state;
        final budget = state.budgetSetup;
        final generalExpense = state.categories
            .where((c) => c.scope == 'expense' && c.incomeSourceId == null)
            .toList();
        final generalIncome = state.categories
            .where((c) => c.scope == 'income' && c.incomeSourceId == null)
            .toList();

        final sections = _tab == 'income'
            ? [
                ...budget.incomeSources.map(
                  (income) => _SectionData(
                    key: 'income-${income.id}',
                    title: income.name,
                    subtitle: income.isVariable ? 'دخل غير ثابت' : 'دخل ثابت',
                    target: _CategoryTarget('income-source', income.id),
                    categories: state.categories
                        .where((c) => c.incomeSourceId == income.id)
                        .toList(),
                  ),
                ),
                _SectionData(
                  key: 'general-income',
                  title: 'فئات دخل عامة',
                  subtitle: 'لأي دخل غير مربوط بمصدر محدد',
                  target: const _CategoryTarget('general-income', 'general-income'),
                  categories: generalIncome,
                ),
              ]
            : [
                ...budget.allocations.map(
                  (allocation) => _SectionData(
                    key: 'allocation-${allocation.id}',
                    title: allocation.name,
                    subtitle: 'فئات هذا المخصص',
                    target: _CategoryTarget('allocation', allocation.id),
                    categories: allocation.categories,
                  ),
                ),
                ...budget.linkedWallets.map(
                  (wallet) => _SectionData(
                    key: 'linked-${wallet.id}',
                    title: wallet.name,
                    subtitle: 'فئات هذا الحساب المرتبط',
                    target: _CategoryTarget('linked-wallet', wallet.id),
                    categories: wallet.categories,
                  ),
                ),
                _SectionData(
                  key: 'general-expense',
                  title: 'فئات عامة',
                  subtitle: 'للمعاملات خارج الميزانية',
                  target: const _CategoryTarget('general-expense', 'general-expense'),
                  categories: generalExpense,
                ),
              ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text('الفئات', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'expense', label: Text('فئات المصروف')),
                ButtonSegment(value: 'income', label: Text('فئات الدخل')),
              ],
              selected: {_tab},
              onSelectionChanged: (set) => setState(() => _tab = set.first),
            ),
            const SizedBox(height: 12),
            if (sections.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(14),
                  child: Text('لا توجد أقسام بعد. أضف مخصصات أو مصادر دخل من إعداد الميزانية.'),
                ),
              )
            else
              ...sections.map((section) => _buildSection(section)),
          ],
        );
      },
    );
  }

  Widget _buildSection(_SectionData section) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(section.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text(section.subtitle, style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6), fontSize: 12)),
                    ],
                  ),
                ),
                FilledButton.icon(
                  onPressed: () => _openCategoryDialog(section.target),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('إضافة فئة'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (section.categories.isEmpty)
              const Text('لا توجد فئات داخل هذا القسم حتى الآن.')
            else
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: section.categories.map((category) {
                  final iconData = _iconForName(category.icon);
                  final bgColor = _parseColor(category.color);
                  return Container(
                    width: 180,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: bgColor, borderRadius: BorderRadius.circular(12)),
                          child: Icon(iconData, color: Colors.white, size: 18),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: Text(category.name, overflow: TextOverflow.ellipsis)),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          onPressed: () => _openCategoryDialog(section.target, editing: category),
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline, size: 18, color: Theme.of(context).colorScheme.error),
                          onPressed: () => _deleteCategory(section.target, category),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openCategoryDialog(_CategoryTarget target, {CategoryEntity? editing}) async {
    final nameController = TextEditingController(text: editing?.name ?? '');
    var selectedIcon = editing?.icon ?? 'category';
    var selectedColor = editing?.color ?? '#165b47';

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) {
          return AlertDialog(
            title: Text(editing == null ? 'إضافة فئة جديدة' : 'تعديل الفئة'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('اسم الفئة'),
                    const SizedBox(height: 6),
                    TextField(controller: nameController, decoration: const InputDecoration(hintText: 'مثال: مطعم')),
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
                        label: const Text('اختيار الأيقونة'),
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
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(nameController.text.isEmpty ? 'اسم الفئة' : nameController.text),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              FilledButton(
                onPressed: () async {
                  final name = nameController.text.trim();
                  if (name.isEmpty) return;
                  final category = CategoryEntity(
                    id: editing?.id ?? 'cat-${DateTime.now().microsecondsSinceEpoch}',
                    name: name,
                    icon: selectedIcon,
                    color: selectedColor,
                    scope: _tab,
                    allocationId: target.kind == 'allocation' ? target.id : null,
                    walletId: target.kind == 'linked-wallet' ? target.id : null,
                    incomeSourceId: target.kind == 'income-source' ? target.id : null,
                  );
                  await _saveCategory(target, category, editing: editing);
                  if (context.mounted) Navigator.pop(context);
                },
                child: const Text('تم'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _saveCategory(_CategoryTarget target, CategoryEntity category, {CategoryEntity? editing}) async {
    final state = widget.cubit.state;
    final budget = state.budgetSetup;

    if (target.kind == 'allocation') {
      final allocation = budget.allocations.firstWhere((a) => a.id == target.id);
      final next = editing == null
          ? [...allocation.categories, category]
          : allocation.categories.map((c) => c.id == editing.id ? category : c).toList();
      await widget.cubit.updateAllocationCategories(allocationId: target.id, categories: next);
      return;
    }

    if (target.kind == 'linked-wallet') {
      final wallet = budget.linkedWallets.firstWhere((w) => w.id == target.id);
      final next = editing == null
          ? [...wallet.categories, category]
          : wallet.categories.map((c) => c.id == editing.id ? category : c).toList();
      await widget.cubit.updateLinkedWalletCategories(linkedWalletId: target.id, categories: next);
      return;
    }

    final current = state.categories;
    List<CategoryEntity> next;
    if (target.kind == 'income-source') {
      final source = current.where((c) => c.incomeSourceId == target.id).toList();
      final updated = editing == null
          ? [...source, category]
          : source.map((c) => c.id == editing.id ? category : c).toList();
      final untouched = current.where((c) => c.incomeSourceId != target.id).toList();
      next = [...untouched, ...updated];
    } else if (target.kind == 'general-income') {
      final source = current.where((c) => c.scope == 'income' && c.incomeSourceId == null).toList();
      final updated = editing == null
          ? [...source, category]
          : source.map((c) => c.id == editing.id ? category : c).toList();
      final untouched = current.where((c) => !(c.scope == 'income' && c.incomeSourceId == null)).toList();
      next = [...untouched, ...updated];
    } else {
      final source = current.where((c) => c.scope == 'expense' && c.incomeSourceId == null).toList();
      final updated = editing == null
          ? [...source, category]
          : source.map((c) => c.id == editing.id ? category : c).toList();
      final untouched = current.where((c) => !(c.scope == 'expense' && c.incomeSourceId == null)).toList();
      next = [...untouched, ...updated];
    }
    await widget.cubit.setCategories(next);
  }

  Future<void> _deleteCategory(_CategoryTarget target, CategoryEntity category) async {
    final state = widget.cubit.state;
    final budget = state.budgetSetup;

    if (target.kind == 'allocation') {
      final allocation = budget.allocations.firstWhere((a) => a.id == target.id);
      await widget.cubit.updateAllocationCategories(
        allocationId: target.id,
        categories: allocation.categories.where((c) => c.id != category.id).toList(),
      );
      return;
    }

    if (target.kind == 'linked-wallet') {
      final wallet = budget.linkedWallets.firstWhere((w) => w.id == target.id);
      await widget.cubit.updateLinkedWalletCategories(
        linkedWalletId: target.id,
        categories: wallet.categories.where((c) => c.id != category.id).toList(),
      );
      return;
    }

    await widget.cubit.setCategories(state.categories.where((c) => c.id != category.id).toList());
  }

  IconData _iconForName(String icon) {
    return AppIconPickerDialog.iconDataForName(icon);
  }

  Color _parseColor(String hex) {
    final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | value);
  }

}

class _CategoryTarget {
  const _CategoryTarget(this.kind, this.id);
  final String kind;
  final String id;
}

class _SectionData {
  const _SectionData({
    required this.key,
    required this.title,
    required this.subtitle,
    required this.target,
    required this.categories,
  });

  final String key;
  final String title;
  final String subtitle;
  final _CategoryTarget target;
  final List<CategoryEntity> categories;
}
