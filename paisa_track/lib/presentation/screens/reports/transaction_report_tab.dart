import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

class TransactionReportTab extends StatefulWidget {
  const TransactionReportTab({Key? key}) : super(key: key);

  @override
  State<TransactionReportTab> createState() => _TransactionReportTabState();
}

class _TransactionReportTabState extends State<TransactionReportTab> {
  late TransactionRepository _transactionRepository;
  late CategoryRepository _categoryRepository;
  late AccountRepository _accountRepository;
  bool _isLoading = true;
  
  DateTime _startDate = DateTime.now().copyWith(day: 1);
  DateTime _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
  List<TransactionModel> _transactions = [];
  
  Map<DateTime, double> _dailyIncomes = {};
  Map<DateTime, double> _dailyExpenses = {};
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _averageDailyExpense = 0;
  double _averageDailyIncome = 0;
  
  @override
  void initState() {
    super.initState();
  }
  
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    // Get repository instances
    _transactionRepository = Provider.of<TransactionRepository>(context, listen: false);
    _categoryRepository = Provider.of<CategoryRepository>(context, listen: false);
    _accountRepository = Provider.of<AccountRepository>(context, listen: false);
    
    // Initial data load
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      _transactions = _transactionRepository.getTransactionsInRange(
        _startDate,
        _endDate,
      );

