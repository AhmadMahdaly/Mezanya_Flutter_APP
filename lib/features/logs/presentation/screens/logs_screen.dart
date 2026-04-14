import 'package:flutter/material.dart';

import '../../../app_state/presentation/cubits/app_cubit.dart';
import '../../domain/entities/log_entry_entity.dart';

class LogsScreen extends StatefulWidget {
  const LogsScreen({super.key, required this.cubit});
  final AppCubit cubit;

  @override
  State<LogsScreen> createState() => _LogsScreenState();
}

class _LogsScreenState extends State<LogsScreen> {
  String _range = 'all';
  final Set<String> _actions = <String>{};

  @override
  Widget build(BuildContext context) {
    final logs = _filtered(widget.cubit.state.logs);
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
      body: logs.isEmpty
          ? const Center(child: Text('لا توجد سجلات مطابقة للفلاتر الحالية.'))
          : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                log.details,
                                style: const TextStyle(fontWeight: FontWeight.w700),
                              ),
                            ),
                            Text(log.action, style: const TextStyle(fontSize: 12)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'الكيان: ${log.entityType} • ${_fmt(log.timestamp)}',
                          style: const TextStyle(fontSize: 12, color: Colors.black54),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            OutlinedButton.icon(
                              onPressed: () async {
                                await widget.cubit.toggleLogRevert(log.id);
                                if (!mounted) return;
                                setState(() {});
                              },
                              icon: Icon(log.isReverted ? Icons.redo : Icons.undo),
                              label: Text(log.isReverted ? 'إلغاء التراجع' : 'تراجع'),
                            ),
                            const SizedBox(width: 8),
                            if (log.revertedAt != null)
                              Text('تم التراجع ${_fmt(log.revertedAt!)}',
                                  style: const TextStyle(fontSize: 12, color: Colors.black54)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }

  List<LogEntryEntity> _filtered(List<LogEntryEntity> logs) {
    final now = DateTime.now();
    final filteredRange = logs.where((log) {
      if (_range == 'day') return now.difference(log.timestamp).inHours <= 24;
      if (_range == 'week') return now.difference(log.timestamp).inDays <= 7;
      if (_range == 'month') return now.difference(log.timestamp).inDays <= 30;
      return true;
    });
    final filteredAction =
        _actions.isEmpty ? filteredRange : filteredRange.where((log) => _actions.contains(log.action));
    final result = filteredAction.toList()..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    return result;
  }

  void _openFilters() {
    final selected = Set<String>.from(_actions);
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
                children: ['add', 'edit', 'delete', 'transfer', 'revert', 'import']
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
                    _actions
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

  String _fmt(DateTime date) =>
      '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
}
