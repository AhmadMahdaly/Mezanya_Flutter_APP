import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

import 'core/theme/app_theme.dart';
import 'features/app_state/domain/entities/app_state_entity.dart';
import 'features/app_state/presentation/cubits/app_cubit.dart';
import 'features/budget/presentation/screens/budget_setup_screen.dart';
import 'features/budget/presentation/screens/budget_tracking_screen.dart';
import 'features/categories/presentation/screens/categories_screen.dart';
import 'features/goals/presentation/screens/goals_screen.dart';
import 'features/home/presentation/screens/money_screen.dart';
import 'features/logs/presentation/screens/logs_screen.dart';
import 'features/notifications/presentation/screens/notifications_screen.dart';
import 'features/settings/presentation/screens/app_settings_screen.dart';
import 'features/transactions/presentation/screens/add_transaction_screen.dart';
import 'features/transactions/presentation/screens/recurring_transactions_screen.dart';
import 'features/wallets/presentation/screens/wallets_screen.dart';

class KorassaApp extends StatelessWidget {
  const KorassaApp({
    super.key,
    required this.cubit,
  });

  final AppCubit cubit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Korassa',
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.tactileManuscript(),
      home: StreamBuilder<AppStateEntity>(
        stream: cubit.stream,
        initialData: cubit.state,
        builder: (context, _) => MainLayout(cubit: cubit),
      ),
    );
  }
}

class MainLayout extends StatefulWidget {
  const MainLayout({super.key, required this.cubit});

  final AppCubit cubit;

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  final _tabs = const <_BottomTab>[
    _BottomTab(
      label: 'الفلوس',
      icon: Icons.bar_chart_rounded,
      activeIcon: Icons.bar_chart,
    ),
    _BottomTab(
      label: 'المحافظ',
      icon: Icons.account_balance_wallet_outlined,
      activeIcon: Icons.account_balance_wallet_rounded,
    ),
    _BottomTab(
      label: 'إضافة',
      icon: Icons.add_circle_outline_rounded,
      activeIcon: Icons.add_circle_rounded,
    ),
    _BottomTab(
      label: 'الميزانية',
      icon: Icons.pie_chart_outline_rounded,
      activeIcon: Icons.pie_chart_rounded,
    ),
    _BottomTab(
      label: 'المزيد',
      icon: Icons.more_horiz_rounded,
      activeIcon: Icons.more_horiz_rounded,
    ),
  ];

  Future<String> _todayLabel() async {
    await initializeDateFormatting('ar');
    return DateFormat('EEEE d MMMM yyyy', 'ar').format(DateTime.now());
  }

  bool get _hideHeader => _currentIndex == 2;

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      MoneyScreen(cubit: widget.cubit),
      WalletsScreen(cubit: widget.cubit),
      AddTransactionScreen(cubit: widget.cubit),
      _BudgetTab(cubit: widget.cubit),
      _MoreTab(
        cubit: widget.cubit,
        onOpenSection: (index) => setState(() => _currentIndex = index),
      ),
    ];

    return Scaffold(
      appBar: _hideHeader
          ? null
          : AppBar(
              titleSpacing: 12,
              title: Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    child: Icon(Icons.insights_rounded, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('الميزانية'),
                  const Spacer(),
                  FutureBuilder<String>(
                    future: _todayLabel(),
                    builder: (context, snapshot) {
                      return Text(
                        snapshot.data ?? '',
                        style: Theme.of(context).textTheme.bodySmall,
                      );
                    },
                  ),
                ],
              ),
              actions: [
                IconButton(
                  tooltip: 'الإشعارات',
                  icon: const Icon(Icons.notifications_none_rounded),
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('الإشعارات')),
                          body: NotificationsScreen(cubit: widget.cubit),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: pages,
        ),
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F4EF), // surface-container-low
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                  color: Theme.of(context).colorScheme.outlineVariant),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 40,
                  offset: Offset(0, 12),
                  color: Color(0x0F31332F), // Ambient shadow
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) =>
                  setState(() => _currentIndex = index),
              destinations: _tabs
                  .map(
                    (tab) => NavigationDestination(
                      icon: Icon(tab.icon),
                      selectedIcon: Icon(tab.activeIcon),
                      label: tab.label,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }
}

