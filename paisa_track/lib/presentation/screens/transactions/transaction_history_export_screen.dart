import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';
import 'package:paisa_track/data/services/pdf_service.dart';
import 'package:paisa_track/providers/currency_provider.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/enums/account_type.dart';

class TransactionHistoryExportScreen extends StatefulWidget {
  static const String routeName = '/transaction-history-export';

  const TransactionHistoryExportScreen({Key? key}) : super(key: key);

  @override
  State<TransactionHistoryExportScreen> createState() => _TransactionHistoryExportScreenState();
}

class _TransactionHistoryExportScreenState extends State<TransactionHistoryExportScreen> {
  // Repositories and services
  late final TransactionRepository _transactionRepository;
  late final AccountRepository _accountRepository;
  late final CategoryRepository _categoryRepository;
  late final PdfService _pdfService;
  late final UserRepository _userRepository;
  
  // Date range
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();
  
  // Filters
  String? _selectedTypeFilter;
  String? _selectedCategoryFilter;
  String? _selectedAccountFilter;
  
  // Processing state
  bool _isProcessing = false;
  String? _statusMessage;
  
  // Available filter options
  List<CategoryModel> _categories = [];
  List<AccountModel> _accounts = [];
  final List<String> _transactionTypes = ['All', 'Income', 'Expense', 'Transfer'];
  
  @override
  void initState() {
    super.initState();
    _transactionRepository = Provider.of<TransactionRepository>(context, listen: false);
    _accountRepository = Provider.of<AccountRepository>(context, listen: false);
    _categoryRepository = Provider.of<CategoryRepository>(context, listen: false);
    _pdfService = PdfService();
    _userRepository = UserRepository();
    
    _loadFilterOptions();
  }
  
  // Load filter options
  Future<void> _loadFilterOptions() async {
    final categories = _categoryRepository.getAllCategories();
    final accounts = _accountRepository.getAllAccounts();
    
    setState(() {
      _categories = categories;
      _accounts = accounts;
    });
  }
  
