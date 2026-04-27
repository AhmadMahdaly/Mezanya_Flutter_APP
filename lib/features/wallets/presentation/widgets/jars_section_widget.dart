import 'package:flutter/material.dart';
import '../screens/full_jars_page.dart';
import '../screens/jar_editor_screen.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';

class JarsSectionWidget extends StatelessWidget {
  final AppCubit cubit;
  final int previewCount;

  const JarsSectionWidget({
    super.key,
    required this.cubit,
    this.previewCount = 2,
  });

  Future<void> _addJar(BuildContext context) async {
    final result = await Navigator.of(context).push<JarEditorResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => JarEditorScreen(
          incomeSources: cubit.state.budgetSetup.incomeSources,
          idFactory: (prefix) =>
              '$prefix-${DateTime.now().microsecondsSinceEpoch}',
        ),
      ),
    );

    if (result?.entity != null) {
      await cubit.addLinkedWallet(result!.entity!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final jars = cubit.state.budgetSetup.linkedWallets;

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
          Row(
            children: [
              const Text(
                'الحصالات',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              _circleAction(
                icon: Icons.add,
                onTap: () => _addJar(context),
              ),
              const SizedBox(width: 10),
              _circleAction(
                icon: Icons.swap_horiz,
                onTap: () => _transferBetweenJars(context),
              ),
            ],
          ),
          const SizedBox(height: 22),
          Expanded(
            child: jars.isEmpty
                ? Center(
                    child: Text(
                      'لا توجد حصالات',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                      ),
                    ),
                  )
                : ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount:
                        jars.length > previewCount ? previewCount : jars.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      return _jarCard(jars[index]);
                    },
                  ),
          ),
          const SizedBox(height: 16),
          InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => FullJarsPage(
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
          )
        ],
      ),
    );
  }

  void _transferBetweenJars(BuildContext context) {
    if (cubit.state.budgetSetup.linkedWallets.length < 2) {
      return;
    }

    showDialog(
      context: context,
      builder: (_) {
        String fromId = cubit.state.budgetSetup.linkedWallets.first.id;

        String toId = cubit.state.budgetSetup.linkedWallets[1].id;

        final amountController = TextEditingController();

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('تحويل بين الحصالات'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField(
                    initialValue: fromId,
                    items: cubit.state.budgetSetup.linkedWallets
                        .map(
                          (j) => DropdownMenuItem(
                            value: j.id,
                            child: Text(j.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => fromId = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField(
                    initialValue: toId,
                    items: cubit.state.budgetSetup.linkedWallets
                        .map(
                          (j) => DropdownMenuItem(
                            value: j.id,
                            child: Text(j.name),
                          ),
                        )
                        .toList(),
                    onChanged: (v) {
                      if (v == null) return;
                      setState(() => toId = v);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ',
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('إلغاء'),
                ),
                FilledButton(
                  onPressed: () {
                    Navigator.pop(context);

                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'اربط transfer logic القديم هنا',
                        ),
                      ),
                    );
                  },
                  child: const Text('تحويل'),
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
  Widget build(BuildContext context) {
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

Widget _jarCard(dynamic jar) {
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
            borderRadius: BorderRadius.circular(18),
          ),
          child: const Icon(Icons.savings),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                jar.name,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                jar.balance.toStringAsFixed(2),
              ),
            ],
          ),
        )
      ],
    ),
  );
}
