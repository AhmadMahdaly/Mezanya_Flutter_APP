import 'package:flutter/material.dart';

import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../../budget/domain/entities/budget_setup_entity.dart';
import '../../domain/entities/wallet_entity.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key, required this.cubit});
  final AppCubit cubit;

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  static const _walletIcons = <IconData>[
    Icons.account_balance_wallet,
    Icons.credit_card,
    Icons.account_balance,
    Icons.payments,
    Icons.savings,
    Icons.receipt_long,
    Icons.currency_exchange,
    Icons.attach_money,
    Icons.point_of_sale,
    Icons.business_center,
    Icons.money,
    Icons.wallet_membership,
  ];

  static const _colors = <String>[
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
    final state = widget.cubit.state;
    final wallets = state.wallets;
    final jars = state.budgetSetup.linkedWallets;
    final walletPreview = wallets.take(5).toList();
    final jarPreview = jars.take(5).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('المحافظ',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              onPressed: () => _openWalletEditor(),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'إضافة محفظة',
            ),
            IconButton(
              onPressed: wallets.length < 2 ? null : _openTransferDialog,
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'تحويل بين المحافظ',
            ),
          ],
        ),
        const SizedBox(height: 10),
        _FixedSectionBox(
          title: 'المحافظ',
          subtitle: 'المحافظ الفعلية الموجودة معك الآن',
          onMore: () => _openAllItemsPage(isWallets: true),
          child: walletPreview.isEmpty
              ? const _EmptyBlock(text: 'لا توجد محافظ بعد.')
              : ListView.builder(
                  itemCount: walletPreview.length,
                  itemBuilder: (context, index) =>
                      _walletTile(walletPreview[index]),
                ),
        ),
        const SizedBox(height: 14),
        Row(
          children: [
            const Expanded(
              child: Text('الحصالات',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              onPressed: () => _openJarEditor(),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'إضافة حصالة',
            ),
          ],
        ),
        const SizedBox(height: 8),
        _FixedSectionBox(
          title: 'الحصالات',
          subtitle: 'أوعية منطقية مرتبطة بخطة الميزانية',
          onMore: () => _openAllItemsPage(isWallets: false),
          child: jarPreview.isEmpty
              ? const _EmptyBlock(text: 'لا توجد حصالات بعد.')
              : ListView.builder(
                  itemCount: jarPreview.length,
                  itemBuilder: (context, index) => _jarTile(jarPreview[index]),
                ),
        ),
      ],
    );
  }

  Widget _walletTile(WalletEntity wallet) {
    return ListTile(
      onTap: () => _openDetailsSheet(walletId: wallet.id, isWallet: true),
      leading: _iconBubble(
          iconName: wallet.icon ?? 'account_balance_wallet',
          colorHex: wallet.iconColor ?? '#165b47'),
      title: Text(wallet.name),
      trailing: Text(wallet.balance.toStringAsFixed(2)),
    );
  }

  Widget _jarTile(LinkedWalletEntity jar) {
    return ListTile(
      onTap: () => _openDetailsSheet(walletId: jar.id, isWallet: false),
      leading: _iconBubble(iconName: jar.icon, colorHex: jar.iconColor),
      title: Text(jar.name),
      subtitle: Text('شهريًا ${jar.monthlyAmount.toStringAsFixed(2)}'),
      trailing: Text(jar.balance.toStringAsFixed(2)),
    );
  }

  Widget _iconBubble({required String iconName, required String colorHex}) {
    final icon = _iconFromName(iconName);
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: _parseColor(colorHex),
          borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, color: Colors.white, size: 20),
    );
  }

  void _openAllItemsPage({required bool isWallets}) {
    final state = widget.cubit.state;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(isWallets ? 'كل المحافظ' : 'كل الحصالات')),
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              ...(isWallets ? state.wallets : state.budgetSetup.linkedWallets)
                  .map(
                (item) => isWallets
                    ? _walletTile(item as WalletEntity)
                    : _jarTile(item as LinkedWalletEntity),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetailsSheet({required String walletId, required bool isWallet}) {
    final state = widget.cubit.state;
    final wallet =
        isWallet ? state.wallets.firstWhere((w) => w.id == walletId) : null;
    final jar = !isWallet
        ? state.budgetSetup.linkedWallets.firstWhere((j) => j.id == walletId)
        : null;
    final txns = state.transactions
        .where((t) =>
            t.walletId == walletId ||
            t.fromWalletId == walletId ||
            t.toWalletId == walletId)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.82,
        child: Column(
          children: [
            ListTile(
              title: Text(isWallet ? wallet!.name : jar!.name),
              subtitle: const Text('تفاصيل الرصيد وحركة العنصر'),
              trailing: IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () {
                  Navigator.pop(context);
                  if (isWallet) {
                    _openWalletEditor(current: wallet);
                  } else {
                    _openJarEditor(current: jar);
                  }
                },
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: txns.isEmpty
                  ? const Center(child: Text('لا توجد معاملات لهذا العنصر.'))
                  : ListView.builder(
                      itemCount: txns.length,
                      itemBuilder: (context, index) {
                        final t = txns[index];
                        return ListTile(
                          title: Text(t.notes ??
                              (t.type == 'expense'
                                  ? 'مصروف'
                                  : t.type == 'income'
                                      ? 'دخل'
                                      : 'تحويل')),
                          subtitle: Text(
                              '${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}'),
                          trailing: Text(
                            '${t.type == 'expense' ? '-' : '+'}${t.amount.toStringAsFixed(2)}',
                            style: TextStyle(
                                color: t.type == 'expense'
                                    ? Colors.red
                                    : Colors.green),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _openTransferDialog() {
    final wallets = widget.cubit.state.wallets;
    String fromId = wallets.first.id;
    String toId = wallets.length > 1 ? wallets[1].id : wallets.first.id;
    final amountController = TextEditingController();

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('تحويل بين المحافظ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: fromId,
                decoration: const InputDecoration(labelText: 'من محفظة'),
                items: wallets
                    .map((w) =>
                        DropdownMenuItem(value: w.id, child: Text(w.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialog(() => fromId = v);
                },
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                initialValue: toId,
                decoration: const InputDecoration(labelText: 'إلى محفظة'),
                items: wallets
                    .map((w) =>
                        DropdownMenuItem(value: w.id, child: Text(w.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialog(() => toId = v);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ'),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                if (amount <= 0 || fromId == toId) return;
                await widget.cubit.addTransaction(
                  type: 'transfer',
                  amount: amount,
                  fromWalletId: fromId,
                  toWalletId: toId,
                  transferType: 'wallet-to-wallet',
                  notes: 'تحويل بين المحافظ',
                );
                if (!mounted) return;
                Navigator.of(this.context).pop();
              },
              child: const Text('تنفيذ التحويل'),
            ),
          ],
        ),
      ),
    );
  }

  void _openWalletEditor({WalletEntity? current}) {
    final nameController = TextEditingController(text: current?.name ?? '');
    final balanceController =
        TextEditingController(text: (current?.balance ?? 0).toStringAsFixed(0));
    String selectedColor = current?.iconColor ?? _colors.first;
    String selectedIcon = current?.icon ?? 'account_balance_wallet';

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(current == null ? 'إضافة محفظة جديدة' : 'تعديل المحفظة'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'اسم المحفظة')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: balanceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'الفلوس'),
                  ),
                  const SizedBox(height: 10),
                  _iconSelector(
                    selectedIcon: selectedIcon,
                    selectedColor: selectedColor,
                    onIcon: (v) => setDialog(() => selectedIcon = v),
                    onColor: (v) => setDialog(() => selectedColor = v),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (current != null)
              TextButton(
                onPressed: () async {
                  await widget.cubit.deleteWallet(current.id);
                  if (!mounted) return;
                  Navigator.of(this.context).pop();
                },
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final balance =
                    double.tryParse(balanceController.text.trim()) ?? 0;
                if (name.isEmpty) return;
                if (current == null) {
                  await widget.cubit.addWallet(
                    name: name,
                    openingBalance: balance,
                    icon: selectedIcon,
                    iconColor: selectedColor,
                  );
                } else {
                  await widget.cubit.updateWallet(
                    id: current.id,
                    name: name,
                    balance: balance,
                    icon: selectedIcon,
                    iconColor: selectedColor,
                  );
                }
                if (!mounted) return;
                Navigator.of(this.context).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  void _openJarEditor({LinkedWalletEntity? current}) {
    final incomes = widget.cubit.state.budgetSetup.incomeSources;
    final nameController = TextEditingController(text: current?.name ?? '');
    final balanceController =
        TextEditingController(text: (current?.balance ?? 0).toStringAsFixed(0));
    String selectedColor = current?.iconColor ?? '#0f766e';
    String selectedIcon = current?.icon ?? 'savings';
    String automationType = current?.automationType ?? 'confirm';
    final dayController =
        TextEditingController(text: (current?.executionDay ?? 1).toString());
    var funding = List<LinkedWalletEntityFunding>.from(
      current?.funding ??
          [
            LinkedWalletEntityFunding(
              id: 'fund-${DateTime.now().millisecondsSinceEpoch}',
              incomeSourceId: incomes.isNotEmpty ? incomes.first.id : '',
              plannedAmount: 0,
            ),
          ],
    );

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(current == null ? 'إضافة حصالة' : 'تعديل الحصالة'),
          content: SizedBox(
            width: 560,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                      controller: nameController,
                      decoration:
                          const InputDecoration(labelText: 'اسم الحصالة')),
                  const SizedBox(height: 8),
                  TextField(
                    controller: balanceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'الرصيد'),
                  ),
                  const SizedBox(height: 10),
                  _iconSelector(
                    selectedIcon: selectedIcon,
                    selectedColor: selectedColor,
                    onIcon: (v) => setDialog(() => selectedIcon = v),
                    onColor: (v) => setDialog(() => selectedColor = v),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Expanded(
                          child: Text('المساهمات الشهرية (مصادر دخل متعددة)')),
                      TextButton(
                        onPressed: () => setDialog(() {
                          funding.add(
                            LinkedWalletEntityFunding(
                              id: 'fund-${DateTime.now().millisecondsSinceEpoch}',
                              incomeSourceId:
                                  incomes.isNotEmpty ? incomes.first.id : '',
                              plannedAmount: 0,
                            ),
                          );
                        }),
                        child: const Text('إضافة مصدر'),
                      ),
                    ],
                  ),
                  ...funding.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: DropdownButtonFormField<String>(
                                initialValue: f.incomeSourceId.isEmpty
                                    ? null
                                    : f.incomeSourceId,
                                items: incomes
                                    .map((i) => DropdownMenuItem(
                                        value: i.id, child: Text(i.name)))
                                    .toList(),
                                onChanged: (v) {
                                  if (v == null) return;
                                  setDialog(() {
                                    funding = funding
                                        .map((x) => x.id == f.id
                                            ? LinkedWalletEntityFunding(
                                                id: x.id,
                                                incomeSourceId: v,
                                                plannedAmount: x.plannedAmount)
                                            : x)
                                        .toList();
                                  });
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextFormField(
                                initialValue:
                                    f.plannedAmount.toStringAsFixed(0),
                                keyboardType: TextInputType.number,
                                decoration:
                                    const InputDecoration(labelText: 'المبلغ'),
                                onChanged: (v) {
                                  final n = double.tryParse(v) ?? 0;
                                  setDialog(() {
                                    funding = funding
                                        .map((x) => x.id == f.id
                                            ? LinkedWalletEntityFunding(
                                                id: x.id,
                                                incomeSourceId:
                                                    x.incomeSourceId,
                                                plannedAmount: n)
                                            : x)
                                        .toList();
                                  });
                                },
                              ),
                            ),
                            IconButton(
                              onPressed: funding.length == 1
                                  ? null
                                  : () => setDialog(() => funding = funding
                                      .where((x) => x.id != f.id)
                                      .toList()),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                      )),
                  DropdownButtonFormField<String>(
                    initialValue: automationType,
                    decoration: const InputDecoration(labelText: 'نوع التنفيذ'),
                    items: const [
                      DropdownMenuItem(value: 'auto', child: Text('تلقائي')),
                      DropdownMenuItem(
                          value: 'confirm', child: Text('يحتاج تأكيد')),
                      DropdownMenuItem(value: 'manual', child: Text('يدوي')),
                    ],
                    onChanged: (v) {
                      if (v != null) setDialog(() => automationType = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: dayController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'يوم التحويل الشهري (1-28)'),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            if (current != null)
              TextButton(
                onPressed: () async {
                  await widget.cubit.deleteLinkedWallet(current.id);
                  if (!mounted) return;
                  Navigator.of(this.context).pop();
                },
                child: const Text('حذف', style: TextStyle(color: Colors.red)),
              ),
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء')),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                if (name.isEmpty) return;
                final day =
                    (int.tryParse(dayController.text.trim()) ?? 1).clamp(1, 28);
                final cleanedFunding = funding
                    .where((f) =>
                        f.incomeSourceId.isNotEmpty && f.plannedAmount > 0)
                    .toList();
                final monthlyAmount = cleanedFunding.fold<double>(
                    0, (s, f) => s + f.plannedAmount);
                final primary = cleanedFunding.isNotEmpty
                    ? cleanedFunding.first.incomeSourceId
                    : '';

                final entity = LinkedWalletEntity(
                  id: current?.id ??
                      'linked-${DateTime.now().millisecondsSinceEpoch}',
                  name: name,
                  balance: double.tryParse(balanceController.text.trim()) ?? 0,
                  monthlyAmount: monthlyAmount,
                  executionDay: day,
                  fundingSource: primary,
                  funding: cleanedFunding,
                  icon: selectedIcon,
                  iconColor: selectedColor,
                  automationType: automationType,
                  categories: current?.categories ?? const [],
                );
                if (current == null) {
                  await widget.cubit.addLinkedWallet(entity);
                } else {
                  await widget.cubit.updateLinkedWallet(entity);
                }
                if (!mounted) return;
                Navigator.of(this.context).pop();
              },
              child: const Text('حفظ'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _iconSelector({
    required String selectedIcon,
    required String selectedColor,
    required ValueChanged<String> onIcon,
    required ValueChanged<String> onColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('اختيار الأيقونة'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _walletIcons.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1.2,
          ),
          itemBuilder: (context, index) {
            final icon = _walletIcons[index];
            final name = _iconName(icon);
            final active = selectedIcon == name;
            return InkWell(
              onTap: () => onIcon(name),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: active ? const Color(0xFFF3F4F6) : Colors.white,
                  border: Border.all(
                      color: active ? Colors.black87 : const Color(0xFFE5E7EB)),
                ),
                child: Icon(icon, color: Colors.black87, size: 20),
              ),
            );
          },
        ),
        const SizedBox(height: 8),
        const Text('الألوان'),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _colors.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            childAspectRatio: 1,
          ),
          itemBuilder: (context, index) {
            final c = _colors[index];
            final active = selectedColor == c;
            return InkWell(
              onTap: () => onColor(c),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                decoration: BoxDecoration(
                  color: _parseColor(c),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: active ? Colors.black87 : Colors.white,
                      width: active ? 2 : 1),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  IconData _iconFromName(String name) {
    return {
          'account_balance_wallet': Icons.account_balance_wallet,
          'credit_card': Icons.credit_card,
          'account_balance': Icons.account_balance,
          'payments': Icons.payments,
          'savings': Icons.savings,
          'receipt_long': Icons.receipt_long,
          'currency_exchange': Icons.currency_exchange,
          'attach_money': Icons.attach_money,
          'point_of_sale': Icons.point_of_sale,
          'business_center': Icons.business_center,
          'money': Icons.money,
          'wallet_membership': Icons.wallet_membership,
        }[name] ??
        Icons.account_balance_wallet;
  }

  String _iconName(IconData icon) {
    if (icon == Icons.credit_card) return 'credit_card';
    if (icon == Icons.account_balance) return 'account_balance';
    if (icon == Icons.payments) return 'payments';
    if (icon == Icons.savings) return 'savings';
    if (icon == Icons.receipt_long) return 'receipt_long';
    if (icon == Icons.currency_exchange) return 'currency_exchange';
    if (icon == Icons.attach_money) return 'attach_money';
    if (icon == Icons.point_of_sale) return 'point_of_sale';
    if (icon == Icons.business_center) return 'business_center';
    if (icon == Icons.money) return 'money';
    if (icon == Icons.wallet_membership) return 'wallet_membership';
    return 'account_balance_wallet';
  }

  Color _parseColor(String hex) {
    final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | value);
  }
}

class _FixedSectionBox extends StatelessWidget {
  const _FixedSectionBox({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.onMore,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final VoidCallback onMore;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: SizedBox(
        height: 420,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18)),
              Text(subtitle,
                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
              const SizedBox(height: 8),
              Expanded(child: child),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onMore,
                  child: const Text('المزيد'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Text(text, style: const TextStyle(color: Colors.black54)),
    );
  }
}
