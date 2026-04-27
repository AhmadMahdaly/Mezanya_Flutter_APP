import 'package:flutter/material.dart';

class FullWalletsPage extends StatelessWidget {
  final dynamic cubit;

  const FullWalletsPage({
    super.key,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final wallets = cubit.state.wallets;

    return Scaffold(
      appBar: AppBar(
        title: const Text('كل المحافظ'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: wallets.length,
        itemBuilder: (c, i) {
          final w = wallets[i];

          return Card(
            child: ListTile(
              title: Text(w.name),
              subtitle: Text(
                w.balance.toString(),
              ),
            ),
          );
        },
      ),
    );
  }
}
