// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/cash_entry.dart';
import '../services/database_service.dart';

class DailyTransactionsScreen extends StatelessWidget {
  final DateTime date;

  const DailyTransactionsScreen({super.key, required this.date});

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final dateKey = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';

    final dailyEntries = dbService.cashEntries.where((entry) {
      final eKey = '${entry.date.year}-${entry.date.month.toString().padLeft(2, '0')}-${entry.date.day.toString().padLeft(2, '0')}';
      return eKey == dateKey;
    }).toList();

    double totalIn = 0.0;
    double totalOut = 0.0;
    for (var e in dailyEntries) {
      if (e.type == CashEntryType.cashIn) {
        totalIn += e.amount;
      } else {
        totalOut += e.amount;
      }
    }
    final netDaily = totalIn - totalOut;

    return Scaffold(
      appBar: AppBar(
        title: Text('Transactions: ${date.day}/${date.month}/${date.year}'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary Banner Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Column(
                      children: [
                        const Text('Cash In (+)', style: TextStyle(fontSize: 11, color: AppConstants.cashInColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(AppConstants.formatCurrency(totalIn), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.cashInColor)),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.3)),
                    Column(
                      children: [
                        const Text('Cash Out (-)', style: TextStyle(fontSize: 11, color: AppConstants.cashOutColor, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(AppConstants.formatCurrency(totalOut), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppConstants.cashOutColor)),
                      ],
                    ),
                    Container(height: 30, width: 1, color: Colors.grey.withOpacity(0.3)),
                    Column(
                      children: [
                        const Text('Net Balance', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          AppConstants.formatCurrency(netDaily),
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: netDaily >= 0 ? AppConstants.cashInColor : AppConstants.cashOutColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '${dailyEntries.length} Transactions Recorded',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 10),
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
                                backgroundColor: color.withOpacity(0.15),
                                child: Icon(
                                  isCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                  color: color,
                                ),
                              ),
                              title: Text(entry.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                              subtitle: Text('${entry.category} • ${entry.date.hour.toString().padLeft(2, '0')}:${entry.date.minute.toString().padLeft(2, '0')}'),
                              trailing: Text(
                                '${isCashIn ? "+" : "-"}${AppConstants.formatCurrency(entry.amount)}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                              ),
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
