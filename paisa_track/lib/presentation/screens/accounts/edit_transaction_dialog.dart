import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';

class EditTransactionDialog extends StatefulWidget {
  final TransactionModel transaction;
  final AccountModel account;
  
  const EditTransactionDialog({
    super.key,
    required this.transaction,
    required this.account,
  });

  @override
  State<EditTransactionDialog> createState() => _EditTransactionDialogState();
}

class _EditTransactionDialogState extends State<EditTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  late TextEditingController _notesController;
  
  final AccountRepository _accountRepository = AccountRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  
  late List<AccountModel> _accounts;
  late List<CategoryModel> _categories;
  
  late TransactionType _selectedType;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String? _selectedCategoryId;
  late String? _selectedToAccountId;
  
  bool _isLoading = true;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    
    // Initialize controllers with existing transaction data
    _amountController = TextEditingController(text: widget.transaction.amount.toString());
    _descriptionController = TextEditingController(text: widget.transaction.description);
    _notesController = TextEditingController(text: widget.transaction.notes ?? '');
    
    // Set initial values from transaction
    _selectedType = widget.transaction.type;
    _selectedDate = widget.transaction.date;
    _selectedTime = TimeOfDay(
      hour: widget.transaction.date.hour,
      minute: widget.transaction.date.minute,
    );
    _selectedCategoryId = widget.transaction.categoryId;
    _selectedToAccountId = widget.transaction.toAccountId;
    
    _loadData();
  }
  
  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    try {
      // Load all accounts and categories
      final accounts = _accountRepository.getAllAccounts();
      final categories = _categoryRepository.getAllCategories();
      
      setState(() {
        _accounts = accounts;
        _categories = categories;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading data: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
    }
  }
  
  void _updateSelectedType(TransactionType type) {
    setState(() {
      _selectedType = type;
      
      // Update selected category based on transaction type if current category doesn't match type
      final currentCategory = _categories.firstWhere(
        (c) => c.id == _selectedCategoryId,
        orElse: () => CategoryModel(
          id: '', 
          name: '',
          iconName: 'other',
          colorValue: Colors.grey.value,
          isIncome: type == TransactionType.income,
          createdAt: DateTime.now(),
        ),
      );
      
      // If current category type doesn't match new transaction type, update category
      if (currentCategory.isIncome != (type == TransactionType.income)) {
        final filteredCategories = _categories.where(
          (c) => c.isIncome == (type == TransactionType.income)
        ).toList();
        
        _selectedCategoryId = filteredCategories.isNotEmpty ? filteredCategories.first.id : null;
      }
      
      // Clear destination account if not a transfer
      if (type != TransactionType.transfer) {
        _selectedToAccountId = null;
      } else if (_selectedToAccountId == null && _accounts.length > 1) {
        // Select a default destination account different from the source
        for (var account in _accounts) {
          if (account.id != widget.account.id) {
            _selectedToAccountId = account.id;
            break;
          }
        }
      }
    });
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
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
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectTime() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
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
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  TransactionModel _updateTransaction() {
    // Combine date and time
    final dateTime = DateTime(
      _selectedDate.year,
      _selectedDate.month,
      _selectedDate.day,
      _selectedTime.hour,
      _selectedTime.minute,
    );
    
    // Update transaction with new data
    return widget.transaction.copyWith(
      amount: double.parse(_amountController.text),
      description: _descriptionController.text,
      date: dateTime,
      type: _selectedType,
      categoryId: _selectedCategoryId,
      accountId: widget.account.id,
      toAccountId: _selectedType == TransactionType.transfer ? _selectedToAccountId : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );
  }
  
  @override
  Widget build(BuildContext context) {
    final currencySymbol = widget.account.currency.symbol;
    
    if (_isLoading) {
      return const Dialog(
        child: Padding(
          padding: EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading...'),
            ],
          ),
        ),
      );
    }
    
    if (_hasError) {
      return Dialog(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, color: ColorConstants.errorColor, size: 48),
              const SizedBox(height: 16),
              const Text('Error loading data'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close'),
              ),
            ],
          ),
        ),
      );
    }
    
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Dialog header
                Row(
                  children: [
                    const Text(
                      'Edit Transaction',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                      tooltip: 'Close',
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Transaction Type Selector
                const Text(
                  'Transaction Type',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                SegmentedButton<TransactionType>(
                  segments: const [
                    ButtonSegment(
                      value: TransactionType.expense,
                      label: Text('Expense'),
                      icon: Icon(Icons.arrow_downward),
                    ),
                    ButtonSegment(
                      value: TransactionType.income,
                      label: Text('Income'),
                      icon: Icon(Icons.arrow_upward),
                    ),
                    ButtonSegment(
                      value: TransactionType.transfer,
                      label: Text('Transfer'),
                      icon: Icon(Icons.swap_horiz),
                    ),
                  ],
                  selected: {_selectedType},
                  onSelectionChanged: (Set<TransactionType> selection) {
                    if (selection.isNotEmpty) {
                      _updateSelectedType(selection.first);
                    }
                  },
                ),
                const SizedBox(height: 16),
                
                // Amount Field
                TextFormField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount',
                    prefixText: currencySymbol,
                    border: const OutlineInputBorder(),
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    
                    final amount = double.tryParse(value);
                    if (amount == null) {
                      return 'Please enter a valid number';
                    }
                    
                    if (amount <= 0) {
                      return 'Amount must be greater than 0';
                    }
                    
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Description Field
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // Date and Time Pickers
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: _selectDate,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Date',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            DateFormat('MMM d, yyyy').format(_selectedDate),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: InkWell(
                        onTap: _selectTime,
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'Time',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(
                            _selectedTime.format(context),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Category Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                  items: _categories
                      .where((c) => c.isIncome == (_selectedType == TransactionType.income))
                      .map((category) {
                    return DropdownMenuItem<String>(
                      value: category.id,
                      child: Text(category.name),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedCategoryId = value;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                
                // To Account Dropdown (for Transfers only)
                if (_selectedType == TransactionType.transfer)
                  DropdownButtonFormField<String>(
                    value: _selectedToAccountId,
                    decoration: const InputDecoration(
                      labelText: 'To Account',
                      border: OutlineInputBorder(),
                    ),
                    items: _accounts
                        .where((a) => a.id != widget.account.id) // Filter out the current account
                        .map((account) {
                      return DropdownMenuItem<String>(
                        value: account.id,
                        child: Text(account.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedToAccountId = value;
                      });
                    },
                    validator: (value) {
                      if (_selectedType == TransactionType.transfer && (value == null || value.isEmpty)) {
                        return 'Please select a destination account';
                      }
                      return null;
                    },
                  ),
                
                if (_selectedType == TransactionType.transfer)
                  const SizedBox(height: 16),
                
                // Notes Field
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Notes (Optional)',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                
                // Action Buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final updatedTransaction = _updateTransaction();
                          Navigator.of(context).pop(updatedTransaction);
                        }
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
} 