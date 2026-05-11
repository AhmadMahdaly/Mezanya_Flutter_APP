import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mezanya/features/app_state/domain/entities/app_state_entity.dart';
import 'package:mezanya/features/app_state/presentation/cubits/app_cubit.dart';
import 'package:mezanya/features/categories/presentation/screens/categories_screen.dart';
import 'package:mezanya/features/goals/presentation/screens/goals_screen.dart';
import 'package:mezanya/features/lent/presentation/screens/lent_people_screen.dart';
import 'package:mezanya/features/logs/presentation/screens/logs_screen.dart';
import 'package:mezanya/features/settings/presentation/screens/settings_screen.dart';
import 'package:mezanya/features/settings/presentation/screens/backup_screen.dart';

class MoreTabContent extends StatelessWidget {
  const MoreTabContent({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        _MenuItem(
          icon: Icons.category,
          title: 'الفئات',
          onTap: () => _navigate(context, const CategoriesScreen()),
        ),
        _MenuItem(
          icon: Icons.flag,
          title: 'الأهداف',
          onTap: () => _navigate(context, const GoalsScreen()),
        ),
        _MenuItem(
          icon: Icons.money_off,
          title: 'السلف',
          onTap: () => _navigate(context, const LentPeopleScreen()),
        ),
        _MenuItem(
          icon: Icons.history,
          title: 'السجل',
          onTap: () => _navigate(context, const LogsScreen()),
        ),
        _MenuItem(
          icon: Icons.settings,
          title: 'الإعدادات',
          onTap: () => _navigate(context, const SettingsScreen()),
        ),
        _MenuItem(
          icon: Icons.backup,
          title: 'النسخ الاحتياطي',
          onTap: () => _navigate(context, const BackupScreen()),
        ),
      ],
    );
  }

  void _navigate(BuildContext context, Widget screen) {
    Navigator.push(context, MaterialPageRoute(builder: (_) => screen));
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}