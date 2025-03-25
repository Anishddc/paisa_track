import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:paisa_track/core/utils/date_utils.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/presentation/screens/transactions/add_transaction_dialog.dart';
import 'package:paisa_track/presentation/screens/transactions/transaction_details_screen.dart';
import 'package:paisa_track/presentation/widgets/common/confirmation_dialog.dart';
import 'package:paisa_track/presentation/widgets/common/loading_indicator.dart';
import 'package:paisa_track/presentation/widgets/common/error_view.dart';
import 'package:paisa_track/core/utils/app_router.dart';

class AllTransactionsScreen extends StatefulWidget {
  const AllTransactionsScreen({Key? key}) : super(key: key);

  @override
  State<AllTransactionsScreen> createState() => _AllTransactionsScreenState();
}

class _AllTransactionsScreenState extends State<AllTransactionsScreen> {
  final TransactionRepository _transactionRepository = TransactionRepository();
  final CategoryRepository _categoryRepository = CategoryRepository();
  final AccountRepository _accountRepository = AccountRepository();
  
  List<TransactionModel> _allTransactions = [];
  List<TransactionModel> _filteredTransactions = [];
  Map<String, CategoryModel> _categoriesMap = {};
  Map<String, AccountModel> _accountsMap = {};
  
  bool _isLoading = true;
  String? _error;
  
  // Filter states
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  TransactionType? _selectedTransactionType;
  String? _selectedCategoryId;
  String? _selectedAccountId;
  bool _isFilterActive = false;
  
  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _showSearchBar = false;

