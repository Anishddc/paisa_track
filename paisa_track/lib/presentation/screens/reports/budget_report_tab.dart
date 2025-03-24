import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:provider/provider.dart';

class BudgetReportTab extends StatefulWidget {
  const BudgetReportTab({Key? key}) : super(key: key);

  @override
  State<BudgetReportTab> createState() => _BudgetReportTabState();
}

class _BudgetReportTabState extends State<BudgetReportTab> {
  late CategoryRepository _categoryRepository;
  late TransactionRepository _transactionRepository;
  bool _isLoading = true;
  
  // Category data
  List<CategoryModel> _categories = [];
  
  // Transaction data
  List<TransactionModel> _currentMonthTransactions = [];
  
  // Date range
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  
  @override
  void initState() {
    super.initState();
    // Initialize date range to current month
    final now = DateTime.now();
    _startDate = DateTime(now.year, now.month, 1);
    _endDate = DateTime(now.year, now.month + 1, 0);
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _categoryRepository = Provider.of<CategoryRepository>(context, listen: false);
    _transactionRepository = Provider.of<TransactionRepository>(context, listen: false);
    _loadData();
  }
  
  void _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load all expense categories
      _categories = _categoryRepository.getExpenseCategories()
          .where((c) => !c.isArchived)
          .toList();
      
      // Load transactions for selected period
      _currentMonthTransactions = _transactionRepository
          .getTransactionsInRange(_startDate, _endDate)
          .where((t) => t.isExpense)
          .toList();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading budget reports: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  double _getCategorySpending(String categoryId) {
    try {
      return _currentMonthTransactions
          .where((t) => t.categoryId == categoryId)
          .fold(0.0, (sum, t) => sum + t.amount);
    } catch (e) {
      print('Error calculating category spending: $e');
      return 0.0;
    }
  }
  
  double _getTotalBudget() {
    return _categories.fold(0.0, (sum, category) => sum + category.monthlyBudget);
  }
  
