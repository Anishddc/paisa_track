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

class AddTransactionScreen extends StatefulWidget {
  final AccountModel? account;
  final TransactionType? initialType;
  
  const AddTransactionScreen({
    Key? key,
    this.account,
    this.initialType,
  }) : super(key: key);

  @override
  State<AddTransactionScreen> createState() => _AddTransactionScreenState();
}

class _AddTransactionScreenState extends State<AddTransactionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _notesController = TextEditingController();
  
  final _accountRepository = AccountRepository();
  final _categoryRepository = CategoryRepository();
  final _transactionRepository = TransactionRepository();
  
  late TransactionType _transactionType;
  AccountModel? _selectedAccount;
  AccountModel? _selectedToAccount;
  CategoryModel? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedTime = TimeOfDay.now();
  
  List<AccountModel> _accounts = [];
  List<CategoryModel> _categories = [];
  
  bool _isLoading = false;
  int _selectedTransactionTypeIndex = 0;

  @override
  void initState() {
    super.initState();
    _transactionType = widget.initialType ?? TransactionType.expense;
    _selectedAccount = widget.account;
    _loadAccounts();
    
    // Set the initial tab index based on the transaction type
    if (widget.initialType == TransactionType.income) {
      _selectedTransactionTypeIndex = 1;
    } else if (widget.initialType == TransactionType.transfer) {
      _selectedTransactionTypeIndex = 2;
    }
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
      
      // If we have more than one account, set the second one as the default "to" account for transfers
      if (_accounts.length > 1) {
        _selectedToAccount = _accounts[1];
      } else {
        _selectedToAccount = _accounts.first;
      }
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
      // Validate transfer accounts
      if (_transactionType == TransactionType.transfer) {
        if (_selectedAccount?.id == _selectedToAccount?.id) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('From and To accounts cannot be the same for transfers'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        
        if (_selectedToAccount == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select a destination account for the transfer'),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
      }
      
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
        destinationAccountId: _transactionType == TransactionType.transfer ? _selectedToAccount?.id : null,
        date: dateTime,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );
      
      setState(() {
        _isLoading = true;
      });
      
      try {
        // Add transaction using repository to trigger stream update
        debugPrint('Adding transaction: ${transaction.description}, amount: ${transaction.amount}');
        await _transactionRepository.addTransaction(transaction);
        
        // Force direct notifications on repositories
        _transactionRepository.notifyListeners();
        
        // Also update the account to ensure its listeners are triggered
        if (_selectedAccount != null) {
          _accountRepository.notifyListeners();
        }
        
        debugPrint('Transaction added successfully and notifications sent!');
        
        if (mounted) {
          // Return true to indicate success and that listeners should refresh
          Navigator.pop(context, true);
        }
      } catch (e) {
        debugPrint('Error saving transaction: $e');
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
    return Scaffold(
      backgroundColor: const Color(0xFFFAF9F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'Add transaction',
          style: TextStyle(
            color: Colors.black87,
            fontSize: 24,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black87),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading && _accounts.isEmpty 
        ? const Center(child: CircularProgressIndicator())
        : Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Transaction Type
                Container(
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(32),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        _buildTransactionTypeButton('Expense', 0, Icons.arrow_downward),
                        _buildTransactionTypeButton('Income', 1, Icons.arrow_upward),
                        _buildTransactionTypeButton('Transfer', 2, Icons.swap_horiz),
                      ],
                    ),
                  ),
                ),
                
                // Expense name / Description
                _buildTextField(
                  controller: _descriptionController,
                  label: _transactionType == TransactionType.expense 
                    ? 'Expense name' 
                    : _transactionType == TransactionType.income
                      ? 'Income name'
                      : 'Transfer name',
                  icon: Icons.description_outlined,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Amount
                _buildTextField(
                  controller: _amountController,
                  label: 'Amount',
                  icon: Icons.attach_money,
                  keyboardType: TextInputType.number,
                  suffixIcon: Icons.calculate,
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
                
                const SizedBox(height: 16),
                
                // Description for transfers
                if (_transactionType == TransactionType.transfer)
                  _buildTextField(
                    controller: _notesController,
                    label: 'Notes (Optional)',
                    icon: Icons.note_outlined,
                  ),
                  
                const SizedBox(height: 24),
                
                // Date & Time section
                const Text(
                  'Date & time',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Date and Time row
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectDate(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.calendar_today, color: ColorConstants.primaryColor),
                              const SizedBox(width: 12),
                              Text(
                                DateFormat('MM/dd/yyyy').format(_selectedDate),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: InkWell(
                        onTap: () => _selectTime(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.access_time, color: ColorConstants.primaryColor),
                              const SizedBox(width: 12),
                              Text(
                                _selectedTime.format(context),
                                style: const TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 24),
                
                // Account Selection section for transfers
                if (_transactionType == TransactionType.transfer) ...[
                  _buildSectionTitle('From Account'),
                  
                  const SizedBox(height: 12),
                  
                  // From Account Selection
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _accounts.length,
                      itemBuilder: (context, index) {
                        final account = _accounts[index];
                        final isSelected = _selectedAccount?.id == account.id;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedAccount = account;
                              // If to account is same as from account, select different account
                              if (_selectedToAccount?.id == account.id && _accounts.length > 1) {
                                // Find a different account to set as to account
                                _selectedToAccount = _accounts.firstWhere(
                                  (a) => a.id != account.id,
                                  orElse: () => _accounts.first,
                                );
                              }
                            });
                          },
                          child: Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Color(0xFFECF3FE) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? ColorConstants.primaryColor : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: account.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: account.bankLogoPath != null && account.bankLogoPath!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.asset(
                                          account.bankLogoPath!,
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('Error loading bank logo: ${account.bankLogoPath}, error: $error');
                                            return Icon(
                                              account.icon,
                                              color: account.color,
                                              size: 20,
                                            );
                                          },
                                        ),
                                      )
                                    : Icon(
                                        account.icon,
                                        color: account.color,
                                        size: 20,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  account.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Transfer visualization
                  if (_selectedAccount != null)
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'From',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: _selectedAccount!.color.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: _selectedAccount!.bankLogoPath != null && _selectedAccount!.bankLogoPath!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.asset(
                                              _selectedAccount!.bankLogoPath!,
                                              width: 14,
                                              height: 14,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  _selectedAccount!.icon,
                                                  color: _selectedAccount!.color,
                                                  size: 14,
                                                );
                                              },
                                            ),
                                          )
                                        : Icon(
                                            _selectedAccount!.icon,
                                            color: _selectedAccount!.color,
                                            size: 14,
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _selectedAccount!.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.arrow_forward,
                                  color: ColorConstants.primaryColor,
                                  size: 24,
                                ),
                                if (_amountController.text.isNotEmpty)
                                  Text(
                                    _amountController.text,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: ColorConstants.primaryColor,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'To',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.normal,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                _selectedToAccount != null ? Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(4),
                                      decoration: BoxDecoration(
                                        color: _selectedToAccount!.color.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(4),
                                      ),
                                      child: _selectedToAccount!.bankLogoPath != null && _selectedToAccount!.bankLogoPath!.isNotEmpty
                                        ? ClipOval(
                                            child: Image.asset(
                                              _selectedToAccount!.bankLogoPath!,
                                              width: 14,
                                              height: 14,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) {
                                                return Icon(
                                                  _selectedToAccount!.icon,
                                                  color: _selectedToAccount!.color,
                                                  size: 14,
                                                );
                                              },
                                            ),
                                          )
                                        : Icon(
                                            _selectedToAccount!.icon,
                                            color: _selectedToAccount!.color,
                                            size: 14,
                                          ),
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        _selectedToAccount!.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ) : Text(
                                  'Select destination',
                                  style: TextStyle(
                                    fontWeight: FontWeight.normal,
                                    fontSize: 14,
                                    color: Colors.grey.shade500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                  const SizedBox(height: 24),
                  
                  // To Account Selection
                  Row(
                    children: [
                      Expanded(
                        child: _buildSectionTitle('To Account'),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: ColorConstants.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.arrow_downward,
                          color: ColorConstants.primaryColor,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: _accounts.length,
                      itemBuilder: (context, index) {
                        final account = _accounts[index];
                        // Skip the selected "from" account to avoid selecting same account
                        if (_selectedAccount?.id == account.id && _accounts.length > 1) {
                          return const SizedBox.shrink();
                        }
                        
                        final isSelected = _selectedToAccount?.id == account.id;
                        
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _selectedToAccount = account;
                            });
                          },
                          child: Container(
                            width: 160,
                            margin: const EdgeInsets.only(right: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? Color(0xFFECF3FE) : Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected ? ColorConstants.primaryColor : Colors.grey.shade200,
                                width: isSelected ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: account.color.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: account.bankLogoPath != null && account.bankLogoPath!.isNotEmpty
                                    ? ClipOval(
                                        child: Image.asset(
                                          account.bankLogoPath!,
                                          width: 20,
                                          height: 20,
                                          fit: BoxFit.cover,
                                          errorBuilder: (context, error, stackTrace) {
                                            print('Error loading bank logo: ${account.bankLogoPath}, error: $error');
                                            return Icon(
                                              account.icon,
                                              color: account.color,
                                              size: 20,
                                            );
                                          },
                                        ),
                                      )
                                    : Icon(
                                        account.icon,
                                        color: account.color,
                                        size: 20,
                                      ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  account.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 16,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ] else ...[
                  // Regular Account Selection for non-transfer transactions
                  _buildSectionTitle('Select account'),
                  
                  const SizedBox(height: 12),
                  
                  if (_accounts.isNotEmpty) ...[
                    SizedBox(
                      height: 100,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _accounts.length,
                        itemBuilder: (context, index) {
                          final account = _accounts[index];
                          final isSelected = _selectedAccount?.id == account.id;
                          
                          return GestureDetector(
                            onTap: () {
                              setState(() {
                                _selectedAccount = account;
                              });
                            },
                            child: Container(
                              width: 160,
                              margin: const EdgeInsets.only(right: 12),
                              decoration: BoxDecoration(
                                color: isSelected ? Color(0xFFECF3FE) : Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: isSelected ? ColorConstants.primaryColor : Colors.grey.shade200,
                                  width: isSelected ? 2 : 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.05),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: account.color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: account.bankLogoPath != null && account.bankLogoPath!.isNotEmpty
                                      ? ClipOval(
                                          child: Image.asset(
                                            account.bankLogoPath!,
                                            width: 20,
                                            height: 20,
                                            fit: BoxFit.cover,
                                            errorBuilder: (context, error, stackTrace) {
                                              print('Error loading bank logo: ${account.bankLogoPath}, error: $error');
                                              return Icon(
                                                account.icon,
                                                color: account.color,
                                                size: 20,
                                              );
                                            },
                                          ),
                                        )
                                      : Icon(
                                          account.icon,
                                          color: account.color,
                                          size: 20,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    account.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ] else ...[
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text('No accounts available. Please add an account first.'),
                      ),
                    ),
                  ],
                ],
                
                const SizedBox(height: 24),
                
                // Category Selection
                _buildSectionTitle('Category'),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButtonFormField<String>(
                      value: _categories.any((c) => c.id == _selectedCategory?.id) ? _selectedCategory!.id : null,
                      decoration: const InputDecoration.collapsed(
                        hintText: 'Select category',
                      ),
                      icon: const Icon(Icons.arrow_drop_down),
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
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: category.color.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      category.icon,
                                      color: category.color,
                                      size: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(category.name),
                                ],
                              ),
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
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 16,
                      ),
                      isExpanded: true,
                    ),
                  ),
                ),
                
                const SizedBox(height: 32),
              ],
            ),
          ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: ElevatedButton(
            onPressed: _isLoading ? null : _saveTransaction,
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              elevation: 0,
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.add),
                      SizedBox(width: 8),
                      Text(
                        'Add',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTransactionTypeButton(String title, int index, IconData icon) {
    final isSelected = _selectedTransactionTypeIndex == index;
    
    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTransactionTypeIndex = index;
            _transactionType = index == 0 
                ? TransactionType.expense 
                : index == 1 
                  ? TransactionType.income 
                  : TransactionType.transfer;
            _updateSelectedCategoryForType();
          });
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? ColorConstants.primaryColor.withOpacity(0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              Icon(
                icon,
                size: 20,
                color: isSelected ? ColorConstants.primaryColor : Colors.grey,
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: isSelected ? ColorConstants.primaryColor : Colors.grey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    IconData? suffixIcon,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(fontSize: 16),
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: Icon(icon, color: ColorConstants.primaryColor),
          suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.grey) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16, 
            vertical: 16,
          ),
        ),
        validator: validator,
      ),
    );
  }
  
  Widget _buildSectionTitle(String title) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (title == 'Select account') 
          IconButton(
            icon: const Icon(Icons.add, size: 20),
            onPressed: () {
              // Add account logic here
            },
          ),
      ],
    );
  }
} 