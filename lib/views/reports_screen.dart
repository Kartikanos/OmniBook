// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';
import '../services/database_service.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Accounting Reports & Summary'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Business Performance', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(
                'Financial summary for Utensils & Hardware operations',
                style: TextStyle(fontSize: 13, color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight),
              ),
              const SizedBox(height: 20),

              // Overview Cards
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: isDark ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: [
                      _buildReportRow(
                        label: 'Total Opening Balance:',
                        value: AppConstants.formatCurrency(dbService.todaysOpeningBalance),
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                      const Divider(height: 24),
                      _buildReportRow(
                        label: 'Lifetime Total Sales / Cash In:',
                        value: AppConstants.formatCurrency(dbService.totalCashIn),
                        color: AppConstants.cashInColor,
                      ),
                      const Divider(height: 24),
                      _buildReportRow(
                        label: 'Lifetime Total Purchases / Cash Out:',
                        value: AppConstants.formatCurrency(dbService.totalCashOut),
                        color: AppConstants.cashOutColor,
                      ),
                      const Divider(height: 24),
                      _buildReportRow(
                        label: 'Net Closing Balance:',
                        value: AppConstants.formatCurrency(dbService.closingBalance),
                        color: AppConstants.primaryAccent,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ).animate().fade().scale(),

              const SizedBox(height: 24),
              const Text('Inventory Stock Valuation', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                  side: isDark ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      _buildReportRow(
                        label: 'Total Unique Utensil Items:',
                        value: '${dbService.inventoryItems.length} Products',
                        color: AppConstants.secondaryColor,
                      ),
                      const Divider(height: 20),
                      _buildReportRow(
                        label: 'Estimated Stock Valuation:',
                        value: AppConstants.formatCurrency(
                          dbService.inventoryItems.fold(0.0, (sum, i) => sum + (i.unitPrice * i.stockQuantity)),
                        ),
                        color: AppConstants.primaryColor,
                        isBold: true,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportRow({
    required String label,
    required String value,
    required Color color,
    bool isBold = false,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: isBold ? 14 : 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w500,
            ),
          ),
        ),
        const SizedBox(width: 8),
        FittedBox(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isBold ? 16 : 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
