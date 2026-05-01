import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_holics/core/router/app_routes.dart';
import 'package:the_holics/core/theme/app_theme.dart';
import 'package:the_holics/shared/widgets/holics_buttons.dart';
import 'package:the_holics/shared/widgets/common_widgets.dart';
import 'package:the_holics/shared/widgets/holics_bottom_nav.dart';
import 'package:the_holics/shared/widgets/state_widgets.dart';
import 'package:the_holics/shared/providers/content_provider.dart';
import 'package:the_holics/shared/providers/providers.dart';
import 'package:the_holics/shared/models/appointment_model.dart';
import 'package:gap/gap.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SkinHolicsScreen extends ConsumerStatefulWidget {
  const SkinHolicsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<SkinHolicsScreen> createState() => _SkinHolicsScreenState();
}

class _SkinHolicsScreenState extends ConsumerState<SkinHolicsScreen> {
  int _currentStep = 0;
  String? _selectedService;
  double _selectedServicePrice = 0;
  int _selectedServiceDurationMin = 60;
  DateTime? _selectedDate;
  String? _selectedTime;
  String? _selectedSpecialist;
  String? _selectedPaymentMode;
  String? _selectedPaymentProof;
  String? _paymentProofUrl;
  bool _isConfirmingBooking = false;

  bool get _isVideoConsultation {
    return (_selectedService ?? '').toLowerCase().contains('video');
  }

  List<String> get _steps {
    return const ['Service', 'Date & Time', 'Specialist', 'Payment', 'Confirm'];
  }

