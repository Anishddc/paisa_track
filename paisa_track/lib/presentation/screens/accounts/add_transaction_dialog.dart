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
import 'package:paisa_track/data/repositories/transaction_repository.dart';

class AddTransactionDialog extends StatefulWidget {
  final AccountModel account;
  final TransactionType? initialType;
  
  const AddTransactionDialog({
    super.key,
    required this.account,
    this.initialType,
  });

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  final AccountRepository _accountRepository = AccountRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();
  
  late List<AccountModel> _accounts;
  late List<CategoryModel> _categories;
  
  late TransactionType _selectedType;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  String? _selectedCategoryId;
  String? _selectedToAccountId;
  
  bool _isLoading = true;
  bool _hasError = false;
  
  @override
  void initState() {
    super.initState();
    // Set the initial transaction type (use the provided one or default to expense)
    _selectedType = widget.initialType ?? TransactionType.expense;
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
      
      // Select appropriate default category based on transaction type
      final defaultCategories = categories.where(
        (c) => c.isIncome == (_selectedType == TransactionType.income)
      ).toList();
      
      setState(() {
        _accounts = accounts;
        _categories = categories;
        _selectedCategoryId = defaultCategories.isNotEmpty ? defaultCategories.first.id : null;
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
      
      // Update selected category based on transaction type
      final filteredCategories = _categories.where(
        (c) => c.isIncome == (type == TransactionType.income)
      ).toList();
      
      _selectedCategoryId = filteredCategories.isNotEmpty ? filteredCategories.first.id : null;
      
      // Clear destination account if not a transfer
      if (type != TransactionType.transfer) {
        _selectedToAccountId = null;
      }
    });
  }
  
