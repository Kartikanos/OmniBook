class InventoryItem {
  final String id;
  final String name;
  final double unitPrice;
  final int stockQuantity;
  final String unit; // 'Pieces', 'Kg', 'Dozen', 'Set'
  final double? weightKg;
  final double gstRate; // 0, 5, 12, 18
  final String? category;
  final DateTime createdAt;

  InventoryItem({
    required this.id,
    required this.name,
    required this.unitPrice,
    required this.stockQuantity,
    this.unit = 'Pieces',
    this.weightKg,
    this.gstRate = 5.0,
    this.category,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  double get cgstRate => gstRate / 2;
  double get sgstRate => gstRate / 2;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final String nameVal = (json['item_name']?.toString()) ?? (json['name']?.toString()) ?? 'Unnamed Item';
    final double priceVal = double.tryParse(json['unit_price']?.toString() ?? '0') ?? 0.0;
    
    final String rawStockStr = json['stock_quantity']?.toString() ?? '0';
    final int qtyVal = (double.tryParse(rawStockStr) ?? 0.0).toInt();

    final String rawGstStr = (json['gst_rate']?.toString() ?? '5').replaceAll('%', '').trim();
    final double gstVal = double.tryParse(rawGstStr) ?? 5.0;

    final String dateStr = json['created_at']?.toString() ?? '';

    return InventoryItem(
      id: json['id']?.toString() ?? 'ut_${DateTime.now().millisecondsSinceEpoch}',
      name: nameVal,
      unitPrice: priceVal,
      stockQuantity: qtyVal,
      unit: json['unit']?.toString() ?? 'Pieces',
      weightKg: double.tryParse(json['weight_kg']?.toString() ?? ''),
      gstRate: gstVal,
      category: json['category']?.toString() ?? 'General Utensils',
      createdAt: dateStr.isNotEmpty ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'item_name': name,
      'unit_price': unitPrice,
      'stock_quantity': stockQuantity,
      'unit': unit,
      'weight_kg': weightKg,
      'gst_rate': gstRate,
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseInsert(String userId) {
    return {
      'user_id': userId,
      'item_name': name,
      'stock_quantity': stockQuantity,
      'unit_price': unitPrice,
      'gst_rate': gstRate,
      'category': category ?? 'General Utensils',
      'created_at': createdAt.toIso8601String(),
    };
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    double? unitPrice,
    int? stockQuantity,
    String? unit,
    double? weightKg,
    double? gstRate,
    String? category,
    DateTime? createdAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unitPrice: unitPrice ?? this.unitPrice,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      unit: unit ?? this.unit,
      weightKg: weightKg ?? this.weightKg,
      gstRate: gstRate ?? this.gstRate,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