  void _handleBackNavigation() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      return;
    }

    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          setState(() => _currentStep--);
          return false;
        }

        if (context.canPop()) {
          return true;
        } else {
          context.go(AppRoutes.home);
          return false;
        }
      },
      child: Scaffold(
        backgroundColor: AppTheme.darkBg,
        appBar: AppBar(
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBackNavigation,
          ),
          title: const Text('Skin Holics'),
          backgroundColor: AppTheme.darkBg,
          elevation: 0,
        ),
        bottomNavigationBar: const HolicsBottomNav(currentIndex: 2),
        body: Stack(
          children: [
            Positioned(
              top: -100,
              right: -90,
              child: Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.skinHolichPink.withOpacity(0.12),
                ),
              ),
            ),
            Positioned(
              bottom: -130,
              left: -100,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.bodyHolicsOrange.withOpacity(0.08),
                ),
              ),
            ),
            SafeArea(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard.withOpacity(0.88),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: _StepperIndicator(
                        currentStep: _currentStep,
                        steps: _steps,
                      ),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppTheme.surfaceCard.withOpacity(0.72),
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: _buildStepContent(),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _Step1SelectService(
          selectedService: _selectedService,
          onServiceSelected: (service, price, durationMin) {
            setState(() {
              _selectedService = service;
              _selectedServicePrice = price;
              _selectedServiceDurationMin = durationMin;
              if (service.toLowerCase().contains('video')) {
                _selectedPaymentMode = 'pay_now';
              } else {
                _selectedPaymentMode = 'pay_physical';
                _selectedPaymentProof = null;
                _paymentProofUrl = null;
              }
            });
          },
          onContinue: () => setState(() => _currentStep = 1),
        );
      case 1:
        return _Step2SelectDateTime(
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          onDateSelected: (date) => setState(() => _selectedDate = date),
          onTimeSelected: (time) => setState(() => _selectedTime = time),
          onContinue: () => setState(() => _currentStep = 2),
          onBack: () => setState(() => _currentStep = 0),
        );
      case 2:
        return _Step3ChooseSpecialist(
          selectedSpecialist: _selectedSpecialist,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          isVideoConsultation: _isVideoConsultation,
          onSpecialistSelected: (specialist) {
            setState(() => _selectedSpecialist = specialist);
          },
          onContinue: () => setState(() => _currentStep = 3),
          onBack: () => setState(() => _currentStep = 1),
        );
      case 3:
        return _Step4Payment(
          amount: _selectedServicePrice,
          isVideoConsultation: _isVideoConsultation,
          initialPaymentMode: _selectedPaymentMode,
          initialPaymentProof: _selectedPaymentProof,
          initialPaymentProofUrl: _paymentProofUrl,
          onPaymentUpdated: (paymentMode, proofName, proofUrl) {
            setState(() {
              _selectedPaymentMode = paymentMode;
              _selectedPaymentProof = proofName;
              _paymentProofUrl = proofUrl;
            });
          },
          onBack: () => setState(() => _currentStep = 2),
          onContinue: () => setState(() => _currentStep = 4),
        );
      case 4:
        return _Step4ReviewConfirm(
          selectedService: _selectedService,
          selectedPrice: _selectedServicePrice,
          selectedDate: _selectedDate,
          selectedTime: _selectedTime,
          selectedSpecialist: _selectedSpecialist,
          selectedPaymentMode: _selectedPaymentMode,
          selectedPaymentProof: _selectedPaymentProof,
          isVideoConsultation: _isVideoConsultation,
          onConfirm: _handleConfirmBooking,
          onBack: () => setState(() => _currentStep = 3),
          isConfirming: _isConfirmingBooking,
        );
      default:
        return const SizedBox();
    }
  }

  void _handleConfirmBooking() async {
    if (_isConfirmingBooking) return;

    setState(() => _isConfirmingBooking = true);

    try {
      final uid = ref.read(currentUserIdProvider);
      final firestoreService = ref.read(firestoreServiceProvider);
      final authService = ref.read(authServiceProvider);
      final currentUser = authService.currentUser;

      if (uid == null) return;

      final selectedServiceName = _selectedService ?? '';
      final isVideoConsultation =
          selectedServiceName.toLowerCase().contains('video');
      final selectedPaymentMode =
          isVideoConsultation ? 'pay_now' : (_selectedPaymentMode ?? 'pay_physical');

      if (selectedPaymentMode == 'pay_now' &&
          (_paymentProofUrl == null || _paymentProofUrl!.isEmpty)) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Please upload payment proof before submitting booking.',
              ),
            ),
          );
        }
        setState(() => _isConfirmingBooking = false);
        return;
      }

        final paymentProofUrl =
          selectedPaymentMode == 'pay_now' ? _paymentProofUrl : null;
        final appointmentStatus = 'pending'; // All new bookings start as pending

      final appointment = Appointment(
        id: '',
        userId: uid,
        userName: (currentUser?.displayName != null && currentUser!.displayName!.trim().isNotEmpty)
            ? currentUser.displayName!.trim()
            : null,
        userEmail: currentUser?.email,
        service: selectedServiceName,
        durationMin: _selectedServiceDurationMin,
        date: _selectedDate ?? DateTime.now(),
        time: _selectedTime ?? '',
        specialistId: _selectedSpecialist ?? '',
        price: _selectedServicePrice,
        status: appointmentStatus,
        paymentMethod:
          selectedPaymentMode == 'pay_now' ? 'manual' : 'pay_physical',
        paymentStatus:
          selectedPaymentMode == 'pay_now' ? 'proof_submitted' : null,
        paymentProofUrl: paymentProofUrl,
        createdAt: DateTime.now(),
      );

      await firestoreService.createAppointment(uid, appointment);

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            title: Text(
              selectedPaymentMode == 'pay_now'
                  ? 'Payment Submitted'
                  : 'Booking Confirmed',
            ),
            content: Text(
              selectedPaymentMode == 'pay_now'
                  ? 'Your payment proof has been submitted. Your appointment will be confirmed after admin verification.'
                  : 'Your appointment has been booked successfully. Please pay at the clinic.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('OK'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      context.go(AppRoutes.home);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isConfirmingBooking = false);
      }
    }
  }
}

class _StepperIndicator extends StatelessWidget {
  final int currentStep;
  final List<String> steps;

