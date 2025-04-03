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
import 'package:paisa_track/data/repositories/category_repository.dart';
import 'package:paisa_track/data/repositories/transaction_repository.dart';
import 'package:paisa_track/data/repositories/user_repository.dart';
import 'package:paisa_track/presentation/screens/transactions/add_transaction_screen.dart';
import 'package:paisa_track/presentation/screens/transactions/transaction_details_screen.dart';
import 'package:paisa_track/presentation/widgets/common/loading_indicator.dart';
import 'package:paisa_track/presentation/widgets/common/error_view.dart';
import 'package:paisa_track/core/utils/currency_utils.dart';
import 'package:provider/provider.dart';
import 'package:paisa_track/providers/auth_provider.dart';
import 'package:paisa_track/providers/user_profile_provider.dart';
import 'package:paisa_track/data/models/app_icon.dart';
import '../../../data/services/update_service.dart';
import 'package:paisa_track/providers/currency_provider.dart';
import 'package:paisa_track/data/services/profile_fix_service.dart';
import 'package:paisa_track/presentation/screens/accounts/account_details_screen.dart';
import 'package:paisa_track/presentation/screens/accounts/edit_transaction_dialog.dart';

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
  AnimationController? _pulseAnimationController;
  
  // Animations
  Animation<double>? _pulseAnimation;
  
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

  // Add debounce timer
  Timer? _debounceTimer;
  bool _isDataStale = false;

  @override
  void initState() {
    super.initState();
    
    // Initialize animations first to avoid late initialization errors
    _initializeAnimations();
    
    _loadData();
    _initializeUserData();
    
    // Add this line to check and fix currency issues
    _checkAndFixCurrencyIssues();
    
    // Initialize data first, then set up stream listeners
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Listeners are set up after the first build
      _setupStreamListeners();
      
      // Check for updates silently in the background only if enabled
      UpdateService.shouldCheckForUpdates().then((shouldCheck) {
        if (shouldCheck) {
          UpdateService.checkForUpdates(context).catchError((error) {
            debugPrint('Background update check failed: $error');
          });
        } else {
          debugPrint('Skipping automatic update check - disabled by user or cooldown period not elapsed');
        }
      });
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _debounceTimer?.cancel();
    _pulseAnimationController?.dispose();
    super.dispose();
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

  void _markDataAsStale() {
    if (!mounted) return;
    
    setState(() {
      _isDataStale = true;
    });

    // Cancel any existing timer
    _debounceTimer?.cancel();
    
    // Set a new timer to reload data after 500ms of no changes
    _debounceTimer = Timer(const Duration(milliseconds: 500), () {
      if (mounted && _isDataStale) {
        _loadData();
        setState(() {
          _isDataStale = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: const Color(0xFF000000),
        appBar: AppBar(
          backgroundColor: const Color(0xFF000000),
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: false,
          title: Text(
            'Paisa Track',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 26,
            ),
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.search_outlined, 
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.allTransactions);
              },
            ),
            IconButton(
              icon: Icon(
                Icons.settings_outlined, 
                color: Colors.white,
              ),
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.modernSettingsRoute);
              },
            ),
          ],
        ),
        body: _isLoading 
          ? const LoadingIndicator() 
          : (_error != null 
              ? ErrorView(message: _error!, onRetry: _loadData) 
              : _buildDashboardContent()),
        floatingActionButton: SizedBox(
          width: 64,
          height: 64,
          child: FloatingActionButton(
            onPressed: _addTransaction,
            backgroundColor: const Color(0xFF00925B),
            child: const Icon(
              Icons.add,
              color: Colors.white,
              size: 32,
            ),
          ),
        ),
        bottomNavigationBar: SizedBox(
          height: 70,
          child: Theme(
            data: Theme.of(context).copyWith(
              canvasColor: const Color(0xFF000000),
              splashColor: Colors.transparent,
              highlightColor: Colors.transparent,
            ),
            child: BottomNavigationBar(
              backgroundColor: const Color(0xFF000000),
              type: BottomNavigationBarType.fixed,
              selectedItemColor: const Color(0xFF00B37E),
              unselectedItemColor: Colors.grey,
              selectedFontSize: 12,
              unselectedFontSize: 12,
              iconSize: 24,
              selectedLabelStyle: const TextStyle(height: 1.5),
              unselectedLabelStyle: const TextStyle(height: 1.5),
              elevation: 0,
              currentIndex: 0,
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  label: 'Home',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.account_balance_wallet_outlined),
                  label: 'Accounts',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.grid_view_outlined),
                  label: 'Categories',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.sync_outlined),
                  label: 'Reports',
                ),
              ],
              onTap: (index) {
                if (index == 0) {
                  // Already on dashboard
                } else if (index == 1) {
                  Navigator.pushNamed(context, AppRouter.accounts);
                } else if (index == 2) {
                  Navigator.pushNamed(context, AppRouter.categories);
                } else if (index == 3) {
                  Navigator.pushNamed(context, AppRouter.reports);
                }
              },
            ),
          ),
        ),
      ),
    );
  }

  void _initializeAnimations() {
    try {
      // Dispose existing controller if it exists to prevent memory leaks
      _pulseAnimationController?.dispose();
      
      // Initialize pulse animation controller for background effects
      _pulseAnimationController = AnimationController(
        vsync: this,
        duration: const Duration(seconds: 10),
      );
      
      // Start the animation and make it repeat
      _pulseAnimationController!.repeat();
      
      _pulseAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
        CurvedAnimation(
          parent: _pulseAnimationController!,
          curve: Curves.easeInOut,
        ),
      );
      
      debugPrint("Animation controller initialized successfully");
    } catch (e) {
      debugPrint("Error initializing animations: $e");
      // Set controller to null if initialization failed
      _pulseAnimationController = null;
      _pulseAnimation = null;
    }
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    
    setState(() {
      _isLoading = true;
      _error = null;
    });
    
    try {
      // Get user info
      final userProfile = await _userRepository.getUserProfile();
      final userCurrencyCode = userProfile?.defaultCurrencyCode ?? 'USD';
      debugPrint("Loading dashboard with currency: $userCurrencyCode");
      
      // Get accounts
      final accounts = _accountRepository.getAllAccounts();
      debugPrint("Found ${accounts.length} accounts");
      
      // Get total balance with user's currency code
      final totalBalance = await _accountRepository.getTotalBalanceAsync(currencyCode: userCurrencyCode);
      debugPrint("Total balance in $userCurrencyCode: $totalBalance");
      
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
      
      // Get recent transactions (show more transactions now that we have more space)
      final recentTransactions = _transactionRepository.getAllTransactionsSorted();
      final limitedTransactions = 
          recentTransactions.length > 8 ? recentTransactions.sublist(0, 8) : recentTransactions;
      
      if (mounted) {
        setState(() {
          _accounts = accounts;
          _userName = userProfile?.name ?? 'User';
          _profileImagePath = userProfile?.profileImagePath;
          _currencyCode = userCurrencyCode;
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
      debugPrint('Error loading dashboard data: $e');
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

  Widget _buildUserSectionCompact() {
    final userRepository = UserRepository();
    final greeting = _getTimeBasedGreeting();
    
    return FutureBuilder<UserProfileModel?>(
      future: userRepository.getUserProfile(),
      builder: (context, snapshot) {
        final userProfile = snapshot.data;
        
        return Container(
          decoration: BoxDecoration(
            color: const Color(0xFF2D2878), // Darker purple color
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => Navigator.pushNamed(context, AppRouter.profileEditRoute).then((_) {
              // Refresh user data when returning from profile screen
              if (mounted) {
                setState(() {});
                _loadData();
              }
            }),
            borderRadius: BorderRadius.circular(20),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  userProfile?.profileImagePath != null && userProfile!.profileImagePath!.isNotEmpty
                      ? CircleAvatar(
                          radius: 22,
                          backgroundImage: FileImage(File(userProfile.profileImagePath!)),
                        )
                      : Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.person,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          greeting,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.8),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          userProfile?.name ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.15),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        ShaderMask(
                          shaderCallback: (Rect bounds) {
                            return const LinearGradient(
                              colors: [Color(0xFFFF5722), Color(0xFFFFB74D)],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ).createShader(bounds);
                          },
                          child: const Icon(
                            Icons.local_fire_department,
                            color: Colors.white,
                            size: 16,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '$_loginStreak',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }
  
  Widget _buildProfileAvatar() {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.15),
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
                  Theme.of(context).cardColor,
                  Theme.of(context).cardColor.withOpacity(0.9),
                ],
              ),
              shape: BoxShape.circle,
              border: Border.all(
                color: Theme.of(context).cardColor,
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
                          color: Theme.of(context).colorScheme.primary,
                        );
                      },
                    )
                  : Icon(
                      Icons.person,
                      size: 26,
                      color: Theme.of(context).colorScheme.primary,
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
                  color: Theme.of(context).colorScheme.error,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).cardColor,
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
                        : [Theme.of(context).colorScheme.secondary, Theme.of(context).colorScheme.secondary.withOpacity(0.7)],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).cardColor,
                    width: 1.5,
                  ),
                ),
                child: Center(
                  child: Icon(
                    _loginStreak >= 30 ? Icons.star : Icons.local_fire_department,
                    size: 7,
                    color: Theme.of(context).colorScheme.onSecondary,
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
    // Calculate the percentage changes for income and expense
    double incomeChange = _calculateIncomeChange();
    double expenseChange = _calculateExpenseChange();
    
    // Determine if values are up or down compared to last month
    bool isIncomeDown = incomeChange < 0;
    bool isExpenseDown = expenseChange < 0;
    
    // Use absolute values for display
    double incomeChangeAbs = incomeChange.abs();
    double expenseChangeAbs = expenseChange.abs();
    
    // Calculate ratio for progress bar
    double progressValue = 0.1;
    if (_totalIncome + _totalExpense > 0) {
      progressValue = _totalExpense / (_totalIncome + _totalExpense);
    }
    
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF3A35B1), // Darker purple color
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Total Balance section
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total Balance',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      _showBalance = !_showBalance;
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      _showBalance ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Balance amount
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _showBalance 
                ? CurrencyUtils.formatAmountWithUserCurrency(context, _totalBalance)
                : '••••••••',
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          
          // Progress bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progressValue,
                backgroundColor: Colors.white.withOpacity(0.2),
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.red),
                minHeight: 6,
              ),
            ),
          ),
          
          // Income & Expense section
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.1),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          'Income',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _showBalance
                            ? CurrencyUtils.formatAmountWithUserCurrency(context, _totalIncome)
                            : '••••••',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isIncomeDown ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isIncomeDown ? Colors.red : Colors.green,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${incomeChangeAbs.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: isIncomeDown ? Colors.red : Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 40,
                  color: Colors.white.withOpacity(0.2),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Column(
                      children: [
                        Text(
                          'Expenses',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _showBalance
                            ? CurrencyUtils.formatAmountWithUserCurrency(context, _totalExpense)
                            : '••••••',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              isExpenseDown ? Icons.arrow_downward : Icons.arrow_upward,
                              color: isExpenseDown ? Colors.green : Colors.red,
                              size: 12,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${expenseChangeAbs.toStringAsFixed(1)}%',
                              style: TextStyle(
                                fontSize: 12,
                                color: isExpenseDown ? Colors.green : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuickAccess() {
    // Define only two primary colors for all cards
    final Color primaryColor1 = const Color(0xFF023047);  // Deep blue
    final Color primaryColor2 = const Color(0xFF1E5128);  // Deep green
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildFeatureCard(
                    context,
                    icon: Icons.savings,
                    label: 'Budgets',
                    iconColor: Colors.white,
                    iconBgColor: primaryColor1,
                    count: '0 budgets',
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.budgets);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    icon: Icons.flag,
                    label: 'Goals',
                    iconColor: Colors.white,
                    iconBgColor: primaryColor2,
                    count: '0 active, 0 completed',
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.goals);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    icon: Icons.calendar_today,
                    label: 'Bills',
                    iconColor: Colors.white,
                    iconBgColor: primaryColor1,
                    count: '0 Bills',
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.bills);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: Column(
                children: [
                  _buildFeatureCard(
                    context,
                    icon: Icons.sync_alt,
                    label: 'Loans',
                    iconColor: Colors.white,
                    iconBgColor: primaryColor2,
                    amount: "Rs0.00",
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.loans);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    icon: Icons.repeat,
                    label: 'Recurring',
                    iconColor: Colors.white,
                    iconBgColor: primaryColor1,
                    count: "0 Active",
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.recurring);
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildFeatureCard(
                    context,
                    icon: Icons.currency_exchange,
                    label: 'Currency',
                    iconColor: Colors.white,
                    iconBgColor: primaryColor2,
                    onTap: () {
                      Navigator.pushNamed(context, AppRouter.currencyConverter);
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: _buildFeatureCard(
                context,
                icon: Icons.receipt_long,
                label: 'Transactions',
                iconColor: Colors.white,
                iconBgColor: primaryColor1,
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.allTransactions);
                },
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 1,
              child: _buildFeatureCard(
                context,
                icon: Icons.camera_alt,
                label: 'Scan Receipt',
                iconColor: Colors.white,
                iconBgColor: primaryColor2,
                onTap: () {
                  Navigator.pushNamed(context, AppRouter.scanReceipt);
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Color iconColor,
    required Color iconBgColor,
    String? count,
    String? amount,
    required VoidCallback onTap,
  }) {
    // Define gradient colors based on the icon background color
    final Color gradientStart = _adjustColor(iconBgColor, 0.85);
    final Color gradientEnd = _adjustColor(iconBgColor, 1.15);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [gradientStart, gradientEnd],
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Icon(
                  Icons.arrow_forward_ios,
                  color: Colors.white.withOpacity(0.7),
                  size: 14,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (count != null) ...[
              const SizedBox(height: 6),
              Text(
                count,
                style: TextStyle(
                  color: Colors.white.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
            if (amount != null) ...[
              const SizedBox(height: 6),
              Text(
                amount,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // Helper method to adjust color brightness
  Color _adjustColor(Color color, double factor) {
    final hslColor = HSLColor.fromColor(color);
    final adjustedColor = hslColor.withLightness(
      (hslColor.lightness * factor).clamp(0.0, 1.0)
    ).toColor();
    return adjustedColor;
  }
  
  Widget _buildRecentTransactions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Recent Transactions',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.allTransactions);
              },
              icon: Icon(Icons.arrow_forward, size: 16, color: Theme.of(context).colorScheme.primary),
              label: Text('View All', style: TextStyle(color: Theme.of(context).colorScheme.primary)),
              style: TextButton.styleFrom(
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
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).shadowColor.withOpacity(0.05),
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
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No transactions yet',
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Add your first transaction using the + button',
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _addTransaction,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).colorScheme.primary,
                          foregroundColor: Theme.of(context).colorScheme.onPrimary,
                          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        ),
                        child: const Text('Add Transaction'),
                      ),
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Column(
                    children: [
                      ..._recentTransactions.map((transaction) {
                        return _buildTransactionItemModern(transaction);
                      }).toList(),
                      // Add "View All" button at the bottom
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                          border: Border(
                            top: BorderSide(
                              color: Theme.of(context).dividerColor,
                              width: 1,
                            ),
                          ),
                        ),
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, AppRouter.allTransactions);
                          },
                          child: Text(
                            'View All Transactions',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
      ],
    );
  }
  
  Widget _buildTransactionItemModern(TransactionModel transaction) {
    final dateFormat = DateFormat('MMM d');
    bool isLastItem = _recentTransactions.last.id == transaction.id;
    
    return Dismissible(
      key: Key(transaction.id),
      direction: DismissDirection.horizontal,
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.endToStart) {
          // Show delete confirmation dialog
          await _showDeleteTransactionConfirmation(transaction);
          return false; // Don't dismiss automatically, let the dialog handle it
        } else if (direction == DismissDirection.startToEnd) {
          // Show edit dialog
          await _showEditTransactionDialog(transaction);
          return false; // Don't dismiss automatically, let the dialog handle it
        }
        return false;
      },
      background: Container(
        color: const Color(0xFF00B37E),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerLeft,
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
        color: const Color(0xFFE83F5B),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        alignment: Alignment.centerRight,
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
      child: AnimatedOpacity(
        opacity: 1.0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeIn,
        child: InkWell(
          onTap: () {
            // Navigate to transaction details screen when tapped
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => TransactionDetailsScreen(
                  transactionId: transaction.id,
                ),
              ),
            ).then((_) {
              // Refresh data when returning from details screen
              _loadData();
            });
          },
          child: Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              border: !isLastItem ? Border(
                bottom: BorderSide(
                  color: Theme.of(context).dividerColor,
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
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${_getAccountName(transaction.accountId)} • ${dateFormat.format(transaction.date)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Text(
                _formatAmount(transaction),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: _getTransactionColor(transaction),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
  
  Color _getCategoryColor(TransactionModel transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.primary;
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
  
  Color _getTransactionColor(TransactionModel transaction) {
    switch (transaction.type) {
      case TransactionType.income:
        return Colors.green;
      case TransactionType.expense:
        return Colors.red;
      case TransactionType.transfer:
        return Colors.blue;
      default:
        return Theme.of(context).colorScheme.primary;
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
    final accountsData = _accounts.sublist(0, math.min(3, _accounts.length));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Your Accounts',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              InkWell(
                onTap: () => _navigateToAccountsScreen(),
                borderRadius: BorderRadius.circular(20),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 320, // Reduced from 340px to 320px to match smaller card height
          child: ListView.builder(
            padding: const EdgeInsets.only(left: 16),
            scrollDirection: Axis.horizontal,
            itemCount: accountsData.length,
            itemBuilder: (context, index) {
              final account = accountsData[index];
              final currencySymbol = CurrencyUtils.getUserCurrencySymbol(context);
              
              return _buildAccountCard(account, _totalBalance);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyAccountsState() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).shadowColor.withOpacity(0.05),
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
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
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
                  color: Theme.of(context).textTheme.bodySmall?.color?.withOpacity(0.8),
                ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () => _navigateToAccountsScreen(showAddDialog: true),
            icon: const Icon(Icons.add),
            label: const Text('Add Account'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.primary,
              foregroundColor: Theme.of(context).colorScheme.onPrimary,
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
      height: 320, // Increased from 302 to 320 to accommodate wider cards
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16), // Increased from 12 to 16
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
      margin: const EdgeInsets.only(right: 12),
      width: 300, // Increased from 140 to 300
      height: 220,
      child: Card(
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.3),
        color: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: const Color(0xFF30363D),
            width: 1.5,
          ),
        ),
        child: InkWell(
          onTap: () => _navigateToAccountsScreen(showAddDialog: true),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(24), // Increased from 12 to 24
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 60, // Increased from 50 to 60
                  height: 60, // Increased from 50 to 60
                  decoration: BoxDecoration(
                    color: const Color(0xFF58A6FF).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.add_rounded,
                    color: Color(0xFF58A6FF),
                    size: 36, // Increased from 30 to 36
                  ),
                ),
                const SizedBox(height: 16), // Increased from 12 to 16
                Text(
                  'Add Account',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 18, // Increased from 14 to 18
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
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
    final currencySymbol = CurrencyUtils.getUserCurrencySymbol(context);
    
    // Determine card gradient based on account type
    List<Color> cardGradient;
    
    switch (account.type) {
      case AccountType.bank:
        cardGradient = [
          const Color(0xFF0D1117),
          const Color(0xFF161B22),
          const Color(0xFF21262D),
        ];
        break;
      case AccountType.cash:
        cardGradient = [
          const Color(0xFF0F2417),
          const Color(0xFF133121),
          const Color(0xFF174025),
        ];
        break;
      case AccountType.creditCard:
        cardGradient = [
          const Color(0xFF2D1823),
          const Color(0xFF3C1C2E),
          const Color(0xFF4A2038),
        ];
        break;
      case AccountType.investment:
        cardGradient = [
          const Color(0xFF162447),
          const Color(0xFF1E3163),
          const Color(0xFF26427A),
        ];
        break;
      case AccountType.digitalWallet:
        cardGradient = [
          const Color(0xFF1A2421),
          const Color(0xFF1E3432),
          const Color(0xFF244039),
        ];
        break;
      default:
        cardGradient = [
          const Color(0xFF0D1117),
          const Color(0xFF161B22),
          const Color(0xFF21262D),
        ];
    }
    
    return Container(
      margin: const EdgeInsets.only(right: 12),
      width: 300, // Increased from 250 to 300
      height: 300,
      child: Card(
        elevation: 12,
        shadowColor: Colors.black.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: InkWell(
          onTap: () => _showAccountDetails(account),
          borderRadius: BorderRadius.circular(20),
          child: AnimatedBuilder(
            animation: _pulseAnimationController!,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: cardGradient,
                    stops: const [0.0, 0.6, 1.0],
                  ),
                  border: Border.all(
                    color: const Color(0xFF30363D),
                    width: 1.5,
                  ),
                ),
                padding: const EdgeInsets.all(24), // Increased from 20 to 24
                child: Stack(
                  children: [
                    // Animated background patterns
                    Positioned(
                      top: -20 + 6 * math.sin(_pulseAnimationController!.value * math.pi * 2),
                      right: -15 + 4 * math.cos(_pulseAnimationController!.value * math.pi * 2),
                      child: Container(
                        height: 80,
                        width: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.03 + 0.01 * math.sin(_pulseAnimationController!.value * math.pi)),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: -30 + 8 * math.cos(_pulseAnimationController!.value * math.pi * 2),
                      left: -20 + 6 * math.sin(_pulseAnimationController!.value * math.pi * 2),
                      child: Container(
                        height: 100,
                        width: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.02 + 0.01 * math.cos(_pulseAnimationController!.value * math.pi)),
                        ),
                      ),
                    ),
                    
                    // Account content
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Account Type Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.1),
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
                        const SizedBox(height: 20),
                        
                        // Account Name
                        Text(
                          account.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 22, // Increased from 20 to 22
                            letterSpacing: 0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        
                        // Account Number (masked)
                        if (account.accountNumber != null && account.accountNumber!.isNotEmpty)
                          Text(
                            _showBalance 
                              ? _formatAccountNumber(account.accountNumber!) 
                              : '••••  ••••  ••••  ••••',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                              letterSpacing: 1.0,
                            ),
                          ),
                          
                        const Spacer(),
                        
                        // Balance
                        Text(
                          'Balance',
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _showBalance 
                              ? CurrencyUtils.formatAmountWithUserCurrency(context, account.balance)
                              : '••••••••',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 30, // Increased from 28 to 30
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Progress Bar Section
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(balancePercentage * 100).toStringAsFixed(1)}% of total',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.6),
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              'View Details',
                              style: TextStyle(
                                color: const Color(0xFF58A6FF),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        LayoutBuilder(
                          builder: (context, constraints) {
                            return Stack(
                              children: [
                                // Background
                                Container(
                                  height: 6,
                                  width: constraints.maxWidth,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                                // Progress
                                AnimatedContainer(
                                  duration: const Duration(milliseconds: 500),
                                  curve: Curves.easeInOut,
                                  height: 6,
                                  width: constraints.maxWidth * balancePercentage,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        const Color(0xFF58A6FF),
                                        const Color(0xFF58A6FF).withOpacity(0.7),
                                      ],
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                    ),
                                    borderRadius: BorderRadius.circular(3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: const Color(0xFF58A6FF).withOpacity(0.3),
                                        blurRadius: 4,
                                        offset: const Offset(0, 1),
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
                  ],
                ),
              );
            }
          ),
        ),
      ),
    );
  }
  
  // Helper method to format account number
  String _formatAccountNumber(String accountNumber) {
    // Strip any non-digit characters
    final digitsOnly = accountNumber.replaceAll(RegExp(r'[^\d]'), '');
    
    // If the account number is really short, just return it
    if (digitsOnly.length < 4) return accountNumber;
    
    // For longer account numbers, mask the middle part
    if (digitsOnly.length >= 8) {
      final firstFour = digitsOnly.substring(0, 4);
      final lastFour = digitsOnly.substring(digitsOnly.length - 4);
      
      // Format with spaces between groups of 4 digits
      return '$firstFour  ••••  ••••  $lastFour';
    }
    
    // For medium length account numbers, mask the end
    final firstFour = digitsOnly.substring(0, 4);
    return '$firstFour  ••••';
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
              Navigator.pushNamed(context, AppRouter.modernSettingsRoute);
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
        color: Theme.of(context).colorScheme.primary,
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
                  primaryColor: Theme.of(context).colorScheme.onPrimary,
                  secondaryColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.8),
                  backgroundColor: Theme.of(context).colorScheme.primary.withOpacity(0.7),
                ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userProfile?.name ?? 'Welcome',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (userProfile != null)
                      Text(
                        'Currency: ${userProfile.defaultCurrencyCode}',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onPrimary,
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
        color: Theme.of(context).iconTheme.color,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium,
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
    return Stack(
      children: [
        // Animated background gradient
        Positioned.fill(
          child: AnimatedContainer(
            duration: const Duration(seconds: 20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF050505),
                  const Color(0xFF0A0A0A),
                  const Color(0xFF111111),
                ],
              ),
            ),
          ),
        ),
        
        // Animated circle decoration
        Positioned(
          top: -100,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  const Color(0xFF1A1E21).withOpacity(0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        
        // Content
        RefreshIndicator(
          onRefresh: _refreshData,
          child: SingleChildScrollView(
            controller: _scrollController,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Column(
                key: ValueKey<int>(_accounts.length), // Force animation when data changes
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  _buildUserSectionCompact(),
                  const SizedBox(height: 24),
                  
                  // Animated entrance for the balance card
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 800),
                    offset: const Offset(0, 0), // Starts at final position now but can be animated
                    curve: Curves.easeOutQuart,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 800),
                      opacity: 1.0,
                      curve: Curves.easeOut,
                      child: _buildTotalBalanceCard(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Headline for Quick Access
                  Padding(
                    padding: const EdgeInsets.only(left: 4, bottom: 16),
                    child: Text(
                      'Quick Access',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  
                  // Animated entrance for quick access
                  AnimatedSlide(
                    duration: const Duration(milliseconds: 1000),
                    offset: const Offset(0, 0), // Starts at final position now but can be animated
                    curve: Curves.easeOutCubic,
                    child: AnimatedOpacity(
                      duration: const Duration(milliseconds: 1000),
                      opacity: 1.0,
                      child: _buildQuickAccess(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Show accounts preview if there are accounts
                  if (_accounts.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: Text(
                        'Your Accounts',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    SizedBox(
                      height: 300,
                      child: AnimatedOpacity(
                        duration: const Duration(milliseconds: 1200),
                        opacity: 1.0,
                        child: _buildAccountsCarousel(),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  
                  // Recent transactions section
                  if (_recentTransactions.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 16),
                      child: Text(
                        'Recent Activity',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    AnimatedOpacity(
                      duration: const Duration(milliseconds: 1400),
                      opacity: 1.0,
                      child: _buildRecentTransactions(),
                    ),
                  ],
                  
                  const SizedBox(height: 80), // Add extra padding at the bottom for the navigation bar
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
  
  // Add a floating action chip for quick actions
  Widget _buildFloatingActionChip() {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: const Color(0xFF2E2E2E),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildActionButton(
                  icon: Icons.refresh,
                  onTap: _loadData,
                  tooltip: 'Refresh',
                ),
                _buildActionButton(
                  icon: _showBalance ? Icons.visibility_off : Icons.visibility,
                  onTap: _toggleBalanceVisibility,
                  tooltip: _showBalance ? 'Hide Balance' : 'Show Balance',
                ),
                _buildActionButton(
                  icon: Icons.search,
                  onTap: () => Navigator.pushNamed(context, AppRouter.allTransactions),
                  tooltip: 'Search',
                ),
              ],
            ),
          ),
        );
      }
    );
  }
  
  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required String tooltip,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Container(
            width: 48,
            height: 48,
            alignment: Alignment.center,
            child: Icon(
              icon,
              color: Colors.white.withOpacity(0.9),
              size: 20,
            ),
          ),
        ),
      ),
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

  // Helper method to format transaction amount
  String _formatAmount(TransactionModel transaction) {
    if (!_showBalance) {
      return '••••••••';
    }
    
    final amount = transaction.amount;
    final symbol = CurrencyUtils.getUserCurrencySymbol(context);
    
    if (transaction.type == TransactionType.expense) {
      return '-$symbol${amount.toStringAsFixed(2)}';
    } else if (transaction.type == TransactionType.income) {
      return '+$symbol${amount.toStringAsFixed(2)}';
    } else {
      return '$symbol${amount.toStringAsFixed(2)}';
    }
  }
  
  void _checkAndFixCurrencyIssues() async {
    // Create an instance of the ProfileFixService
    final profileFixService = ProfileFixService();
    
    // Log current profile info
    await profileFixService.logProfileInfo();
    
    // Fix currency if needed silently
    if (mounted) {
      await profileFixService.fixNepaliCurrency(context);
      
      // Reload data with correct currency if needed
      _loadData();
    }
  }

  void _showAccountDetails(AccountModel account) {
    try {
      print('Opening account details for account: ${account.id}, type: ${account.type}, typeIndex: ${account.typeIndex}');
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => AccountDetailsScreen(account: account),
        ),
      );
    } catch (e, stackTrace) {
      print('Error opening account details: $e');
      print('Stack trace: $stackTrace');
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error opening account details: $e'),
          backgroundColor: ColorConstants.errorColor,
        ),
      );
    }
  }

  // Add transaction method
  void _addTransaction() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const AddTransactionScreen(),
      ),
    );
    
    if (result == true) {
      // Force reload data immediately
      if (mounted) {
        _loadData();
      }
    }
  }

  Future<void> _showEditTransactionDialog(TransactionModel transaction) async {
    final account = _accountRepository.getAccountById(transaction.accountId);
    
    if (account == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not find account for this transaction'),
          backgroundColor: Color(0xFFE83F5B),
        ),
      );
      return;
    }
    
    final updatedTransaction = await showDialog<TransactionModel>(
      context: context,
      builder: (BuildContext context) {
        return EditTransactionDialog(
          transaction: transaction,
          account: account,
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
            backgroundColor: Color(0xFF00B37E),
          ),
        );
        
        // Refresh data to update transactions and account balance
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating transaction: $e'),
            backgroundColor: Color(0xFFE83F5B),
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
          backgroundColor: const Color(0xFF121214),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text(
            'Delete Transaction',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to delete this transaction? This action cannot be undone.',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              style: TextButton.styleFrom(foregroundColor: Colors.white70),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: TextButton.styleFrom(foregroundColor: Color(0xFFE83F5B)),
              child: const Text('Delete'),
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
            backgroundColor: Color(0xFF00B37E),
          ),
        );
        
        // Refresh data to update transactions and account balance
        _loadData();
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error deleting transaction: $e'),
            backgroundColor: Color(0xFFE83F5B),
          ),
        );
      }
    }
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