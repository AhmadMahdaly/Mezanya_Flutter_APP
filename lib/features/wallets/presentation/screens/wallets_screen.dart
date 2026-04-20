import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon_picker_dialog.dart';
import '../../../app_state/domain/entities/app_state_entity.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../../budget/domain/entities/budget_setup_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/widgets/transaction_details_sheet.dart';
import 'jar_editor_screen.dart';
import '../../domain/entities/wallet_entity.dart';

class WalletsScreen extends StatefulWidget {
  const WalletsScreen({super.key, required this.cubit});
  final AppCubit cubit;

  @override
  State<WalletsScreen> createState() => _WalletsScreenState();
}

class _WalletsScreenState extends State<WalletsScreen> {
  @override
  Widget build(BuildContext context) {
    final state = widget.cubit.state;
    final wallets = state.wallets;
    final jars = _orderedJars(state.budgetSetup.linkedWallets);
    final walletPreview = wallets.take(3).toList();
    final jarPreview = jars.take(3).toList();

    return ListView(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(8),
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('المحافظ',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            ),
            IconButton(
              onPressed: wallets.length < 2 ? null : _openTransferDialog,
              icon: const Icon(Icons.swap_horiz),
              tooltip: 'تحويل بين المحافظ',
            ),
            IconButton(
              onPressed: () => _openWalletEditor(),
              icon: const Icon(Icons.add_circle_outline),
              tooltip: 'إضافة محفظة',
            ),
          ],
        ),
        // const SizedBox(height: 4),
        _FixedSectionBox(
          title: 'المحافظ',
          subtitle: 'المحافظ الفعلية الموجودة معك الآن',
          onMore: () => _openAllItemsPage(isWallets: true),
          child: walletPreview.isEmpty
              ? const _EmptyBlock(text: 'لا توجد محافظ بعد.')
              : Column(
                  children: walletPreview
                      .map((wallet) => _walletTile(wallet))
                      .toList(),
                ),
        ),
        // const SizedBox(height: 8),
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
        // const SizedBox(height: 8),
        _FixedSectionBox(
          title: 'الحصالات',
          subtitle: 'أوعية منطقية مرتبطة بخطة الميزانية',
          onMore: () => _openAllItemsPage(isWallets: false),
          child: jarPreview.isEmpty
              ? const _EmptyBlock(text: 'لا توجد حصالات بعد.')
              : Column(
                  children: jarPreview.map((jar) => _jarTile(jar)).toList(),
                ),
        ),
      ],
    );
  }

  Widget _walletTile(WalletEntity wallet) {
    final available = wallet.balance - wallet.reservedForSavings;
    return ListTile(
      onTap: () => _openDetailsSheet(walletId: wallet.id, isWallet: true),
      leading: _iconBubble(
          iconName: wallet.icon ?? 'account_balance_wallet',
          colorHex: wallet.iconColor ?? '#165b47'),
      title: Text(wallet.name),
      subtitle: wallet.reservedForSavings > 0
          ? Text(
              'المتاح ${available.toStringAsFixed(2)} • المحجوز ${wallet.reservedForSavings.toStringAsFixed(2)}')
          : null,
      trailing: Text(wallet.balance.toStringAsFixed(2)),
    );
  }

  Widget _jarTile(LinkedWalletEntity jar) {
    final isSavings = jar.id == 'linked-savings-default';
    return ListTile(
      onTap: () => _openDetailsSheet(walletId: jar.id, isWallet: false),
      leading: _iconBubble(iconName: jar.icon, colorHex: jar.iconColor),
      title: Text(jar.name),
      subtitle: Text(
          isSavings
              ? 'حصالة افتراضية غير قابلة للحذف'
              : 'شهريًا ${jar.monthlyAmount.toStringAsFixed(2)}',
          style: const TextStyle(fontSize: 12)),
      trailing: Text(jar.balance.toStringAsFixed(2)),
    );
  }

  Widget _iconBubble({required String iconName, required String colorHex}) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
          color: _parseColor(colorHex),
          borderRadius: BorderRadius.circular(12)),
      child: Center(
        child: AppIconPickerDialog.iconWidgetForName(
          iconName,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _openAllItemsPage({required bool isWallets}) {
    final state = widget.cubit.state;
    final wallets = state.wallets;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(title: Text(isWallets ? 'كل المحافظ' : 'كل الحصالات')),
          floatingActionButton: isWallets
              ? FloatingActionButton.extended(
                  onPressed: wallets.length < 2 ? null : _openTransferDialog,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('تحويل'),
                )
              : null,
          body: ListView(
            padding: const EdgeInsets.all(12),
            children: [
              if (isWallets)
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => _openWalletEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة محفظة'),
                  ),
                )
              else
                Align(
                  alignment: Alignment.centerLeft,
                  child: FilledButton.icon(
                    onPressed: () => _openJarEditor(),
                    icon: const Icon(Icons.add),
                    label: const Text('إضافة حصالة'),
                  ),
                ),
              const SizedBox(height: 8),
              ...(isWallets
                      ? state.wallets
                      : _orderedJars(state.budgetSetup.linkedWallets))
                  .map(
                (item) => isWallets
                    ? _walletBigCard(item as WalletEntity, context)
                    : _jarBigCard(item as LinkedWalletEntity, context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _walletBigCard(WalletEntity wallet, BuildContext pageContext) {
    final color = _parseColor(wallet.iconColor ?? '#165b47');
    final available = wallet.balance - wallet.reservedForSavings;
    return Card(
      color: color.withValues(alpha: 0.14),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _openDetailsSheet(
          walletId: wallet.id,
          isWallet: true,
          sheetContext: pageContext,
        ),
        leading: _iconBubble(
            iconName: wallet.icon ?? 'account_balance_wallet',
            colorHex: wallet.iconColor ?? '#165b47'),
        title: Text(wallet.name,
            style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          wallet.reservedForSavings > 0
              ? 'المتاح: ${available.toStringAsFixed(2)} • المحجوز: ${wallet.reservedForSavings.toStringAsFixed(2)}'
              : 'الرصيد الحالي: ${wallet.balance.toStringAsFixed(2)}',
        ),
        trailing: const Icon(Icons.chevron_left_rounded),
      ),
    );
  }

  Widget _jarBigCard(LinkedWalletEntity jar, BuildContext pageContext) {
    final color = _parseColor(jar.iconColor);
    final isSavings = jar.id == 'linked-savings-default';
    return Card(
      color: isSavings
          ? color.withValues(alpha: 0.24)
          : color.withValues(alpha: 0.14),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        onTap: () => _openDetailsSheet(
          walletId: jar.id,
          isWallet: false,
          sheetContext: pageContext,
        ),
        leading: _iconBubble(iconName: jar.icon, colorHex: jar.iconColor),
        title:
            Text(jar.name, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(
          isSavings
              ? 'حصالة التوفير الافتراضية • الرصيد: ${jar.balance.toStringAsFixed(2)}'
              : 'الرصيد: ${jar.balance.toStringAsFixed(2)} • مخصص شهريًا: ${jar.monthlyAmount.toStringAsFixed(2)}',
        ),
        trailing: const Icon(Icons.chevron_left_rounded),
      ),
    );
  }

  void _openDetailsSheet({
    required String walletId,
    required bool isWallet,
    BuildContext? sheetContext,
  }) {
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
        .where((t) => isWallet ? !_isJarReserveTx(t) : true)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    final savingsContributors = !isWallet && jar!.id == 'linked-savings-default'
        ? state.wallets.where((w) => w.reservedForSavings > 0).toList()
        : <WalletEntity>[];

    showModalBottomSheet<void>(
      context: sheetContext ?? context,
      isScrollControlled: true,
      builder: (context) {
        var showJarBreakdown = false;
        var showReserveHistory = false;
        return StatefulBuilder(
            builder: (context, setSheetState) => SizedBox(
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
                      if (isWallet) ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Column(
                            children: [
                              _metricRow(
                                context,
                                'الرصيد الكلي',
                                wallet!.balance.toStringAsFixed(2),
                              ),
                              if (wallet.reservedForSavings > 0) ...[
                                _metricRow(
                                  context,
                                  'المتاح للصرف',
                                  (wallet.balance - wallet.reservedForSavings)
                                      .toStringAsFixed(2),
                                ),
                                _metricRow(
                                  context,
                                  'المحجوز للتوفير',
                                  wallet.reservedForSavings.toStringAsFixed(2),
                                ),
                              ],
                              _walletJarBreakdownCard(
                                wallet: wallet,
                                state: state,
                                isExpanded: showJarBreakdown,
                                onToggle: () => setSheetState(
                                  () => showJarBreakdown = !showJarBreakdown,
                                ),
                                onTapJar: (jarId) {
                                  Navigator.pop(context);
                                  _openDetailsSheet(
                                      walletId: jarId, isWallet: false);
                                },
                              ),
                              _walletReserveHistoryCard(
                                wallet: wallet,
                                state: state,
                                isExpanded: showReserveHistory,
                                onToggle: () => setSheetState(
                                  () =>
                                      showReserveHistory = !showReserveHistory,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: () => _openWalletReserveToJar(wallet),
                              icon: const Icon(Icons.savings_outlined),
                              label:
                                  const Text('تخصيص من هذه المحفظة إلى حصالة'),
                            ),
                          ),
                        ),
                      ],
                      if (!isWallet && jar!.id == 'linked-savings-default') ...[
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _metricRow(context, 'إجمالي التوفير',
                                  jar.balance.toStringAsFixed(2)),
                              const SizedBox(height: 6),
                              const Text(
                                'المحافظ المساهمة',
                                style: TextStyle(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              if (savingsContributors.isEmpty)
                                const Text('لا توجد تخصيصات توفير حتى الآن.')
                              else
                                ...savingsContributors.map(
                                  (w) => ListTile(
                                    dense: true,
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(w.name),
                                    trailing: Text(w.reservedForSavings
                                        .toStringAsFixed(2)),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                      if (!isWallet)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          child: Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openJarAllocationAction(
                                    jar: jar!,
                                    action: 'allocate',
                                    title: 'تخصيص للحصالة',
                                  ),
                                  icon: const Icon(Icons.add_circle_outline),
                                  label: const Text('تخصيص'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: () => _openJarAllocationAction(
                                    jar: jar!,
                                    action: 'cancel',
                                    title: 'إلغاء تخصيص',
                                  ),
                                  icon: const Icon(Icons.remove_circle_outline),
                                  label: const Text('إلغاء'),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: () => _openJarAllocationAction(
                                    jar: jar!,
                                    action: 'spend',
                                    title: 'صرف من التخصيص',
                                  ),
                                  icon:
                                      const Icon(Icons.shopping_cart_checkout),
                                  label: const Text('صرف'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const Divider(height: 1),
                      Expanded(
                        child: txns.isEmpty
                            ? const Center(
                                child: Text('لا توجد معاملات لهذا العنصر.'))
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
                                      '${_txnSign(t)}${t.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        color: _txnColor(context, t),
                                      ),
                                    ),
                                    onTap: () => openTransactionDetailsSheet(
                                      context,
                                      cubit: widget.cubit,
                                      transaction: t,
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                ));
      },
    );
  }

  Widget _walletJarBreakdownCard({
    required WalletEntity? wallet,
    required AppStateEntity state,
    required bool isExpanded,
    required VoidCallback onToggle,
    required ValueChanged<String> onTapJar,
  }) {
    if (wallet == null) return const SizedBox.shrink();
    final byJar = <String, double>{};
    for (final t in state.transactions) {
      if (t.transferType == 'jar-allocation' &&
          t.fromWalletId == wallet.id &&
          t.toWalletId != null) {
        byJar[t.toWalletId!] = (byJar[t.toWalletId!] ?? 0) + t.amount;
      }
      if (t.type == 'income' &&
          t.budgetScope == 'within-budget' &&
          t.walletId == wallet.id &&
          t.toWalletId != null) {
        byJar[t.toWalletId!] = (byJar[t.toWalletId!] ?? 0) + t.amount;
      }
      if (t.transferType == 'jar-allocation-cancel' &&
          t.fromWalletId == wallet.id &&
          t.toWalletId != null) {
        byJar[t.toWalletId!] = (byJar[t.toWalletId!] ?? 0) - t.amount;
      }
    }
    byJar.removeWhere((_, v) => v <= 0);
    if (byJar.isEmpty) {
      return const SizedBox.shrink();
    }
    final jars = state.budgetSetup.linkedWallets;
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: const Text('التخصيصات على الحصالات'),
            subtitle: Text(
                'إجمالي: ${byJar.values.fold<double>(0, (s, n) => s + n).toStringAsFixed(2)}'),
            trailing: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
            ),
            onTap: onToggle,
          ),
          if (isExpanded)
            ...byJar.entries.map((entry) {
              final jar = jars.where((j) => j.id == entry.key).toList();
              final name = jar.isEmpty ? 'حصالة' : jar.first.name;
              return ListTile(
                dense: true,
                title: Text(name),
                trailing: Text(entry.value.toStringAsFixed(2)),
                onTap: () => onTapJar(entry.key),
              );
            }),
        ],
      ),
    );
  }

  Widget _walletReserveHistoryCard({
    required WalletEntity? wallet,
    required AppStateEntity state,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) {
    if (wallet == null) return const SizedBox.shrink();
    final reserveTx = state.transactions
        .where((t) =>
            t.fromWalletId == wallet.id &&
            (t.transferType == 'jar-allocation' ||
                t.transferType == 'jar-allocation-cancel' ||
                t.transferType == 'jar-allocation-spend'))
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (reserveTx.isEmpty) return const SizedBox.shrink();
    final jarsById = {
      for (final j in state.budgetSetup.linkedWallets) j.id: j.name,
    };
    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.04),
      ),
      child: Column(
        children: [
          ListTile(
            dense: true,
            title: const Text('سجل الحجز على الحصالات'),
            subtitle: Text('عدد العمليات: ${reserveTx.length}'),
            trailing: Icon(
              isExpanded
                  ? Icons.keyboard_arrow_up_rounded
                  : Icons.keyboard_arrow_down_rounded,
            ),
            onTap: onToggle,
          ),
          if (isExpanded)
            ...reserveTx.map((t) {
              final toName = jarsById[t.toWalletId] ?? 'حصالة';
              final isPositive = t.transferType == 'jar-allocation';
              final label = t.transferType == 'jar-allocation'
                  ? 'تخصيص'
                  : t.transferType == 'jar-allocation-cancel'
                      ? 'إلغاء تخصيص'
                      : 'صرف من المحجوز';
              return ListTile(
                dense: true,
                title: Text('$label - $toName'),
                subtitle: Text(
                    '${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}'),
                trailing: Text(
                  '${isPositive ? '+' : '-'}${t.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    color: isPositive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.error,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                onTap: () => openTransactionDetailsSheet(
                  context,
                  cubit: widget.cubit,
                  transaction: t,
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _metricRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  String _txnSign(TransactionEntity t) {
    if (t.transferType == 'jar-allocation-cancel') return '-';
    if (t.transferType == 'jar-allocation-spend') return '-';
    if (t.type == 'expense') return '-';
    return '+';
  }

  Color _txnColor(BuildContext context, TransactionEntity t) {
    if (t.transferType == 'jar-allocation-cancel' ||
        t.transferType == 'jar-allocation-spend' ||
        t.type == 'expense') {
      return Theme.of(context).colorScheme.error;
    }
    return Theme.of(context).colorScheme.primary;
  }

  bool _isJarReserveTx(TransactionEntity t) {
    return t.transferType == 'jar-allocation' ||
        t.transferType == 'jar-allocation-cancel' ||
        t.transferType == 'jar-allocation-spend';
  }

  void _openJarAllocationAction({
    required LinkedWalletEntity jar,
    required String action,
    required String title,
  }) {
    final wallets = widget.cubit.state.wallets;
    if (wallets.isEmpty) return;
    String sourceWalletId = wallets.first.id;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: sourceWalletId,
                decoration: const InputDecoration(labelText: 'من محفظة'),
                items: wallets
                    .map((w) =>
                        DropdownMenuItem(value: w.id, child: Text(w.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialog(() => sourceWalletId = v);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                if (amount <= 0) return;
                final sourceWalletName =
                    wallets.firstWhere((w) => w.id == sourceWalletId).name;
                final now = DateTime.now();
                final actionText = action == 'allocate'
                    ? 'خصص'
                    : action == 'cancel'
                        ? 'ألغى تخصيص'
                        : 'صرف من تخصيص';
                await widget.cubit.addTransaction(
                  type: action == 'allocate' ? 'transfer' : 'expense',
                  walletId: action == 'allocate' ? null : jar.id,
                  fromWalletId: sourceWalletId,
                  toWalletId: jar.id,
                  amount: amount,
                  transferType: action == 'allocate'
                      ? 'jar-allocation'
                      : action == 'cancel'
                          ? 'jar-allocation-cancel'
                          : 'jar-allocation-spend',
                  notes:
                      '$actionText ${amount.toStringAsFixed(2)} من $sourceWalletName إلى ${jar.name} يوم ${now.day}/${now.month}/${now.year}${notesController.text.trim().isEmpty ? '' : ' - ${notesController.text.trim()}'}',
                );
                if (jar.id == 'linked-savings-default') {
                  await widget.cubit.applySavingsReserve(
                    walletId: sourceWalletId,
                    amount: amount,
                    action: action,
                  );
                }
                if (!mounted) return;
                Navigator.of(this.context).pop();
              },
              child: const Text('تأكيد'),
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
    String selectedColor = current?.iconColor ?? '#165b47';
    String selectedIcon = current?.icon ?? 'wallet';

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
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final picked = await AppIconPickerDialog.show(
                          context,
                          initialIconName: selectedIcon,
                          initialColorHex: selectedColor,
                          title: 'اختيار أيقونة المحفظة',
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
                child: Text('حذف',
                    style:
                        TextStyle(color: Theme.of(context).colorScheme.error)),
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
    Navigator.of(context)
        .push<JarEditorResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => JarEditorScreen(
          current: current,
          incomeSources: incomes,
          idFactory: (prefix) =>
              '$prefix-${DateTime.now().millisecondsSinceEpoch}',
        ),
      ),
    )
        .then((result) async {
      if (result == null) {
        return;
      }
      if (result.deleteRequested && current != null) {
        if (current.id == 'linked-savings-default') {
          return;
        }
        await widget.cubit.deleteLinkedWallet(current.id);
        return;
      }
      final entity = result.entity;
      if (entity == null) {
        return;
      }
      if (current == null) {
        await widget.cubit.addLinkedWallet(entity);
      } else {
        await widget.cubit.updateLinkedWallet(entity);
      }
    });
  }

  Color _parseColor(String hex) {
    final value = int.parse(hex.replaceFirst('#', ''), radix: 16);
    return Color(0xFF000000 | value);
  }

  List<LinkedWalletEntity> _orderedJars(List<LinkedWalletEntity> jars) {
    final sorted = List<LinkedWalletEntity>.from(jars);
    sorted.sort((a, b) {
      if (a.id == 'linked-savings-default' &&
          b.id != 'linked-savings-default') {
        return -1;
      }
      if (b.id == 'linked-savings-default' &&
          a.id != 'linked-savings-default') {
        return 1;
      }
      return a.name.compareTo(b.name);
    });
    return sorted;
  }

  void _openWalletReserveToJar(WalletEntity wallet) {
    final jars = _orderedJars(widget.cubit.state.budgetSetup.linkedWallets);
    if (jars.isEmpty) return;
    String jarId = jars.first.id;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialog) => AlertDialog(
          title: const Text('تخصيص من المحفظة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: jarId,
                decoration: const InputDecoration(labelText: 'الحصالة'),
                items: jars
                    .map((j) =>
                        DropdownMenuItem(value: j.id, child: Text(j.name)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setDialog(() => jarId = v);
                },
              ),
              const SizedBox(height: 8),
              TextField(
                controller: amountController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'المبلغ'),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                if (amount <= 0) return;
                final targetJar = jars.firstWhere((j) => j.id == jarId);
                await widget.cubit.addTransaction(
                  type: 'transfer',
                  fromWalletId: wallet.id,
                  toWalletId: targetJar.id,
                  amount: amount,
                  transferType: 'jar-allocation',
                  notes:
                      'تخصيص ${amount.toStringAsFixed(2)} من ${wallet.name} إلى ${targetJar.name}'
                      '${notesController.text.trim().isEmpty ? '' : ' - ${notesController.text.trim()}'}',
                );
                if (targetJar.id == 'linked-savings-default') {
                  await widget.cubit.applySavingsReserve(
                    walletId: wallet.id,
                    amount: amount,
                    action: 'allocate',
                  );
                }
                if (!mounted) return;
                Navigator.of(this.context).pop();
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
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
      child: AspectRatio(
        aspectRatio: 1.4,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Text(title,
              //     style: const TextStyle(
              //         fontWeight: FontWeight.bold, fontSize: 18)),
              // Text(subtitle,
              //     style: TextStyle(
              //         fontSize: 12,
              //         color: Theme.of(context)
              //             .colorScheme
              //             .onSurface
              //             .withValues(alpha: 0.5))),
              // const SizedBox(height: 8),
              Expanded(
                child: SingleChildScrollView(
                  physics: const NeverScrollableScrollPhysics(),
                  child: child,
                ),
              ),

              SizedBox(
                height: 36,
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: onMore,
                  child: const Text('المزيد'),
                ),
              ),
              const SizedBox(height: 4),
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
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(text,
          style: TextStyle(
              color: Theme.of(context)
                  .colorScheme
                  .onSurface
                  .withValues(alpha: 0.5))),
    );
  }
}