  @override
  void initState() {
    super.initState();
    _loadData();
    _searchController.addListener(_onSearchChanged);
    
    // Set up stream listeners after initial render
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupStreamListeners();
    });
  }
  
  void _setupStreamListeners() {
    // Listen to transaction changes
    _transactionRepository.transactionsChanged.listen((_) {
      debugPrint("All Transactions Screen: Transaction change detected!");
      if (mounted) {
        _loadData();
      }
    });
  }
  
  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }
  
  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text;
      _applyFilters();
    });
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Load all transactions
      final transactions = _transactionRepository.getAllTransactions();
      transactions.sort((a, b) => b.date.compareTo(a.date)); // Newest first
      
      // Load categories and accounts
      final categories = _categoryRepository.getAllCategories();
      final accounts = _accountRepository.getAllAccounts();
      
      // Create maps for quick lookups
      final categoriesMap = {for (var c in categories) c.id: c};
      final accountsMap = {for (var a in accounts) a.id: a};
      
      setState(() {
        _allTransactions = transactions;
        _categoriesMap = categoriesMap;
        _accountsMap = accountsMap;
        _isLoading = false;
      });
      
      // Apply filters after loading data
      _applyFilters();
    } catch (e) {
      setState(() {
        _error = 'Failed to load transactions: $e';
        _isLoading = false;
      });
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
      
      // Account filter
      if (_selectedAccountId != null && 
          transaction.accountId != _selectedAccountId) {
        return false;
      }
      
      // Search query
      if (_searchQuery.isNotEmpty) {
        final query = _searchQuery.toLowerCase();
        final category = _categoriesMap[transaction.categoryId];
        final account = _accountsMap[transaction.accountId];
        
        // Search in description, amount, category name, account name
        final matchesDescription = transaction.description != null && 
            transaction.description!.toLowerCase().contains(query);
        final matchesAmount = transaction.amount.toString().contains(query);
        final matchesCategory = category != null && 
            category.name.toLowerCase().contains(query);
        final matchesAccount = account != null && 
            account.name.toLowerCase().contains(query);
        final matchesNotes = transaction.notes != null && 
            transaction.notes!.toLowerCase().contains(query);
        
        return matchesDescription || matchesAmount || matchesCategory || 
               matchesAccount || matchesNotes;
      }
      
      return true;
    }).toList();
    
    // Update filter active status
    _isFilterActive = _selectedTransactionType != null || 
                      _selectedCategoryId != null || 
                      _selectedAccountId != null ||
                      !_startDate.isAtSameMomentAs(DateTime.now().subtract(const Duration(days: 30))) ||
                      !_endDate.isAtSameMomentAs(DateTime.now()) ||
                      _searchQuery.isNotEmpty;
  }

  Future<void> _showFilterDialog() async {
    final accounts = _accountRepository.getAllAccounts();
    final categories = _categoryRepository.getAllCategories();
    
    // Store original values to restore if canceled
    final originalStartDate = _startDate;
    final originalEndDate = _endDate;
    final originalType = _selectedTransactionType;
    final originalCategoryId = _selectedCategoryId;
    final originalAccountId = _selectedAccountId;
    
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text('Filter Transactions'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Preset date ranges
                const Text('Quick Date Ranges', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _buildDatePresetChip('Last 7 days', 7, setStateDialog),
                      const SizedBox(width: 8),
                      _buildDatePresetChip('Last 30 days', 30, setStateDialog),
                      const SizedBox(width: 8),
                      _buildDatePresetChip('Last 3 months', 90, setStateDialog, isThisMonth: true),
                      const SizedBox(width: 8),
                      _buildDatePresetChip('This month', 0, setStateDialog, isThisMonth: true),
                      const SizedBox(width: 8),
                      _buildDatePresetChip('Last month', 0, setStateDialog, isLastMonth: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              
                // Date Range
                const Text('Custom Date Range', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _startDate,
                            firstDate: DateTime(2000),
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setStateDialog(() {
                              _startDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'From',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(DateFormat('MMM d, yyyy').format(_startDate)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: _endDate,
                            firstDate: _startDate,
                            lastDate: DateTime.now(),
                          );
                          if (date != null) {
                            setStateDialog(() {
                              _endDate = date;
                            });
                          }
                        },
                        child: InputDecorator(
                          decoration: const InputDecoration(
                            labelText: 'To',
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(DateFormat('MMM d, yyyy').format(_endDate)),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                
                // Transaction Type
                const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<TransactionType?>(
                  value: _selectedTransactionType,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<TransactionType?>(
                      value: null,
                      child: Text('All Types'),
                    ),
                    ...TransactionType.values.map((type) => DropdownMenuItem<TransactionType?>(
                      value: type,
                      child: Text(type.name),
                    )).toList(),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      _selectedTransactionType = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Account
                const Text('Account', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _selectedAccountId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Accounts'),
                    ),
                    ...accounts.map((account) => DropdownMenuItem<String?>(
                      value: account.id,
                      child: Text(account.name),
                    )).toList(),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      _selectedAccountId = value;
                    });
                  },
                ),
                const SizedBox(height: 16),
                
                // Category
                const Text('Category', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                DropdownButtonFormField<String?>(
                  value: _selectedCategoryId,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Categories'),
                    ),
                    ...categories.map((category) => DropdownMenuItem<String?>(
                      value: category.id,
                      child: Text(category.name),
                    )).toList(),
                  ],
                  onChanged: (value) {
                    setStateDialog(() {
                      _selectedCategoryId = value;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                // Restore original values
                _startDate = originalStartDate;
                _endDate = originalEndDate;
                _selectedTransactionType = originalType;
                _selectedCategoryId = originalCategoryId;
                _selectedAccountId = originalAccountId;
                Navigator.of(context).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
    
    if (result == true) {
      setState(() {
        _applyFilters();
      });
    }
  }
  
  Widget _buildDatePresetChip(String label, int days, Function(void Function()) setStateDialog, {
    bool isThisMonth = false,
    bool isLastMonth = false,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: false,
      onSelected: (selected) {
        if (selected) {
          setStateDialog(() {
            if (isThisMonth) {
              // This month
              final now = DateTime.now();
              _startDate = DateTime(now.year, now.month, 1);
              _endDate = DateTime.now();
            } else if (isLastMonth) {
              // Last month
              final now = DateTime.now();
              _startDate = DateTime(now.year, now.month - 1, 1);
              _endDate = DateTime(now.year, now.month, 0);
            } else {
              // Last X days
              _endDate = DateTime.now();
              _startDate = DateTime.now().subtract(Duration(days: days));
            }
          });
        }
      },
    );
  }

  void _clearFilters() {
    setState(() {
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
      _selectedTransactionType = null;
      _selectedCategoryId = null;
      _selectedAccountId = null;
      _searchController.clear();
      _searchQuery = '';
      _isFilterActive = false;
      
      _applyFilters();
    });
  }
  
  void _toggleSearchBar() {
    setState(() {
      _showSearchBar = !_showSearchBar;
      if (!_showSearchBar) {
        _searchController.clear();
      }
    });
  }

  Future<void> _showAddTransactionDialog() async {
    final accounts = _accountRepository.getActiveAccounts();
    
    if (accounts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please create an account first'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    // Use selected account or first account
    final account = _selectedAccountId != null 
        ? accounts.firstWhere((a) => a.id == _selectedAccountId, orElse: () => accounts.first)
        : accounts.first;
    
    final result = await showDialog<TransactionModel>(
      context: context,
      builder: (context) => AddTransactionDialog(
        account: account,
      ),
    );
    
    if (result != null && mounted) {
      await _loadData();
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction added successfully'),
          backgroundColor: ColorConstants.successColor,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _showSearchBar 
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                  border: InputBorder.none,
                ),
                style: const TextStyle(color: Colors.white),
                autofocus: true,
                cursorColor: Colors.white,
              )
            : const Text('All Transactions'),
        centerTitle: !_showSearchBar,
        leading: _showSearchBar 
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: _toggleSearchBar,
              )
            : null,
        actions: [
          if (!_showSearchBar)
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: _toggleSearchBar,
              tooltip: 'Search Transactions',
            ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'Statistics',
            onPressed: () {
              Navigator.pushNamed(context, AppRouter.transactionStatistics);
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: _showFilterDialog,
            tooltip: 'Filter Transactions',
          ),
          if (_isFilterActive)
            IconButton(
              icon: const Icon(Icons.filter_list_off),
              onPressed: _clearFilters,
              tooltip: 'Clear Filters',
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          if (_isFilterActive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: ColorConstants.primaryColor.withOpacity(0.1),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    if (_searchQuery.isNotEmpty)
                      _buildFilterChip(
                        'Search: ${_searchQuery.length > 10 ? '${_searchQuery.substring(0, 10)}...' : _searchQuery}',
                        () {
                          setState(() {
                            _searchController.clear();
                          });
                        },
                      ),
                    if (_selectedTransactionType != null)
                      _buildFilterChip(
                        'Type: ${_selectedTransactionType!.name}',
                        () {
                          setState(() {
                            _selectedTransactionType = null;
                            _applyFilters();
                          });
                        },
                      ),
                    if (_selectedCategoryId != null && _categoriesMap.containsKey(_selectedCategoryId))
                      _buildFilterChip(
                        'Category: ${_categoriesMap[_selectedCategoryId]!.name}',
                        () {
                          setState(() {
                            _selectedCategoryId = null;
                            _applyFilters();
                          });
                        },
                      ),
                    if (_selectedAccountId != null && _accountsMap.containsKey(_selectedAccountId))
                      _buildFilterChip(
                        'Account: ${_accountsMap[_selectedAccountId]!.name}',
                        () {
                          setState(() {
                            _selectedAccountId = null;
                            _applyFilters();
                          });
                        },
                      ),
                    if (!_startDate.isAtSameMomentAs(DateTime.now().subtract(const Duration(days: 30))) ||
                        !_endDate.isAtSameMomentAs(DateTime.now()))
                      _buildFilterChip(
                        'Date: ${DateFormat('MMM d').format(_startDate)} - ${DateFormat('MMM d').format(_endDate)}',
                        () {
                          setState(() {
                            _startDate = DateTime.now().subtract(const Duration(days: 30));
                            _endDate = DateTime.now();
                            _applyFilters();
                          });
                        },
                      ),
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Clear All'),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        minimumSize: Size.zero,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          
          // Transactions list
          Expanded(
            child: _isLoading
                ? const LoadingIndicator()
                : _error != null
                    ? ErrorView(
                        message: _error!,
                        onRetry: _loadData,
                      )
                    : _buildTransactionsList(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        tooltip: 'Add Transaction',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildFilterChip(String label, VoidCallback onDeleted) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Chip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        deleteIcon: const Icon(Icons.close, size: 16),
        onDeleted: onDeleted,
        visualDensity: VisualDensity.compact,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      ),
    );
  }

  String _formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateOnly = DateTime(date.year, date.month, date.day);
    
    if (dateOnly.isAtSameMomentAs(DateTime(now.year, now.month, now.day))) {
      return 'Today';
    } else if (dateOnly.isAtSameMomentAs(yesterday)) {
      return 'Yesterday';
    } else {
      return DateFormat('EEEE, MMMM d, y').format(date);
    }
  }

  Widget _buildTransactionsList() {
    final transactionsToDisplay = _isFilterActive ? _filteredTransactions : _allTransactions;
    
    if (transactionsToDisplay.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.receipt_long,
              size: 64,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              _isFilterActive
                  ? 'No transactions match your filters'
                  : 'No transactions yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (!_isFilterActive)
              const Text(
                'Add your first transaction using the + button',
                textAlign: TextAlign.center,
                style: TextStyle(color: ColorConstants.secondaryTextColor),
              ),
            if (_isFilterActive)
              TextButton(
                onPressed: _clearFilters,
                child: const Text('Clear Filters'),
              ),
          ],
        ),
      );
    }
    
    // Group transactions by date
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
            ...transactions.map((transaction) => _buildTransactionItem(transaction)).toList(),
          ],
        );
      },
    );
  }

  Widget _buildTransactionItem(TransactionModel transaction) {
    final isIncome = transaction.type == TransactionType.income;
    final isTransfer = transaction.type == TransactionType.transfer;
    final category = _categoriesMap[transaction.categoryId];
    final account = _accountsMap[transaction.accountId];
    
    if (category == null || account == null) {
      return const SizedBox.shrink();
    }
    
    final color = isIncome 
        ? ColorConstants.successColor
        : isTransfer 
            ? ColorConstants.infoColor
            : ColorConstants.errorColor;
    
    final icon = isIncome 
        ? Icons.arrow_upward
        : isTransfer 
            ? Icons.swap_horiz
            : Icons.arrow_downward;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TransactionDetailsScreen(
                transactionId: transaction.id,
              ),
            ),
          ).then((_) {
            _loadData();
          });
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  category.icon ?? icon,
                  color: color,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      category.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                      ),
                    ),
                    if (transaction.description != null && transaction.description!.isNotEmpty)
                      Text(
                        transaction.description!,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const SizedBox(height: 4),
                    Text(
                      account.name,
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '${isIncome ? '+' : isTransfer ? '≈' : '-'}${account.currency.symbol}${transaction.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    DateFormat('h:mm a').format(transaction.date),
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 