// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/constants.dart';
import '../models/inventory_item.dart';
import '../models/invoice_model.dart';
import '../models/party_model.dart';
import '../services/database_service.dart';
import '../services/auth_service.dart';
import '../services/invoice_pdf_service.dart';

class GstBillingScreen extends StatefulWidget {
  const GstBillingScreen({super.key});

  @override
  State<GstBillingScreen> createState() => _GstBillingScreenState();
}

class _GstBillingScreenState extends State<GstBillingScreen> {
  Party? _selectedParty;
  final TextEditingController _customPartyController = TextEditingController(text: 'Counter Customer');
  final String _invoiceNo = 'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

  final List<InvoiceItemLine> _billItems = [];

  void _addItemToBill(InventoryItem item) {
    setState(() {
      _billItems.add(
        InvoiceItemLine(
          itemId: item.id,
          itemName: item.name,
          unit: item.unit,
          weightKg: item.weightKg,
          quantity: 1,
          unitPrice: item.unitPrice,
          gstRate: item.gstRate,
        ),
      );
    });
  }

  void _updateItemQuantity(int index, int delta) {
    setState(() {
      final current = _billItems[index];
      final newQty = (current.quantity + delta).clamp(1, 9999);
      _billItems[index] = InvoiceItemLine(
        itemId: current.itemId,
        itemName: current.itemName,
        unit: current.unit,
        weightKg: current.weightKg,
        quantity: newQty,
        unitPrice: current.unitPrice,
        gstRate: current.gstRate,
      );
    });
  }

  void _updateItemGstRate(int index, double newGst) {
    setState(() {
      final current = _billItems[index];
      _billItems[index] = InvoiceItemLine(
        itemId: current.itemId,
        itemName: current.itemName,
        unit: current.unit,
        weightKg: current.weightKg,
        quantity: current.quantity,
        unitPrice: current.unitPrice,
        gstRate: newGst,
      );
    });
  }

  void _removeItem(int index) {
    setState(() {
      _billItems.removeAt(index);
    });
  }

  double get subtotal => _billItems.fold(0.0, (sum, i) => sum + i.lineTotalWithoutGst);
  double get totalCgst => _billItems.fold(0.0, (sum, i) => sum + i.cgstAmount);
  double get totalSgst => _billItems.fold(0.0, (sum, i) => sum + i.sgstAmount);
  double get grandTotal => subtotal + totalCgst + totalSgst;

  Future<void> _saveAndPrintInvoice() async {
    if (_billItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least 1 utensil item to the bill.')),
      );
      return;
    }

    final dbService = Provider.of<DatabaseService>(context, listen: false);
    final authService = Provider.of<AuthService>(context, listen: false);

    final invoice = Invoice(
      id: 'inv_${DateTime.now().millisecondsSinceEpoch}',
      invoiceNo: _invoiceNo,
      partyId: _selectedParty?.id,
      partyName: _selectedParty?.name ?? _customPartyController.text.trim(),
      items: _billItems,
      subtotal: subtotal,
      cgstAmount: totalCgst,
      sgstAmount: totalSgst,
      grandTotal: grandTotal,
    );

    final success = await dbService.createInvoice(invoice, isGuest: authService.isGuestMode);

