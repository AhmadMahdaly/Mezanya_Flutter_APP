import 'package:flutter/material.dart';

import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../../budget/domain/entities/budget_setup_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../wallets/domain/entities/wallet_entity.dart';

class AddTransactionScreen extends StatefulWidget {
  const AddTransactionScreen({super.key, required this.cubit});

  final AppCubit cubit;

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
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

  static const _icons = [
    ('UtensilsCrossed', 'food', 'وجبات', Icons.restaurant),
    ('Pizza', 'food', 'مطاعم', Icons.local_pizza),
    ('Coffee', 'food', 'قهوة', Icons.coffee),
    ('Apple', 'food', 'فواكه', Icons.apple),
    ('CookingPot', 'food', 'طبخ', Icons.soup_kitchen),
    ('CupSoda', 'food', 'مشروبات', Icons.local_drink),
    ('HeartPulse', 'health', 'صحة', Icons.favorite),
    ('Pill', 'health', 'دواء', Icons.medication),
    ('Stethoscope', 'health', 'كشف', Icons.health_and_safety),
    ('Syringe', 'health', 'حقن', Icons.vaccines),
    ('Hospital', 'health', 'مستشفى', Icons.local_hospital),
    ('ShieldPlus', 'health', 'رعاية', Icons.health_and_safety_outlined),
    ('BriefcaseBusiness', 'work', 'شغل', Icons.work),
    ('Building2', 'work', 'شركة', Icons.apartment),
    ('Laptop2', 'work', 'عمل رقمي', Icons.laptop),
    ('Calculator', 'work', 'حسابات', Icons.calculate),
    ('BadgeDollarSign', 'work', 'دخل', Icons.attach_money),
    ('ClipboardList', 'work', 'مهام', Icons.checklist),
    ('Wallet2', 'money', 'محفظة', Icons.account_balance_wallet),
    ('CreditCard', 'money', 'بطاقة', Icons.credit_card),
    ('Landmark', 'money', 'بنك', Icons.account_balance),
    ('Banknote', 'money', 'كاش', Icons.payments),
    ('Coins', 'money', 'عملات', Icons.toll),
    ('Receipt', 'money', 'فاتورة', Icons.receipt_long),
    ('Home', 'home', 'منزل', Icons.home),
    ('BedSingle', 'home', 'غرفة', Icons.bed),
    ('Sofa', 'home', 'أثاث', Icons.weekend),
    ('WashingMachine', 'home', 'غسيل', Icons.local_laundry_service),
    ('ShowerHead', 'home', 'مرافق', Icons.shower),
    ('LampDesk', 'home', 'إضاءة', Icons.desk),
    ('CarFront', 'transport', 'سيارة', Icons.directions_car),
    ('BusFront', 'transport', 'أتوبيس', Icons.directions_bus),
    ('Bike', 'transport', 'دراجة', Icons.directions_bike),
    ('Plane', 'transport', 'سفر', Icons.flight),
    ('Fuel', 'transport', 'بنزين', Icons.local_gas_station),
    ('MapPinned', 'transport', 'مشوار', Icons.pin_drop),
    ('Gamepad2', 'fun', 'ألعاب', Icons.sports_esports),
    ('Film', 'fun', 'أفلام', Icons.movie),
    ('Music4', 'fun', 'موسيقى', Icons.music_note),
    ('Ticket', 'fun', 'تذاكر', Icons.confirmation_number),
    ('PartyPopper', 'fun', 'خروجات', Icons.celebration),
    ('Tv', 'fun', 'مشاهدة', Icons.tv),
    ('ShoppingCart', 'shopping', 'تسوق', Icons.shopping_cart),
    ('Store', 'shopping', 'متجر', Icons.store),
    ('Package', 'shopping', 'طلبات', Icons.inventory_2),
    ('Shirt', 'shopping', 'ملابس', Icons.checkroom),
    ('Gift', 'shopping', 'هدايا', Icons.card_giftcard),
    ('Gem', 'shopping', 'مشتريات', Icons.diamond),
    ('Smartphone', 'tech', 'موبايل', Icons.smartphone),
    ('Laptop', 'tech', 'لابتوب', Icons.laptop_mac),
    ('MonitorSmartphone', 'tech', 'أجهزة', Icons.devices),
    ('Wifi', 'tech', 'إنترنت', Icons.wifi),
    ('Cable', 'tech', 'كابلات', Icons.cable),
    ('Cpu', 'tech', 'تقنية', Icons.memory),
  ];

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

  String _type = 'expense';
  String _budgetScope = 'within-budget';
  final _amountController = TextEditingController();
  final _notesController = TextEditingController();
  final _newCategoryController = TextEditingController();
  DateTime _date = DateTime.now();
  String _walletId = '';
  String _allocationId = '';
  String _incomeSourceId = 'wallet-only';

  @override
  void initState() {
    super.initState();
    final state = widget.cubit.state;
    _walletId = state.wallets.isNotEmpty ? state.wallets.first.id : '';
    _incomeSourceId = state.budgetSetup.incomeSources.isNotEmpty
        ? state.budgetSetup.incomeSources.first.id
        : 'wallet-only';
  }

