import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/enums/account_type.dart';
import 'package:paisa_track/data/models/enums/currency_type.dart';
import 'package:paisa_track/data/services/database_service.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';

class AccountRepository {
  final DatabaseService _databaseService = DatabaseService();
  final UserRepository _userRepository = UserRepository();
  
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
    final accountBox = _databaseService.accountsBox;
    if (includeArchived) {
      return accountBox.values.toList();
    } else {
      return accountBox.values.where((account) => !account.isArchived).toList();
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
    final accountBox = _databaseService.accountsBox;
    // Ensure account uses default currency
    final defaultCurrency = await _getDefaultCurrency();
    final updatedAccount = account.copyWith(currency: defaultCurrency);
    await accountBox.put(updatedAccount.id, updatedAccount);
  }
  
  // Update account
  Future<void> updateAccount(AccountModel account) async {
    final accountBox = _databaseService.accountsBox;
    // Ensure account uses default currency
    final defaultCurrency = await _getDefaultCurrency();
    final updatedAccount = account.copyWith(currency: defaultCurrency);
    await accountBox.put(updatedAccount.id, updatedAccount);
  }
  
  // Delete account
  Future<void> deleteAccount(String id) async {
    final accountBox = _databaseService.accountsBox;
    await accountBox.delete(id);
  }
  
  // Archive account
  Future<void> archiveAccount(String id) async {
    final account = getAccountById(id);
    if (account != null) {
      final updatedAccount = account.copyWith(isArchived: true);
      await updateAccount(updatedAccount);
    }
  }
  
  // Unarchive account
  Future<void> unarchiveAccount(String id) async {
    final account = getAccountById(id);
    if (account != null) {
      final updatedAccount = account.copyWith(isArchived: false);
      await updateAccount(updatedAccount);
    }
  }
  
  // Update account balance
  Future<void> updateAccountBalance(String id, double newBalance) async {
    final account = getAccountById(id);
    if (account != null) {
      final updatedAccount = account.updateBalance(newBalance);
      await _databaseService.accountsBox.put(updatedAccount.id, updatedAccount);
    }
  }
  
  // Add amount to account balance
  Future<void> addToAccountBalance(String id, double amount) async {
    final account = getAccountById(id);
    if (account != null) {
      final updatedAccount = account.addToBalance(amount);
      await _databaseService.accountsBox.put(updatedAccount.id, updatedAccount);
    }
  }
  
  // Subtract amount from account balance
  Future<void> subtractFromAccountBalance(String id, double amount) async {
    final account = getAccountById(id);
    if (account != null) {
      final updatedAccount = account.subtractFromBalance(amount);
      await _databaseService.accountsBox.put(updatedAccount.id, updatedAccount);
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
} 