    if (mounted) {
      if (success) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.print_rounded, color: AppConstants.primaryColor),
                SizedBox(width: 8),
                Text('Invoice Generated!'),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Invoice #${invoice.invoiceNo} successfully created.'),
                const SizedBox(height: 8),
                Text('Party: ${invoice.partyName}'),
                Text('Grand Total: ${AppConstants.formatCurrency(invoice.grandTotal)}'),
                const SizedBox(height: 12),
                const Text('Logged to CashBook and inventory updated!'),
              ],
            ),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            actions: [
              TextButton.icon(
                icon: const Icon(Icons.picture_as_pdf_rounded),
                label: const Text('Print / Save PDF'),
                onPressed: () async {
                  await InvoicePdfService.printOrShareInvoice(invoice);
                },
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () {
                  Navigator.of(ctx).pop();
                  setState(() {
                    _billItems.clear();
                  });
                },
                child: const Text('OK & Clear'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dbService = Provider.of<DatabaseService>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Safely match selected party by ID to avoid DropdownMenuItem assertion
    Party? currentPartyValue;
    if (_selectedParty != null) {
      final matches = dbService.parties.where((p) => p.id == _selectedParty!.id);
      if (matches.isNotEmpty) {
        currentPartyValue = matches.first;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick GST Billing Invoice'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_rounded),
            onPressed: _saveAndPrintInvoice,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 40),
          child: Column(
            children: [
              // Invoice Header Info Card
              Card(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: isDark ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              'Invoice No: $_invoiceNo',
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Text(
                            'Date: ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}',
                            style: TextStyle(fontSize: 12, color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<Party?>(
                        value: currentPartyValue,
                        isExpanded: true,
                        decoration: InputDecoration(
                          labelText: 'Select Customer / Supplier',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                        items: [
                          const DropdownMenuItem<Party?>(value: null, child: Text('Counter Customer (Walk-in)')),
                          ...dbService.parties.map((p) => DropdownMenuItem<Party?>(value: p, child: Text('${p.name} (${p.typeLabel})'))),
                        ],
                        onChanged: (p) => setState(() => _selectedParty = p),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Item Search & Add Bar
              Autocomplete<InventoryItem>(
                displayStringForOption: (item) => '${item.name} (${AppConstants.formatCurrency(item.unitPrice)})',
                optionsBuilder: (TextEditingValue val) => dbService.searchInventory(val.text),
                onSelected: _addItemToBill,
                fieldViewBuilder: (ctx, controller, focusNode, onComplete) {
                  return TextField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      hintText: 'Search utensil item to add to bill...',
                      prefixIcon: const Icon(Icons.add_shopping_cart_rounded),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  );
                },
              ),
              const SizedBox(height: 12),

              // Bill Line Items Container
              Container(
                constraints: const BoxConstraints(minHeight: 160, maxHeight: 280),
                child: _billItems.isEmpty
                    ? Center(
                        child: Text(
                          'No items added to invoice. Search above to add items.',
                          style: TextStyle(color: isDark ? AppConstants.textMutedDark : AppConstants.textMutedLight),
                        ),
                      )
                    : ListView.separated(
                        shrinkWrap: true,
                        itemCount: _billItems.length,
                        separatorBuilder: (ctx, idx) => const SizedBox(height: 8),
                        itemBuilder: (ctx, idx) {
                          final item = _billItems[idx];
                          return Card(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: isDark ? const BorderSide(color: Color(0xFF334155)) : BorderSide.none,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          item.itemName,
                                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                        ),
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline_rounded, color: AppConstants.accentColor, size: 20),
                                        onPressed: () => _removeItem(idx),
                                      ),
                                    ],
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          IconButton(
                                            icon: const Icon(Icons.remove_circle_outline, size: 20),
                                            onPressed: () => _updateItemQuantity(idx, -1),
                                          ),
                                          Text('${item.quantity} ${item.unit}', style: const TextStyle(fontWeight: FontWeight.bold)),
                                          IconButton(
                                            icon: const Icon(Icons.add_circle_outline, size: 20),
                                            onPressed: () => _updateItemQuantity(idx, 1),
                                          ),
                                        ],
                                      ),
                                      DropdownButton<double>(
                                        value: item.gstRate,
                                        items: const [
                                          DropdownMenuItem(value: 0.0, child: Text('GST 0%')),
                                          DropdownMenuItem(value: 5.0, child: Text('GST 5%')),
                                          DropdownMenuItem(value: 12.0, child: Text('GST 12%')),
                                          DropdownMenuItem(value: 18.0, child: Text('GST 18%')),
                                        ],
                                        onChanged: (v) {
                                          if (v != null) _updateItemGstRate(idx, v);
                                        },
                                      ),
                                      Text(
                                        AppConstants.formatCurrency(item.lineGrandTotal),
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: AppConstants.primaryAccent),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),

              const SizedBox(height: 14),

              // Invoice Total Summary & Action
              Card(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                elevation: 4,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:'),
                          Text(AppConstants.formatCurrency(subtotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('CGST + SGST:'),
                          Text(
                            '${AppConstants.formatCurrency(totalCgst)} + ${AppConstants.formatCurrency(totalSgst)}',
                            style: const TextStyle(fontSize: 12, color: AppConstants.secondaryColor),
                          ),
                        ],
                      ),
                      const Divider(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Grand Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          FittedBox(
                            child: Text(
                              AppConstants.formatCurrency(grandTotal),
                              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppConstants.cashInColor),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppConstants.primaryColor,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                          onPressed: _saveAndPrintInvoice,
                          icon: const Icon(Icons.print_rounded),
                          label: const Text('Save & Print Invoice', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                        ),
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
}
