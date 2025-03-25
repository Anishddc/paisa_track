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

class _ReportsScreenState extends State<ReportsScreen> with TickerProviderStateMixin {
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
    // Check if accessed from tab navigation
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final bool fromTab = args != null && 
                       args is Map<String, dynamic> && 
                       args.containsKey('fromTab') && 
                       args['fromTab'] == true;
    
    return WillPopScope(
      onWillPop: () async {
        if (fromTab) {
          Navigator.pushReplacementNamed(
            context, 
            AppRouter.dashboard,
            arguments: {'initialTab': 0}
          );
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxScrolled) => [
            SliverAppBar(
              elevation: 0,
              pinned: true,
              floating: true,
              forceElevated: innerBoxScrolled,
              backgroundColor: ColorConstants.primaryColor,
              title: const Text(
                'Reports',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              leading: fromTab 
                ? IconButton(
                    icon: const Icon(Icons.home, color: Colors.white),
                    onPressed: () {
                      Navigator.pushReplacementNamed(
                        context, 
                        AppRouter.dashboard,
                        arguments: {'initialTab': 0}
                      );
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    Navigator.pushNamed(context, AppRouter.settingsRoute);
                  },
                ),
              ],
              expandedHeight: 150.0,
              flexibleSpace: FlexibleSpaceBar(
                background: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        ColorConstants.primaryColor,
                        ColorConstants.primaryColor.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 80, 16, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Financial Reports',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Track your spending patterns and financial health',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              bottom: TabBar(
                controller: _tabController,
                indicatorColor: Colors.white,
                indicatorWeight: 3,
                labelColor: Colors.white,
                unselectedLabelColor: Colors.white.withOpacity(0.7),
                labelStyle: const TextStyle(fontWeight: FontWeight.bold),
                tabs: const [
                  Tab(text: 'Budget'),
                  Tab(text: 'Transactions'),
                  Tab(text: 'Categories'),
                ],
              ),
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: const [
              BudgetReportTab(),
              TransactionReportTab(),
              CategoryReportTab(),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            Navigator.pushNamed(context, AppRouter.addTransaction);
          },
          backgroundColor: ColorConstants.accentColor,
          icon: const Icon(Icons.add),
          label: const Text('Add Transaction'),
        ),
        bottomNavigationBar: fromTab 
          ? BottomAppBar(
              height: 60,
              color: Colors.white,
              elevation: 8,
              notchMargin: 6,
              shape: const CircularNotchedRectangle(),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildBottomNavItem(
                    icon: Icons.category,
                    label: 'Categories',
                    onTap: () {
                      Navigator.pushNamed(
                        context, 
                        AppRouter.categories,
                        arguments: {'fromTab': true}
                      );
                    }
                  ),
                  const SizedBox(width: 48),
                  _buildBottomNavItem(
                    icon: Icons.settings,
                    label: 'Settings',
                    onTap: () {
                      Navigator.pushNamed(
                        context, 
                        AppRouter.settingsRoute,
                        arguments: {'fromTab': true}
                      );
                    }
                  ),
                ],
              ),
            )
          : null,
      ),
    );
  }
  
  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: ColorConstants.primaryColor),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: ColorConstants.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
} 