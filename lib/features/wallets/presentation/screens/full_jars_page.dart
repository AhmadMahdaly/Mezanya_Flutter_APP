import 'package:flutter/material.dart';

class FullJarsPage extends StatelessWidget {
  final dynamic cubit;

  const FullJarsPage({
    super.key,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    final jars = cubit.state.budgetSetup.linkedWallets;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'كل الحصالات',
        ),
      ),
      body: ListView.builder(
        itemCount: jars.length,
        itemBuilder: (c, i) {
          final jar = jars[i];

          return ListTile(
            title: Text(jar.name),
            subtitle: Text(
              jar.balance.toString(),
            ),
          );
        },
      ),
    );
  }
}
