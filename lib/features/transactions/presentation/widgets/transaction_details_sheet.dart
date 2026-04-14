import 'package:flutter/material.dart';

import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../screens/add_transaction_screen.dart';
import '../../domain/entities/transaction_entity.dart';

Future<void> openTransactionDetailsSheet(
  BuildContext context, {
  required AppCubit cubit,
  required TransactionEntity transaction,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (context) => SafeArea(
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            ..._detailRows(cubit, transaction),
            Text(
              transaction.notes?.isNotEmpty == true
                  ? transaction.notes!
                  : (transaction.type == 'income'
                      ? 'معاملة دخل'
                      : transaction.type == 'expense'
                          ? 'معاملة مصروف'
                          : 'معاملة تحويل'),
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () async {
                Navigator.pop(context);
                await showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (ctx) => FractionallySizedBox(
                    heightFactor: 0.96,
                    child: AddTransactionScreen(
                      cubit: cubit,
                      initialTransaction: transaction,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.edit_outlined),
              label: const Text('تعديل المعاملة'),
            ),
          ],
        ),
      ),
    ),
  );
}

List<Widget> _detailRows(AppCubit cubit, TransactionEntity tx) {
  final state = cubit.state;
  String walletName(String? id) =>
      state.wallets.where((w) => w.id == id).map((w) => w.name).cast<String?>().firstWhere((_) => true, orElse: () => id) ?? '-';
  String jarName(String? id) => state.budgetSetup.linkedWallets
      .where((j) => j.id == id)
      .map((j) => j.name)
      .cast<String?>()
      .firstWhere((_) => true, orElse: () => id) ?? '-';
  String allocName(String? id) => state.budgetSetup.allocations
      .where((a) => a.id == id)
      .map((a) => a.name)
      .cast<String?>()
      .firstWhere((_) => true, orElse: () => id) ?? '-';
  String categoryName(String? id) => state.categories
      .where((c) => c.id == id)
      .map((c) => c.name)
      .cast<String?>()
      .firstWhere((_) => true, orElse: () => id) ?? '-';
  final rows = <Widget>[
    _row('النوع', tx.type),
    _row('المبلغ', tx.amount.toStringAsFixed(2)),
    _row('التاريخ', '${tx.createdAt.day}/${tx.createdAt.month}/${tx.createdAt.year}'),
    _row(
      'الوقت',
      '${tx.createdAt.hour.toString().padLeft(2, '0')}:${tx.createdAt.minute.toString().padLeft(2, '0')}',
    ),
    if (tx.walletId != null) _row('المحفظة', walletName(tx.walletId)),
    if (tx.fromWalletId != null) _row('من محفظة', walletName(tx.fromWalletId)),
    if (tx.toWalletId != null) _row('إلى', jarName(tx.toWalletId)),
    if (tx.allocationId != null) _row('المخصص', allocName(tx.allocationId)),
    if (tx.categoryId != null) _row('الفئة', categoryName(tx.categoryId)),
    if (tx.budgetScope != null) _row('نطاق الميزانية', tx.budgetScope!),
    if (tx.transferType != null) _row('نوع التحويل', tx.transferType!),
  ];
  rows.add(const SizedBox(height: 10));
  return rows;
}

Widget _row(String label, String value) {
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
