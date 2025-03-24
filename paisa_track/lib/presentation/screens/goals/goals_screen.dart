import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:math' as math;

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  bool _isLoading = false;
  final List<Map<String, dynamic>> _dummyGoals = [];
  
  @override
  void initState() {
    super.initState();
    _createDummyGoals();
  }
  
  void _createDummyGoals() {
    // Sample goals for the placeholder screen
    _dummyGoals.add({
      'id': '1',
      'name': 'New Laptop',
      'targetAmount': 1500.0,
      'currentAmount': 750.0,
      'deadline': DateTime.now().add(const Duration(days: 120)),
      'color': Colors.blue,
      'icon': Icons.laptop_mac,
      'notes': 'Saving for a MacBook Pro for work',
    });
    
    _dummyGoals.add({
      'id': '2',
      'name': 'Summer Vacation',
      'targetAmount': 3000.0,
      'currentAmount': 1200.0,
      'deadline': DateTime.now().add(const Duration(days: 180)),
      'color': Colors.orange,
      'icon': Icons.beach_access,
      'notes': 'Trip to Hawaii in July',
    });
    
    _dummyGoals.add({
      'id': '3',
      'name': 'Emergency Fund',
      'targetAmount': 5000.0,
      'currentAmount': 2500.0,
      'deadline': DateTime.now().add(const Duration(days: 365)),
      'color': Colors.red,
      'icon': Icons.health_and_safety,
      'notes': 'For unexpected expenses',
    });
    
    _dummyGoals.add({
      'id': '4',
      'name': 'New Phone',
      'targetAmount': 800.0,
      'currentAmount': 150.0,
      'deadline': DateTime.now().add(const Duration(days: 90)),
      'color': Colors.green,
      'icon': Icons.smartphone,
      'notes': 'Latest iPhone',
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals'),
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
          : _dummyGoals.isEmpty
              ? _buildEmptyState()
              : _buildGoalsList(),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Add goal functionality coming soon!'))
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
            Icons.flag_outlined,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          const Text(
            'No savings goals yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Set a goal to save for something special',
            style: TextStyle(
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Add goal functionality coming soon!'))
              );
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Goal'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildGoalsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _dummyGoals.length,
      itemBuilder: (context, index) {
        final goal = _dummyGoals[index];
        return _buildGoalCard(goal);
      },
    );
  }
  
  Widget _buildGoalCard(Map<String, dynamic> goal) {
    final currencyFormat = NumberFormat.currency(symbol: '\$');
    final dateFormat = DateFormat('MMM d, yyyy');
    
    final progress = goal['currentAmount'] / goal['targetAmount'];
    final percentComplete = (progress * 100).toStringAsFixed(1);
    final daysLeft = goal['deadline'].difference(DateTime.now()).inDays;
    
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
                  backgroundColor: goal['color'].withOpacity(0.2),
                  child: Icon(
                    goal['icon'],
                    color: goal['color'],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        goal['name'],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        '${currencyFormat.format(goal['currentAmount'])} of ${currencyFormat.format(goal['targetAmount'])}',
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '$percentComplete%',
                    style: const TextStyle(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: Colors.grey[200],
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Deadline: ${dateFormat.format(goal['deadline'])}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
                Text(
                  '$daysLeft days left',
                  style: TextStyle(
                    fontSize: 12,
                    color: daysLeft < 30 ? Colors.orange : Colors.grey,
                    fontWeight: daysLeft < 30 ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ],
            ),
            if (goal['notes'] != null) ...[
              const SizedBox(height: 12),
              Text(
                goal['notes'],
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Add funds functionality coming soon!'))
                    );
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Funds'),
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