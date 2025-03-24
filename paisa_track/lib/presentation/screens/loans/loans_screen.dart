import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class LoansScreen extends StatefulWidget {
  const LoansScreen({Key? key}) : super(key: key);

  @override
  State<LoansScreen> createState() => _LoansScreenState();
}

class _LoansScreenState extends State<LoansScreen> with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  late TabController _tabController;
  final List<Map<String, dynamic>> _dummyLoans = [];
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _createDummyLoans();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  void _createDummyLoans() {
    // Sample loans for the placeholder screen
    _dummyLoans.add({
      'id': '1',
      'name': 'Home Mortgage',
      'originalAmount': 250000.0,
      'remainingAmount': 200000.0,
      'interestRate': 4.5,
      'monthlyPayment': 1265.0,
      'nextPaymentDate': DateTime.now().add(const Duration(days: 15)),
      'lender': 'First National Bank',
      'type': 'borrowed', // borrowed or lent
      'status': 'active',
    });
    
    _dummyLoans.add({
      'id': '2',
      'name': 'Car Loan',
      'originalAmount': 20000.0,
      'remainingAmount': 12000.0,
      'interestRate': 3.9,
      'monthlyPayment': 375.0,
      'nextPaymentDate': DateTime.now().add(const Duration(days: 5)),
      'lender': 'Auto Finance Inc.',
      'type': 'borrowed',
      'status': 'active',
    });
    
    _dummyLoans.add({
      'id': '3',
      'name': 'Personal Loan to Tom',
      'originalAmount': 1000.0,
      'remainingAmount': 1000.0,
      'interestRate': 0.0,
      'monthlyPayment': 0.0,
      'nextPaymentDate': DateTime.now().add(const Duration(days: 30)),
      'lender': 'Tom Smith',
      'type': 'lent',
      'status': 'active',
    });
    
    _dummyLoans.add({
      'id': '4',
      'name': 'Student Loan',
      'originalAmount': 35000.0,
      'remainingAmount': 15000.0,
      'interestRate': 5.2,
      'monthlyPayment': 450.0,
      'nextPaymentDate': DateTime.now().add(const Duration(days: 20)),
      'lender': 'Student Aid Corp',
      'type': 'borrowed',
      'status': 'active',
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Loans'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'I Borrowed'),
            Tab(text: 'I Lent'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildLoansList('borrowed'),
                _buildLoansList('lent'),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add loan functionality coming soon!'))
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildEmptyState(String type) {
    final String message = type == 'borrowed' 
        ? 'No loans you borrowed'
        : 'No loans you lent';
    
    final String subMessage = type == 'borrowed'
        ? 'Add loans you borrowed to track payments'
        : 'Add loans you lent to track repayments';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            type == 'borrowed' ? Icons.account_balance_outlined : Icons.paid_outlined,
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
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add loan functionality coming soon!'))
              );
            },
            icon: const Icon(Icons.add),
            label: Text('Add ${type == 'borrowed' ? 'Loan' : 'Debt'}'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLoansList(String type) {
    final loans = _dummyLoans.where((loan) => loan['type'] == type).toList();
    
    if (loans.isEmpty) {
      return _buildEmptyState(type);
    }
    
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: loans.length,
      itemBuilder: (context, index) {
        final loan = loans[index];
        return _buildLoanCard(loan);
      },
    );
  }
  
  Widget _buildLoanCard(Map<String, dynamic> loan) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final percentFormat = NumberFormat.percentPattern();
    final dateFormat = DateFormat('MMM d, yyyy');
    
    final daysUntilNextPayment = loan['nextPaymentDate'].difference(DateTime.now()).inDays;
    final paymentLate = daysUntilNextPayment < 0;
    
    final progress = 1 - (loan['remainingAmount'] / loan['originalAmount']);
    
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
                  backgroundColor: loan['type'] == 'borrowed' ? Colors.red.withOpacity(0.2) : Colors.green.withOpacity(0.2),
                  child: Icon(
                    loan['type'] == 'borrowed' ? Icons.arrow_outward : Icons.arrow_downward,
                    color: loan['type'] == 'borrowed' ? Colors.red : Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        loan['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${loan['type'] == 'borrowed' ? 'From' : 'To'}: ${loan['lender']}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: loan['status'] == 'active' ? Colors.blue.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    loan['status'].toUpperCase(),
                    style: TextStyle(
                      color: loan['status'] == 'active' ? Colors.blue : Colors.grey,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress.toDouble(),
                backgroundColor: Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(loan['type'] == 'borrowed' ? Colors.orange : Colors.green),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: ${currencyFormat.format(loan['originalAmount'])}',
                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),
                Text(
                  'Remaining: ${currencyFormat.format(loan['remainingAmount'])}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rate: ${percentFormat.format(loan['interestRate']/100)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                if (loan['monthlyPayment'] > 0)
                  Text(
                    'Monthly: ${currencyFormat.format(loan['monthlyPayment'])}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  Icons.calendar_today,
                  size: 14,
                  color: paymentLate ? Colors.red : Colors.grey,
                ),
                const SizedBox(width: 4),
                Text(
                  paymentLate
                      ? 'Payment was due ${daysUntilNextPayment.abs()} days ago'
                      : 'Next payment in $daysUntilNextPayment days',
                  style: TextStyle(
                    fontSize: 12,
                    color: paymentLate ? Colors.red : Colors.grey,
                    fontWeight: paymentLate ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Make payment functionality coming soon!'))
                    );
                  },
                  icon: const Icon(Icons.payment, size: 16),
                  label: const Text('Make Payment'),
                ),
                TextButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('View details functionality coming soon!'))
                    );
                  },
                  child: const Text('View Details'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
} 