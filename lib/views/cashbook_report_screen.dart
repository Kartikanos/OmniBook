// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/cash_entry.dart';
import '../services/database_service.dart';
import 'daily_transactions_screen.dart';

class CashbookReportScreen extends StatefulWidget {
  const CashbookReportScreen({super.key});

  @override
  State<CashbookReportScreen> createState() => _CashbookReportScreenState();
}

class _CashbookReportScreenState extends State<CashbookReportScreen> {
  String _selectedDuration = 'This Month'; // 'This Month', 'Single Day', 'Last Week', 'Last Month', 'All', 'Date Range'
  DateTimeRange? _customDateRange;
  DateTime _singleDate = DateTime.now();

  final List<String> _durationOptions = [
    'This Month',
    'Single Day',
    'Last Week',
    'Last Month',
    'All',
    'Date Range',
  ];

  void _showDurationPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              const Text('Select Duration / Period', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              ..._durationOptions.map((option) {
                final isSelected = _selectedDuration == option;
                return ListTile(
                  title: Text(option, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                  trailing: isSelected ? const Icon(Icons.check_circle_rounded, color: AppConstants.primaryColor) : null,
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    if (option == 'Single Day') {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: _singleDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (picked != null) {
                        setState(() {
                          _selectedDuration = option;
                          _singleDate = picked;
                        });
                      }
                    } else if (option == 'Date Range') {
                      final pickedRange = await showDateRangePicker(
                        context: context,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2030),
                      );
                      if (pickedRange != null) {
                        setState(() {
                          _selectedDuration = option;
                          _customDateRange = pickedRange;
                        });
                      }
                    } else {
                      setState(() {
                        _selectedDuration = option;
                      });
                    }
                  },
                );
              }),
            ],
          ),
        );
      },
    );
  }

  List<CashEntry> _filterEntries(List<CashEntry> allEntries) {
    final now = DateTime.now();
    if (_selectedDuration == 'Single Day') {
      final sKey = '${_singleDate.year}-${_singleDate.month.toString().padLeft(2, '0')}-${_singleDate.day.toString().padLeft(2, '0')}';
      return allEntries.where((e) {
        final eKey = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
        return eKey == sKey;
      }).toList();
    } else if (_selectedDuration == 'This Month') {
      return allEntries.where((e) => e.date.year == now.year && e.date.month == now.month).toList();
    } else if (_selectedDuration == 'Last Month') {
      final lastMonthDate = DateTime(now.year, now.month - 1, 1);
      return allEntries.where((e) => e.date.year == lastMonthDate.year && e.date.month == lastMonthDate.month).toList();
    } else if (_selectedDuration == 'Last Week') {
      final sevenDaysAgo = now.subtract(const Duration(days: 7));
      return allEntries.where((e) => e.date.isAfter(sevenDaysAgo)).toList();
    } else if (_selectedDuration == 'Date Range' && _customDateRange != null) {
      return allEntries.where((e) {
        return e.date.isAfter(_customDateRange!.start.subtract(const Duration(days: 1))) &&
            e.date.isBefore(_customDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }
    return allEntries; // 'All'
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filtered = _filterEntries(dbService.cashEntries);

    double totalIn = 0.0;
    double totalOut = 0.0;
    for (var e in filtered) {
      if (e.type == CashEntryType.cashIn) {
        totalIn += e.amount;
      } else {
        totalOut += e.amount;
      }
    }
    final netBalance = totalIn - totalOut;

    // Group entries by date for Date Breakdown List
    final Map<String, List<CashEntry>> groupedByDate = {};
    for (var e in filtered) {
      final key = '${e.date.year}-${e.date.month.toString().padLeft(2, '0')}-${e.date.day.toString().padLeft(2, '0')}';
      groupedByDate.putIfAbsent(key, () => []).add(e);
    }

    final sortedDates = groupedByDate.keys.toList()..sort((a, b) => b.compareTo(a));

    return Scaffold(
      appBar: AppBar(
        title: const Text('CashBook Ledger Reports'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Duration Filter Card
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_month_rounded, color: AppConstants.primaryColor),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Report Duration', style: TextStyle(fontSize: 11, color: Colors.grey)),
                            Text(_selectedDuration, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                          ],
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      icon: const Icon(Icons.filter_alt_rounded, size: 16),
                      label: const Text('Change'),
                      onPressed: _showDurationPicker,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Summary Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppConstants.primaryColor, AppConstants.secondaryColor],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Total Cash In', style: TextStyle(fontSize: 11, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(AppConstants.formatCurrency(totalIn), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.white30),
                    Column(
                      children: [
                        const Text('Total Cash Out', style: TextStyle(fontSize: 11, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(AppConstants.formatCurrency(totalOut), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.white30),
                    Column(
                      children: [
                        const Text('Net Balance', style: TextStyle(fontSize: 11, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(AppConstants.formatCurrency(netBalance), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              const Text('Daily Balance Breakdown', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),

              // Date Breakdown List
              Expanded(
                child: sortedDates.isEmpty
                    ? const Center(child: Text('No transactions for selected duration.'))
                    : ListView.separated(
                        itemCount: sortedDates.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                        itemBuilder: (ctx, idx) {
                          final dateKey = sortedDates[idx];
                          final entries = groupedByDate[dateKey]!;
                          final d = entries.first.date;

                          double dayIn = 0.0;
                          double dayOut = 0.0;
                          for (var e in entries) {
                            if (e.type == CashEntryType.cashIn) {
                              dayIn += e.amount;
                            } else {
                              dayOut += e.amount;
                            }
                          }
                          final dailyBal = dayIn - dayOut;

                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: isDark ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              title: Text(
                                '${d.day}/${d.month}/${d.year}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              subtitle: Text(
                                '${entries.length} entries • In: ${AppConstants.formatCurrency(dayIn)} | Out: ${AppConstants.formatCurrency(dayOut)}',
                                style: const TextStyle(fontSize: 12),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      const Text('Daily Balance', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                      Text(
                                        AppConstants.formatCurrency(dailyBal),
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 14,
                                          color: dailyBal >= 0 ? AppConstants.cashInColor : AppConstants.cashOutColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 8),
                                  const Icon(Icons.chevron_right_rounded),
                                ],
                              ),
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (ctx) => DailyTransactionsScreen(date: d),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
