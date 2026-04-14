import 'dart:convert';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../budget/domain/entities/budget_setup_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../logs/domain/entities/log_entry_entity.dart';
import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../wallets/domain/entities/wallet_entity.dart';
import '../../domain/entities/app_state_entity.dart';
import '../../domain/repositories/app_repository.dart';

class AppCubit extends Cubit<AppStateEntity> {
  AppCubit(this._repository) : super(AppStateEntity.initial());

  final AppRepository _repository;

  Future<void> initialize() async {
    emit(await _repository.loadState());
  }

  String _id(String prefix) => '$prefix-${DateTime.now().microsecondsSinceEpoch}';

  Map<String, dynamic> _coreMap(AppStateEntity appState) {
    final map = appState.toMap();
    map.remove('logs');
    return map;
  }

  AppStateEntity _restoreFromCore(String coreJson, List<LogEntryEntity> logs) {
    final map = jsonDecode(coreJson) as Map<String, dynamic>;
    return AppStateEntity.fromMap(map).copyWith(logs: logs);
  }

  Future<void> _applyAndLog({
    required String action,
    required String entityType,
    required String entityId,
    required String details,
    required Future<AppStateEntity> Function() apply,
  }) async {
    final before = jsonEncode(_coreMap(state));
    final nextRaw = await apply();
    final after = jsonEncode(_coreMap(nextRaw));
    final log = LogEntryEntity(
      id: _id('log'),
      action: action,
      entityType: entityType,
      entityId: entityId,
      details: details,
      timestamp: DateTime.now(),
      beforeState: before,
      afterState: after,
      isReverted: false,
    );
    final next = nextRaw.copyWith(logs: [log, ...nextRaw.logs].take(600).toList());
    await _repository.saveState(next);
    emit(next);
  }

  Future<void> addWallet({
    required String name,
    required double openingBalance,
    String? icon,
    String? iconColor,
  }) async {
    final wallet = WalletEntity(
      id: _id('wallet'),
      name: name,
      balance: openingBalance,
      icon: icon,
      iconColor: iconColor,
    );
    await _applyAndLog(
      action: 'add',
      entityType: 'wallet',
      entityId: wallet.id,
      details: 'تمت إضافة محفظة جديدة: $name',
      apply: () => _repository.addWallet(wallet),
    );
  }

  Future<void> addTransaction({
    String? walletId,
    String? fromWalletId,
    String? toWalletId,
    required double amount,
    required String type,
    String? allocationId,
    String? budgetScope,
    String? incomeSourceId,
    String? categoryId,
    String? transferType,
    String? notes,
    DateTime? createdAt,
  }) async {
    final transaction = TransactionEntity(
      id: _id('txn'),
      walletId: walletId,
      fromWalletId: fromWalletId,
      toWalletId: toWalletId,
      allocationId: allocationId,
      budgetScope: budgetScope,
      incomeSourceId: incomeSourceId,
      categoryId: categoryId,
      transferType: transferType,
      amount: amount,
      type: type,
      notes: notes,
      createdAt: createdAt ?? DateTime.now(),
    );
    await _applyAndLog(
      action: type == 'transfer' ? 'transfer' : 'add',
      entityType: 'transaction',
      entityId: transaction.id,
      details: 'تم تسجيل ${type == 'income' ? 'دخل' : type == 'expense' ? 'مصروف' : 'تحويل'} بقيمة ${amount.toStringAsFixed(2)}',
      apply: () => _repository.addTransaction(transaction),
    );
  }

  Future<void> updateBudgetSetup(BudgetSetupEntity setup) async {
    await _applyAndLog(
      action: 'edit',
      entityType: 'budget',
      entityId: 'budget-setup',
      details: 'تم تعديل إعدادات الميزانية',
      apply: () => _repository.updateBudgetSetup(setup),
    );
  }

  Future<void> updateWallet({
    required String id,
    String? name,
    double? balance,
    String? icon,
    String? iconColor,
  }) async {
    final wallets = state.wallets
        .map((wallet) => wallet.id == id ? wallet.copyWith(name: name, balance: balance, icon: icon, iconColor: iconColor) : wallet)
        .toList();
    final next = state.copyWith(wallets: wallets);
    await _applyAndLog(
      action: 'edit',
      entityType: 'wallet',
      entityId: id,
      details: 'تم تعديل بيانات محفظة',
      apply: () async => next,
    );
  }

  Future<void> deleteWallet(String id) async {
    final next = state.copyWith(wallets: state.wallets.where((wallet) => wallet.id != id).toList());
    await _applyAndLog(
      action: 'delete',
      entityType: 'wallet',
      entityId: id,
      details: 'تم حذف محفظة',
      apply: () async => next,
    );
  }

