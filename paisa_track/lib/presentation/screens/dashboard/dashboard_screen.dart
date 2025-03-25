import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:math' as math;
import 'dart:async';
import 'package:flutter/animation.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/constants/text_constants.dart';
import 'package:paisa_track/core/utils/app_router.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/enums/duration_filter.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/transaction_model.dart';
import 'package:paisa_track/data/models/enums/account_type.dart';
import 'package:paisa_track/data/models/user_profile_model.dart';
import 'package:paisa_track/data/repositories/account_repository.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';
import 'package:paisa_track/presentation/screens/transactions/add_transaction_screen.dart';
import 'package:paisa_track/presentation/widgets/common/loading_indicator.dart';
import 'package:paisa_track/presentation/widgets/common/error_view.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:provider/provider.dart';
import 'package:paisa_track/providers/auth_provider.dart';
import 'package:paisa_track/providers/user_profile_provider.dart';
import 'package:paisa_track/data/models/app_icon.dart';
import '../../../data/services/update_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> with SingleTickerProviderStateMixin {
  final AccountRepository _accountRepository = AccountRepository();
  final TransactionRepository _transactionRepository = TransactionRepository();
  final UserRepository _userRepository = UserRepository();
  
  // Animation controllers
  late AnimationController _pulseAnimationController;
  
  // Animations
  late Animation<double> _pulseAnimation;
  
  bool _isLoading = true;
  bool _showBalance = true;
  String? _error;
  List<AccountModel> _accounts = [];
  
  // Financial data
  double _totalBalance = 0;
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _lastMonthIncome = 0;
  double _lastMonthExpense = 0;
  
  // User data
  String _userName = '';
  String? _profileImagePath;
  String _currencyCode = 'USD'; // Default currency code
  
  // Transactions
  List<TransactionModel> _recentTransactions = [];
  
  // Add this key as a class field
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  // Add a state variable to track expanded state
  bool _quickActionsExpanded = false;
  
  // Add these properties to the class
  int _loginStreak = 0;
  DateTime? _lastLoginDate;
  bool _hasNotifications = false;
  
  // Add the scrollController
  final ScrollController _scrollController = ScrollController();
  
  // Add a navigation key to keep track of nested navigation
  final GlobalKey<NavigatorState> _dashboardNavigatorKey = GlobalKey<NavigatorState>();
  
  // Add the PageController for tab navigation
  final PageController _pageController = PageController(initialPage: 0);
  
  // Add this variable to track the last time back was pressed
  DateTime? _lastBackPressTime;
  
  @override
  void initState() {
    super.initState();
    _loadData();
    _initializeUserData();
    _initializeAnimations();
    
    // Initialize data first, then set up stream listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Listeners are set up after the first build
      _setupStreamListeners();
      
      // Check for updates when the screen loads
      UpdateService.checkForUpdates(context);
    });
  }
  
  void _setupStreamListeners() {
    // Listen to transaction changes
    _transactionRepository.transactionsChanged.listen((_) {
      debugPrint("Dashboard: Transaction change detected!");
      if (mounted) {
        _loadData();
      }
    });
    
    // Listen to account changes
    _accountRepository.accountsChanged.listen((_) {
      debugPrint("Dashboard: Account change detected!");
      if (mounted) {
        _loadData();
      }
    });
  }
  
  void _initializeAnimations() {
    // Remove pulse animation controller for FAB
    // Only keep necessary animations for other elements
  }

  @override
  void dispose() {
    // Ensure resources are properly cleaned up
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null; // Reset error on new load attempt
    });
    
    try {
      // Get user info - always reload this to ensure we have the latest data
      final userProfile = await _userRepository.getUserProfile();
      print('User Profile: ${userProfile?.name}, Has Image: ${userProfile?.profileImagePath != null}'); // Debug log
      
      // Get accounts - use getAllAccounts instead of getAllAccountsAsync
      final accounts = _accountRepository.getAllAccounts();
      
      // Get total balance
      final totalBalance = await _accountRepository.getTotalBalanceAsync();
      
      // Get current month's income and expenses
      final now = DateTime.now();
      final startOfMonth = DateTime(now.year, now.month, 1);
      final endOfMonth = DateTime(now.year, now.month + 1, 0);
      
      final totalIncome = _transactionRepository.calculateTotalIncome(startOfMonth, endOfMonth);
      final totalExpense = _transactionRepository.calculateTotalExpense(startOfMonth, endOfMonth);
      
      // Get last month's income and expenses
      final startOfLastMonth = DateTime(now.year, now.month - 1, 1);
      final endOfLastMonth = DateTime(now.year, now.month, 0);
      
      final lastMonthIncome = _transactionRepository.calculateTotalIncome(startOfLastMonth, endOfLastMonth);
      final lastMonthExpense = _transactionRepository.calculateTotalExpense(startOfLastMonth, endOfLastMonth);
      
      // Get recent transactions
      final recentTransactions = _transactionRepository.getAllTransactionsSorted();
      final limitedTransactions = 
          recentTransactions.length > 5 ? recentTransactions.sublist(0, 5) : recentTransactions;
      
      // Update state if component is still mounted
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _userName = userProfile?.name ?? 'User';
          _profileImagePath = userProfile?.profileImagePath;
          _currencyCode = userProfile?.defaultCurrencyCode ?? 'USD'; // Set currency code from user profile
          print('Profile Image Path: $_profileImagePath'); // Debug log
          if (_profileImagePath != null) {
            final file = File(_profileImagePath!);
            print('File exists: ${file.existsSync()}');
          }
          _totalBalance = totalBalance;
          _totalIncome = totalIncome;
          _totalExpense = totalExpense;
          _lastMonthIncome = lastMonthIncome;
          _lastMonthExpense = lastMonthExpense;
          _recentTransactions = limitedTransactions;
          _isLoading = false;
        });
      }
    } catch (e) {
      // Handle error
      print('Error loading dashboard data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load data. Please try again.';
        });
      }
    }
  }
  
  void _toggleBalanceVisibility() {
    setState(() {
      _showBalance = !_showBalance;
    });
  }
  
  String _getTimeBasedGreeting() {
    final hour = DateTime.now().hour;
    
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
  
  double _calculateIncomeChange() {
    if (_lastMonthIncome == 0) {
      return _totalIncome > 0 ? 100 : 0; // If no last month income but current income exists, show 100% increase
    }
    return ((_totalIncome - _lastMonthIncome) / _lastMonthIncome) * 100;
  }
  
  double _calculateExpenseChange() {
    if (_lastMonthExpense == 0) {
      return _totalExpense > 0 ? 100 : 0; // If no last month expense but current expense exists, show 100% increase
    }
    return ((_totalExpense - _lastMonthExpense) / _lastMonthExpense) * 100;
  }

  Future<void> _initializeUserData() async {
    // Load login streak
    _loginStreak = await _userRepository.getLoginStreak() ?? 0;
    _lastLoginDate = await _userRepository.getLastLoginDate();
    
    // Update login streak
    await _updateLoginStreak();
    
    // Check for notifications
    await _checkForNotifications();
    
    setState(() {});
  }
  
  Future<void> _updateLoginStreak() async {
    final today = DateTime.now();
    final yesterday = today.subtract(Duration(days: 1));
    
    // If it's the first login
    if (_lastLoginDate == null) {
      _loginStreak = 1;
      await _userRepository.saveLoginStreak(_loginStreak);
      await _userRepository.saveLastLoginDate(today);
      return;
    }
    
    // Check if the last login was yesterday or today
    final lastLoginDate = DateTime(
      _lastLoginDate!.year, 
      _lastLoginDate!.month, 
      _lastLoginDate!.day
    );
    
    final todayDate = DateTime(today.year, today.month, today.day);
    final yesterdayDate = DateTime(yesterday.year, yesterday.month, yesterday.day);
    
    if (lastLoginDate.isAtSameMomentAs(todayDate)) {
      // Already logged in today, do nothing
      return;
    } else if (lastLoginDate.isAtSameMomentAs(yesterdayDate)) {
      // Consecutive login, increment streak
      _loginStreak++;
    } else {
      // Missed a day, reset streak
      _loginStreak = 1;
    }
    
    // Save updated streak and last login date
    await _userRepository.saveLoginStreak(_loginStreak);
    await _userRepository.saveLastLoginDate(today);
  }
  
  Future<void> _checkForNotifications() async {
    bool hasUnprocessedTransactions = await _transactionRepository.hasUnprocessedTransactions();
    bool? hasNewFeatures = await _userRepository.hasNewFeatures() ?? false;
    
    setState(() {
      _hasNotifications = hasUnprocessedTransactions || hasNewFeatures;
    });
    
    // Mark transactions as processed
    if (hasUnprocessedTransactions) {
      await _transactionRepository.markTransactionsAsProcessed();
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<void>(
      stream: _transactionRepository.transactionsChanged,
      builder: (context, txSnapshot) {
        return StreamBuilder<void>(
          stream: _accountRepository.accountsChanged,
          builder: (context, accSnapshot) {
            // Always reload data when either stream emits an event
            if (txSnapshot.connectionState == ConnectionState.active || 
                accSnapshot.connectionState == ConnectionState.active) {
              print("Stream event detected in Dashboard, reloading data...");
              // Use Future.microtask to avoid build phase errors
              Future.microtask(() => _loadData());
            }
            
            return WillPopScope(
              onWillPop: _onWillPop,
              child: Scaffold(
                key: _scaffoldKey,
                appBar: _buildAppBar(),
                drawer: _buildDrawer(),
                backgroundColor: Theme.of(context).scaffoldBackgroundColor,
                body: _isLoading 
                  ? const LoadingIndicator() 
                  : (_error != null 
                      ? ErrorView(message: _error!, onRetry: _loadData) 
                      : _buildDashboardContent()),
                floatingActionButton: _buildFloatingActionButton(),
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
                            // Already on dashboard
                          }),
                          _buildNavItem(1, Icons.account_balance_wallet_outlined, 'Accounts', () {
                            Navigator.pushNamed(context, AppRouter.accounts);
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
        );
      }
    );
  }
  
  Widget _buildUserSectionCompact() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.primaryColor,
            ColorConstants.primaryColor.withBlue(220),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          _buildProfileAvatar(),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      _getGreeting(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8, 
                        vertical: 2
                      ),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: ColorConstants.accentColor.withOpacity(0.3),
                      ),
                      child: Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _userName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.local_fire_department,
                      color: Colors.orange,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$_loginStreak days',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProfileAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 4,
            spreadRadius: 0,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white,
                  Colors.white.withOpacity(0.9),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white,
                width: 2,
              ),
            ),
            child: ClipOval(
              child: _profileImagePath != null
                  ? Image.file(
                      File(_profileImagePath!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          size: 26,
                          color: ColorConstants.primaryColor,
                        );
                      },
                    )
                  : Icon(
                      Icons.person,
                      size: 26,
                      color: ColorConstants.primaryColor,
                    ),
            ),
          ),
          // Notification indicator
          if (_hasNotifications)
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          // Streak badge
          if (_loginStreak > 0)
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                width: 15,
                height: 15,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: _loginStreak >= 30 
                        ? [Colors.orange, Colors.amber]
                        : [Colors.blue.shade300, Colors.blue.shade600],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _loginStreak >= 30 ? Icons.star : Icons.local_fire_department,
                    size: 7,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
  
  String _getGreeting() {
    final now = DateTime.now();
    String greeting = "Hello";
    if (now.hour < 12) {
      greeting = "Good Morning";
    } else if (now.hour < 17) {
      greeting = "Good Afternoon";
    } else {
      greeting = "Good Evening";
    }
    return greeting;
  }
  
  Widget _buildTotalBalanceCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            ColorConstants.primaryColor,
            ColorConstants.primaryColor.withBlue(220),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: ColorConstants.primaryColor.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Text(
                  'Total Balance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _showBalance ? Icons.visibility : Icons.visibility_off,
                    color: Colors.white,
                    size: 22,
                  ),
                  onPressed: _toggleBalanceVisibility,
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _showBalance 
                ? CurrencyUtils.formatCurrency(_totalBalance, currencyCode: _currencyCode)
                : '••••••••',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                return Container(
                  height: 6,
                  width: constraints.maxWidth,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: Row(
                    children: [
                      Container(
                        height: 6,
                        width: _totalBalance > 0 
                            ? constraints.maxWidth * (_totalExpense / _totalBalance).clamp(0.0, 1.0)
                            : 0,
                        decoration: BoxDecoration(
                          color: Colors.redAccent,
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildBalanceStatCardModern(
                    'Income',
                    _totalIncome,
                    Icons.arrow_downward_rounded,
                    Colors.green.shade300,
                    _calculateIncomeChange(),
                  ),
                ),
                Container(
                  height: 40,
                  width: 1,
                  color: Colors.white.withOpacity(0.2),
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                ),
                Expanded(
                  child: _buildBalanceStatCardModern(
                    'Expenses',
                    _totalExpense,
                    Icons.arrow_upward_rounded,
                    Colors.red.shade300,
                    _calculateExpenseChange(),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildBalanceStatCardModern(
    String label, 
    double amount, 
    IconData icon, 
    Color color,
    double changePercent,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                size: 14,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            _showBalance ? CurrencyUtils.formatCurrency(amount, currencyCode: _currencyCode) : '••••••••',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (changePercent == 0 && (label == 'Income' ? _lastMonthIncome == 0 : _lastMonthExpense == 0))
          Text(
            'No data',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.7),
            ),
          )
        else
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                changePercent >= 0 ? Icons.trending_up : Icons.trending_down,
                size: 12,
                color: Colors.white,
              ),
              const SizedBox(width: 4),
              Text(
                "${changePercent.abs().toStringAsFixed(1)}% ${changePercent >= 0 ? 'up' : 'down'}",
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
      ],
    );
  }
  
  Widget _buildQuickAccess() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              // Primary actions (always visible)
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 16,
                childAspectRatio: 0.85,
                children: [
                  // Row 1
                  _buildQuickAction(
                    context,
                    icon: Icons.account_balance_wallet,
                    label: 'Accounts',
                    iconColor: Colors.blue,
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.accounts);
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.category,
                    label: 'Categories',
                    iconColor: Colors.orange,
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.categories);
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.add_circle_outline,
                    label: 'Add',
                    iconColor: Colors.green,
                    onTap: () {
                      _addTransaction();
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.bar_chart,
                    label: 'Reports',
                    iconColor: Colors.purple,
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.reports);
                    },
                  ),
                  
                  // Row 2
                  _buildQuickAction(
                    context,
                    icon: Icons.savings,
                    label: 'Budget',
                    iconColor: Colors.teal,
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.budgets);
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.flag,
                    label: 'Goals',
                    iconColor: Colors.amber,
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.goals);
                    },
                  ),
                  _buildQuickAction(
                    context,
                    icon: Icons.swap_horiz,
                    label: 'Transfer',
                    iconColor: Colors.cyan,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const AddTransactionScreen(
                            initialType: TransactionType.transfer,
                          ),
                        ),
                      );
                      
                      if (result == true) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Transfer added successfully'),
                            backgroundColor: ColorConstants.successColor,
                          ),
                        );
                        // No need to reload manually as we're listening to streams
                      }
                    },
                  ),
                  // Expand/collapse button
                  _buildQuickAction(
                    context,
                    icon: _quickActionsExpanded ? Icons.expand_less : Icons.expand_more,
                    label: _quickActionsExpanded ? 'Less' : 'More',
                    iconColor: Colors.grey,
                    onTap: () {
                      setState(() {
                        _quickActionsExpanded = !_quickActionsExpanded;
                      });
                    },
                  ),
                ],
              ),
              
              // Additional actions (visible when expanded)
              if (_quickActionsExpanded) ...[
                const SizedBox(height: 16),
                const Divider(height: 1),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 4,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.85,
                  children: [
                    // Additional actions
                    _buildQuickAction(
                      context,
                      icon: Icons.money,
                      label: 'Loans',
                      iconColor: Colors.deepOrange,
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.loans);
                      },
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.repeat,
                      label: 'Recurring',
                      iconColor: Colors.indigo,
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.recurring);
                      },
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.calendar_today,
                      label: 'Bills',
                      iconColor: Colors.brown,
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.bills);
                      },
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.camera_alt,
                      label: 'Scan',
                      iconColor: Colors.pink,
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.scanReceipt);
                      },
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.currency_exchange,
                      label: 'Currency',
                      iconColor: Colors.deepPurple,
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.currencyConverter);
                      },
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.search,
                      label: 'Search',
                      iconColor: Colors.indigo,
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.allTransactions);
                      },
                    ),
                    _buildQuickAction(
                      context,
                      icon: Icons.settings,
                      label: 'Settings',
                      iconColor: Colors.blueGrey,
                      onTap: () {
                        Navigator.pushNamed(context, AppRouter.settingsRoute);
                      },
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildQuickAction(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.allTransactions);
              },
              icon: const Icon(Icons.arrow_forward, size: 16),
              label: const Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: ColorConstants.primaryColor,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                minimumSize: const Size(0, 0),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: _recentTransactions.isEmpty
              ? Container(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      Icon(
                        Icons.receipt_long,
                        size: 48,
                        color: Colors.grey.withOpacity(0.5),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'No transactions yet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Add your first transaction using the + button',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: _recentTransactions.map((transaction) {
                      return _buildTransactionItemModern(transaction);
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
  
  Widget _buildTransactionItemModern(TransactionModel transaction) {
    final dateFormat = DateFormat('MMM d');
    bool isLastItem = _recentTransactions.last.id == transaction.id;
    
    return AnimatedOpacity(
      opacity: 1.0,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeIn,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          border: !isLastItem ? Border(
            bottom: BorderSide(
              color: Colors.grey.withOpacity(0.15),
              width: 1,
            ),
          ) : null,
        ),
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          minVerticalPadding: 0,
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: _getCategoryColor(transaction).withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getCategoryIcon(transaction),
              color: _getCategoryColor(transaction),
              size: 18,
            ),
          ),
          title: Text(
            transaction.description,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Text(
            '${_getAccountName(transaction.accountId)} • ${dateFormat.format(transaction.date)}',
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          trailing: Text(
            (_showBalance ? CurrencyUtils.formatCurrency(transaction.amount, currencyCode: _currencyCode) : '••••••••'),
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: _getAmountColor(transaction),
            ),
          ),
          onTap: () {
            Navigator.pushNamed(
              context,
              AppRouter.transactionDetails,
              arguments: transaction.id,
            ).then((result) {
              if (result == true) {
                _loadData();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Transaction updated successfully'),
                    backgroundColor: ColorConstants.successColor,
                  ),
                );
              }
            });
          },
        ),
      ),
    );
  }
  
  Color _getCategoryColor(TransactionModel transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return ColorConstants.successColor;
      case TransactionType.expense:
        return ColorConstants.errorColor;
      case TransactionType.transfer:
        return ColorConstants.infoColor;
      default:
        return Colors.grey;
    }
  }
  
  IconData _getCategoryIcon(TransactionModel transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return Icons.arrow_downward;
      case TransactionType.expense:
        return Icons.arrow_upward;
      case TransactionType.transfer:
        return Icons.swap_horiz;
      default:
        return Icons.attach_money;
    }
  }
  
  String _getAccountName(String accountId) {
    final account = _accountRepository.getAccountById(accountId);
    return account?.name ?? 'Unknown Account';
  }
  
  Color _getAmountColor(TransactionModel transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return ColorConstants.successColor;
      case TransactionType.expense:
        return ColorConstants.errorColor;
      case TransactionType.transfer:
        return ColorConstants.infoColor;
      default:
        return Colors.grey;
    }
  }
  
  void _navigateToAccountsScreen({bool showAddDialog = false}) {
    Navigator.pushNamed(
      context, 
      AppRouter.accounts,
      arguments: {
        'showAddDialog': showAddDialog,
      },
    );
  }

  Widget _buildAccountsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Accounts',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: ColorConstants.primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${_accounts.length}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: ColorConstants.primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _navigateToAccountsScreen,
                icon: const Icon(Icons.visibility, size: 16),
                label: const Text('View All'),
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                ),
              ),
            ],
          ),
        ),
        _accounts.isEmpty
            ? _buildEmptyAccountsState()
            : _buildAccountsCarousel(),
      ],
    );
  }

  Widget _buildEmptyAccountsState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.account_balance_wallet_outlined,
            size: 48,
            color: Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No accounts yet',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first account to start tracking your finances',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey.shade600,
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _navigateToAccountsScreen(showAddDialog: true),
            icon: const Icon(Icons.add),
            label: const Text('Add Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: ColorConstants.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsCarousel() {
    // Calculate total balance instead of max balance
    double totalBalance = 0;
    if (_accounts.isNotEmpty) {
      totalBalance = _accounts.fold(0, (sum, account) => sum + account.balance);
    }

    return SizedBox(
      height: 245,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: _accounts.length + 1,
        itemBuilder: (context, index) {
          if (index == _accounts.length) {
            return _buildAddAccountCard();
          }
          final account = _accounts[index];
          return _buildAccountCard(account, totalBalance);
        },
      ),
    );
  }

  Widget _buildAddAccountCard() {
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      width: 140,
      height: 220,
      child: Card(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: ColorConstants.primaryColor.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToAccountsScreen(showAddDialog: true),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: ColorConstants.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.add,
                    color: ColorConstants.primaryColor,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Add Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: ColorConstants.primaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAccountCard(AccountModel account, double totalBalance) {
    // Calculate percentage based on total balance instead of max balance
    final balancePercentage = totalBalance > 0 ? (account.balance / totalBalance).clamp(0.0, 1.0) : 0.0;
    final currencySymbol = CurrencyUtils.getCurrencySymbol(_currencyCode);
    
    return Container(
      margin: const EdgeInsets.only(right: 8, bottom: 8),
      width: 250,
      child: Card(
        elevation: 8,
        shadowColor: account.color.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () => Navigator.pushNamed(context, AppRouter.accounts),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  account.color.withOpacity(0.9),
                  account.color,
                  Color.lerp(account.color, Colors.black, 0.3) ?? account.color,
                ],
                stops: const [0.0, 0.6, 1.0],
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Account Type Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      account.bankLogoPath != null && account.bankLogoPath!.isNotEmpty
                        ? ClipOval(
                            child: Image.asset(
                              account.bankLogoPath!,
                              width: 18,
                              height: 18,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  account.icon,
                                  color: Colors.white,
                                  size: 18,
                                );
                              },
                            ),
                          )
                        : Icon(
                            account.icon,
                            color: Colors.white,
                            size: 18,
                          ),
                      const SizedBox(width: 8),
                      Text(
                        account.type.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                
                // Account Name
                Text(
                  account.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    letterSpacing: 0.5,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 12),
                
                // Balance
                Text(
                  'Balance',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _showBalance 
                      ? '$currencySymbol${account.balance.toStringAsFixed(2)}'
                      : '••••••••',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 24,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 16),
                
                // Progress Bar Section
                Text(
                  '${(balancePercentage * 100).toStringAsFixed(1)}% of total', // Changed to 1 decimal place
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 6),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return Stack(
                      children: [
                        // Background
                        Container(
                          height: 8,
                          width: constraints.maxWidth,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        // Progress
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeInOut,
                          height: 8,
                          width: constraints.maxWidth * balancePercentage,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.white.withOpacity(0.5),
                                blurRadius: 8,
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton() {
    return Container(
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
          onTap: _addTransaction,
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
    );
  }

  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _buildDrawerHeader(),
          _buildDrawerItem(
            icon: Icons.dashboard,
            title: 'Dashboard',
            onTap: () {
              Navigator.pop(context);
            },
          ),
          _buildDrawerItem(
            icon: Icons.account_balance,
            title: 'Accounts',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.accounts);
            },
          ),
          _buildDrawerItem(
            icon: Icons.receipt_long,
            title: 'Transactions',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.allTransactions);
            },
          ),
          _buildDrawerItem(
            icon: Icons.category,
            title: 'Categories',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.categories);
            },
          ),
          _buildDrawerItem(
            icon: Icons.savings,
            title: 'Budget',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.budgets);
            },
          ),
          const Divider(height: 1),
          _buildDrawerItem(
            icon: Icons.flag,
            title: 'Goals',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.goals);
            },
          ),
          _buildDrawerItem(
            icon: Icons.money,
            title: 'Loans',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.loans);
            },
          ),
          _buildDrawerItem(
            icon: Icons.repeat,
            title: 'Recurring',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.recurring);
            },
          ),
          _buildDrawerItem(
            icon: Icons.calendar_today,
            title: 'Bills',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.bills);
            },
          ),
          const Divider(height: 1),
          _buildDrawerItem(
            icon: Icons.bar_chart,
            title: 'Reports',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.reports);
            },
          ),
          _buildDrawerItem(
            icon: Icons.currency_exchange,
            title: 'Currency Converter',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.currencyConverter);
            },
          ),
          _buildDrawerItem(
            icon: Icons.camera_alt,
            title: 'Scan Receipt',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.scanReceipt);
            },
          ),
          const Divider(height: 1),
          _buildDrawerItem(
            icon: Icons.settings,
            title: 'Settings',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.settingsRoute);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('About'),
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, AppRouter.about);
            },
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerHeader() {
    final userProfile = context.read<UserProfileProvider>().userProfile;
    
    return DrawerHeader(
      decoration: BoxDecoration(
        color: Theme.of(context).primaryColor,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // User avatar or default icon
              if (userProfile?.profileImagePath != null)
                CircleAvatar(
                  radius: 32,
                  backgroundImage: FileImage(File(userProfile!.profileImagePath!)),
                )
              else
                AppIcon(
                  size: 64,
                  primaryColor: Colors.white,
                  secondaryColor: Colors.white.withOpacity(0.8),
                  backgroundColor: Theme.of(context).primaryColor.withOpacity(0.7),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfile?.name ?? 'Welcome',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (userProfile != null)
                      Text(
                        'Currency: ${userProfile.defaultCurrencyCode}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(
        icon,
        size: 20,
        color: Colors.black,
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.normal,
          color: Colors.black,
        ),
      ),
      dense: true,
      onTap: onTap,
      visualDensity: const VisualDensity(horizontal: -2, vertical: -2),
    );
  }

  // Add missing methods
  Future<void> _refreshData() async {
    await _loadData();  // Use the existing _loadData method instead
    setState(() {});
  }

  // Add the missing _buildDashboardContent method
  Widget _buildDashboardContent() {
    return RefreshIndicator(
      onRefresh: _refreshData,
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            _buildUserSectionCompact(),
            const SizedBox(height: 24),
            _buildTotalBalanceCard(),
            const SizedBox(height: 24),
            _buildQuickAccess(),
            const SizedBox(height: 24),
            _buildRecentTransactions(),
            const SizedBox(height: 24),
            _buildAccountsList(),
            const SizedBox(height: 100), // Extra space for FAB and bottom nav
          ],
        ),
      ),
    );
  }

  // Add this method to show menu options
  void _showDashboardMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(20),
            topRight: Radius.circular(20),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 10),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh),
              title: const Text('Refresh Dashboard'),
              onTap: () {
                Navigator.pop(context);
                _loadData();
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility),
              title: Text(_showBalance ? 'Hide Balance' : 'Show Balance'),
              onTap: () {
                Navigator.pop(context);
                _toggleBalanceVisibility();
              },
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Search Transactions'),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRouter.allTransactions);
              },
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
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
                color: index == 0 ? ColorConstants.primaryColor : Colors.grey,
                size: 22,
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: index == 0 ? ColorConstants.primaryColor : Colors.grey,
                  fontWeight: index == 0 ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Update navigation for the FAB + button
  void _addTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );
    
    if (result == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Transaction added successfully'),
          backgroundColor: ColorConstants.successColor,
        ),
      );
      // No need to reload manually as we're listening to streams
    }
  }

  // Find the AppBar and add a reload button
  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Paisa Track'),
      actions: [
        // Add a reload button
        IconButton(
          icon: const Icon(Icons.refresh),
          tooltip: 'Reload data',
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
          icon: const Icon(Icons.search),
          onPressed: () {
            // TODO: Implement search
          },
        ),
        IconButton(
          icon: const Icon(Icons.settings),
          onPressed: () {
            Navigator.pushNamed(context, AppRouter.settingsRoute);
          },
        ),
      ],
    );
  }

  Future<bool> _onWillPop() {
    final now = DateTime.now();
    if (_lastBackPressTime == null || 
        now.difference(_lastBackPressTime!) > const Duration(seconds: 2)) {
      _lastBackPressTime = now;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Press back again to exit'),
          duration: Duration(seconds: 2),
        ),
      );
      return Future.value(false);
    }
    return Future.value(true);
  }
}

