import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/utils/app_router.dart';
import 'package:paisa_track/core/utils/date_utils.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/presentation/widgets/common/loading_indicator.dart';
import 'package:paisa_track/presentation/widgets/common/error_view.dart';

class TransactionStatisticsScreen extends StatefulWidget {
  const TransactionStatisticsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionStatisticsScreen> createState() => _TransactionStatisticsScreenState();
}

class _TransactionStatisticsScreenState extends State<TransactionStatisticsScreen> with SingleTickerProviderStateMixin {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final AccountRepository _accountRepository = AccountRepository();
  
  List<TransactionModel> _transactions = [];
  Map<String, CategoryModel> _categoriesMap = {};
  Map<String, AccountModel> _accountsMap = {};
  
  bool _isLoading = true;
  String? _error;
  
  // Time period selection
  String _selectedPeriod = 'This Month';
  final List<String> _periods = [
    'Last 7 Days',
    'Last 30 Days',
    'This Month',
    'Last Month',
    'Last 3 Months',
    'This Year',
  ];
  
  // Statistics data
  double _totalIncome = 0;
  double _totalExpenses = 0;
  double _totalTransfers = 0;
  Map<String, double> _categoryExpenses = {};
  Map<String, double> _categoryIncome = {};
  List<FlSpot> _expenseTrend = [];
  List<FlSpot> _incomeTrend = [];
  late TabController _tabController;
  
  // Date range for statistics
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  // Statistics data
  double _totalExpense = 0;
  double _totalTransfer = 0;
  List<TransactionModel> _recentTransactions = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load all transactions
      final transactions = _transactionRepository.getAllTransactions();
      
      // Load categories and accounts
      final categories = _categoryRepository.getAllCategories();
      final accounts = _accountRepository.getAllAccounts();
      
      // Create maps for quick lookups
      final categoriesMap = {for (var c in categories) c.id: c};
      final accountsMap = {for (var a in accounts) a.id: a};
      
      setState(() {
        _transactions = transactions;
        _categoriesMap = categoriesMap;
        _accountsMap = accountsMap;
        _isLoading = false;
      });
      
