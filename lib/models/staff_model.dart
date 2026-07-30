import 'package:uuid/uuid.dart';

enum AttendanceStatus { present, absent, halfDay, terminated }

class AttendanceRecord {
  final String id;
  final String staffId;
  final DateTime date;
  final AttendanceStatus status;

  AttendanceRecord({
    String? id,
    required this.staffId,
    required this.date,
    required this.status,
  }) : id = id ?? const Uuid().v4();

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final rawSt = json['status']?.toString().toUpperCase() ?? '';
    AttendanceStatus st = AttendanceStatus.present;
    if (rawSt.contains('ABSENT')) st = AttendanceStatus.absent;
    if (rawSt.contains('HALF')) st = AttendanceStatus.halfDay;
    if (rawSt.contains('TERMINAT')) st = AttendanceStatus.terminated;

    final dStr = json['date']?.toString() ?? json['created_at']?.toString() ?? '';

    return AttendanceRecord(
      id: json['id']?.toString() ?? const Uuid().v4(),
      staffId: json['staff_id']?.toString() ?? '',
      date: dStr.isNotEmpty ? (DateTime.tryParse(dStr) ?? DateTime.now()) : DateTime.now(),
      status: st,
    );
  }

  Map<String, dynamic> toJson() {
    String stStr = 'present';
    if (status == AttendanceStatus.absent) stStr = 'absent';
    if (status == AttendanceStatus.halfDay) stStr = 'half_day';
    if (status == AttendanceStatus.terminated) stStr = 'terminated';

    return {
      'id': id,
      'staff_id': staffId,
      'date': date.toIso8601String(),
      'status': stStr,
    };
  }
}

class StaffMember {
  final String id;
  final String name;
  final String phone;
  final String designation; // e.g. 'Polisher', 'Helper', 'Sales Associate'
  final double dailyWage;
  final bool isActive;
  final String paymentTerms;
  final DateTime createdAt;

  StaffMember({
    String? id,
    required this.name,
    required this.phone,
    this.designation = 'Worker',
    required this.dailyWage,
    this.isActive = true,
    this.paymentTerms = 'Daily',
    DateTime? createdAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  bool get isTerminated => !isActive;
  double get dailySalary => dailyWage;

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    final bool active = json['is_active'] == null ? (json['is_terminated'] != true) : (json['is_active'] == true);

    return StaffMember(
      id: json['id']?.toString() ?? const Uuid().v4(),
      name: json['name']?.toString() ?? 'Unnamed Worker',
      phone: json['phone']?.toString() ?? '',
      designation: json['designation']?.toString() ?? 'Worker',
      dailyWage: double.tryParse(json['daily_salary']?.toString() ?? json['daily_wage']?.toString() ?? '0') ?? 0.0,
      isActive: active,
      paymentTerms: json['payment_terms']?.toString() ?? 'Daily',
      createdAt: json['created_at'] != null
          ? (DateTime.tryParse(json['created_at'].toString()) ?? DateTime.now())
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'designation': designation,
      'daily_salary': dailyWage,
      'daily_wage': dailyWage,
      'is_active': isActive,
      'is_terminated': !isActive,
      'payment_terms': paymentTerms,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseInsert(String userId) {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'phone': phone,
      'daily_salary': dailyWage,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Map<String, dynamic> toSupabaseUpdate(String userId) {
    return {
      'user_id': userId,
      'name': name,
      'phone': phone,
      'daily_salary': dailyWage,
      'is_active': isActive,
    };
  }

  StaffMember copyWith({
    String? id,
    String? name,
    String? phone,
    String? designation,
    double? dailyWage,
    bool? isActive,
    String? paymentTerms,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      designation: designation ?? this.designation,
      dailyWage: dailyWage ?? this.dailyWage,
      isActive: isActive ?? this.isActive,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
