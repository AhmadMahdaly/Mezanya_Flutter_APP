import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/theme/app_theme.dart';
import 'features/app_state/presentation/cubits/app_cubit.dart';
import 'features/app_state/domain/entities/app_state_entity.dart';
import 'features/budget/presentation/screens/budget_setup_screen.dart';
import 'features/budget/presentation/screens/budget_tracking_screen.dart';
import 'features/home/presentation/screens/money_screen.dart';
import 'features/wallets/presentation/screens/wallets_screen.dart';
import 'features/transactions/presentation/screens/add_transaction_screen.dart';
import 'features/categories/presentation/screens/categories_screen.dart';
import 'features/settings/presentation/screens/app_settings_screen.dart';
import 'features/logs/presentation/screens/logs_screen.dart';

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
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: AppTheme.light(),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('صفحة الإشعارات جاهزة للربط.')),
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
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: const [
                BoxShadow(
                  blurRadius: 20,
                  offset: Offset(0, 8),
                  color: Color(0x1F000000),
                ),
              ],
            ),
            child: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: (index) => setState(() => _currentIndex = index),
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
        ...items.map(
          (item) => Card(
            child: ListTile(
              title: Text(item.key),
              subtitle: Text(item.value),
              trailing: const Icon(Icons.chevron_left_rounded),
              onTap: () {
                if (item.value == 'budget-setup') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('إعداد الميزانية الشهرية')),
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
                if (item.value == 'logs') {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => LogsScreen(cubit: cubit),
                    ),
                  );
                  return;
                }
                ScaffoldMessenger.of(context)
                    .showSnackBar(SnackBar(content: Text('صفحة ${item.key} جاهزة للربط.')));
              },
            ),
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => onOpenSection(2),
          icon: const Icon(Icons.add),
          label: const Text('إضافة عملية بسرعة'),
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
