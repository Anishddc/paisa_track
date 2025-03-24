import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:paisa_track/core/utils/date_utils.dart' as app_date_utils;
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/enums/account_type.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/presentation/screens/accounts/edit_account_dialog.dart';
import 'package:hive/hive.dart';
import 'package:get_it/get_it.dart';
import 'transaction_filter_dialog.dart';
import 'add_transaction_dialog.dart';
import 'edit_transaction_dialog.dart';
import 'package:paisa_track/data/models/app_icon.dart';

class AccountDetailsScreen extends StatefulWidget {
  final AccountModel account;
  
  const AccountDetailsScreen({
    super.key,
    required this.account,
  });

  @override
  State<AccountDetailsScreen> createState() => _AccountDetailsScreenState();
}

class _AccountDetailsScreenState extends State<AccountDetailsScreen> with SingleTickerProviderStateMixin {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final AccountRepository _accountRepository = AccountRepository();
  
  late TabController _tabController;
  late AccountModel _account;
  
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _recentTransactions = [];
  Map<String, CategoryModel> _categoriesMap = {};
  Map<String, AccountModel> _accountsMap = {};
  
  bool _isLoading = true;
  
  // For transaction filtering
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  TransactionType? _selectedTransactionType;
  String? _selectedCategoryId;
  List<CategoryModel> _categories = [];
  List<TransactionModel> _filteredTransactions = [];
  bool _isFilterActive = false;
  
  @override
  void initState() {
    super.initState();
    _account = widget.account;
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Refresh account data
      final freshAccount = _accountRepository.getAccountById(_account.id);
      if (freshAccount != null) {
        _account = freshAccount;
      }
      
      // Load transactions for this account
      final transactions = _transactionRepository.getTransactionsByAccount(_account.id);
      transactions.sort((a, b) => b.date.compareTo(a.date)); // Newest first
      
      // Get all categories to display category names
      final categories = _categoryRepository.getAllCategories();
      final categoriesMap = {for (var c in categories) c.id: c};
      
      // Get all accounts to display account names (for transfers)
      final accounts = _accountRepository.getAllAccounts();
      final accountsMap = {for (var a in accounts) a.id: a};
      
      final recentTransactions = transactions.take(5).toList();
      
      // Load categories for filtering
      final categoryBox = await Hive.openBox<CategoryModel>('categories');
      _categories = categoryBox.values.toList();
      
      // Load and filter transactions
      await _loadTransactions();
      
      setState(() {
        _allTransactions = transactions;
        _recentTransactions = recentTransactions;
        _categoriesMap = categoriesMap;
        _accountsMap = accountsMap;
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading account details: $e');
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading details: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }
  
  Future<void> _loadTransactions() async {
    try {
      // Use the existing repository
      _allTransactions = _transactionRepository.getTransactionsByAccount(_account.id);
      
      // Apply filters if active
      _applyFilters();
      
      // Print debugging information
      print('Loaded ${_allTransactions.length} transactions for account ${_account.name}');
      print('After filtering: ${_filteredTransactions.length} transactions match criteria');
      
    } catch (e) {
      print('Error loading transactions: $e');
    }
  }
  
  void _applyFilters() {
    if (_allTransactions.isEmpty) {
      _filteredTransactions = [];
      return;
    }

    _filteredTransactions = _allTransactions.where((transaction) {
      // Date filter
      final transactionDate = transaction.date;
      final isAfterStart = transactionDate.isAfter(_startDate) || 
                           transactionDate.isAtSameMomentAs(_startDate);
      final isBeforeEnd = transactionDate.isBefore(_endDate) || 
                          transactionDate.isAtSameMomentAs(_endDate);
      
      if (!isAfterStart || !isBeforeEnd) {
        return false;
      }
      
      // Transaction type filter
      if (_selectedTransactionType != null && 
          transaction.type != _selectedTransactionType) {
        return false;
      }
      
      // Category filter
      if (_selectedCategoryId != null && 
          transaction.categoryId != _selectedCategoryId) {
        return false;
      }
      
      return true;
    }).toList();
    
    // Sort by date (most recent first)
    _filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
    
    // Update filter active status
    _isFilterActive = _selectedTransactionType != null || 
                      _selectedCategoryId != null || 
                      !_startDate.isAtSameMomentAs(DateTime.now().subtract(const Duration(days: 30))) ||
                      !_endDate.isAtSameMomentAs(DateTime.now());
  }
  
  Future<void> _showEditAccountDialog() async {
    final updatedAccount = await showDialog<AccountModel>(
      context: context,
      builder: (BuildContext context) {
        return EditAccountDialog(
          account: _account,
        );
      },
    );
    
    if (updatedAccount != null) {
      try {
        await _accountRepository.updateAccount(updatedAccount);
        
        setState(() {
          _account = updatedAccount;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account updated successfully'),
            backgroundColor: ColorConstants.successColor,
          ),
        );
        
        // Refresh data to update any related information
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating account: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }
  
  Future<void> _showAddTransactionDialog({TransactionType? initialType}) async {
    final transaction = await showDialog<TransactionModel>(
      context: context,
      builder: (BuildContext context) {
        return AddTransactionDialog(
          account: _account,
          initialType: initialType,
        );
      },
    );
    
    if (transaction != null) {
      // Refresh data to update transactions and account balance
      _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction added successfully'),
          backgroundColor: ColorConstants.successColor,
        ),
      );
    }
  }
  
  Future<void> _showFilterDialog() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => TransactionFilterDialog(
        initialStartDate: _startDate,
        initialEndDate: _endDate,
        initialTransactionType: _selectedTransactionType,
        initialCategoryId: _selectedCategoryId,
        categories: _categories,
      ),
    );
    
    if (result != null) {
      setState(() {
        _startDate = result['startDate'] as DateTime;
        _endDate = result['endDate'] as DateTime;
        _selectedTransactionType = result['transactionType'] as TransactionType?;
        _selectedCategoryId = result['categoryId'] as String?;
        
        _applyFilters();
      });
    }
  }
  
