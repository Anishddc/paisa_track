import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:provider/provider.dart';
import 'package:paisa_track/core/utils/date_utils.dart' as date_utils;
import 'package:paisa_track/presentation/widgets/loader.dart';

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
  DateTime _startDate = DateTime.now().copyWith(day: 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _netIncome = 0;
  
  Map<String, double> _spendingByCategory = {};
  List<Color> _categoryColors = [];
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get repository instances
    _categoryRepository = Provider.of<CategoryRepository>(context, listen: false);
    _transactionRepository = Provider.of<TransactionRepository>(context, listen: false);
    
    // Initial data load
    _loadData();
  }
  
  Future<void> _loadData() async {
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
          .getTransactionsInRange(_startDate, _endDate);
      
      _calculateSummary();
      _calculateSpendingByCategory();
      
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
  
  void _calculateSummary() {
    _totalIncome = 0;
    _totalExpense = 0;

    for (final transaction in _currentMonthTransactions) {
      if (transaction.isIncome) {
        _totalIncome += transaction.amount;
      } else if (transaction.isExpense) {
        _totalExpense += transaction.amount;
      }
    }

    _netIncome = _totalIncome - _totalExpense;
  }
  
  void _calculateSpendingByCategory() {
    _spendingByCategory = {};
    _categoryColors = [];

    for (final transaction in _currentMonthTransactions) {
      if (transaction.isExpense) {
        final category = _categoryRepository.getCategoryById(transaction.categoryId);
        if (category != null) {
          final String categoryName = category.name;
          
          if (_spendingByCategory.containsKey(categoryName)) {
            _spendingByCategory[categoryName] = 
                _spendingByCategory[categoryName]! + transaction.amount;
          } else {
            _spendingByCategory[categoryName] = transaction.amount;
            _categoryColors.add(category.color);
          }
        }
      }
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
    return StreamBuilder<void>(
      stream: _transactionRepository.transactionsChanged,
      builder: (context, snapshot) {
        // Reload data when stream emits an event
        if (snapshot.connectionState == ConnectionState.active) {
          // Load data on a slight delay to ensure Hive has completed its operation
          Future.microtask(() => _loadData());
        }
        
        return _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadData,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateSelector(),
                      _buildSummaryCards(),
                      _buildBudgetChart(),
                      _buildCategoryBreakdown(),
                    ],
                  ),
                ),
              );
      },
    );
  }
  
  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: _selectDateRange,
        child: Row(
          children: [
            Icon(
              Icons.calendar_today,
              color: ColorConstants.primaryColor,
              size: 18,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Date Range',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${DateFormat('MMM d, y').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.grey,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
  
  Future<void> _selectDateRange() async {
    final DateTimeRange? pickedRange = await showDateRangePicker(
      context: context,
      initialDateRange: DateTimeRange(
        start: _startDate,
        end: _endDate,
      ),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: ColorConstants.primaryColor,
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedRange != null) {
      setState(() {
        _startDate = pickedRange.start;
        _endDate = pickedRange.end;
      });
      _loadData();
    }
  }
  
  Widget _buildSummaryCards() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Income',
                  amount: _totalIncome,
                  currencyFormat: currencyFormat,
                  color: Colors.green.shade600,
                  icon: Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Expenses',
                  amount: _totalExpense,
                  currencyFormat: currencyFormat,
                  color: Colors.red.shade600,
                  icon: Icons.arrow_downward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildNetIncomeCard(currencyFormat),
        ],
      ),
    );
  }
  
  Widget _buildSummaryCard({
    required String title,
    required double amount,
    required NumberFormat currencyFormat,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNetIncomeCard(NumberFormat currencyFormat) {
    final Color textColor = _netIncome >= 0 ? Colors.green.shade600 : Colors.red.shade600;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            ColorConstants.primaryColor.withOpacity(0.8),
            ColorConstants.primaryColor,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primaryColor.withOpacity(0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Net Income',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currencyFormat.format(_netIncome.abs()),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _netIncome >= 0 ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      _netIncome >= 0 ? Icons.trending_up : Icons.trending_down,
                      color: Colors.white,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _netIncome >= 0 ? 'Savings' : 'Deficit',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBudgetChart() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Income vs Expenses',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _totalIncome == 0 && _totalExpense == 0
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Text(
                      'No data available for the selected period',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                )
              : SizedBox(
                  height: 200,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: _totalIncome > _totalExpense 
                          ? _totalIncome * 1.2 
                          : _totalExpense * 1.2,
                      titlesData: FlTitlesData(
                        show: true,
                        topTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final titles = ['Income', 'Expense'];
                              return Padding(
                                padding: const EdgeInsets.only(top: 8.0),
                                child: Text(
                                  titles[value.toInt()],
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 60,
                            getTitlesWidget: (double value, TitleMeta meta) {
                              final currencyFormat = NumberFormat.compactCurrency(
                                symbol: '\$',
                                decimalDigits: 0,
                              );
                              
                              if (value == 0) {
                                return const SizedBox.shrink();
                              }
                              
                              return Padding(
                                padding: const EdgeInsets.only(right: 4.0),
                                child: Text(
                                  currencyFormat.format(value),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: _totalIncome > _totalExpense 
                            ? _totalIncome / 5 
                            : _totalExpense / 5,
                        getDrawingHorizontalLine: (value) {
                          return FlLine(
                            color: Colors.grey.withOpacity(0.2),
                            strokeWidth: 1,
                          );
                        },
                      ),
                      borderData: FlBorderData(
                        show: false,
                      ),
                      barGroups: [
                        BarChartGroupData(
                          x: 0,
                          barRods: [
                            BarChartRodData(
                              toY: _totalIncome,
                              color: Colors.green.shade600,
                              width: 40,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                          ],
                        ),
                        BarChartGroupData(
                          x: 1,
                          barRods: [
                            BarChartRodData(
                              toY: _totalExpense,
                              color: Colors.red.shade600,
                              width: 40,
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(8),
                                topRight: Radius.circular(8),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
        ],
      ),
    );
  }
  
  Widget _buildCategoryBreakdown() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    if (_spendingByCategory.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Center(
          child: Text(
            'No expense categories for the selected period',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }
    
    // Sort by highest spending
    final List<MapEntry<String, double>> sortedEntries = 
        _spendingByCategory.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value));
          
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Spending by Category',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          Column(
            children: List.generate(
              sortedEntries.length,
              (index) {
                final entry = sortedEntries[index];
                final percent = (entry.value / _totalExpense) * 100;
                final color = _categoryColors.length > index 
                    ? _categoryColors[index] 
                    : Colors.grey;
                    
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 12,
                                height: 12,
                                decoration: BoxDecoration(
                                  color: color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                entry.key,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${percent.toStringAsFixed(1)}%',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).brightness == Brightness.dark 
                                  ? Colors.grey[400] 
                                  : Colors.grey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: entry.value / _totalExpense,
                                minHeight: 6,
                                backgroundColor: Colors.grey.shade100,
                                valueColor: AlwaysStoppedAnimation<Color>(color),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            currencyFormat.format(entry.value),
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: color,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
} 