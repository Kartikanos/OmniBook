import 'package:uuid/uuid.dart';

enum PartyType { supplier, customer, both }

class Party {
  final String id;
  final String name;
  final String phone;
  final PartyType type;
  final double openingBalance;
  final double currentBalance;
  final DateTime createdAt;

  Party({
    String? id,
    required this.name,
    required this.phone,
    required this.type,
    this.openingBalance = 0.0,
    double? currentBalance,
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        currentBalance = currentBalance ?? openingBalance,
        createdAt = createdAt ?? DateTime.now();

  String? get address => null;

  String get typeLabel {
    switch (type) {
      case PartyType.supplier:
        return 'SUPPLIER';
      case PartyType.customer:
        return 'CUSTOMER';
      case PartyType.both:
        return 'SUPPLIER / CUSTOMER';
    }
  }

  factory Party.fromJson(Map<String, dynamic> json) {
    final rawType = (json['party_type']?.toString() ?? json['type']?.toString() ?? '').toUpperCase();
    PartyType pType = PartyType.customer;
    if (rawType.contains('BOTH') || (rawType.contains('CUSTOMER') && rawType.contains('SUPPLIER'))) {
      pType = PartyType.both;
    } else if (rawType.contains('SUPPLIER')) {
      pType = PartyType.supplier;
    }

    final double opBal = double.tryParse(json['opening_balance']?.toString() ?? '') ?? 0.0;
    final double currBal = double.tryParse(json['current_balance']?.toString() ?? '') ?? opBal;
    final dateStr = json['created_at']?.toString() ?? '';

    return Party(
      id: json['id']?.toString() ?? const Uuid().v4(),
      name: json['name']?.toString() ?? 'Unnamed Party',
      phone: json['phone']?.toString() ?? '',
      type: pType,
      openingBalance: opBal,
      currentBalance: currBal,
      createdAt: dateStr.isNotEmpty ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    String pTypeStr = 'CUSTOMER';
    if (type == PartyType.supplier) pTypeStr = 'SUPPLIER';
    if (type == PartyType.both) pTypeStr = 'BOTH';

    return {
      'id': id,
      'name': name,
      'phone': phone,
      'party_type': pTypeStr,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseInsert(String userId) {
    String pTypeStr = 'CUSTOMER';
    if (type == PartyType.supplier) pTypeStr = 'SUPPLIER';
    if (type == PartyType.both) pTypeStr = 'BOTH';

    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'party_type': pTypeStr,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseUpdate(String userId) {
    String pTypeStr = 'CUSTOMER';
    if (type == PartyType.supplier) pTypeStr = 'SUPPLIER';
    if (type == PartyType.both) pTypeStr = 'BOTH';

    return {
      'user_id': userId,
      'name': name,
      'phone': phone,
      'party_type': pTypeStr,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
    };
  }

  Party copyWith({
    String? id,
    String? name,
    String? phone,
    PartyType? type,
    double? openingBalance,
    double? currentBalance,
    DateTime? createdAt,
  }) {
    return Party(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
