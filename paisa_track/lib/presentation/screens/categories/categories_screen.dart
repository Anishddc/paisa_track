import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/utils/app_router.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/presentation/screens/categories/category_add_edit_screen.dart';
import 'package:fl_chart/fl_chart.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({Key? key}) : super(key: key);

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> with TickerProviderStateMixin {
  final CategoryRepository _categoryRepository = CategoryRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();
  late TabController _tabController;
  
  List<CategoryModel> _expenseCategories = [];
  List<CategoryModel> _incomeCategories = [];
  bool _isLoading = true;
  
  // For the pie chart
  Map<CategoryModel, double> _expenseDistribution = {};
  double _totalExpense = 0;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
    _loadCategories();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadCategories() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      final expenseCats = _categoryRepository.getCategoriesByType(TransactionType.expense);
      final incomeCats = _categoryRepository.getCategoriesByType(TransactionType.income);
      
      // Calculate spending distribution for expense categories
      final today = DateTime.now();
      final startOfMonth = DateTime(today.year, today.month, 1);
      final endOfMonth = DateTime(today.year, today.month + 1, 0);
      _totalExpense = _transactionRepository.calculateTotalExpense(startOfMonth, endOfMonth);
      
      Map<CategoryModel, double> expenseMap = {};
      for (var category in expenseCats) {
        final transactions = await _transactionRepository.getTransactionsByCategory(category.id);
        final categoryTotal = transactions
            .where((tx) => 
                tx.type == TransactionType.expense && 
                tx.date.isAfter(startOfMonth) && 
                tx.date.isBefore(endOfMonth))
            .fold(0.0, (sum, tx) => sum + tx.amount);
        
        if (categoryTotal > 0) {
          expenseMap[category] = categoryTotal;
        }
      }
      
      setState(() {
        _expenseCategories = expenseCats;
        _incomeCategories = incomeCats;
        _expenseDistribution = expenseMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading categories: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToAddEditCategory(BuildContext context, {CategoryModel? category, required bool isIncome}) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CategoryAddEditScreen(
          category: category,
          isIncome: isIncome,
        ),
      ),
    );
    
    if (result == true) {
      // Reload categories if changes were made
      _loadCategories();
    }
  }

  Future<void> _deleteCategory(CategoryModel category) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Are you sure you want to delete "${category.name}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      try {
        await _categoryRepository.deleteCategory(category.id);
        setState(() {
          if (category.isIncome) {
            _incomeCategories.removeWhere((c) => c.id == category.id);
          } else {
            _expenseCategories.removeWhere((c) => c.id == category.id);
          }
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Category deleted successfully'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting category: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if accessed from tab navigation
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final bool fromTab = args != null && 
                       args is Map<String, dynamic> && 
                       args.containsKey('fromTab') && 
                       args['fromTab'] == true;
    
    return WillPopScope(
      onWillPop: () async {
        if (fromTab) {
          Navigator.pushReplacementNamed(
            context, 
            AppRouter.dashboard,
            arguments: {'initialTab': 0}
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Categories',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          backgroundColor: ColorConstants.primaryColor,
          leading: fromTab 
              ? IconButton(
                  icon: const Icon(Icons.home, color: Colors.white),
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context, 
                      AppRouter.dashboard,
                      arguments: {'initialTab': 0}
                    );
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.settingsRoute);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: const [
              Tab(text: 'EXPENSE'),
              Tab(text: 'INCOME'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildCategoryListWithChart(_expenseCategories, false),
                  _buildCategoryListWithChart(_incomeCategories, true),
                ],
              ),
        floatingActionButton: Container(
          height: 52,
          width: 52,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorConstants.primaryColor,
                ColorConstants.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ColorConstants.primaryColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _navigateToAddEditCategory(
                context,
                isIncome: _tabController.index == 0
              ),
              customBorder: const CircleBorder(),
              child: const Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.dashboard_outlined, 'Home', () {
                    Navigator.pushNamed(context, AppRouter.dashboard);
                  }),
                  _buildNavItem(1, Icons.account_balance_wallet_outlined, 'Accounts', () {
                    Navigator.pushNamed(context, AppRouter.accounts);
                  }),
                  const SizedBox(width: 40), // Space for FAB
                  _buildNavItem(2, Icons.category_outlined, 'Categories', () {
                    // Already on categories
                  }),
                  _buildNavItem(3, Icons.bar_chart_outlined, 'Reports', () {
                    Navigator.pushNamed(context, AppRouter.reports);
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildCategoryListWithChart(List<CategoryModel> categories, bool isIncome) {
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        if (!isIncome) ...[
          SliverToBoxAdapter(
            child: _buildSpendingOverview(),
          ),
          SliverToBoxAdapter(
            child: _buildPieChartSection(),
          ),
        ],
        
        // Categories section header
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Row(
              children: [
                Text(
                  isIncome ? 'Income Categories' : 'Expense Categories',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${categories.length}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: ColorConstants.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Categories list
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) => _buildCategoryCard(categories[index]),
            childCount: categories.length,
          ),
        ),
        
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }
  
  Widget _buildSpendingOverview() {
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 20, 20, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.primaryColor,
            ColorConstants.primaryColor.withBlue(220),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This Month\'s Spending',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '\$${_totalExpense.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            '${_expenseDistribution.length} active categories',
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPieChartSection() {
    if (_expenseDistribution.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Container(
      height: 220,
      margin: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: PieChart(
              PieChartData(
                sections: _expenseDistribution.entries.map((entry) {
                  final percentage = (entry.value / _totalExpense) * 100;
                  return PieChartSectionData(
                    color: entry.key.color,
                    value: entry.value,
                    title: percentage >= 5 ? '${percentage.round()}%' : '',
                    radius: 60,
                    titleStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList(),
                centerSpaceRadius: 40,
                sectionsSpace: 2,
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            flex: 4,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Top Categories',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: _buildLegend(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLegend() {
    // Sort categories by spending amount (descending)
    final sortedEntries = _expenseDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Take top 5 categories for the legend
    final topCategories = sortedEntries.take(5).toList();
    
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: topCategories.length,
      itemBuilder: (context, index) {
        final entry = topCategories[index];
        final percentage = (entry.value / _totalExpense) * 100;
        
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: entry.key.color,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  entry.key.name,
                  style: const TextStyle(fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percentage.round()}%',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
  
  Widget _buildCategoryCard(CategoryModel category) {
    // Get category spending
    final categorySpending = _expenseDistribution[category] ?? 0.0;
    final percentage = _totalExpense > 0 ? (categorySpending / _totalExpense) * 100 : 0.0;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () {
            _navigateToAddEditCategory(context, category: category, isIncome: category.isIncome);
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Category icon
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: category.color.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    category.icon,
                    color: category.color,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                
                // Category name and details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        category.name,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (category.description != null && category.description!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          category.description!,
                          style: Theme.of(context).textTheme.bodySmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (!category.isIncome && _totalExpense > 0) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          height: 4,
                          child: LinearProgressIndicator(
                            value: categorySpending / _totalExpense,
                            backgroundColor: Theme.of(context).brightness == Brightness.dark 
                                ? Colors.grey[800] 
                                : Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation<Color>(category.color),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                
                // Amount and actions
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (categorySpending > 0)
                      Text(
                        '\$${categorySpending.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: category.isIncome ? Colors.green : Colors.red,
                        ),
                      )
                    else
                      const SizedBox(height: 16),
                    
                    if (!category.isIncome && percentage > 0)
                      Text(
                        '${percentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                  ],
                ),
                
                // Edit/Delete buttons
                Column(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () {
                        _navigateToAddEditCategory(
                          context, 
                          category: category, 
                          isIncome: category.isIncome
                        );
                      },
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                      onPressed: () => _deleteCategory(category),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(8),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: index == 2 ? ColorConstants.primaryColor : Colors.grey,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: index == 2 ? ColorConstants.primaryColor : Colors.grey,
                  fontWeight: index == 2 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 