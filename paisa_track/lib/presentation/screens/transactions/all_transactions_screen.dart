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
import 'package:paisa_track/presentation/screens/accounts/edit_transaction_dialog.dart';
import 'package:paisa_track/presentation/widgets/common/confirmation_dialog.dart';
import 'package:paisa_track/presentation/widgets/common/loading_indicator.dart';
import 'package:paisa_track/presentation/widgets/common/error_view.dart';
import 'package:paisa_track/core/utils/app_router.dart' as core_router;
import 'package:paisa_track/app/router/app_router.dart';
import 'package:paisa_track/providers/currency_provider.dart';
import 'package:provider/provider.dart';

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
        _applyFilters();
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
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: _showSearchBar 
            ? TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search transactions...',
                  hintStyle: TextStyle(color: theme.appBarTheme.foregroundColor?.withOpacity(0.7)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _toggleSearchBar();
                    },
                  ),
                ),
                style: TextStyle(color: theme.appBarTheme.foregroundColor),
                autofocus: true,
                cursorColor: theme.primaryColor,
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
              Navigator.pushNamed(context, core_router.AppRouter.transactionStatistics);
            },
          ),
          // Export transactions button
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: 'Export Transactions',
            onPressed: () {
              Navigator.pushNamed(context, core_router.AppRouter.transactionHistoryExport);
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'More options',
            onSelected: (value) {
              switch (value) {
                case 'filter':
                  _showFilterDialog();
                  break;
                case 'clear':
                  _clearFilters();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'filter',
                child: Row(
                  children: [
                    Icon(Icons.filter_list, size: 20),
                    SizedBox(width: 8),
                    Text('Filter Transactions'),
                  ],
                ),
              ),
              if (_isFilterActive)
                const PopupMenuItem<String>(
                  value: 'clear',
                  child: Row(
                    children: [
                      Icon(Icons.filter_list_off, size: 20),
                      SizedBox(width: 8),
                      Text('Clear Filters'),
                    ],
                  ),
                ),
            ],
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(44),
          child: Container(
            color: theme.scaffoldBackgroundColor,
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isDarkMode 
                    ? theme.colorScheme.surfaceVariant.withOpacity(0.4)
                    : theme.colorScheme.primaryContainer.withOpacity(0.2),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range, 
                    size: 18, 
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('MMM d, yyyy').format(_startDate)} - ${DateFormat('MMM d, yyyy').format(_endDate)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: _showDateRangeModal,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        'Change',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          // Filter chips
          if (_isFilterActive && (_selectedTransactionType != null || 
                                 _selectedCategoryId != null || 
                                 _selectedAccountId != null ||
                                 _searchQuery.isNotEmpty))
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              color: theme.colorScheme.primaryContainer.withOpacity(0.1),
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
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: Container(
        decoration: BoxDecoration(
          color: theme.brightness == Brightness.dark
              ? theme.colorScheme.surfaceVariant
              : theme.colorScheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: theme.colorScheme.primary.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 8, right: 4),
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.primary,
                  ),
                ),
              ),
              Material(
                color: Colors.transparent,
                shape: const CircleBorder(),
                clipBehavior: Clip.antiAlias,
                child: IconButton(
                  icon: Icon(Icons.close, size: 16, color: theme.colorScheme.primary),
                  onPressed: onDeleted,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(),
                  visualDensity: VisualDensity.compact,
                  splashRadius: 16,
                ),
              ),
            ],
          ),
        ),
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
    
    // Get the current system currency from provider
    final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
    final currencySymbol = CurrencyUtils.getCurrencySymbol(currencyProvider.currencyCode);
    
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

    return Dismissible(
      key: Key(transaction.id),
      background: Container(
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        color: const Color(0xFF00B37E),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Icon(Icons.edit, color: Colors.white),
            SizedBox(width: 8),
            Text(
              'Edit',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: Colors.red,
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(width: 8),
            Icon(Icons.delete, color: Colors.white),
          ],
        ),
      ),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Delete operation
          return await _confirmDeleteTransaction(transaction);
        } else if (direction == DismissDirection.startToEnd) {
          // Edit operation
          _editTransaction(transaction);
          return false; // Don't dismiss the item
        }
        return false;
      },
      onDismissed: (direction) {
        if (direction == DismissDirection.endToStart) {
          _deleteTransaction(transaction);
        }
      },
      child: Card(
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
                      '${isIncome ? '+' : isTransfer ? '≈' : '-'}$currencySymbol${transaction.amount.toStringAsFixed(2)}',
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
      ),
    );
  }

  Future<bool> _confirmDeleteTransaction(TransactionModel transaction) async {
    return await showDialog<bool>(
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
    ) ?? false;
  }
  
  Future<void> _deleteTransaction(TransactionModel transaction) async {
    try {
      // Delete the transaction using the repository
      await _transactionRepository.deleteTransaction(transaction.id);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Transaction deleted successfully'),
            backgroundColor: ColorConstants.successColor,
            action: SnackBarAction(
              label: 'Undo',
              textColor: Colors.white,
              onPressed: () {
                // This would require additional implementation to support undo
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Undo feature coming soon'),
                  ),
                );
              },
            ),
          ),
        );
      }
      
      // Refresh data to update transactions list
      _loadData();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transaction: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  void _editTransaction(TransactionModel transaction) {
    final AccountModel? account = _accountsMap[transaction.accountId];
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error: Could not find account information'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionDialog(
          transaction: transaction,
          account: account,
        ),
      ),
    ).then((_) {
      _loadData();
    });
  }

  // Show date range selector modal
  void _showDateRangeModal() async {
    final currentYear = DateTime.now().year;
    final initialDateRange = DateTimeRange(start: _startDate, end: _endDate);
    
    // Predefined date ranges
    final presetRanges = [
      {'label': 'Today', 'days': 0},
      {'label': 'Yesterday', 'days': 1},
      {'label': 'Last 7 days', 'days': 7},
      {'label': 'Last 30 days', 'days': 30},
      {'label': 'This Month', 'days': -1},  // Special case
      {'label': 'Last Month', 'days': -2},  // Special case
      {'label': 'This Year', 'days': -3},   // Special case
    ];
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Date Range',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 8),
                  
                  // Preset date ranges
                  Text(
                    'Preset Ranges',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: presetRanges.map((range) {
                      return InkWell(
                        onTap: () {
                          final DateTime now = DateTime.now();
                          DateTime start, end;
                          
                          switch (range['days']) {
                            case 0: // Today
                              start = DateTime(now.year, now.month, now.day);
                              end = now;
                              break;
                            case 1: // Yesterday
                              final yesterday = now.subtract(const Duration(days: 1));
                              start = DateTime(yesterday.year, yesterday.month, yesterday.day);
                              end = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
                              break;
                            case -1: // This Month
                              start = DateTime(now.year, now.month, 1);
                              end = now;
                              break;
                            case -2: // Last Month
                              final lastMonth = DateTime(now.year, now.month - 1, 1);
                              start = DateTime(lastMonth.year, lastMonth.month, 1);
                              end = DateTime(now.year, now.month, 0, 23, 59, 59);
                              break;
                            case -3: // This Year
                              start = DateTime(now.year, 1, 1);
                              end = now;
                              break;
                            default: // Last n days
                              start = DateTime.now().subtract(Duration(days: range['days'] as int));
                              end = now;
                          }
                          
                          setModalState(() {
                            _startDate = start;
                            _endDate = end;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            range['label'] as String,
                            style: TextStyle(
                              fontSize: 14,
                              color: Theme.of(context).colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 24),
                  
                  // Custom range
                  Text(
                    'Custom Range',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  
                  // Start date picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _startDate,
                        firstDate: DateTime(currentYear - 5),
                        lastDate: _endDate,
                      );
                      if (picked != null) {
                        setModalState(() {
                          _startDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Start Date',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(
                                DateFormat('MMMM d, yyyy').format(_startDate),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // End date picker
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _endDate,
                        firstDate: _startDate,
                        lastDate: DateTime.now(),
                      );
                      if (picked != null) {
                        setModalState(() {
                          _endDate = picked;
                        });
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Theme.of(context).dividerColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 20),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'End Date',
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                              Text(
                                DateFormat('MMMM d, yyyy').format(_endDate),
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  const Spacer(),
                  
                  // Apply button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {
                          _applyFilters();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text('Apply Date Range'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
} 