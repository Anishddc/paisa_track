import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:provider/provider.dart';

class CategoryReportTab extends StatefulWidget {
  const CategoryReportTab({Key? key}) : super(key: key);

  @override
  State<CategoryReportTab> createState() => _CategoryReportTabState();
}

class _CategoryReportTabState extends State<CategoryReportTab> {
  late CategoryRepository _categoryRepository;
  late TransactionRepository _transactionRepository;
  bool _isLoading = true;
  String _selectedTab = 'Expense';
  
  // Data
  List<CategoryModel> _categories = [];
  List<TransactionModel> _transactions = [];
  Map<String, double> _categorySpending = {};
  
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
      // Load categories based on selected tab
      if (_selectedTab == 'Expense') {
        _categories = _categoryRepository.getExpenseCategories()
            .where((c) => !c.isArchived)
            .toList();
      } else {
        _categories = _categoryRepository.getIncomeCategories()
            .where((c) => !c.isArchived)
            .toList();
      }
      
      // Load transactions for selected period
      _transactions = _transactionRepository.getTransactionsInRange(_startDate, _endDate);
      
      // Filter transactions based on selected tab
      if (_selectedTab == 'Expense') {
        _transactions = _transactions.where((t) => t.isExpense).toList();
      } else {
        _transactions = _transactions.where((t) => !t.isExpense).toList();
      }
      
      // Calculate spending by category
      _categorySpending = {};
      for (var transaction in _transactions) {
        if (_categorySpending.containsKey(transaction.categoryId)) {
          _categorySpending[transaction.categoryId] = 
              _categorySpending[transaction.categoryId]! + transaction.amount;
        } else {
          _categorySpending[transaction.categoryId] = transaction.amount;
        }
      }
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading category reports: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  double _getTotalAmount() {
    return _transactions.fold(0.0, (sum, transaction) => sum + transaction.amount);
  }
  
  String _getCategoryName(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId).name;
    } catch (e) {
      return 'Unknown';
    }
  }
  
  Color _getCategoryColor(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId).color;
    } catch (e) {
      return Colors.grey;
    }
  }
  
  IconData _getCategoryIcon(String categoryId) {
    try {
      return _categories.firstWhere((c) => c.id == categoryId).icon;
    } catch (e) {
      return Icons.help_outline;
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
                    _buildTabSelector(),
                    const SizedBox(height: 16),
                    _buildCategorySummary(),
                    const SizedBox(height: 16),
                    _buildCategoryPieChart(),
                    const SizedBox(height: 16),
                    _buildCategoryBreakdown(),
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
                _buildQuickDateButton('Year to Date', () => _setYearToDate()),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTabSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Category Type',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(
                  value: 'Expense', 
                  label: Text('Expense'),
                  icon: Icon(Icons.arrow_downward),
                ),
                ButtonSegment<String>(
                  value: 'Income', 
                  label: Text('Income'),
                  icon: Icon(Icons.arrow_upward),
                ),
              ],
              selected: {_selectedTab},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedTab = selection.first;
                  _loadData(); // Reload data for the selected tab
                });
              },
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
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        textStyle: const TextStyle(fontSize: 12),
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
  
  void _setYearToDate() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, 1, 1);
      _endDate = DateTime(now.year, now.month + 1, 0);
    });
    _loadData();
  }
  
  Widget _buildCategorySummary() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final totalAmount = _getTotalAmount();
    final categoryCount = _categorySpending.length;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedTab} Summary',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSummaryItem(
                  'Total ${_selectedTab}',
                  currencyFormat.format(totalAmount),
                  _selectedTab == 'Expense' ? Icons.shopping_cart : Icons.account_balance_wallet,
                  _selectedTab == 'Expense' ? ColorConstants.errorColor : ColorConstants.successColor,
                ),
                _buildSummaryItem(
                  'Categories Used',
                  categoryCount.toString(),
                  Icons.category,
                  ColorConstants.primaryColor,
                ),
                _buildSummaryItem(
                  'Transactions',
                  _transactions.length.toString(),
                  Icons.receipt_long,
                  Colors.purple,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
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
  
  Widget _buildCategoryPieChart() {
    if (_categorySpending.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text(
              'No data available for this period.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ),
      );
    }
    
    final totalAmount = _getTotalAmount();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedTab} by Category',
              style: const TextStyle(
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
                        sections: _getPieSections(totalAmount),
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
                    child: _buildPieLegend(totalAmount),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  List<PieChartSectionData> _getPieSections(double totalAmount) {
    // Sort categories by amount
    final sortedCategories = _categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Limit to top 5, with "Others" for the rest
    final topCategories = sortedCategories.take(5).toList();
    
    return topCategories.map((entry) {
      final percentage = (entry.value / totalAmount) * 100;
      return PieChartSectionData(
        color: _getCategoryColor(entry.key),
        value: entry.value,
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
  
  Widget _buildPieLegend(double totalAmount) {
    // Sort categories by amount
    final sortedCategories = _categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    // Limit to top 5, with "Others" for the rest
    final topCategories = sortedCategories.take(5).toList();
    
    final currencyFormat = NumberFormat.currency(symbol: '\$', decimalDigits: 0);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: topCategories.map((entry) {
        final percentage = (entry.value / totalAmount) * 100;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                color: _getCategoryColor(entry.key),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getCategoryName(entry.key),
                  style: const TextStyle(fontSize: 12),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                '${percentage.toStringAsFixed(1)}%',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
  
  Widget _buildCategoryBreakdown() {
    if (_categorySpending.isEmpty) {
      return const SizedBox.shrink();
    }
    
    // Sort categories by amount
    final sortedCategories = _categorySpending.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    
    final totalAmount = _getTotalAmount();
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${_selectedTab} Categories Breakdown',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ...sortedCategories.map((entry) {
              final percentage = (entry.value / totalAmount) * 100;
              final transactionCount = _transactions
                  .where((t) => t.categoryId == entry.key)
                  .length;
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: _getCategoryColor(entry.key).withOpacity(0.2),
                          child: Icon(
                            _getCategoryIcon(entry.key),
                            color: _getCategoryColor(entry.key),
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _getCategoryName(entry.key),
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '$transactionCount transactions',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              currencyFormat.format(entry.value),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '${percentage.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(entry.key)),
                      minHeight: 6,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ],
                ),
              );
            }).toList(),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/categories');
                },
                child: const Text('Manage Categories'),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 