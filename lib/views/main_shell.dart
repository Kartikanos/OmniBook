import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
import '../widgets/floating_dock.dart';
import 'dashboard_screen.dart';
import 'cashbook_screen.dart';
import 'inventory_screen.dart';
import 'settings_screen.dart';
import 'parties_screen.dart';
import 'gst_billing_screen.dart';
import 'staff_manager_screen.dart';
import 'reports_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;
  bool _isNavVisible = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      dbService.fetchAllData(isGuest: authService.isGuestMode);
    });
  }

  void _navigateToTab(int index) {
    setState(() {
      _currentIndex = index;
      _isNavVisible = true;
    });
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      DashboardScreen(
        onNavigateTab: _navigateToTab,
        onOpenParties: () => _openPage(const PartiesScreen()),
        onOpenBilling: () => _openPage(const GstBillingScreen()),
        onOpenStaff: () => _openPage(const StaffManagerScreen()),
        onOpenReports: () => _openPage(const ReportsScreen()),
      ),
      const CashbookScreen(),
      const InventoryScreen(),
      const SettingsScreen(),
    ];

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (_currentIndex != 0) {
          // Navigate back to Dashboard tab instead of exiting
          setState(() {
            _currentIndex = 0;
            _isNavVisible = true;
          });
        } else {
          // Already on Dashboard — close the app
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: NotificationListener<UserScrollNotification>(
          onNotification: (notification) {
            if (notification.direction == ScrollDirection.reverse) {
              if (_isNavVisible) {
                setState(() => _isNavVisible = false);
              }
            } else if (notification.direction == ScrollDirection.forward) {
              if (!_isNavVisible) {
                setState(() => _isNavVisible = true);
              }
            }
            return true;
          },
          child: Stack(
            children: [
              // Active Screen view
              IndexedStack(
                index: _currentIndex,
                children: screens,
              ),

              // Animated Auto-Hiding Glassmorphic Floating Dock
              Align(
                alignment: Alignment.bottomCenter,
                child: AnimatedSlide(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  offset: _isNavVisible ? Offset.zero : const Offset(0, 2.5),
                  child: FloatingDock(
                    selectedIndex: _currentIndex,
                    onItemSelected: (index) {
                      setState(() {
                        _currentIndex = index;
                        _isNavVisible = true;
                      });
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