      _calculateDailyTransactions();
      _calculateStatistics();
    } catch (e) {
      debugPrint('Error loading transaction data: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _calculateDailyTransactions() {
    _dailyIncomes = {};
    _dailyExpenses = {};
    _totalIncome = 0;
    _totalExpense = 0;
    
    // Initialize all days in the range
    for (DateTime date = _startDate;
        date.isBefore(_endDate.add(const Duration(days: 1)));
        date = date.add(const Duration(days: 1))) {
      final DateTime normalizedDate = DateTime(date.year, date.month, date.day);
      _dailyIncomes[normalizedDate] = 0;
      _dailyExpenses[normalizedDate] = 0;
    }
    
    // Sum up transactions by day
    for (final transaction in _transactions) {
      final DateTime normalizedDate = DateTime(
        transaction.date.year,
        transaction.date.month,
        transaction.date.day,
      );
      
      if (transaction.isIncome) {
        _dailyIncomes[normalizedDate] = 
            (_dailyIncomes[normalizedDate] ?? 0) + transaction.amount;
        _totalIncome += transaction.amount;
      } else if (transaction.isExpense) {
        _dailyExpenses[normalizedDate] = 
            (_dailyExpenses[normalizedDate] ?? 0) + transaction.amount;
        _totalExpense += transaction.amount;
      }
    }
  }
  
  void _calculateStatistics() {
    final int days = _endDate.difference(_startDate).inDays + 1;
    _averageDailyExpense = days > 0 ? _totalExpense / days : 0;
    _averageDailyIncome = days > 0 ? _totalIncome / days : 0;
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

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _transactionRepository.transactionsChanged,
      builder: (context, snapshot) {
        // Handle errors in the stream
        if (snapshot.hasError) {
          debugPrint('Error in transaction stream: ${snapshot.error}');
          // Continue showing the current data
        }
        
        // Reload data when stream emits an event
        if (snapshot.connectionState == ConnectionState.active) {
          // Load data on a slight delay to ensure Hive has completed its operation
          Future.microtask(() => _loadData());
        }
        
        return RefreshIndicator(
          onRefresh: _loadData,
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  padding: const EdgeInsets.only(bottom: 100),
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDateSelector(),
                      _buildSummaryCards(),
                      _buildLineChart(),
                      _buildTransactionList(),
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
                  title: 'Total Income',
                  amount: _totalIncome,
                  currencyFormat: currencyFormat,
                  color: Colors.green.shade600,
                  icon: Icons.arrow_upward,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Total Expenses',
                  amount: _totalExpense,
                  currencyFormat: currencyFormat,
                  color: Colors.red.shade600,
                  icon: Icons.arrow_downward,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  title: 'Avg. Daily Income',
                  amount: _averageDailyIncome,
                  currencyFormat: currencyFormat,
                  color: Colors.amber.shade700,
                  icon: Icons.show_chart,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildSummaryCard(
                  title: 'Avg. Daily Expense',
                  amount: _averageDailyExpense,
                  currencyFormat: currencyFormat,
                  color: Colors.deepPurple.shade400,
                  icon: Icons.show_chart,
                ),
              ),
            ],
          ),
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
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            currencyFormat.format(amount),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart() {
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
          const Row(
            children: [
              Text(
                'Daily Transactions',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Spacer(),
              _ChartLegendItem(color: Colors.green, label: 'Income'),
              SizedBox(width: 12),
              _ChartLegendItem(color: Colors.red, label: 'Expense'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 220,
            child: _dailyIncomes.isEmpty && _dailyExpenses.isEmpty
                ? const Center(
                    child: Text(
                      'No transaction data available for this period',
                      style: TextStyle(
                        color: Colors.grey,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  )
                : _buildLineChartContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildLineChartContent() {
    try {
      if (_dailyIncomes.isEmpty) {
        return const Center(
          child: Text(
            'No data available for chart visualization',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }

      // Check if we can build a valid chart
      if (_dailyIncomes.length < 2) {
        return const Center(
          child: Text(
            'Not enough data points for chart visualization',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        );
      }

      return LineChart(
        LineChartData(
          minX: 0,
          maxX: _dailyIncomes.length.toDouble() - 1,
          minY: 0,
          maxY: _getChartMaxY(),
          lineTouchData: LineTouchData(
            touchTooltipData: LineTouchTooltipData(
              getTooltipItems: (touchedSpots) {
                return touchedSpots.map((touchedSpot) {
                  final int index = touchedSpot.x.toInt();
                  final date = _getDayFromIndex(index);
                  final formatter = DateFormat('MMM d');
                  final String dateStr = formatter.format(date);
                  final currencyFormat = NumberFormat.currency(symbol: '\$');
                  
                  return LineTooltipItem(
                    '$dateStr\n${currencyFormat.format(touchedSpot.y)}',
                    TextStyle(
                      color: touchedSpot.bar.color,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                }).toList();
              },
            ),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: _getChartMaxY() / 5,
            getDrawingHorizontalLine: (value) {
              return FlLine(
                color: Colors.grey.withOpacity(0.2),
                strokeWidth: 1,
              );
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            rightTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                interval: _getDateLabelInterval(),
                getTitlesWidget: (value, meta) {
                  final int index = value.toInt();
                  if (index < 0 || index >= _dailyIncomes.length) {
                    return const SizedBox.shrink();
                  }
                  
                  final date = _getDayFromIndex(index);
                  return Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      DateFormat('d').format(date),
                      style: const TextStyle(
                        fontSize: 12,
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
                getTitlesWidget: (value, meta) {
                  if (value == 0) {
                    return const SizedBox.shrink();
                  }
                  
                  final formatter = NumberFormat.compactCurrency(
                    symbol: '\$',
                    decimalDigits: 0,
                  );
                  
                  return Text(
                    formatter.format(value),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  );
                },
                reservedSize: 40,
              ),
            ),
          ),
          borderData: FlBorderData(
            show: false,
          ),
          lineBarsData: [
            _buildLineChartBarData(
              _dailyIncomes.values.toList(), 
              Colors.green.shade600,
            ),
            _buildLineChartBarData(
              _dailyExpenses.values.toList(), 
              Colors.red.shade600,
            ),
          ],
        ),
      );
    } catch (e) {
      // Return a fallback widget if chart generation fails
      debugPrint('Error generating chart: $e');
      return const Center(
        child: Text(
          'Unable to generate chart visualization',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }
  }

  LineChartBarData _buildLineChartBarData(List<double> values, Color color) {
    return LineChartBarData(
      spots: List.generate(
        values.length, 
        (index) => FlSpot(index.toDouble(), values[index]),
      ),
      isCurved: true,
      color: color,
      barWidth: 3,
      isStrokeCapRound: true,
      dotData: FlDotData(show: false),
      belowBarData: BarAreaData(
        show: true,
        color: color.withOpacity(0.1),
      ),
    );
  }

  double _getChartMaxY() {
    double maxIncome = _dailyIncomes.values.isEmpty 
        ? 0 
        : _dailyIncomes.values.reduce((a, b) => a > b ? a : b);
    double maxExpense = _dailyExpenses.values.isEmpty 
        ? 0 
        : _dailyExpenses.values.reduce((a, b) => a > b ? a : b);
    double maxValue = maxIncome > maxExpense ? maxIncome : maxExpense;
    return maxValue > 0 ? maxValue * 1.2 : 100;
  }

  double _getDateLabelInterval() {
    final int days = _dailyIncomes.length;
    if (days <= 10) return 1;
    if (days <= 31) return (days / 5).round().toDouble();
    return (days / 10).round().toDouble();
  }

  DateTime _getDayFromIndex(int index) {
    if (_dailyIncomes.isEmpty) {
      // Return current date as fallback if there's no data
      return DateTime.now();
    }
    
    final daysSorted = _dailyIncomes.keys.toList()..sort();
    
    // Handle out of bounds index
    if (index < 0 || index >= daysSorted.length) {
      return DateTime.now();
    }
    
    return daysSorted[index];
  }

  Widget _buildTransactionList() {
    if (_transactions.isEmpty) {
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
            'No transactions for the selected period',
            style: TextStyle(
              color: Colors.grey,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    // Sort transactions by date (newest first)
    final sortedTransactions = List<TransactionModel>.from(_transactions)
      ..sort((a, b) => b.date.compareTo(a.date));

    // Group transactions by date
    final Map<String, List<TransactionModel>> groupedTransactions = {};
    for (var transaction in sortedTransactions) {
      final dateStr = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (!groupedTransactions.containsKey(dateStr)) {
        groupedTransactions[dateStr] = [];
      }
      groupedTransactions[dateStr]!.add(transaction);
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Row(
              children: [
                const Text(
                  'Recent Transactions',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                Text(
                  '${_transactions.length} total',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          const Divider(),
          ...groupedTransactions.entries.take(5).map((entry) {
            final dateStr = entry.key;
            final transactionsForDate = entry.value;
            final date = DateTime.parse(dateStr);
            
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: Text(
                    DateFormat('EEEE, MMMM d, y').format(date),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey,
                    ),
                  ),
                ),
                ...transactionsForDate.map(_buildTransactionItem),
                if (entry.key != groupedTransactions.keys.toList().take(5).last)
                  const Divider(height: 1),
              ],
            );
          }).toList(),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: TextButton.icon(
                onPressed: () {
                  // Navigate to full transaction history
                },
                icon: const Icon(Icons.history),
                label: const Text('View All Transactions'),
                style: TextButton.styleFrom(
                  foregroundColor: ColorConstants.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    
    final category = _categoryRepository.getCategoryById(transaction.categoryId);
    final account = _accountRepository.getAccountById(transaction.accountId);
    
    final Color amountColor = transaction.isIncome
        ? Colors.green.shade600
        : Colors.red.shade600;
    
    final IconData icon = transaction.isIncome
        ? Icons.arrow_downward
        : transaction.isExpense
            ? Icons.arrow_upward
            : Icons.swap_horiz;
    
    final Color iconColor = transaction.isIncome
        ? Colors.green.shade600
        : transaction.isExpense
            ? Colors.red.shade600
            : Colors.blue.shade600;
    
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: iconColor,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transaction.description,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        DateFormat('MMM d').format(transaction.date),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (category != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: category.color.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            category.name,
                            style: TextStyle(
                              fontSize: 10,
                              color: category.color,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      if (category != null)
                        const SizedBox(width: 8),
                      if (account != null)
                        Text(
                          account.name,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                    ],
                  ),
                ],
              ),
            ),
            Text(
              currencyFormat.format(transaction.amount),
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: amountColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartLegendItem extends StatelessWidget {
  final Color color;
  final String label;

  const _ChartLegendItem({
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
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
} 