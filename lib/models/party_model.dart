enum PartyType { supplier, customer, both }

class Party {
  final String id;
  final String name;
  final String phone;
  final String? address;
  final PartyType type;
  final double openingBalance;
  final double currentBalance;
  final DateTime createdAt;

  Party({
    required this.id,
    required this.name,
    required this.phone,
    this.address,
    required this.type,
    this.openingBalance = 0.0,
    double? currentBalance,
    DateTime? createdAt,
  })  : currentBalance = currentBalance ?? openingBalance,
        createdAt = createdAt ?? DateTime.now();

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

    final double bal = double.tryParse(json['balance']?.toString() ?? '') ??
        double.tryParse(json['current_balance']?.toString() ?? '') ??
        double.tryParse(json['opening_balance']?.toString() ?? '') ??
        0.0;

    final double opBal = double.tryParse(json['opening_balance']?.toString() ?? '') ?? bal;
    final dateStr = json['created_at']?.toString() ?? '';

    return Party(
      id: json['id']?.toString() ?? 'pty_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Unnamed Party',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString(),
      type: pType,
      openingBalance: opBal,
      currentBalance: bal,
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
      'address': address,
      'type': pTypeStr.toLowerCase(),
      'party_type': pTypeStr,
      'opening_balance': openingBalance,
      'current_balance': currentBalance,
      'balance': currentBalance,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// INSERT payload — only columns guaranteed in Supabase ledgers schema.
  Map<String, dynamic> toSupabaseInsert(String userId) {
    String pType = 'CUSTOMER';
    if (type == PartyType.supplier) pType = 'SUPPLIER';
    if (type == PartyType.both) pType = 'BOTH';

    final map = <String, dynamic>{
      'user_id': userId,
      'name': name,
      'phone': phone,
      'party_type': pType,
      'balance': currentBalance,
      'opening_balance': openingBalance,
      'created_at': createdAt.toIso8601String(),
    };

    // Only include id if it's a valid UUID string (prevents Postgres 22P02 error from non-UUID string like 'pty_...')
    final isUuid = RegExp(r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$').hasMatch(id);
    if (isUuid) {
      map['id'] = id;
    }

    return map;
  }

  /// UPDATE payload — maps balance and opening_balance columns without id.
  Map<String, dynamic> toSupabaseUpdate(String userId) {
    String pType = 'CUSTOMER';
    if (type == PartyType.supplier) pType = 'SUPPLIER';
    if (type == PartyType.both) pType = 'BOTH';

    return {
      'user_id': userId,
      'name': name,
      'phone': phone,
      'party_type': pType,
      'balance': currentBalance,
      'opening_balance': openingBalance,
    };
  }

  Party copyWith({
    String? id,
    String? name,
    String? phone,
    String? address,
    PartyType? type,
    double? openingBalance,
    double? currentBalance,
    DateTime? createdAt,
  }) {
    return Party(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      type: type ?? this.type,
      openingBalance: openingBalance ?? this.openingBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