// Replace the ShimmerLoading implementation with a more stable version
class ShimmerLoading extends StatefulWidget {
  final Color baseColor;
  final Color highlightColor;

  const ShimmerLoading({
    Key? key,
    required this.baseColor,
    required this.highlightColor,
  }) : super(key: key);

  @override
  _ShimmerLoadingState createState() => _ShimmerLoadingState();
}

class _ShimmerLoadingState extends State<ShimmerLoading> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                widget.baseColor,
                widget.highlightColor,
                widget.baseColor,
              ],
              stops: const [0.0, 0.5, 1.0],
              begin: Alignment(-1.0 + (2.0 * _controller.value), 0),
              end: Alignment(1.0 + (2.0 * _controller.value), 0),
            ),
          ),
        );
      },
    );
  }
}

// Fix WavePainter animation for stability
class WavePainter extends CustomPainter {
  final Color color;
  final double waveHeight;
  final double progress;

  WavePainter({
    required this.color,
    required this.waveHeight,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    
    // Use a simpler implementation to avoid math errors
    // Calculate a safe y value based on progress
    final safeProgress = progress.clamp(0.0, 1.0);
    final y = size.height * (1 - safeProgress);

    // Simple wave design
    path.moveTo(0, y);
    
    // First curve
    path.quadraticBezierTo(
      size.width / 4, 
      y - waveHeight,
      size.width / 2, 
      y
    );
    
    // Second curve
    path.quadraticBezierTo(
      size.width * 3 / 4, 
      y + waveHeight,
      size.width, 
      y
    );
    
    // Complete the path
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(WavePainter oldDelegate) => 
      color != oldDelegate.color ||
      waveHeight != oldDelegate.waveHeight ||
      progress != oldDelegate.progress;
} 