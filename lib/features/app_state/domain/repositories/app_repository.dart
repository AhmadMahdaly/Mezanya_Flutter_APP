import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../wallets/domain/entities/wallet_entity.dart';
import '../../../budget/domain/entities/budget_setup_entity.dart';
import '../entities/app_state_entity.dart';

abstract class AppRepository {
  Future<AppStateEntity> loadState();
  Future<void> saveState(AppStateEntity state);

  Future<AppStateEntity> addWallet(WalletEntity wallet);
  Future<AppStateEntity> addTransaction(TransactionEntity transaction);
  Future<AppStateEntity> updateBudgetSetup(BudgetSetupEntity budgetSetup);
}
