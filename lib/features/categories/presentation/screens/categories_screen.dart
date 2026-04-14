import 'package:flutter/material.dart';

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

  static const _families = [
    ('food', 'أكل'),
    ('health', 'علاج'),
    ('work', 'شغل'),
    ('money', 'فلوس'),
    ('home', 'بيت'),
    ('transport', 'مواصلات'),
    ('fun', 'ترفيه'),
    ('shopping', 'تسوق'),
    ('tech', 'تقنية'),
  ];

  static const _iconsByFamily = <String, List<(String, IconData)>>{
    'food': [
      ('food_1', Icons.restaurant), ('food_2', Icons.local_pizza), ('food_3', Icons.fastfood), ('food_4', Icons.ramen_dining),
      ('food_5', Icons.coffee), ('food_6', Icons.cake), ('food_7', Icons.icecream), ('food_8', Icons.egg_alt),
      ('food_9', Icons.lunch_dining), ('food_10', Icons.dinner_dining), ('food_11', Icons.local_drink), ('food_12', Icons.wine_bar),
      ('food_13', Icons.kebab_dining), ('food_14', Icons.bakery_dining), ('food_15', Icons.set_meal), ('food_16', Icons.soup_kitchen),
      ('food_17', Icons.restaurant_menu), ('food_18', Icons.cookie), ('food_19', Icons.brunch_dining), ('food_20', Icons.takeout_dining),
    ],
    'health': [
      ('health_1', Icons.favorite), ('health_2', Icons.medication), ('health_3', Icons.local_hospital), ('health_4', Icons.health_and_safety),
      ('health_5', Icons.monitor_heart), ('health_6', Icons.vaccines), ('health_7', Icons.medical_services), ('health_8', Icons.sick),
      ('health_9', Icons.healing), ('health_10', Icons.bloodtype), ('health_11', Icons.spa), ('health_12', Icons.elderly),
      ('health_13', Icons.clean_hands), ('health_14', Icons.masks), ('health_15', Icons.air), ('health_16', Icons.wc),
      ('health_17', Icons.accessibility_new), ('health_18', Icons.fitness_center), ('health_19', Icons.run_circle), ('health_20', Icons.self_improvement),
    ],
    'work': [
      ('work_1', Icons.work), ('work_2', Icons.business), ('work_3', Icons.apartment), ('work_4', Icons.badge),
      ('work_5', Icons.description), ('work_6', Icons.assignment), ('work_7', Icons.checklist), ('work_8', Icons.calculate),
      ('work_9', Icons.attach_money), ('work_10', Icons.cases), ('work_11', Icons.event_note), ('work_12', Icons.fact_check),
      ('work_13', Icons.groups), ('work_14', Icons.handshake), ('work_15', Icons.engineering), ('work_16', Icons.sell),
      ('work_17', Icons.store_mall_directory), ('work_18', Icons.laptop), ('work_19', Icons.desktop_windows), ('work_20', Icons.print),
    ],
    'money': [
      ('money_1', Icons.account_balance_wallet), ('money_2', Icons.account_balance), ('money_3', Icons.credit_card), ('money_4', Icons.payments),
      ('money_5', Icons.currency_exchange), ('money_6', Icons.savings), ('money_7', Icons.receipt_long), ('money_8', Icons.toll),
      ('money_9', Icons.request_quote), ('money_10', Icons.price_check), ('money_11', Icons.price_change), ('money_12', Icons.paid),
      ('money_13', Icons.monetization_on), ('money_14', Icons.wallet), ('money_15', Icons.trending_up), ('money_16', Icons.trending_down),
      ('money_17', Icons.analytics), ('money_18', Icons.shopping_bag), ('money_19', Icons.local_atm), ('money_20', Icons.qr_code_scanner),
    ],
    'home': [
      ('home_1', Icons.home), ('home_2', Icons.bed), ('home_3', Icons.weekend), ('home_4', Icons.kitchen),
      ('home_5', Icons.chair), ('home_6', Icons.bathtub), ('home_7', Icons.shower), ('home_8', Icons.light),
      ('home_9', Icons.garage), ('home_10', Icons.roofing), ('home_11', Icons.door_front_door), ('home_12', Icons.window),
      ('home_13', Icons.cleaning_services), ('home_14', Icons.local_laundry_service), ('home_15', Icons.yard), ('home_16', Icons.hvac),
      ('home_17', Icons.blender), ('home_18', Icons.microwave), ('home_19', Icons.tv), ('home_20', Icons.charging_station),
    ],
    'transport': [
      ('transport_1', Icons.directions_car), ('transport_2', Icons.directions_bus), ('transport_3', Icons.train), ('transport_4', Icons.flight),
      ('transport_5', Icons.two_wheeler), ('transport_6', Icons.directions_bike), ('transport_7', Icons.local_taxi), ('transport_8', Icons.local_gas_station),
      ('transport_9', Icons.ev_station), ('transport_10', Icons.pin_drop), ('transport_11', Icons.map), ('transport_12', Icons.route),
      ('transport_13', Icons.alt_route), ('transport_14', Icons.navigation), ('transport_15', Icons.local_shipping), ('transport_16', Icons.airport_shuttle),
      ('transport_17', Icons.directions_boat), ('transport_18', Icons.subway), ('transport_19', Icons.traffic), ('transport_20', Icons.no_crash),
    ],
    'fun': [
      ('fun_1', Icons.sports_esports), ('fun_2', Icons.movie), ('fun_3', Icons.music_note), ('fun_4', Icons.celebration),
      ('fun_5', Icons.sports_soccer), ('fun_6', Icons.sports_basketball), ('fun_7', Icons.sports_tennis), ('fun_8', Icons.sports_gymnastics),
      ('fun_9', Icons.beach_access), ('fun_10', Icons.casino), ('fun_11', Icons.attractions), ('fun_12', Icons.nightlife),
      ('fun_13', Icons.theaters), ('fun_14', Icons.mic), ('fun_15', Icons.piano), ('fun_16', Icons.palette),
      ('fun_17', Icons.camera_alt), ('fun_18', Icons.photo_camera), ('fun_19', Icons.videogame_asset), ('fun_20', Icons.book),
    ],
    'shopping': [
      ('shopping_1', Icons.shopping_cart), ('shopping_2', Icons.shopping_bag), ('shopping_3', Icons.store), ('shopping_4', Icons.inventory_2),
      ('shopping_5', Icons.checkroom), ('shopping_6', Icons.card_giftcard), ('shopping_7', Icons.diamond), ('shopping_8', Icons.sell),
      ('shopping_9', Icons.local_mall), ('shopping_10', Icons.local_offer), ('shopping_11', Icons.storefront), ('shopping_12', Icons.add_shopping_cart),
      ('shopping_13', Icons.receipt), ('shopping_14', Icons.redeem), ('shopping_15', Icons.watch), ('shopping_16', Icons.shopping_basket),
      ('shopping_17', Icons.local_grocery_store), ('shopping_18', Icons.kitchen), ('shopping_19', Icons.chair_alt), ('shopping_20', Icons.style),
    ],
    'tech': [
      ('tech_1', Icons.smartphone), ('tech_2', Icons.laptop), ('tech_3', Icons.devices), ('tech_4', Icons.memory),
      ('tech_5', Icons.wifi), ('tech_6', Icons.router), ('tech_7', Icons.cable), ('tech_8', Icons.watch),
      ('tech_9', Icons.headphones), ('tech_10', Icons.keyboard), ('tech_11', Icons.mouse), ('tech_12', Icons.desktop_windows),
      ('tech_13', Icons.print), ('tech_14', Icons.sd_storage), ('tech_15', Icons.developer_board), ('tech_16', Icons.battery_charging_full),
      ('tech_17', Icons.usb), ('tech_18', Icons.power), ('tech_19', Icons.settings_input_component), ('tech_20', Icons.security),
    ],
  };

  static const _colors = [
    '#165b47',
    '#0f766e',
    '#2563eb',
    '#7c3aed',
    '#c2410c',
    '#dc2626',
    '#d97706',
    '#0f172a',
    '#be185d',
    '#334155',
  ];

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
                      Text(section.subtitle, style: const TextStyle(color: Colors.black54, fontSize: 12)),
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
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: const [BoxShadow(color: Color(0x14000000), blurRadius: 6)],
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
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
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
    var family = _familyForIcon(editing?.icon ?? 'UtensilsCrossed');
    var selectedIcon = editing?.icon ?? 'UtensilsCrossed';
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
                    ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: const BorderSide(color: Color(0xFFE5E7EB)),
                      ),
                      leading: Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: _parseColor(selectedColor),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(_iconForName(selectedIcon), color: Colors.white, size: 18),
                      ),
                      title: const Text('الأيقونة'),
                      subtitle: Text(_familyTitle(family)),
                      trailing: const Icon(Icons.arrow_drop_down),
                      onTap: () async {
                        final picked = await _pickIconFromDialog(
                          family: family,
                          selectedIcon: selectedIcon,
                        );
                        if (picked == null) {
                          return;
                        }
                        setDialog(() {
                          family = picked.$1;
                          selectedIcon = picked.$2;
                        });
                      },
                    ),
                    const SizedBox(height: 14),
                    const Text('لون الخلفية'),
                    const SizedBox(height: 6),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _colors.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final item = _colors[index];
                        final active = selectedColor == item;
                        return InkWell(
                          onTap: () => setDialog(() => selectedColor = item),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: _parseColor(item),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                width: active ? 2 : 1,
                                color: active ? Colors.black87 : Colors.white,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
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
                            child: Icon(_iconForName(selectedIcon), color: Colors.white),
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

  String _familyForIcon(String icon) {
    for (final family in _families) {
      final icons = _iconsByFamily[family.$1] ?? const <(String, IconData)>[];
      if (icons.any((item) => item.$1 == icon)) {
        return family.$1;
      }
    }
    return 'food';
  }

  IconData _iconForName(String icon) {
    for (final list in _iconsByFamily.values) {
      for (final item in list) {
        if (item.$1 == icon) {
          return item.$2;
        }
      }
    }
    return Icons.category;
  }

  String _familyTitle(String familyKey) {
    final entry = _families.where((f) => f.$1 == familyKey).toList();
    return entry.isEmpty ? 'أيقونة' : entry.first.$2;
  }

  Color _parseColor(String hex) {
    final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | value);
  }

  Future<(String, String)?> _pickIconFromDialog({
    required String family,
    required String selectedIcon,
  }) async {
    var selectedFamily = family;
    var selected = selectedIcon;

    return showDialog<(String, String)>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) {
          final options = _iconsByFamily[selectedFamily] ?? const <(String, IconData)>[];
          return AlertDialog(
            title: const Text('اختيار الأيقونة'),
            content: SizedBox(
              width: 540,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: selectedFamily,
                    decoration: const InputDecoration(labelText: 'الكاتيجوري'),
                    items: _families
                        .map((f) => DropdownMenuItem(value: f.$1, child: Text(f.$2)))
                        .toList(),
                    onChanged: (v) {
                      if (v == null) {
                        return;
                      }
                      setDialog(() {
                        selectedFamily = v;
                        final first = _iconsByFamily[v]!.first;
                        selected = first.$1;
                      });
                    },
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 300,
                    child: GridView.builder(
                      itemCount: options.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 4,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 1,
                      ),
                      itemBuilder: (context, index) {
                        final item = options[index];
                        final isActive = selected == item.$1;
                        return InkWell(
                          onTap: () => setDialog(() => selected = item.$1),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: isActive ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isActive ? const Color(0xFF0F172A) : const Color(0xFFE2E8F0),
                              ),
                            ),
                            child: Icon(item.$2, color: isActive ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('عدد الأيقونات: ${options.length}', style: const TextStyle(fontSize: 12, color: Colors.black54)),
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('إلغاء')),
              FilledButton(
                onPressed: () => Navigator.pop(context, (selectedFamily, selected)),
                child: const Text('اختيار'),
              ),
            ],
          );
        },
      ),
    );
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
