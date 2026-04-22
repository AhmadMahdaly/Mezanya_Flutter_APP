import 'package:flutter/material.dart';

import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../../budget/presentation/screens/budget_setup_screen.dart';
import '../../../categories/presentation/screens/categories_screen.dart';
import '../../../goals/presentation/screens/goals_screen.dart';
import '../../../logs/presentation/screens/logs_screen.dart';
import '../../../notifications/presentation/screens/notifications_center_screen.dart';
import 'package:mezanya_app/features/settings/presentation/screens/app_settings_screen.dart';
import '../../../transactions/presentation/screens/recurring_transactions_screen.dart';
import 'section_page_scaffold.dart';

class MoreTabContent extends StatelessWidget {
  const MoreTabContent({
    super.key,
    required this.cubit,
  });

  final AppCubit cubit;

  static const List<_MoreMenuEntry> _entries = [
    _MoreMenuEntry(
      label: 'إعداد الميزانية',
      destination: 'budget-setup',
    ),
    _MoreMenuEntry(
      label: 'العمليات المتكررة',
      destination: 'recurring-transactions',
    ),
    _MoreMenuEntry(
      label: 'إعداد الفئات',
      destination: 'categories',
    ),
    _MoreMenuEntry(
      label: 'الأهداف',
      destination: 'goals',
    ),
    _MoreMenuEntry(
      label: 'السجلات',
      destination: 'logs',
    ),
    _MoreMenuEntry(
      label: 'الإشعارات',
      destination: 'notifications',
    ),
    _MoreMenuEntry(
      label: 'إعدادات التطبيق',
      destination: 'app-settings',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final state = cubit.state;
    final userName = state.userName.trim().isEmpty
        ? 'مستخدم ميزانية'
        : state.userName.trim();
    final googleAccountLabel =
        state.googleEmail.isEmpty ? 'غير متصل بحساب Google' : state.googleEmail;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'المزيد',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        _UserProfileCard(
          userName: userName,
          userInitial: userName.characters.first,
          googleAccountLabel: googleAccountLabel,
        ),
        const SizedBox(height: 10),
        ..._entries.map(
          (entry) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Card(
              child: ListTile(
                title: Text(entry.label),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _openDestination(context, entry),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await cubit.updateSettings(googleEmail: '');
            if (!context.mounted) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('غير متصل بحساب Google')),
            );
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('تسجيل الخروج'),
        ),
      ],
    );
  }

  void _openDestination(BuildContext context, _MoreMenuEntry entry) {
    final page = switch (entry.destination) {
      'budget-setup' => SectionPageScaffold(
          title: 'إعداد الميزانية',
          child: BudgetSetupScreen(
            cubit: cubit,
            displayMonth: DateTime.now(),
          ),
        ),
      'categories' => SectionPageScaffold(
          title: 'إعداد الفئات',
          child: CategoriesScreen(cubit: cubit),
        ),
      'recurring-transactions' => SectionPageScaffold(
          title: 'العمليات المتكررة',
          child: RecurringTransactionsScreen(cubit: cubit),
        ),
      'app-settings' => SectionPageScaffold(
          title: 'إعدادات التطبيق',
          child: AppSettingsScreen(cubit: cubit),
        ),
      'goals' => SectionPageScaffold(
          title: 'الأهداف',
          child: GoalsScreen(cubit: cubit),
        ),
      'logs' => LogsScreen(cubit: cubit),
      'notifications' => SectionPageScaffold(
          title: 'الإشعارات',
          child: NotificationsScreen(cubit: cubit),
        ),
      _ => null,
    };

    if (page == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('صفحة ${entry.label} جاهزة للربط.')),
      );
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }
}

class _UserProfileCard extends StatelessWidget {
  const _UserProfileCard({
    required this.userName,
    required this.userInitial,
    required this.googleAccountLabel,
  });

  final String userName;
  final String userInitial;
  final String googleAccountLabel;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              child: Text(
                userInitial,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    googleAccountLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MoreMenuEntry {
  const _MoreMenuEntry({
    required this.label,
    required this.destination,
  });

  final String label;
  final String destination;
}
