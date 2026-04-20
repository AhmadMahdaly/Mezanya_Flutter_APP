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

class MezanyaApp extends StatelessWidget {
  const MezanyaApp({
    super.key,
    required this.cubit,
  });

  final AppCubit cubit;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Mezanya',
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
  bool _isAddSheetOpen = false;
  static const double _bottomBarHeight = 98;

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

  int _pendingNotificationCount(AppStateEntity state) {
    final month = DateTime(DateTime.now().year, DateTime.now().month, 1);
    final budget = state.budgetSetup;
    final monthTx = state.transactions.where((t) {
      return t.createdAt.year == month.year && t.createdAt.month == month.month;
    }).toList();
    final incomeTx = monthTx.where((t) => t.type == 'income').toList();
    var count = 0;

    for (final income in budget.incomeSources) {
      if (income.isVariable ||
          incomeTx.any((t) => t.incomeSourceId == income.id)) {
        continue;
      }
      final linked = state.recurringTransactions.where(
        (item) =>
            item.type == 'income' &&
            item.budgetScope == 'within-budget' &&
            item.incomeSourceId == income.id,
      );
      final recurring = linked.isEmpty ? null : linked.first;
      final dueDate =
          DateTime(month.year, month.month, income.date.clamp(1, 28));
      final lead = (recurring?.reminderLeadDays ?? 0).clamp(0, 3);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final reminderDate = dueDate.subtract(Duration(days: lead));
      final canEarly =
          lead > 0 && !today.isBefore(reminderDate) && today.isBefore(dueDate);
      final isDueOrLate = !today.isBefore(dueDate);
      if (canEarly || isDueOrLate) {
        count++;
      }
    }

    for (final debt in budget.debts) {
      final recurring = state.recurringTransactions.where(
        (item) =>
            item.type == 'expense' &&
            item.budgetScope == 'within-budget' &&
            item.isDebtOrSubscription &&
            (((debt.recurringTransactionId ?? '').isNotEmpty &&
                    item.id == debt.recurringTransactionId) ||
                (item.name == debt.name && item.amount == debt.amount)),
      );
      if (recurring.isEmpty || recurring.first.executionType != 'confirm') {
        continue;
      }
      final paid = monthTx
          .where((t) => t.notes?.contains(debt.name) == true)
          .fold<double>(0, (s, t) => s + t.amount);
      if ((debt.amount - paid) > 0) {
        count++;
      }
    }

    return count;
  }

  // void _openAddTransactionSheet() {
  //   setState(() => _isAddSheetOpen = true);
  // }

  void _closeAddTransactionSheet() {
    if (!_isAddSheetOpen) {
      return;
    }
    setState(() => _isAddSheetOpen = false);
  }

  void _openAddSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // مهم عشان يأخذ full height
      useSafeArea: true, showDragHandle: true,
      backgroundColor: Color(0xffeee5d8),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: AddTransactionScreen(cubit: widget.cubit),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final pendingNotifications = _pendingNotificationCount(widget.cubit.state);
    // final bottomInset =
    //     MediaQuery.of(context).padding.bottom + _bottomBarHeight;
    final pages = <Widget>[
      MoneyScreen(cubit: widget.cubit),
      WalletsScreen(cubit: widget.cubit),
      const SizedBox.shrink(),
      _BudgetTab(cubit: widget.cubit),
      _MoreTab(
        cubit: widget.cubit,
        onOpenSection: (index) => setState(() => _currentIndex = index),
      ),
    ];

    return PopScope(
      canPop: !_isAddSheetOpen,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop || !_isAddSheetOpen) {
          return;
        }
        _closeAddTransactionSheet();
      },
      child: Scaffold(
        appBar: _hideHeader
            ? null
            : AppBar(
                titleSpacing: 12,
                title: Row(
                  children: [
                    CircleAvatar(
                      radius: 18,
                      backgroundColor:
                          Theme.of(context).colorScheme.secondaryContainer,
                      child: Icon(
                        Icons.insights_rounded,
                        size: 18,
                        color: Theme.of(context).colorScheme.primary,
                      ),
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
                    icon: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        const Icon(Icons.notifications_none_rounded),
                        if (pendingNotifications > 0)
                          PositionedDirectional(
                            top: -6,
                            end: -4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: const BoxDecoration(
                                color: Colors.red,
                                borderRadius:
                                    BorderRadius.all(Radius.circular(999)),
                              ),
                              child: Text(
                                pendingNotifications > 99
                                    ? '99+'
                                    : pendingNotifications.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
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
          child: Stack(
            children: [
              IndexedStack(
                index: _currentIndex,
                children: pages,
              ),
            ],
          ),
        ),
        bottomNavigationBar: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context)
                        .colorScheme
                        .surface
                        .withValues(alpha: 0.95),
                    Theme.of(context)
                        .colorScheme
                        .secondaryContainer
                        .withValues(alpha: 0.72),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                    color: Theme.of(context).colorScheme.outlineVariant),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 40,
                    offset: Offset(0, 12),
                    color: Color(0x1431332F),
                  ),
                ],
              ),
              child: NavigationBar(
                selectedIndex: _currentIndex,
                onDestinationSelected: (index) {
                  if (index == 2) {
                    _openAddSheet(); // مش setState
                  } else {
                    setState(() => _currentIndex = index);
                  }
                },
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
    final userName = state.userName.trim().isEmpty
        ? 'مستخدم ميزانية'
        : state.userName.trim();
    final userInitial = userName.isNotEmpty ? userName.characters.first : 'ظ…';

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
                          appBar: AppBar(title: const Text('إعداد الميزانية')),
                          body: BudgetSetupScreen(
                            cubit: cubit,
                            displayMonth: DateTime.now(),
                          ),
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
                              AppBar(title: const Text('العمليات المتكررة')),
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
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text('صفحة ${item.key}  جاهزة للربط .')));
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
              const SnackBar(content: Text('غير متصل بحساب Google')),
            );
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('طھط³ط¬ظٹظ„ ط§ظ„ط®ط±ظˆط¬'),
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
