import 'package:flutter/material.dart';
import '../widgets/wallets_section_widget.dart';
import '../widgets/jars_section_widget.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';

class WalletsScreen extends StatelessWidget {
  final AppCubit cubit;

  const WalletsScreen({
    super.key,
    required this.cubit,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            16,
            16,
            16,
            120,
          ),
          children: [
            WalletsSectionWidget(
              cubit: cubit,
              previewCount: 2,
            ),
            const SizedBox(height: 24),
            JarsSectionWidget(
              cubit: cubit,
              previewCount: 2,
            ),
          ],
        ),
      ),
    );
  }
}
