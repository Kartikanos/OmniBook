// ignore_for_file: avoid_print, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../core/supabase_config.dart';
import '../models/cash_entry.dart';
import '../models/inventory_item.dart';
import '../models/party_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class CashEntryModal extends StatefulWidget {
  final CashEntryType entryType;

  const CashEntryModal({
    super.key,
    required this.entryType,
  });

  @override
  State<CashEntryModal> createState() => _CashEntryModalState();
}

class _CashEntryModalState extends State<CashEntryModal> {
  final _formKey = GlobalKey<FormState>();

  late String _selectedCategory;
  late List<String> _categories;

  Party? _selectedParty;
  final TextEditingController _itemNameController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController(text: '1');
  final TextEditingController _unitPriceController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  bool get _isItemCategory =>
      _selectedCategory == 'Item Sale' ||
      _selectedCategory == 'Item Purchase' ||
      _selectedCategory.contains('Item');

  @override
  void initState() {
    super.initState();
    final isCashIn = widget.entryType == CashEntryType.cashIn;
    final primaryCategory = isCashIn ? 'Item Sale' : 'Item Purchase';
    _selectedCategory = primaryCategory;
    _categories = [
      primaryCategory,
      'Party Payment',
      'Miscellaneous',
      'Random',
    ];
  }

