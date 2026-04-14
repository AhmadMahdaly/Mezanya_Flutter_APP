import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../app_state/domain/entities/app_state_entity.dart';
import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../domain/entities/log_entry_entity.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key, required this.cubit});
  final AppCubit cubit;

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _tab = 'all';
  String _range = 'all';
  final Set<String> _entityTypes = <String>{};

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<AppStateEntity>(
      stream: widget.cubit.stream,
      initialData: widget.cubit.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? widget.cubit.state;
        final logs = _filtered(state.logs);
        return Scaffold(
          appBar: AppBar(
            title: const Text('السجلات'),
            actions: [
              IconButton(
                icon: const Icon(Icons.filter_alt_outlined),
                onPressed: _openFilters,
              ),
            ],
          ),
          body: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _tabChip('all', 'عام'),
                      _tabChip('transaction', 'معاملات'),
                      _tabChip('edit', 'تعديلات'),
                      _tabChip('delete', 'حذف'),
                      _tabChip('transfer', 'تحويل'),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: logs.isEmpty
                    ? const Center(child: Text('لا توجد سجلات مطابقة للفلاتر الحالية.'))
                    : ListView.builder(
                        padding: const EdgeInsets.all(12),
                        itemCount: logs.length,
                        itemBuilder: (context, index) {
                          final log = logs[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            child: ListTile(
                              title: Text(
                                _pretty(log),
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                              subtitle: Text('النوع: ${_actionName(log.action)} • ${_fmt(log.timestamp)}'),
                              trailing: Icon(log.isReverted ? Icons.redo : Icons.chevron_left_rounded),
                              onTap: () => _openDetails(state, log),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _tabChip(String id, String label) {
    final selected = _tab == id;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => setState(() => _tab = id),
      ),
    );
  }

  List<LogEntryEntity> _filtered(List<LogEntryEntity> logs) {
    final now = DateTime.now();
    var filtered = logs.where((log) {
      if (_range == 'day') return now.difference(log.timestamp).inHours <= 24;
      if (_range == 'week') return now.difference(log.timestamp).inDays <= 7;
      if (_range == 'month') return now.difference(log.timestamp).inDays <= 30;
      return true;
    });
    if (_tab == 'transaction') {
      filtered = filtered.where((log) => log.entityType == 'transaction');
    } else if (_tab == 'edit') {
      filtered = filtered.where((log) => log.action == 'edit');
    } else if (_tab == 'delete') {
      filtered = filtered.where((log) => log.action == 'delete');
    } else if (_tab == 'transfer') {
      filtered = filtered.where((log) => log.action == 'transfer');
    }
    if (_entityTypes.isNotEmpty) {
      filtered = filtered.where((log) => _entityTypes.contains(log.entityType));
    }
    final result = filtered.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  void _openFilters() {
    final selected = Set<String>.from(_entityTypes);
    String range = _range;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheet) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('فلترة السجلات', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: range,
                decoration: const InputDecoration(labelText: 'المدى الزمني'),
                items: const [
                  DropdownMenuItem(value: 'all', child: Text('الكل')),
                  DropdownMenuItem(value: 'day', child: Text('آخر يوم')),
                  DropdownMenuItem(value: 'week', child: Text('آخر أسبوع')),
                  DropdownMenuItem(value: 'month', child: Text('آخر شهر')),
                ],
                onChanged: (v) {
                  if (v != null) setSheet(() => range = v);
                },
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: ['transaction', 'wallet', 'budget', 'settings', 'goal', 'revert']
                    .map(
                      (a) => FilterChip(
                        label: Text(a),
                        selected: selected.contains(a),
                        onSelected: (on) {
                          setSheet(() {
                            if (on) {
                              selected.add(a);
                            } else {
                              selected.remove(a);
                            }
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () {
                  setState(() {
                    _range = range;
                    _entityTypes
                      ..clear()
                      ..addAll(selected);
                  });
                  Navigator.pop(context);
                },
                child: const Text('تطبيق الفلتر'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _openDetails(AppStateEntity state, LogEntryEntity log) async {
    final canDeleteTransaction = log.entityType == 'transaction' && log.action == 'add';
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.72,
        child: ListView(
          padding: const EdgeInsets.all(14),
          children: [
            Text(_pretty(log), style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text('العملية: ${_actionName(log.action)}'),
            Text('الكيان: ${log.entityType}'),
            Text('الوقت: ${_fmt(log.timestamp)}'),
            if (log.revertedAt != null) Text('تم التراجع في: ${_fmt(log.revertedAt!)}'),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () async {
                await widget.cubit.toggleLogRevert(log.id);
                if (context.mounted) Navigator.pop(context);
              },
              icon: Icon(log.isReverted ? Icons.redo : Icons.undo),
              label: Text(log.isReverted ? 'إلغاء التراجع' : 'تراجع عن الإجراء'),
            ),
            if (canDeleteTransaction) ...[
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () async {
                  await widget.cubit.deleteTransaction(log.entityId);
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline),
                label: const Text('حذف المعاملة'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _pretty(LogEntryEntity log) {
    if (log.details.trim().isNotEmpty) return log.details.trim();
    return '${_actionName(log.action)} على ${log.entityType}';
  }

  String _actionName(String action) {
    switch (action) {
      case 'add':
        return 'إضافة';
      case 'edit':
        return 'تعديل';
      case 'delete':
        return 'حذف';
      case 'transfer':
        return 'تحويل';
      case 'revert':
        return 'تراجع';
      case 'import':
        return 'استيراد';
      default:
        return action;
    }
  }

  String _fmt(DateTime date) => DateFormat('yyyy/MM/dd HH:mm').format(date);
}
