import 'package:paisa_track/core/utils/date_utils.dart' as app_date_utils;
import 'package:paisa_track/data/models/budget_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/data/services/database_service.dart';

class BudgetRepository {
  final DatabaseService _databaseService = DatabaseService();
  final TransactionRepository _transactionRepository = TransactionRepository();
  
  // Get all budgets
  List<BudgetModel> getAllBudgets({bool includeArchived = false}) {
    final budgetBox = _databaseService.budgetsBox;
    if (includeArchived) {
      return budgetBox.values.toList();
    } else {
      return budgetBox.values.where((budget) => !budget.isArchived).toList();
    }
  }
  
  // Get active budgets
  List<BudgetModel> getActiveBudgets() {
    return getAllBudgets(includeArchived: false);
  }
  
  // Get archived budgets
  List<BudgetModel> getArchivedBudgets() {
    final budgetBox = _databaseService.budgetsBox;
    return budgetBox.values.where((budget) => budget.isArchived).toList();
  }
  
  // Get current budgets (that include today's date)
  List<BudgetModel> getCurrentBudgets() {
    final today = DateTime.now();
    final budgets = getActiveBudgets();
    return budgets.where((budget) => budget.isDateInBudgetPeriod(today)).toList();
  }
  
  // Get budget by ID
  BudgetModel? getBudgetById(String id) {
    final budgetBox = _databaseService.budgetsBox;
    return budgetBox.get(id);
  }
  
  // Add new budget
  Future<void> addBudget(BudgetModel budget) async {
    final budgetBox = _databaseService.budgetsBox;
    await budgetBox.put(budget.id, budget);
  }
  
  // Update budget
  Future<void> updateBudget(BudgetModel budget) async {
    final budgetBox = _databaseService.budgetsBox;
    await budgetBox.put(budget.id, budget);
  }
  
  // Delete budget
  Future<void> deleteBudget(String id) async {
    final budgetBox = _databaseService.budgetsBox;
    await budgetBox.delete(id);
  }
  
  // Archive budget
  Future<void> archiveBudget(String id) async {
    final budget = getBudgetById(id);
    if (budget != null) {
      final updatedBudget = budget.copyWith(isArchived: true);
      await updateBudget(updatedBudget);
    }
  }
  
  // Unarchive budget
  Future<void> unarchiveBudget(String id) async {
    final budget = getBudgetById(id);
    if (budget != null) {
      final updatedBudget = budget.copyWith(isArchived: false);
      await updateBudget(updatedBudget);
    }
  }
  
  // Calculate spent amount for a budget
  double calculateBudgetSpent(String budgetId) {
    final budget = getBudgetById(budgetId);
    if (budget == null) return 0;
    
    // Get transactions in the budget period
    final transactions = _transactionRepository.getTransactionsByDateRange(
      budget.startDate, 
      budget.endDate
    ).where((tx) => 
      tx.type == TransactionType.expense && 
      budget.categoryIds.contains(tx.categoryId)
    );
    
    // Sum the transactions
    return transactions.fold(0, (sum, tx) => sum + tx.amount);
  }
  
  // Calculate remaining amount for a budget
  double calculateBudgetRemaining(String budgetId) {
    final budget = getBudgetById(budgetId);
    if (budget == null) return 0;
    
    final spent = calculateBudgetSpent(budgetId);
    return budget.amount - spent;
  }
  
  // Calculate budget progress percentage
  double calculateBudgetProgressPercentage(String budgetId) {
    final budget = getBudgetById(budgetId);
    if (budget == null) return 0;
    
    final spent = calculateBudgetSpent(budgetId);
    if (budget.amount <= 0) return 0; // Avoid division by zero
    
    return (spent / budget.amount) * 100;
  }
  
  // Create a monthly budget
  Future<BudgetModel> createMonthlyBudget({
    required String name,
    required double amount,
    required String currencyCode,
    required List<String> categoryIds,
    required int colorValue,
    String? notes,
    DateTime? startDate,
  }) async {
    final now = DateTime.now();
    final id = 'budget_${name.toLowerCase().replaceAll(' ', '_')}_${now.millisecondsSinceEpoch}';
    
    // If start date is not provided, use the start of the current month
    final start = startDate ?? app_date_utils.DateUtils.getStartOfMonth(now);
    
    // End date is the end of the month for the start date
    final end = app_date_utils.DateUtils.getEndOfMonth(start);
    
    final budget = BudgetModel(
      id: id,
      name: name,
      amount: amount,
      currencyCode: currencyCode,
      categoryIds: categoryIds,
      startDate: start,
      endDate: end,
      colorValue: colorValue,
      notes: notes,
      createdAt: now,
    );
    
    await addBudget(budget);
    return budget;
  }
} 