  const _StepperIndicator({
    required this.currentStep,
    required this.steps,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
        children: List.generate(steps.length, (index) {
          final isCompleted = index < currentStep;
          final isActive = index == currentStep;

          return Expanded(
            child: Column(
              children: [
                Row(
                  children: [
                    if (index != 0)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted || isActive
                              ? AppTheme.skinHolichPink
                              : AppTheme.borderColor,
                        ),
                      ),
                    if (index != 0) const Gap(8),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCompleted || isActive
                            ? AppTheme.skinHolichPink
                            : AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(
                          color: AppTheme.borderColor,
                        ),
                      ),
                      child: Center(
                        child: isCompleted
                            ? const Icon(Icons.check,
                                color: Colors.white, size: 16)
                            : Text(
                                '${index + 1}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: isActive
                                      ? Colors.white
                                      : AppTheme.textSecondary,
                                ),
                              ),
                      ),
                    ),
                    const Gap(8),
                    if (index != steps.length - 1)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: isCompleted
                              ? AppTheme.skinHolichPink
                              : AppTheme.borderColor,
                        ),
                      ),
                  ],
                ),
                const Gap(8),
                Text(
                  steps[index],
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppTheme.skinHolichPink
                        : AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }),
      );
  }
}

class _Step1SelectService extends ConsumerWidget {
  final String? selectedService;
  final void Function(String, double, int) onServiceSelected;
  final VoidCallback onContinue;

