import 'package:flutter/material.dart';
import 'package:paisa_track/data/models/account_model.dart';
import 'package:paisa_track/data/models/category_model.dart';
import 'package:paisa_track/data/models/enums/transaction_type.dart';
import 'package:paisa_track/data/models/loan_model.dart';
import 'package:paisa_track/presentation/screens/accounts/account_details_screen.dart';
import 'package:paisa_track/presentation/screens/accounts/accounts_screen.dart';
import 'package:paisa_track/presentation/screens/accounts/add_account_screen.dart';
import 'package:paisa_track/presentation/screens/accounts/edit_account_screen.dart';
import 'package:paisa_track/presentation/screens/bills/bills_screen.dart';
import 'package:paisa_track/presentation/screens/budgets/budget_screen.dart';
import 'package:paisa_track/presentation/screens/categories/categories_screen.dart';
import 'package:paisa_track/presentation/screens/categories/category_add_edit_screen.dart';
import 'package:paisa_track/presentation/screens/categories/category_details_screen.dart';
import 'package:paisa_track/presentation/screens/dashboard/dashboard_screen.dart';
import 'package:paisa_track/presentation/screens/goals/goals_screen.dart';
import 'package:paisa_track/presentation/screens/loans/loans_screen.dart';
import 'package:paisa_track/presentation/screens/loans/add_loan_screen.dart';
import 'package:paisa_track/presentation/screens/loans/loan_details_screen.dart';
import 'package:paisa_track/presentation/screens/loans/add_loan_payment_screen.dart';
import 'package:paisa_track/presentation/screens/onboarding/onboarding_screen.dart';
import 'package:paisa_track/presentation/screens/recurring/recurring_screen.dart';
import 'package:paisa_track/presentation/screens/recurring/recurring_transactions_screen.dart';
import 'package:paisa_track/presentation/screens/recurring/add_edit_recurring_transaction.dart';
import 'package:paisa_track/presentation/screens/reports/reports_screen.dart';
import 'package:paisa_track/presentation/screens/scan/receipt_scanner_screen.dart';
import 'package:paisa_track/presentation/screens/settings/settings_screen.dart';
import 'package:paisa_track/presentation/screens/settings/modern_settings_screen.dart';
import 'package:paisa_track/presentation/screens/settings/currency_settings_screen.dart';
import 'package:paisa_track/presentation/screens/splash_screen.dart';
import 'package:paisa_track/presentation/screens/transactions/add_transaction_screen.dart';
import 'package:paisa_track/presentation/screens/transactions/all_transactions_screen.dart';
import 'package:paisa_track/presentation/screens/transactions/transaction_details_screen.dart';
import 'package:paisa_track/presentation/screens/transactions/transaction_statistics_screen.dart';
import 'package:paisa_track/presentation/screens/transactions/transaction_history_export_screen.dart';
import 'package:paisa_track/presentation/screens/user_setup/user_setup_screen.dart';
import 'package:paisa_track/presentation/screens/about/about_screen.dart';
import 'package:paisa_track/presentation/screens/bills/add_bill_screen.dart';
import 'package:paisa_track/presentation/screens/bills/edit_bill_screen.dart';
import 'package:paisa_track/presentation/screens/bills/bill_details_screen.dart';
import 'package:paisa_track/presentation/screens/settings/privacy_settings_screen.dart';
import 'package:paisa_track/presentation/screens/settings/profile_edit_screen.dart';
import 'package:paisa_track/presentation/screens/settings/support_screen.dart';
import 'package:paisa_track/presentation/screens/settings/terms_policy_screen.dart';
import 'package:paisa_track/presentation/screens/settings/notification_settings_screen.dart';
import 'package:paisa_track/presentation/screens/settings/notification_test_screen.dart';
import 'package:paisa_track/tests/biometric_test.dart';
import 'package:paisa_track/presentation/screens/settings/backup_restore_screen.dart';

