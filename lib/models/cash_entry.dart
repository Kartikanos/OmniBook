import 'package:uuid/uuid.dart';

enum CashEntryType { cashIn, cashOut }

class CashEntry {
  final String id;
  final CashEntryType type;
  final String category; // 'Item Sale', 'Item Purchase', 'Party Payment', 'Miscellaneous', etc.
  final String title;
  final String? partyId;
  final double amount;
  final DateTime date;

  CashEntry({
    String? id,
    required this.type,
    required this.category,
    String? title,
    this.partyId,
    required this.amount,
    DateTime? date,
  })  : id = id ?? const Uuid().v4(),
        title = (title != null && title.trim().isNotEmpty) ? title.trim() : category,
        date = date ?? DateTime.now();

  // Backward compatibility getters for UI display
  String get itemName => title;
  String? get partyName => null;
  String? get itemId => null;
  int get quantity => 1;
  String? get notes => null;

  factory CashEntry.fromJson(Map<String, dynamic> json) {
    final rawType = json['type']?.toString().toUpperCase() ?? '';
    final isCashIn = rawType == 'CASH_IN' || rawType == 'CASHIN' || json['type'] == 'cash_in';

    final String titleVal = json['title']?.toString() ?? json['category']?.toString() ?? 'Miscellaneous';
    final String dateStr = json['created_at']?.toString() ?? json['date']?.toString() ?? '';

    return CashEntry(
      id: json['id']?.toString() ?? const Uuid().v4(),
      type: isCashIn ? CashEntryType.cashIn : CashEntryType.cashOut,
      category: json['category']?.toString() ?? 'Miscellaneous',
      title: titleVal,
      partyId: json['party_id']?.toString(),
      amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0.0,
      date: dateStr.isNotEmpty ? (DateTime.tryParse(dateStr) ?? DateTime.now()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type == CashEntryType.cashIn ? 'CASH_IN' : 'CASH_OUT',
      'category': category,
      'title': title,
      'party_id': partyId,
      'amount': amount,
      'created_at': date.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseInsert(String userId) {
    final map = <String, dynamic>{
      'id': id,
      'user_id': userId,
      'title': title,
      'amount': amount,
      'type': type == CashEntryType.cashIn ? 'CASH_IN' : 'CASH_OUT',
      'category': category,
      'created_at': date.toIso8601String(),
    };

    if (partyId != null && partyId!.isNotEmpty) map['party_id'] = partyId;

    return map;
  }

  Map<String, dynamic> toSupabaseUpdate(String userId) {
    final map = <String, dynamic>{
      'user_id': userId,
      'title': title,
      'amount': amount,
      'type': type == CashEntryType.cashIn ? 'CASH_IN' : 'CASH_OUT',
      'category': category,
    };

    if (partyId != null && partyId!.isNotEmpty) map['party_id'] = partyId;

    return map;
  }
}