  Future<void> addLinkedWallet(LinkedWalletEntity linkedWallet) async {
    await updateBudgetSetup(state.budgetSetup.copyWith(linkedWallets: [...state.budgetSetup.linkedWallets, linkedWallet]));
  }

  Future<void> updateLinkedWallet(LinkedWalletEntity linkedWallet) async {
    await updateBudgetSetup(
      state.budgetSetup.copyWith(
        linkedWallets: state.budgetSetup.linkedWallets.map((item) => item.id == linkedWallet.id ? linkedWallet : item).toList(),
      ),
    );
  }

  Future<void> deleteLinkedWallet(String id) async {
    await updateBudgetSetup(
      state.budgetSetup.copyWith(
        linkedWallets: state.budgetSetup.linkedWallets.where((wallet) => wallet.id != id).toList(),
      ),
    );
  }

  Future<void> setCategories(List<CategoryEntity> categories) async {
    final next = state.copyWith(categories: categories);
    await _applyAndLog(
      action: 'edit',
      entityType: 'category',
      entityId: 'categories',
      details: 'تم تحديث الفئات',
      apply: () async => next,
    );
  }

  Future<void> updateAllocationCategories({
    required String allocationId,
    required List<CategoryEntity> categories,
  }) async {
    final allocations = state.budgetSetup.allocations
        .map((item) => item.id == allocationId
            ? AllocationEntity(
                id: item.id,
                name: item.name,
                rolloverBehavior: item.rolloverBehavior,
                funding: item.funding,
                categories: categories,
              )
            : item)
        .toList();
    await updateBudgetSetup(state.budgetSetup.copyWith(allocations: allocations));
  }

  Future<void> updateLinkedWalletCategories({
    required String linkedWalletId,
    required List<CategoryEntity> categories,
  }) async {
    final linkedWallets = state.budgetSetup.linkedWallets
        .map((item) => item.id == linkedWalletId
            ? LinkedWalletEntity(
                id: item.id,
                name: item.name,
                balance: item.balance,
                monthlyAmount: item.monthlyAmount,
                executionDay: item.executionDay,
                fundingSource: item.fundingSource,
                funding: item.funding,
                icon: item.icon,
                iconColor: item.iconColor,
                automationType: item.automationType,
                categories: categories,
              )
            : item)
        .toList();
    await updateBudgetSetup(state.budgetSetup.copyWith(linkedWallets: linkedWallets));
  }

  Future<void> updateSettings({
    String? userName,
    String? currencyCode,
    bool? notificationsEnabled,
    String? googleEmail,
  }) async {
    final next = state.copyWith(
      userName: userName,
      currencyCode: currencyCode,
      notificationsEnabled: notificationsEnabled,
      googleEmail: googleEmail,
    );
    await _applyAndLog(
      action: 'edit',
      entityType: 'settings',
      entityId: 'app-settings',
      details: 'تم تعديل إعدادات التطبيق',
      apply: () async => next,
    );
  }

  String exportStateJson() => jsonEncode(state.toMap());

  Future<void> importStateJson(String jsonString) async {
    final map = jsonDecode(jsonString) as Map<String, dynamic>;
    final next = AppStateEntity.fromMap(map);
    await _applyAndLog(
      action: 'import',
      entityType: 'backup',
      entityId: 'import',
      details: 'تم استيراد نسخة احتياطية',
      apply: () async => next,
    );
  }

  Future<void> resetAllData() async {
    final next = AppStateEntity.initial();
    await _applyAndLog(
      action: 'delete',
      entityType: 'all-data',
      entityId: 'reset',
      details: 'تم حذف كل بيانات التطبيق',
      apply: () async => next,
    );
  }

  Future<void> toggleLogRevert(String logId) async {
    final target = state.logs.where((log) => log.id == logId).toList();
    if (target.isEmpty) return;
    final log = target.first;

    final updatedLogs = state.logs
        .map((item) => item.id == logId ? item.copyWith(isReverted: !item.isReverted, revertedAt: item.isReverted ? null : DateTime.now()) : item)
        .toList();

    final restored = _restoreFromCore(log.isReverted ? log.afterState : log.beforeState, updatedLogs);
    final revertLog = LogEntryEntity(
      id: _id('log'),
      action: 'revert',
      entityType: log.entityType,
      entityId: log.entityId,
      details: log.isReverted ? 'تم التراجع عن التراجع' : 'تم التراجع عن العملية الأصلية',
      timestamp: DateTime.now(),
      beforeState: jsonEncode(_coreMap(state.copyWith(logs: updatedLogs))),
      afterState: jsonEncode(_coreMap(restored)),
      isReverted: false,
    );
    final next = restored.copyWith(logs: [revertLog, ...updatedLogs].take(600).toList());
    await _repository.saveState(next);
    emit(next);
  }
}
