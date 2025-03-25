import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/enums/account_type.dart';
import 'package:paisa_track/data/models/enums/currency_type.dart';
import 'package:paisa_track/data/services/database_service.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class AccountRepository {
  final DatabaseService _databaseService = DatabaseService();
  final UserRepository _userRepository = UserRepository();
  
  // Stream controller to notify listeners when accounts change
  final StreamController<void> _accountsChangedController = StreamController<void>.broadcast();
  
  // Stream that emits an event whenever accounts change
  Stream<void> get accountsChanged => _accountsChangedController.stream;
  
  // Trigger the stream to notify listeners
  void notifyListeners() {
    if (!_accountsChangedController.isClosed) {
      // Add a event to the stream to notify listeners
      _accountsChangedController.add(null);
      print('Account stream notified! Listeners should update now.');
    }
  }
  
  // Get user's default currency
  Future<CurrencyType> _getDefaultCurrency() async {
    final userProfile = await _userRepository.getUserProfile();
    if (userProfile?.defaultCurrencyCode == null) {
      return CurrencyType.usd;
    }
    return CurrencyType.fromCode(userProfile!.defaultCurrencyCode);
  }
  
  // Get all accounts
  List<AccountModel> getAllAccounts({bool includeArchived = false}) {
    try {
      final accountBox = _databaseService.accountsBox;
      final accounts = includeArchived 
        ? accountBox.values.toList()
        : accountBox.values.where((account) => !account.isArchived).toList();
      print('Fetched ${accounts.length} accounts from Hive');
      return accounts;
    } catch (e) {
      debugPrint('Error fetching accounts: $e');
      return [];
    }
  }
  
  // Get active accounts
  List<AccountModel> getActiveAccounts() {
    return getAllAccounts(includeArchived: false);
  }
  
  // Get archived accounts
  List<AccountModel> getArchivedAccounts() {
    final accountBox = _databaseService.accountsBox;
    return accountBox.values.where((account) => account.isArchived).toList();
  }
  
  // Get accounts by type
  List<AccountModel> getAccountsByType(AccountType type) {
    final accounts = getActiveAccounts();
    return accounts.where((account) => account.type == type).toList();
  }
  
  // Get account by ID
  AccountModel? getAccountById(String id) {
    final accountBox = _databaseService.accountsBox;
    return accountBox.get(id);
  }
  
  // Add new account
  Future<void> addAccount(AccountModel account) async {
    try {
      final accountBox = _databaseService.accountsBox;
      // Ensure account uses default currency
      final defaultCurrency = await _getDefaultCurrency();
      final updatedAccount = account.copyWith(currency: defaultCurrency);
      await accountBox.put(updatedAccount.id, updatedAccount);
      
      // Notify listeners immediately
      notifyListeners();
      
      debugPrint('Account added: ${account.id}, name: ${account.name}');
    } catch (e) {
      debugPrint('Error adding account: $e');
      rethrow;
    }
  }
  
  // Update account
  Future<void> updateAccount(AccountModel account) async {
    try {
      final accountBox = _databaseService.accountsBox;
      // Ensure account uses default currency
      final defaultCurrency = await _getDefaultCurrency();
      final updatedAccount = account.copyWith(currency: defaultCurrency);
      await accountBox.put(updatedAccount.id, updatedAccount);
      
      // Notify listeners immediately
      notifyListeners();
      
      debugPrint('Account updated: ${account.id}, name: ${account.name}');
    } catch (e) {
      debugPrint('Error updating account: $e');
      rethrow;
    }
  }
  
  // Delete account
  Future<void> deleteAccount(String id) async {
    try {
      final accountBox = _databaseService.accountsBox;
      await accountBox.delete(id);
      
      // Notify listeners immediately
      notifyListeners();
      
      debugPrint('Account deleted: $id');
    } catch (e) {
      debugPrint('Error deleting account: $e');
      rethrow;
    }
  }
  
  // Archive account
  Future<void> archiveAccount(String id) async {
    final account = getAccountById(id);
    if (account != null) {
      final updatedAccount = account.copyWith(isArchived: true);
      await updateAccount(updatedAccount);
      
      // Notified through updateAccount
      debugPrint('Account archived: $id');
    }
  }
  
  // Unarchive account
  Future<void> unarchiveAccount(String id) async {
    final account = getAccountById(id);
    if (account != null) {
      final updatedAccount = account.copyWith(isArchived: false);
      await updateAccount(updatedAccount);
      
      // Notified through updateAccount
      debugPrint('Account unarchived: $id');
    }
  }
  
  // Update account balance
  Future<void> updateAccountBalance(String id, double newBalance) async {
    try {
      final account = getAccountById(id);
      if (account != null) {
        final updatedAccount = account.updateBalance(newBalance);
        await _databaseService.accountsBox.put(updatedAccount.id, updatedAccount);
        
        // Notify listeners immediately
        notifyListeners();
        
        debugPrint('Account balance updated: $id, new balance: $newBalance');
      }
    } catch (e) {
      debugPrint('Error updating account balance: $e');
      rethrow;
    }
  }
  
  // Add amount to account balance
  Future<void> addToAccountBalance(String id, double amount) async {
    try {
      final account = getAccountById(id);
      if (account != null) {
        final updatedAccount = account.addToBalance(amount);
        await _databaseService.accountsBox.put(updatedAccount.id, updatedAccount);
        
        // Notify listeners immediately
        notifyListeners();
        
        debugPrint('Added to account balance: $id, amount: $amount');
      }
    } catch (e) {
      debugPrint('Error adding to account balance: $e');
      rethrow;
    }
  }
  
  // Subtract amount from account balance
  Future<void> subtractFromAccountBalance(String id, double amount) async {
    try {
      final account = getAccountById(id);
      if (account != null) {
        final updatedAccount = account.subtractFromBalance(amount);
        await _databaseService.accountsBox.put(updatedAccount.id, updatedAccount);
        
        // Notify listeners immediately
        notifyListeners();
        
        debugPrint('Subtracted from account balance: $id, amount: $amount');
      }
    } catch (e) {
      debugPrint('Error subtracting from account balance: $e');
      rethrow;
    }
  }
  
  // Get total balance of all active accounts
  double getTotalBalance({String? currencyCode}) {
    final accounts = getActiveAccounts();
    if (currencyCode != null) {
      // Only sum accounts with the specified currency code
      return accounts
          .where((account) => account.currency.name == currencyCode)
          .fold(0, (sum, account) => sum + account.balance);
    } else {
      // Sum all accounts
      return accounts.fold(0, (sum, account) => sum + account.balance);
    }
  }
  
  // Get total balance asynchronously (for currency conversion if needed)
  Future<double> getTotalBalanceAsync({String? currencyCode}) async {
    if (currencyCode == null) {
      // Get default currency code if not provided
      final defaultCurrency = await _getDefaultCurrency();
      currencyCode = defaultCurrency.name;
    }
    
    return getTotalBalance(currencyCode: currencyCode);
  }
  
  // Create a default cash account
  Future<AccountModel> createDefaultCashAccount(String currencyCode) async {
    final currency = CurrencyType.values.firstWhere(
      (c) => c.name == currencyCode,
      orElse: () => CurrencyType.usd,
    );
    
    final account = AccountModel(
      name: 'Cash',
      type: AccountType.cash,
      balance: 0,
      currency: currency,
      colorValue: AccountType.cash.colorValue,
    );
    
    await addAccount(account);
    return account;
  }
  
  // Dispose resources
  void dispose() {
    try {
      _accountsChangedController.close();
      debugPrint('Account stream controller closed');
    } catch (e) {
      debugPrint('Error closing accounts stream controller: $e');
    }
  }
} 