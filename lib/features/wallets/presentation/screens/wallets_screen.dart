import 'package:flutter/material.dart';

import '../../../../core/widgets/app_icon_picker_dialog.dart';
import '../../../app_state/domain/entities/app_state_entity.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../../budget/domain/entities/budget_setup_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../transactions/presentation/widgets/transaction_details_sheet.dart';
import '../../domain/entities/wallet_entity.dart';
import 'jar_editor_screen.dart';

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

    return ListView(
      // physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 20),
      children: [
        _SectionShell(
          title: 'المحافظ',
          subtitle:
              'الأرصدة الفعلية التي تملكها الآن، مع توضيح الجزء المتاح والجزء المحجوز داخل الحصالات.',
          actionLabel: 'إضافة محفظة',
          onAction: () => _openWalletEditor(),
          trailing: IconButton(
            onPressed: wallets.length < 2 ? null : _openWalletTransferDialog,
            icon: const Icon(Icons.swap_horiz_rounded),
            tooltip: 'تحويل بين المحافظ',
          ),
          child: wallets.isEmpty
              ? const _EmptyStateCard(
                  title: 'لا توجد محافظ بعد',
                  subtitle:
                      'أضف محفظة فعلية مثل الكاش أو البنك لتبدأ المتابعة.',
                )
              : Column(
                  children: wallets
                      .map(
                        (wallet) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _walletCard(state, wallet),
                        ),
                      )
                      .toList(),
                ),
        ),
        const SizedBox(height: 16),
        _SectionShell(
          title: 'الحصالات',
          subtitle:
              'الحصالة مساحة افتراضية لحجز جزء من أرصدة المحافظ الفعلية وتنظيمها بعيدًا عن الصرف اليومي.',
          actionLabel: 'إضافة حصالة',
          onAction: () => _openJarEditor(),
          child: jars.isEmpty
              ? const _EmptyStateCard(
                  title: 'لا توجد حصالات بعد',
                  subtitle:
                      'أنشئ حصالة لتوزيع المال المحجوز بين الادخار أو السكن أو أي هدف آخر.',
                )
              : Column(
                  children: jars
                      .map(
                        (jar) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _jarCard(state, jar),
                        ),
                      )
                      .toList(),
                ),
        ),
      ],
    );
  }

  Widget _walletCard(AppStateEntity state, WalletEntity wallet) {
    final reserved = _walletReservedAmount(state, wallet.id);
    final available = wallet.balance - reserved;
    final accent = _parseColor(wallet.iconColor ?? '#165b47');
    final hasMultipleWallets = state.wallets.length >= 2;

    return InkWell(
      onTap: () => _openWalletDetailsSheet(wallet),
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الهيدر: نوع البطاقة + الإجراءات السريعة
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'محفظة',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (hasMultipleWallets)
                      IconButton(
                        onPressed: _openWalletTransferDialog,
                        icon: const Icon(Icons.swap_horiz_rounded),
                        color: const Color(0xFF7A725F),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        tooltip: 'تحويل بين المحافظ',
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _openWalletAllocateToJarDialog(wallet),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: const Color(0xFF7A725F),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      tooltip: 'تخصيص مبلغ',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // الصندوق الداخلي (البيانات الرئيسية كما في الرسمة)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE4DCCF), width: 1.5),
              ),
              child: Row(
                children: [
                  _iconBubble(
                    iconName: wallet.icon ?? 'account_balance_wallet',
                    colorHex: wallet.iconColor ?? '#165b47',
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      wallet.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${wallet.balance.toStringAsFixed(0)} جنيه',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF7D7461),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // الفوتر (المزيد من التفاصيل + بيانات مساعدة)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المزيد من التفاصيل',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  reserved > 0
                      ? 'محجوز: ${reserved.toStringAsFixed(2)} جنيه'
                      : 'متاح: ${available.toStringAsFixed(2)} جنيه',
                  style: const TextStyle(
                    color: Color(0xFF7D7461),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _jarCard(AppStateEntity state, LinkedWalletEntity jar) {
    final accent = _parseColor(jar.iconColor);
    final distribution = _jarDistribution(state, jar.id);

    return InkWell(
      onTap: () => _openJarDetailsSheet(jar),
      borderRadius: BorderRadius.circular(26),
      child: Ink(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF4),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(color: accent.withValues(alpha: 0.2)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // الهيدر
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'حصالة',
                    style: TextStyle(
                      color: accent,
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (distribution.isNotEmpty)
                      IconButton(
                        onPressed: () =>
                            _openInternalTransferDialog(sourceJar: jar),
                        icon: const Icon(Icons.swap_horiz_rounded),
                        color: const Color(0xFF7A725F),
                        padding: EdgeInsets.zero,
                        constraints:
                            const BoxConstraints(minWidth: 36, minHeight: 36),
                        tooltip: 'تحويل داخلي',
                      ),
                    const SizedBox(width: 4),
                    IconButton(
                      onPressed: () => _openJarAdjustmentDialog(
                        jar: jar,
                        mode: _JarAdjustmentMode.allocate,
                      ),
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      color: const Color(0xFF7A725F),
                      padding: EdgeInsets.zero,
                      constraints:
                          const BoxConstraints(minWidth: 36, minHeight: 36),
                      tooltip: 'تخصيص للحصالة',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 16),

            // الصندوق الداخلي
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE4DCCF), width: 1.5),
              ),
              child: Row(
                children: [
                  _iconBubble(
                    iconName: jar.icon,
                    colorHex: jar.iconColor,
                    size: 52,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      jar.name,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${jar.balance.toStringAsFixed(0)} جنيه',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Color(0xFF7D7461),
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // الفوتر
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'المزيد من التفاصيل',
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                Text(
                  'مخصص شهرياً: ${jar.monthlyAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Color(0xFF7D7461),
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWalletDetailsSheet(WalletEntity wallet) async {
    final state = widget.cubit.state;
    final reserved = _walletReservedAmount(state, wallet.id);
    final available = wallet.balance - reserved;
    final reservations = _walletReservations(state, wallet.id);
    final transactions = state.transactions
        .where(
          (transaction) =>
              (transaction.walletId == wallet.id ||
                  transaction.fromWalletId == wallet.id ||
                  transaction.toWalletId == wallet.id) &&
              !_isVirtualJarTransaction(transaction),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DetailsSheetShell(
          child: Column(
            children: [
              _heroCard(
                title: wallet.name,
                icon: wallet.icon ?? 'account_balance_wallet',
                colorHex: wallet.iconColor ?? '#165b47',
                onEdit: () {
                  Navigator.of(context).pop();
                  _openWalletEditor(current: wallet);
                },
                rows: [
                  _heroMetric(
                      'إجمالي الرصيد', wallet.balance.toStringAsFixed(2)),
                  _heroMetric('الصافي المتاح', available.toStringAsFixed(2)),
                  _heroMetric('المحجوز للحصالات', reserved.toStringAsFixed(2)),
                ],
              ),
              const Divider(height: 1, color: Color(0xFFD6D0C2)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  children: [
                    _sectionHeader('الحصص المحجوزة للحصالات'),
                    const SizedBox(height: 10),
                    if (reservations.isEmpty)
                      const _InlineNote(
                        text:
                            'لا يوجد أي مبلغ محجوز من هذه المحفظة داخل الحصالات حتى الآن.',
                      )
                    else
                      ...reservations.entries.map((entry) {
                        final jar = state.budgetSetup.linkedWallets.firstWhere(
                          (item) => item.id == entry.key,
                          orElse: () => LinkedWalletEntity(
                            id: entry.key,
                            name: 'حصالة',
                            balance: entry.value,
                            monthlyAmount: 0,
                            executionDay: 1,
                            fundingSource: '',
                            funding: const [],
                            icon: 'savings',
                            iconColor: '#0f766e',
                            automationType: 'confirm',
                            categories: const [],
                          ),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SimpleValueTile(
                            title: jar.name,
                            subtitle: 'جزء محجوز من هذه المحفظة',
                            value: entry.value.toStringAsFixed(2),
                            icon: jar.icon,
                            colorHex: jar.iconColor,
                            onTap: () {
                              Navigator.of(context).pop();
                              _openJarDetailsSheet(jar);
                            },
                          ),
                        );
                      }),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: () => _openWalletAllocateToJarDialog(wallet),
                        icon: const Icon(Icons.add_circle_outline_rounded),
                        label:
                            const Text('تخصيص مبلغ من هذه المحفظة إلى حصالة'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionHeader('المعاملات'),
                    const SizedBox(height: 10),
                    if (transactions.isEmpty)
                      const _InlineNote(
                        text:
                            'لا توجد معاملات فعلية مسجلة على هذه المحفظة حتى الآن.',
                      )
                    else
                      ...transactions.map(
                        (transaction) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _TransactionTile(
                            transaction: transaction,
                            onTap: () => openTransactionDetailsSheet(
                              context,
                              cubit: widget.cubit,
                              transaction: transaction,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openJarDetailsSheet(LinkedWalletEntity jar) async {
    final state = widget.cubit.state;
    final distribution = _jarDistribution(state, jar.id);
    final relevantTransactions = state.transactions
        .where(
          (transaction) =>
              transaction.toWalletId == jar.id ||
              transaction.walletId == jar.id ||
              (transaction.type == 'income' &&
                  transaction.toWalletId == jar.id),
        )
        .where(
          (transaction) =>
              transaction.transferType == 'jar-allocation' ||
              transaction.transferType == 'jar-allocation-cancel' ||
              transaction.transferType == 'jar-allocation-spend' ||
              transaction.transferType == 'jar-funding' ||
              transaction.transferType == 'allocation-to-jar' ||
              transaction.transferType == 'jar-to-allocation' ||
              (transaction.type == 'income' &&
                  transaction.budgetScope == 'within-budget'),
        )
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _DetailsSheetShell(
          child: Column(
            children: [
              _heroCard(
                title: jar.name,
                icon: jar.icon,
                colorHex: jar.iconColor,
                onEdit: () {
                  Navigator.of(context).pop();
                  _openJarEditor(current: jar);
                },
                rows: [
                  _heroMetric('إجمالي الحصالة', jar.balance.toStringAsFixed(2)),
                  _heroMetric(
                    'المخصص الشهري',
                    jar.monthlyAmount.toStringAsFixed(2),
                  ),
                  _heroMetric(
                    'عدد المحافظ المرتبطة',
                    distribution.length.toString(),
                  ),
                ],
              ),
              const Divider(height: 1, color: Color(0xFFD6D0C2)),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  children: [
                    _sectionHeader('توزيع رصيد الحصالة على المحافظ'),
                    const SizedBox(height: 10),
                    if (distribution.isEmpty)
                      const _InlineNote(
                        text:
                            'لا يوجد تخصيص فعلي لهذه الحصالة بعد. يمكنك تخصيص مبلغ لها من أي محفظة.',
                      )
                    else
                      ...distribution.entries.map((entry) {
                        final wallet = state.wallets.firstWhere(
                          (item) => item.id == entry.key,
                          orElse: () => WalletEntity(
                            id: entry.key,
                            name: 'محفظة',
                            balance: entry.value,
                          ),
                        );
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _SimpleValueTile(
                            title: wallet.name,
                            subtitle: 'جزء من رصيد الحصالة',
                            value: entry.value.toStringAsFixed(2),
                            icon: wallet.icon ?? 'account_balance_wallet',
                            colorHex: wallet.iconColor ?? '#165b47',
                            onTap: () {
                              Navigator.of(context).pop();
                              _openWalletDetailsSheet(wallet);
                            },
                          ),
                        );
                      }),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openJarAdjustmentDialog(
                              jar: jar,
                              mode: _JarAdjustmentMode.allocate,
                            ),
                            icon: const Icon(Icons.add_circle_outline_rounded),
                            label: const Text('تخصيص'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: distribution.isEmpty
                                ? null
                                : () => _openJarAdjustmentDialog(
                                      jar: jar,
                                      mode: _JarAdjustmentMode.cancel,
                                    ),
                            icon:
                                const Icon(Icons.remove_circle_outline_rounded),
                            label: const Text('إلغاء تخصيص'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: distribution.isEmpty
                            ? null
                            : () => _openInternalTransferDialog(sourceJar: jar),
                        icon: const Icon(Icons.swap_horiz_rounded),
                        label: const Text('تحويل داخلي'),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _sectionHeader('سجل الحصالة'),
                    const SizedBox(height: 10),
                    if (relevantTransactions.isEmpty)
                      const _InlineNote(
                        text: 'لا توجد حركات مسجلة على هذه الحصالة حتى الآن.',
                      )
                    else
                      ...relevantTransactions.map(
                        (transaction) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _TransactionTile(
                            transaction: transaction,
                            onTap: () => openTransactionDetailsSheet(
                              context,
                              cubit: widget.cubit,
                              transaction: transaction,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openJarAdjustmentDialog({
    required LinkedWalletEntity jar,
    required _JarAdjustmentMode mode,
  }) async {
    final state = widget.cubit.state;
    final sourceDistribution = _jarDistribution(state, jar.id);
    final availableWallets = mode == _JarAdjustmentMode.allocate
        ? state.wallets
        : state.wallets
            .where((wallet) => (sourceDistribution[wallet.id] ?? 0) > 0)
            .toList();
    if (availableWallets.isEmpty) {
      return;
    }

    var walletId = availableWallets.first.id;
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final selectedReserved = sourceDistribution[walletId] ?? 0;
          final title = switch (mode) {
            _JarAdjustmentMode.allocate => 'تخصيص مبلغ للحصالة',
            _JarAdjustmentMode.cancel => 'إلغاء تخصيص من الحصالة',
          };
          final actionLabel = switch (mode) {
            _JarAdjustmentMode.allocate => 'تأكيد التخصيص',
            _JarAdjustmentMode.cancel => 'تأكيد الإلغاء',
          };

          return AlertDialog(
            title: Text(title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: walletId,
                  decoration: const InputDecoration(labelText: 'المحفظة'),
                  items: availableWallets
                      .map(
                        (wallet) => DropdownMenuItem<String>(
                          value: wallet.id,
                          child: Text(wallet.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => walletId = value);
                  },
                ),
                if (mode == _JarAdjustmentMode.cancel) ...[
                  const SizedBox(height: 8),
                  Align(
                    alignment: AlignmentDirectional.centerStart,
                    child: Text(
                      'المتاح إلغاؤه من هذه المحفظة ${selectedReserved.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(amountController.text.trim()) ?? 0;
                  if (amount <= 0) {
                    return;
                  }
                  if (mode == _JarAdjustmentMode.cancel &&
                      amount > selectedReserved) {
                    return;
                  }

                  await widget.cubit.addTransaction(
                    type: mode == _JarAdjustmentMode.allocate
                        ? 'transfer'
                        : 'expense',
                    walletId: mode == _JarAdjustmentMode.cancel ? jar.id : null,
                    fromWalletId: walletId,
                    toWalletId: jar.id,
                    amount: amount,
                    transferType: mode == _JarAdjustmentMode.allocate
                        ? 'jar-allocation'
                        : 'jar-allocation-cancel',
                    notes: notesController.text.trim().isEmpty
                        ? (mode == _JarAdjustmentMode.allocate
                            ? 'تخصيص ${amount.toStringAsFixed(2)} إلى ${jar.name}'
                            : 'إلغاء تخصيص ${amount.toStringAsFixed(2)} من ${jar.name}')
                        : notesController.text.trim(),
                  );

                  if (jar.id == 'linked-savings-default') {
                    await widget.cubit.applySavingsReserve(
                      walletId: walletId,
                      amount: amount,
                      action: mode == _JarAdjustmentMode.allocate
                          ? 'allocate'
                          : 'cancel',
                    );
                  }

                  if (!mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                },
                child: Text(actionLabel),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openInternalTransferDialog({
    required LinkedWalletEntity sourceJar,
  }) async {
    final state = widget.cubit.state;
    final sourceDistribution = _jarDistribution(state, sourceJar.id);
    final sourceWallets = state.wallets
        .where((wallet) => (sourceDistribution[wallet.id] ?? 0) > 0)
        .toList();
    final otherJars = _orderedJars(state.budgetSetup.linkedWallets)
        .where((jar) => jar.id != sourceJar.id)
        .toList();
    if (sourceWallets.isEmpty || otherJars.isEmpty) {
      return;
    }

    var walletId = sourceWallets.first.id;
    var targetJarId = otherJars.first.id;
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final availableAmount = sourceDistribution[walletId] ?? 0;
          return AlertDialog(
            title: const Text('تحويل داخلي'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: walletId,
                  decoration: const InputDecoration(
                    labelText: 'من أي محفظة فعلية؟',
                  ),
                  items: sourceWallets
                      .map(
                        (wallet) => DropdownMenuItem<String>(
                          value: wallet.id,
                          child: Text(
                            '${wallet.name} • ${sourceDistribution[wallet.id]!.toStringAsFixed(2)}',
                          ),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => walletId = value);
                  },
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  initialValue: targetJarId,
                  decoration: const InputDecoration(
                    labelText: 'إلى أي حصالة؟',
                  ),
                  items: otherJars
                      .map(
                        (jar) => DropdownMenuItem<String>(
                          value: jar.id,
                          child: Text(jar.name),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setDialogState(() => targetJarId = value);
                  },
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: AlignmentDirectional.centerStart,
                  child: Text(
                    'المتاح نقله من هذه المحفظة داخل الحصالة ${availableAmount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountController,
                  keyboardType:
                      const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(labelText: 'المبلغ'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(labelText: 'ملاحظات'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('إلغاء'),
              ),
              FilledButton(
                onPressed: () async {
                  final amount =
                      double.tryParse(amountController.text.trim()) ?? 0;
                  if (amount <= 0 || amount > availableAmount) {
                    return;
                  }

                  final targetJar = state.budgetSetup.linkedWallets.firstWhere(
                    (jar) => jar.id == targetJarId,
                  );
                  final note = notesController.text.trim().isEmpty
                      ? 'تحويل داخلي من ${sourceJar.name} إلى ${targetJar.name}'
                      : notesController.text.trim();

                  await widget.cubit.addTransaction(
                    type: 'expense',
                    walletId: sourceJar.id,
                    fromWalletId: walletId,
                    toWalletId: sourceJar.id,
                    amount: amount,
                    transferType: 'jar-allocation-cancel',
                    notes: note,
                  );
                  if (sourceJar.id == 'linked-savings-default') {
                    await widget.cubit.applySavingsReserve(
                      walletId: walletId,
                      amount: amount,
                      action: 'cancel',
                    );
                  }

                  await widget.cubit.addTransaction(
                    type: 'transfer',
                    fromWalletId: walletId,
                    toWalletId: targetJar.id,
                    amount: amount,
                    transferType: 'jar-allocation',
                    notes: note,
                  );
                  if (targetJar.id == 'linked-savings-default') {
                    await widget.cubit.applySavingsReserve(
                      walletId: walletId,
                      amount: amount,
                      action: 'allocate',
                    );
                  }

                  if (!mounted) {
                    return;
                  }
                  Navigator.of(context).pop();
                },
                child: const Text('تنفيذ التحويل'),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openWalletAllocateToJarDialog(WalletEntity wallet) async {
    final jars = _orderedJars(widget.cubit.state.budgetSetup.linkedWallets);
    if (jars.isEmpty) {
      return;
    }

    var jarId = jars.first.id;
    final amountController = TextEditingController();
    final notesController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تخصيص من المحفظة إلى حصالة'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: jarId,
                decoration: const InputDecoration(labelText: 'الحصالة'),
                items: jars
                    .map(
                      (jar) => DropdownMenuItem<String>(
                        value: jar.id,
                        child: Text(jar.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => jarId = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'المبلغ'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: notesController,
                decoration: const InputDecoration(labelText: 'ملاحظات'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                if (amount <= 0) {
                  return;
                }
                final targetJar = jars.firstWhere((jar) => jar.id == jarId);
                await widget.cubit.addTransaction(
                  type: 'transfer',
                  fromWalletId: wallet.id,
                  toWalletId: targetJar.id,
                  amount: amount,
                  transferType: 'jar-allocation',
                  notes: notesController.text.trim().isEmpty
                      ? 'تخصيص ${amount.toStringAsFixed(2)} من ${wallet.name} إلى ${targetJar.name}'
                      : notesController.text.trim(),
                );
                if (targetJar.id == 'linked-savings-default') {
                  await widget.cubit.applySavingsReserve(
                    walletId: wallet.id,
                    amount: amount,
                    action: 'allocate',
                  );
                }
                if (!mounted) {
                  return;
                }
                Navigator.of(context).pop();
              },
              child: const Text('تأكيد'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openWalletTransferDialog() async {
    final wallets = widget.cubit.state.wallets;
    if (wallets.length < 2) {
      return;
    }
    var fromId = wallets.first.id;
    var toId = wallets[1].id;
    final amountController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('تحويل بين المحافظ'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: fromId,
                decoration: const InputDecoration(labelText: 'من محفظة'),
                items: wallets
                    .map(
                      (wallet) => DropdownMenuItem<String>(
                        value: wallet.id,
                        child: Text(wallet.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => fromId = value);
                },
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: toId,
                decoration: const InputDecoration(labelText: 'إلى محفظة'),
                items: wallets
                    .map(
                      (wallet) => DropdownMenuItem<String>(
                        value: wallet.id,
                        child: Text(wallet.name),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => toId = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: amountController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'المبلغ'),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final amount =
                    double.tryParse(amountController.text.trim()) ?? 0;
                if (amount <= 0 || fromId == toId) {
                  return;
                }
                await widget.cubit.addTransaction(
                  type: 'transfer',
                  amount: amount,
                  fromWalletId: fromId,
                  toWalletId: toId,
                  transferType: 'wallet-to-wallet',
                  notes: 'تحويل بين المحافظ',
                );
                if (!mounted) {
                  return;
                }
                Navigator.of(context).pop();
              },
              child: const Text('تنفيذ'),
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
    var selectedColor = current?.iconColor ?? '#165b47';
    var selectedIcon = current?.icon ?? 'account_balance_wallet';

    showDialog<void>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(current == null ? 'إضافة محفظة' : 'تعديل المحفظة'),
          content: SizedBox(
            width: 540,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(labelText: 'اسم المحفظة'),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: balanceController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(
                      labelText: 'الرصيد الفعلي',
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () async {
                      final picked = await AppIconPickerDialog.show(
                        context,
                        initialIconName: selectedIcon,
                        initialColorHex: selectedColor,
                        title: 'اختيار أيقونة المحفظة',
                      );
                      if (picked == null) {
                        return;
                      }
                      setDialogState(() {
                        selectedIcon = picked.iconName;
                        selectedColor = picked.colorHex;
                      });
                    },
                    icon: const Icon(Icons.palette_outlined),
                    label: const Text('اختيار الأيقونة واللون'),
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
                  if (!mounted) {
                    return;
                  }
                  Navigator.of(this.context).pop();
                },
                child: const Text(
                  'حذف',
                  style: TextStyle(color: Color(0xFFB3261E)),
                ),
              ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();
                final balance =
                    double.tryParse(balanceController.text.trim()) ?? 0;
                if (name.isEmpty) {
                  return;
                }
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
                if (!mounted) {
                  return;
                }
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

  Map<String, double> _walletReservations(
      AppStateEntity state, String walletId) {
    final result = <String, double>{};
    for (final transaction in state.transactions) {
      if (transaction.fromWalletId != walletId ||
          transaction.toWalletId == null) {
        continue;
      }
      final jarId = transaction.toWalletId!;
      if (transaction.transferType == 'jar-allocation' ||
          transaction.transferType == 'jar-funding' ||
          transaction.transferType == 'allocation-to-jar') {
        result[jarId] = (result[jarId] ?? 0) + transaction.amount;
      } else if (transaction.transferType == 'jar-allocation-cancel' ||
          transaction.transferType == 'jar-allocation-spend' ||
          transaction.transferType == 'jar-to-allocation') {
        result[jarId] = (result[jarId] ?? 0) - transaction.amount;
      }
    }
    for (final transaction in state.transactions) {
      if (transaction.type == 'income' &&
          transaction.budgetScope == 'within-budget' &&
          transaction.walletId == walletId &&
          transaction.toWalletId != null) {
        final jarId = transaction.toWalletId!;
        result[jarId] = (result[jarId] ?? 0) + transaction.amount;
      }
    }
    result.removeWhere((key, value) => value <= 0);
    return result;
  }

  Map<String, double> _jarDistribution(AppStateEntity state, String jarId) {
    final result = <String, double>{};
    for (final transaction in state.transactions) {
      if (transaction.toWalletId != jarId && transaction.walletId != jarId) {
        continue;
      }
      final walletId = transaction.fromWalletId ?? transaction.walletId;
      if (walletId == null) {
        continue;
      }
      if (transaction.transferType == 'jar-allocation' ||
          transaction.transferType == 'jar-funding' ||
          transaction.transferType == 'allocation-to-jar' ||
          (transaction.type == 'income' &&
              transaction.budgetScope == 'within-budget' &&
              transaction.toWalletId == jarId)) {
        result[walletId] = (result[walletId] ?? 0) + transaction.amount;
      } else if (transaction.transferType == 'jar-allocation-cancel' ||
          transaction.transferType == 'jar-allocation-spend' ||
          transaction.transferType == 'jar-to-allocation') {
        result[walletId] = (result[walletId] ?? 0) - transaction.amount;
      }
    }
    result.removeWhere((key, value) => value <= 0);
    return result;
  }

  double _walletReservedAmount(AppStateEntity state, String walletId) {
    return _walletReservations(state, walletId)
        .values
        .fold<double>(0, (sum, item) => sum + item);
  }

  bool _isVirtualJarTransaction(TransactionEntity transaction) {
    return transaction.transferType == 'jar-allocation' ||
        transaction.transferType == 'jar-allocation-cancel' ||
        transaction.transferType == 'jar-allocation-spend' ||
        transaction.transferType == 'jar-funding' ||
        transaction.transferType == 'allocation-to-jar' ||
        transaction.transferType == 'jar-to-allocation';
  }

  Widget _iconBubble({
    required String iconName,
    required String colorHex,
    double size = 48,
  }) {
    final color = _parseColor(colorHex);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size / 3),
      ),
      child: Center(
        child: AppIconPickerDialog.iconWidgetForName(
          iconName,
          color: color,
          size: size * 0.42,
        ),
      ),
    );
  }

  Widget _metricChip({
    required String label,
    required String value,
    bool emphasize = false,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F3E7),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Color(0xFF7D7461)),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: emphasize ? 20 : 18,
              fontWeight: FontWeight.w900,
              color: valueColor ?? const Color(0xFF241F17),
            ),
          ),
        ],
      ),
    );
  }

  Widget _pillLabel(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEDF),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          color: Color(0xFF73695A),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  MapEntry<String, String> _heroMetric(String label, String value) {
    return MapEntry(label, value);
  }

  Widget _heroCard({
    required String title,
    required String icon,
    required String colorHex,
    required VoidCallback onEdit,
    required List<MapEntry<String, String>> rows,
  }) {
    final accent = _parseColor(colorHex);
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF1),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: accent.withValues(alpha: 0.20)),
        boxShadow: [
          BoxShadow(
            color: accent.withValues(alpha: 0.10),
            blurRadius: 22,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.settings_outlined),
                tooltip: 'تعديل',
              ),
              const Spacer(),
              Expanded(
                flex: 5,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              _iconBubble(iconName: icon, colorHex: colorHex, size: 64),
            ],
          ),
          const SizedBox(height: 14),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      row.value,
                      textAlign: TextAlign.left,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    row.key,
                    style: const TextStyle(
                      color: Color(0xFF6E6558),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Align(
      alignment: AlignmentDirectional.centerEnd,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
      ),
    );
  }

  Color _parseColor(String hex) {
    final normalized = hex.replaceAll('#', '');
    final value = int.tryParse(normalized, radix: 16) ?? 0xFF165B47;
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
}

enum _JarAdjustmentMode { allocate, cancel }

class _SectionShell extends StatelessWidget {
  const _SectionShell({
    required this.title,
    required this.subtitle,
    required this.child,
    required this.actionLabel,
    required this.onAction,
    this.trailing,
  });

  final String title;
  final String subtitle;
  final Widget child;
  final String actionLabel;
  final VoidCallback onAction;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFE0D7C8)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF165B47).withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (trailing != null) trailing!,
              const Spacer(),
              Expanded(
                flex: 6,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      title,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      subtitle,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: Color(0xFF6E6558),
                        height: 1.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: onAction,
              icon: const Icon(Icons.add_rounded),
              label: Text(actionLabel),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailsSheetShell extends StatelessWidget {
  const _DetailsSheetShell({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.88,
      minChildSize: 0.54,
      maxChildSize: 0.95,
      builder: (context, controller) => Container(
        decoration: const BoxDecoration(
          color: Color(0xFFFCF7EC),
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: child,
      ),
    );
  }
}

class _SimpleValueTile extends StatelessWidget {
  const _SimpleValueTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.icon,
    required this.colorHex,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final String value;
  final String icon;
  final String colorHex;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(
      0xFF000000 |
          (int.tryParse(colorHex.replaceAll('#', ''), radix: 16) ?? 0x165B47),
    );
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: color.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      color: Color(0xFF7A725F),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    title,
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 22,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: AppIconPickerDialog.iconWidgetForName(
                        icon,
                        color: color,
                        size: 26,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_left_rounded),
          ],
        ),
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({
    required this.transaction,
    required this.onTap,
  });

  final TransactionEntity transaction;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isNegative = transaction.type == 'expense' ||
        transaction.transferType == 'jar-allocation-cancel' ||
        transaction.transferType == 'jar-allocation-spend';
    final label = switch (transaction.transferType) {
      'jar-allocation' => 'تخصيص للحصالة',
      'jar-allocation-cancel' => 'إلغاء تخصيص',
      'jar-allocation-spend' => 'سحب من المحجوز',
      'jar-funding' => 'تمويل تلقائي للحصالة',
      'wallet-to-wallet' => 'تحويل بين المحافظ',
      _ => transaction.notes ??
          switch (transaction.type) {
            'income' => 'دخل',
            'expense' => 'مصروف',
            _ => 'تحويل',
          },
    };

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Ink(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE4DCCF)),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${isNegative ? '-' : '+'}${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 20,
                      color: isNegative
                          ? const Color(0xFFB3261E)
                          : const Color(0xFF165B47),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${transaction.createdAt.day}/${transaction.createdAt.month}/${transaction.createdAt.year}',
                    style: const TextStyle(color: Color(0xFF7D7461)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.right,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_left_rounded),
          ],
        ),
      ),
    );
  }
}

class _InlineNote extends StatelessWidget {
  const _InlineNote({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF3EEDF),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFF72685A),
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  const _EmptyStateCard({
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFE4DCCF)),
      ),
      child: Column(
        children: [
          const Icon(Icons.inbox_outlined, size: 34, color: Color(0xFF7A725F)),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF72685A),
              height: 1.5,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
