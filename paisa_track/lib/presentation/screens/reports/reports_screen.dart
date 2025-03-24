import 'package:flutter/material.dart';
import 'package:paisa_track/core/constants/color_constants.dart';
import 'package:paisa_track/core/utils/app_router.dart';
import 'package:paisa_track/presentation/screens/reports/budget_report_tab.dart';
import 'package:paisa_track/presentation/screens/reports/transaction_report_tab.dart';
import 'package:paisa_track/presentation/screens/reports/category_report_tab.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
        appBar: AppBar(
          title: const Text('Financial Reports'),
          // If we came from tab navigation, show a home button instead of back
          leading: fromTab 
              ? IconButton(
                  icon: const Icon(Icons.home),
                  onPressed: () {
                    Navigator.pushReplacementNamed(
                      context,
                      AppRouter.dashboard,
                      arguments: {'initialTab': 0}
                    );
                  },
                )
              : null,
          actions: [
            IconButton(
              icon: const Icon(Icons.settings, color: Colors.white),
              onPressed: () {
                Navigator.pushNamed(context, AppRouter.settingsRoute);
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: ColorConstants.primaryColor,
            tabs: const [
              Tab(
                icon: Icon(Icons.account_balance_wallet),
                text: 'Budget',
              ),
              Tab(
                icon: Icon(Icons.swap_horiz),
                text: 'Transactions',
              ),
              Tab(
                icon: Icon(Icons.category),
                text: 'Categories',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [
            BudgetReportTab(),
            TransactionReportTab(),
            CategoryReportTab(),
          ],
        ),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      height: 65,
      margin: const EdgeInsets.fromLTRB(10, 0, 10, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 12,
            spreadRadius: 1,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          Expanded(child: _buildNavItem(0, Icons.dashboard_outlined, 'Home')),
          Expanded(child: _buildNavItem(1, Icons.account_balance_wallet_outlined, 'Accounts')),
          const SizedBox(width: 60), // Space for the FAB
          Expanded(child: _buildNavItem(2, Icons.category_outlined, 'Categories')),
          Expanded(child: _buildNavItem(3, Icons.analytics_outlined, 'Reports', isActive: true)),
        ],
      ),
    );
  }

  Widget _buildNavItem(int index, IconData icon, String label, {bool isActive = false}) {
    return InkWell(
      onTap: () => _onItemTapped(index),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 36,
              width: 36,
              decoration: BoxDecoration(
                color: isActive ? ColorConstants.primaryColor.withOpacity(0.15) : Colors.transparent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 22,
                color: isActive ? ColorConstants.primaryColor : Colors.grey.shade500,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                height: 1.0,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                color: isActive ? ColorConstants.primaryColor : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onItemTapped(int index) {
    if (index == 3) return; // Already on reports tab
    
    // Navigate directly to the appropriate screen based on the selected index
    switch (index) {
      case 0: // Dashboard
        Navigator.pushReplacementNamed(
          context, 
          AppRouter.dashboard,
        );
        break;
      case 1: // Accounts
        Navigator.pushReplacementNamed(
          context, 
          AppRouter.accounts,
          arguments: {'fromTab': true},
        );
        break;
      case 2: // Categories
        Navigator.pushReplacementNamed(
          context, 
          AppRouter.categories,
          arguments: {'fromTab': true},
        );
        break;
    }
  }
} 