  double _getTotalSpending() {
    try {
      return _currentMonthTransactions.fold(0.0, (sum, t) => sum + t.amount);
    } catch (e) {
      print('Error calculating total spending: $e');
      return 0.0;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : RefreshIndicator(
            onRefresh: () async {
              _loadData();
            },
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDateRangePicker(),
                    const SizedBox(height: 16),
                    _buildBudgetSummary(),
                    const SizedBox(height: 16),
                    _buildBudgetPieChart(),
                    const SizedBox(height: 16),
                    _buildBudgetProgressCharts(),
                    const SizedBox(height: 16),
                    _buildMonthlyTrendChart(),
                  ],
                ),
              ),
            ),
          );
  }
  
  Widget _buildDateRangePicker() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select Time Period',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                    onPressed: () => _selectDate(true),
                  ),
                ),
                const SizedBox(width: 16),
                const Text('to'),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.calendar_today),
                    label: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                    onPressed: () => _selectDate(false),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildQuickDateButton('This Month', () => _setThisMonth()),
                _buildQuickDateButton('Last Month', () => _setLastMonth()),
                _buildQuickDateButton('Last 3 Months', () => _setLastNMonths(3)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildQuickDateButton(String label, VoidCallback onPressed) {
    return TextButton(
      onPressed: onPressed,
      child: Text(label),
      style: TextButton.styleFrom(
        backgroundColor: ColorConstants.primaryColor.withOpacity(0.1),
        foregroundColor: ColorConstants.primaryColor,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
    );
  }
  
  Future<void> _selectDate(bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: isStartDate ? _startDate : _endDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
          // Ensure end date is not before start date
          if (_endDate.isBefore(_startDate)) {
            _endDate = _startDate.add(const Duration(days: 1));
          }
        } else {
          _endDate = picked;
          // Ensure start date is not after end date
          if (_startDate.isAfter(_endDate)) {
            _startDate = _endDate.subtract(const Duration(days: 1));
          }
        }
      });
      _loadData();
    }
  }
  
  void _setThisMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    });
    _loadData();
  }
  
  void _setLastMonth() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month - 1, 1);
      _endDate = DateTime(now.year, now.month, 0);
    });
    _loadData();
  }
  
  void _setLastNMonths(int months) {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, now.month - (months - 1), 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    });
    _loadData();
  }
  
  Widget _buildBudgetSummary() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final totalBudget = _getTotalBudget();
    final totalSpending = _getTotalSpending();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Budget Summary: ${DateFormat('MMMM yyyy').format(_startDate)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildBudgetSummaryItem(
                  'Total Budget',
                  currencyFormat.format(totalBudget),
                  Icons.account_balance_wallet,
                  ColorConstants.primaryColor,
                ),
                _buildBudgetSummaryItem(
                  'Total Spent',
                  currencyFormat.format(totalSpending),
                  Icons.shopping_cart,
                  totalSpending > totalBudget && totalBudget > 0
                      ? ColorConstants.errorColor 
                      : ColorConstants.successColor,
                ),
                _buildBudgetSummaryItem(
                  'Remaining',
                  currencyFormat.format(totalBudget - totalSpending),
                  Icons.savings,
                  totalSpending > totalBudget && totalBudget > 0
                      ? ColorConstants.errorColor 
                      : ColorConstants.successColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: totalBudget > 0 ? (totalSpending / totalBudget).clamp(0.0, 1.0) : 0.0,
              backgroundColor: Colors.grey[200],
              valueColor: AlwaysStoppedAnimation<Color>(
                totalSpending > totalBudget && totalBudget > 0
                    ? ColorConstants.errorColor 
                    : ColorConstants.successColor,
              ),
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Text(
              totalBudget <= 0 
                  ? 'No budget set for this period.'
                  : totalSpending > totalBudget 
                      ? 'Over budget by ${currencyFormat.format(totalSpending - totalBudget)}' 
                      : '${((totalSpending / totalBudget) * 100).toStringAsFixed(1)}% of budget used',
              style: TextStyle(
                color: totalSpending > totalBudget && totalBudget > 0
                    ? ColorConstants.errorColor 
                    : ColorConstants.successColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBudgetSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: color.withOpacity(0.2),
          child: Icon(
            icon,
            color: color,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
  
  Widget _buildBudgetPieChart() {
    final categoriesWithBudget = _categories
        .where((c) => c.monthlyBudget > 0)
        .toList();
    
    if (categoriesWithBudget.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No budget data available for this period.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Allocation',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sections: _getBudgetPieSections(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 2,
                        pieTouchData: PieTouchData(
                          enabled: true,
                          touchCallback: (_, pieTouchResponse) {},
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: _buildPieLegend(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<PieChartSectionData> _getBudgetPieSections() {
    final categoriesWithBudget = _categories
        .where((c) => c.monthlyBudget > 0)
        .toList();
    
    final totalBudget = _getTotalBudget();
    
    return categoriesWithBudget.map((category) {
      final percentage = (category.monthlyBudget / totalBudget) * 100;
      return PieChartSectionData(
        color: category.color,
        value: category.monthlyBudget,
        title: '${percentage.toStringAsFixed(0)}%',
        radius: 50,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }
  
  Widget _buildPieLegend() {
    final categoriesWithBudget = _categories
        .where((c) => c.monthlyBudget > 0)
        .take(5)
        .toList()
      ..sort((a, b) => b.monthlyBudget.compareTo(a.monthlyBudget));
    
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: categoriesWithBudget.map((category) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                color: category.color,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  category.name,
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                currencyFormat.format(category.monthlyBudget),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildBudgetProgressCharts() {
    final categoriesWithBudget = _categories
        .where((c) => c.monthlyBudget > 0)
        .toList()
      ..sort((a, b) => b.monthlyBudget.compareTo(a.monthlyBudget));
    
    if (categoriesWithBudget.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Budget Progress by Category',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...categoriesWithBudget.map(_buildCategoryBudgetProgress).toList(),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryBudgetProgress(CategoryModel category) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final spending = _getCategorySpending(category.id);
    final percentage = (spending / category.monthlyBudget).clamp(0.0, 1.0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(category.icon, color: category.color, size: 16),
            const SizedBox(width: 8),
            Text(
              category.name,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            Text(
              '${currencyFormat.format(spending)} of ${currencyFormat.format(category.monthlyBudget)}',
              style: TextStyle(
                fontSize: 12,
                color: spending > category.monthlyBudget
                    ? ColorConstants.errorColor
                    : Colors.grey[700],
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percentage,
          backgroundColor: Colors.grey[200],
          valueColor: AlwaysStoppedAnimation<Color>(
            spending > category.monthlyBudget
                ? ColorConstants.errorColor
                : ColorConstants.successColor,
          ),
          minHeight: 8,
          borderRadius: BorderRadius.circular(4),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
  
  Widget _buildMonthlyTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Budget Trends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Historical budget vs. spending data will appear here.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/budgets');
                },
                child: const Text('Manage Budgets'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 