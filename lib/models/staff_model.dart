enum AttendanceStatus { present, absent, halfDay, terminated }

class AttendanceRecord {
  final String id;
  final String staffId;
  final DateTime date;
  final AttendanceStatus status;

  AttendanceRecord({
    required this.id,
    required this.staffId,
    required this.date,
    required this.status,
  });

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) {
    final rawSt = json['status']?.toString().toUpperCase() ?? '';
    AttendanceStatus st = AttendanceStatus.present;
    if (rawSt.contains('ABSENT')) st = AttendanceStatus.absent;
    if (rawSt.contains('HALF')) st = AttendanceStatus.halfDay;
    if (rawSt.contains('TERMINAT')) st = AttendanceStatus.terminated;

    final dStr = json['date']?.toString() ?? json['created_at']?.toString() ?? '';

    return AttendanceRecord(
      id: json['id']?.toString() ?? 'att_${DateTime.now().millisecondsSinceEpoch}',
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
  final String designation; // e.g. 'Polisher', 'Helper', 'Sales Associate', 'Store Manager'
  final double dailyWage;
  final bool isTerminated;
  final String paymentTerms; // e.g. 'Daily', 'Weekly', 'Monthly'
  final DateTime createdAt;

  StaffMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.designation,
    required this.dailyWage,
    this.isTerminated = false,
    this.paymentTerms = 'Daily',
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory StaffMember.fromJson(Map<String, dynamic> json) {
    return StaffMember(
      id: json['id']?.toString() ?? 'stf_${DateTime.now().millisecondsSinceEpoch}',
      name: json['name']?.toString() ?? 'Unnamed Worker',
      phone: json['phone']?.toString() ?? '',
      designation: json['designation']?.toString() ?? 'Worker',
      dailyWage: double.tryParse(json['daily_wage']?.toString() ?? json['salary_amount']?.toString() ?? '0') ?? 0.0,
      isTerminated: json['is_terminated'] == true || json['status'] == 'terminated',
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
      'daily_wage': dailyWage,
      'is_terminated': isTerminated,
      'payment_terms': paymentTerms,
      'created_at': createdAt.toIso8601String(),
    };
  }

  StaffMember copyWith({
    String? id,
    String? name,
    String? phone,
    String? designation,
    double? dailyWage,
    bool? isTerminated,
    String? paymentTerms,
    DateTime? createdAt,
  }) {
    return StaffMember(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      designation: designation ?? this.designation,
      dailyWage: dailyWage ?? this.dailyWage,
      isTerminated: isTerminated ?? this.isTerminated,
      paymentTerms: paymentTerms ?? this.paymentTerms,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