class AppRouter {
  static const String onboarding = '/onboarding';
  static const String userSetup = '/user-setup';
  static const String splash = '/splash';
  static const String dashboard = '/';
  static const String accounts = '/accounts';
  static const String accountDetails = '/accounts/details';
  static const String categories = '/categories';
  static const String categoryAddEdit = '/categories/add-edit';
  static const String allTransactions = '/transactions';
  static const String transactionDetails = '/transactions/details';
  static const String addTransaction = '/transactions/add';
  static const String transactionStatistics = '/transactions/statistics';
  static const String transactionHistoryExport = '/transaction-history-export';
  static const String settingsRoute = '/settings';
  static const String modernSettingsRoute = '/settings/modern';
  static const String privacySettingsRoute = '/settings/privacy';
  static const String profileEditRoute = '/settings/profile-edit';
  static const String supportRoute = '/settings/support';
  static const String termsAndPolicyRoute = '/settings/terms-privacy';
  static const String notificationSettingsRoute = '/settings/notifications';
  static const String notificationTestRoute = '/settings/notifications/test';
  static const String currencySettingsRoute = '/settings/currency';
  static const String budgets = '/budgets';
  static const String goals = '/goals';
  static const String loans = '/loans';
  static const String addLoanScreen = '/loans/add';
  static const String loanDetailsScreen = '/loans/details';
  static const String addLoanPaymentScreen = '/loans/payment/add';
  static const String addAccountScreen = '/accounts/add';
  static const String recurring = '/recurring';
  static const String recurringTransactions = '/recurring/transactions';
  static const String addRecurringTransaction = '/recurring/transactions/add';
  static const String editRecurringTransaction = '/recurring/transactions/edit';
  static const String scanReceipt = '/scan-receipt';
  static const String bills = '/bills';
  static const String currencyConverter = '/currency-converter';
  static const String reports = '/reports';
  static const String about = '/about';
  static const String billsScreen = '/bills';
  static const String addBill = '/bills/add';
  static const String editBill = '/bills/edit';
  static const String billDetails = '/bills/details';
  static const String tags = '/tags';
  static const String analytics = '/analytics';
  static const String biometricTestRoute = '/biometric_test';
  static const String backupRestoreRoute = '/settings/backup-restore';
  
  static Map<String, WidgetBuilder> routes = {
    dashboard: (_) => const DashboardScreen(),
    accounts: (_) => const AccountsScreen(),
    categories: (_) => const CategoriesScreen(),
    allTransactions: (_) => const AllTransactionsScreen(),
    transactionStatistics: (_) => const TransactionStatisticsScreen(),
    transactionHistoryExport: (_) => const TransactionHistoryExportScreen(),
    settingsRoute: (_) => const ModernSettingsScreen(),
    modernSettingsRoute: (_) => const ModernSettingsScreen(),
    privacySettingsRoute: (_) => const PrivacySettingsScreen(),
    profileEditRoute: (_) => const ProfileEditScreen(),
    supportRoute: (_) => const SupportScreen(),
    termsAndPolicyRoute: (_) => const TermsAndPolicyScreen(),
    notificationSettingsRoute: (_) => const NotificationSettingsScreen(),
    notificationTestRoute: (_) => const NotificationTestScreen(),
    currencySettingsRoute: (_) => const CurrencySettingsScreen(),
    budgets: (_) => const BudgetScreen(),
    goals: (_) => const GoalsScreen(),
    loans: (context) => LoansScreen.builder(context),
    recurring: (_) => const RecurringScreen(),
    recurringTransactions: (_) => const RecurringTransactionsScreen(),
    scanReceipt: (_) => const ReceiptScannerScreen(),
    bills: (context) => BillsScreen.builder(context),
    splash: (_) => const SplashScreen(),
    currencyConverter: (context) => const CurrencySettingsScreen(),
    reports: (_) => const ReportsScreen(),
    about: (_) => const AboutScreen(),
    tags: (context) => Scaffold(
      appBar: AppBar(title: const Text('Tags')),
      body: const Center(child: Text('Tags feature coming soon!')),
    ),
    analytics: (context) => Scaffold(
      appBar: AppBar(title: const Text('Analytics')),
      body: const Center(child: Text('Analytics feature coming soon!')),
    ),
    biometricTestRoute: (_) => const BiometricTestScreen(),
    backupRestoreRoute: (_) => const BackupRestoreScreen(),
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
        
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
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
        final args = routeSettings.arguments;
        
        // Handle different argument types
        if (args is Map<String, dynamic>) {
          // Map arguments - could contain 'account' and/or 'initialType'
          return MaterialPageRoute(
            settings: routeSettings,
            builder: (_) => AddTransactionScreen(
              account: args.containsKey('account') ? args['account'] as AccountModel : null,
              initialType: args.containsKey('initialType') ? args['initialType'] as TransactionType : null,
            ),
          );
        } else if (args is AccountModel) {
          // Direct account model
          return MaterialPageRoute(
            settings: routeSettings,
            builder: (_) => AddTransactionScreen(account: args),
          );
        } else {
          // No arguments, use defaults
          return MaterialPageRoute(
            settings: routeSettings,
            builder: (_) => const AddTransactionScreen(),
          );
        }
        
      case transactionStatistics:
        return MaterialPageRoute(
          builder: (_) => const TransactionStatisticsScreen(),
        );
        
      case transactionHistoryExport:
        return MaterialPageRoute(
          builder: (_) => const TransactionHistoryExportScreen(),
        );
        
      case settingsRoute:
        if (fromTab) {
          return MaterialPageRoute(
            builder: (_) => const ModernSettingsScreen(),
            maintainState: true,
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => const ModernSettingsScreen(),
          );
        }
        
      case modernSettingsRoute:
        if (fromTab) {
          return MaterialPageRoute(
            builder: (_) => const ModernSettingsScreen(),
            maintainState: true,
          );
        } else {
          return MaterialPageRoute(
            builder: (_) => const ModernSettingsScreen(),
          );
        }
        
      case privacySettingsRoute:
        return MaterialPageRoute(
          builder: (_) => const PrivacySettingsScreen(),
        );
        
      case profileEditRoute:
        return MaterialPageRoute(
          builder: (_) => const ProfileEditScreen(),
        );
        
      case supportRoute:
        return MaterialPageRoute(
          builder: (_) => const SupportScreen(),
        );
        
      case termsAndPolicyRoute:
        return MaterialPageRoute(
          builder: (_) => const TermsAndPolicyScreen(),
        );
        
      case notificationSettingsRoute:
        return MaterialPageRoute(
          builder: (_) => const NotificationSettingsScreen(),
        );
        
      case notificationTestRoute:
        return MaterialPageRoute(
          builder: (_) => const NotificationTestScreen(),
        );
        
      case currencySettingsRoute:
        return MaterialPageRoute(
          builder: (_) => const CurrencySettingsScreen(),
        );
        
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
          builder: (context) => LoansScreen.builder(context),
        );
        