  void _clearFilters() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
      _selectedTransactionType = null;
      _selectedCategoryId = null;
      _isFilterActive = false;
      
      _applyFilters();
    });
  }

  @override
  Widget build(BuildContext context) {
    final currencySymbol = _account.currency.symbol;
    
    return Scaffold(
      appBar: AppBar(
        title: Text(_account.name),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showEditAccountDialog,
            tooltip: 'Edit Account',
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: _showDeleteAccountConfirmation,
            tooltip: 'Delete Account',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview'),
            Tab(text: 'Transactions'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                // Overview Tab
                _buildOverviewTab(currencySymbol),
                
                // Transactions Tab
                _buildTransactionsTab(currencySymbol),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddTransactionDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Add Transaction',
      ),
    );
  }
  
  Widget _buildOverviewTab(String currencySymbol) {
    // Calculate income, expense, and balance for this month
    final now = DateTime.now();
    final startOfMonth = app_date_utils.DateUtils.getStartOfMonth(now);
    final endOfMonth = app_date_utils.DateUtils.getEndOfMonth(now);
    
    double monthlyIncome = 0;
    double monthlyExpense = 0;
    
    for (final tx in _allTransactions) {
      if ((tx.date.isAfter(startOfMonth) || tx.date.isAtSameMomentAs(startOfMonth)) &&
          (tx.date.isBefore(endOfMonth) || tx.date.isAtSameMomentAs(endOfMonth))) {
        if (tx.type == TransactionType.income) {
          monthlyIncome += tx.amount;
        } else if (tx.type == TransactionType.expense) {
          monthlyExpense += tx.amount;
        }
      }
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Account card
          _buildAccountCard(currencySymbol),
          const SizedBox(height: 16),
          
          // Quick action buttons
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildQuickActionButton(
                    icon: Icons.arrow_upward,
                    label: 'Income',
                    color: ColorConstants.successColor,
                    onTap: () => _showAddTransactionDialog(initialType: TransactionType.income),
                  ),
                  _buildQuickActionButton(
                    icon: Icons.arrow_downward,
                    label: 'Expense',
                    color: ColorConstants.errorColor,
                    onTap: () => _showAddTransactionDialog(initialType: TransactionType.expense),
                  ),
                  _buildQuickActionButton(
                    icon: Icons.swap_horiz,
                    label: 'Transfer',
                    color: ColorConstants.infoColor,
                    onTap: () => _showAddTransactionDialog(initialType: TransactionType.transfer),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          
          // Monthly statistics
          _buildMonthlyStatistics(currencySymbol, monthlyIncome, monthlyExpense),
          const SizedBox(height: 24),
          
          // Recent transactions
          _buildRecentTransactionsSection(currencySymbol),
        ],
      ),
    );
  }
  
  Widget _buildAccountCard(String currencySymbol) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _account.bankLogoPath != null && _account.bankLogoPath!.isNotEmpty
                  ? Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _account.color.withOpacity(0.1),
                      ),
                      padding: const EdgeInsets.all(4),
                      child: ClipOval(
                        child: Image.asset(
                          _account.bankLogoPath!,
                          width: 28,
                          height: 28,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return ClipOval(
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                width: 28,
                                height: 28,
                                fit: BoxFit.cover,
                              ),
                            );
                          },
                        ),
                      ),
                    )
                  : ClipOval(
                      child: Image.asset(
                        'assets/images/app_icon.png',
                        width: 28,
                        height: 28,
                        fit: BoxFit.cover,
                      ),
                    ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _account.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _account.type.name,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Current Balance',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$currencySymbol${_account.balance.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: _account.balance >= 0 ? ColorConstants.successColor : ColorConstants.errorColor,
              ),
            ),
            
            // Account details for bank or digital wallet
            if (_account.type == AccountType.bank || _account.type == AccountType.digitalWallet) ...[
              const SizedBox(height: 16),
              Text(
                _account.type == AccountType.bank ? 'Bank Details' : 'Wallet Details',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              if (_account.bankName != null && _account.bankName!.isNotEmpty)
                _buildDetailRow(
                  _account.type == AccountType.bank ? 'Bank' : 'Wallet', 
                  _account.bankName!,
                ),
              if (_account.accountHolderName != null && _account.accountHolderName!.isNotEmpty)
                _buildDetailRow(
                  _account.type == AccountType.bank ? 'Account Holder' : 'Owner', 
                  _account.accountHolderName!,
                ),
              if (_account.accountNumber != null && _account.accountNumber!.isNotEmpty)
                _buildDetailRow(
                  _account.type == AccountType.bank ? 'Account Number' : 'Mobile Number', 
                  _account.type == AccountType.bank 
                      ? '••••${_account.accountNumber!.substring(math.max(0, _account.accountNumber!.length - 4))}' 
                      : _account.accountNumber!,
                ),
            ],
            
            if (_account.description != null && _account.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Notes',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 4),
              Text(_account.description!),
            ],
          ],
        ),
      ),
    );
  }
  
  Widget _buildMonthlyStatistics(String currencySymbol, double income, double expense) {
    final monthYearFormat = DateFormat('MMMM yyyy');
    final currentMonth = monthYearFormat.format(DateTime.now());
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics for $currentMonth',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatItem(
                  'Income',
                  '$currencySymbol${income.toStringAsFixed(2)}',
                  Icons.arrow_upward,
                  ColorConstants.successColor,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey[300],
                ),
                _buildStatItem(
                  'Expense',
                  '$currencySymbol${expense.toStringAsFixed(2)}',
                  Icons.arrow_downward,
                  ColorConstants.errorColor,
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.grey[300],
                ),
                _buildStatItem(
                  'Net',
                  '$currencySymbol${(income - expense).toStringAsFixed(2)}',
                  income - expense >= 0 ? Icons.trending_up : Icons.trending_down,
                  income - expense >= 0 ? ColorConstants.successColor : ColorConstants.errorColor,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  
  Widget _buildStatItem(String label, String value, IconData icon, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Icon(
          icon,
          color: color,
          size: 16,
        ),
      ],
    );
  }
  
  Widget _buildRecentTransactionsSection(String currencySymbol) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton(
              onPressed: () {
                _tabController.animateTo(1); // Switch to transactions tab
              },
              child: const Text('See All'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        _recentTransactions.isEmpty
            ? _buildEmptyTransactions()
            : Column(
                children: _recentTransactions.map((transaction) {
                  return _buildTransactionItem(
                    transaction: transaction,
                    currencySymbol: currencySymbol,
                  );
                }).toList(),
              ),
      ],
    );
  }
  
  Widget _buildEmptyTransactions() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AppIcon(
              size: 80,
              primaryColor: Theme.of(context).primaryColor.withOpacity(0.7),
              secondaryColor: Theme.of(context).primaryColor,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
            const SizedBox(height: 24),
            Text(
              'No transactions yet',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Text(
              'Start recording your financial activity for this account',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).textTheme.bodySmall?.color,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                _showAddTransactionDialog();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionsTab(String currencySymbol) {
    return Column(
      children: [
        // Filter bar
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _isFilterActive 
                      ? 'Filtered Transactions' 
                      : 'All Transactions',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              if (_isFilterActive)
                IconButton(
                  icon: const Icon(Icons.clear),
                  tooltip: 'Clear Filters',
                  onPressed: _clearFilters,
                ),
              IconButton(
                icon: const Icon(Icons.filter_list),
                tooltip: 'Filter Transactions',
                onPressed: _showFilterDialog,
              ),
            ],
          ),
        ),
        
        Expanded(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator())
              : _allTransactions.isEmpty
                  ? const Center(child: Text('No transactions found'))
                  : _buildTransactionList(),
        ),
      ],
    );
  }
  
  Widget _buildTransactionList() {
    // Group transactions by date
    final transactionsToDisplay = _isFilterActive ? _filteredTransactions : _allTransactions;
    
    if (transactionsToDisplay.isEmpty) {
      return const Center(
        child: Text('No transactions match the current filters'),
      );
    }
    
    final groupedTransactions = <String, List<TransactionModel>>{};
    
    for (final transaction in transactionsToDisplay) {
      final date = DateFormat('yyyy-MM-dd').format(transaction.date);
      if (!groupedTransactions.containsKey(date)) {
        groupedTransactions[date] = [];
      }
      groupedTransactions[date]!.add(transaction);
    }
    
    // Sort dates in descending order (most recent first)
    final sortedDates = groupedTransactions.keys.toList()
      ..sort((a, b) => b.compareTo(a));
    
    return ListView.builder(
      itemCount: sortedDates.length,
      itemBuilder: (context, index) {
        final date = sortedDates[index];
        final transactions = groupedTransactions[date]!;
        
        // Get currency symbol for this screen
        final currencyCode = _account.currencyCode;
        final currencySymbol = CurrencyUtils.getCurrencySymbol(currencyCode);
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                _formatDateHeader(DateTime.parse(date)),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: Colors.grey,
                ),
              ),
            ),
            ...transactions.map((transaction) => _buildTransactionItem(
              transaction: transaction,
              currencySymbol: currencySymbol,
            )).toList(),
          ],
        );
      },
    );
  }
  
  Widget _buildTransactionItem({
    required TransactionModel transaction,
    required String currencySymbol,
  }) {
    // Get category name
    final category = _categoriesMap[transaction.categoryId];
    final categoryName = category?.name ?? 'Uncategorized';
    
    // For transfers, get destination account name
    String? destinationAccountName;
    if (transaction.type == TransactionType.transfer && transaction.toAccountId != null) {
      final toAccount = _accountsMap[transaction.toAccountId];
      destinationAccountName = toAccount?.name;
    }
    
    // Format display data
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final amountText = '$currencySymbol${transaction.amount.toStringAsFixed(2)}';
    final amountColor = isIncome
        ? ColorConstants.successColor
        : isTransfer
            ? ColorConstants.infoColor
            : ColorConstants.errorColor;
    final icon = isIncome
        ? Icons.arrow_upward
        : isTransfer
            ? Icons.swap_horiz
            : Icons.arrow_downward;
    
    // Create subtitle text
    String subtitle = categoryName;
    if (isTransfer && destinationAccountName != null) {
      subtitle = 'To: $destinationAccountName';
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: amountColor.withOpacity(0.1),
          child: Icon(
            icon,
            color: amountColor,
          ),
        ),
        title: Text(
          transaction.description,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Text(
          '$subtitle • ${DateFormat('h:mm a').format(transaction.date)}',
          style: const TextStyle(fontSize: 12),
        ),
        trailing: Text(
          amountText,
          style: TextStyle(
            color: amountColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        onTap: () => _showTransactionDetails(transaction),
      ),
    );
  }
  
  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly == DateTime(now.year, now.month, now.day)) {
      return 'Today';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d, y').format(date);
    }
  }

  // Update the _showTransactionDetails method to include the edit and delete functionality
  void _showTransactionDetails(TransactionModel transaction) {
    final currencySymbol = CurrencyUtils.getCurrencySymbol(_account.currencyCode);
    
    // Get category name
    final category = _categoriesMap[transaction.categoryId];
    final categoryName = category?.name ?? 'Uncategorized';
    
    // Get destination account for transfers
    String? destinationAccountName;
    if (transaction.type == TransactionType.transfer && transaction.toAccountId != null) {
      final toAccount = _accountsMap[transaction.toAccountId];
      destinationAccountName = toAccount?.name;
    }
    
    // Determine colors and icons based on transaction type
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final amountColor = isIncome
        ? ColorConstants.successColor
        : isTransfer
            ? ColorConstants.infoColor
            : ColorConstants.errorColor;
    final typeIcon = isIncome
        ? Icons.arrow_upward
        : isTransfer
            ? Icons.swap_horiz
            : Icons.arrow_downward;
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  CircleAvatar(
                    backgroundColor: amountColor.withOpacity(0.1),
                    radius: 24,
                    child: Icon(
                      typeIcon,
                      color: amountColor,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          transaction.description,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          DateFormat('EEEE, MMMM d, y • h:mm a').format(transaction.date),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Amount
              Center(
                child: Text(
                  '$currencySymbol${transaction.amount.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: amountColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Details
              _buildDetailRow('Type', transaction.type.name.toUpperCase()),
              const SizedBox(height: 8),
              _buildDetailRow('Category', categoryName),
              
              if (isTransfer && destinationAccountName != null) ...[
                const SizedBox(height: 8),
                _buildDetailRow('To Account', destinationAccountName),
              ],
              
              if (transaction.notes != null && transaction.notes!.isNotEmpty) ...[
                const SizedBox(height: 16),
                const Text(
                  'Notes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(transaction.notes!),
              ],
              
              const SizedBox(height: 32),
              
              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton.icon(
                    icon: const Icon(Icons.edit),
                    label: const Text('Edit'),
                    onPressed: () {
                      Navigator.pop(context);
                      _showEditTransactionDialog(transaction);
                    },
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.delete, color: ColorConstants.errorColor),
                    label: Text('Delete', style: TextStyle(color: ColorConstants.errorColor)),
                    onPressed: () {
                      Navigator.pop(context);
                      _showDeleteTransactionConfirmation(transaction);
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showEditTransactionDialog(TransactionModel transaction) async {
    final updatedTransaction = await showDialog<TransactionModel>(
      context: context,
      builder: (BuildContext context) {
        return EditTransactionDialog(
          transaction: transaction,
          account: _account,
        );
      },
    );
    
    if (updatedTransaction != null) {
      try {
        // Update the transaction using the repository
        await _transactionRepository.updateTransaction(transaction, updatedTransaction);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction updated successfully'),
            backgroundColor: ColorConstants.successColor,
          ),
        );
        
        // Refresh data to update transactions and account balance
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating transaction: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  Future<void> _showDeleteTransactionConfirmation(TransactionModel transaction) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Transaction'),
          content: const Text('Are you sure you want to delete this transaction? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text(
                'Delete',
                style: TextStyle(color: ColorConstants.errorColor),
              ),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      try {
        // Delete the transaction using the repository
        await _transactionRepository.deleteTransaction(transaction.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction deleted successfully'),
            backgroundColor: ColorConstants.successColor,
          ),
        );
        
        // Refresh data to update transactions and account balance
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transaction: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDeleteAccountConfirmation() async {
    final hasTransactions = _allTransactions.isNotEmpty;
    
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "${_account.name}"?'),
              const SizedBox(height: 12),
              if (hasTransactions)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: ColorConstants.errorColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.warning, color: ColorConstants.errorColor, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'This account has ${_allTransactions.length} transactions. Deleting it will also remove all associated transactions.',
                          style: TextStyle(
                            color: ColorConstants.errorColor,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
              const Text(
                'This action cannot be undone.',
                style: TextStyle(fontStyle: FontStyle.italic),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(
                foregroundColor: ColorConstants.errorColor,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
    
    if (confirmed == true) {
      try {
        // First delete all associated transactions
        if (hasTransactions) {
          for (final transaction in _allTransactions) {
            await _transactionRepository.deleteTransaction(transaction.id);
          }
        }
        
        // Then delete the account
        await _accountRepository.deleteAccount(_account.id);
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${_account.name} has been deleted'),
              backgroundColor: ColorConstants.successColor,
            ),
          );
          
          // Navigate back to the accounts screen
          Navigator.of(context).pop();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error deleting account: $e'),
              backgroundColor: ColorConstants.errorColor,
            ),
          );
        }
      }
    }
  }
} 