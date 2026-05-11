import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mezanya/core/utils/date_utils.dart';
import 'package:mezanya/features/app_state/domain/entities/app_state_entity.dart';
import 'package:mezanya/features/app_state/presentation/cubits/app_cubit.dart';
import 'package:mezanya/features/app_state/domain/usecases/notification_usecase.dart';
import 'package:mezanya/features/budget/presentation/screens/budget_tracking_screen.dart';
import 'package:mezanya/features/home/presentation/screens/money_screen.dart';
import 'package:mezanya/features/notifications/presentation/screens/notifications_center_screen.dart';
import 'package:mezanya/features/transactions/presentation/screens/add_transaction_screen.dart';
import 'package:mezanya/features/wallets/presentation/screens/wallets_screen.dart';
import '../widgets/main_shell_app_bar.dart';
import '../widgets/main_shell_bottom_navigation.dart';
import '../widgets/more_tab_content.dart';
import '../widgets/section_page_scaffold.dart';

class MainShellScreen extends StatelessWidget {
  const MainShellScreen({super.key});

  static const int _addTabIndex = 2;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppStateEntity>(
      builder: (context, state) {
        final cubit = context.read<AppCubit>();
        final notificationUsecase = NotificationUsecase();
        final pendingCount = notificationUsecase.calculatePendingCount(state);

        return _MainShellView(
          state: state,
          cubit: cubit,
          pendingNotifications: pendingCount,
        );
      },
    );
  }
}

class _MainShellView extends StatefulWidget {
  final AppStateEntity state;
  final AppCubit cubit;
  final int pendingNotifications;

  const _MainShellView({
    required this.state,
    required this.cubit,
    required this.pendingNotifications,
  });

  @override
  State<_MainShellView> createState() => _MainShellViewState();
}

class _MainShellViewState extends State<_MainShellView> {
  int _currentIndex = 0;
  bool _isAddSheetOpen = false;

  final List<MainShellDestination> _destinations = const [
    MainShellDestination(label: 'الفلوس', icon: Icons.bar_chart_rounded, activeIcon: Icons.bar_chart),
    MainShellDestination(label: 'المحافظ', icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet_rounded),
    MainShellDestination(label: 'إضافة', icon: Icons.add_circle_outline_rounded, activeIcon: Icons.add_circle_rounded),
    MainShellDestination(label: 'الميزانية', icon: Icons.pie_chart_outline_rounded, activeIcon: Icons.pie_chart_rounded),
    MainShellDestination(label: 'المزيد', icon: Icons.more_horiz_rounded, activeIcon: Icons.more_horiz_rounded),
  ];

  bool get _showsAppBar => _currentIndex != MainShellScreen._addTabIndex;

  List<Widget> get _pages => [
    MoneyScreen(),
    WalletsScreen(),
    const SizedBox.shrink(),
    BudgetTrackingScreen(),
    MoreTabContent(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: _showsAppBar
        ? MainShellAppBar(
            todayLabel: AppDateUtils.formatDate(DateTime.now()),
            pendingNotifications: widget.pendingNotifications,
            onOpenNotifications: _openNotifications,
          )
        : null,
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
      ),
      bottomNavigationBar: MainShellBottomNavigation(
        selectedIndex: _currentIndex,
        destinations: _destinations,
        onSelected: _handleDestinationSelected,
      ),
    );
  }

  void _handleDestinationSelected(int index) {
    if (index == MainShellScreen._addTabIndex) {
      _openAddSheet();
      return;
    }
    setState(() => _currentIndex = index);
  }

  Future<void> _openAddSheet() async {
    if (_isAddSheetOpen) return;
    setState(() => _isAddSheetOpen = true);

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      barrierColor: const Color(0xFF2D2A22).withValues(alpha: 0.28),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: const AddTransactionScreen(),
      ),
    );

    if (mounted) setState(() => _isAddSheetOpen = false);
  }

  void _openNotifications() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const SectionPageScaffold(
          title: 'الإشعارات',
          child: NotificationsCenterScreen(),
        ),
      ),
    );
  }
}