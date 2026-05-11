import 'package:mezanya/features/app_state/domain/entities/app_state_entity.dart';
import 'package:mezanya/features/budget/domain/entities/budget_setup_entity.dart';
import 'package:mezanya/features/budget/domain/services/budget_recurring_plan_service.dart';
import 'package:mezanya/features/transactions/domain/services/recurring_schedule_engine.dart';
import 'package:mezanya/core/utils/date_utils.dart';

class NotificationUsecase {
  int calculatePendingCount(AppStateEntity state) {
    final now = DateTime.now();
    final budget = state.budgetSetup;
    final cycleStart = budget.cycleStartFor(now);
    final cycleEnd = budget.cycleEndFor(now);
    
    final cycleTransactions = state.transactions.where((t) => 
      AppDateUtils.isInRange(t.createdAt, cycleStart, cycleEnd)
    ).toList();

    var count = 0;

    // Income reminders
    count += _incomeReminders(state, budget, now, cycleTransactions);

    // Debt reminders
    count += _debtReminders(state, budget, now, cycleTransactions);

    return count;
  }

  int _incomeReminders(AppStateEntity state, BudgetSetupEntity budget, DateTime now, List transactions) {
    var count = 0;
    final monthStart = DateTime(now.year, now.month, 1);
    
    final incomeTransactions = transactions.where((t) => 
      t.type == 'income' && AppDateUtils.isInRange(t.createdAt, monthStart, now)
    ).toList();

    for (final income in budget.incomeSources) {
      if (income.isVariable) continue;
      if (incomeTransactions.any((t) => t.incomeSourceId == income.id)) continue;

      final dueDate = DateTime(now.year, now.month, income.date.clamp(1, 28));
      final today = AppDateUtils.startOfDay(now);
      
      if (!today.isBefore(dueDate)) {
        count++;
      }
    }
    return count;
  }

  int _debtReminders(AppStateEntity state, BudgetSetupEntity budget, DateTime now, List cycleTransactions) {
    var count = 0;

    for (final debt in budget.debts) {
      final recurring = BudgetRecurringPlanService.linkedRecurring(
        state.recurringTransactions,
        debt,
      );
      if (recurring == null || recurring.executionType != 'confirm') continue;

      final paidAmount = cycleTransactions
        .where((t) => t.type == 'expense' && t.notes?.contains(debt.name) == true)
        .fold(0.0, (sum, t) => sum + t.amount);

      final remaining = BudgetRecurringPlanService.pendingDecisionAmount(
        debt: debt,
        recurring: recurring,
        cyclePaid: paidAmount,
      );

      if (remaining > 0) {
        final prompt = RecurringScheduleEngine.expensePrompt(recurring, now);
        if (prompt != null) count++;
      }
    }
    return count;
  }
}