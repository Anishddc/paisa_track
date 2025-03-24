import 'package:paisa_track/core/utils/date_utils.dart' as app_date_utils;
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:paisa_track/data/services/database_service.dart';
import 'package:hive/hive.dart';

class TransactionRepository {
  final DatabaseService _databaseService = DatabaseService();
  final AccountRepository _accountRepository = AccountRepository();
  static const String _boxName = 'transactions';
  
  // Get all transactions
  List<TransactionModel> getAllTransactions() {
    final transactionBox = _databaseService.transactionsBox;
    return transactionBox.values.toList();
  }
  
  // Get all transactions sorted by date (newest first)
  List<TransactionModel> getAllTransactionsSorted() {
    final transactions = getAllTransactions();
    transactions.sort((a, b) => b.date.compareTo(a.date));
    return transactions;
  }
  
  // Get transactions by type
  List<TransactionModel> getTransactionsByType(TransactionType type) {
    final transactions = getAllTransactions();
    return transactions.where((tx) => tx.type == type).toList();
  }
  
  // Get transactions by account
  List<TransactionModel> getTransactionsByAccount(String accountId) {
    final transactions = getAllTransactions();
    return transactions.where((tx) => 
      tx.accountId == accountId || 
      (tx.type == TransactionType.transfer && tx.toAccountId == accountId)
    ).toList();
  }
  
  // Get transactions by category
  Future<List<TransactionModel>> getTransactionsByCategory(String categoryId) async {
    final box = await Hive.openBox<TransactionModel>(_boxName);
    return box.values.where((transaction) => transaction.categoryId == categoryId).toList();
  }
  
  // Get transactions by date range
  List<TransactionModel> getTransactionsByDateRange(DateTime start, DateTime end) {
    final transactions = getAllTransactions();
    return transactions.where((tx) => 
      (tx.date.isAfter(start) || tx.date.isAtSameMomentAs(start)) &&
      (tx.date.isBefore(end) || tx.date.isAtSameMomentAs(end))
    ).toList();
  }
  
  // Get transactions for today
  List<TransactionModel> getTransactionsForToday() {
    final today = DateTime.now();
    final start = app_date_utils.DateUtils.getStartOfDay(today);
    final end = app_date_utils.DateUtils.getEndOfDay(today);
    return getTransactionsByDateRange(start, end);
  }
  
  // Get transactions for this week
  List<TransactionModel> getTransactionsForThisWeek() {
    final today = DateTime.now();
    final start = app_date_utils.DateUtils.getStartOfWeek(today);
    final end = app_date_utils.DateUtils.getEndOfWeek(today);
    return getTransactionsByDateRange(start, end);
  }
  
  // Get transactions for this month
  List<TransactionModel> getTransactionsForThisMonth() {
    final today = DateTime.now();
    final start = app_date_utils.DateUtils.getStartOfMonth(today);
    final end = app_date_utils.DateUtils.getEndOfMonth(today);
    return getTransactionsByDateRange(start, end);
  }
  
  // Get recent transactions (limited by count)
  List<TransactionModel> getRecentTransactions({int count = 10}) {
    final transactions = getAllTransactionsSorted();
    return transactions.take(count).toList();
  }
  
  // Get recent transactions for a specific account (limited by count)
  List<TransactionModel> getRecentTransactionsByAccount({
    required String accountId,
    int count = 10
  }) {
    final accountTransactions = getTransactionsByAccount(accountId);
    // Sort by date (newest first)
    accountTransactions.sort((a, b) => b.date.compareTo(a.date));
    return accountTransactions.take(count).toList();
  }
  
  // Get transaction by ID
  TransactionModel? getTransactionById(String id) {
    final transactionBox = _databaseService.transactionsBox;
    return transactionBox.get(id);
  }
  
  // Add new transaction
  Future<void> addTransaction(TransactionModel transaction) async {
    final transactionBox = _databaseService.transactionsBox;
    
    // Update account balances
    await _updateAccountBalances(transaction);
    
    // Save the transaction
    await transactionBox.put(transaction.id, transaction);
  }
  
  // Update transaction
  Future<void> updateTransaction(TransactionModel oldTransaction, TransactionModel newTransaction) async {
    final transactionBox = _databaseService.transactionsBox;
    
    // First revert the old transaction's effect on account balances
    await _revertAccountBalances(oldTransaction);
    
    // Then apply the new transaction's effect
    await _updateAccountBalances(newTransaction);
    
    // Save the updated transaction
    await transactionBox.put(newTransaction.id, newTransaction);
  }
  
  // Delete transaction
  Future<void> deleteTransaction(String id) async {
    final transaction = getTransactionById(id);
    if (transaction != null) {
      // Revert the transaction's effect on account balances
      await _revertAccountBalances(transaction);
      
      // Delete the transaction
      final transactionBox = _databaseService.transactionsBox;
      await transactionBox.delete(id);
    }
  }
  
