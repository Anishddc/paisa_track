import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';

class CategoryService {
  final CategoryRepository _categoryRepository;

  CategoryService({
    CategoryRepository? categoryRepository,
  }) : _categoryRepository = categoryRepository ?? CategoryRepository();

  List<CategoryModel> getAllCategories() {
    try {
      return _categoryRepository.getAllCategories();
    } catch (e) {
      print('Error getting all categories: $e');
      return [];
    }
  }

  List<CategoryModel> getExpenseCategories() {
    try {
      return _categoryRepository.getExpenseCategories();
    } catch (e) {
      print('Error getting expense categories: $e');
      return [];
    }
  }

  List<CategoryModel> getIncomeCategories() {
    try {
      return _categoryRepository.getIncomeCategories();
    } catch (e) {
      print('Error getting income categories: $e');
      return [];
    }
  }

  CategoryModel? getCategoryById(String id) {
    try {
      return _categoryRepository.getCategoryById(id);
    } catch (e) {
      print('Error getting category by ID: $e');
      return null;
    }
  }

  bool addCategory(CategoryModel category) {
    try {
      return _categoryRepository.addCategory(category);
    } catch (e) {
      print('Error adding category: $e');
      return false;
    }
  }

  bool updateCategory(CategoryModel category) {
    try {
      return _categoryRepository.updateCategory(category);
    } catch (e) {
      print('Error updating category: $e');
      return false;
    }
  }

  bool deleteCategory(String id) {
    try {
      return _categoryRepository.deleteCategory(id);
    } catch (e) {
      print('Error deleting category: $e');
      return false;
    }
  }

  bool archiveCategory(String id) {
    try {
      final category = _categoryRepository.getCategoryById(id);
      if (category != null) {
        final updatedCategory = category.copyWith(isArchived: true);
        return _categoryRepository.updateCategory(updatedCategory);
      }
      return false;
    } catch (e) {
      print('Error archiving category: $e');
      return false;
    }
  }

  bool unarchiveCategory(String id) {
    try {
      final category = _categoryRepository.getCategoryById(id);
      if (category != null) {
        final updatedCategory = category.copyWith(isArchived: false);
        return _categoryRepository.updateCategory(updatedCategory);
      }
      return false;
    } catch (e) {
      print('Error unarchiving category: $e');
      return false;
    }
  }
} 