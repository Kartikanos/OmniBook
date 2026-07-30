class InvoiceItemLine {
  final String itemId;
  final String itemName;
  final String unit;
  final double? weightKg;
  final int quantity;
  final double unitPrice;
  final double gstRate;

  InvoiceItemLine({
    required this.itemId,
    required this.itemName,
    this.unit = 'Pieces',
    this.weightKg,
    required this.quantity,
    required this.unitPrice,
    required this.gstRate,
  });

  double get lineTotalWithoutGst => quantity * unitPrice;
  double get cgstRate => gstRate / 2;
  double get sgstRate => gstRate / 2;
  double get cgstAmount => lineTotalWithoutGst * (cgstRate / 100);
  double get sgstAmount => lineTotalWithoutGst * (sgstRate / 100);
  double get totalGstAmount => cgstAmount + sgstAmount;
  double get lineGrandTotal => lineTotalWithoutGst + totalGstAmount;

  factory InvoiceItemLine.fromJson(Map<String, dynamic> json) {
    return InvoiceItemLine(
      itemId: json['item_id'] as String? ?? '',
      itemName: json['item_name'] as String? ?? '',
      unit: json['unit'] as String? ?? 'Pieces',
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      quantity: (json['quantity'] as num?)?.toInt() ?? 1,
      unitPrice: (json['unit_price'] as num?)?.toDouble() ?? 0.0,
      gstRate: (json['gst_rate'] as num?)?.toDouble() ?? 5.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'item_id': itemId,
      'item_name': itemName,
      'unit': unit,
      'weight_kg': weightKg,
      'quantity': quantity,
      'unit_price': unitPrice,
      'gst_rate': gstRate,
    };
  }
}

class Invoice {
  final String id;
  final String invoiceNo;
  final String? partyId;
  final String partyName;
  final DateTime date;
  final List<InvoiceItemLine> items;
  final double subtotal;
  final double cgstAmount;
  final double sgstAmount;
  final double grandTotal;

  Invoice({
    required this.id,
    required this.invoiceNo,
    this.partyId,
    required this.partyName,
    DateTime? date,
    required this.items,
    required this.subtotal,
    required this.cgstAmount,
    required this.sgstAmount,
    required this.grandTotal,
  }) : date = date ?? DateTime.now();

  double get totalGst => cgstAmount + sgstAmount;

  factory Invoice.fromJson(Map<String, dynamic> json) {
    var rawItems = json['items'] as List? ?? [];
    List<InvoiceItemLine> itemList =
        rawItems.map((i) => InvoiceItemLine.fromJson(i as Map<String, dynamic>)).toList();

    return Invoice(
      id: json['id'] as String,
      invoiceNo: json['invoice_no'] as String,
      partyId: json['party_id'] as String?,
      partyName: json['party_name'] as String? ?? 'Counter Customer',
      date: json['date'] != null ? DateTime.parse(json['date'] as String) : DateTime.now(),
      items: itemList,
      subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0.0,
      cgstAmount: (json['cgst_amount'] as num?)?.toDouble() ?? 0.0,
      sgstAmount: (json['sgst_amount'] as num?)?.toDouble() ?? 0.0,
      grandTotal: (json['grand_total'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'invoice_no': invoiceNo,
      'party_id': partyId,
      'party_name': partyName,
      'date': date.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
      'subtotal': subtotal,
      'cgst_amount': cgstAmount,
      'sgst_amount': sgstAmount,
      'grand_total': grandTotal,
    };
  }
}
