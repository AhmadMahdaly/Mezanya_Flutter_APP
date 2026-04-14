import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/storage/shared_prefs_keys.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../wallets/domain/entities/wallet_entity.dart';
import '../../../budget/domain/entities/budget_setup_entity.dart';
import '../../domain/entities/app_state_entity.dart';
import '../../domain/repositories/app_repository.dart';

class SharedPrefsAppRepository implements AppRepository {
  SharedPrefsAppRepository(this._prefs);

  final SharedPreferences _prefs;

  @override
  Future<AppStateEntity> loadState() async {
    final payload = _prefs.getString(SharedPrefsKeys.appState);
    if (payload == null || payload.isEmpty) {
      final initial = AppStateEntity.initial();
      await saveState(initial);
      return initial;
    }

    try {
      final decoded = jsonDecode(payload) as Map<String, dynamic>;
      return AppStateEntity.fromMap(decoded);
    } catch (_) {
      final fallback = AppStateEntity.initial();
      await saveState(fallback);
      return fallback;
    }
  }

  @override
  Future<void> saveState(AppStateEntity state) async {
    await _prefs.setString(SharedPrefsKeys.appState, jsonEncode(state.toMap()));
  }

  @override
  Future<AppStateEntity> addWallet(WalletEntity wallet) async {
    final current = await loadState();
    final next = current.copyWith(wallets: <WalletEntity>[...current.wallets, wallet]);
    await saveState(next);
    return next;
  }

  @override
  Future<AppStateEntity> addTransaction(TransactionEntity transaction) async {
    final current = await loadState();
    var wallets = List<WalletEntity>.from(current.wallets);
    var linkedWallets = List<LinkedWalletEntity>.from(current.budgetSetup.linkedWallets);

    if (transaction.type == 'transfer' &&
        transaction.fromWalletId != null &&
        transaction.toWalletId != null) {
      wallets = wallets.map((wallet) {
        if (wallet.id == transaction.fromWalletId) {
          return wallet.copyWith(balance: wallet.balance - transaction.amount);
        }
        if (wallet.id == transaction.toWalletId) {
          return wallet.copyWith(balance: wallet.balance + transaction.amount);
        }
        return wallet;
      }).toList();

      linkedWallets = linkedWallets.map((wallet) {
        if (wallet.id == transaction.toWalletId) {
          return LinkedWalletEntity(
            id: wallet.id,
            name: wallet.name,
            balance: wallet.balance + transaction.amount,
            monthlyAmount: wallet.monthlyAmount,
            executionDay: wallet.executionDay,
            fundingSource: wallet.fundingSource,
            funding: wallet.funding,
            icon: wallet.icon,
            iconColor: wallet.iconColor,
            automationType: wallet.automationType,
            categories: wallet.categories,
          );
        }
        return wallet;
      }).toList();
    } else {
      wallets = wallets.map((wallet) {
        if (wallet.id != transaction.walletId) return wallet;
        final nextBalance =
            transaction.type == 'income' ? wallet.balance + transaction.amount : wallet.balance - transaction.amount;
        return wallet.copyWith(balance: nextBalance);
      }).toList();
    }

    final next = current.copyWith(
      wallets: wallets,
      budgetSetup: current.budgetSetup.copyWith(linkedWallets: linkedWallets),
      transactions: <TransactionEntity>[...current.transactions, transaction],
    );
    await saveState(next);
    return next;
  }

  @override
  Future<AppStateEntity> updateBudgetSetup(BudgetSetupEntity budgetSetup) async {
    final current = await loadState();
    final next = current.copyWith(budgetSetup: budgetSetup);
    await saveState(next);
    return next;
  }
}
