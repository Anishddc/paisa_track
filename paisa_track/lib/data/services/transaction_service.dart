import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';

class TransactionService {
  final TransactionRepository _transactionRepository;
  final CategoryRepository _categoryRepository;
  final AccountRepository _accountRepository;

  TransactionService({
    TransactionRepository? transactionRepository,
    CategoryRepository? categoryRepository,
    AccountRepository? accountRepository,
  }) : _transactionRepository = transactionRepository ?? TransactionRepository(),
       _categoryRepository = categoryRepository ?? CategoryRepository(),
       _accountRepository = accountRepository ?? AccountRepository();

  Future<List<TransactionModel>> getAllTransactions() async {
    try {
      final transactions = _transactionRepository.getAllTransactions();
      return _enrichTransactions(transactions);
    } catch (e) {
      print('Error getting all transactions: $e');
      return [];
    }
  }

  Future<List<TransactionModel>> getTransactionsByDateRange(
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final transactions = _transactionRepository.getTransactionsInRange(
        startDate,
        endDate,
      );
      return _enrichTransactions(transactions);
    } catch (e) {
      print('Error getting transactions by date range: $e');
      return [];
    }
  }

  Future<TransactionModel?> getTransactionById(String id) async {
    try {
      final transaction = _transactionRepository.getTransactionById(id);
      if (transaction != null) {
        return _enrichTransaction(transaction);
      }
      return null;
    } catch (e) {
      print('Error getting transaction by ID: $e');
      return null;
    }
  }

  Future<bool> addTransaction(TransactionModel transaction) async {
    try {
      return _transactionRepository.addTransaction(transaction);
    } catch (e) {
      print('Error adding transaction: $e');
      return false;
    }
  }

  Future<bool> updateTransaction(TransactionModel transaction) async {
    try {
      return _transactionRepository.updateTransaction(transaction);
    } catch (e) {
      print('Error updating transaction: $e');
      return false;
    }
  }

  Future<bool> deleteTransaction(String id) async {
    try {
      return _transactionRepository.deleteTransaction(id);
    } catch (e) {
      print('Error deleting transaction: $e');
      return false;
    }
  }

  List<TransactionModel> _enrichTransactions(List<TransactionModel> transactions) {
    return transactions.map((transaction) => _enrichTransaction(transaction)).toList();
  }

  TransactionModel _enrichTransaction(TransactionModel transaction) {
    // Add category and account information to transaction
    final category = _categoryRepository.getCategoryById(transaction.categoryId);
    final account = _accountRepository.getAccountById(transaction.accountId);
    
    // For transfer transactions, add destination account
    AccountModel? destinationAccount;
    if (transaction.destinationAccountId != null) {
      destinationAccount = _accountRepository.getAccountById(
        transaction.destinationAccountId!
      );
    }

    // We can't directly add these properties to the TransactionModel since it's immutable,
    // but we're adding them as extension properties for the UI to use
    transaction.category = category;
    transaction.account = account;
    transaction.destinationAccount = destinationAccount;
    
    return transaction;
  }
}

// Extension to add category and account to TransactionModel
extension TransactionModelEnrichment on TransactionModel {
  // Use static variables to store the enriched data
  static final Map<String, CategoryModel?> _categories = {};
  static final Map<String, AccountModel?> _accounts = {};
  static final Map<String, AccountModel?> _destinationAccounts = {};

  CategoryModel? get category => _categories[id];
  set category(CategoryModel? value) => _categories[id] = value;

  AccountModel? get account => _accounts[id];
  set account(AccountModel? value) => _accounts[id] = value;

  AccountModel? get destinationAccount => _destinationAccounts[id];
  set destinationAccount(AccountModel? value) => _destinationAccounts[id] = value;
} 