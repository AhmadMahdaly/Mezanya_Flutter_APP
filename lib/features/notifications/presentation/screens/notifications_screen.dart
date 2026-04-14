import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_state/domain/entities/app_state_entity.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../domain/entities/notification_entity.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key, required this.cubit});

  final AppCubit cubit;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  String _tab = 'new';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStateEntity>(
      stream: widget.cubit.stream,
      initialData: widget.cubit.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? widget.cubit.state;
        final newItems = state.notifications.where((n) => !n.isRead).toList();
        final historyItems = state.notifications.where((n) => n.isRead).toList();
        final visible = _tab == 'new' ? newItems : historyItems;

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      selected: _tab == 'new',
                      label: Text('جديد (${newItems.length})'),
                      onSelected: (_) => setState(() => _tab = 'new'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      selected: _tab == 'history',
                      label: Text('السجل (${historyItems.length})'),
                      onSelected: (_) => setState(() => _tab = 'history'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              Card(
                child: ListTile(
                  title: Text(_tab == 'new' ? 'لا توجد إشعارات جديدة.' : 'سجل الإشعارات فارغ.'),
                ),
              )
            else
              ...visible.map((item) => _notificationCard(state, item)),
          ],
        );
      },
    );
  }

  Widget _notificationCard(AppStateEntity state, NotificationEntity item) {
    final relatedLog = item.relatedLogId == null
        ? null
        : state.logs.where((log) => log.id == item.relatedLogId).toList();
    final log = relatedLog != null && relatedLog.isNotEmpty ? relatedLog.first : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(item.title),
        subtitle: Text(item.message),
        trailing: Text(DateFormat('d/M HH:mm').format(item.createdAt)),
        onTap: () async {
          if (!item.isRead) {
            await widget.cubit.markNotificationRead(item.id);
          }
          if (!mounted) return;
          await showModalBottomSheet<void>(
            context: context,
            isScrollControlled: true,
            builder: (context) => SizedBox(
              height: MediaQuery.of(context).size.height * 0.65,
              child: ListView(
                padding: const EdgeInsets.all(14),
                children: [
                  Text(item.title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 8),
                  Text(item.message),
                  const SizedBox(height: 8),
                  Text('الوقت: ${DateFormat('d/M/yyyy - HH:mm').format(item.createdAt)}'),
                  const SizedBox(height: 16),
                  if (log != null)
                    OutlinedButton.icon(
                      onPressed: () async {
                        await widget.cubit.toggleLogRevert(log.id);
                        if (context.mounted) Navigator.pop(context);
                      },
                      icon: const Icon(Icons.undo_rounded),
                      label: Text(log.isReverted ? 'التراجع عن التراجع' : 'تراجع عن الإجراء'),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
