import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/data/services/database_service.dart';

class AddTransactionDialog extends StatefulWidget {
  final AccountModel? account;
  
  const AddTransactionDialog({
    Key? key,
    this.account,
  }) : super(key: key);

  @override
  State<AddTransactionDialog> createState() => _AddTransactionDialogState();
}

class _AddTransactionDialogState extends State<AddTransactionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  final _accountRepository = AccountRepository();
  final _categoryRepository = CategoryRepository();
  final _transactionRepository = TransactionRepository();
  
  late TransactionType _transactionType;
  AccountModel? _selectedAccount;
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];
  
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _transactionType = TransactionType.expense;
    _selectedAccount = widget.account;
    _loadAccounts();
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }
  
  void _loadAccounts() {
    setState(() {
      _isLoading = true;
    });
    
    // Load accounts
    _accounts = _accountRepository.getActiveAccounts();
    
    // Load categories
    _categories = _categoryRepository.getAllCategories();
    
    // Set default account
    if (widget.account != null) {
      _selectedAccount = widget.account;
    } else if (_accounts.isNotEmpty) {
      _selectedAccount = _accounts.first;
    }
    
    // Set default category based on transaction type
    _updateSelectedCategoryForType();
    
    setState(() {
      _isLoading = false;
    });
  }
  
  void _updateSelectedCategoryForType() {
    // Filter categories by transaction type
    final filteredCategories = _categories.where((category) {
      switch (_transactionType) {
        case TransactionType.income:
          return category.isIncome;
        case TransactionType.expense:
          return !category.isIncome && !category.isTransfer;
        case TransactionType.transfer:
          return category.isTransfer;
      }
    }).toList();
    
    if (filteredCategories.isNotEmpty) {
      _selectedCategory = filteredCategories.first;
    }
  }
  
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }
  
  Future<void> _selectTime(BuildContext context) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    
    if (picked != null && picked != _selectedTime) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }
  
  Future<void> _saveTransaction() async {
    if (_formKey.currentState!.validate()) {
      // Combine date and time
      final dateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );
      
      // Parse amount
      final amount = double.parse(_amountController.text);
      
      // Create transaction
      final transaction = TransactionModel(
        description: _descriptionController.text,
        amount: amount,
        type: _transactionType,
        categoryId: _selectedCategory!.id,
        accountId: _selectedAccount!.id,
        date: dateTime,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        await _transactionRepository.addTransaction(transaction);
        
        if (mounted) {
          Navigator.pop(context, true);
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error saving transaction: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: ColorConstants.primaryColor,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(24),
                  topRight: Radius.circular(24),
                ),
                boxShadow: [
                  BoxShadow(
                    color: ColorConstants.primaryColor.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Add Transaction',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Transaction Type
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[100],
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey[200]!,
                            width: 1,
                          ),
                        ),
                        child: SegmentedButton<TransactionType>(
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
                          selected: {_transactionType},
                          onSelectionChanged: (Set<TransactionType> selection) {
                            if (selection.isNotEmpty) {
                              setState(() {
                                _transactionType = selection.first;
                                _updateSelectedCategoryForType();
                              });
                            }
                          },
                          style: ButtonStyle(
                            backgroundColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return ColorConstants.primaryColor;
                                }
                                return Colors.transparent;
                              },
                            ),
                            foregroundColor: MaterialStateProperty.resolveWith<Color>(
                              (Set<MaterialState> states) {
                                if (states.contains(MaterialState.selected)) {
                                  return Colors.white;
                                }
                                return Colors.black87;
                              },
                            ),
                            padding: MaterialStateProperty.all(
                              const EdgeInsets.symmetric(vertical: 16),
                            ),
                            shape: MaterialStateProperty.all(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      
                      // Amount Field
                      TextFormField(
                        controller: _amountController,
                        keyboardType: TextInputType.number,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Amount',
                          prefixIcon: Icon(
                            Icons.attach_money,
                            color: ColorConstants.primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: ColorConstants.primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
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
                      const SizedBox(height: 24),
                      
                      // Description Field
                      TextFormField(
                        controller: _descriptionController,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Description',
                          prefixIcon: Icon(
                            Icons.description_outlined,
                            color: ColorConstants.primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: ColorConstants.primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a description';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Account Selection
                      DropdownButtonFormField<String>(
                        value: _accounts.any((a) => a.id == _selectedAccount!.id) ? _selectedAccount!.id : null,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Account',
                          prefixIcon: Icon(
                            Icons.account_balance_wallet,
                            color: ColorConstants.primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: ColorConstants.primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: _accounts.map((account) {
                          return DropdownMenuItem<String>(
                            value: account.id,
                            child: Text(account.name),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedAccount = _accounts.firstWhere((a) => a.id == value);
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select an account';
                          }
                          return null;
                        },
                      ),
                      
                      if (_transactionType == TransactionType.transfer) ...[
                        const SizedBox(height: 24),
                        DropdownButtonFormField<String>(
                          value: _selectedAccount!.id,
                          style: const TextStyle(fontSize: 16),
                          decoration: InputDecoration(
                            labelText: 'To Account',
                            prefixIcon: Icon(
                              Icons.account_balance_wallet,
                              color: ColorConstants.primaryColor,
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(16),
                              borderSide: BorderSide(color: ColorConstants.primaryColor),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                          ),
                          items: _accounts
                              .where((a) => a.id != _selectedAccount!.id)
                              .map((account) {
                            return DropdownMenuItem<String>(
                              value: account.id,
                              child: Text(account.name),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() {
                                _selectedAccount = _accounts.firstWhere((a) => a.id == value);
                              });
                            }
                          },
                          validator: (value) {
                            if (_transactionType == TransactionType.transfer && (value == null || value.isEmpty)) {
                              return 'Please select a destination account';
                            }
                            return null;
                          },
                        ),
                      ],
                      
                      const SizedBox(height: 24),
                      
                      // Category Selection
                      DropdownButtonFormField<String>(
                        value: _categories.any((c) => c.id == _selectedCategory!.id) ? _selectedCategory!.id : null,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Category',
                          prefixIcon: Icon(
                            Icons.category,
                            color: ColorConstants.primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: ColorConstants.primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        items: _categories
                            .where((category) {
                              switch (_transactionType) {
                                case TransactionType.income:
                                  return category.isIncome;
                                case TransactionType.expense:
                                  return !category.isIncome && !category.isTransfer;
                                case TransactionType.transfer:
                                  return category.isTransfer;
                              }
                            })
                            .map((category) {
                              return DropdownMenuItem<String>(
                                value: category.id,
                                child: Text(category.name),
                              );
                            }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = _categories.firstWhere((c) => c.id == value);
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please select a category';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      // Date and Time
                      Row(
                        children: [
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectDate(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Date',
                                  prefixIcon: Icon(
                                    Icons.calendar_today,
                                    color: ColorConstants.primaryColor,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: ColorConstants.primaryColor),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                child: Text(
                                  DateFormat('MMM d, yyyy').format(_selectedDate),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: InkWell(
                              onTap: () => _selectTime(context),
                              child: InputDecorator(
                                decoration: InputDecoration(
                                  labelText: 'Time',
                                  prefixIcon: Icon(
                                    Icons.access_time,
                                    color: ColorConstants.primaryColor,
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: Colors.grey[300]!),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(color: ColorConstants.primaryColor),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                ),
                                child: Text(
                                  _selectedTime.format(context),
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      
                      // Notes Field
                      TextFormField(
                        controller: _notesController,
                        style: const TextStyle(fontSize: 16),
                        decoration: InputDecoration(
                          labelText: 'Notes (Optional)',
                          prefixIcon: Icon(
                            Icons.note_outlined,
                            color: ColorConstants.primaryColor,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: Colors.grey[300]!),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide(color: ColorConstants.primaryColor),
                          ),
                          filled: true,
                          fillColor: Colors.grey[50],
                        ),
                        maxLines: 3,
                      ),
                      const SizedBox(height: 32),
                      
                      // Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () => Navigator.pop(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.grey[200],
                                foregroundColor: Colors.black87,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Cancel',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _saveTransaction,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: ColorConstants.primaryColor,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 16),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                elevation: 2,
                              ),
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                      ),
                                    )
                                  : const Text(
                                      'Save',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
} 