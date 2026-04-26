import 'package:flutter/material.dart';

class MainShellDestination {
  const MainShellDestination({
    required this.label,
    required this.icon,
    required this.activeIcon,
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
}

class MainShellBottomNavigation extends StatelessWidget {
  const MainShellBottomNavigation({
    super.key,
    required this.selectedIndex,
    required this.destinations,
    required this.onSelected,
  });

  final int selectedIndex;
  final List<MainShellDestination> destinations;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.surface.withValues(alpha: 0.96),
                Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withValues(alpha: 0.54),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            boxShadow: const [
              BoxShadow(
                blurRadius: 40,
                offset: Offset(0, 12),
                color: Color(0x1F5D4B32),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: selectedIndex,
            onDestinationSelected: onSelected,
            destinations: destinations
                .map(
                  (destination) => NavigationDestination(
                    icon: Icon(destination.icon),
                    selectedIcon: Icon(destination.activeIcon),
                    label: destination.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
