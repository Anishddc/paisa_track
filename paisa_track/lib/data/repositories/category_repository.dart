import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/services/database_service.dart';

class CategoryRepository {
  final DatabaseService _databaseService = DatabaseService();
  
  // Get all categories
  List<CategoryModel> getAllCategories({bool includeArchived = false}) {
    final categoryBox = _databaseService.categoriesBox;
    if (includeArchived) {
      return categoryBox.values.toList();
    } else {
      return categoryBox.values.where((category) => !category.isArchived).toList();
    }
  }
  
  // Get active categories
  List<CategoryModel> getActiveCategories() {
    return getAllCategories(includeArchived: false);
  }
  
  // Get archived categories
  List<CategoryModel> getArchivedCategories() {
    final categoryBox = _databaseService.categoriesBox;
    return categoryBox.values.where((category) => category.isArchived).toList();
  }
  
  // Get categories by type
  List<CategoryModel> getCategoriesByType(TransactionType type) {
    final categories = getActiveCategories();
    return categories.where((category) => category.type == type).toList();
  }
  
  // Get expense categories
  List<CategoryModel> getExpenseCategories() {
    final categories = getActiveCategories();
    return categories.where((category) => !category.isIncome && !category.isTransfer).toList();
  }
  
  // Get income categories
  List<CategoryModel> getIncomeCategories() {
    final categories = getActiveCategories();
    return categories.where((category) => category.isIncome).toList();
  }
  
  // Get transfer categories
  List<CategoryModel> getTransferCategories() {
    final categories = getActiveCategories();
    return categories.where((category) => category.isTransfer).toList();
  }
  
  // Get category by ID
  CategoryModel? getCategoryById(String id) {
    final categoryBox = _databaseService.categoriesBox;
    return categoryBox.get(id);
  }
  
  // Add new category
  Future<void> addCategory(CategoryModel category) async {
    final categoryBox = _databaseService.categoriesBox;
    await categoryBox.put(category.id, category);
  }
  
  // Update category
  Future<void> updateCategory(CategoryModel category) async {
    final categoryBox = _databaseService.categoriesBox;
    await categoryBox.put(category.id, category);
  }
  
  // Delete category
  Future<void> deleteCategory(String id) async {
    final categoryBox = _databaseService.categoriesBox;
    await categoryBox.delete(id);
  }
  
  // Archive category
  Future<void> archiveCategory(String id) async {
    final category = getCategoryById(id);
    if (category != null) {
      final updatedCategory = category.copyWith(isArchived: true);
      await updateCategory(updatedCategory);
    }
  }
  
  // Unarchive category
  Future<void> unarchiveCategory(String id) async {
    final category = getCategoryById(id);
    if (category != null) {
      final updatedCategory = category.copyWith(isArchived: false);
      await updateCategory(updatedCategory);
    }
  }
  
  // Create a new custom category
  Future<CategoryModel> createCustomCategory({
    required String name,
    required TransactionType type,
    required int colorValue,
    String? iconName,
    String? description,
  }) async {
    final isIncome = type == TransactionType.income;
    final defaultIconName = isIncome ? 'work' : 'shopping';
    
    final category = CategoryModel(
      name: name,
      iconName: iconName ?? defaultIconName,
      colorValue: colorValue,
      isIncome: isIncome,
      description: description,
    );
    
    await addCategory(category);
    return category;
  }
  
  // Initialize default categories if not already present
  Future<void> initializeDefaultCategories() async {
    final categoryBox = _databaseService.categoriesBox;
    
    if (categoryBox.isEmpty) {
      final expenseCategories = CategoryModel.defaultExpenseCategories();
      final incomeCategories = CategoryModel.defaultIncomeCategories();
      final transferCategories = CategoryModel.defaultTransferCategories();
      
      for (final category in [...expenseCategories, ...incomeCategories, ...transferCategories]) {
        await categoryBox.put(category.id, category);
      }
    }
  }

  // Get default transfer category
  CategoryModel? getTransferCategory() {
    final categories = getActiveCategories();
    try {
      return categories.firstWhere((category) => category.isTransfer);
    } catch (e) {
      return null;
    }
  }
} 