  Future<void> _selectDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: ColorConstants.primaryColor,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = DateTime(
          picked.year,
          picked.month,
          picked.day,
          _selectedTime.hour,
          _selectedTime.minute,
        );
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
              surface: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
        _selectedDate = DateTime(
          _selectedDate.year,
          _selectedDate.month,
          _selectedDate.day,
          picked.hour,
          picked.minute,
        );
      });
    }
  }
  
  Future<void> _saveTransaction() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    
    try {
      final amount = double.parse(_amountController.text);
      final description = _descriptionController.text;
      final notes = _notesController.text.isEmpty ? null : _notesController.text;
      
      if (_selectedCategoryId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select a category'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
        return;
      }
      
      final transaction = TransactionModel(
        description: description,
        amount: amount,
        type: _selectedType,
        categoryId: _selectedCategoryId!,
        accountId: widget.account.id,
        date: _selectedDate,
        notes: notes,
        destinationAccountId: _selectedToAccountId,
      );
      
      // Add transaction - this will trigger stream notifications
      debugPrint('Dialog: Adding transaction: $description, amount: $amount');
      await _transactionRepository.addTransaction(transaction);
      
      // Force a direct notification
      _transactionRepository.notifyListeners();
      
      // Also update the account balance to trigger that listener
      final account = _accountRepository.getAccountById(widget.account.id);
      if (account != null) {
        await _accountRepository.updateAccount(account);
        
        // Force a direct notification for accounts
        _accountRepository.notifyListeners();
      }
      
      debugPrint('Dialog: Transaction added successfully and notifications sent!');
      
      if (mounted) {
        // Return true to indicate success
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      debugPrint('Dialog: Error saving transaction: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving transaction: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  Color _getColorForType(TransactionType type) {
    switch (type) {
      case TransactionType.expense:
        return Colors.red.shade600;
      case TransactionType.income:
        return Colors.green.shade600;
      case TransactionType.transfer:
        return Colors.blue.shade600;
      default:
        return ColorConstants.primaryColor;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: const Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Loading data...'),
            ],
          ),
        ),
      );
    }
    
    if (_hasError) {
      return Dialog(
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: ColorConstants.errorColor),
              const SizedBox(height: 16),
              const Text('Error loading data', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadData,
                style: ElevatedButton.styleFrom(
                  backgroundColor: ColorConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final typeColor = _getColorForType(_selectedType);
    
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header with title and close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Add Transaction',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: ColorConstants.primaryColor,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Transaction Type Selector
                  Center(
                    child: SegmentedButton<TransactionType>(
                      style: ButtonStyle(
                        backgroundColor: MaterialStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(MaterialState.selected)) {
                              return typeColor.withOpacity(0.1);
                            }
                            return Colors.transparent;
                          },
                        ),
                        foregroundColor: MaterialStateProperty.resolveWith<Color>(
                          (states) {
                            if (states.contains(MaterialState.selected)) {
                              return typeColor;
                            }
                            return Colors.grey;
                          },
                        ),
                      ),
                      segments: const [
                        ButtonSegment(
                          value: TransactionType.expense,
                          label: Text('Expense', style: TextStyle(fontSize: 13)),
                          icon: Icon(Icons.arrow_downward, size: 18),
                        ),
                        ButtonSegment(
                          value: TransactionType.income,
                          label: Text('Income', style: TextStyle(fontSize: 13)),
                          icon: Icon(Icons.arrow_upward, size: 18),
                        ),
                        ButtonSegment(
                          value: TransactionType.transfer,
                          label: Text('Transfer', style: TextStyle(fontSize: 13)),
                          icon: Icon(Icons.swap_horiz, size: 18),
                        ),
                      ],
                      selected: {_selectedType},
                      onSelectionChanged: (Set<TransactionType> newSelection) {
                        _updateSelectedType(newSelection.first);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Amount
                  Container(
                    decoration: BoxDecoration(
                      color: typeColor.withOpacity(0.05),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: TextFormField(
                      controller: _amountController,
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: typeColor,
                      ),
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        labelStyle: TextStyle(color: typeColor.withOpacity(0.8)),
                        prefixText: '${widget.account.currency.symbol} ',
                        prefixStyle: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: typeColor,
                        ),
                        border: InputBorder.none,
                        floatingLabelBehavior: FloatingLabelBehavior.auto,
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter an amount';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Please enter a valid number';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Description
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Description',
                      prefixIcon: const Icon(Icons.description_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter a description';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Category with icons
                  DropdownButtonFormField<String>(
                    value: _selectedCategoryId,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Category',
                      prefixIcon: const Icon(Icons.category_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    items: _categories
                        .where((c) => c.isIncome == (_selectedType == TransactionType.income))
                        .map((category) => DropdownMenuItem(
                              value: category.id,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    category.icon,
                                    color: category.color,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      category.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              ),
                            ))
                        .toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedCategoryId = value;
                      });
                    },
                    validator: (value) {
                      if (value == null) {
                        return 'Please select a category';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  
                  // Date and Time Row
                  Row(
                    children: [
                      Expanded(
                        child: InkWell(
                          onTap: _selectDate,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.calendar_today, color: ColorConstants.primaryColor, size: 16),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    DateFormat('MMM dd, yyyy').format(_selectedDate),
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: InkWell(
                          onTap: _selectTime,
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 15),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.access_time, color: ColorConstants.primaryColor, size: 16),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    _selectedTime.format(context),
                                    style: const TextStyle(fontSize: 13),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Destination Account (for transfers) with account logos
                  if (_selectedType == TransactionType.transfer)
                    DropdownButtonFormField<String>(
                      value: _selectedToAccountId,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'To Account',
                        prefixIcon: const Icon(Icons.account_balance_outlined),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _accounts
                          .where((a) => a.id != widget.account.id)
                          .map((account) => DropdownMenuItem(
                                value: account.id,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    account.bankLogoPath != null && account.bankLogoPath!.isNotEmpty
                                      ? ClipOval(
                                          child: Image.asset(
                                            account.bankLogoPath!,
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              debugPrint('Error loading bank logo: $error');
                                              return Icon(Icons.account_balance, size: 20, color: ColorConstants.primaryColor);
                                            },
                                          ),
                                        )
                                      : Icon(Icons.account_balance, size: 20, color: ColorConstants.primaryColor),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        account.name,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedToAccountId = value;
                        });
                      },
                      validator: (value) {
                        if (_selectedType == TransactionType.transfer && value == null) {
                          return 'Please select a destination account';
                        }
                        return null;
                      },
                    ),
                  if (_selectedType == TransactionType.transfer)
                    const SizedBox(height: 16),
                  
                  // Notes
                  TextFormField(
                    controller: _notesController,
                    decoration: InputDecoration(
                      labelText: 'Notes (optional)',
                      prefixIcon: const Icon(Icons.note_outlined),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      alignLabelWithHint: true,
                    ),
                    maxLines: 2,
                    maxLength: 200,
                    buildCounter: (context, {required currentLength, required isFocused, maxLength}) => null,
                  ),
                  const SizedBox(height: 16),
                  
                  // Buttons Row
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveTransaction,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: typeColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 