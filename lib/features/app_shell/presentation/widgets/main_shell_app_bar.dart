import 'package:flutter/material.dart';

class MainShellAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String todayLabel;
  final int pendingNotifications;
  final VoidCallback onOpenNotifications;

  const MainShellAppBar({
    super.key,
    required this.todayLabel,
    required this.pendingNotifications,
    required this.onOpenNotifications,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Text(todayLabel),
      actions: [
        IconButton(
          icon: Badge(
            isLabelVisible: pendingNotifications > 0,
            label: Text('$pendingNotifications'),
            child: const Icon(Icons.notifications_outlined),
          ),
          onPressed: onOpenNotifications,
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}