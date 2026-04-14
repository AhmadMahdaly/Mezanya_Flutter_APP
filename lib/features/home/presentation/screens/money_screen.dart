import 'package:flutter/material.dart';

import '../../../app_state/presentation/cubits/app_cubit.dart';

class MoneyScreen extends StatelessWidget {
  const MoneyScreen({super.key, required this.cubit});

  final AppCubit cubit;

  @override
  Widget build(BuildContext context) {
    final state = cubit.state;
    final wallets = state.wallets;
    final txns = state.transactions;
    final budget = state.budgetSetup;

    final totalWalletBalances = wallets.fold<double>(0, (sum, wallet) => sum + wallet.balance);
    final actualIncome = txns.where((t) => t.type == 'income').fold<double>(0, (s, t) => s + t.amount);
    final actualExpenses = txns.where((t) => t.type == 'expense').fold<double>(0, (s, t) => s + t.amount);
    final recent = [...txns]..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    final chartItems = budget.allocations.map((allocation) {
      final planned = allocation.funding.fold<double>(0, (s, f) => s + f.plannedAmount);
      final spent = txns
          .where((t) => t.type == 'expense' && t.allocationId == allocation.id)
          .fold<double>(0, (s, t) => s + t.amount);
      return (name: allocation.name, planned: planned, spent: spent);
    }).where((item) => item.spent > 0).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: const Color(0xFF0F766E),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('إجمالي المحافظ الفعلية', style: TextStyle(color: Colors.white70)),
                const SizedBox(height: 6),
                Text(
                  '${totalWalletBalances.toStringAsFixed(2)} ${state.currencyCode}',
                  style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _mini('صافي الشهر', actualIncome - actualExpenses)),
                    const SizedBox(width: 8),
                    Expanded(child: _mini('إجمالي الدخل', actualIncome)),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('آخر المعاملات', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (recent.isEmpty)
                  const Text('لا توجد معاملات في هذا الشهر حتى الآن.')
                else
                  ...recent.take(5).map(
                    (t) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(t.notes ?? (t.type == 'expense' ? 'مصروف' : 'دخل')),
                      subtitle: Text('${t.createdAt.day}/${t.createdAt.month}/${t.createdAt.year}'),
                      trailing: Text(
                        '${t.type == 'expense' ? '-' : '+'}${t.amount.toStringAsFixed(2)}',
                        style: TextStyle(color: t.type == 'expense' ? Colors.red : Colors.green),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('تحليل المخصصات', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                if (chartItems.isEmpty)
                  const Text('لا توجد بيانات كافية للشارت حاليًا.')
                else
                  ...chartItems.take(4).map(
                    (item) {
                      final ratio = (item.spent / (item.planned <= 0 ? 1 : item.planned)).clamp(0, 1);
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.name),
                                Text('${item.spent.toStringAsFixed(2)} / ${item.planned.toStringAsFixed(2)}'),
                              ],
                            ),
                            const SizedBox(height: 6),
                            LinearProgressIndicator(value: ratio.toDouble(), minHeight: 8),
                          ],
                        ),
                      );
                    },
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _mini(String title, double value) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(color: Colors.white70, fontSize: 12)),
          const SizedBox(height: 4),
          Text(value.toStringAsFixed(2), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