  @override
  void dispose() {
    _itemNameController.dispose();
    _quantityController.dispose();
    _unitPriceController.dispose();
    _amountController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _calculateTotal() {
    final qty = int.tryParse(_quantityController.text) ?? 1;
    final unitPrice = double.tryParse(_unitPriceController.text) ?? 0.0;
    if (_isItemCategory) {
      _amountController.text = (qty * unitPrice).toStringAsFixed(2);
    }
  }

  Future<void> _submitEntry() async {
    if (!_formKey.currentState!.validate()) return;

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);
    final isGuest = authService.isGuestMode;

    final double amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final int qty = int.tryParse(_quantityController.text.trim()) ?? 1;
    final double unitPrice = double.tryParse(_unitPriceController.text.trim()) ?? 0.0;
    final String inputName = _itemNameController.text.trim();

    // Check user auth state
    final currentUser = SupabaseConfig.client.auth.currentUser;
    if (!isGuest && currentUser == null) {
      print('--- SUPABASE CRITICAL ERROR: User not authenticated! ---');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: You are not logged in!')),
        );
      }
      return;
    }

    if (_isItemCategory && inputName.isNotEmpty) {
      final existingItems = dbService.searchInventory(inputName);
      final exactMatch = existingItems.firstWhere(
        (i) => i.name.toLowerCase() == inputName.toLowerCase(),
        orElse: () => InventoryItem(id: '', name: '', unitPrice: 0, stockQuantity: 0),
      );

      if (exactMatch.id.isEmpty) {
        final bool? shouldAddToInventory = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Add to Stock Inventory?'),
            content: Text(
              'Do you want to add "$inputName" to your utensils stock inventory?',
              style: const TextStyle(fontSize: 15),
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => Navigator.of(ctx).pop(true),
                child: const Text('Add Item'),
              ),
            ],
          ),
        );

        if (shouldAddToInventory == true) {
          final newItem = InventoryItem(
            id: const Uuid().v4(),
            name: inputName,
            unitPrice: unitPrice > 0 ? unitPrice : (amount / (qty > 0 ? qty : 1)),
            stockQuantity: widget.entryType == CashEntryType.cashIn ? 0 : qty,
            unit: 'Pieces',
            category: 'General Utensils',
          );
          await dbService.addInventoryItem(newItem, isGuest: isGuest);
        }
      }
    }

    String entryTitle = inputName;
    if (_selectedParty != null && (entryTitle.isEmpty || _selectedCategory == 'Party Payment')) {
      entryTitle = widget.entryType == CashEntryType.cashIn
          ? 'Received from ${_selectedParty!.name}'
          : 'Paid to ${_selectedParty!.name}';
    }

    final entry = CashEntry(
      id: const Uuid().v4(),
      type: widget.entryType,
      category: _selectedCategory,
      title: entryTitle.isNotEmpty ? entryTitle : _selectedCategory,
      partyId: _selectedParty?.id,
      amount: amount,
      date: DateTime.now(),
    );

    try {
      final success = await dbService.addCashEntry(entry, isGuest: isGuest);
      if (mounted) {
        if (success) {
          print('--- SUCCESS! CASH TRANSACTION SAVED ---');
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${widget.entryType == CashEntryType.cashIn ? "Cash In (+)" : "Cash Out (-)"} recorded: ${AppConstants.formatCurrency(amount)}',
              ),
              backgroundColor: widget.entryType == CashEntryType.cashIn
                  ? AppConstants.cashInColor
                  : AppConstants.cashOutColor,
            ),
          );
        } else {
          print('--- SUPABASE CRITICAL ERROR: Save returned false ---');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Save failed: ${dbService.errorMessage ?? "Database save error"}'),
              backgroundColor: AppConstants.accentColor,
            ),
          );
        }
      }
    } catch (e, stackTrace) {
      print('--- SUPABASE CRITICAL ERROR: $e ---');
      print(stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Save failed: $e'),
            backgroundColor: AppConstants.accentColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isCashIn = widget.entryType == CashEntryType.cashIn;
    final primaryColor = isCashIn ? AppConstants.cashInColor : AppConstants.cashOutColor;
    final dbService = Provider.of<DatabaseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: primaryColor.withOpacity(0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isCashIn ? Icons.arrow_downward_rounded : Icons.arrow_upward_rounded,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            isCashIn ? 'Record Cash In' : 'Record Cash Out',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: primaryColor,
                            ),
                          ),
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
              const SizedBox(height: 20),

              // Category Selector Chips
              Text(
                'Select Transaction Category',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white70 : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  return ChoiceChip(
                    label: Text(cat),
                    selected: isSelected,
                    selectedColor: primaryColor.withOpacity(0.2),
                    backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.grey[200],
                    labelStyle: TextStyle(
                      color: isSelected
                          ? primaryColor
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      fontSize: 13,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(
                        color: isSelected ? primaryColor : Colors.transparent,
                      ),
                    ),
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _selectedCategory = cat;
                        });
                      }
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Optional Select Party Dropdown linked to Unified Parties
              Builder(
                builder: (context) {
                  final Party? validSelectedParty = _selectedParty != null &&
                          dbService.parties.any((p) => p.id == _selectedParty!.id)
                      ? dbService.parties.firstWhere((p) => p.id == _selectedParty!.id)
                      : null;

                  return DropdownButtonFormField<Party>(
                    value: validSelectedParty,
                    isExpanded: true,
                    decoration: InputDecoration(
                      labelText: 'Select Party Account (Optional)',
                      hintText: 'Link transaction to Party Ledger',
                      prefixIcon: const Icon(Icons.person_pin_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: [
                      const DropdownMenuItem<Party>(
                        value: null,
                        child: Text('None (General Cash Entry)'),
                      ),
                      ...dbService.parties.map(
                        (p) => DropdownMenuItem<Party>(
                          value: p,
                          child: Text(
                            '${p.name} (${p.typeLabel})',
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    ],
                    onChanged: (p) => setState(() => _selectedParty = p),
                  );
                },
              ),
              const SizedBox(height: 14),

              // Item Autocomplete section (If Item Sale or Item Purchase selected)
              if (_isItemCategory) ...[
                Autocomplete<InventoryItem>(
                  displayStringForOption: (item) => item.name,
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    return dbService.searchInventory(textEditingValue.text);
                  },
                  onSelected: (InventoryItem selection) {
                    setState(() {
                      _itemNameController.text = selection.name;
                      _unitPriceController.text = selection.unitPrice.toStringAsFixed(2);
                      _calculateTotal();
                    });
                  },
                  fieldViewBuilder: (context, controller, focusNode, onEditingComplete) {
                    return TextFormField(
                      controller: controller,
                      focusNode: focusNode,
                      decoration: InputDecoration(
                        labelText: 'Utensil Item Name',
                        hintText: 'Search or type utensil name',
                        prefixIcon: const Icon(Icons.search_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onChanged: (val) {
                        _itemNameController.text = val;
                      },
                      validator: (val) {
                        if (_isItemCategory && (val == null || val.trim().isEmpty)) {
                          return 'Please enter item name';
                        }
                        return null;
                      },
                    );
                  },
                  optionsViewBuilder: (context, onSelected, options) {
                    return Align(
                      alignment: Alignment.topLeft,
                      child: Material(
                        elevation: 4,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          width: MediaQuery.of(context).size.width - 40,
                          constraints: const BoxConstraints(maxHeight: 180),
                          color: isDark ? const Color(0xFF1E293B) : Colors.white,
                          child: ListView.builder(
                            padding: EdgeInsets.zero,
                            shrinkWrap: true,
                            itemCount: options.length,
                            itemBuilder: (BuildContext context, int index) {
                              final item = options.elementAt(index);
                              return ListTile(
                                leading: const Icon(Icons.local_dining_outlined),
                                title: Text(item.name),
                                subtitle: Text(
                                  'Stock: ${item.stockQuantity} ${item.unit} | ${AppConstants.formatCurrency(item.unitPrice)}',
                                ),
                                onTap: () => onSelected(item),
                              );
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 14),

                Row(
                  children: [
                    // Quantity
                    Expanded(
                      flex: 2,
                      child: TextFormField(
                        controller: _quantityController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Quantity',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (_) => _calculateTotal(),
                        validator: (val) {
                          if (val == null || int.tryParse(val) == null || int.parse(val) <= 0) {
                            return 'Min 1';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Unit Price (₹)
                    Expanded(
                      flex: 3,
                      child: TextFormField(
                        controller: _unitPriceController,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(
                          labelText: 'Unit Price (${AppConstants.currencySymbol})',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        onChanged: (_) => _calculateTotal(),
                        validator: (val) {
                          if (_isItemCategory && (val == null || double.tryParse(val) == null)) {
                            return 'Enter price';
                          }
                          return null;
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
              ],

              // Total Amount Field (₹)
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                decoration: InputDecoration(
                  labelText: 'Total Amount (${AppConstants.currencySymbol})',
                  prefixText: '${AppConstants.currencySymbol} ',
                  prefixStyle: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: primaryColor,
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                validator: (val) {
                  if (val == null || double.tryParse(val) == null || double.parse(val) <= 0) {
                    return 'Please enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Notes field
              TextFormField(
                controller: _notesController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: 'Notes / Remarks (Optional)',
                  hintText: 'Add transaction notes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  onPressed: _submitEntry,
                  child: Text(
                    isCashIn ? 'Save Cash In (Item Sale)' : 'Save Cash Out (Item Purchase)',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
