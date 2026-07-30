import 'package:uuid/uuid.dart';

class InventoryItem {
  final String id;
  final String name;
  final String unit; // NOS, PCS, KGS, BAG, WKS, MON, YRS, BAL, BOU, BTL, BOX
  final String? secondaryUnit;
  final double salePrice;
  final double purchasePrice;
  final bool taxIncluded;
  final int openingStock;
  final int stockQuantity;
  final int lowStockAlert;
  final String? hsn;
  final double gstRate; // 0, 5, 12, 18, 28
  final double? weightKg;
  final DateTime asOfDate;
  final String? category;
  final DateTime createdAt;

  InventoryItem({
    String? id,
    required this.name,
    this.unit = 'PCS',
    this.secondaryUnit,
    double? salePrice,
    double? unitPrice,
    this.purchasePrice = 0.0,
    this.taxIncluded = false,
    this.openingStock = 0,
    int? stockQuantity,
    this.lowStockAlert = 5,
    this.hsn,
    this.gstRate = 5.0,
    this.weightKg,
    DateTime? asOfDate,
    this.category,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        salePrice = salePrice ?? (unitPrice ?? 0.0),
        stockQuantity = stockQuantity ?? openingStock,
        asOfDate = asOfDate ?? DateTime.now(),
        createdAt = createdAt ?? DateTime.now();

  double get unitPrice => salePrice > 0 ? salePrice : (purchasePrice > 0 ? purchasePrice : 0.0);
  double get cgstRate => gstRate / 2;
  double get sgstRate => gstRate / 2;

  factory InventoryItem.fromJson(Map<String, dynamic> json) {
    final String nameVal = json['name']?.toString() ?? json['item_name']?.toString() ?? 'Unnamed Item';
    final double saleP = double.tryParse(json['sale_price']?.toString() ?? json['unit_price']?.toString() ?? '0') ?? 0.0;
    final double purchP = double.tryParse(json['purchase_price']?.toString() ?? '0') ?? 0.0;
    final int opStock = (double.tryParse(json['opening_stock']?.toString() ?? '0') ?? 0.0).toInt();
    final int curStock = (double.tryParse(json['stock_quantity']?.toString() ?? opStock.toString()) ?? opStock.toDouble()).toInt();
    final int alertVal = (double.tryParse(json['low_stock_alert']?.toString() ?? '5') ?? 5.0).toInt();
    final double gstVal = double.tryParse((json['gst_rate']?.toString() ?? '5').replaceAll('%', '').trim()) ?? 5.0;

    return InventoryItem(
      id: json['id']?.toString() ?? const Uuid().v4(),
      name: nameVal,
      unit: json['unit']?.toString() ?? 'PCS',
      secondaryUnit: json['secondary_unit']?.toString(),
      salePrice: saleP,
      purchasePrice: purchP,
      taxIncluded: json['tax_included'] == true,
      openingStock: opStock,
      stockQuantity: curStock,
      lowStockAlert: alertVal,
      hsn: json['hsn']?.toString(),
      gstRate: gstVal,
      weightKg: double.tryParse(json['weight_kg']?.toString() ?? ''),
      asOfDate: json['as_of_date'] != null ? (DateTime.tryParse(json['as_of_date'].toString()) ?? DateTime.now()) : DateTime.now(),
      category: json['category']?.toString() ?? 'General Utensils',
      createdAt: json['created_at'] != null ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'unit': unit,
      'secondary_unit': secondaryUnit,
      'sale_price': salePrice,
      'purchase_price': purchasePrice,
      'tax_included': taxIncluded,
      'opening_stock': openingStock,
      'stock_quantity': stockQuantity,
      'low_stock_alert': lowStockAlert,
      'hsn': hsn,
      'gst_rate': gstRate,
      'weight_kg': weightKg,
      'as_of_date': asOfDate.toIso8601String(),
      'category': category,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseInsert(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'unit': unit,
      'sale_price': salePrice,
      'purchase_price': purchasePrice,
      'tax_included': taxIncluded,
      'opening_stock': openingStock,
      'stock_quantity': stockQuantity,
      'low_stock_alert': lowStockAlert,
      'hsn': hsn,
      'gst_rate': gstRate,
      'weight_kg': weightKg,
      'category': category ?? 'General Utensils',
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseUpdate(String userId) {
    return {
      'user_id': userId,
      'name': name,
      'unit': unit,
      'sale_price': salePrice,
      'purchase_price': purchasePrice,
      'tax_included': taxIncluded,
      'opening_stock': openingStock,
      'stock_quantity': stockQuantity,
      'low_stock_alert': lowStockAlert,
      'hsn': hsn,
      'gst_rate': gstRate,
      'weight_kg': weightKg,
      'category': category ?? 'General Utensils',
    };
  }

  InventoryItem copyWith({
    String? id,
    String? name,
    String? unit,
    String? secondaryUnit,
    double? salePrice,
    double? purchasePrice,
    bool? taxIncluded,
    int? openingStock,
    int? stockQuantity,
    int? lowStockAlert,
    String? hsn,
    double? gstRate,
    double? weightKg,
    DateTime? asOfDate,
    String? category,
    DateTime? createdAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      unit: unit ?? this.unit,
      secondaryUnit: secondaryUnit ?? this.secondaryUnit,
      salePrice: salePrice ?? this.salePrice,
      purchasePrice: purchasePrice ?? this.purchasePrice,
      taxIncluded: taxIncluded ?? this.taxIncluded,
      openingStock: openingStock ?? this.openingStock,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      lowStockAlert: lowStockAlert ?? this.lowStockAlert,
      hsn: hsn ?? this.hsn,
      gstRate: gstRate ?? this.gstRate,
      weightKg: weightKg ?? this.weightKg,
      asOfDate: asOfDate ?? this.asOfDate,
      category: category ?? this.category,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