class _BudgetTab extends StatelessWidget {
  const _BudgetTab({required this.cubit});

  final AppCubit cubit;

  @override
  Widget build(BuildContext context) {
    return BudgetTrackingScreen(cubit: cubit);
  }
}

class _MoreTab extends StatelessWidget {
  const _MoreTab({
    required this.cubit,
    required this.onOpenSection,
  });

  final AppCubit cubit;
  final ValueChanged<int> onOpenSection;

  @override
  Widget build(BuildContext context) {
    final state = cubit.state;
    final userName =
        state.userName.trim().isEmpty ? 'مستخدم كراسة' : state.userName.trim();
    final userInitial = userName.isNotEmpty ? userName.characters.first : 'ك';

    const items = <MapEntry<String, String>>[
      MapEntry('إعداد الميزانية', 'budget-setup'),
      MapEntry('العمليات المتكررة', 'recurring-transactions'),
      MapEntry('إعداد الفئات', 'categories'),
      MapEntry('الأهداف', 'goals'),
      MapEntry('السجلات', 'logs'),
      MapEntry('الإشعارات', 'notifications'),
      MapEntry('إعدادات التطبيق', 'app-settings'),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'المزيد',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        const SizedBox(height: 12),
        Card(
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
                        color: Colors.white),
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
                        state.googleEmail.isEmpty
                            ? 'غير متصل بحساب Google'
                            : state.googleEmail,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // IconButton(
                //   tooltip: 'تعديل بيانات الحساب',
                //   icon: const Icon(Icons.edit_outlined),
                //   onPressed: () {
                //     Navigator.of(context).push(
                //       MaterialPageRoute(
                //         builder: (_) => Scaffold(
                //           appBar: AppBar(title: const Text('إعدادات التطبيق')),
                //           body: AppSettingsScreen(cubit: cubit),
                //         ),
                //       ),
                //     );
                //   },
                // ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Card(
              child: ListTile(
                title: Text(item.key),
                subtitle: Text(item.value),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  if (item.value == 'budget-setup') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(
                              title: const Text('إعداد الميزانية الشهرية')),
                          body: BudgetSetupScreen(cubit: cubit),
                        ),
                      ),
                    );
                    return;
                  }
                  if (item.value == 'categories') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('إعداد الفئات')),
                          body: CategoriesScreen(cubit: cubit),
                        ),
                      ),
                    );
                    return;
                  }
                  if (item.value == 'recurring-transactions') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar:
                              AppBar(title: const Text('المعاملات المتكررة')),
                          body: RecurringTransactionsScreen(cubit: cubit),
                        ),
                      ),
                    );
                    return;
                  }
                  if (item.value == 'app-settings') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('إعدادات التطبيق')),
                          body: AppSettingsScreen(cubit: cubit),
                        ),
                      ),
                    );
                    return;
                  }
                  if (item.value == 'goals') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('الأهداف')),
                          body: GoalsScreen(cubit: cubit),
                        ),
                      ),
                    );
                    return;
                  }
                  if (item.value == 'logs') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LogsScreen(cubit: cubit),
                      ),
                    );
                    return;
                  }
                  if (item.value == 'notifications') {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => Scaffold(
                          appBar: AppBar(title: const Text('الإشعارات')),
                          body: NotificationsScreen(cubit: cubit),
                        ),
                      ),
                    );
                    return;
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('صفحة ${item.key} جاهزة للربط.')));
                },
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () async {
            await cubit.updateSettings(googleEmail: '');
            if (!context.mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('تم تسجيل الخروج من الحساب.')),
            );
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('تسجيل الخروج'),
        ),
      ],
    );
  }
}

class _BottomTab {
  const _BottomTab({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}
