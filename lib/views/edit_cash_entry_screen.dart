// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/cash_entry.dart';
import '../models/party_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class EditCashEntryScreen extends StatefulWidget {
  final CashEntry entry;

  const EditCashEntryScreen({super.key, required this.entry});

  @override
  State<EditCashEntryScreen> createState() => _EditCashEntryScreenState();
}

class _EditCashEntryScreenState extends State<EditCashEntryScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;

  late CashEntryType _selectedType;
  late String _selectedCategory;
  late DateTime _selectedDate;
  Party? _selectedParty;

  final List<String> _categories = [
    'Miscellaneous',
    'Item Sale',
    'Item Purchase',
    'Party Payment',
    'Salary',
    'Rent',
    'Transport',
    'Other'
  ];

  @override
  void initState() {
    super.initState();
    final entry = widget.entry;
    _titleController = TextEditingController(text: entry.title);
    _amountController = TextEditingController(text: entry.amount.toStringAsFixed(2));
    _selectedType = entry.type;
    _selectedCategory = _categories.contains(entry.category) ? entry.category : 'Miscellaneous';
    _selectedDate = entry.date;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (entry.partyId != null && entry.partyId!.isNotEmpty) {
        final dbService = Provider.of<DatabaseService>(context, listen: false);
        final pIndex = dbService.parties.indexWhere((p) => p.id == entry.partyId);
        if (pIndex != -1) {
          setState(() {
            _selectedParty = dbService.parties[pIndex];
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    final newAmount = double.tryParse(_amountController.text.trim());
    if (newAmount == null || newAmount <= 0) return;

    final updated = CashEntry(
      id: widget.entry.id,
      type: _selectedType,
      category: _selectedCategory,
      title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : _selectedCategory,
      partyId: _selectedParty?.id,
      amount: newAmount,
      date: _selectedDate,
    );

    final success = await dbService.updateCashEntry(updated, isGuest: authService.isGuestMode);

    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction entry updated!'),
            backgroundColor: AppConstants.cashInColor,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update entry: ${dbService.errorMessage ?? "Database error"}'),
            backgroundColor: AppConstants.accentColor,
          ),
        );
      }
    }
  }

  Future<void> _deleteEntry() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete Transaction Entry?'),
        content: Text('Permanently remove "${widget.entry.title}"?'),
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

    if (confirm == true && mounted) {
      final dbService = Provider.of<DatabaseService>(context, listen: false);
      final authService = Provider.of<AuthService>(context, listen: false);

      final success = await dbService.deleteCashEntry(widget.entry.id, isGuest: authService.isGuestMode);
      if (mounted && success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction deleted.')),
        );
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Transaction Entry'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppConstants.accentColor),
            onPressed: _deleteEntry,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Entry Type Segmented Control
              const Text('Transaction Type', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('CASH IN (+)', style: TextStyle(fontWeight: FontWeight.bold))),
                      selected: _selectedType == CashEntryType.cashIn,
                      selectedColor: AppConstants.cashInColor.withValues(alpha: 0.25),
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                      labelStyle: TextStyle(
                        color: _selectedType == CashEntryType.cashIn ? AppConstants.cashInColor : null,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedType = CashEntryType.cashIn);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ChoiceChip(
                      label: const Center(child: Text('CASH OUT (-)', style: TextStyle(fontWeight: FontWeight.bold))),
                      selected: _selectedType == CashEntryType.cashOut,
                      selectedColor: AppConstants.cashOutColor.withValues(alpha: 0.25),
                      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                      labelStyle: TextStyle(
                        color: _selectedType == CashEntryType.cashOut ? AppConstants.cashOutColor : null,
                      ),
                      onSelected: (val) {
                        if (val) setState(() => _selectedType = CashEntryType.cashOut);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Title Field
              TextFormField(
                controller: _titleController,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Title / Description *',
                  prefixIcon: const Icon(Icons.edit_note_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title is required' : null,
              ),
              const SizedBox(height: 16),

              // Amount Field
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Amount (${AppConstants.currencySymbol}) *',
                  prefixText: '${AppConstants.currencySymbol} ',
                  prefixIcon: const Icon(Icons.currency_rupee_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'Amount is required';
                  final d = double.tryParse(val.trim());
                  if (d == null || d <= 0) return 'Enter a valid positive amount';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Category Selector
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  prefixIcon: const Icon(Icons.category_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _selectedCategory = val);
                },
              ),
              const SizedBox(height: 16),

              // Linked Party Selector (Optional)
              DropdownButtonFormField<Party?>(
                value: _selectedParty,
                decoration: InputDecoration(
                  labelText: 'Linked Party / Account (Optional)',
                  prefixIcon: const Icon(Icons.person_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                items: [
                  const DropdownMenuItem<Party?>(value: null, child: Text('None (General Cash)')),
                  ...dbService.parties.map((p) => DropdownMenuItem<Party?>(value: p, child: Text('${p.name} (${p.phone})'))),
                ],
                onChanged: (p) => setState(() => _selectedParty = p),
              ),
              const SizedBox(height: 16),

              // Date & Time Picker Button
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                icon: const Icon(Icons.access_time_rounded),
                label: Text(
                  'Date & Time: ${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year} at ${_selectedDate.hour.toString().padLeft(2, '0')}:${_selectedDate.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: _pickDateTime,
              ),
              const SizedBox(height: 32),

              // Save Action Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saveChanges,
                  child: const Text('SAVE TRANSACTION CHANGES', style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
