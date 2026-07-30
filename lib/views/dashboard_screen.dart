// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';
import '../core/constants.dart';
import '../models/cash_entry.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/cash_entry_modal.dart';

class DashboardScreen extends StatelessWidget {
  final ValueChanged<int>? onNavigateTab;
  final VoidCallback? onOpenParties;
  final VoidCallback? onOpenBilling;
  final VoidCallback? onOpenStaff;
  final VoidCallback? onOpenReports;

  const DashboardScreen({
    super.key,
    this.onNavigateTab,
    this.onOpenParties,
    this.onOpenBilling,
    this.onOpenStaff,
    this.onOpenReports,
  });

  void _openCashModal(BuildContext context, CashEntryType entryType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CashEntryModal(entryType: entryType),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final authService = Provider.of<AuthService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final userName = dbService.currentUserModel?.fullName ?? '';

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => dbService.fetchAllData(isGuest: authService.isGuestMode),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(left: 18, right: 18, top: 18, bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Hello, ${authService.isGuestMode ? "Guest Manager" : (userName.isNotEmpty ? userName : "Manager")}',
                              style: const TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (authService.isGuestMode) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppConstants.secondaryColor.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: AppConstants.secondaryColor, width: 1),
                                ),
                                child: const Text(
                                  'GUEST',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    color: AppConstants.secondaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Utensils & Hardware Wholesale Accounting',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.notifications_none_rounded),
                    ),
                  ],
                ).animate().fade().slideY(begin: -0.2, end: 0),

                const SizedBox(height: 20),

                if (dbService.isLoading &&
                    dbService.cashEntries.isEmpty &&
                    dbService.inventoryItems.isEmpty &&
                    dbService.parties.isEmpty)
                  _buildShimmerPlaceholder(isDark)
                else ...[
                  // SUMMARY CARD (NET CLOSING BALANCE IN ₹)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(22),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4F46E5), // Indigo
                        Color(0xFF0284C7), // Sky
                      ],
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF4F46E5).withOpacity(0.35),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Net Closing Balance',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.currency_rupee, color: Colors.white, size: 14),
                                SizedBox(width: 2),
                                Text(
                                  'Live Ledger (₹)',
                                  style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      Text(
                        AppConstants.formatCurrency(dbService.closingBalance),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 34,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '= Opening (${AppConstants.formatCurrency(dbService.todaysOpeningBalance)}) + Cash In (${AppConstants.formatCurrency(dbService.todaysCashIn)}) - Cash Out (${AppConstants.formatCurrency(dbService.todaysCashOut)})',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 11,
                        ),
                      ),

                      const SizedBox(height: 18),
                      const Divider(color: Colors.white24, height: 1),
                      const SizedBox(height: 14),

                      // Breakdown Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildMetricItem(
                            label: 'Opening Bal',
                            value: AppConstants.formatCurrency(dbService.todaysOpeningBalance),
                            color: Colors.white,
                          ),
                          Container(width: 1, height: 28, color: Colors.white24),
                          _buildMetricItem(
                            label: "Today's Cash In",
                            value: AppConstants.formatCurrency(dbService.todaysCashIn),
                            color: const Color(0xFFA7F3D0),
                          ),
                          Container(width: 1, height: 28, color: Colors.white24),
                          _buildMetricItem(
                            label: "Today's Cash Out",
                            value: AppConstants.formatCurrency(dbService.todaysCashOut),
                            color: const Color(0xFFFECDD3),
                          ),
                        ],
                      ),
                    ],
                  ),
                ).animate().scale(duration: 350.ms, curve: Curves.easeOutCubic),

                const SizedBox(height: 20),

                // ACTION BUTTONS ROW: CASH IN (+) / CASH OUT (-)
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.cashInColor,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _openCashModal(context, CashEntryType.cashIn),
                          icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                          label: const Text('Cash In (+)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 50,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.cashOutColor,
                            foregroundColor: Colors.white,
                            elevation: 3,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          onPressed: () => _openCashModal(context, CashEntryType.cashOut),
                          icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                          label: const Text('Cash Out (-)', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                  ],
                ).animate().fade().slideY(begin: 0.2, end: 0, delay: 100.ms),

                const SizedBox(height: 24),

                // FEATURE MODULES 2x3 GRID HEADER
                const Text(
                  'Feature Modules & Tools',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                // 2x3 FEATURE SQUARE GRID
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  childAspectRatio: 1.25,
                  children: [
                    // Card 1: Daily CashBook
                    _buildFeatureCard(
                      context,
                      title: 'Daily CashBook',
                      subtitle: 'Track ledger entries',
                      icon: Icons.account_balance_wallet_rounded,
                      color: AppConstants.primaryColor,
                      onTap: () => onNavigateTab?.call(1),
                    ),

                    // Card 2: Unified Parties Ledger
                    _buildFeatureCard(
                      context,
                      title: 'Parties Ledger',
                      subtitle: 'Suppliers & Customers',
                      icon: Icons.people_alt_rounded,
                      color: Colors.orange,
                      badgeText: '${dbService.parties.length}',
                      onTap: onOpenParties,
                    ),

                    // Card 3: Utensils Inventory Stock
                    _buildFeatureCard(
                      context,
                      title: 'Utensils Stock',
                      subtitle: 'Products & GST rates',
                      icon: Icons.inventory_2_rounded,
                      color: AppConstants.secondaryColor,
                      badgeText: '${dbService.inventoryItems.length}',
                      onTap: () => onNavigateTab?.call(2),
                    ),

                    // Card 4: Quick GST Billing
                    _buildFeatureCard(
                      context,
                      title: 'Quick GST Billing',
                      subtitle: 'Create GST invoices',
                      icon: Icons.receipt_long_rounded,
                      color: AppConstants.cashInColor,
                      onTap: onOpenBilling,
                    ),

                    // Card 5: Staff & Attendance
                    _buildFeatureCard(
                      context,
                      title: 'Staff Manager',
                      subtitle: 'Attendance & Payroll',
                      icon: Icons.badge_rounded,
                      color: Colors.purple,
                      badgeText: '${dbService.staffMembers.length}',
                      onTap: onOpenStaff,
                    ),

                    // Card 6: Reports & Analytics
                    _buildFeatureCard(
                      context,
                      title: 'Reports & Audit',
                      subtitle: 'Valuation & Summary',
                      icon: Icons.analytics_rounded,
                      color: Colors.teal,
                      onTap: onOpenReports,
                    ),
                  ],
                ).animate().fade().slideY(begin: 0.1, end: 0, delay: 150.ms),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder(bool isDark) {
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF1E293B) : Colors.grey[300]!,
      highlightColor: isDark ? const Color(0xFF334155) : Colors.grey[100]!,
      child: Column(
        children: [
          Container(
            height: 180,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 14,
            mainAxisSpacing: 14,
            childAspectRatio: 1.15,
            children: List.generate(
              6,
              (index) => Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureCard(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    String? badgeText,
    required VoidCallback? onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: isDark ? const BorderSide(color: Color(0xFF334155), width: 0.8) : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(icon, color: color, size: 24),
                  ),
                  if (badgeText != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        badgeText,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
                      ),
                    ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMetricItem({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11)),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
