// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/cash_entry.dart';
import '../services/database_service.dart';
import '../widgets/cash_entry_modal.dart';
import 'edit_cash_entry_screen.dart';

class ReportOfDateScreen extends StatelessWidget {
  final DateTime selectedDate;

  const ReportOfDateScreen({super.key, required this.selectedDate});

  String _getMonthName(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }

  String _formatTimestamp(DateTime dt) {
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    return '${hour.toString().padLeft(2, '0')}:$minute $period';
  }

  void _openAddEntryModal(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CashEntryModal(
        entryType: CashEntryType.cashIn,
        initialDate: selectedDate,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dateKey = '${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}';

    final dailyEntries = dbService.cashEntries.where((entry) {
      final eKey = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
      return eKey == dateKey;
    }).toList();

    double dayCashIn = 0.0;
    double dayCashOut = 0.0;
    for (var e in dailyEntries) {
      if (e.type == CashEntryType.cashIn) {
        dayCashIn += e.amount;
      } else {
        dayCashOut += e.amount;
      }
    }
    final selectedDateBalance = dayCashIn - dayCashOut;

    // Overall total cash in hand vs online
    double totalCashInHand = dbService.netCashBalance;
    double overallTotalBalance = dbService.netCashBalance + dbService.baseOpeningBalance;

    final headerTitle = 'Report of ${selectedDate.day} ${_getMonthName(selectedDate.month)}';

    return Scaffold(
      appBar: AppBar(
        title: Text(headerTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Cards Grid (Total Balance, Selected Date Balance, Cash in Hand, Online)
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 2.2,
                children: [
                  // Total Balance
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Total Balance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppConstants.formatCurrency(overallTotalBalance),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Selected Date Balance
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Selected Date Balance', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppConstants.formatCurrency(selectedDateBalance),
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: selectedDateBalance >= 0 ? AppConstants.cashInColor : AppConstants.cashOutColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Cash in Hand
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Cash in Hand', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppConstants.formatCurrency(totalCashInHand),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.cashInColor),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Online / Bank
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Online / Bank', style: TextStyle(fontSize: 11, color: Colors.grey)),
                        const SizedBox(height: 4),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            AppConstants.formatCurrency(0.0),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              Text(
                'Transactions for ${selectedDate.day} ${_getMonthName(selectedDate.month)} (${dailyEntries.length})',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),

              // Entries List
              Expanded(
                child: dailyEntries.isEmpty
                    ? const Center(child: Text('No transactions recorded for this date.'))
                    : ListView.separated(
                        itemCount: dailyEntries.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final entry = dailyEntries[idx];
                          final isCashIn = entry.type == CashEntryType.cashIn;
                          final color = isCashIn ? AppConstants.cashInColor : AppConstants.cashOutColor;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: isDark ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: color.withValues(alpha: 0.15),
                                child: Icon(
                                  isCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: color,
                                ),
                              ),
                              title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${entry.category} • ${_formatTimestamp(entry.date)}'),
                              trailing: Text(
                                '${isCashIn ? "+" : "-"}${AppConstants.formatCurrency(entry.amount)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => EditCashEntryScreen(entry: entry),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 12),

              // Full-Width ADD ENTRY TO DATE Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_rounded),
                  label: Text(
                    'ADD ENTRY TO ${selectedDate.day} ${_getMonthName(selectedDate.month).toUpperCase()}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  onPressed: () => _openAddEntryModal(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
