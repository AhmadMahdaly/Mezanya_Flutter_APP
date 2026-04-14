import '../../../transactions/domain/entities/transaction_entity.dart';
import '../../../wallets/domain/entities/wallet_entity.dart';
import '../../../budget/domain/entities/budget_setup_entity.dart';
import '../../../categories/domain/entities/category_entity.dart';
import '../../../logs/domain/entities/log_entry_entity.dart';

class AppStateEntity {
  const AppStateEntity({
    required this.wallets,
    required this.transactions,
    required this.budgetSetup,
    required this.categories,
    required this.userName,
    required this.currencyCode,
    required this.notificationsEnabled,
    required this.googleEmail,
    required this.logs,
  });

  final List<WalletEntity> wallets;
  final List<TransactionEntity> transactions;
  final BudgetSetupEntity budgetSetup;
  final List<CategoryEntity> categories;
  final String userName;
  final String currencyCode;
  final bool notificationsEnabled;
  final String googleEmail;
  final List<LogEntryEntity> logs;

  factory AppStateEntity.initial() {
    return AppStateEntity(
      wallets: <WalletEntity>[
        const WalletEntity(id: 'wallet-cash-default', name: 'الكاش', balance: 0),
        const WalletEntity(id: 'wallet-bank-default', name: 'البنك', balance: 0),
      ],
      transactions: <TransactionEntity>[],
      budgetSetup: BudgetSetupEntity.initial('wallet-cash-default'),
      categories: const <CategoryEntity>[],
      userName: '',
      currencyCode: 'EGP',
      notificationsEnabled: true,
      googleEmail: '',
      logs: const <LogEntryEntity>[],
    );
  }

  AppStateEntity copyWith({
    List<WalletEntity>? wallets,
    List<TransactionEntity>? transactions,
    BudgetSetupEntity? budgetSetup,
    List<CategoryEntity>? categories,
    String? userName,
    String? currencyCode,
    bool? notificationsEnabled,
    String? googleEmail,
    List<LogEntryEntity>? logs,
  }) {
    return AppStateEntity(
      wallets: wallets ?? this.wallets,
      transactions: transactions ?? this.transactions,
      budgetSetup: budgetSetup ?? this.budgetSetup,
      categories: categories ?? this.categories,
      userName: userName ?? this.userName,
      currencyCode: currencyCode ?? this.currencyCode,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      googleEmail: googleEmail ?? this.googleEmail,
      logs: logs ?? this.logs,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'wallets': wallets.map((wallet) => wallet.toMap()).toList(),
      'transactions': transactions.map((transaction) => transaction.toMap()).toList(),
      'budgetSetup': budgetSetup.toMap(),
      'categories': categories.map((category) => category.toMap()).toList(),
      'userName': userName,
      'currencyCode': currencyCode,
      'notificationsEnabled': notificationsEnabled,
      'googleEmail': googleEmail,
      'logs': logs.map((item) => item.toMap()).toList(),
    };
  }

  factory AppStateEntity.fromMap(Map<String, dynamic> map) {
    final walletsRaw = map['wallets'] as List<dynamic>? ?? <dynamic>[];
    final transactionsRaw = map['transactions'] as List<dynamic>? ?? <dynamic>[];
    final categoriesRaw = map['categories'] as List<dynamic>? ?? <dynamic>[];
    final logsRaw = map['logs'] as List<dynamic>? ?? <dynamic>[];

    return AppStateEntity(
      wallets: walletsRaw
          .whereType<Map<String, dynamic>>()
          .map(WalletEntity.fromMap)
          .toList(),
      transactions: transactionsRaw
          .whereType<Map<String, dynamic>>()
          .map(TransactionEntity.fromMap)
          .toList(),
      budgetSetup: map['budgetSetup'] is Map<String, dynamic>
          ? BudgetSetupEntity.fromMap(map['budgetSetup'] as Map<String, dynamic>)
          : BudgetSetupEntity.initial(
              walletsRaw.isNotEmpty
                  ? ((walletsRaw.first as Map<String, dynamic>)['id'] as String? ?? 'wallet-cash-default')
                  : 'wallet-cash-default',
            ),
      categories: categoriesRaw.whereType<Map<String, dynamic>>().map(CategoryEntity.fromMap).toList(),
      userName: map['userName'] as String? ?? '',
      currencyCode: map['currencyCode'] as String? ?? 'EGP',
      notificationsEnabled: map['notificationsEnabled'] as bool? ?? true,
      googleEmail: map['googleEmail'] as String? ?? '',
      logs: logsRaw.whereType<Map<String, dynamic>>().map(LogEntryEntity.fromMap).toList(),
    );
  }
}