      // Calculate statistics
      _calculateStatistics();
    } catch (e) {
      setState(() {
        _error = 'Failed to load statistics: $e';
        _isLoading = false;
      });
    }
  }

  void _calculateStatistics() {
    // Reset statistics
    _totalIncome = 0;
    _totalExpenses = 0;
    _totalTransfers = 0;
    _categoryExpenses.clear();
    _categoryIncome.clear();
    _expenseTrend.clear();
    _incomeTrend.clear();

    // Get date range based on selected period
    final now = DateTime.now();
    DateTime startDate;
    
    switch (_selectedPeriod) {
      case 'Last 7 Days':
        startDate = now.subtract(const Duration(days: 7));
        break;
      case 'Last 30 Days':
        startDate = now.subtract(const Duration(days: 30));
        break;
      case 'This Month':
        startDate = DateTime(now.year, now.month, 1);
        break;
      case 'Last Month':
        startDate = DateTime(now.year, now.month - 1, 1);
        break;
      case 'Last 3 Months':
        startDate = DateTime(now.year, now.month - 2, 1);
        break;
      case 'This Year':
        startDate = DateTime(now.year, 1, 1);
        break;
      default:
        startDate = DateTime(now.year, now.month, 1);
    }

    // Filter transactions by date range
    final filteredTransactions = _transactions.where((t) => 
      t.date.isAfter(startDate) || t.date.isAtSameMomentAs(startDate)
    ).toList();

    // Calculate totals and category breakdowns
    for (final transaction in filteredTransactions) {
      final category = _categoriesMap[transaction.categoryId];
      if (category == null) continue;

      switch (transaction.type) {
        case TransactionType.income:
          _totalIncome += transaction.amount;
          _categoryIncome[category.name] = (_categoryIncome[category.name] ?? 0) + transaction.amount;
          break;
        case TransactionType.expense:
          _totalExpenses += transaction.amount;
          _categoryExpenses[category.name] = (_categoryExpenses[category.name] ?? 0) + transaction.amount;
          break;
        case TransactionType.transfer:
          _totalTransfers += transaction.amount;
          break;
      }
    }

    // Calculate trends
    final days = now.difference(startDate).inDays;
    final dailyExpenses = <DateTime, double>{};
    final dailyIncome = <DateTime, double>{};

    // Initialize daily maps
    for (var i = 0; i <= days; i++) {
      final date = startDate.add(Duration(days: i));
      dailyExpenses[DateTime(date.year, date.month, date.day)] = 0;
      dailyIncome[DateTime(date.year, date.month, date.day)] = 0;
    }

    // Fill in actual values
    for (final transaction in filteredTransactions) {
      final date = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      if (transaction.type == TransactionType.expense) {
        dailyExpenses[date] = (dailyExpenses[date] ?? 0) + transaction.amount;
      } else if (transaction.type == TransactionType.income) {
        dailyIncome[date] = (dailyIncome[date] ?? 0) + transaction.amount;
      }
    }

    // Create trend data points
    var x = 0.0;
    dailyExpenses.forEach((date, amount) {
      _expenseTrend.add(FlSpot(x, amount));
      x += 1;
    });

    x = 0.0;
    dailyIncome.forEach((date, amount) {
      _incomeTrend.add(FlSpot(x, amount));
      x += 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Statistics'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.list),
            tooltip: 'All Transactions',
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.allTransactions);
            },
          ),
          IconButton(
            icon: const Icon(Icons.calendar_today),
            onPressed: _selectDateRange,
            tooltip: 'Select Date Range',
          ),
          PopupMenuButton<String>(
            initialValue: _selectedPeriod,
            onSelected: (value) {
              setState(() {
                _selectedPeriod = value;
                _calculateStatistics();
              });
            },
            itemBuilder: (context) => _periods.map((period) => 
              PopupMenuItem<String>(
                value: period,
                child: Text(period),
              )
            ).toList(),
          ),
        ],
      ),
      body: _isLoading
          ? const LoadingIndicator()
          : _error != null
              ? ErrorView(
                  message: _error!,
                  onRetry: _loadData,
                )
              : Column(
                  children: [
                    TabBar(
                      controller: _tabController,
                      tabs: const [
                        Tab(text: 'Overview'),
                        Tab(text: 'Categories'),
                        Tab(text: 'Transactions'),
                      ],
                    ),
                    Expanded(
                      child: TabBarView(
                        controller: _tabController,
                        children: [
                          _buildOverviewTab(),
                          _buildCategoriesTab(),
                          _buildTransactionsTab(),
                        ],
                      ),
                    ),
                  ],
                ),
    );
  }

  Widget _buildOverviewTab() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDateRangeCard(),
          const SizedBox(height: 16),
          _buildTotalSummaryCard(currencyFormat),
          const SizedBox(height: 16),
          _buildPieChart(),
          const SizedBox(height: 16),
          _buildTrendChart(),
        ],
      ),
    );
  }
  
  Widget _buildDateRangeCard() {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Date Range',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(dateFormat.format(_startDate)),
                const Text('to'),
                Text(dateFormat.format(_endDate)),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTotalSummaryCard(NumberFormat currencyFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Summary',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSummaryItem('Income', _totalIncome, ColorConstants.successColor, currencyFormat),
                _buildSummaryItem('Expenses', _totalExpenses, ColorConstants.errorColor, currencyFormat),
                _buildSummaryItem('Transfers', _totalTransfers, ColorConstants.infoColor, currencyFormat),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildSummaryItem(String label, double amount, Color color, NumberFormat currencyFormat) {
    return Column(
      children: [
        Text(
          currencyFormat.format(amount),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
  
  Widget _buildPieChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Distribution',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: _categoryExpenses.entries.map((entry) {
                    return PieChartSectionData(
                      value: entry.value,
                      title: '${(entry.value / _totalExpenses * 100).toStringAsFixed(1)}%',
                      radius: 100,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTrendChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
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
            SizedBox(
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: const FlGridData(show: true),
                  titlesData: const FlTitlesData(show: true),
                  borderData: FlBorderData(show: true),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        const FlSpot(0, 0),
                        FlSpot(1, _totalIncome),
                        FlSpot(2, _totalExpenses),
                      ],
                      isCurved: true,
                      color: ColorConstants.primaryColor,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoriesTab() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Expense Categories',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          ..._categoryExpenses.entries.map((entry) {
            final percentage = (_totalExpenses > 0) 
                ? (entry.value / _totalExpenses * 100) 
                : 0.0;
                
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                title: Text(entry.key), // TODO: Get category name from repository
                subtitle: LinearProgressIndicator(
                  value: entry.value / _totalExpenses,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(ColorConstants.primaryColor),
                ),
                trailing: Text(
                  '${currencyFormat.format(entry.value)} (${percentage.toStringAsFixed(1)}%)',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: ColorConstants.errorColor,
                  ),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
  
  Widget _buildTransactionsTab() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _transactions.length,
      itemBuilder: (context, index) {
        final transaction = _transactions[index];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getTransactionColor(transaction.type),
              child: Icon(
                _getTransactionIcon(transaction.type),
                color: Colors.white,
              ),
            ),
            title: Text(transaction.description),
            subtitle: Text(dateFormat.format(transaction.date)),
            trailing: Text(
              currencyFormat.format(transaction.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: _getTransactionColor(transaction.type),
              ),
            ),
          ),
        );
      },
    );
  }
  
  Color _getTransactionColor(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return ColorConstants.successColor;
      case TransactionType.expense:
        return ColorConstants.errorColor;
      case TransactionType.transfer:
        return ColorConstants.infoColor;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getTransactionIcon(TransactionType type) {
    switch (type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      default:
        return Icons.attach_money;
    }
  }
  
  Future<void> _selectDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: DateTimeRange(start: _startDate, end: _endDate),
    );
    
    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      _loadStatistics();
    }
  }
  
  Future<void> _loadStatistics() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get transactions for the selected date range
      final transactions = _transactionRepository.getTransactionsByDateRange(_startDate, _endDate);
      
      // Calculate totals
      _totalExpense = transactions
          .where((t) => t.type == TransactionType.expense)
          .fold(0, (sum, t) => sum + t.amount);
          
      _totalTransfer = transactions
          .where((t) => t.type == TransactionType.transfer)
          .fold(0, (sum, t) => sum + t.amount);
      
      // Calculate category-wise totals
      _categoryExpenses.clear();
      _categoryIncome.clear();
      
      for (var transaction in transactions) {
        if (transaction.type == TransactionType.expense) {
          _categoryExpenses[transaction.categoryId] = 
              (_categoryExpenses[transaction.categoryId] ?? 0) + transaction.amount;
        } else if (transaction.type == TransactionType.income) {
          _categoryIncome[transaction.categoryId] = 
              (_categoryIncome[transaction.categoryId] ?? 0) + transaction.amount;
        }
      }
      
      // Get recent transactions
      _recentTransactions = transactions;
      _recentTransactions.sort((a, b) => b.date.compareTo(a.date));
      
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading statistics: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
} 