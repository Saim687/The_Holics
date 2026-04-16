import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:the_holics/shared/models/user_model.dart';
import 'package:the_holics/shared/models/subscription_model.dart';
import 'package:the_holics/shared/models/appointment_model.dart';
import 'package:the_holics/shared/models/workout_model.dart';
import 'package:the_holics/shared/models/skin_models.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const Map<String, double> _defaultSubscriptionPricing = {
    'monthly': 49,
    'quarterly': 39,
    'yearly': 29,
    'registrationFee': 1000,
  };

  // === USERS ===
  Future<void> createUser(String uid, User user) async {
    try {
      await _firestore.collection('users').doc(uid).set(user.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getUser(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (doc.exists) {
        return User.fromJson(doc.data()!, uid);
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<User?> getUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection('users')
          .where('email', isEqualTo: email)
          .limit(1)
          .get();

      if (query.docs.isNotEmpty) {
        final doc = query.docs.first;
        return User.fromJson(doc.data(), doc.id);
      }

      return null;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateUser(String uid, Map<String, dynamic> data) async {
    try {
      await _firestore.collection('users').doc(uid).update(data);
    } catch (e) {
      rethrow;
    }
  }

  Stream<User?> watchUser(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return User.fromJson(doc.data()!, uid);
      }
      return null;
    });
  }

  // === SUBSCRIPTIONS ===
  Future<void> createSubscription(String uid, Subscription subscription) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('subscriptions')
          .add(subscription.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Subscription>> getSubscriptions(String uid) async {
    try {
      final docs = await _firestore
          .collection('users')
          .doc(uid)
          .collection('subscriptions')
          .get();
      return docs.docs
          .map((doc) => Subscription.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // === APPOINTMENTS ===
  Future<void> createAppointment(String uid, Appointment appointment) async {
    try {
      final slotId = _buildAppointmentSlotId(appointment);
      final slotRef = _firestore.collection('booked_slots').doc(slotId);
      final appointmentRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('appointments')
          .doc();

      await _firestore.runTransaction((transaction) async {
        final slotSnap = await transaction.get(slotRef);
        if (slotSnap.exists) {
          throw Exception('This slot is already booked. Please choose another slot.');
        }

        transaction.set(slotRef, {
          'slotId': slotId,
          'specialistId': appointment.specialistId,
          'date': _dateKey(appointment.date),
          'time': appointment.time,
          'timeKey': _timeKey(appointment.time),
          'userId': uid,
          'appointmentPath': appointmentRef.path,
          'status': appointment.status,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(
          appointmentRef,
          appointment.copyWith(slotId: slotId).toJson(),
        );
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Appointment>> getAppointments(String uid) async {
    try {
      final docs = await _firestore
          .collection('users')
          .doc(uid)
          .collection('appointments')
          .get();
      return docs.docs
          .map((doc) => Appointment.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> updateAppointment(
      String uid, String appointmentId, Map<String, dynamic> data) async {
    try {
      final appointmentRef = _firestore
          .collection('users')
          .doc(uid)
          .collection('appointments')
          .doc(appointmentId);

      await _firestore.runTransaction((transaction) async {
        final appointmentSnap = await transaction.get(appointmentRef);
        if (!appointmentSnap.exists) {
          throw Exception('Appointment not found.');
        }

        final existing = Appointment.fromJson(
          appointmentSnap.data()!,
          appointmentSnap.id,
        );

        final newStatus = data['status']?.toString().toLowerCase();
        final oldStatus = existing.status.toLowerCase();

        transaction.update(appointmentRef, data);

        final shouldReleaseSlot =
            newStatus == 'cancelled' && oldStatus != 'cancelled';
        if (shouldReleaseSlot) {
          final slotId = existing.slotId ?? _buildAppointmentSlotId(existing);
          final slotRef = _firestore.collection('booked_slots').doc(slotId);
          transaction.delete(slotRef);
        } else if (newStatus != null && existing.slotId != null) {
          final slotRef = _firestore.collection('booked_slots').doc(existing.slotId!);
          transaction.set(
            slotRef,
            {
              'status': newStatus,
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
        }
      });
    } catch (e) {
      rethrow;
    }
  }

  String _buildAppointmentSlotId(Appointment appointment) {
    final date = _dateKey(appointment.date);
    final time = _timeKey(appointment.time);
    return '${appointment.specialistId}_${date}_$time';
  }

  String _dateKey(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    return '$yyyy$mm$dd';
  }

  String _timeKey(String time) {
    return time
        .trim()
        .toLowerCase()
        .replaceAll(' ', '')
        .replaceAll(':', '')
        .replaceAll('.', '');
  }

  Stream<Set<String>> bookedSpecialistIdsForSlot(DateTime date, String time) {
    final dateKey = _dateKey(date);
    final timeKey = _timeKey(time);

    return _firestore
        .collection('booked_slots')
        .where('date', isEqualTo: dateKey)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .where((doc) {
            final data = doc.data();
            final docStatus = (data['status'] ?? '').toString().toLowerCase();
            if (docStatus == 'cancelled') return false;

            final rawTime = (data['time'] ?? '').toString();
            final rawTimeKey = (data['timeKey'] ?? '').toString();
            final normalizedTime = rawTime.isNotEmpty ? _timeKey(rawTime) : '';

            return rawTimeKey == timeKey || normalizedTime == timeKey;
          })
          .map((doc) => (doc.data()['specialistId'] ?? '').toString())
          .where((id) => id.isNotEmpty)
          .toSet();
    });
  }

  // === WORKOUTS ===
  Future<void> createWorkout(String uid, Workout workout) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('workouts')
          .add(workout.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Workout>> getWorkouts(String uid) async {
    try {
      final docs = await _firestore
          .collection('users')
          .doc(uid)
          .collection('workouts')
          .get();
      return docs.docs
          .map((doc) => Workout.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // === SKIN CONSULTATIONS ===
  Future<void> createSkinConsultation(
      String uid, SkinConsultation consultation) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('skin_consultations')
          .add(consultation.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SkinConsultation>> getSkinConsultations(String uid) async {
    try {
      final docs = await _firestore
          .collection('users')
          .doc(uid)
          .collection('skin_consultations')
          .get();
      return docs.docs
          .map((doc) => SkinConsultation.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // === SKIN ROUTINES ===
  Future<void> createSkinRoutine(String uid, SkinRoutine routine) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('skin_routines')
          .add(routine.toJson());
    } catch (e) {
      rethrow;
    }
  }

  Future<List<SkinRoutine>> getSkinRoutines(String uid) async {
    try {
      final docs = await _firestore
          .collection('users')
          .doc(uid)
          .collection('skin_routines')
          .get();
      return docs.docs
          .map((doc) => SkinRoutine.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  // === SUBSCRIPTION REQUESTS ===
  Future<void> createSubscriptionRequest(
    String uid,
    String userName,
    String planSelected,
    Map<String, dynamic> personalInfo,
    Map<String, dynamic> bankDetails,
    String? paymentProofUrl,
    double? selectedPrice,
    {
    double? registrationFee,
    double? totalAmount,
    bool requiresRegistrationFee = false,
    bool registrationFeePaid = false,
  }) async {
    try {
      await _firestore.collection('subscription_requests').doc(uid).set({
        'userId': uid,
        'userName': userName,
        'planSelected': planSelected,
        'selectedPrice': selectedPrice,
        'registrationFee': registrationFee,
        'totalAmount': totalAmount ?? selectedPrice,
        'requiresRegistrationFee': requiresRegistrationFee,
        'registrationFeePaid': registrationFeePaid,
        'personalInfo': personalInfo,
        'bankDetails': bankDetails,
        'paymentProofUrl': paymentProofUrl,
        'status': 'pending', // inactive, pending, active
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Map<String, dynamic>>> subscriptionRequestsStream() {
    return _firestore
        .collection('subscription_requests')
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snapshot) {
      final docs = snapshot.docs.map((doc) => {
            'id': doc.id,
            'data': doc.data(),
          }).toList();

      docs.sort((a, b) {
        final aData = a['data'] as Map<String, dynamic>;
        final bData = b['data'] as Map<String, dynamic>;
        final aTime = aData['createdAt'] ?? aData['updatedAt'];
        final bTime = bData['createdAt'] ?? bData['updatedAt'];
        if (aTime == null && bTime == null) return 0;
        if (aTime == null) return 1;
        if (bTime == null) return -1;
        try {
          return (bTime as dynamic).compareTo(aTime as dynamic);
        } catch (_) {
          return 0;
        }
      });

      return docs;
    });
  }

  Stream<Map<String, dynamic>?> userSubscriptionRequestStream(String uid) {
    return _firestore
        .collection('subscription_requests')
        .doc(uid)
        .snapshots()
        .map((doc) => doc.data());
  }

  Future<void> updateSubscriptionRequestStatus(String docId, String newStatus) async {
    try {
      await _firestore.collection('subscription_requests').doc(docId).update({
        'status': newStatus,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> approveSubscriptionRequest(String uid) async {
    final requestRef = _firestore.collection('subscription_requests').doc(uid);
    final pricingRef =
      _firestore.collection('admin_settings').doc('subscription_pricing');
    final subscriptionsCollection =
        _firestore.collection('users').doc(uid).collection('subscriptions');
    final userRef = _firestore.collection('users').doc(uid);

    try {
      await _firestore.runTransaction((transaction) async {
        final requestSnap = await transaction.get(requestRef);
        if (!requestSnap.exists) {
          throw Exception('Subscription request not found.');
        }

        final data = requestSnap.data() as Map<String, dynamic>;
        final plan =
            (data['planSelected']?.toString().toLowerCase() ?? 'monthly');
        final pricingSnap = await transaction.get(pricingRef);
        final pricingData = pricingSnap.data();
        final now = DateTime.now();
        final endDate = _planEndDate(plan, now);
        final price = _planPriceFromData(pricingData, plan,
          fallback: _numberToDouble(data['selectedPrice']) ?? _planPrice(plan));
        final registrationFee = _numberToDouble(data['registrationFee']) ??
            _numberToDouble(pricingData?['registrationFee']) ??
            _defaultSubscriptionPricing['registrationFee']!;
        final requiresRegistrationFee =
            data['requiresRegistrationFee'] as bool? ?? registrationFee > 0;
        final totalAmount = _numberToDouble(data['totalAmount']) ??
            price + (requiresRegistrationFee ? registrationFee : 0);

        final subscriptionRef = subscriptionsCollection.doc();
        transaction.set(subscriptionRef, {
          'plan': plan,
          'startDate': now.toIso8601String(),
          'endDate': endDate.toIso8601String(),
          'status': 'active',
          'price': totalAmount,
          'planPrice': price,
          'registrationFee': requiresRegistrationFee ? registrationFee : 0,
          'totalAmount': totalAmount,
          'approvedFromRequestId': uid,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });

        transaction.set(userRef, {
          'bodyHolicsRegistrationFeePaid': true,
          'bodyHolicsRegistrationFeePaidAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        transaction.update(requestRef, {
          'status': 'active',
          'approvedAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
          'registrationFeePaid': true,
        });
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<void> rejectSubscriptionRequest(String uid) async {
    try {
      await _firestore.collection('subscription_requests').doc(uid).update({
        'status': 'inactive',
        'rejectedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      rethrow;
    }
  }

  DateTime _planEndDate(String plan, DateTime startDate) {
    switch (plan) {
      case 'yearly':
        return DateTime(startDate.year + 1, startDate.month, startDate.day);
      case 'quarterly':
        return DateTime(startDate.year, startDate.month + 3, startDate.day);
      case 'monthly':
      default:
        return DateTime(startDate.year, startDate.month + 1, startDate.day);
    }
  }

  double _planPrice(String plan) {
    switch (plan) {
      case 'yearly':
        return 29;
      case 'quarterly':
        return 39;
      case 'monthly':
      default:
        return 49;
    }
  }

  double _planPriceFromData(
    Map<String, dynamic>? pricingData,
    String plan, {
    required double fallback,
  }) {
    if (pricingData == null) return fallback;

    final raw = pricingData[plan];
    final value = _numberToDouble(raw);
    if (value != null && value > 0) return value;
    return fallback;
  }

  double? _numberToDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return null;
  }

  Future<Map<String, double>> getBodySubscriptionPricing() async {
    try {
      final doc = await _firestore
          .collection('admin_settings')
          .doc('subscription_pricing')
          .get();
      return _parseBodyPricing(doc.data());
    } catch (_) {
      return _defaultSubscriptionPricing;
    }
  }

  Stream<Map<String, double>> bodySubscriptionPricingStream() {
    return _firestore
        .collection('admin_settings')
        .doc('subscription_pricing')
        .snapshots()
        .map((doc) => _parseBodyPricing(doc.data()));
  }

  Map<String, double> _parseBodyPricing(Map<String, dynamic>? data) {
    if (data == null) return _defaultSubscriptionPricing;
    return {
      'monthly': _numberToDouble(data['monthly']) ?? _defaultSubscriptionPricing['monthly']!,
      'quarterly': _numberToDouble(data['quarterly']) ?? _defaultSubscriptionPricing['quarterly']!,
      'yearly': _numberToDouble(data['yearly']) ?? _defaultSubscriptionPricing['yearly']!,
      'registrationFee': _numberToDouble(data['registrationFee']) ?? _defaultSubscriptionPricing['registrationFee']!,
    };
  }

  Future<void> setBodySubscriptionPricing(Map<String, double> pricing) async {
    try {
      await _firestore
          .collection('admin_settings')
          .doc('subscription_pricing')
          .set({
        'monthly': pricing['monthly'] ?? _defaultSubscriptionPricing['monthly'],
        'quarterly': pricing['quarterly'] ?? _defaultSubscriptionPricing['quarterly'],
        'yearly': pricing['yearly'] ?? _defaultSubscriptionPricing['yearly'],
        'registrationFee': pricing['registrationFee'] ?? _defaultSubscriptionPricing['registrationFee'],
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  // === ADMIN BANK DETAILS ===
  Future<void> setAdminBankDetails(Map<String, dynamic> bankDetails) async {
    try {
      await _firestore.collection('admin_settings').doc('bank_details').set({
        ...bankDetails,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> getAdminBankDetails() async {
    try {
      final doc = await _firestore
          .collection('admin_settings')
          .doc('bank_details')
          .get();
      if (doc.exists) {
        return doc.data();
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  Stream<Map<String, dynamic>?> adminBankDetailsStream() {
    return _firestore
        .collection('admin_settings')
        .doc('bank_details')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  Stream<Map<String, dynamic>?> supportContactStream() {
    return _firestore
        .collection('admin_settings')
        .doc('support_details')
        .snapshots()
        .map((doc) {
      if (doc.exists) {
        return doc.data();
      }
      return null;
    });
  }

  // === GOALS ===
  Future<void> createGoal(String uid, Map<String, dynamic> goal) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('goals')
          .add(goal);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> getGoals(String uid) async {
    try {
      final docs = await _firestore
          .collection('users')
          .doc(uid)
          .collection('goals')
          .get();
      return docs.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      rethrow;
    }
  }

  // === STREAM METHODS ===
  Stream<User?> userStream(String uid) {
    return watchUser(uid);
  }

  Stream<List<Appointment>> userAppointmentsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('appointments')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Appointment.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<Subscription>> subscriptionStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('subscriptions')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Subscription.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Future<List<User>> getAllUsers() async {
    try {
      final docs = await _firestore.collection('users').get();
      return docs.docs
          .map((doc) => User.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Subscription>> getAllSubscriptions() async {
    try {
      final docs = await _firestore
          .collectionGroup('subscriptions')
          .get();
      return docs.docs
          .map((doc) => Subscription.fromJson(
                doc.data(),
                doc.reference.parent.parent?.id ?? doc.id,
              ))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Appointment>> getAllAppointments() async {
    try {
      final docs = await _firestore
          .collectionGroup('appointments')
          .get();
      return docs.docs
          .map((doc) => Appointment.fromJson(doc.data(), doc.id))
          .toList();
    } catch (e) {
      rethrow;
    }
  }

  Stream<List<Workout>> workoutsStream() {
    return _firestore
        .collection('workouts')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Workout.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<SkinService>> skinServicesStream() {
    return _firestore
        .collection('skin_services')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SkinService.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<Specialist>> specialistsStream() {
    return _firestore
        .collection('specialists')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => Specialist.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<SkinConsultation>> skinConsultationsStream(String uid) {
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('skin_consultations')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => SkinConsultation.fromJson(doc.data(), doc.id))
          .toList();
    });
  }

  Stream<List<NutritionPlan>> nutritionPlansStream() {
    return _firestore
        .collection('nutrition_plans')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => NutritionPlan.fromJson(doc.data(), doc.id))
          .toList();
    });
  }
}
