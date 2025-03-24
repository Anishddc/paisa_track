import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class BillsScreen extends StatefulWidget {
  const BillsScreen({Key? key}) : super(key: key);

  @override
  State<BillsScreen> createState() => _BillsScreenState();
}

class _BillsScreenState extends State<BillsScreen> {
  bool _isLoading = false;
  final List<Map<String, dynamic>> _dummyBills = [];
  
  @override
  void initState() {
    super.initState();
    _createDummyBills();
  }
  
  void _createDummyBills() {
    // Sample bills for the placeholder screen
    _dummyBills.add({
      'id': '1',
      'name': 'Electricity Bill',
      'amount': 85.50,
      'dueDate': DateTime.now().add(const Duration(days: 5)),
      'category': 'Utilities',
      'payee': 'City Power Co.',
      'accountId': '1',
      'accountName': 'Main Bank Account',
      'isRecurring': true,
      'status': 'upcoming',
      'color': Colors.amber,
      'icon': Icons.bolt,
    });
    
    _dummyBills.add({
      'id': '2',
      'name': 'Internet Service',
      'amount': 59.99,
      'dueDate': DateTime.now().add(const Duration(days: 12)),
      'category': 'Utilities',
      'payee': 'Fast Internet Inc.',
      'accountId': '1',
      'accountName': 'Main Bank Account',
      'isRecurring': true,
      'status': 'upcoming',
      'color': Colors.blue,
      'icon': Icons.wifi,
    });
    
    _dummyBills.add({
      'id': '3',
      'name': 'Water Bill',
      'amount': 45.75,
      'dueDate': DateTime.now().add(const Duration(days: -2)),
      'category': 'Utilities',
      'payee': 'City Water Department',
      'accountId': '1',
      'accountName': 'Main Bank Account',
      'isRecurring': true,
      'status': 'overdue',
      'color': Colors.cyan,
      'icon': Icons.water_drop,
    });
    
    _dummyBills.add({
      'id': '4',
      'name': 'Mobile Phone',
      'amount': 75.00,
      'dueDate': DateTime.now().add(const Duration(days: 20)),
      'category': 'Utilities',
      'payee': 'Mobile Service Provider',
      'accountId': '1',
      'accountName': 'Main Bank Account',
      'isRecurring': true,
      'status': 'upcoming',
      'color': Colors.green,
      'icon': Icons.phone_android,
    });
    
    _dummyBills.add({
      'id': '5',
      'name': 'Credit Card Payment',
      'amount': 350.00,
      'dueDate': DateTime.now().add(const Duration(days: 2)),
      'category': 'Debt',
      'payee': 'Bank Credit Card',
      'accountId': '1',
      'accountName': 'Main Bank Account',
      'isRecurring': true,
      'status': 'upcoming',
      'color': Colors.red,
      'icon': Icons.credit_card,
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bill Reminders'),
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
          : DefaultTabController(
              length: 3,
              child: Column(
                children: [
                  const TabBar(
                    tabs: [
                      Tab(text: 'Upcoming'),
                      Tab(text: 'Paid'),
                      Tab(text: 'Overdue'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        _buildBillsList('upcoming'),
                        _buildBillsList('paid'),
                        _buildBillsList('overdue'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add bill reminder functionality coming soon!'))
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState(String status) {
    final String message = status == 'upcoming' 
        ? 'No upcoming bills'
        : status == 'paid'
            ? 'No paid bills'
            : 'No overdue bills';
    
    final String subMessage = status == 'upcoming'
        ? 'Add bill reminders to track upcoming payments'
        : status == 'paid'
            ? 'Your paid bills will appear here'
            : 'You have no overdue bills - good job!';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            status == 'overdue' ? Icons.warning_outlined : Icons.calendar_today_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subMessage,
            style: const TextStyle(
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          if (status == 'upcoming') ...[
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Add bill reminder functionality coming soon!'))
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Bill Reminder'),
            ),
          ],
        ],
      ),
    );
  }
  
  Widget _buildBillsList(String status) {
    final bills = _dummyBills.where((bill) => bill['status'] == status).toList();
    
    if (bills.isEmpty) {
      return _buildEmptyState(status);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: bills.length,
      itemBuilder: (context, index) {
        final bill = bills[index];
        return _buildBillCard(bill);
      },
    );
  }
  
  Widget _buildBillCard(Map<String, dynamic> bill) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM d, yyyy');
    
    final daysUntilDue = bill['dueDate'].difference(DateTime.now()).inDays;
    final isOverdue = daysUntilDue < 0;
    
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
                  backgroundColor: bill['color'].withOpacity(0.2),
                  child: Icon(
                    bill['icon'],
                    color: bill['color'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bill['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Payee: ${bill['payee']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Text(
                  currencyFormat.format(bill['amount']),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
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
                      color: isOverdue ? Colors.red : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Due: ${dateFormat.format(bill['dueDate'])}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isOverdue ? Colors.red : daysUntilDue <= 3 ? Colors.orange : Colors.grey,
                        fontWeight: (isOverdue || daysUntilDue <= 3) ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                  ],
                ),
                if (bill['isRecurring'])
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.blue.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.repeat,
                          size: 12,
                          color: Colors.blue,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Recurring',
                          style: TextStyle(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Account: ${bill['accountName']}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Pay now functionality coming soon!'))
                    );
                  },
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Pay Now'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Mark as paid functionality coming soon!'))
                    );
                  },
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Mark as Paid'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 