  const _Step1SelectService({
    required this.selectedService,
    required this.onServiceSelected,
    required this.onContinue,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(skinServicesProvider);

    return servicesAsync.when(
      data: (services) {
        if (services.isEmpty) {
          return const EmptyStateWidget(
            title: 'No services found',
            subtitle:
                'No data in Firebase collection "skin_services" yet. Add services in the Firebase and reload.',
            icon: Icons.spa_outlined,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: InkWell(
                onTap: () => context.push(AppRoutes.skinHolicsGallery),
                borderRadius: BorderRadius.circular(999),
                child: Ink(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFFFF4FA7), Color(0xFFE91E8C)],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.skinHolichPink.withOpacity(0.3),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 16,
                        color: Colors.white,
                      ),
                      Gap(6),
                      Text(
                        'Our Results Gallery',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const Gap(14),
            const Text(
              'Select a Service',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Gap(4),
            const Text(
              'Choose your preferred treatment to begin booking.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const Gap(16),
            GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.95,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemCount: services.length,
              itemBuilder: (context, index) {
                final service = services[index];
                final isSelected = selectedService == service.name;

                return GestureDetector(
                  onTap: () => onServiceSelected(
                    service.name,
                    service.price,
                    service.durationMin,
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: isSelected
                            ? [
                                AppTheme.skinHolichPink.withOpacity(0.22),
                                AppTheme.surfaceCard,
                              ]
                            : [
                                AppTheme.surfaceCard,
                                const Color(0xFF1A1A1A),
                              ],
                      ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isSelected
                            ? AppTheme.skinHolichPink
                            : AppTheme.borderColor,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if (service.badge != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppTheme.skinHolichPink.withOpacity(0.22),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              service.badge!,
                              style: const TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.skinHolichPink,
                              ),
                            ),
                          ),
                        ],
                        Text(
                          service.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textPrimary,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        Column(
                          children: [
                            Text(
                              '⏱ ${service.durationMin} min',
                              style: const TextStyle(
                                fontSize: 10,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const Gap(4),
                            Text(
                              'PKR ${service.price.toStringAsFixed(0)}',
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.skinHolichPink,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const Gap(24),
            HolicsPinkButton(
              label: 'Continue',
              onPressed: selectedService != null ? onContinue : () {},
            ),
          ],
        );
      },
      loading: () => ShimmerCardLoader(),
      error: (error, stack) => ErrorStateWidget(
        message: error.toString(),
        onRetry: () {},
      ),
    );
  }
}

class _Step2SelectDateTime extends StatefulWidget {
  final DateTime? selectedDate;
  final String? selectedTime;
  final Function(DateTime) onDateSelected;
  final Function(String) onTimeSelected;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _Step2SelectDateTime({
    required this.selectedDate,
    required this.selectedTime,
    required this.onDateSelected,
    required this.onTimeSelected,
    required this.onContinue,
    required this.onBack,
  });

  @override
  State<_Step2SelectDateTime> createState() => _Step2SelectDateTimeState();
}

class _Step2SelectDateTimeState extends State<_Step2SelectDateTime> {
  late DateTime _displayedMonth;

  @override
  void initState() {
    super.initState();
    _displayedMonth = DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final times = _timeSlots();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select Date & Time',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const Gap(4),
        const Text(
          'Pick a date and 1-hour slot between 3 PM and 10 PM.',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const Gap(16),
        // Calendar
        Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard.withOpacity(0.9),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: () => setState(
                        () => _displayedMonth =
                            DateTime(_displayedMonth.year, _displayedMonth.month - 1)),
                  ),
                  Text(
                    '${_displayedMonth.month}/${_displayedMonth.year}',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: () => setState(
                        () => _displayedMonth =
                            DateTime(_displayedMonth.year, _displayedMonth.month + 1)),
                  ),
                ],
              ),
              const Gap(12),
              GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 7,
                  childAspectRatio: 1,
                ),
                physics: const NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: 35,
                itemBuilder: (context, index) {
                  final firstDay = DateTime(_displayedMonth.year, _displayedMonth.month, 1);
                  final day = index - (firstDay.weekday - 1);

                  if (day <= 0 || day > _daysInMonth(_displayedMonth)) {
                    return const SizedBox();
                  }

                  final date = DateTime(_displayedMonth.year, _displayedMonth.month, day);
                  final isSelected = widget.selectedDate?.day == day;
                  final isPast = date.isBefore(DateTime.now());

                  return GestureDetector(
                    onTap: isPast ? null : () => widget.onDateSelected(date),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.skinHolichPink
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                        border: !isSelected && !_isSameDate(date, DateTime.now())
                            ? null
                            : Border.all(
                                color: isSelected
                                    ? AppTheme.skinHolichPink
                                    : AppTheme.skinHolichPink.withOpacity(0.4),
                              ),
                      ),
                      child: Center(
                        child: Text(
                          '$day',
                          style: TextStyle(
                            color: isPast
                                ? AppTheme.textSecondary
                                : isSelected
                                    ? Colors.white
                                    : AppTheme.textPrimary,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
        const Gap(20),
        // Times
        const Text(
          'Time Slots',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Gap(12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: times.map((time) {
            final isSelected = widget.selectedTime == time;
            return GestureDetector(
              onTap: () => widget.onTimeSelected(time),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected ? AppTheme.skinHolichPink : AppTheme.surfaceCard,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? AppTheme.skinHolichPink
                        : AppTheme.borderColor,
                  ),
                ),
                child: Text(
                  time,
                  style: TextStyle(
                    color: isSelected ? Colors.white : AppTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Gap(24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: widget.onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE91E8C)),
                ),
                child: const Text('Back', style: TextStyle(color: Color(0xFFE91E8C))),
              ),
            ),
            const Gap(12),
            Expanded(
              child: HolicsPinkButton(
                label: 'Continue',
                onPressed: (widget.selectedDate != null && widget.selectedTime != null)
                    ? widget.onContinue
                    : () {},
              ),
            ),
          ],
        ),
      ],
    );
  }

  int _daysInMonth(DateTime date) {
    return DateTime(date.year, date.month + 1, 0).day;
  }

  bool _isSameDate(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  List<String> _timeSlots() {
    final buffer = <String>[];

    for (int totalMinutes = 15 * 60; totalMinutes < 22 * 60; totalMinutes += 60) {
      final hour24 = totalMinutes ~/ 60;
      final minute = totalMinutes % 60;
      final isPm = hour24 >= 12;
      final hour12 = hour24 % 12 == 0 ? 12 : hour24 % 12;
      final minuteText = minute.toString().padLeft(2, '0');
      final period = isPm ? 'PM' : 'AM';
      buffer.add('$hour12:$minuteText $period');
    }

    return buffer;
  }
}

class _Step3ChooseSpecialist extends ConsumerWidget {
  final String? selectedSpecialist;
  final DateTime? selectedDate;
  final String? selectedTime;
  final bool isVideoConsultation;
  final Function(String) onSpecialistSelected;
  final VoidCallback onContinue;
  final VoidCallback onBack;

  const _Step3ChooseSpecialist({
    required this.selectedSpecialist,
    required this.selectedDate,
    required this.selectedTime,
    required this.isVideoConsultation,
    required this.onSpecialistSelected,
    required this.onContinue,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialistsAsync = ref.watch(specialistsProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final slotBookedSpecialistsStream =
        (selectedDate != null && selectedTime != null)
            ? firestoreService.bookedSpecialistIdsForSlot(
                selectedDate!,
                selectedTime!,
              )
            : Stream.value(<String>{});

    return specialistsAsync.when(
      data: (specialists) {
        if (specialists.isEmpty) {
          return const EmptyStateWidget(
            title: 'No specialists found',
            subtitle:
                'No data in Firebase collection "specialists" yet. Add specialists in Firebase and reload.',
            icon: Icons.person_outline,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Choose Specialist',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
            ),
            const Gap(4),
            const Text(
              'Select an available specialist for your chosen slot.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
            const Gap(16),
            StreamBuilder<Set<String>>(
              stream: slotBookedSpecialistsStream,
              builder: (context, snapshot) {
                final bookedSpecialistIds = snapshot.data ?? <String>{};

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...specialists.map((specialist) {
                      final isSelected = selectedSpecialist == specialist.id;
                      final isSlotBooked = bookedSpecialistIds.contains(specialist.id);
                      final canSelect = specialist.isAvailable && !isSlotBooked;
                      final statusText = isSlotBooked
                          ? 'Booked'
                          : (specialist.isAvailable ? 'Available' : 'Unavailable');
                      final statusColor = isSlotBooked
                          ? AppTheme.warningYellow
                          : (specialist.isAvailable
                              ? AppTheme.successGreen
                              : AppTheme.errorRed);

                      return GestureDetector(
                        onTap: canSelect
                            ? () => onSpecialistSelected(specialist.id)
                            : null,
                        child: Opacity(
                          opacity: canSelect ? 1.0 : 0.5,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.surfaceCard, Color(0xFF1A1A1A)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected
                                    ? AppTheme.skinHolichPink
                                    : AppTheme.borderColor,
                                width: isSelected ? 2 : 1,
                              ),
                            ),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppTheme.skinHolichPink,
                                  child: const Icon(Icons.person, color: Colors.white),
                                ),
                                const Gap(12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        specialist.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.textPrimary,
                                        ),
                                      ),
                                      const Gap(2),
                                      Text(
                                        specialist.specialty,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    statusText,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                    const Gap(24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: onBack,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFE91E8C)),
                            ),
                            child: const Text(
                              'Back',
                              style: TextStyle(color: Color(0xFFE91E8C)),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: HolicsPinkButton(
                            label: isVideoConsultation
                                ? 'Continue to Payment'
                                : 'Review Booking',
                            onPressed: (selectedSpecialist != null &&
                                    !bookedSpecialistIds
                                        .contains(selectedSpecialist))
                                ? onContinue
                                : () {},
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ],
        );
      },
      loading: () => ShimmerCardLoader(),
      error: (error, stack) => ErrorStateWidget(
        message: error.toString(),
        onRetry: () {},
      ),
    );
  }
}

class _Step4ReviewConfirm extends ConsumerWidget {
  final String? selectedService;
  final double selectedPrice;
  final DateTime? selectedDate;
  final String? selectedTime;
  final String? selectedSpecialist;
  final String? selectedPaymentMode;
  final String? selectedPaymentProof;
  final bool isVideoConsultation;
  final VoidCallback onConfirm;
  final VoidCallback onBack;
  final bool isConfirming;

  const _Step4ReviewConfirm({
    required this.selectedService,
    required this.selectedPrice,
    required this.selectedDate,
    required this.selectedTime,
    required this.selectedSpecialist,
    required this.selectedPaymentMode,
    required this.selectedPaymentProof,
    required this.isVideoConsultation,
    required this.onConfirm,
    required this.onBack,
    required this.isConfirming,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Review & Confirm',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
            const Gap(4),
            const Text(
              'Please verify all details before submitting your booking.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textSecondary,
              ),
            ),
        const Gap(16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _ReviewItem(label: 'Service', value: selectedService ?? ''),
              _ReviewItem(
                label: 'Date',
                value:
                    '${selectedDate?.day}/${selectedDate?.month}/${selectedDate?.year}',
              ),
              _ReviewItem(label: 'Time', value: selectedTime ?? ''),
              _ReviewItem(
                label: 'Price',
                value: 'PKR ${selectedPrice.toStringAsFixed(0)}',
              ),
              _ReviewItem(
                label: 'Payment',
                value: (selectedPaymentMode == 'pay_now' || isVideoConsultation)
                    ? 'Pay Now (Manual)'
                    : 'Pay Physical',
              ),
              if (selectedPaymentMode == 'pay_now' || isVideoConsultation)
                _ReviewItem(
                  label: 'Payment Proof',
                  value: selectedPaymentProof ?? 'Uploaded',
                ),
            ],
          ),
        ),
        const Gap(24),
        HolicsPinkButton(
          label: 'Confirm Booking',
          isLoading: isConfirming,
          onPressed: isConfirming ? () {} : onConfirm,
        ),
        const Gap(12),
        OutlinedButton(
          onPressed: isConfirming ? null : onBack,
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFE91E8C)),
            minimumSize: const Size(double.infinity, 56),
          ),
          child: const Text('Back', style: TextStyle(color: Color(0xFFE91E8C))),
        ),
      ],
    );
  }
}

class _ReviewItem extends StatelessWidget {
  final String label;
  final String value;

  const _ReviewItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _Step4Payment extends ConsumerStatefulWidget {
  final double amount;
  final bool isVideoConsultation;
  final String? initialPaymentMode;
  final String? initialPaymentProof;
  final String? initialPaymentProofUrl;
  final void Function(
    String paymentMode,
    String? paymentProof,
    String? paymentProofUrl,
  ) onPaymentUpdated;
  final VoidCallback onBack;
  final VoidCallback onContinue;

  const _Step4Payment({
    required this.amount,
    required this.isVideoConsultation,
    required this.initialPaymentMode,
    required this.initialPaymentProof,
    required this.initialPaymentProofUrl,
    required this.onPaymentUpdated,
    required this.onBack,
    required this.onContinue,
  });

  @override
  ConsumerState<_Step4Payment> createState() => _Step4PaymentState();
}

class _Step4PaymentState extends ConsumerState<_Step4Payment> {
  String _paymentMode = 'pay_physical';
  String? _selectedPaymentProof;
  String? _paymentProofUrl;
  bool _isUploadingProof = false;

  @override
  void initState() {
    super.initState();
    _paymentMode = widget.isVideoConsultation
        ? 'pay_now'
        : (widget.initialPaymentMode ?? 'pay_physical');
    _selectedPaymentProof = widget.initialPaymentProof;
    _paymentProofUrl = widget.initialPaymentProofUrl;
  }

  bool get _isPayNow {
    return widget.isVideoConsultation || _paymentMode == 'pay_now';
  }

  bool get _canContinue {
    if (_isUploadingProof) return false;
    if (_isPayNow) {
      return _paymentProofUrl != null && _paymentProofUrl!.isNotEmpty;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = ref.read(firestoreServiceProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Payment Details',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const Gap(4),
        const Text(
          'Confirm your preferred payment mode to continue.',
          style: TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 12,
          ),
        ),
        const Gap(2),
        Text(
          'PKR ${widget.amount.toStringAsFixed(0)}',
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        const Gap(16),
        if (!widget.isVideoConsultation) ...[
          const Text(
            'Choose Payment Method',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Gap(10),
          Row(
            children: [
              Expanded(
                child: _PaymentOptionCard(
                  title: 'Pay Physical',
                  subtitle: 'Pay at clinic on appointment day',
                  isSelected: _paymentMode == 'pay_physical',
                  onTap: () {
                    setState(() {
                      _paymentMode = 'pay_physical';
                      _selectedPaymentProof = null;
                      _paymentProofUrl = null;
                    });
                    widget.onPaymentUpdated(
                      _paymentMode,
                      _selectedPaymentProof,
                      _paymentProofUrl,
                    );
                  },
                ),
              ),
              const Gap(10),
              Expanded(
                child: _PaymentOptionCard(
                  title: 'Pay Now',
                  subtitle: 'Manual transfer + payment proof',
                  isSelected: _paymentMode == 'pay_now',
                  onTap: () {
                    setState(() {
                      _paymentMode = 'pay_now';
                    });
                  },
                ),
              ),
            ],
          ),
          const Gap(16),
        ],
        if (_isPayNow) ...[
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.skinHolichPink.withOpacity(0.1),
            border: Border.all(
              color: AppTheme.skinHolichPink.withOpacity(0.35),
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: StreamBuilder<Map<String, dynamic>?>(
            stream: firestoreService.adminBankDetailsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(),
                );
              }

              final bankDetails = snapshot.data;
              if (bankDetails == null) {
                return const Text(
                  'Owner bank details not yet configured. Please contact admin.',
                  style: TextStyle(color: AppTheme.textSecondary),
                );
              }

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Transfer Money To:',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondary,
                    ),
                  ),
                  const Gap(12),
                  _buildDetailRow(
                    'Bank Name',
                    bankDetails['bankName'] ?? 'N/A',
                  ),
                  const Gap(8),
                  _buildDetailRow(
                    'Account Holder',
                    bankDetails['accountHolder'] ?? 'N/A',
                  ),
                  const Gap(8),
                  _buildDetailRow(
                    'Account Number',
                    bankDetails['accountNumber'] ?? 'N/A',
                  ),
                  const Gap(8),
                  _buildDetailRow(
                    'IFSC Code',
                    bankDetails['ifscCode'] ?? 'N/A',
                  ),
                ],
              );
            },
          ),
        ),
        const Gap(16),
        const Text(
          'Payment Proof',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Gap(8),
        const Text(
          'Upload screenshot of your payment transfer',
          style: TextStyle(
            fontSize: 12,
            color: AppTheme.textSecondary,
          ),
        ),
        const Gap(12),
        GestureDetector(
          onTap: _isUploadingProof ? null : _pickAndUploadProof,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.skinHolichPink.withOpacity(0.5),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.skinHolichPink.withOpacity(0.05),
            ),
            padding: const EdgeInsets.symmetric(
              vertical: 20,
              horizontal: 16,
            ),
            child: Column(
              children: [
                _isUploadingProof
                    ? const SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.skinHolichPink,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.cloud_upload_outlined,
                        color: AppTheme.skinHolichPink,
                        size: 40,
                      ),
                const Gap(8),
                Text(
                  _selectedPaymentProof ?? 'Attach Payment Proof',
                  style: TextStyle(
                    color: _selectedPaymentProof != null
                        ? AppTheme.textPrimary
                        : AppTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
        ],
        const Gap(24),
        Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isUploadingProof ? null : widget.onBack,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE91E8C)),
                ),
                child: const Text(
                  'Back',
                  style: TextStyle(color: Color(0xFFE91E8C)),
                ),
              ),
            ),
            const Gap(12),
            Expanded(
              child: HolicsPinkButton(
                label: 'Review Booking',
                onPressed: !_canContinue
                    ? () {}
                    : () {
                        widget.onPaymentUpdated(
                          _isPayNow ? 'pay_now' : 'pay_physical',
                          _selectedPaymentProof,
                          _paymentProofUrl,
                        );
                        widget.onContinue();
                      },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _pickAndUploadProof() async {
    final authService = ref.read(authServiceProvider);
    final uid = authService.currentUser?.uid;
    if (uid == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please sign in first.')),
        );
      }
      return;
    }

    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked == null) return;

    setState(() {
      _isUploadingProof = true;
      _selectedPaymentProof = picked.name;
    });

    try {
      final supabase = Supabase.instance.client;
      final path =
          'users/$uid/payment_proofs/${DateTime.now().millisecondsSinceEpoch}_${picked.name}';
      final bytes = await picked.readAsBytes();

      await supabase.storage.from('images').uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: picked.mimeType ?? 'image/jpeg',
              upsert: true,
            ),
          );

      final downloadUrl = supabase.storage.from('images').getPublicUrl(path);

      if (mounted) {
        setState(() {
          _paymentProofUrl = downloadUrl;
          _isUploadingProof = false;
        });
        widget.onPaymentUpdated(
          _isPayNow ? 'pay_now' : 'pay_physical',
          _selectedPaymentProof,
          _paymentProofUrl,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Payment proof uploaded successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploadingProof = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Upload failed: $e')),
        );
      }
    }
  }
}

class _PaymentOptionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _PaymentOptionCard({
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppTheme.skinHolichPink : AppTheme.borderColor,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(4),
            Text(
              subtitle,
              style: const TextStyle(
                color: AppTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
