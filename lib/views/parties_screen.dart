import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';
import '../models/party_model.dart';
import '../models/cash_entry.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/shimmer_loader.dart';

import 'add_party_screen.dart';

class PartiesScreen extends StatefulWidget {
  const PartiesScreen({super.key});

  @override
  State<PartiesScreen> createState() => _PartiesScreenState();
}

class _PartiesScreenState extends State<PartiesScreen> {
  String _filterType = 'All'; // 'All', 'Suppliers', 'Customers'
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authService = Provider.of<AuthService>(context, listen: false);
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      dbService.fetchAllData(isGuest: authService.isGuestMode);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddPartyDialog(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (ctx) => const AddPartyScreen()),
    );
  }

  void _openPartyLedgerDetails(BuildContext context, Party party) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _PartyLedgerDetailSheet(party: party),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final authService = Provider.of<AuthService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final parties = dbService.searchParties(_searchController.text, filterType: _filterType);

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => dbService.fetchAllData(isGuest: authService.isGuestMode),
          child: Padding(
            padding: const EdgeInsets.only(left: 16, right: 16, top: 16, bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unified Parties Ledger',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Suppliers & Customers',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppConstants.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onPressed: () => _showAddPartyDialog(context),
                      icon: const Icon(Icons.person_add_alt_1_rounded, size: 16),
                      label: const Text('New Party', style: TextStyle(fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Search Input
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search by party name or phone...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {});
                            },
                          )
                        : null,
                  ),
                ),
                const SizedBox(height: 12),

                // Filter Chips Row: [All], [Suppliers], [Customers]
                Row(
                  children: ['All', 'Suppliers', 'Customers'].map((type) {
                    final isSelected = _filterType == type;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: ChoiceChip(
                        label: Text(type),
                        selected: isSelected,
                        selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                        backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                        labelStyle: TextStyle(
                          color: isSelected
                              ? AppConstants.primaryAccent
                              : (isDark ? Colors.white70 : Colors.black87),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                            color: isSelected ? AppConstants.primaryColor : Colors.transparent,
                          ),
                        ),
                        onSelected: (selected) {
                          if (selected) setState(() => _filterType = type);
                        },
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Parties List
                Expanded(
                  child: dbService.isLoading && parties.isEmpty
                      ? const ShimmerListLoader(itemCount: 6)
                      : parties.isEmpty
                          ? ListView(
                          children: [
                            const SizedBox(height: 60),
                            Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.people_outline_rounded,
                                    size: 48,
                                    color: isDark ? Colors.white30 : Colors.grey[400],
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No party accounts found.',
                                    style: TextStyle(
                                      color: isDark
                                          ? AppConstants.textMutedDark
                                          : AppConstants.textMutedLight,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          itemCount: parties.length,
                          separatorBuilder: (ctx, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final party = parties[index];

                            Color tagColor = AppConstants.cashInColor; // Green for customer
                            if (party.type == PartyType.supplier) {
                              tagColor = Colors.orange;
                            } else if (party.type == PartyType.both) {
                              tagColor = Colors.purple;
                            }

                            return Card(
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(18),
                                side: isDark
                                    ? const BorderSide(color: Color(0xFF334155), width: 0.8)
                                    : BorderSide.none,
                              ),
                              child: InkWell(
                                onTap: () => _openPartyLedgerDetails(context, party),
                                borderRadius: BorderRadius.circular(18),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: tagColor.withOpacity(0.18),
                                        child: Icon(
                                          party.type == PartyType.supplier
                                              ? Icons.local_shipping_outlined
                                              : (party.type == PartyType.both
                                                  ? Icons.compare_arrows_rounded
                                                  : Icons.person_outline_rounded),
                                          color: tagColor,
                                          size: 20,
                                        ),
                                      ),
                                      const SizedBox(width: 12),

                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    party.name,
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                                  ),
                                                ),
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: tagColor.withOpacity(0.15),
                                                    borderRadius: BorderRadius.circular(8),
                                                    border: Border.all(color: tagColor.withOpacity(0.4), width: 1),
                                                  ),
                                                  child: Text(
                                                    party.typeLabel,
                                                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: tagColor),
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              '${party.phone} ${party.address != null ? "• ${party.address}" : ""}',
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(width: 10),

                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              final netBal = dbService.calculatePartyNetBalance(party.id);
                                              final isRec = netBal >= 0;
                                              return Column(
                                                crossAxisAlignment: CrossAxisAlignment.end,
                                                children: [
                                                  FittedBox(
                                                    child: Text(
                                                      AppConstants.formatCurrency(netBal.abs()),
                                                      style: TextStyle(
                                                        fontWeight: FontWeight.bold,
                                                        fontSize: 15,
                                                        color: isRec ? AppConstants.cashInColor : AppConstants.cashOutColor,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 2),
                                                  Container(
                                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                    decoration: BoxDecoration(
                                                      color: (isRec ? AppConstants.cashInColor : AppConstants.cashOutColor).withOpacity(0.12),
                                                      borderRadius: BorderRadius.circular(6),
                                                    ),
                                                    child: Text(
                                                      isRec ? 'Receivable' : 'Payable',
                                                      style: TextStyle(
                                                        fontSize: 10,
                                                        fontWeight: FontWeight.bold,
                                                        color: isRec ? AppConstants.cashInColor : AppConstants.cashOutColor,
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ).animate().fade().slideY(begin: 0.1, end: 0, delay: (index * 40).ms);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _PartyLedgerDetailSheet extends StatefulWidget {
  final Party party;

  const _PartyLedgerDetailSheet({required this.party});

  @override
  State<_PartyLedgerDetailSheet> createState() => _PartyLedgerDetailSheetState();
}

class _PartyLedgerDetailSheetState extends State<_PartyLedgerDetailSheet> {
  String _dateRangeFilter = 'All Time'; // 'All Time', 'Today', 'This Month'

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final allEntries = dbService.getPartyCashEntries(widget.party.id);

    final now = DateTime.now();
    List<CashEntry> filteredEntries = allEntries.where((e) {
      if (_dateRangeFilter == 'Today') {
        return e.date.year == now.year && e.date.month == now.month && e.date.day == now.day;
      }
      if (_dateRangeFilter == 'This Month') {
        return e.date.year == now.year && e.date.month == now.month;
      }
      return true;
    }).toList();

    final isReceivable = widget.party.currentBalance >= 0;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.party.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${widget.party.typeLabel} • ${widget.party.phone}',
                      style: TextStyle(fontSize: 12, color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Balance Banner Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isReceivable
                  ? AppConstants.cashInColor.withOpacity(0.12)
                  : AppConstants.cashOutColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isReceivable ? AppConstants.cashInColor : AppConstants.cashOutColor,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isReceivable ? 'Net Amount Receivable' : 'Net Amount Payable',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isReceivable ? AppConstants.cashInColor : AppConstants.cashOutColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      AppConstants.formatCurrency(widget.party.currentBalance.abs()),
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: isReceivable ? AppConstants.cashInColor : AppConstants.cashOutColor,
                      ),
                    ),
                  ],
                ),
                Icon(
                  isReceivable ? Icons.arrow_circle_down_rounded : Icons.arrow_circle_up_rounded,
                  color: isReceivable ? AppConstants.cashInColor : AppConstants.cashOutColor,
                  size: 36,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Date Filter Row: [All Time], [Today], [This Month]
          Row(
            children: ['All Time', 'Today', 'This Month'].map((filter) {
              final isSel = _dateRangeFilter == filter;
              return Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: ChoiceChip(
                  label: Text(filter),
                  selected: isSel,
                  selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                  labelStyle: TextStyle(
                    color: isSel ? AppConstants.primaryAccent : (isDark ? Colors.white70 : Colors.black87),
                    fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                    fontSize: 12,
                  ),
                  onSelected: (selected) {
                    if (selected) setState(() => _dateRangeFilter = filter);
                  },
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 14),

          const Text('Both-Way Statement Entries (Sales & Payments)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 10),

          // Both-Way Party Transactions List
          Expanded(
            child: filteredEntries.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.receipt_long_outlined, size: 44, color: isDark ? Colors.white30 : Colors.grey[400]),
                        const SizedBox(height: 8),
                        Text(
                          'No statement entries found for this party.',
                          style: TextStyle(color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    itemCount: filteredEntries.length,
                    separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                    itemBuilder: (ctx, idx) {
                      final entry = filteredEntries[idx];
                      final isCashIn = entry.type == CashEntryType.cashIn;
                      final col = isCashIn ? AppConstants.cashInColor : AppConstants.cashOutColor;

                      return Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: isDark ? const BorderSide(color: Color(0xFF334155), width: 0.8) : BorderSide.none,
                        ),
                        child: ListTile(
                          dense: true,
                          leading: Icon(
                            isCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: col,
                          ),
                          title: Text(
                            entry.title,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Text(
                            '${(entry.category == "Item Sale/Purchase" || entry.category.contains("Item")) ? (isCashIn ? "Item Sale" : "Item Purchase") : entry.category} • ${entry.date.day}/${entry.date.month}/${entry.date.year}',
                            style: const TextStyle(fontSize: 11),
                          ),
                          trailing: Text(
                            '${isCashIn ? "+" : "-"}${AppConstants.formatCurrency(entry.amount)}',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: col),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
