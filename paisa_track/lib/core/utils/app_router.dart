import 'package:flutter/material.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/presentation/screens/accounts/account_details_screen.dart';
import 'package:paisa_track/presentation/screens/accounts/accounts_screen.dart';
import 'package:paisa_track/presentation/screens/bills/bills_screen.dart';
import 'package:paisa_track/presentation/screens/budgets/budget_screen.dart';
import 'package:paisa_track/presentation/screens/categories/categories_screen.dart';
import 'package:paisa_track/presentation/screens/categories/category_add_edit_screen.dart';
import 'package:paisa_track/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:paisa_track/presentation/screens/goals/goals_screen.dart';
import 'package:paisa_track/presentation/screens/loans/loans_screen.dart';
import 'package:paisa_track/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:paisa_track/presentation/screens/recurring/recurring_screen.dart';
import 'package:paisa_track/presentation/screens/reports/reports_screen.dart';
import 'package:paisa_track/presentation/screens/scan/receipt_scanner_screen.dart';
import 'package:paisa_track/presentation/screens/settings/settings_screen.dart';
import 'package:paisa_track/presentation/screens/transactions/add_transaction_dialog.dart';
import 'package:paisa_track/presentation/screens/transactions/all_transactions_screen.dart';
import 'package:paisa_track/presentation/screens/transactions/transaction_details_screen.dart';
import 'package:paisa_track/presentation/screens/transactions/transaction_statistics_screen.dart';
import 'package:paisa_track/presentation/screens/user_setup/user_setup_screen.dart';
import 'package:paisa_track/presentation/screens/about/about_screen.dart';

class AppRouter {
  static const String onboarding = '/onboarding';
  static const String userSetup = '/user-setup';
  static const String dashboard = '/';
  static const String accounts = '/accounts';
  static const String accountDetails = '/accounts/details';
  static const String categories = '/categories';
  static const String categoryAddEdit = '/categories/add-edit';
  static const String allTransactions = '/transactions';
  static const String transactionDetails = '/transactions/details';
  static const String addTransaction = '/transactions/add';
  static const String transactionStatistics = '/transactions/statistics';
  static const String settingsRoute = '/settings';
  static const String budgets = '/budgets';
  static const String goals = '/goals';
  static const String loans = '/loans';
  static const String recurring = '/recurring';
  static const String scanReceipt = '/scan-receipt';
  static const String bills = '/bills';
  static const String currencyConverter = '/currency-converter';
  static const String reports = '/reports';
  static const String about = '/about';
  
  static Map<String, WidgetBuilder> routes = {
    dashboard: (_) => const DashboardScreen(),
    accounts: (_) => const AccountsScreen(),
    categories: (_) => const CategoriesScreen(),
    allTransactions: (_) => const AllTransactionsScreen(),
    transactionStatistics: (_) => const TransactionStatisticsScreen(),
    settingsRoute: (_) => const SettingsScreen(),
    budgets: (_) => const BudgetScreen(),
    goals: (_) => const GoalsScreen(),
    loans: (_) => const LoansScreen(),
    recurring: (_) => const RecurringScreen(),
    scanReceipt: (_) => const ReceiptScannerScreen(),
    bills: (_) => const BillsScreen(),
    currencyConverter: (context) => Scaffold(
      appBar: AppBar(title: const Text('Currency Converter')),
      body: const Center(child: Text('Currency Converter coming soon!')),
    ),
    reports: (_) => const ReportsScreen(),
    about: (_) => const AboutScreen(),
  };

  static Route<dynamic> generateRoute(RouteSettings routeSettings) {
    // Extract arguments and check if navigation came from the bottom tab
    final args = routeSettings.arguments as Map<String, dynamic>?;
    final fromTab = args != null && args.containsKey('fromTab') && args['fromTab'] == true;
    
    switch (routeSettings.name) {
      case onboarding:
        return MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
        );
        
      case userSetup:
        return MaterialPageRoute(
          builder: (_) => const UserSetupScreen(),
        );
        
      case dashboard:
        return MaterialPageRoute(
          builder: (_) => const DashboardScreen(),
          maintainState: true,
        );
        
      case accounts:
        if (fromTab) {
          return MaterialPageRoute(
            builder: (_) => const AccountsScreen(),
            maintainState: true,
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => const AccountsScreen(),
          );
        }
        
      case accountDetails:
        final account = routeSettings.arguments as AccountModel;
        return MaterialPageRoute(
          builder: (_) => AccountDetailsScreen(account: account),
        );
        
      case categories:
        return MaterialPageRoute(
          builder: (_) => const CategoriesScreen(),
        );
        
      case categoryAddEdit:
        final isIncome = routeSettings.arguments as bool;
        return MaterialPageRoute(
          builder: (_) => CategoryAddEditScreen(isIncome: isIncome),
        );
        
      case allTransactions:
        return MaterialPageRoute(
          builder: (_) => const AllTransactionsScreen(),
        );
        
      case transactionDetails:
        final transactionId = routeSettings.arguments as String;
        return MaterialPageRoute(
          builder: (_) => TransactionDetailsScreen(transactionId: transactionId),
        );
        
      case addTransaction:
        final account = routeSettings.arguments as AccountModel?;
        return MaterialPageRoute(
          builder: (_) => AddTransactionDialog(account: account),
        );
        
      case transactionStatistics:
        return MaterialPageRoute(
          builder: (_) => const TransactionStatisticsScreen(),
        );
        
      case settingsRoute:
        if (fromTab) {
          return MaterialPageRoute(
            builder: (_) => const SettingsScreen(),
            maintainState: true,
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => const SettingsScreen(),
          );
        }
        
      case budgets:
        return MaterialPageRoute(
          builder: (_) => const BudgetScreen(),
        );
        
      case goals:
        return MaterialPageRoute(
          builder: (_) => const GoalsScreen(),
        );
        
      case loans:
        return MaterialPageRoute(
          builder: (_) => const LoansScreen(),
        );
        
      case recurring:
        return MaterialPageRoute(
          builder: (_) => const RecurringScreen(),
        );
        
      case scanReceipt:
        return MaterialPageRoute(
          builder: (_) => const ReceiptScannerScreen(),
        );
        
      case bills:
        return MaterialPageRoute(
          builder: (_) => const BillsScreen(),
        );
        
      case currencyConverter:
        return MaterialPageRoute(
          builder: (context) => Scaffold(
            appBar: AppBar(title: const Text('Currency Converter')),
            body: const Center(child: Text('Currency Converter coming soon!')),
          ),
        );
        
      case reports:
        if (fromTab) {
          return MaterialPageRoute(
            builder: (_) => const ReportsScreen(),
            maintainState: true,
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => const ReportsScreen(),
          );
        }
        
      case about:
        return MaterialPageRoute(
          builder: (_) => const AboutScreen(),
        );
        
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${routeSettings.name}'),
            ),
          ),
        );
    }
  }
} 