// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';
import '../models/cash_entry.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../widgets/cash_entry_modal.dart';
import '../widgets/shimmer_loader.dart';

enum _DateMode { all, singleDate, customMonth, customRange }

class CashbookScreen extends StatefulWidget {
  const CashbookScreen({super.key});

  @override
  State<CashbookScreen> createState() => _CashbookScreenState();
}

class _CashbookScreenState extends State<CashbookScreen> {
  String _filterType = 'All'; // 'All', 'Cash In', 'Cash Out'
  final TextEditingController _searchController = TextEditingController();

  // Date filter mode
  _DateMode _dateMode = _DateMode.all;
  DateTime _singleDate = DateTime.now();
  int _filterMonth = DateTime.now().month;
  int _filterYear = DateTime.now().year;
  DateTime _rangeStart = DateTime.now().subtract(const Duration(days: 30));
  DateTime _rangeEnd = DateTime.now();

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

  void _openCashModal(BuildContext context, CashEntryType entryType) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CashEntryModal(entryType: entryType),
    );
  }

  void _showEditCashEntryDialog(BuildContext context, CashEntry entry) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final titleCtrl = TextEditingController(text: entry.title);
    final amountCtrl = TextEditingController(text: entry.amount.toStringAsFixed(2));
    final notesCtrl = TextEditingController(text: entry.notes ?? '');
    DateTime editDate = entry.date;

    final categories = ['Miscellaneous', 'Item Sale', 'Item Purchase', 'Party Payment', 'Salary', 'Rent', 'Transport', 'Other'];
    String selectedCategory = categories.contains(entry.category) ? entry.category : 'Miscellaneous';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setMs) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Edit ${entry.type == CashEntryType.cashIn ? "Cash In" : "Cash Out"} Entry',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline_rounded, color: AppConstants.accentColor),
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (c) => AlertDialog(
                            title: const Text('Delete Entry?'),
                            content: Text('Remove "${entry.title}" permanently?'),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentColor, foregroundColor: Colors.white),
                                onPressed: () => Navigator.pop(c, true),
                                child: const Text('Delete'),
                              ),
                            ],
                          ),
                        );
                        if (confirm == true && context.mounted) {
                          await dbService.deleteCashEntry(entry.id, isGuest: authService.isGuestMode);
                        }
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleCtrl,
                  decoration: InputDecoration(
                    labelText: 'Title / Description',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Amount (${AppConstants.currencySymbol})',
                    prefixText: '${AppConstants.currencySymbol} ',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                DropdownButtonFormField<String>(
                  value: selectedCategory,
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  items: categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                  onChanged: (v) => setMs(() => selectedCategory = v ?? selectedCategory),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: notesCtrl,
                  decoration: InputDecoration(
                    labelText: 'Notes (optional)',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 10),
                // Date picker row
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.calendar_today_rounded, size: 16),
                  label: Text('Date: ${editDate.day}/${editDate.month}/${editDate.year}'),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: editDate,
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                    );
                    if (picked != null) setMs(() => editDate = picked);
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppConstants.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    onPressed: () async {
                      final newAmount = double.tryParse(amountCtrl.text.trim());
                      if (newAmount == null || newAmount <= 0) return;

                      final updated = CashEntry(
                        id: entry.id,
                        type: entry.type,
                        category: selectedCategory,
                        title: titleCtrl.text.trim().isNotEmpty ? titleCtrl.text.trim() : selectedCategory,
                        partyId: entry.partyId,
                        amount: newAmount,
                        date: editDate,
                      );

                      await dbService.updateCashEntry(updated, isGuest: authService.isGuestMode);
                      if (ctx.mounted) Navigator.of(ctx).pop();
                    },
                    child: const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditOpeningBalanceDialog(BuildContext context, double currentBase) {
    final ctrl = TextEditingController(text: currentBase.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit Opening Balance'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'This is the initial capital / starting cash balance before any transactions were recorded.',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Opening Balance (${AppConstants.currencySymbol})',
                prefixText: '${AppConstants.currencySymbol} ',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              autofocus: true,
            ),
            const SizedBox(height: 8),
            const Text(
              'Changing this value will recalibrate all Closing Balances automatically.',
              style: TextStyle(fontSize: 11, color: Colors.orange),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppConstants.primaryColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final val = double.tryParse(ctrl.text.trim());
              if (val != null) {
                final dbService = Provider.of<DatabaseService>(context, listen: false);
                await dbService.updateBaseOpeningBalance(val);
                if (ctx.mounted) {
                  Navigator.of(ctx).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Opening balance updated to ${AppConstants.formatCurrency(val)}'),
                      backgroundColor: AppConstants.cashInColor,
                    ),
                  );
                }
              }
            },
            child: const Text('Save & Recalibrate'),
          ),
        ],
      ),
    );
  }

  String _monthName(int m) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[m - 1];
  }

  /// Pick a month/year combo
  Future<void> _pickMonth() async {
    int tempMonth = _filterMonth;
    int tempYear = _filterYear;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDs) => AlertDialog(
          title: const Text('Select Month & Year'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setDs(() => tempYear--)),
                  Text('$tempYear', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setDs(() => tempYear++)),
                ],
              ),
              const SizedBox(height: 8),
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                children: List.generate(12, (i) {
                  final m = i + 1;
                  final isSel = m == tempMonth;
                  final monthAbbr = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  return GestureDetector(
                    onTap: () => setDs(() => tempMonth = m),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSel ? AppConstants.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: isSel ? AppConstants.primaryColor : Colors.grey.withOpacity(0.3)),
                      ),
                      child: Center(
                        child: Text(
                          monthAbbr[i],
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isSel ? Colors.white : null),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              onPressed: () {
                setState(() {
                  _filterMonth = tempMonth;
                  _filterYear = tempYear;
                  _dateMode = _DateMode.customMonth;
                });
                Navigator.of(ctx).pop();
              },
              child: const Text('Apply'),
            ),
          ],
        ),
      ),
    );
  }

  /// Compute opening balance just before [cutoff]
  double _openingBalanceBefore(DateTime cutoff, List<CashEntry> allEntries, double base) {
    final before = cutoff;
    final prevIn = allEntries
        .where((e) => e.type == CashEntryType.cashIn && e.date.isBefore(before))
        .fold(0.0, (s, e) => s + e.amount);
    final prevOut = allEntries
        .where((e) => e.type == CashEntryType.cashOut && e.date.isBefore(before))
        .fold(0.0, (s, e) => s + e.amount);
    return base + prevIn - prevOut;
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final authService = Provider.of<AuthService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allEntries = dbService.cashEntries.toList();
    final double baseBalance = dbService.baseOpeningBalance; // mutable, persisted

    // Apply date mode filter first
    List<CashEntry> dateModeFiltered;
    switch (_dateMode) {
      case _DateMode.singleDate:
        dateModeFiltered = allEntries.where((e) =>
            e.date.year == _singleDate.year &&
            e.date.month == _singleDate.month &&
            e.date.day == _singleDate.day).toList();
        break;
      case _DateMode.customMonth:
        dateModeFiltered = allEntries.where((e) =>
            e.date.year == _filterYear &&
            e.date.month == _filterMonth).toList();
        break;
      case _DateMode.customRange:
        final startDay = DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
        final endDay = DateTime(_rangeEnd.year, _rangeEnd.month, _rangeEnd.day, 23, 59, 59);
        dateModeFiltered = allEntries.where((e) =>
            !e.date.isBefore(startDay) && !e.date.isAfter(endDay)).toList();
        break;
      case _DateMode.all:
        dateModeFiltered = allEntries;
        break;
    }

    // Apply type + search filters
    final query = _searchController.text.trim().toLowerCase();
    List<CashEntry> filteredList = dateModeFiltered.where((entry) {
      if (_filterType == 'Cash In' && entry.type != CashEntryType.cashIn) return false;
      if (_filterType == 'Cash Out' && entry.type != CashEntryType.cashOut) return false;
      if (query.isNotEmpty) {
        final title = entry.title.toLowerCase();
        final notes = (entry.notes ?? '').toLowerCase();
        return title.contains(query) || notes.contains(query);
      }
      return true;
    }).toList();

    // Balance calculations for date-filtered period
    final bool showBalanceBanner = _dateMode != _DateMode.all;
    double openingBalance = 0;
    double periodCashIn = 0;
    double periodCashOut = 0;
    double closingBalance = 0;

    if (showBalanceBanner) {
      DateTime periodStart;
      switch (_dateMode) {
        case _DateMode.singleDate:
          periodStart = DateTime(_singleDate.year, _singleDate.month, _singleDate.day);
          break;
        case _DateMode.customMonth:
          periodStart = DateTime(_filterYear, _filterMonth, 1);
          break;
        case _DateMode.customRange:
          periodStart = DateTime(_rangeStart.year, _rangeStart.month, _rangeStart.day);
          break;
        case _DateMode.all:
          periodStart = DateTime(2000);
          break;
      }
      openingBalance = _openingBalanceBefore(periodStart, allEntries, baseBalance);
      periodCashIn = dateModeFiltered.where((e) => e.type == CashEntryType.cashIn).fold(0.0, (s, e) => s + e.amount);
      periodCashOut = dateModeFiltered.where((e) => e.type == CashEntryType.cashOut).fold(0.0, (s, e) => s + e.amount);
      closingBalance = openingBalance + periodCashIn - periodCashOut;
    }

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => dbService.fetchAllData(isGuest: authService.isGuestMode),
          child: Padding(
            padding: const EdgeInsets.only(left: 20, right: 20, top: 20, bottom: 110),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header & Quick Add Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'CashBook Ledger',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Track all cash flow transactions (₹)',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight,
                          ),
                        ),
                      ],
                    ),
                    PopupMenuButton<CashEntryType>(
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppConstants.primaryColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.add_rounded, color: Colors.white),
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      onSelected: (type) => _openCashModal(context, type),
                      itemBuilder: (ctx) => [
                        const PopupMenuItem(
                          value: CashEntryType.cashIn,
                          child: Row(
                            children: [
                              Icon(Icons.arrow_downward_rounded, color: AppConstants.cashInColor),
                              SizedBox(width: 8),
                              Text('Record Cash In (+)'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: CashEntryType.cashOut,
                          child: Row(
                            children: [
                              Icon(Icons.arrow_upward_rounded, color: AppConstants.cashOutColor),
                              SizedBox(width: 8),
                              Text('Record Cash Out (-)'),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // ── DATE FILTER HEADER BAR ─────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? const Color(0xFF334155) : Colors.grey.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Filter by Period',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white54 : Colors.black45,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            // All Time button
                            _DateFilterChip(
                              label: 'All Time',
                              icon: Icons.all_inclusive_rounded,
                              isSelected: _dateMode == _DateMode.all,
                              isDark: isDark,
                              onTap: () => setState(() => _dateMode = _DateMode.all),
                            ),
                            const SizedBox(width: 8),
                            // Single Date
                            _DateFilterChip(
                              label: _dateMode == _DateMode.singleDate
                                  ? '${_singleDate.day}/${_singleDate.month}/${_singleDate.year}'
                                  : 'Single Date',
                              icon: Icons.calendar_today_rounded,
                              isSelected: _dateMode == _DateMode.singleDate,
                              isDark: isDark,
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _singleDate,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                );
                                if (picked != null) {
                                  setState(() {
                                    _singleDate = picked;
                                    _dateMode = _DateMode.singleDate;
                                  });
                                }
                              },
                            ),
                            const SizedBox(width: 8),
                            // Custom Month
                            _DateFilterChip(
                              label: _dateMode == _DateMode.customMonth
                                  ? '${_monthName(_filterMonth)} $_filterYear'
                                  : 'Custom Month',
                              icon: Icons.date_range_rounded,
                              isSelected: _dateMode == _DateMode.customMonth,
                              isDark: isDark,
                              onTap: _pickMonth,
                            ),
                            const SizedBox(width: 8),
                            // Custom Range
                            _DateFilterChip(
                              label: _dateMode == _DateMode.customRange
                                  ? '${_rangeStart.day}/${_rangeStart.month} – ${_rangeEnd.day}/${_rangeEnd.month}'
                                  : 'Custom Range',
                              icon: Icons.tune_rounded,
                              isSelected: _dateMode == _DateMode.customRange,
                              isDark: isDark,
                              onTap: () async {
                                final start = await showDatePicker(
                                  context: context,
                                  initialDate: _rangeStart,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime(2030),
                                  helpText: 'SELECT START DATE',
                                );
                                if (start == null || !context.mounted) return;
                                final end = await showDatePicker(
                                  context: context,
                                  initialDate: _rangeEnd.isBefore(start) ? start : _rangeEnd,
                                  firstDate: start,
                                  lastDate: DateTime(2030),
                                  helpText: 'SELECT END DATE',
                                );
                                if (end != null) {
                                  setState(() {
                                    _rangeStart = start;
                                    _rangeEnd = end;
                                    _dateMode = _DateMode.customRange;
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // ── BALANCE SUMMARY BANNER (only for date-filtered modes) ──
                if (showBalanceBanner)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppConstants.primaryColor.withOpacity(0.12),
                          AppConstants.secondaryColor.withOpacity(0.08),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppConstants.primaryColor.withOpacity(0.2)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            _BalanceStat(label: 'Opening', value: openingBalance, color: isDark ? Colors.white70 : Colors.black54, isNeutral: true),
                            _buildDivider(),
                            _BalanceStat(label: 'Cash In', value: periodCashIn, color: AppConstants.cashInColor),
                            _buildDivider(),
                            _BalanceStat(label: 'Cash Out', value: periodCashOut, color: AppConstants.cashOutColor),
                            _buildDivider(),
                            _BalanceStat(label: 'Closing', value: closingBalance, color: closingBalance >= 0 ? AppConstants.cashInColor : AppConstants.cashOutColor),
                          ],
                        ),
                        const SizedBox(height: 6),
                        GestureDetector(
                          onTap: () => _showEditOpeningBalanceDialog(context, baseBalance),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.edit_rounded, size: 12, color: AppConstants.primaryColor.withOpacity(0.7)),
                              const SizedBox(width: 4),
                              Text(
                                'Edit Opening Balance (${AppConstants.formatCurrency(baseBalance)})',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: AppConstants.primaryColor.withOpacity(0.8),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ).animate().fade().slideY(begin: -0.2, end: 0),

                // Search Bar
                TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: 'Search ledger entries...',
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

                // Type Filter Chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ...['All', 'Cash In', 'Cash Out'].map((type) {
                        final isSelected = _filterType == type;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(type),
                            selected: isSelected,
                            selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                            labelStyle: TextStyle(
                              color: isSelected ? AppConstants.primaryAccent : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                              side: BorderSide(color: isSelected ? AppConstants.primaryColor : Colors.transparent),
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _filterType = type);
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Ledger Transactions List
                Expanded(
                  child: dbService.isLoading && filteredList.isEmpty
                      ? const ShimmerListLoader(itemCount: 6)
                      : filteredList.isEmpty
                          ? ListView(
                              children: [
                                const SizedBox(height: 60),
                                Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.search_off_rounded,
                                        size: 48,
                                        color: isDark ? Colors.white30 : Colors.grey[400],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No ledger records found.',
                                        style: TextStyle(
                                          color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            )
                          : ListView.separated(
                              itemCount: filteredList.length,
                              separatorBuilder: (ctx, index) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final entry = filteredList[index];
                                final isCashIn = entry.type == CashEntryType.cashIn;
                                final color = isCashIn ? AppConstants.cashInColor : AppConstants.cashOutColor;

                                return GestureDetector(
                                  onLongPress: () => _showEditCashEntryDialog(context, entry),
                                  child: Card(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                      side: isDark
                                          ? const BorderSide(color: Color(0xFF334155), width: 0.8)
                                          : BorderSide.none,
                                    ),
                                    child: ListTile(
                                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                                      onLongPress: () => _showEditCashEntryDialog(context, entry),
                                      leading: Container(
                                        padding: const EdgeInsets.all(10),
                                        decoration: BoxDecoration(
                                          color: color.withOpacity(0.12),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          isCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                                          color: color,
                                          size: 22,
                                        ),
                                      ),
                                      title: Text(
                                        entry.title,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                      ),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Builder(
                                            builder: (context) {
                                              String catLabel = entry.category;
                                              if (catLabel == 'Item Sale/Purchase') {
                                                catLabel = isCashIn ? 'Item Sale' : 'Item Purchase';
                                              }
                                              return Text(
                                                '$catLabel ${entry.quantity > 1 ? "• Qty: ${entry.quantity}" : ""}',
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight,
                                                ),
                                              );
                                            },
                                          ),
                                          if (entry.notes != null && entry.notes!.isNotEmpty)
                                            Text(
                                              entry.notes!,
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontStyle: FontStyle.italic,
                                                color: isDark ? Colors.white60 : Colors.black54,
                                              ),
                                            ),
                                          // Long-press hint
                                          Text(
                                            'Hold to edit',
                                            style: TextStyle(
                                              fontSize: 9,
                                              color: isDark ? Colors.white30 : Colors.black26,
                                            ),
                                          ),
                                        ],
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${isCashIn ? "+" : "-"}${AppConstants.formatCurrency(entry.amount)}',
                                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${entry.date.day}/${entry.date.month}/${entry.date.year}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight,
                                            ),
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

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 36,
      color: Colors.grey.withOpacity(0.25),
      margin: const EdgeInsets.symmetric(horizontal: 10),
    );
  }
}

// ── Helper Widgets ─────────────────────────────────────────────────────────────

class _DateFilterChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _DateFilterChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppConstants.primaryColor : (isDark ? const Color(0xFF0F172A) : Colors.white),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppConstants.primaryColor : (isDark ? const Color(0xFF334155) : Colors.grey.withOpacity(0.3)),
          ),
          boxShadow: isSelected
              ? [BoxShadow(color: AppConstants.primaryColor.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: isSelected ? Colors.white : (isDark ? Colors.white60 : Colors.black54)),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BalanceStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;
  final bool isNeutral;

  const _BalanceStat({required this.label, required this.value, required this.color, this.isNeutral = false});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(label, style: TextStyle(fontSize: 9, color: color, fontWeight: FontWeight.w600)),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              AppConstants.formatCurrency(value.abs()),
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: color),
            ),
          ),
        ],
      ),
    );
  }
}
