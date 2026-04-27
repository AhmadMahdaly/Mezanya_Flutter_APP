import 'package:flutter/material.dart';
import '../screens/full_wallets_page.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';

class WalletsSectionWidget extends StatelessWidget {
  final AppCubit cubit;
  final int previewCount;

  const WalletsSectionWidget({
    super.key,
    required this.cubit,
    this.previewCount = 2,
  });

  @override
  Widget build(BuildContext context) {
    final wallets = cubit.state.wallets;

    return Container(
      height: 430,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: Colors.grey.shade300,
        ),
      ),
      child: Column(
        children: [
          /// HEADER
          Row(
            children: [
              const Text(
                'المحافظ',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              _circleAction(
                icon: Icons.add,
                onTap: () {
                  _openAddWalletDialog(
                    context,
                  );
                },
              ),
              const SizedBox(width: 10),
              _circleAction(
                icon: Icons.swap_horiz,
                onTap: () {
                  _openTransferDialog(
                    context,
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 22),

          /// PREVIEW ONLY
          Expanded(
            child: wallets.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد محافظ بعد',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: wallets.length > previewCount
                        ? previewCount
                        : wallets.length,
                    separatorBuilder: (_, __) => const SizedBox(
                      height: 16,
                    ),
                    itemBuilder: (context, index) {
                      final wallet = wallets[index];

                      return _walletCard(
                        wallet,
                      );
                    },
                  ),
          ),

          const SizedBox(height: 16),

          /// MORE BUTTON
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullWalletsPage(
                    cubit: cubit,
                  ),
                ),
              );
            },
            borderRadius: BorderRadius.circular(18),
            child: Container(
              height: 54,
              width: double.infinity,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: const Text(
                'المزيد',
                style: TextStyle(
                  fontSize: 23,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openAddWalletDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) {
        final nameController = TextEditingController();

        final balanceController = TextEditingController();

        return AlertDialog(
          title: const Text(
            'إضافة محفظة',
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'اسم المحفظة',
                ),
              ),
              const SizedBox(
                height: 12,
              ),
              TextField(
                controller: balanceController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'الرصيد',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(
                  context,
                );
              },
              child: const Text('إلغاء'),
            ),
            FilledButton(
              onPressed: () async {
                final name = nameController.text.trim();

                final balance = double.tryParse(
                      balanceController.text,
                    ) ??
                    0;

                if (name.isEmpty) {
                  return;
                }

                await cubit.addWallet(
                  name: name,
                  openingBalance: balance,
                );

                if (context.mounted) {
                  Navigator.pop(
                    context,
                  );
                }
              },
              child: const Text('حفظ'),
            )
          ],
        );
      },
    );
  }

  void _openTransferDialog(BuildContext context) {
    if (cubit.state.wallets.length < 2) {
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        String fromId = cubit.state.wallets.first.id;

        String toId = cubit.state.wallets[1].id;

        final amountController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'تحويل بين المحافظ',
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    initialValue: fromId,
                    items: cubit.state.wallets
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(
                        () => fromId = v,
                      );
                    },
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  DropdownButtonFormField<String>(
                    initialValue: toId,
                    items: cubit.state.wallets
                        .map(
                          (w) => DropdownMenuItem(
                            value: w.id,
                            child: Text(w.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(
                        () => toId = v,
                      );
                    },
                  ),
                  const SizedBox(
                    height: 12,
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ',
                    ),
                  )
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(
                      context,
                    );
                  },
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () async {
                    final amount = double.tryParse(
                          amountController.text,
                        ) ??
                        0;

                    if (amount <= 0 || fromId == toId) {
                      return;
                    }

                    await cubit.addTransaction(
                      type: 'transfer',
                      amount: amount,
                      fromWalletId: fromId,
                      toWalletId: toId,
                      transferType: 'wallet-to-wallet',
                      notes: 'تحويل بين المحافظ',
                    );

                    if (context.mounted) {
                      Navigator.pop(
                        context,
                      );
                    }
                  },
                  child: const Text('تنفيذ'),
                )
              ],
            );
          },
        );
      },
    );
  }
}

class _circleAction extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _circleAction({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(
    BuildContext context,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(40),
      child: Container(
        width: 46,
        height: 46,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.grey.shade300,
          ),
        ),
        child: Icon(icon),
      ),
    );
  }
}

Widget _walletCard(
  dynamic wallet,
) {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: Colors.grey.shade50,
      borderRadius: BorderRadius.circular(24),
    ),
    child: Row(
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(
              18,
            ),
          ),
          child: const Icon(
            Icons.account_balance_wallet,
          ),
        ),
        const SizedBox(
          width: 14,
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                wallet.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(
                height: 6,
              ),
              Text(
                wallet.balance.toStringAsFixed(2),
              ),
            ],
          ),
        )
      ],
    ),
  );
}
