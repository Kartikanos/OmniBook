import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/database_service.dart';
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
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      dbService.fetchAllData(isGuest: authService.isGuestMode);
    });
  }

  void _openPage(Widget page) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: DashboardScreen(
        onOpenCashbook: () => _openPage(const CashbookScreen()),
        onOpenParties: () => _openPage(const PartiesScreen()),
        onOpenInventory: () => _openPage(const InventoryScreen()),
        onOpenBilling: () => _openPage(const GstBillingScreen()),
        onOpenStaff: () => _openPage(const StaffManagerScreen()),
        onOpenReports: () => _openPage(const ReportsScreen()),
        onOpenSettings: () => _openPage(const SettingsScreen()),
      ),
    );
  }
}
