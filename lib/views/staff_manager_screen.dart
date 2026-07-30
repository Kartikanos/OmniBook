// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../core/constants.dart';
import '../models/staff_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class StaffManagerScreen extends StatefulWidget {
  const StaffManagerScreen({super.key});

  @override
  State<StaffManagerScreen> createState() => _StaffManagerScreenState();
}

class _StaffManagerScreenState extends State<StaffManagerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Daily Attendance Mode state
  DateTime _selectedDate = DateTime.now();

  // Monthly Summary Mode state
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedMonth = DateTime.now().month;
    _selectedYear = DateTime.now().year;
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddStaffDialog(BuildContext context, {StaffMember? existingStaff}) {
    final formKey = GlobalKey<FormState>();
    final isEditing = existingStaff != null;
    final nameCtrl = TextEditingController(text: existingStaff?.name ?? '');
    final phoneCtrl = TextEditingController(text: existingStaff?.phone ?? '');
    final desigCtrl = TextEditingController(text: existingStaff?.designation ?? 'Helper / Polisher');
    final wageCtrl = TextEditingController(text: existingStaff != null ? existingStaff.dailyWage.toStringAsFixed(0) : '500');

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isEditing ? 'Edit Worker / Staff' : 'Add Worker / Staff Member'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Worker Name'),
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone Number'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: desigCtrl,
                  decoration: const InputDecoration(labelText: 'Role / Designation'),
                ),
                const SizedBox(height: 10),
                TextFormField(
                  controller: wageCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(
                    labelText: 'Daily Wage (${AppConstants.currencySymbol})',
                    prefixText: '${AppConstants.currencySymbol} ',
                  ),
                  validator: (v) => v == null || double.tryParse(v) == null ? 'Required' : null,
                ),
              ],
            ),
          ),
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
              if (formKey.currentState!.validate()) {
                final dbService = Provider.of<DatabaseService>(context, listen: false);
                final authService = Provider.of<AuthService>(context, listen: false);

                final updatedStaff = StaffMember(
                  id: existingStaff?.id ?? 'stf_${DateTime.now().millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  phone: phoneCtrl.text.trim(),
                  designation: desigCtrl.text.trim(),
                  dailyWage: double.parse(wageCtrl.text.trim()),
                );

                await dbService.addStaffMember(updatedStaff, isGuest: authService.isGuestMode);
                if (ctx.mounted) Navigator.of(ctx).pop();
              }
            },
            child: Text(isEditing ? 'Save Changes' : 'Save Worker'),
          ),
        ],
      ),
    );
  }

  /// Opens a month+year picker dialog for the Monthly Summary tab
  Future<void> _pickMonth(BuildContext context) async {
    int tempMonth = _selectedMonth;
    int tempYear = _selectedYear;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDs) => AlertDialog(
          title: const Text('Select Month & Year'),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Year Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setDs(() => tempYear--),
                  ),
                  Text(
                    '$tempYear',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setDs(() => tempYear++),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Month grid
              GridView.count(
                crossAxisCount: 4,
                shrinkWrap: true,
                children: List.generate(12, (i) {
                  final m = i + 1;
                  final isSelected = m == tempMonth;
                  final monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
                  return GestureDetector(
                    onTap: () => setDs(() => tempMonth = m),
                    child: Container(
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: isSelected ? AppConstants.primaryColor : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? AppConstants.primaryColor : Colors.grey.withOpacity(0.3),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          monthNames[i],
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : null,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
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
              onPressed: () {
                setState(() {
                  _selectedMonth = tempMonth;
                  _selectedYear = tempYear;
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

  String _monthName(int month) {
    const names = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return names[month - 1];
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final authService = Provider.of<AuthService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Staff & Attendance Manager'),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppConstants.primaryColor,
          labelColor: AppConstants.primaryColor,
          unselectedLabelColor: isDark ? Colors.white54 : Colors.black54,
          tabs: const [
            Tab(icon: Icon(Icons.calendar_today_rounded, size: 18), text: 'Daily Attendance'),
            Tab(icon: Icon(Icons.bar_chart_rounded, size: 18), text: 'Monthly Summary'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_rounded),
            onPressed: () => _showAddStaffDialog(context),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── TAB 1: DAILY ATTENDANCE MODE ──────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date Selector Header Card
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
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Daily Attendance Mode', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${dbService.staffMembers.length} Workers — tap to mark',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.calendar_month_rounded, size: 18),
                          label: const Text('Pick Date'),
                          onPressed: () async {
                            final picked = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2024),
                              lastDate: DateTime(2030),
                            );
                            if (picked != null) setState(() => _selectedDate = picked);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Mark Attendance for Selected Date', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),

                  Expanded(
                    child: dbService.staffMembers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off_rounded, size: 48, color: isDark ? Colors.white30 : Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No staff members added yet.',
                                  style: TextStyle(color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: dbService.staffMembers.length,
                            separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                            itemBuilder: (ctx, idx) {
                              final staff = dbService.staffMembers[idx];
                              final selDateKey = '${_selectedDate.year}-${_selectedDate.month.toString().padLeft(2, '0')}-${_selectedDate.day.toString().padLeft(2, '0')}';
                              final attMatches = dbService.attendanceRecords.where(
                                (a) => a.staffId == staff.id &&
                                    '${a.date.year}-${a.date.month.toString().padLeft(2, '0')}-${a.date.day.toString().padLeft(2, '0')}' == selDateKey,
                              );
                              final AttendanceStatus? currentStatus = attMatches.isNotEmpty ? attMatches.first.status : null;

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: isDark ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(14.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  staff.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${staff.designation} • ${AppConstants.formatCurrency(staff.dailyWage)}/day',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 12, color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Row(
                                            children: [
                                              IconButton(
                                                icon: const Icon(Icons.edit_outlined, size: 18),
                                                onPressed: () => _showAddStaffDialog(context, existingStaff: staff),
                                              ),
                                              IconButton(
                                                icon: const Icon(Icons.person_remove_outlined, size: 18, color: AppConstants.accentColor),
                                                onPressed: () async {
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (c) => AlertDialog(
                                                      title: const Text('Terminate / Delete Worker?'),
                                                      content: Text('Are you sure you want to permanently remove worker "${staff.name}"?'),
                                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                                      actions: [
                                                        TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
                                                        ElevatedButton(
                                                          style: ElevatedButton.styleFrom(backgroundColor: AppConstants.accentColor, foregroundColor: Colors.white),
                                                          onPressed: () => Navigator.pop(c, true),
                                                          child: const Text('Terminate'),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true && context.mounted) {
                                                    await dbService.deleteStaffMember(staff.id, isGuest: authService.isGuestMode);
                                                  }
                                                },
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 10),

                                      // Status Label
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          const Text('Attendance Status:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                                          Text(
                                            currentStatus == null
                                                ? 'Unmarked'
                                                : (currentStatus == AttendanceStatus.present
                                                    ? 'Present ✓'
                                                    : (currentStatus == AttendanceStatus.halfDay ? 'Half-Day' : 'Absent')),
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: currentStatus == null
                                                  ? Colors.grey
                                                  : (currentStatus == AttendanceStatus.present
                                                      ? AppConstants.cashInColor
                                                      : (currentStatus == AttendanceStatus.halfDay ? Colors.orange : AppConstants.accentColor)),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),

                                      // Action Buttons
                                      Row(
                                        children: [
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: currentStatus == AttendanceStatus.present
                                                    ? AppConstants.cashInColor
                                                    : (isDark ? const Color(0xFF334155) : Colors.grey[200]),
                                                foregroundColor: currentStatus == AttendanceStatus.present ? Colors.white : Colors.black87,
                                                padding: EdgeInsets.zero,
                                              ),
                                              onPressed: () => dbService.markAttendance(staff.id, _selectedDate, AttendanceStatus.present, isGuest: authService.isGuestMode),
                                              child: const Text('Present', style: TextStyle(fontSize: 12)),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: currentStatus == AttendanceStatus.halfDay
                                                    ? Colors.orange
                                                    : (isDark ? const Color(0xFF334155) : Colors.grey[200]),
                                                foregroundColor: currentStatus == AttendanceStatus.halfDay ? Colors.white : Colors.black87,
                                                padding: EdgeInsets.zero,
                                              ),
                                              onPressed: () => dbService.markAttendance(staff.id, _selectedDate, AttendanceStatus.halfDay, isGuest: authService.isGuestMode),
                                              child: const Text('Half-Day', style: TextStyle(fontSize: 12)),
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: currentStatus == AttendanceStatus.absent
                                                    ? AppConstants.accentColor
                                                    : (isDark ? const Color(0xFF334155) : Colors.grey[200]),
                                                foregroundColor: currentStatus == AttendanceStatus.absent ? Colors.white : Colors.black87,
                                                padding: EdgeInsets.zero,
                                              ),
                                              onPressed: () => dbService.markAttendance(staff.id, _selectedDate, AttendanceStatus.absent, isGuest: authService.isGuestMode),
                                              child: const Text('Absent', style: TextStyle(fontSize: 12)),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fade().slideY(begin: 0.1, end: 0, delay: (idx * 40).ms);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),

          // ── TAB 2: MONTHLY SUMMARY MODE ───────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 100),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Month Selector Header Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppConstants.secondaryColor, AppConstants.primaryColor],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Monthly Summary Mode', style: TextStyle(color: Colors.white70, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                '${_monthName(_selectedMonth)} $_selectedYear',
                                style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${dbService.staffMembers.length} Workers — aggregated view',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.2),
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          icon: const Icon(Icons.date_range_rounded, size: 18),
                          label: const Text('Pick Month'),
                          onPressed: () => _pickMonth(context),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('Worker Attendance Summary', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  const SizedBox(height: 10),

                  Expanded(
                    child: dbService.staffMembers.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.group_off_rounded, size: 48, color: isDark ? Colors.white30 : Colors.grey[400]),
                                const SizedBox(height: 12),
                                Text(
                                  'No staff members added yet.',
                                  style: TextStyle(color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight),
                                ),
                              ],
                            ),
                          )
                        : ListView.separated(
                            itemCount: dbService.staffMembers.length,
                            separatorBuilder: (ctx, idx) => const SizedBox(height: 10),
                            itemBuilder: (ctx, idx) {
                              final staff = dbService.staffMembers[idx];

                              // Monthly aggregate calculation
                              final monthRecords = dbService.attendanceRecords.where(
                                (a) => a.staffId == staff.id && a.date.year == _selectedYear && a.date.month == _selectedMonth,
                              ).toList();
                              final presents = monthRecords.where((r) => r.status == AttendanceStatus.present).length;
                              final halfDays = monthRecords.where((r) => r.status == AttendanceStatus.halfDay).length;
                              final absents = monthRecords.where((r) => r.status == AttendanceStatus.absent).length;
                              final daysInMonth = DateTime(_selectedYear, _selectedMonth + 1, 0).day;
                              final unmarked = (daysInMonth - monthRecords.length).clamp(0, 31);
                              final estimatedWage = dbService.calculateMonthlyWage(staff.id, _selectedYear, _selectedMonth);

                              return Card(
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18),
                                  side: isDark ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16.0),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Worker Header
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  staff.name,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                                ),
                                                const SizedBox(height: 2),
                                                Text(
                                                  '${staff.designation} • ${AppConstants.formatCurrency(staff.dailyWage)}/day',
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: TextStyle(fontSize: 12, color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment: CrossAxisAlignment.end,
                                            children: [
                                              const Text('Est. Monthly Wage', style: TextStyle(fontSize: 10, color: Colors.grey)),
                                              Text(
                                                AppConstants.formatCurrency(estimatedWage),
                                                style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.cashInColor, fontSize: 15),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 14),

                                      // Summary Stat Cards Row
                                      Row(
                                        children: [
                                          _buildSummaryStatChip(
                                            label: 'Presents',
                                            value: '$presents',
                                            color: AppConstants.cashInColor,
                                            icon: Icons.check_circle_outline_rounded,
                                            isDark: isDark,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildSummaryStatChip(
                                            label: 'Half-Days',
                                            value: '$halfDays',
                                            color: Colors.orange,
                                            icon: Icons.timelapse_rounded,
                                            isDark: isDark,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildSummaryStatChip(
                                            label: 'Absences',
                                            value: '$absents',
                                            color: AppConstants.accentColor,
                                            icon: Icons.cancel_outlined,
                                            isDark: isDark,
                                          ),
                                          const SizedBox(width: 8),
                                          _buildSummaryStatChip(
                                            label: 'Unmarked',
                                            value: '$unmarked',
                                            color: Colors.grey,
                                            icon: Icons.help_outline_rounded,
                                            isDark: isDark,
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ).animate().fade().slideY(begin: 0.1, end: 0, delay: (idx * 40).ms);
                            },
                          ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryStatChip({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: color),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 9, color: isDark ? Colors.white60 : Colors.black54),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
