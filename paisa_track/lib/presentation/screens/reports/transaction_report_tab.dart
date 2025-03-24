import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:provider/provider.dart';

class TransactionReportTab extends StatefulWidget {
  const TransactionReportTab({Key? key}) : super(key: key);

  @override
  State<TransactionReportTab> createState() => _TransactionReportTabState();
}

class _TransactionReportTabState extends State<TransactionReportTab> {
  late TransactionRepository _transactionRepository;
  bool _isLoading = true;
  
  // Transaction data
  List<TransactionModel> _transactions = [];
  
  // Date range
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  String _selectedTimeFrame = 'Monthly';
  
  // Report data
  double _totalIncome = 0;
  double _totalExpense = 0;
  Map<DateTime, double> _incomeByDate = {};
  Map<DateTime, double> _expenseByDate = {};
  
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
    _transactionRepository = Provider.of<TransactionRepository>(context, listen: false);
    _loadData();
  }
  
  void _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Load transactions for selected period
      _transactions = _transactionRepository.getTransactionsInRange(_startDate, _endDate);
      
      // Calculate totals
      _totalIncome = _transactions
          .where((t) => !t.isExpense)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      _totalExpense = _transactions
          .where((t) => t.isExpense)
          .fold(0.0, (sum, t) => sum + t.amount);
      
      // Group transactions by date
      _incomeByDate = _groupTransactionsByDate(_transactions.where((t) => !t.isExpense).toList());
      _expenseByDate = _groupTransactionsByDate(_transactions.where((t) => t.isExpense).toList());
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading transaction reports: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }
  
  Map<DateTime, double> _groupTransactionsByDate(List<TransactionModel> transactions) {
    final Map<DateTime, double> result = {};
    
    for (var transaction in transactions) {
      final date = _getDateByTimeFrame(transaction.date);
      if (result.containsKey(date)) {
        result[date] = result[date]! + transaction.amount;
      } else {
        result[date] = transaction.amount;
      }
    }
    
    return result;
  }
  
  DateTime _getDateByTimeFrame(DateTime date) {
    switch (_selectedTimeFrame) {
      case 'Daily':
        return DateTime(date.year, date.month, date.day);
      case 'Weekly':
        // Find the start of the week (Monday)
        final daysToSubtract = (date.weekday - 1) % 7;
        return DateTime(date.year, date.month, date.day - daysToSubtract);
      case 'Monthly':
        return DateTime(date.year, date.month, 1);
      case 'Yearly':
        return DateTime(date.year, 1, 1);
      default:
        return DateTime(date.year, date.month, date.day);
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
                    _buildTransactionSummary(),
                    const SizedBox(height: 16),
                    _buildTimeFrameSelector(),
                    const SizedBox(height: 16),
                    _buildIncomeExpenseChart(),
                    const SizedBox(height: 16),
                    _buildCashflowChart(),
                    const SizedBox(height: 16),
                    _buildTransactionTrends(),
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
  
  Widget _buildTimeFrameSelector() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Group Data By',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: const [
                ButtonSegment<String>(value: 'Daily', label: Text('Daily')),
                ButtonSegment<String>(value: 'Weekly', label: Text('Weekly')),
                ButtonSegment<String>(value: 'Monthly', label: Text('Monthly')),
                ButtonSegment<String>(value: 'Yearly', label: Text('Yearly')),
              ],
              selected: {_selectedTimeFrame},
              onSelectionChanged: (Set<String> selection) {
                setState(() {
                  _selectedTimeFrame = selection.first;
                  _loadData(); // Reload data with new time frame
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
  
  Widget _buildTransactionSummary() {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final netCashflow = _totalIncome - _totalExpense;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Transaction Summary: ${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryItem(
                  'Income',
                  currencyFormat.format(_totalIncome),
                  Icons.arrow_upward,
                  ColorConstants.successColor,
                ),
                _buildSummaryItem(
                  'Expenses',
                  currencyFormat.format(_totalExpense),
                  Icons.arrow_downward,
                  ColorConstants.errorColor,
                ),
                _buildSummaryItem(
                  'Net Cashflow',
                  currencyFormat.format(netCashflow),
                  netCashflow >= 0 ? Icons.trending_up : Icons.trending_down,
                  netCashflow >= 0 ? ColorConstants.successColor : ColorConstants.errorColor,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Total Transactions: ${_transactions.length}',
              style: TextStyle(
                color: Colors.grey[700],
              ),
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
  
  Widget _buildIncomeExpenseChart() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
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
              child: BarChart(
                BarChartData(
                  barGroups: [
                    BarChartGroupData(
                      x: 0,
                      barRods: [
                        BarChartRodData(
                          fromY: 0,
                          toY: _totalIncome,
                          width: 20,
                          color: ColorConstants.successColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                    BarChartGroupData(
                      x: 1,
                      barRods: [
                        BarChartRodData(
                          fromY: 0,
                          toY: _totalExpense,
                          width: 20,
                          color: ColorConstants.errorColor,
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(4),
                            topRight: Radius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ],
                  titlesData: FlTitlesData(
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          final titles = ['Income', 'Expenses'];
                          return Padding(
                            padding: const EdgeInsets.only(top: 8.0),
                            child: Text(
                              titles[value.toInt()],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          );
                        },
                        reservedSize: 30,
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 40,
                        getTitlesWidget: (double value, TitleMeta meta) {
                          return Text(
                            NumberFormat.compactCurrency(symbol: '\$').format(value),
                            style: const TextStyle(fontSize: 10),
                          );
                        },
                      ),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: _getYAxisInterval(),
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: Colors.grey[300],
                        strokeWidth: 1,
                      );
                    },
                  ),
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      tooltipBgColor: Colors.blueGrey,
                      tooltipPadding: const EdgeInsets.all(8),
                      tooltipMargin: 8,
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final titles = ['Income', 'Expenses'];
                        final amount = [_totalIncome, _totalExpense][group.x.toInt()];
                        return BarTooltipItem(
                          '${titles[group.x.toInt()]}: ${NumberFormat.currency(symbol: '\$').format(amount)}',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCashflowChart() {
    final netCashflow = _totalIncome - _totalExpense;
    final isPositive = netCashflow >= 0;
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Net Cashflow',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Text(
                  NumberFormat.currency(symbol: '\$').format(netCashflow),
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? ColorConstants.successColor : ColorConstants.errorColor,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: isPositive ? ColorConstants.successColor : ColorConstants.errorColor,
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              isPositive
                  ? 'Your income exceeds your expenses. Great job!'
                  : 'Your expenses exceed your income. Consider adjusting your budget.',
              style: TextStyle(
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: 0.5,
              backgroundColor: ColorConstants.errorColor.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation<Color>(
                ColorConstants.successColor,
              ),
              minHeight: 40,
              borderRadius: BorderRadius.circular(4),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: ColorConstants.successColor,
                    ),
                    const SizedBox(width: 4),
                    const Text('Income', style: TextStyle(fontSize: 12)),
                  ],
                ),
                Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      color: ColorConstants.errorColor.withOpacity(0.2),
                    ),
                    const SizedBox(width: 4),
                    const Text('Expenses', style: TextStyle(fontSize: 12)),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionTrends() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Transaction Trends',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'Historical transaction trend data will appear here.',
                style: TextStyle(color: Colors.grey),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pushNamed('/transactions');
                },
                child: const Text('View All Transactions'),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  double _getYAxisInterval() {
    final maxValue = _totalIncome > _totalExpense ? _totalIncome : _totalExpense;
    if (maxValue == 0) return 100;
    
    if (maxValue < 100) return 20;
    if (maxValue < 1000) return 200;
    if (maxValue < 10000) return 2000;
    return 5000;
  }
} 