import 'package:cloud_firestore/cloud_firestore.dart';

class Appointment {
  final String id;
  final String userId;
  final String? userName;
  final String? userEmail;
  final String service;
  final int durationMin;
  final DateTime date;
  final String time; // HH:mm format
  final String specialistId;
  final String? slotId;
  final double price;
  final String status; // 'pending', 'approved', 'confirmed', 'completed', 'cancelled'
  final String? paymentMethod; // e.g. 'manual'
  final String? paymentStatus; // e.g. 'proof_submitted'
  final String? paymentProofUrl;
  final DateTime createdAt;

  Appointment({
    required this.id,
    required this.userId,
    this.userName,
    this.userEmail,
    required this.service,
    required this.durationMin,
    required this.date,
    required this.time,
    required this.specialistId,
    this.slotId,
    required this.price,
    required this.status,
    this.paymentMethod,
    this.paymentStatus,
    this.paymentProofUrl,
    required this.createdAt,
  });

  factory Appointment.fromJson(Map<String, dynamic> json, String docId) {
    return Appointment(
      id: docId,
      userId: json['userId'] ?? '',
      userName: json['userName'],
      userEmail: json['userEmail'],
      service: json['service'] ?? '',
      durationMin: (json['durationMin'] as num?)?.toInt() ?? 0,
      date: _parseDate(json['date']),
      time: json['time'] ?? '',
      specialistId: json['specialistId'] ?? '',
      slotId: json['slotId'],
      price: (json['price'] as num?)?.toDouble() ?? 0,
      status: json['status'] ?? 'pending',
      paymentMethod: json['paymentMethod'],
      paymentStatus: json['paymentStatus'],
      paymentProofUrl: json['paymentProofUrl'],
      createdAt: _parseDate(json['createdAt']),
    );
  }

  static DateTime _parseDate(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is Timestamp) return value.toDate();
    if (value is String && value.isNotEmpty) {
      try {
        return DateTime.parse(value);
      } catch (_) {
        return DateTime.now();
      }
    }
    return DateTime.now();
  }

  static DateTime _dateOnly(DateTime value) {
    return DateTime(value.year, value.month, value.day);
  }

  bool get isPast {
    return _dateOnly(date).isBefore(_dateOnly(DateTime.now()));
  }

  bool get isUpcoming {
    return !isPast;
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'service': service,
      'durationMin': durationMin,
      'date': date,
      'time': time,
      'specialistId': specialistId,
      'slotId': slotId,
      'price': price,
      'status': status,
      'paymentMethod': paymentMethod,
      'paymentStatus': paymentStatus,
      'paymentProofUrl': paymentProofUrl,
      'createdAt': createdAt,
    };
  }

  Appointment copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? service,
    int? durationMin,
    DateTime? date,
    String? time,
    String? specialistId,
    String? slotId,
    double? price,
    String? status,
    String? paymentMethod,
    String? paymentStatus,
    String? paymentProofUrl,
    DateTime? createdAt,
  }) {
    return Appointment(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      service: service ?? this.service,
      durationMin: durationMin ?? this.durationMin,
      date: date ?? this.date,
      time: time ?? this.time,
      specialistId: specialistId ?? this.specialistId,
      slotId: slotId ?? this.slotId,
      price: price ?? this.price,
      status: status ?? this.status,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
