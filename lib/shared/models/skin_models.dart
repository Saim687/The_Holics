class SkinService {
  final String id;
  final String name;
  final int durationMin;
  final double price;
  final String? badge; // 'popular', 'new', null
  final bool isActive;

  SkinService({
    required this.id,
    required this.name,
    required this.durationMin,
    required this.price,
    this.badge,
    required this.isActive,
  });

  factory SkinService.fromJson(Map<String, dynamic> json, String docId) {
    return SkinService(
      id: docId,
      name: json['name'] ?? '',
      durationMin: (json['durationMin'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toDouble() ?? 0,
      badge: json['badge'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'durationMin': durationMin,
      'price': price,
      'badge': badge,
      'isActive': isActive,
    };
  }
}

class Specialist {
  final String id;
  final String name;
  final String title; // e.g., "Dr. Layla Hassan"
  final String specialty; // e.g., "Anti-Aging & Hydration"
  final bool isAvailable;
  final String? photoUrl;
  final String? whatsappNumber; // e.g., "+923001234567"
  final String? phone; // alternative contact

  Specialist({
    required this.id,
    required this.name,
    required this.title,
    required this.specialty,
    required this.isAvailable,
    this.photoUrl,
    this.whatsappNumber,
    this.phone,
  });

  factory Specialist.fromJson(Map<String, dynamic> json, String docId) {
    return Specialist(
      id: docId,
      name: json['name'] ?? '',
      title: json['title'] ?? '',
      specialty: json['specialty'] ?? '',
      isAvailable: json['isAvailable'] ?? true,
      photoUrl: json['photoUrl'],
      whatsappNumber: json['whatsappNumber'],
      phone: json['phone'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'title': title,
      'specialty': specialty,
      'isAvailable': isAvailable,
      'photoUrl': photoUrl,
      'whatsappNumber': whatsappNumber,
      'phone': phone,
    };
  }
}

class SkinConsultation {
  final String id;
  final String serviceId;
  final String date;
  final String time;
  final String? specialistId;
  final String notes;
  final String status; // pending, completed, cancelled

  SkinConsultation({
    required this.id,
    required this.serviceId,
    required this.date,
    required this.time,
    this.specialistId,
    required this.notes,
    required this.status,
  });

  factory SkinConsultation.fromJson(Map<String, dynamic> json, String docId) {
    return SkinConsultation(
      id: docId,
      serviceId: json['serviceId'] ?? '',
      date: json['date'] ?? '',
      time: json['time'] ?? '',
      specialistId: json['specialistId'],
      notes: json['notes'] ?? '',
      status: json['status'] ?? 'pending',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'serviceId': serviceId,
      'date': date,
      'time': time,
      'specialistId': specialistId,
      'notes': notes,
      'status': status,
    };
  }
}

class SkinRoutine {
  final String id;
  final String title;
  final List<String> products;
  final List<String> steps;

  SkinRoutine({
    required this.id,
    required this.title,
    required this.products,
    required this.steps,
  });

  factory SkinRoutine.fromJson(Map<String, dynamic> json, String docId) {
    return SkinRoutine(
      id: docId,
      title: json['title'] ?? '',
      products: List<String>.from(json['products'] ?? []),
      steps: List<String>.from(json['steps'] ?? []),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'products': products,
      'steps': steps,
    };
  }
}
