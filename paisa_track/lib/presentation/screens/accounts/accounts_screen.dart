import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/constants/text_constants.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/enums/account_type.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';
import 'package:paisa_track/presentation/screens/accounts/account_details_screen.dart';
import 'package:paisa_track/presentation/screens/accounts/add_account_screen.dart';
import 'package:paisa_track/presentation/screens/transactions/add_transaction_screen.dart';
import 'package:paisa_track/presentation/screens/accounts/edit_account_dialog.dart';
import 'package:paisa_track/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:paisa_track/core/utils/app_router.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  final AccountRepository _accountRepository = AccountRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();
  final UserRepository _userRepository = UserRepository();
  
  bool _isLoading = true;
  List<AccountModel> _accounts = [];
  String _defaultCurrencyCode = 'USD';
  String _userName = '';
  bool _isSearching = false;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Set up stream listeners after initial data load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupStreamListeners();
      
      // Check if we need to show the add account dialog immediately
      final Object? args = ModalRoute.of(context)?.settings.arguments;
      if (args != null && args is Map<String, dynamic>) {
        // Show add dialog if requested
        if (args.containsKey('showAddDialog') && args['showAddDialog'] == true) {
          _navigateToAddAccount();
        }
      }
    });
  }
  
  void _setupStreamListeners() {
    // Listen to account changes
    _accountRepository.accountsChanged.listen((_) {
      debugPrint("Accounts Screen: Account change detected!");
      if (mounted) {
        _loadData();
      }
    });
    
    // Listen to transaction changes (for balance updates)
    _transactionRepository.transactionsChanged.listen((_) {
      debugPrint("Accounts Screen: Transaction change detected!");
      if (mounted) {
        _loadData();
      }
    });
  }
  
  @override
  void dispose() {
    // Clean up any resources
    super.dispose();
  }
  
  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
    });
    
    try {
      // Get user info
      final userProfile = await _userRepository.getUserProfile();
      _defaultCurrencyCode = userProfile?.defaultCurrencyCode ?? 'USD';
      _userName = userProfile?.name ?? '';
      
      // Load accounts
      final accounts = _accountRepository.getAllAccounts();
      
      // Update state
      setState(() {
        _accounts = accounts;
        _accounts.sort((a, b) => a.name.compareTo(b.name));
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading accounts: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }
  
  Future<void> _handleReorder(int oldIndex, int newIndex) async {
    // Update the ordering of accounts
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    setState(() {
      final AccountModel account = _accounts.removeAt(oldIndex);
      _accounts.insert(newIndex, account);
    });
    
    // Here we would update the display order in the database
    // This would require adding a displayOrder field to AccountModel
  }
  
  Future<void> _navigateToAddAccount() async {
    final userRepository = UserRepository();
    final userProfile = await userRepository.getUserProfile();
    
    final AccountModel? newAccount = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddAccountScreen(
          defaultCurrencyCode: _defaultCurrencyCode,
          userName: _userName,
        ),
      ),
    );
    
    if (newAccount != null) {
      if (mounted) {
        setState(() {
          _accounts.add(newAccount);
          // Sort again (this would be replaced with orderBy displayOrder later)
          _accounts.sort((a, b) => a.name.compareTo(b.name));
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${newAccount.name} added successfully'),
            backgroundColor: ColorConstants.successColor,
          ),
        );
      }
    }
  }
  
  void _showAccountDetails(AccountModel account) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AccountDetailsScreen(account: account),
      ),
    );
    // No need to reload data here since we're listening to streams
  }

  Future<void> _showAddTransactionDialog(AccountModel account) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddTransactionScreen(account: account),
      ),
    );
    
    if (result == true) {
      // Show success message if the transaction was added successfully
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction added successfully'),
          backgroundColor: ColorConstants.successColor,
        ),
      );
      // No need to manually reload as we're listening to transaction changes
    }
  }

  @override
  Widget build(BuildContext context) {
    // Check if we're accessed from the bottom navigation tab
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final bool fromTab = args != null && 
                       args is Map<String, dynamic> && 
                       args.containsKey('fromTab') && 
                       args['fromTab'] == true;
    
    return WillPopScope(
      // Handle back button behavior
      onWillPop: () async {
        if (fromTab) {
          // Navigate back to dashboard without removing routes from stack
          Navigator.pushReplacementNamed(
            context, 
            AppRouter.dashboard,
            arguments: {'initialTab': 0}
          );
          return false;
        }
        // Normal back button behavior for non-tab navigation
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        extendBody: true,
        appBar: AppBar(
          elevation: 0,
          title: const Text(
            'Accounts',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          actions: [
            // Add manual refresh button
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh data',
              onPressed: () {
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Data refreshed'),
                    duration: Duration(seconds: 1),
                  ),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: _navigateToAddAccount,
              tooltip: 'Add Account',
            ),
          ],
        ),
        body: SafeArea(
          bottom: false,
          child: RefreshIndicator(
            onRefresh: () async {
              await _loadData();
            },
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _accounts.isEmpty
                    ? _buildEmptyState()
                    : _buildAccountsList(),
          ),
        ),
        floatingActionButton: Container(
          height: 52,
          width: 52,
          margin: const EdgeInsets.only(bottom: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                ColorConstants.primaryColor,
                ColorConstants.primaryColor.withOpacity(0.8),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: ColorConstants.primaryColor.withOpacity(0.3),
                blurRadius: 10,
                spreadRadius: 2,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _navigateToAddAccount,
              customBorder: const CircleBorder(),
              child: const Center(
                child: Icon(
                  Icons.add,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: BottomAppBar(
            shape: const CircularNotchedRectangle(),
            notchMargin: 8.0,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildNavItem(0, Icons.dashboard_outlined, 'Home', () {
                    Navigator.pushNamed(context, AppRouter.dashboard);
                  }),
                  _buildNavItem(1, Icons.account_balance_wallet_outlined, 'Accounts', () {
                    // Already on accounts
                  }),
                  const SizedBox(width: 40), // Space for FAB
                  _buildNavItem(2, Icons.category_outlined, 'Categories', () {
                    Navigator.pushNamed(context, AppRouter.categories);
                  }),
                  _buildNavItem(3, Icons.bar_chart_outlined, 'Reports', () {
                    Navigator.pushNamed(context, AppRouter.reports);
                  }),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
            ),
            child: IntrinsicHeight(
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              ColorConstants.primaryColor.withOpacity(0.1),
                              ColorConstants.primaryColor.withOpacity(0.2),
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 60,
                            color: ColorConstants.primaryColor.withOpacity(0.9),
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      Text(
                        'No accounts yet',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey[800],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          'Add your first account to start tracking your finances with Paisa Track',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                            height: 1.5,
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                      ElevatedButton(
                        onPressed: _navigateToAddAccount,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: ColorConstants.primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: 2,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.add, size: 20),
                            const SizedBox(width: 8),
                            const Text(
                              'Add Account', 
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 80), // Extra space for bottom navigation
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      }
    );
  }
  
  Widget _buildAccountsList() {
    // Group accounts by type
    final bankAccounts = _accounts.where((a) => a.type == AccountType.bank).toList();
    final cashAccounts = _accounts.where((a) => a.type == AccountType.cash).toList();
    final digitalWalletAccounts = _accounts.where((a) => a.type == AccountType.digitalWallet).toList();
    
    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: _buildAccountsSummary(),
        ),
        
        // Bank accounts section
        if (bankAccounts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader('Bank Accounts', bankAccounts.length),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildAccountCard(bankAccounts[index]),
              childCount: bankAccounts.length,
            ),
          ),
        ],
        
        // Cash accounts section
        if (cashAccounts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader('Cash Accounts', cashAccounts.length),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildAccountCard(cashAccounts[index]),
              childCount: cashAccounts.length,
            ),
          ),
        ],
        
        // Digital wallet accounts section
        if (digitalWalletAccounts.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: _buildSectionHeader('Digital Wallets', digitalWalletAccounts.length),
          ),
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildAccountCard(digitalWalletAccounts[index]),
              childCount: digitalWalletAccounts.length,
            ),
          ),
        ],
        
        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 120),
        ),
      ],
    );
  }
  
  Widget _buildAccountsSummary() {
    final totalBalance = _accountRepository.getTotalBalance();
    final currencySymbol = CurrencyUtils.getCurrencySymbol(_defaultCurrencyCode);
    
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: ColorConstants.primaryColor,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primaryColor.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Total Balance',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$currencySymbol${totalBalance.toStringAsFixed(2)}',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          Container(
            height: 6,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(3),
            ),
            child: Row(
              children: [
                Container(
                  height: 6,
                  width: MediaQuery.of(context).size.width * 0.5, // Simplified
                  decoration: BoxDecoration(
                    color: Colors.greenAccent,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildBalanceCard(
                  label: 'Accounts',
                  value: '${_accounts.length}',
                  icon: Icons.credit_card,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildBalanceCard(
                  label: 'Active',
                  value: '${_accounts.where((a) => a.balance > 0).length}',
                  icon: Icons.check_circle_outline,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildBalanceCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.8),
                  fontSize: 12,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildSectionHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: ColorConstants.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: ColorConstants.primaryColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAccountCard(AccountModel account) {
    // Get currency symbol
    final currencySymbol = CurrencyUtils.getCurrencySymbol(_defaultCurrencyCode);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: () => _showAccountDetails(account),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Account icon/logo
                account.bankLogoPath != null && account.bankLogoPath!.isNotEmpty
                  ? ClipOval(
                      child: Image.asset(
                        account.bankLogoPath!,
                        width: 48,
                        height: 48,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          print('Error loading account logo: ${account.bankLogoPath}, error: $error');
                          return _buildAccountIcon(account);
                        },
                      ),
                    )
                  : _buildAccountIcon(account),
                const SizedBox(width: 16),
                
                // Account name and type
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        account.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: account.color.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              account.type.name.toUpperCase(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: account.color,
                              ),
                            ),
                          ),
                          if (account.accountHolderName != null && account.accountHolderName!.isNotEmpty) ...[
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                account.type == AccountType.digitalWallet ? 
                                  "Owner: ${account.accountHolderName!}" : 
                                  "Holder: ${account.accountHolderName!}",
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Account balance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$currencySymbol${account.balance.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                        color: account.balance >= 0 ? Colors.black : Colors.red,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.arrow_circle_up_outlined, 
                          size: 14,
                          color: ColorConstants.successColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTransactionStats(account.id, TransactionType.income),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Icon(
                          Icons.arrow_circle_down_outlined, 
                          size: 14,
                          color: ColorConstants.errorColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getTransactionStats(account.id, TransactionType.expense),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
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
  
  Widget _buildAccountIcon(AccountModel account) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: account.color.withOpacity(0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(
        account.icon,
        color: account.color,
        size: 24,
      ),
    );
  }
  
  // Helper method to mask account number for privacy
  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length <= 4) return accountNumber;
    return '••••${accountNumber.substring(accountNumber.length - 4)}';
  }

  Future<void> _showEditAccountDialog(AccountModel account) async {
    final updatedAccount = await showDialog<AccountModel>(
      context: context,
      builder: (context) => EditAccountDialog(account: account),
    );
    
    if (updatedAccount != null) {
      try {
        // Update the account in the repository
        await _accountRepository.updateAccount(updatedAccount);
        
        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${updatedAccount.name} updated successfully'),
              backgroundColor: ColorConstants.successColor,
            ),
          );
          
          // Refresh the accounts list
          _loadData();
        }
      } catch (e) {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error updating account: $e'),
              backgroundColor: ColorConstants.errorColor,
            ),
          );
        }
      }
    }
  }

  Future<void> _showDeleteAccountConfirmation(AccountModel account) async {
    final hasTransactions = _transactionRepository.getTransactionsByAccount(account.id).isNotEmpty;
    
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to delete "${account.name}"?'),
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
                          'This account has transactions. Deleting it will also remove all associated transactions.',
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
          final transactions = _transactionRepository.getTransactionsByAccount(account.id);
          for (final transaction in transactions) {
            await _transactionRepository.deleteTransaction(transaction.id);
          }
        }
        
        // Then delete the account
        await _accountRepository.deleteAccount(account.id);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${account.name} has been deleted'),
            backgroundColor: ColorConstants.successColor,
          ),
        );
        
        // Refresh the accounts list
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting account: $e'),
            backgroundColor: ColorConstants.errorColor,
          ),
        );
      }
    }
  }

  String _getTransactionStats(String accountId, TransactionType type) {
    // Calculate the current month's transactions of the given type
    final now = DateTime.now();
    final startOfMonth = DateTime(now.year, now.month, 1);
    final endOfMonth = DateTime(now.year, now.month + 1, 0);
    
    double total = 0;
    
    if (type == TransactionType.income) {
      total = _transactionRepository.calculateTotalIncomeForAccount(
        accountId, startOfMonth, endOfMonth);
    } else {
      total = _transactionRepository.calculateTotalExpenseForAccount(
        accountId, startOfMonth, endOfMonth);
    }
    
    return CurrencyUtils.formatCompactCurrency(total, currencyCode: _defaultCurrencyCode);
  }

  Widget _buildNavItem(int index, IconData icon, String label, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: index == 1 ? ColorConstants.primaryColor : Colors.grey,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: index == 1 ? ColorConstants.primaryColor : Colors.grey,
                  fontWeight: index == 1 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 