      case recurring:
        return MaterialPageRoute(
          builder: (_) => const RecurringScreen(),
        );
        
      case recurringTransactions:
        return MaterialPageRoute(
          builder: (_) => const RecurringTransactionsScreen(),
        );
        
      case addRecurringTransaction:
        return MaterialPageRoute(
          builder: (_) => const AddEditRecurringTransactionScreen(),
        );
        
      case editRecurringTransaction:
        final transactionId = args as String;
        return MaterialPageRoute(
          builder: (_) => AddEditRecurringTransactionScreen(transactionId: transactionId),
        );
        
      case scanReceipt:
        return MaterialPageRoute(
          builder: (_) => const ReceiptScannerScreen(),
        );
        
      case bills:
        return MaterialPageRoute(
          builder: (context) => BillsScreen.builder(context),
        );
        
      case reports:
        return MaterialPageRoute(
          builder: (_) => const ReportsScreen(),
        );
        
      case currencyConverter:
        return MaterialPageRoute(
          builder: (_) => const CurrencySettingsScreen(),
        );
        
      case about:
        return MaterialPageRoute(
          builder: (_) => const AboutScreen(),
        );
        
      case tags:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Tags')),
            body: const Center(child: Text('Tags feature coming soon!')),
          ),
        );
        
      case analytics:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text('Analytics')),
            body: const Center(child: Text('Analytics feature coming soon!')),
          ),
        );
        
      case billsScreen:
        return MaterialPageRoute(builder: (context) => BillsScreen.builder(context));
      
      case addBill:
        return MaterialPageRoute(builder: (context) => AddBillScreen.builder(context));
      
      case editBill:
        final billId = args as String;
        return MaterialPageRoute(builder: (context) => EditBillScreen.builder(context, billId));
      
      case billDetails:
        final billId = args as String;
        return MaterialPageRoute(builder: (context) => BillDetailsScreen.builder(context, billId));
        
      case addLoanScreen:
        return MaterialPageRoute(builder: (_) => const AddLoanScreen());
      
      case loanDetailsScreen:
        final loanId = args as String;
        return MaterialPageRoute(builder: (context) => LoanDetailsScreen.builder(context, loanId));
      
      case addLoanPaymentScreen:
        final loanId = args as String;
        return MaterialPageRoute(builder: (context) => AddLoanPaymentScreen.builder(context, loanId));
      
      case addAccountScreen:
        return MaterialPageRoute(builder: (_) => const AddAccountScreen());
        
      case biometricTestRoute:
        return MaterialPageRoute(builder: (_) => const BiometricTestScreen());
        
      case backupRestoreRoute:
        return MaterialPageRoute(
          builder: (_) => const BackupRestoreScreen(),
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