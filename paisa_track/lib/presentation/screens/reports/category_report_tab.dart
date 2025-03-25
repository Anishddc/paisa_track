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
  DateTime _startDate = DateTime.now().copyWith(day: 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  
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
        _transactions = _transactions.where((t) => t.isIncome).toList();
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
                        _buildDateSelector(),
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
      },
    );
  }
  
  Widget _buildDateSelector() {
    return Container(
      margin: const EdgeInsets.fromLTRB(0, 0, 0, 0),
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
            'Select Time Period',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          InkWell(
            onTap: _selectDateRange,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: Colors.grey.shade300,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today,
                    color: ColorConstants.primaryColor,
                    size: 18,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      '${DateFormat('MMM d, y').format(_startDate)} - ${DateFormat('MMM d, y').format(_endDate)}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildQuickDateButton('This Month', () => _setThisMonth()),
              _buildQuickDateButton('Last Month', () => _setLastMonth()),
              _buildQuickDateButton('Year to Date', () => _setYearToDate()),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabSelector() {
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
          const Text(
            'Category Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                _buildTabButton('Expense', Icons.arrow_downward, Colors.red),
                _buildTabButton('Income', Icons.arrow_upward, Colors.green),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildTabButton(String label, IconData icon, Color color) {
    final bool isSelected = _selectedTab == label;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTab = label;
            _loadData(); // Reload data for the selected tab
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? ColorConstants.primaryColor : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.white : color,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.grey.shade800,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
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
  
  void _setYearToDate() {
    final now = DateTime.now();
    setState(() {
      _startDate = DateTime(now.year, 1, 1);
      _endDate = DateTime(now.year, now.month, now.day);
    });
    _loadData();
  }
  
  Widget _buildCategorySummary() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final totalAmount = _getTotalAmount();
    final categoryCount = _categorySpending.length;
    
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${_selectedTab} Summary',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
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
    );
  }
  
  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: color,
            size: 22,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
            color: color,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }
  
  Widget _buildCategoryPieChart() {
    if (_categorySpending.isEmpty) {
      return Container(
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
        child: Center(
          child: Column(
            children: [
              Icon(
                _selectedTab == 'Expense' ? Icons.shopping_cart_outlined : Icons.account_balance_wallet_outlined,
                size: 48,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                'No ${_selectedTab.toLowerCase()} data available for this period',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    final totalAmount = _getTotalAmount();
    
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
          Text(
            '${_selectedTab} by Category',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
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
        radius: 80,
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
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: _getCategoryColor(entry.key),
                  shape: BoxShape.circle,
                ),
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
          Text(
            '${_selectedTab} Categories Breakdown',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: sortedCategories.length,
            separatorBuilder: (context, index) => const Divider(height: 24),
            itemBuilder: (context, index) {
              final entry = sortedCategories[index];
              final percentage = (entry.value / totalAmount) * 100;
              final transactionCount = _transactions
                  .where((t) => t.categoryId == entry.key)
                  .length;
              
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _getCategoryColor(entry.key).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
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
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              '$transactionCount transactions',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
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
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _selectedTab == 'Expense' 
                                  ? Colors.red.shade600 
                                  : Colors.green.shade600,
                            ),
                          ),
                          Text(
                            '${percentage.toStringAsFixed(1)}%',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(_getCategoryColor(entry.key)),
                      minHeight: 5,
                    ),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
} 