  // Calculate total income for a date range
  double calculateTotalIncome(DateTime start, DateTime end, {String? currencyCode}) {
    final transactions = getTransactionsByDateRange(start, end)
        .where((tx) => tx.type == TransactionType.income);
    
    if (currencyCode != null) {
      // Get the accounts with the specified currency
      final accounts = _accountRepository.getAllAccounts()
          .where((account) => account.currencyCode == currencyCode)
          .map((account) => account.id)
          .toList();
      
      // Filter transactions by those accounts
      final filteredTransactions = transactions
          .where((tx) => accounts.contains(tx.accountId));
      
      return filteredTransactions.fold(0, (sum, tx) => sum + tx.amount);
    } else {
      return transactions.fold(0, (sum, tx) => sum + tx.amount);
    }
  }
  
  // Calculate total expense for a date range
  double calculateTotalExpense(DateTime start, DateTime end, {String? currencyCode}) {
    final transactions = getTransactionsByDateRange(start, end)
        .where((tx) => tx.type == TransactionType.expense);
    
    if (currencyCode != null) {
      // Get the accounts with the specified currency
      final accounts = _accountRepository.getAllAccounts()
          .where((account) => account.currencyCode == currencyCode)
          .map((account) => account.id)
          .toList();
      
      // Filter transactions by those accounts
      final filteredTransactions = transactions
          .where((tx) => accounts.contains(tx.accountId));
      
      return filteredTransactions.fold(0, (sum, tx) => sum + tx.amount);
    } else {
      return transactions.fold(0, (sum, tx) => sum + tx.amount);
    }
  }
  
  // Calculate total income for an account within date range
  double calculateTotalIncomeForAccount(String accountId, DateTime startDate, DateTime endDate) {
    final transactions = getTransactionsByAccount(accountId)
        .where((tx) => 
            tx.type == TransactionType.income &&
            tx.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
            tx.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
    
    return transactions.fold(0, (sum, tx) => sum + tx.amount);
  }
  
  // Calculate total expense for an account within date range
  double calculateTotalExpenseForAccount(String accountId, DateTime startDate, DateTime endDate) {
    final transactions = getTransactionsByAccount(accountId)
        .where((tx) => 
            tx.type == TransactionType.expense &&
            tx.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
            tx.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
    
    return transactions.fold(0, (sum, tx) => sum + tx.amount);
  }
  
  // Helper method to update account balances when adding a transaction
  Future<void> _updateAccountBalances(TransactionModel transaction) async {
    switch (transaction.type) {
      case TransactionType.income:
        await _accountRepository.addToAccountBalance(transaction.accountId, transaction.amount);
        break;
        
      case TransactionType.expense:
        await _accountRepository.subtractFromAccountBalance(transaction.accountId, transaction.amount);
        break;
        
      case TransactionType.transfer:
        if (transaction.toAccountId != null) {
          // Subtract from source account
          await _accountRepository.subtractFromAccountBalance(transaction.accountId, transaction.amount);
          
          // Add to destination account
          await _accountRepository.addToAccountBalance(transaction.toAccountId!, transaction.amount);
        }
        break;
    }
  }
  
  // Helper method to revert account balances when updating or deleting a transaction
  Future<void> _revertAccountBalances(TransactionModel transaction) async {
    switch (transaction.type) {
      case TransactionType.income:
        await _accountRepository.subtractFromAccountBalance(transaction.accountId, transaction.amount);
        break;
        
      case TransactionType.expense:
        await _accountRepository.addToAccountBalance(transaction.accountId, transaction.amount);
        break;
        
      case TransactionType.transfer:
        if (transaction.toAccountId != null) {
          // Add back to source account
          await _accountRepository.addToAccountBalance(transaction.accountId, transaction.amount);
          
          // Subtract from destination account
          await _accountRepository.subtractFromAccountBalance(transaction.toAccountId!, transaction.amount);
        }
        break;
    }
  }
  
  // Get transactions within a date range
  List<TransactionModel> getTransactionsInRange(DateTime startDate, DateTime endDate) {
    final transactionBox = _databaseService.transactionsBox;
    return transactionBox.values
        .where((transaction) => 
            transaction.date.isAfter(startDate.subtract(const Duration(days: 1))) && 
            transaction.date.isBefore(endDate.add(const Duration(days: 1))))
        .toList();
  }
  
  // Check for unprocessed transactions in the last 24 hours
  Future<bool> hasUnprocessedTransactions() async {
    final box = await Hive.openBox<TransactionModel>(_boxName);
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    
    return box.values.any((transaction) => 
      transaction.date.isAfter(yesterday) && 
      !transaction.isProcessed
    );
  }
  
  // Mark transactions as processed
  Future<void> markTransactionsAsProcessed() async {
    final box = await Hive.openBox<TransactionModel>(_boxName);
    final yesterday = DateTime.now().subtract(Duration(days: 1));
    
    final unprocessedTransactions = box.values.where((transaction) => 
      transaction.date.isAfter(yesterday) && 
      !transaction.isProcessed
    ).toList();
    
    for (var transaction in unprocessedTransactions) {
      transaction.isProcessed = true;
      await transaction.save();
    }
  }
} 