  // Select start date
  Future<void> _selectStartDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: _endDate,
    );
    
    if (picked != null && picked != _startDate) {
      setState(() {
        _startDate = picked;
      });
    }
  }
  
  // Select end date
  Future<void> _selectEndDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _endDate,
      firstDate: _startDate,
      lastDate: DateTime.now(),
    );
    
    if (picked != null && picked != _endDate) {
      setState(() {
        _endDate = picked;
      });
    }
  }
  
  // Select predefined period
  void _selectPredefinedPeriod(String period) {
    final now = DateTime.now();
    
    switch (period) {
      case 'Today':
        setState(() {
          _startDate = DateTime(now.year, now.month, now.day);
          _endDate = now;
        });
        break;
      case 'Yesterday':
        final yesterday = now.subtract(const Duration(days: 1));
        setState(() {
          _startDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
          _endDate = DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59);
        });
        break;
      case 'This Week':
        // Monday as first day of week
        final weekday = now.weekday;
        final firstDayOfWeek = now.subtract(Duration(days: weekday - 1));
        
        setState(() {
          _startDate = DateTime(firstDayOfWeek.year, firstDayOfWeek.month, firstDayOfWeek.day);
          _endDate = now;
        });
        break;
      case 'Last Week':
        // Monday as first day of week
        final weekday = now.weekday;
        final firstDayOfLastWeek = now.subtract(Duration(days: weekday - 1 + 7));
        final lastDayOfLastWeek = now.subtract(Duration(days: weekday));
        
        setState(() {
          _startDate = DateTime(firstDayOfLastWeek.year, firstDayOfLastWeek.month, firstDayOfLastWeek.day);
          _endDate = DateTime(lastDayOfLastWeek.year, lastDayOfLastWeek.month, lastDayOfLastWeek.day, 23, 59, 59);
        });
        break;
      case 'This Month':
        setState(() {
          _startDate = DateTime(now.year, now.month, 1);
          _endDate = now;
        });
        break;
      case 'Last Month':
        final lastMonth = DateTime(now.year, now.month - 1);
        setState(() {
          _startDate = DateTime(lastMonth.year, lastMonth.month, 1);
          _endDate = DateTime(now.year, now.month, 0, 23, 59, 59);
        });
        break;
      case 'Last 3 Months':
        setState(() {
          _startDate = DateTime(now.year, now.month - 3, now.day);
          _endDate = now;
        });
        break;
      case 'Last 6 Months':
        setState(() {
          _startDate = DateTime(now.year, now.month - 6, now.day);
          _endDate = now;
        });
        break;
      case 'This Year':
        setState(() {
          _startDate = DateTime(now.year, 1, 1);
          _endDate = now;
        });
        break;
      case 'Last Year':
        setState(() {
          _startDate = DateTime(now.year - 1, 1, 1);
          _endDate = DateTime(now.year - 1, 12, 31, 23, 59, 59);
        });
        break;
      case 'All Time':
        setState(() {
          _startDate = DateTime(2020);
          _endDate = now;
        });
        break;
      default:
        // Default to last 30 days
        setState(() {
          _startDate = now.subtract(const Duration(days: 30));
          _endDate = now;
        });
    }
  }
  
  // Reset all filters
  void _resetFilters() {
    setState(() {
      _selectedTypeFilter = null;
      _selectedCategoryFilter = null;
      _selectedAccountFilter = null;
      
      // Reset date to last 30 days
      _startDate = DateTime.now().subtract(const Duration(days: 30));
      _endDate = DateTime.now();
    });
  }
  
  // Generate and share PDF
  Future<void> _generateAndSharePdf() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Generating PDF...';
    });
    
    try {
      // Get user profile
      final userProfile = await _userRepository.getUserProfile();
      
      // Get currency details
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      final currentCurrency = currencyProvider.currencyCode;
      final currencySymbol = CurrencyUtils.getCurrencySymbol(currentCurrency);
      
      // Apply filters
      TransactionType? filterType;
      if (_selectedTypeFilter != null && _selectedTypeFilter != 'All') {
        filterType = TransactionType.values.firstWhere(
          (type) => type.name.toLowerCase() == _selectedTypeFilter!.toLowerCase(),
          orElse: () => TransactionType.expense,
        );
      }
      
      String? categoryId;
      if (_selectedCategoryFilter != null) {
        final category = _categories.firstWhere(
          (cat) => cat.name == _selectedCategoryFilter,
          orElse: () => CategoryModel(name: '', iconName: '', colorValue: 0, isIncome: false),
        );
        categoryId = category.id.isNotEmpty ? category.id : null;
      }
      
      String? accountId;
      if (_selectedAccountFilter != null) {
        final account = _accounts.firstWhere(
          (acc) => acc.name == _selectedAccountFilter,
          orElse: () => AccountModel(name: '', type: AccountType.cash),
        );
        accountId = account.id.isNotEmpty ? account.id : null;
      }
      
      // Get filtered transactions
      final transactions = _transactionRepository.getTransactionsByDateRange(_startDate, _endDate);
      
      // Apply additional filters since the repository might not support all filter types
      final filteredTransactions = transactions.where((transaction) {
        // Transaction type filter
        if (filterType != null && transaction.type != filterType) {
          return false;
        }
        
        // Category filter
        if (categoryId != null && transaction.categoryId != categoryId) {
          return false;
        }
        
        // Account filter
        if (accountId != null && transaction.accountId != accountId) {
          return false;
        }
        
        return true;
      }).toList();
      
      // Sort transactions by date (newest first)
      filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
      
      // Prepare category and account lookup maps
      final Map<String, CategoryModel> categoriesMap = {};
      final Map<String, AccountModel> accountsMap = {};
      
      for (final category in _categories) {
        categoriesMap[category.id] = category;
      }
      
      for (final account in _accounts) {
        accountsMap[account.id] = account;
      }
      
      // Set status message based on transaction count
      setState(() {
        _statusMessage = 'Generating PDF with ${filteredTransactions.length} transactions...';
      });
      
      if (filteredTransactions.isEmpty) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'No transactions found for the selected period and filters.';
        });
        return;
      }
      
      // Generate PDF
      final pdfBytes = await _pdfService.generateTransactionHistoryPdf(
        transactions: filteredTransactions,
        categories: categoriesMap,
        accounts: accountsMap,
        currencySymbol: currencySymbol,
        startDate: _startDate,
        endDate: _endDate,
        filterType: _selectedTypeFilter,
        filterCategory: _selectedCategoryFilter,
        filterAccount: _selectedAccountFilter,
        userProfile: userProfile,
      );
      
      // Generate a filename
      final startDateStr = DateFormat('yyyyMMdd').format(_startDate);
      final endDateStr = DateFormat('yyyyMMdd').format(_endDate);
      final fileName = 'Transaction_History_${startDateStr}_to_${endDateStr}.pdf';
      
      // Share PDF
      await _pdfService.sharePdf(pdfBytes, fileName);
      
      setState(() {
        _statusMessage = 'PDF generated successfully!';
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error generating PDF: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  // Generate and download PDF
  Future<void> _generateAndDownloadPdf() async {
    setState(() {
      _isProcessing = true;
      _statusMessage = 'Generating PDF...';
    });
    
    try {
      // Get user profile
      final userProfile = await _userRepository.getUserProfile();
      
      // Get currency details
      final currencyProvider = Provider.of<CurrencyProvider>(context, listen: false);
      final currentCurrency = currencyProvider.currencyCode;
      final currencySymbol = CurrencyUtils.getCurrencySymbol(currentCurrency);
      
      // Apply filters
      TransactionType? filterType;
      if (_selectedTypeFilter != null && _selectedTypeFilter != 'All') {
        filterType = TransactionType.values.firstWhere(
          (type) => type.name.toLowerCase() == _selectedTypeFilter!.toLowerCase(),
          orElse: () => TransactionType.expense,
        );
      }
      
      String? categoryId;
      if (_selectedCategoryFilter != null) {
        final category = _categories.firstWhere(
          (cat) => cat.name == _selectedCategoryFilter,
          orElse: () => CategoryModel(name: '', iconName: '', colorValue: 0, isIncome: false),
        );
        categoryId = category.id.isNotEmpty ? category.id : null;
      }
      
      String? accountId;
      if (_selectedAccountFilter != null) {
        final account = _accounts.firstWhere(
          (acc) => acc.name == _selectedAccountFilter,
          orElse: () => AccountModel(name: '', type: AccountType.cash),
        );
        accountId = account.id.isNotEmpty ? account.id : null;
      }
      
      // Get filtered transactions
      final transactions = _transactionRepository.getTransactionsByDateRange(_startDate, _endDate);
      
      // Apply additional filters since the repository might not support all filter types
      final filteredTransactions = transactions.where((transaction) {
        // Transaction type filter
        if (filterType != null && transaction.type != filterType) {
          return false;
        }
        
        // Category filter
        if (categoryId != null && transaction.categoryId != categoryId) {
          return false;
        }
        
        // Account filter
        if (accountId != null && transaction.accountId != accountId) {
          return false;
        }
        
        return true;
      }).toList();
      
      // Sort transactions by date (newest first)
      filteredTransactions.sort((a, b) => b.date.compareTo(a.date));
      
      // Prepare category and account lookup maps
      final Map<String, CategoryModel> categoriesMap = {};
      final Map<String, AccountModel> accountsMap = {};
      
      for (final category in _categories) {
        categoriesMap[category.id] = category;
      }
      
      for (final account in _accounts) {
        accountsMap[account.id] = account;
      }
      
      // Set status message based on transaction count
      setState(() {
        _statusMessage = 'Generating PDF with ${filteredTransactions.length} transactions...';
      });
      
      if (filteredTransactions.isEmpty) {
        setState(() {
          _isProcessing = false;
          _statusMessage = 'No transactions found for the selected period and filters.';
        });
        return;
      }
      
      // Generate PDF
      final pdfBytes = await _pdfService.generateTransactionHistoryPdf(
        transactions: filteredTransactions,
        categories: categoriesMap,
        accounts: accountsMap,
        currencySymbol: currencySymbol,
        startDate: _startDate,
        endDate: _endDate,
        filterType: _selectedTypeFilter,
        filterCategory: _selectedCategoryFilter,
        filterAccount: _selectedAccountFilter,
        userProfile: userProfile,
      );
      
      // Generate a filename
      final startDateStr = DateFormat('yyyyMMdd').format(_startDate);
      final endDateStr = DateFormat('yyyyMMdd').format(_endDate);
      final fileName = 'Transaction_History_${startDateStr}_to_${endDateStr}.pdf';
      
      // Save PDF to file
      final filePath = await _pdfService.savePdfToTempFile(pdfBytes, fileName);
      
      setState(() {
        _statusMessage = 'PDF saved to: $filePath';
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PDF saved to: $filePath'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 5),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () => _pdfService.sharePdf(pdfBytes, fileName),
            textColor: Colors.white,
          ),
        ),
      );
    } catch (e) {
      setState(() {
        _statusMessage = 'Error generating PDF: $e';
      });
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Export Transaction History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Reset Filters',
            onPressed: _resetFilters,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date range section
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Date Range',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ListTile(
                            title: const Text('From'),
                            subtitle: Text(DateFormat('MMM dd, yyyy').format(_startDate)),
                            onTap: _selectStartDate,
                            leading: const Icon(Icons.calendar_today),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                        Expanded(
                          child: ListTile(
                            title: const Text('To'),
                            subtitle: Text(DateFormat('MMM dd, yyyy').format(_endDate)),
                            onTap: _selectEndDate,
                            leading: const Icon(Icons.calendar_today),
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Quick Select',
                      style: theme.textTheme.titleSmall,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        'Today',
                        'Yesterday',
                        'This Week',
                        'Last Week',
                        'This Month',
                        'Last Month',
                        'Last 3 Months',
                        'This Year',
                      ].map((period) => FilterChip(
                        label: Text(period),
                        selected: false,
                        onSelected: (_) => _selectPredefinedPeriod(period),
                      )).toList(),
                    ),
                  ],
                ),
              ),
            ),
            
            // Filters section
            Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Filters',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    
                    // Type filter
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Transaction Type',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedTypeFilter,
                      hint: const Text('All Transaction Types'),
                      items: _transactionTypes.map((type) => DropdownMenuItem(
                        value: type,
                        child: Text(type),
                      )).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedTypeFilter = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Category filter
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Category',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedCategoryFilter,
                      hint: const Text('All Categories'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ..._categories.map((category) => DropdownMenuItem(
                          value: category.name,
                          child: Text(category.name),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedCategoryFilter = value;
                        });
                      },
                    ),
                    const SizedBox(height: 16),
                    
                    // Account filter
                    DropdownButtonFormField<String>(
                      decoration: const InputDecoration(
                        labelText: 'Account',
                        border: OutlineInputBorder(),
                      ),
                      value: _selectedAccountFilter,
                      hint: const Text('All Accounts'),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('All Accounts'),
                        ),
                        ..._accounts.map((account) => DropdownMenuItem(
                          value: account.name,
                          child: Text(account.name),
                        )).toList(),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _selectedAccountFilter = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            
            // Status and actions
            if (_statusMessage != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: _statusMessage!.contains('Error') 
                      ? Colors.red.withOpacity(0.1) 
                      : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _statusMessage!.contains('Error') 
                        ? Colors.red.withOpacity(0.3) 
                        : Colors.green.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _statusMessage!.contains('Error') ? Icons.error : Icons.info,
                      color: _statusMessage!.contains('Error') ? Colors.red : Colors.green,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _statusMessage!,
                        style: TextStyle(
                          color: _statusMessage!.contains('Error') ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.download),
                    label: const Text('Download PDF'),
                    onPressed: _isProcessing ? null : _generateAndDownloadPdf,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.share),
                    label: const Text('Share PDF'),
                    onPressed: _isProcessing ? null : _generateAndSharePdf,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
            
            if (_isProcessing) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }
} 