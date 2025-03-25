import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:paisa_track/core/constants/app_constants.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/budget_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/enums/account_type.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/models/user_profile_model.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  
  factory DatabaseService() => _instance;
  
  DatabaseService._internal();
  
  bool _isInitialized = false;
  
  // Hive boxes
  late Box<UserProfileModel> _userProfileBox;
  late Box<AccountModel> _accountsBox;
  late Box<CategoryModel> _categoriesBox;
  late Box<TransactionModel> _transactionsBox;
  late Box<BudgetModel> _budgetsBox;
  
  // Getters for boxes
  Box<UserProfileModel> get userProfileBox => _userProfileBox;
  Box<AccountModel> get accountsBox => _accountsBox;
  Box<CategoryModel> get categoriesBox => _categoriesBox;
  Box<TransactionModel> get transactionsBox => _transactionsBox;
  Box<BudgetModel> get budgetsBox => _budgetsBox;
  
  // Initialize database
  Future<void> init() async {
    if (_isInitialized) return;
    
    try {
      // Open boxes - no need to init Hive or register adapters again, it's done in main.dart
      await _openBoxes();
      
      // Fix any AccountType conversion issues
      await _fixAccountTypeIssues();
      
      // Initialize default data if needed
      await _initializeDefaultData();
      
      _isInitialized = true;
    } catch (e) {
      print('Error initializing database: $e');
      rethrow;
    }
  }
  
  // Open all required boxes
  Future<void> _openBoxes() async {
    try {
      // Make sure all boxes are properly opened
      _userProfileBox = await Hive.openBox<UserProfileModel>(AppConstants.userProfileBox);
      
      // Safely open or get reference to other boxes
      try {
        // Try to get boxes that might already be open
        _accountsBox = Hive.box<AccountModel>(AppConstants.accountsBox);
        _categoriesBox = Hive.box<CategoryModel>(AppConstants.categoriesBox);
        _transactionsBox = Hive.box<TransactionModel>(AppConstants.transactionsBox);
      } catch (e) {
        // If boxes aren't open yet, open them
        print('Some boxes not open yet, opening them now: $e');
        _accountsBox = await Hive.openBox<AccountModel>(AppConstants.accountsBox);
        _categoriesBox = await Hive.openBox<CategoryModel>(AppConstants.categoriesBox);
        _transactionsBox = await Hive.openBox<TransactionModel>(AppConstants.transactionsBox);
      }
      
      // Always open budgets box
      _budgetsBox = await Hive.openBox<BudgetModel>(AppConstants.budgetsBox);
      
      print('All boxes opened successfully in DatabaseService');
    } catch (e) {
      print('Error opening boxes in DatabaseService: $e');
      // For unrecoverable errors, rethrow
      rethrow;
    }
  }
  
  // Initialize default data if boxes are empty
  Future<void> _initializeDefaultData() async {
    // We don't want to create a default user profile automatically
    // because the user needs to go through the setup process
    
    // Add default categories if none exist
    if (_categoriesBox.isEmpty) {
      final expenseCategories = CategoryModel.defaultExpenseCategories();
      final incomeCategories = CategoryModel.defaultIncomeCategories();
      final transferCategories = CategoryModel.defaultTransferCategories();
      
      for (final category in [...expenseCategories, ...incomeCategories, ...transferCategories]) {
        await _categoriesBox.put(category.id, category);
      }
    }
  }
  
  // Fix any AccountType conversion issues
  Future<void> _fixAccountTypeIssues() async {
    try {
      print('Fixing any AccountType conversion issues in accounts...');
      
      // Get all accounts
      final accounts = _accountsBox.values.toList();
      int fixedCount = 0;
      
      // Process and fix all accounts regardless of current state
      for (final account in accounts) {
        try {
          // Extract the AccountType from the current account
          final currentType = account.type;
          
          // Create a new account with the type explicitly converted to a string
          final fixedAccount = AccountModel(
            id: account.id,
            name: account.name,
            balance: account.balance,
            type: currentType.toString(), // Store as string representation
            currency: account.currency,
            description: account.description,
            createdAt: account.createdAt,
            updatedAt: DateTime.now(),
            isArchived: account.isArchived,
            bankName: account.bankName,
            accountNumber: account.accountNumber,
            colorValue: account.colorValue,
            accountHolderName: account.accountHolderName,
            iconData: account.iconData,
            bankLogoPath: account.bankLogoPath,
            initialBalance: account.initialBalance,
            userName: account.userName,
          );
          
          // Save the fixed account
          await _accountsBox.put(account.id, fixedAccount);
          fixedCount++;
          
        } catch (e) {
          print('Error handling account type for ${account.name}: $e');
          
          // If there's an issue, recreate the account with a safe default
          try {
            final fixedAccount = AccountModel(
              id: account.id,
              name: account.name,
              balance: account.balance,
              type: 'AccountType.cash', // Use a safe default
              currency: account.currency,
              description: account.description,
              createdAt: account.createdAt,
              updatedAt: DateTime.now(),
              isArchived: account.isArchived,
              bankName: account.bankName,
              accountNumber: account.accountNumber,
              colorValue: account.colorValue,
              accountHolderName: account.accountHolderName,
              iconData: account.iconData,
              bankLogoPath: account.bankLogoPath,
              initialBalance: account.initialBalance,
              userName: account.userName,
            );
            
            // Save the fixed account
            await _accountsBox.put(account.id, fixedAccount);
            fixedCount++;
            print('Fixed account with fallback type for ${account.name}');
          } catch (fixError) {
            print('Failed to fix account ${account.name}: $fixError');
          }
        }
      }
      
      print('Account type conversion completed: fixed $fixedCount accounts');
    } catch (e) {
      print('Error fixing AccountType conversion issues: $e');
      // Don't throw as this is a recovery routine
    }
  }
  
  // Close all boxes
  Future<void> closeBoxes() async {
    await _userProfileBox.close();
    await _accountsBox.close();
    await _categoriesBox.close();
    await _transactionsBox.close();
    await _budgetsBox.close();
    _isInitialized = false;
  }
  
  // Clear all data (for testing or reset functionality)
  Future<void> clearAllData() async {
    await _userProfileBox.clear();
    await _accountsBox.clear();
    await _categoriesBox.clear();
    await _transactionsBox.clear();
    await _budgetsBox.clear();
    
    // Re-initialize default data
    await _initializeDefaultData();
  }
} 