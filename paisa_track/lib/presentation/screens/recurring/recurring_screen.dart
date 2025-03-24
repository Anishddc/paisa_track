import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({Key? key}) : super(key: key);

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  bool _isLoading = false;
  final List<Map<String, dynamic>> _dummyRecurringTransactions = [];
  
  @override
  void initState() {
    super.initState();
    _createDummyRecurringTransactions();
  }
  
  void _createDummyRecurringTransactions() {
    // Sample recurring transactions for the placeholder screen
    _dummyRecurringTransactions.add({
      'id': '1',
      'description': 'Netflix Subscription',
      'amount': 14.99,
      'frequency': 'Monthly',
      'nextDate': DateTime.now().add(const Duration(days: 8)),
      'category': 'Entertainment',
      'accountId': '1',
      'accountName': 'Main Bank Account',
      'isActive': true,
      'color': Colors.red,
      'icon': Icons.movie,
    });
    
    _dummyRecurringTransactions.add({
      'id': '2',
      'description': 'Gym Membership',
      'amount': 49.99,
      'frequency': 'Monthly',
      'nextDate': DateTime.now().add(const Duration(days: 15)),
      'category': 'Health',
      'accountId': '1',
      'accountName': 'Main Bank Account',
      'isActive': true,
      'color': Colors.green,
      'icon': Icons.fitness_center,
    });
    
    _dummyRecurringTransactions.add({
      'id': '3',
      'description': 'Rent Payment',
      'amount': 1200.00,
      'frequency': 'Monthly',
      'nextDate': DateTime.now().add(const Duration(days: 3)),
      'category': 'Housing',
      'accountId': '1',
      'accountName': 'Main Bank Account',
      'isActive': true,
      'color': Colors.blue,
      'icon': Icons.home,
    });
    
    _dummyRecurringTransactions.add({
      'id': '4',
      'description': 'Electricity Bill',
      'amount': 85.50,
      'frequency': 'Monthly',
      'nextDate': DateTime.now().add(const Duration(days: 20)),
      'category': 'Utilities',
      'accountId': '1',
      'accountName': 'Main Bank Account',
      'isActive': true,
      'color': Colors.amber,
      'icon': Icons.bolt,
    });
    
    _dummyRecurringTransactions.add({
      'id': '5',
      'description': 'Salary Deposit',
      'amount': 3500.00,
      'frequency': 'Monthly',
      'nextDate': DateTime.now().add(const Duration(days: 12)),
      'category': 'Income',
      'accountId': '1',
      'accountName': 'Main Bank Account',
      'isActive': true,
      'color': Colors.teal,
      'icon': Icons.work,
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Filter functionality coming soon!'))
              );
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _dummyRecurringTransactions.isEmpty
              ? _buildEmptyState()
              : _buildRecurringList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add recurring transaction functionality coming soon!'))
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.repeat_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No recurring transactions',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set up recurring transactions for bills, subscriptions, or income',
            style: TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add recurring transaction functionality coming soon!'))
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Recurring Transaction'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecurringList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dummyRecurringTransactions.length,
      itemBuilder: (context, index) {
        final transaction = _dummyRecurringTransactions[index];
        return _buildRecurringCard(transaction);
      },
    );
  }
  
  Widget _buildRecurringCard(Map<String, dynamic> transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM d, yyyy');
    
    final daysUntilNext = transaction['nextDate'].difference(DateTime.now()).inDays;
    final isIncome = transaction['category'] == 'Income';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: transaction['color'].withOpacity(0.2),
                  child: Icon(
                    transaction['icon'],
                    color: transaction['color'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction['description'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Account: ${transaction['accountName']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(transaction['amount']),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 14,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Next: ${dateFormat.format(transaction['nextDate'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: daysUntilNext <= 3 ? Colors.orange : Colors.grey,
                        fontWeight: daysUntilNext <= 3 ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    transaction['frequency'],
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Skip functionality coming soon!'))
                    );
                  },
                  icon: const Icon(Icons.skip_next, size: 16),
                  label: const Text('Skip'),
                ),
                TextButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Edit functionality coming soon!'))
                    );
                  },
                  icon: const Icon(Icons.edit, size: 16),
                  label: const Text('Edit'),
                ),
                Switch(
                  value: transaction['isActive'],
                  onChanged: (value) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Toggle functionality coming soon!'))
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 