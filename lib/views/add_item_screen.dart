import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import '../core/constants.dart';
import '../models/inventory_item.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';

class AddItemScreen extends StatefulWidget {
  final InventoryItem? existingItem;

  const AddItemScreen({super.key, this.existingItem});

  @override
  State<AddItemScreen> createState() => _AddItemScreenState();
}

class _AddItemScreenState extends State<AddItemScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _salePriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _openingStockController;
  late TextEditingController _lowStockAlertController;
  late TextEditingController _hsnController;

  String _selectedUnit = 'PCS';
  String? _secondaryUnit;
  bool _enableSecondaryUnit = false;
  bool _taxIncluded = false;
  double _gstRate = 5.0; // 0, 5, 12, 18, 28
  bool _isExempt = false;
  DateTime _asOfDate = DateTime.now();

  final Map<String, String> _unitDisplayNames = const {
    'NOS': 'Numbers (NOS)',
    'PCS': 'Pieces (PCS)',
    'KGS': 'Kilograms (KGS)',
    'BAG': 'Bags (BAG)',
    'BOX': 'Boxes (BOX)',
    'BTL': 'Bottles (BTL)',
    'MON': 'Months (MON)',
    'YRS': 'Years (YRS)',
    'WKS': 'Weeks (WKS)',
    'BAL': 'Bales (BAL)',
    'BOU': 'Bouquet (BOU)',
  };

  final List<String> _units = const [
    'NOS', 'PCS', 'KGS', 'BAG', 'BOX', 'BTL', 'MON', 'YRS', 'WKS', 'BAL', 'BOU'
  ];

  final List<double> _gstRates = const [0.0, 5.0, 12.0, 18.0, 28.0];

  @override
  void initState() {
    super.initState();
    final item = widget.existingItem;
    _nameController = TextEditingController(text: item?.name ?? '');
    _salePriceController = TextEditingController(text: item != null ? item.salePrice.toStringAsFixed(2) : '');
    _purchasePriceController = TextEditingController(text: item != null ? item.purchasePrice.toStringAsFixed(2) : '');
    _openingStockController = TextEditingController(text: item != null ? item.openingStock.toString() : '0');
    _lowStockAlertController = TextEditingController(text: item != null ? item.lowStockAlert.toString() : '5');
    _hsnController = TextEditingController(text: item?.hsn ?? '');

    if (item != null) {
      _selectedUnit = _units.contains(item.unit) ? item.unit : 'PCS';
      _secondaryUnit = item.secondaryUnit;
      _enableSecondaryUnit = item.secondaryUnit != null;
      _taxIncluded = item.taxIncluded;
      _gstRate = item.gstRate;
      _asOfDate = item.asOfDate;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _salePriceController.dispose();
    _purchasePriceController.dispose();
    _openingStockController.dispose();
    _lowStockAlertController.dispose();
    _hsnController.dispose();
    super.dispose();
  }

  void _showUnitPickerModal({bool isSecondary = false}) {
    String searchQuery = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          final filteredUnits = _units
              .where((u) {
                final display = _unitDisplayNames[u] ?? u;
                return display.toLowerCase().contains(searchQuery.toLowerCase());
              })
              .toList();

          return Container(
            height: MediaQuery.of(context).size.height * 0.6,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                Text(
                  isSecondary ? 'Select Secondary Unit' : 'Select Primary Unit',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Search Unit (e.g. Pieces, Kilograms, Box)',
                    prefixIcon: const Icon(Icons.search_rounded),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onChanged: (val) => setModalState(() => searchQuery = val),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: filteredUnits.length,
                    separatorBuilder: (ctx, idx) => const Divider(height: 1),
                    itemBuilder: (ctx, idx) {
                      final unit = filteredUnits[idx];
                      final displayName = _unitDisplayNames[unit] ?? unit;
                      final isSelected = isSecondary ? _secondaryUnit == unit : _selectedUnit == unit;
                      return ListTile(
                        title: Text(displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        trailing: isSelected
                            ? const Icon(Icons.check_circle_rounded, color: AppConstants.primaryColor)
                            : null,
                        onTap: () {
                          setState(() {
                            if (isSecondary) {
                              _secondaryUnit = unit;
                            } else {
                              _selectedUnit = unit;
                            }
                          });
                          Navigator.of(ctx).pop();
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _saveItem() async {
    if (!_formKey.currentState!.validate()) return;

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    final double saleP = double.tryParse(_salePriceController.text.trim()) ?? 0.0;
    final double purchP = double.tryParse(_purchasePriceController.text.trim()) ?? 0.0;
    final int opStock = int.tryParse(_openingStockController.text.trim()) ?? 0;
    final int lowAlert = int.tryParse(_lowStockAlertController.text.trim()) ?? 5;

    final item = InventoryItem(
      id: widget.existingItem?.id ?? const Uuid().v4(),
      name: _nameController.text.trim(),
      unit: _selectedUnit,
      secondaryUnit: _enableSecondaryUnit ? _secondaryUnit : null,
      salePrice: saleP,
      purchasePrice: purchP,
      taxIncluded: _taxIncluded,
      openingStock: opStock,
      stockQuantity: widget.existingItem != null ? widget.existingItem!.stockQuantity : opStock,
      lowStockAlert: lowAlert,
      hsn: _hsnController.text.trim().isNotEmpty ? _hsnController.text.trim() : null,
      gstRate: _isExempt ? 0.0 : _gstRate,
      asOfDate: _asOfDate,
      category: 'General Utensils',
    );

    final success = await dbService.addInventoryItem(item, isGuest: authService.isGuestMode);

    if (mounted) {
      if (success != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(widget.existingItem != null ? 'Item updated successfully!' : 'New item saved to inventory!'),
            backgroundColor: AppConstants.cashInColor,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save item: ${dbService.errorMessage ?? "Database error"}'),
            backgroundColor: AppConstants.accentColor,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existingItem != null ? 'Edit Utensil Item' : 'Add New Item'),
        elevation: 0,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Item Name Field
              TextFormField(
                controller: _nameController,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: 'Item Name *',
                  hintText: 'e.g. Copper Water Jug 1.5L',
                  prefixIcon: const Icon(Icons.inventory_2_rounded),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Item name is required' : null,
              ),
              const SizedBox(height: 20),

              // Unit Selector Section
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      icon: const Icon(Icons.straighten_rounded, size: 18),
                      label: Text('Unit: ${_unitDisplayNames[_selectedUnit] ?? _selectedUnit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                      onPressed: () => _showUnitPickerModal(isSecondary: false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Row(
                    children: [
                      const Text('Secondary Unit', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      Switch(
                        value: _enableSecondaryUnit,
                        activeThumbColor: AppConstants.primaryColor,
                        onChanged: (val) {
                          setState(() {
                            _enableSecondaryUnit = val;
                            if (val && _secondaryUnit == null) {
                              _secondaryUnit = 'PCS';
                            }
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              if (_enableSecondaryUnit) ...[
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                  label: Text('Secondary Unit: ${_unitDisplayNames[_secondaryUnit] ?? _secondaryUnit ?? "PCS"}'),
                  onPressed: () => _showUnitPickerModal(isSecondary: true),
                ),
              ],
              const SizedBox(height: 20),

              // Pricing Section Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('PRICING DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _salePriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Sale Price (${AppConstants.currencySymbol})',
                              prefixText: '${AppConstants.currencySymbol} ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextFormField(
                            controller: _purchasePriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: 'Purchase Price (${AppConstants.currencySymbol})',
                              prefixText: '${AppConstants.currencySymbol} ',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Price includes Tax (GST)', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Switch(
                          value: _taxIncluded,
                          activeColor: AppConstants.primaryColor,
                          onChanged: (val) => setState(() => _taxIncluded = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Stock Section Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('STOCK INVENTORY DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _openingStockController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Opening Stock Count',
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            icon: const Icon(Icons.calendar_today_rounded, size: 16),
                            label: Text('As of: ${_asOfDate.day}/${_asOfDate.month}/${_asOfDate.year}'),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: _asOfDate,
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2030),
                              );
                              if (picked != null) setState(() => _asOfDate = picked);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _lowStockAlertController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Low Stock Alert Threshold',
                        hintText: 'Notify when stock falls below this number',
                        prefixIcon: const Icon(Icons.warning_amber_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Tax & GST Section Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.grey[100],
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: isDark ? const Color(0xFF334155) : Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('TAX & GST DETAILS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: _hsnController,
                      decoration: InputDecoration(
                        labelText: 'HSN / SAC Code (Optional)',
                        hintText: 'e.g. 7323',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Exempt from Tax', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        Switch(
                          value: _isExempt,
                          activeColor: AppConstants.primaryColor,
                          onChanged: (val) => setState(() => _isExempt = val),
                        ),
                      ],
                    ),
                    if (!_isExempt) ...[
                      const SizedBox(height: 10),
                      const Text('GST Percentage Rate:', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        children: _gstRates.map((rate) {
                          final isSel = _gstRate == rate;
                          return ChoiceChip(
                            label: Text('${rate.toStringAsFixed(0)}%'),
                            selected: isSel,
                            selectedColor: AppConstants.primaryColor.withOpacity(0.2),
                            backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                            labelStyle: TextStyle(
                              color: isSel ? AppConstants.primaryColor : (isDark ? Colors.white70 : Colors.black87),
                              fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                            ),
                            onSelected: (selected) {
                              if (selected) setState(() => _gstRate = rate);
                            },
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Full-Width SAVE ITEM Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: _saveItem,
                  child: Text(
                    widget.existingItem != null ? 'SAVE CHANGES' : 'SAVE ITEM',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
