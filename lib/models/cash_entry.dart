enum CashEntryType { cashIn, cashOut }

class CashEntry {
  final String id;
  final CashEntryType type;
  final String category; // 'Item Sale', 'Item Purchase', 'Party Payment', 'Miscellaneous', 'Random'
  final String? itemId;
  final String? itemName;
  final String? partyId;
  final String? partyName;
  final double amount;
  final int quantity;
  final double unitPrice;
  final double gstRate;
  final double gstAmount;
  final String? invoiceNo;
  final DateTime date;
  final String? notes;

  CashEntry({
    required this.id,
    required this.type,
    required this.category,
    this.itemId,
    this.itemName,
    this.partyId,
    this.partyName,
    required this.amount,
    this.quantity = 1,
    this.unitPrice = 0.0,
    this.gstRate = 0.0,
    this.gstAmount = 0.0,
    this.invoiceNo,
    DateTime? date,
    this.notes,
  }) : date = date ?? DateTime.now();

  factory CashEntry.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString().toUpperCase() ?? '';
    final isCashIn = rawType == 'CASH_IN' || rawType == 'CASHIN' || json['type'] == 'cash_in';

    final String? titleVal = json['title']?.toString() ?? json['item_name']?.toString();
    final String dateStr = json['created_at']?.toString() ?? json['date']?.toString() ?? '';

    final String rawQtyStr = json['quantity']?.toString() ?? '1';
    final int qtyVal = (double.tryParse(rawQtyStr) ?? 1.0).toInt();

    final String rawGstStr = (json['gst_rate']?.toString() ?? '0').replaceAll('%', '').trim();
    final double gstVal = double.tryParse(rawGstStr) ?? 0.0;

    return CashEntry(
      id: json['id']?.toString() ?? 'cash_${DateTime.now().millisecondsSinceEpoch}',
      type: isCashIn ? CashEntryType.cashIn : CashEntryType.cashOut,
      category: json['category']?.toString() ?? 'Miscellaneous',
      itemId: json['item_id']?.toString(),
      itemName: titleVal,
      partyId: json['party_id']?.toString(),
      partyName: json['party_name']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      quantity: qtyVal,
      unitPrice: double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0,
      gstRate: gstVal,
      gstAmount: double.tryParse(json['gst_amount']?.toString() ?? '0') ?? 0.0,
      invoiceNo: json['invoice_no']?.toString(),
      date: dateStr.isNotEmpty ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now(),
      notes: json['notes']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == CashEntryType.cashIn ? 'CASH_IN' : 'CASH_OUT',
      'category': category,
      'title': itemName ?? category,
      'item_id': itemId,
      'item_name': itemName,
      'party_id': partyId,
      'party_name': partyName,
      'amount': amount,
      'quantity': quantity,
      'unit_price': unitPrice,
      'gst_rate': gstRate,
      'gst_amount': gstAmount,
      'invoice_no': invoiceNo,
      'date': date.toIso8601String(),
      'created_at': date.toIso8601String(),
      'notes': notes,
    };
  }

  /// INSERT payload — sends only columns that exist in cashbook_entries table:
  /// user_id, title, amount, type, category, created_at, party_id, notes.
  Map<String, dynamic> toSupabaseInsert(String userId) {
    final map = <String, dynamic>{
      'user_id': userId,
      'title': itemName ?? category,
      'amount': amount,
      'type': type == CashEntryType.cashIn ? 'CASH_IN' : 'CASH_OUT',
      'category': category,
      'created_at': date.toIso8601String(),
    };

    if (partyId != null && partyId!.isNotEmpty) map['party_id'] = partyId;
    if (notes != null && notes!.isNotEmpty) map['notes'] = notes;

    return map;
  }

  /// UPDATE payload — same as insert but without created_at.
  Map<String, dynamic> toSupabaseUpdate(String userId) {
    final map = <String, dynamic>{
      'user_id': userId,
      'title': itemName ?? category,
      'amount': amount,
      'type': type == CashEntryType.cashIn ? 'CASH_IN' : 'CASH_OUT',
      'category': category,
    };

    if (partyId != null && partyId!.isNotEmpty) map['party_id'] = partyId;
    if (notes != null && notes!.isNotEmpty) map['notes'] = notes;

    return map;
  }
}
