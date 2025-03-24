import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/utils/app_router.dart';
import 'package:paisa_track/data/models/budget_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/repositories/budget_repository.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:provider/provider.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  late BudgetRepository _budgetRepository;
  late CategoryRepository _categoryRepository;
  bool _isLoading = true;
  List<BudgetModel> _budgets = [];
  List<CategoryModel> _categories = [];
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _budgetRepository = Provider.of<BudgetRepository>(context, listen: false);
    _categoryRepository = Provider.of<CategoryRepository>(context, listen: false);
    _loadData();
  }
  
  void _loadData() {
    setState(() {
      _isLoading = true;
    });
    
    try {
      _budgets = _budgetRepository.getActiveBudgets();
      _categories = _categoryRepository.getAllCategories();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading budgets: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading budgets: $e'))
      );
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart),
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.reports);
            },
            tooltip: 'Budget Reports',
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'filter_active':
                  setState(() {
                    _budgets = _budgetRepository.getActiveBudgets();
                  });
                  break;
                case 'filter_current':
                  setState(() {
                    _budgets = _budgetRepository.getCurrentBudgets();
                  });
                  break;
                case 'filter_all':
                  setState(() {
                    _budgets = _budgetRepository.getAllBudgets(includeArchived: true);
                  });
                  break;
                case 'filter_archived':
                  setState(() {
                    _budgets = _budgetRepository.getArchivedBudgets();
                  });
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'filter_active',
                child: Text('Show Active'),
              ),
              const PopupMenuItem(
                value: 'filter_current',
                child: Text('Show Current Month'),
              ),
              const PopupMenuItem(
                value: 'filter_all',
                child: Text('Show All'),
              ),
              const PopupMenuItem(
                value: 'filter_archived',
                child: Text('Show Archived'),
              ),
            ],
            icon: const Icon(Icons.filter_list),
            tooltip: 'Filter',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _budgets.isEmpty
              ? _buildEmptyState()
              : RefreshIndicator(
                  onRefresh: () async {
                    _loadData();
                  },
                  child: _buildBudgetList(),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showAddBudgetDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  void _showAddBudgetDialog(BuildContext context) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    List<String> selectedCategoryIds = [];
    DateTime startDate = DateTime.now();
    int selectedColor = ColorConstants.primaryColor.value;
    String currencyCode = 'USD';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create New Budget'),
        content: SingleChildScrollView(
          child: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Budget Name',
                    hintText: 'e.g., Monthly Expenses',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: amountController,
                  decoration: const InputDecoration(
                    labelText: 'Budget Amount',
                    hintText: 'e.g., 1500.00',
                    border: OutlineInputBorder(),
                    prefixText: '\$',
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    if (double.tryParse(value) == null) {
                      return 'Please enter a valid number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                ListTile(
                  title: const Text('Budget Period'),
                  subtitle: Text(
                    '${DateFormat('MMM d, yyyy').format(startDate)} - ${DateFormat('MMM d, yyyy').format(DateTime(startDate.year, startDate.month + 1, 0))}'
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: startDate,
                      firstDate: DateTime(DateTime.now().year - 1),
                      lastDate: DateTime(DateTime.now().year + 1),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        startDate = DateTime(pickedDate.year, pickedDate.month, 1);
                      });
                      Navigator.pop(context);
                      _showAddBudgetDialog(context);
                    }
                  },
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    _showCategorySelectionDialog(context, selectedCategoryIds, (selectedIds) {
                      selectedCategoryIds = selectedIds;
                      Navigator.pop(context);
                      _showAddBudgetDialog(context);
                    });
                  },
                  child: Text(selectedCategoryIds.isEmpty 
                      ? 'Select Categories' 
                      : '${selectedCategoryIds.length} Categories Selected'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    hintText: 'Add any additional details',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                if (selectedCategoryIds.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please select at least one category')),
                  );
                  return;
                }
                
                _createBudget(
                  name: nameController.text,
                  amount: double.parse(amountController.text),
                  startDate: startDate,
                  categoryIds: selectedCategoryIds,
                  colorValue: selectedColor,
                  currencyCode: currencyCode,
                  notes: notesController.text,
                );
                
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }
  
  void _showCategorySelectionDialog(
    BuildContext context, 
    List<String> initialSelection,
    Function(List<String>) onSelectionComplete
  ) {
    List<String> selectedIds = List.from(initialSelection);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Categories'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: ListView.builder(
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final category = _categories[index];
              return CheckboxListTile(
                title: Text(category.name),
                subtitle: Text(category.isIncome ? 'Income' : 'Expense'),
                secondary: Icon(
                  category.icon,
                  color: category.color,
                ),
                value: selectedIds.contains(category.id),
                onChanged: (selected) {
                  setState(() {
                    if (selected!) {
                      selectedIds.add(category.id);
                    } else {
                      selectedIds.remove(category.id);
                    }
                  });
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              onSelectionComplete(selectedIds);
            },
            child: const Text('Done'),
          ),
        ],
      ),
    );
  }
  
  void _createBudget({
    required String name,
    required double amount,
    required DateTime startDate,
    required List<String> categoryIds,
    required int colorValue,
    required String currencyCode,
    String? notes,
  }) async {
    try {
      await _budgetRepository.createMonthlyBudget(
        name: name,
        amount: amount,
        currencyCode: currencyCode,
        categoryIds: categoryIds,
        colorValue: colorValue,
        notes: notes,
        startDate: startDate,
      );
      
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget created successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating budget: $e')),
      );
    }
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.savings_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No budgets yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create a budget to track your spending',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              _showAddBudgetDialog(context);
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Budget'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBudgetList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Budget',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '\$${_calculateTotalBudget().toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${_budgets.length} ${_budgets.length == 1 ? 'Budget' : 'Budgets'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 4),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, AppRouter.reports);
                        },
                        icon: const Icon(Icons.bar_chart, size: 16),
                        label: const Text('View Reports'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primaryColor,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            itemCount: _budgets.length,
            itemBuilder: (context, index) {
              final budget = _budgets[index];
              final spent = _budgetRepository.calculateBudgetSpent(budget.id);
              final remaining = budget.amount - spent;
              final progressPercentage = _budgetRepository.calculateBudgetProgressPercentage(budget.id);
              
              return _buildBudgetCard(budget, spent, remaining, progressPercentage);
            },
          ),
        ),
      ],
    );
  }
  
  Widget _buildBudgetCard(BudgetModel budget, double spent, double remaining, double progressPercentage) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final isOverBudget = spent > budget.amount;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            title: Text(
              budget.name,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
            subtitle: Text(
              '${DateFormat('MMM d').format(budget.startDate)} - ${DateFormat('MMM d').format(budget.endDate)}',
            ),
            trailing: PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'edit':
                    // TODO: Implement edit budget
                    break;
                  case 'archive':
                    _archiveBudget(budget.id);
                    break;
                  case 'delete':
                    _showDeleteConfirmation(budget);
                    break;
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit),
                      SizedBox(width: 8),
                      Text('Edit'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'archive',
                  child: Row(
                    children: [
                      Icon(budget.isArchived ? Icons.unarchive : Icons.archive),
                      SizedBox(width: 8),
                      Text(budget.isArchived ? 'Unarchive' : 'Archive'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: Colors.red),
                      SizedBox(width: 8),
                      Text('Delete', style: TextStyle(color: Colors.red)),
                    ],
                  ),
                ),
              ],
            ),
            leading: CircleAvatar(
              backgroundColor: budget.color,
              child: Icon(
                budget.icon,
                color: Colors.white,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Budget: ${currencyFormat.format(budget.amount)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Spent: ${currencyFormat.format(spent)}',
                      style: TextStyle(
                        color: isOverBudget ? Colors.red : null,
                        fontWeight: isOverBudget ? FontWeight.bold : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progressPercentage / 100,
                  backgroundColor: Colors.grey[200],
                  color: isOverBudget 
                      ? Colors.red 
                      : progressPercentage > 90 
                          ? Colors.orange 
                          : Colors.green,
                  minHeight: 10,
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Remaining: ${currencyFormat.format(remaining)}',
                      style: TextStyle(
                        color: isOverBudget ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${progressPercentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        color: isOverBudget 
                            ? Colors.red 
                            : progressPercentage > 90 
                                ? Colors.orange 
                                : null,
                      ),
                    ),
                  ],
                ),
                if (budget.notes != null && budget.notes!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      budget.notes!,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Wrap(
                    spacing: 8,
                    children: _getCategoryChips(budget.categoryIds),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
  
  List<Widget> _getCategoryChips(List<String> categoryIds) {
    return categoryIds.map((id) {
      final category = _categories.firstWhere(
        (c) => c.id == id,
        orElse: () => CategoryModel(
          id: id,
          name: 'Unknown',
          iconName: 'category',
          colorValue: Colors.grey.value,
          isIncome: false,
          isArchived: false,
          createdAt: DateTime.now(),
        ),
      );
      
      return Chip(
        label: Text(category.name),
        avatar: Icon(
          category.icon,
          size: 16,
          color: Colors.white,
        ),
        backgroundColor: category.color.withOpacity(0.8),
        labelStyle: const TextStyle(
          color: Colors.white,
          fontSize: 12,
        ),
        padding: const EdgeInsets.all(4),
      );
    }).toList();
  }
  
  void _archiveBudget(String budgetId) async {
    try {
      final budget = _budgetRepository.getBudgetById(budgetId);
      if (budget == null) return;
      
      if (budget.isArchived) {
        await _budgetRepository.unarchiveBudget(budgetId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget unarchived')),
        );
      } else {
        await _budgetRepository.archiveBudget(budgetId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Budget archived')),
        );
      }
      
      _loadData();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }
  
  void _showDeleteConfirmation(BudgetModel budget) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Budget'),
        content: Text('Are you sure you want to delete "${budget.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              _deleteBudget(budget.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
  
  void _deleteBudget(String budgetId) async {
    try {
      await _budgetRepository.deleteBudget(budgetId);
      _loadData();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Budget deleted')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error deleting budget: $e')),
      );
    }
  }
  
  double _calculateTotalBudget() {
    return _budgets.fold(0.0, (sum, budget) => sum + budget.amount);
  }
} 