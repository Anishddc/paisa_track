import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';

class TransactionFilterDialog extends StatefulWidget {
  final DateTime initialStartDate;
  final DateTime initialEndDate;
  final TransactionType? initialTransactionType;
  final String? initialCategoryId;
  final List<CategoryModel> categories;
  
  const TransactionFilterDialog({
    super.key,
    required this.initialStartDate,
    required this.initialEndDate,
    this.initialTransactionType,
    this.initialCategoryId,
    required this.categories,
  });

  @override
  State<TransactionFilterDialog> createState() => _TransactionFilterDialogState();
}

class _TransactionFilterDialogState extends State<TransactionFilterDialog> {
  late DateTime _startDate;
  late DateTime _endDate;
  late TransactionType? _transactionType;
  late String? _categoryId;
  
  @override
  void initState() {
    super.initState();
    _startDate = widget.initialStartDate;
    _endDate = widget.initialEndDate;
    _transactionType = widget.initialTransactionType;
    _categoryId = widget.initialCategoryId;
  }
  
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }
  
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorConstants.primaryColor,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }
  
  void _selectPresetDateRange(String preset) {
    final now = DateTime.now();
    
    switch (preset) {
      case 'today':
        setState(() {
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = DateTime(now.year, now.month, now.day, 23, 59, 59);
        });
        break;
      case 'yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        setState(() {
          _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          _endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        });
        break;
      case 'this_week':
        // Get the start of the week (Sunday or Monday depending on locale)
        final weekDay = now.weekday;
        final startOfWeek = now.subtract(Duration(days: weekDay - 1));
        setState(() {
          _startDate = DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day);
          _endDate = now;
        });
        break;
      case 'this_month':
        setState(() {
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
        });
        break;
      case 'last_month':
        final lastMonth = DateTime(now.year, now.month - 1);
        setState(() {
          _startDate = DateTime(lastMonth.year, lastMonth.month, 1);
          _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        });
        break;
      case 'last_3_months':
        final threeMonthsAgo = DateTime(now.year, now.month - 3);
        setState(() {
          _startDate = DateTime(threeMonthsAgo.year, threeMonthsAgo.month, 1);
          _endDate = now;
        });
        break;
      case 'this_year':
        setState(() {
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
        });
        break;
      case 'all_time':
        setState(() {
          _startDate = DateTime(2020, 1, 1);
          _endDate = now;
        });
        break;
    }
  }
  
  Map<String, dynamic> _getFilterResult() {
    return {
      'startDate': _startDate,
      'endDate': _endDate,
      'transactionType': _transactionType,
      'categoryId': _categoryId,
    };
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Filter Transactions'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Section
            const Text(
              'Date Range',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            // Date Picker Row
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _selectStartDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        DateFormat('MMM d, yyyy').format(_startDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: InkWell(
                    onTap: _selectEndDate,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      child: Text(
                        DateFormat('MMM d, yyyy').format(_endDate),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Quick Date Selections
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildDateChip('Today', 'today'),
                _buildDateChip('This Week', 'this_week'),
                _buildDateChip('This Month', 'this_month'),
                _buildDateChip('Last Month', 'last_month'),
                _buildDateChip('This Year', 'this_year'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Transaction Type Section
            const Text(
              'Transaction Type',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            // Transaction Type Selection
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _buildTransactionTypeChip(null, 'All'),
                _buildTransactionTypeChip(TransactionType.income, 'Income'),
                _buildTransactionTypeChip(TransactionType.expense, 'Expense'),
                _buildTransactionTypeChip(TransactionType.transfer, 'Transfer'),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Category Section
            const Text(
              'Category',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 8),
            
            // Category Dropdown
            DropdownButtonFormField<String?>(
              value: _categoryId,
              decoration: const InputDecoration(
                labelText: 'Select Category',
                border: OutlineInputBorder(),
              ),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Categories'),
                ),
                ...widget.categories.map((category) {
                  return DropdownMenuItem<String?>(
                    value: category.id,
                    child: Text(category.name),
                  );
                }).toList(),
              ],
              onChanged: (value) {
                setState(() {
                  _categoryId = value;
                });
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop(_getFilterResult());
          },
          child: const Text('Apply'),
        ),
      ],
    );
  }
  
  Widget _buildDateChip(String label, String preset) {
    return ActionChip(
      label: Text(label),
      backgroundColor: Colors.grey[200],
      onPressed: () => _selectPresetDateRange(preset),
    );
  }
  
  Widget _buildTransactionTypeChip(TransactionType? type, String label) {
    final isSelected = _transactionType == type;
    Color? chipColor;
    
    if (isSelected) {
      if (type == TransactionType.income) {
        chipColor = ColorConstants.successColor.withOpacity(0.2);
      } else if (type == TransactionType.expense) {
        chipColor = ColorConstants.errorColor.withOpacity(0.2);
      } else if (type == TransactionType.transfer) {
        chipColor = ColorConstants.infoColor.withOpacity(0.2);
      } else {
        chipColor = ColorConstants.primaryColor.withOpacity(0.2);
      }
    }
    
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      checkmarkColor: type == null 
        ? ColorConstants.primaryColor
        : type == TransactionType.income
            ? ColorConstants.successColor
            : type == TransactionType.expense
                ? ColorConstants.errorColor
                : ColorConstants.infoColor,
      selectedColor: chipColor,
      onSelected: (selected) {
        setState(() {
          _transactionType = selected ? type : null;
        });
      },
    );
  }
} 