  @override
  void dispose() {
    _amountController.dispose();
    _notesController.dispose();
    _newCategoryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = widget.cubit.state;
    final wallets = state.wallets;
    final budget = state.budgetSetup;
    final amount = double.tryParse(_amountController.text.trim()) ?? 0;
    final selectedWallet = wallets.where((w) => w.id == _walletId).toList();
    final selectedWalletName =
        selectedWallet.isEmpty ? 'اختر المحفظة' : selectedWallet.first.name;

    final selectedAllocation =
        budget.allocations.where((a) => a.id == _allocationId).toList();
    final selectedAllocationName = _allocationId == 'unallocated'
        ? 'غير المخصص'
        : selectedAllocation.isEmpty
            ? 'اختر المخصص'
            : selectedAllocation.first.name;

    final allocationCategories = selectedAllocation.isEmpty
        ? <CategoryEntity>[]
        : selectedAllocation.first.categories;
    final generalExpenseCategories = state.categories
        .where((c) => c.scope == 'expense' && c.incomeSourceId == null)
        .toList();
    final visibleCategories = _budgetScope == 'within-budget'
        ? allocationCategories
        : generalExpenseCategories;

    final allocationItems = [
      if (budget.unallocatedAmount > 0)
        const DropdownMenuItem(value: 'unallocated', child: Text('غير المخصص')),
      ...budget.allocations
          .map((a) => DropdownMenuItem(value: a.id, child: Text(a.name))),
    ];
    final allocationIds = allocationItems.map((item) => item.value!).toSet();

    if (_type == 'expense' &&
        _budgetScope == 'within-budget' &&
        _allocationId.isEmpty &&
        allocationItems.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _allocationId.isNotEmpty) {
          return;
        }
        setState(() => _allocationId = allocationItems.first.value!);
      });
    }

    if (_allocationId.isNotEmpty && !allocationIds.contains(_allocationId)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) {
          return;
        }
        setState(() => _allocationId = '');
      });
    }

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
      ),
      child: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          children: [
            Center(
              child: Container(
                width: 54,
                height: 6,
                decoration: BoxDecoration(
                  color: const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: ChoiceChip(
                    label: const Text('مصروف'),
                    selected: _type == 'expense',
                    onSelected: (_) => setState(() => _type = 'expense'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ChoiceChip(
                    label: const Text('دخل'),
                    selected: _type == 'income',
                    onSelected: (_) => setState(() {
                      _type = 'income';
                      _allocationId = '';
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              decoration: const InputDecoration(labelText: 'المبلغ'),
            ),
            const SizedBox(height: 10),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0))),
              title: const Text('المحفظة'),
              subtitle: Text(selectedWalletName),
              trailing: const Icon(Icons.chevron_left),
              onTap: () => _openWalletPicker(wallets),
            ),
            const SizedBox(height: 8),
            ListTile(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: const BorderSide(color: Color(0xFFE2E8F0))),
              title: const Text('تاريخ المعاملة'),
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
            if (_type == 'expense') ...[
              const SizedBox(height: 12),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: Row(
                  children: [
                    const Text('داخل الميزانية'),
                    const Spacer(),
                    Switch(
                      value: _budgetScope == 'within-budget',
                      onChanged: (v) {
                        setState(() {
                          _budgetScope = v ? 'within-budget' : 'outside-budget';
                          if (!v) _allocationId = '';
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
                    borderRadius: BorderRadius.circular(16),
                    side: const BorderSide(color: Color(0xFFE2E8F0))),
                title: const Text('المخصص'),
                subtitle: Text(selectedAllocationName),
                trailing: const Icon(Icons.chevron_left),
                onTap: () => _openAllocationPicker(allocationItems, budget),
              ),
              const SizedBox(height: 10),
              _categoriesBlock(
                title: 'الفئات',
                categories: visibleCategories,
                onAdd: _allocationId.isEmpty && _budgetScope == 'within-budget'
                    ? null
                    : () => _openAddCategoryDialog(
                          budgetScope: _budgetScope,
                          allocationId: _allocationId,
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
                  allocationId: _allocationId,
                  existing: visibleCategories,
                ),
              ),
            ],
            if (_type == 'income') ...[
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: _incomeSourceId,
                decoration: const InputDecoration(labelText: 'مصدر الدخل'),
                items: [
                  const DropdownMenuItem(
                      value: 'wallet-only', child: Text('إيداع للمحفظة فقط')),
                  ...budget.incomeSources.map((i) =>
                      DropdownMenuItem(value: i.id, child: Text(i.name))),
                ],
                onChanged: (v) =>
                    setState(() => _incomeSourceId = v ?? 'wallet-only'),
              ),
            ],
            const SizedBox(height: 10),
            TextField(
              controller: _notesController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'الملاحظات'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () async {
                if (amount <= 0) {
                  _showValidationError('اكتب مبلغ صحيح أكبر من صفر.');
                  return;
                }
                if (_walletId.isEmpty) {
                  _showValidationError('اختَر محفظة أولاً.');
                  return;
                }
                if (_type == 'expense' &&
                    _budgetScope == 'within-budget' &&
                    _allocationId.isEmpty) {
                  _showValidationError('اختَر مخصص للمعاملة داخل الميزانية.');
                  return;
                }
                if (_allocationId == 'unallocated' &&
                    amount > budget.unallocatedAmount) {
                  _showValidationError('المبلغ أكبر من المتاح في غير المخصص.');
                  return;
                }

                await widget.cubit.addTransaction(
                  walletId: _walletId,
                  amount: amount,
                  type: _type,
                  createdAt: DateTime(_date.year, _date.month, _date.day, 12),
                  allocationId: _type == 'expense' &&
                          _budgetScope == 'within-budget' &&
                          _allocationId != 'unallocated'
                      ? _allocationId
                      : null,
                  budgetScope: _type == 'expense' ? _budgetScope : null,
                  incomeSourceId:
                      _type == 'income' && _incomeSourceId != 'wallet-only'
                          ? _incomeSourceId
                          : null,
                  notes: _notesController.text.trim().isEmpty
                      ? null
                      : _notesController.text.trim(),
                );

                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text(_type == 'income'
                          ? 'تم تسجيل الدخل.'
                          : 'تم تسجيل المعاملة.')),
                );
                _amountController.clear();
                _notesController.clear();
              },
              child: Text(_type == 'income' ? 'تسجيل الدخل' : 'تسجيل المعاملة'),
            ),
          ],
        ),
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
                    subtitle:
                        Text('الرصيد: ${wallet.balance.toStringAsFixed(2)}'),
                    trailing: _walletId == wallet.id
                        ? const Icon(Icons.check_circle, color: Colors.green)
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

  void _openAllocationPicker(
      List<DropdownMenuItem<String>> allocationItems, BudgetSetupEntity budget) {
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
                  trailing: _allocationId == id
                      ? const Icon(Icons.check_circle, color: Colors.green)
                      : null,
                  onTap: () {
                    setState(() => _allocationId = id);
                    Navigator.pop(context);
                  },
                ),
              );
            }
            final allocation = budget.allocations.firstWhere((a) => a.id == id);
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
                trailing: _allocationId == id
                    ? const Icon(Icons.check_circle, color: Colors.green)
                    : null,
                onTap: () {
                  setState(() => _allocationId = id);
                  Navigator.pop(context);
                },
              ),
            );
          }).toList(),
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
                child: Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700))),
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
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Text('لا توجد فئات حتى الآن لهذا الجزء.'),
          )
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: categories
                .map(
                  (c) => Container(
                    width: 140,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: _parseColor(c.color).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _parseColor(c.color),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.category,
                              color: Colors.white, size: 16),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            c.name,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
      ],
    );
  }

  Future<void> _openAddCategoryDialog({
    required String budgetScope,
    required String allocationId,
    required List<CategoryEntity> existing,
  }) async {
    _newCategoryController.clear();
    var family = 'food';
    var selectedIcon = 'UtensilsCrossed';
    var selectedColor = '#165b47';

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) {
          final visibleIcons = _icons.where((item) => item.$2 == family).toList();
          return AlertDialog(
            title: const Text('إضافة فئة'),
            content: SizedBox(
              width: 560,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('اسم الفئة'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _newCategoryController,
                      decoration: const InputDecoration(hintText: 'اكتب اسم الفئة'),
                      onChanged: (_) => setDialog(() {}),
                    ),
                    const SizedBox(height: 14),
                    const Text('مجال الأيقونة'),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _families.map((f) {
                        final active = family == f.$1;
                        return ChoiceChip(
                          label: Text(f.$2),
                          selected: active,
                          onSelected: (_) {
                            setDialog(() {
                              family = f.$1;
                              selectedIcon = _icons.firstWhere((icon) => icon.$2 == family).$1;
                            });
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),
                    const Text('الأيقونات المتاحة'),
                    const SizedBox(height: 6),
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: visibleIcons.length,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 8,
                        childAspectRatio: 2.8,
                      ),
                      itemBuilder: (context, index) {
                        final item = visibleIcons[index];
                        final active = selectedIcon == item.$1;
                        return InkWell(
                          onTap: () => setDialog(() => selectedIcon = item.$1),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: active ? Colors.black87 : const Color(0xFFE5E7EB)),
                              color: active ? const Color(0xFFF3F4F6) : Colors.white,
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F172A),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(item.$4, color: Colors.white, size: 16),
                                ),
                                const SizedBox(width: 6),
                                Text(item.$3, style: const TextStyle(fontSize: 12)),
                              ],
                            ),
                          ),
                        );
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

  IconData _iconForName(String icon) {
    final entry = _icons.where((item) => item.$1 == icon).toList();
    return entry.isNotEmpty ? entry.first.$4 : Icons.category;
  }

  void _showValidationError(String message) {
    final messenger = ScaffoldMessenger.maybeOf(context);
    messenger?.showSnackBar(SnackBar(content: Text(message)));
  }
}
