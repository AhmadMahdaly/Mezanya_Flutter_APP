import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mezanya/core/utils/money_utils.dart';
import 'package:mezanya/features/app_state/domain/entities/app_state_entity.dart';
import 'package:mezanya/features/app_state/presentation/cubits/app_cubit.dart';
import 'package:mezanya/features/lent/domain/entities/lent_person_entity.dart';

class LentPeopleScreen extends StatelessWidget {
  const LentPeopleScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AppCubit, AppStateEntity>(
      builder: (context, state) {
        final people = state.lentPeople.where((p) => !p.isArchived).toList();
        
        return Scaffold(
          appBar: AppBar(title: const Text('السلف')),
          body: people.isEmpty
            ? const Center(child: Text('لا يوجد سلف'))
            : ListView.builder(
                itemCount: people.length,
                itemBuilder: (context, index) => _LentPersonCard(person: people[index]),
              ),
          floatingActionButton: FloatingActionButton(
            onPressed: () => _showAddPersonDialog(context),
            child: const Icon(Icons.add),
          ),
        );
      },
    );
  }

  void _showAddPersonDialog(BuildContext context) {
    // Show dialog to add new person
  }
}

class _LentPersonCard extends StatelessWidget {
  final LentPersonEntity person;

  const _LentPersonCard({required this.person});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<AppCubit>();
    
    return Card(
      child: ListTile(
        title: Text(person.name),
        subtitle: Text('متبقي: ${MoneyUtils.format(person.outstandingAmount)}'),
        trailing: Text(
          MoneyUtils.format(person.totalLent),
          style: TextStyle(
            color: person.isSettled ? Colors.green : Colors.orange,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => _showPersonDetail(context, person),
      ),
    );
  }

  void _showPersonDetail(BuildContext context, LentPersonEntity person) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => LentDetailScreen(personId: person.id),
      ),
    );
  }
}