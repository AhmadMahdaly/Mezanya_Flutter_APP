import 'package:flutter/material.dart';

class NotificationsTabSelector extends StatelessWidget {
  const NotificationsTabSelector({
    super.key,
    required this.selectedTab,
    required this.pendingCount,
    required this.historyCount,
    required this.onTabChanged,
  });

  final String selectedTab;
  final int pendingCount;
  final int historyCount;
  final ValueChanged<String> onTabChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Expanded(
            child: ChoiceChip(
              selected: selectedTab == 'new',
              label: Text('التنبيهات ($pendingCount)'),
              onSelected: (_) => onTabChanged('new'),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ChoiceChip(
              selected: selectedTab == 'history',
              label: Text('السجل ($historyCount)'),
              onSelected: (_) => onTabChanged('history'),
            ),
          ),
        ],
      ),
    );
  }
}

class PendingNotificationAction {
  const PendingNotificationAction({
    required this.label,
    required this.onPressed,
    this.filled = true,
  });

  final String label;
  final VoidCallback onPressed;
  final bool filled;
}

class PendingNotificationCard extends StatelessWidget {
  const PendingNotificationCard({
    super.key,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.actions,
  });

  final Color accent;
  final String title;
  final String subtitle;
  final double amount;
  final List<PendingNotificationAction> actions;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: accent.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                amount.toStringAsFixed(2),
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle),
          const SizedBox(height: 10),
          Row(
            children: [
              for (var i = 0; i < actions.length; i++) ...[
                Expanded(child: _NotificationActionButton(action: actions[i])),
                if (i != actions.length - 1) const SizedBox(width: 8),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NotificationActionButton extends StatelessWidget {
  const _NotificationActionButton({
    required this.action,
  });

  final PendingNotificationAction action;

  @override
  Widget build(BuildContext context) {
    if (action.filled) {
      return FilledButton(
        onPressed: action.onPressed,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(38),
          textStyle: const TextStyle(fontWeight: FontWeight.w800),
        ),
        child: Text(action.label),
      );
    }

    return OutlinedButton(
      onPressed: action.onPressed,
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(38),
        textStyle: const TextStyle(fontWeight: FontWeight.w800),
      ),
      child: Text(action.label),
    );
  }
}

class NotificationHistoryTile extends StatelessWidget {
  const NotificationHistoryTile({
    super.key,
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: Text(trailing),
        onTap: onTap,
      ),
    );
  }
}
