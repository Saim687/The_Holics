import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_holics/core/theme/app_theme.dart';
import 'package:the_holics/core/router/app_routes.dart';
import 'package:the_holics/shared/widgets/holics_buttons.dart';
import 'package:the_holics/shared/widgets/common_widgets.dart';
import 'package:the_holics/shared/providers/providers.dart';
import 'package:the_holics/shared/providers/user_provider.dart';
import 'package:the_holics/shared/providers/subscription_provider.dart';
import 'package:the_holics/shared/widgets/holics_bottom_nav.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:gap/gap.dart';

class BodyHolicsScreen extends ConsumerStatefulWidget {
  const BodyHolicsScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<BodyHolicsScreen> createState() => _BodyHolicsScreenState();
}

class _BodyHolicsScreenState extends ConsumerState<BodyHolicsScreen> {
  String _selectedPlan = 'monthly';

  void _handleBack() {
    if (context.canPop()) {
      context.pop();
      return;
    }
    context.go(AppRoutes.home);
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;
    final uid = ref.watch(currentUserIdProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final hasActiveSubscriptionAsync =
      ref.watch(currentUserHasActiveSubscriptionProvider);
    final currentSubscriptionAsync = ref.watch(currentUserSubscriptionProvider);
    final currentUserAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        title: const Text('Body Holics'),
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
      ),
      bottomNavigationBar: const HolicsBottomNav(currentIndex: 1),
      body: Stack(
        children: [
          Positioned(
            top: -100,
            right: -80,
            child: Container(
              width: 230,
              height: 230,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bodyHolicsOrange.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -90,
            child: Container(
              width: 270,
              height: 270,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.skinHolichPink.withOpacity(0.06),
              ),
            ),
          ),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
            // Header banner
            _staggerReveal(
              delayFactor: 0.03,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppTheme.bodyHolicsGradient,
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.bodyHolicsOrange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.fitness_center,
                          color: AppTheme.bodyHolicsOrange, size: 28),
                    ),
                    const Gap(12),
                    const Text(
                      'Body Holics',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Gap(4),
                    const Text(
                      'Gym & Fitness',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Gap(32),

            // Plans section
            _staggerReveal(
              delayFactor: 0.12,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: StreamBuilder<Map<String, dynamic>?>(
                  stream: uid == null
                      ? Stream.value(null)
                      : firestoreService.userSubscriptionRequestStream(uid),
                  builder: (context, snapshot) {
                  final request = snapshot.data;
                  final requestStatus =
                      (request?['status']?.toString().toLowerCase() ?? 'inactive');
                  final isActive = hasActiveSubscriptionAsync.maybeWhen(
                    data: (isActive) => isActive,
                    orElse: () => false,
                  );
                  final currentSubscription = currentSubscriptionAsync.maybeWhen(
                    data: (subscription) => subscription,
                    orElse: () => null,
                  );
                  final currentUser = currentUserAsync.maybeWhen(
                    data: (user) => user,
                    orElse: () => null,
                  );
                  final isPending = requestStatus == 'pending' && !isActive;
                  final showPlans = !isActive && !isPending;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Choose Your Plan',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Gap(4),
                      Text(
                        isActive
                            ? 'Your subscription is active. You can access workouts and nutrition plans.'
                            : isPending
                                ? 'Your subscription request is pending admin approval.'
                                : 'Choose the plan that fits your fitness journey',
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Gap(20),

                      if (showPlans) ...[
                        // Plans grid - visible only for inactive users
                        StreamBuilder<Map<String, double>>(
                          stream: firestoreService.bodySubscriptionPricingStream(),
                          builder: (context, pricingSnapshot) {
                            final pricing = pricingSnapshot.data ?? const {
                              'monthly': 49.0,
                              'quarterly': 39.0,
                              'yearly': 29.0,
                              'registrationFee': 1000.0,
                            };

                            final monthlyPrice = pricing['monthly'] ?? 49.0;
                            final quarterlyPrice = pricing['quarterly'] ?? 39.0;
                            final yearlyPrice = pricing['yearly'] ?? 29.0;
                            final registrationFee = pricing['registrationFee'] ?? 1000.0;
                            final requiresRegistrationFee =
                                currentUser?.bodyHolicsRegistrationFeePaid != true;

                            final monthlyLabel =
                                'PKR ${monthlyPrice.toStringAsFixed(0)}';
                            final quarterlyLabel =
                                'PKR ${quarterlyPrice.toStringAsFixed(0)}';
                            final yearlyLabel =
                                'PKR ${yearlyPrice.toStringAsFixed(0)}';

                            final quarterlyTotal = quarterlyPrice * 3;
                            final yearlyTotal = yearlyPrice * 12;
                            return isMobile
                                ? SingleChildScrollView(
                                    scrollDirection: Axis.horizontal,
                                    child: Row(
                                      children: [
                                        _buildPlanCard(
                                            'monthly',
                                            'Monthly',
                                            monthlyLabel,
                                            monthlyPrice,
                                            'Billed every month',
                                            null,
                                            registrationFee,
                                            requiresRegistrationFee),
                                        const Gap(12),
                                        _buildPlanCard(
                                            'quarterly',
                                            'Quarterly',
                                            quarterlyLabel,
                                            quarterlyPrice,
                                            'Billed every 3 months (PKR ${quarterlyTotal.toStringAsFixed(0)})',
                                            '⚡ MOST POPULAR',
                                            registrationFee,
                                            requiresRegistrationFee,
                                            isMostPopular: true),
                                        const Gap(12),
                                        _buildPlanCard(
                                            'yearly',
                                            'Yearly',
                                            yearlyLabel,
                                            yearlyPrice,
                                            'Billed annually (PKR ${yearlyTotal.toStringAsFixed(0)})',
                                            '⚡ BEST VALUE',
                                            registrationFee,
                                            requiresRegistrationFee),
                                      ],
                                    ),
                                  )
                                : Row(
                                    children: [
                                      Expanded(
                                        child: _buildPlanCard(
                                            'monthly',
                                            'Monthly',
                                            monthlyLabel,
                                            monthlyPrice,
                                            'Billed every month',
                                            null,
                                            registrationFee,
                                            requiresRegistrationFee),
                                      ),
                                      const Gap(16),
                                      Expanded(
                                        child: _buildPlanCard(
                                            'quarterly',
                                            'Quarterly',
                                            quarterlyLabel,
                                            quarterlyPrice,
                                            'Billed every 3 months (PKR ${quarterlyTotal.toStringAsFixed(0)})',
                                            '⚡ MOST POPULAR',
                                            registrationFee,
                                            requiresRegistrationFee,
                                            isMostPopular: true),
                                      ),
                                      const Gap(16),
                                      Expanded(
                                        child: _buildPlanCard(
                                            'yearly',
                                            'Yearly',
                                            yearlyLabel,
                                            yearlyPrice,
                                            'Billed annually (PKR ${yearlyTotal.toStringAsFixed(0)})',
                                            '⚡ BEST VALUE',
                                            registrationFee,
                                            requiresRegistrationFee),
                                      ),
                                    ],
                                  );
                          },
                        ),
                        const Gap(32),
                        StreamBuilder<Map<String, double>>(
                          stream: firestoreService.bodySubscriptionPricingStream(),
                          builder: (context, pricingSnapshot) {
                            final pricing = pricingSnapshot.data ?? const {
                              'registrationFee': 1000.0,
                            };
                            final registrationFee = pricing['registrationFee'] ?? 1000.0;

                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: AppTheme.bodyHolicsOrange.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                  color: AppTheme.bodyHolicsOrange.withOpacity(0.25),
                                ),
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: AppTheme.bodyHolicsOrange.withOpacity(0.18),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: const Icon(
                                      Icons.verified_user_rounded,
                                      color: AppTheme.bodyHolicsOrange,
                                      size: 20,
                                    ),
                                  ),
                                  const Gap(12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          'One-time registration fee',
                                          style: TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.textPrimary,
                                          ),
                                        ),
                                        const Gap(4),
                                        Text(
                                          currentUser?.bodyHolicsRegistrationFeePaid == true
                                              ? 'Registration fee already paid'
                                              : 'First-time registration fee: PKR ${registrationFee.toStringAsFixed(0)}',
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: AppTheme.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const Gap(16),
                      ],

                      if (isActive && currentSubscription != null) ...[
                        _buildActiveSubscriptionSummary(currentSubscription),
                        const Gap(16),
                        _buildMomentumTracker(currentSubscription),
                        const Gap(24),
                      ],

                      if (isPending)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.bodyHolicsOrange.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: AppTheme.bodyHolicsOrange.withOpacity(0.35),
                            ),
                          ),
                          child: const Text(
                            'Request submitted successfully. Please wait for admin approval.',
                            style: TextStyle(color: AppTheme.textPrimary),
                          ),
                        ),

                      if (isPending) const Gap(20),

                      const Text(
                        'Your Premium Access',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Gap(6),
                      Text(
                        isActive
                            ? 'Jump into your daily training and nutrition plans.'
                            : 'Activate your subscription to unlock premium programs.',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Gap(14),
                      if (isMobile) ...[
                        _buildAccessTile(
                          title: 'Workouts',
                          subtitle: isActive
                              ? 'View your workouts'
                              : 'Locked until subscription is active',
                          icon: Icons.play_arrow_rounded,
                          accent: AppTheme.bodyHolicsOrange,
                          isActive: isActive,
                          onTap: isActive
                              ? () => context.push(AppRoutes.bodyHolicsWorkouts)
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isPending
                                            ? 'Your subscription is pending approval.'
                                            : 'Please subscribe first to access workouts.',
                                      ),
                                    ),
                                  );
                                },
                        ),
                        const Gap(12),
                        _buildAccessTile(
                          title: 'Nutrition',
                          subtitle: isActive
                              ? 'Meal plans'
                              : 'Locked until subscription is active',
                          icon: Icons.restaurant_menu_rounded,
                          accent: const Color(0xFFFF8A00),
                          isActive: isActive,
                          onTap: isActive
                              ? () => context.push(AppRoutes.bodyHolicsNutrition)
                              : () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        isPending
                                            ? 'Your subscription is pending approval.'
                                            : 'Please subscribe first to access nutrition plans.',
                                      ),
                                    ),
                                  );
                                },
                        ),
                      ] else
                        Row(
                          children: [
                            Expanded(
                              child: _buildAccessTile(
                                title: 'Workouts',
                                subtitle: isActive
                                    ? 'View your workouts'
                                    : 'Locked until subscription is active',
                                icon: Icons.play_arrow_rounded,
                                accent: AppTheme.bodyHolicsOrange,
                                isActive: isActive,
                                onTap: isActive
                                    ? () => context.push(AppRoutes.bodyHolicsWorkouts)
                                    : () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isPending
                                                  ? 'Your subscription is pending approval.'
                                                  : 'Please subscribe first to access workouts.',
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            ),
                            const Gap(12),
                            Expanded(
                              child: _buildAccessTile(
                                title: 'Nutrition',
                                subtitle: isActive
                                    ? 'Meal plans'
                                    : 'Locked until subscription is active',
                                icon: Icons.restaurant_menu_rounded,
                                accent: const Color(0xFFFF8A00),
                                isActive: isActive,
                                onTap: isActive
                                    ? () => context.push(AppRoutes.bodyHolicsNutrition)
                                    : () {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              isPending
                                                  ? 'Your subscription is pending approval.'
                                                  : 'Please subscribe first to access nutrition plans.',
                                            ),
                                          ),
                                        );
                                      },
                              ),
                            ),
                          ],
                        ),
                      const Gap(32),
                    ],
                  );
                },
              ),
            ),
            ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _staggerReveal({
    required Widget child,
    required double delayFactor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, value, widgetChild) {
        final progress = Interval(delayFactor, 1.0, curve: Curves.easeOutCubic)
            .transform(value.clamp(0.0, 1.0));
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 20),
            child: widgetChild,
          ),
        );
      },
      child: child,
    );
  }

  void _handleSubscription(
    String plan,
    double planPrice,
    double registrationFee,
    bool requiresRegistrationFee,
  ) {
    final totalAmount = planPrice + (requiresRegistrationFee ? registrationFee : 0);
    showDialog(
      context: context,
      builder: (context) => SubscriptionModal(
        plan: plan,
        planPrice: planPrice,
        registrationFee: registrationFee,
        requiresRegistrationFee: requiresRegistrationFee,
        totalAmount: totalAmount,
        onSubmit: (data) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('$plan subscription request submitted!')),
          );
        },
      ),
    );
  }

  Widget _buildActiveSubscriptionSummary(dynamic subscription) {
    String formatDate(DateTime date) {
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      return '$day/$month/${date.year}';
    }

    String formatPlan(String plan) {
      if (plan.isEmpty) return 'N/A';
      return plan[0].toUpperCase() + plan.substring(1);
    }

    final now = DateTime.now();
    final endDate = subscription.endDate as DateTime;
    final startDate = subscription.startDate as DateTime;
    final daysRemaining = endDate.difference(now).inDays;
    final isExpiringSoon = daysRemaining <= 7;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF201208), Color(0xFF151515)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppTheme.bodyHolicsOrange.withOpacity(0.35),
        ),
        boxShadow: [AppTheme.cardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppTheme.bodyHolicsOrange.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.workspace_premium_rounded,
                  color: AppTheme.bodyHolicsOrange,
                ),
              ),
              const Gap(10),
              const Expanded(
                child: Text(
                  'Active Membership',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.successGreen.withOpacity(0.18),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: AppTheme.successGreen.withOpacity(0.35),
                  ),
                ),
                child: const Text(
                  'Active',
                  style: TextStyle(
                    color: AppTheme.successGreen,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const Gap(14),
          if (isExpiringSoon)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.warningYellow.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: AppTheme.warningYellow.withOpacity(0.28),
                ),
              ),
              child: Text(
                daysRemaining > 0
                    ? 'Renew soon: your membership ends in $daysRemaining days.'
                    : 'Your membership expires today. Renew now to keep access.',
                style: const TextStyle(
                  color: AppTheme.warningYellow,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          if (isExpiringSoon) const Gap(12),
          _buildMembershipDetailRow('Plan', formatPlan(subscription.plan as String)),
          const Gap(8),
          _buildMembershipDetailRow('Start Date', formatDate(startDate)),
          const Gap(8),
          _buildMembershipDetailRow('Renewal Date', formatDate(endDate)),
          const Gap(8),
          _buildMembershipDetailRow(
            'Days Remaining',
            daysRemaining > 0 ? '$daysRemaining days' : 'Expires today',
          ),
        ],
      ),
    );
  }

  Widget _buildMomentumTracker(dynamic subscription) {
    final now = DateTime.now();
    final startDate = subscription.startDate as DateTime;
    final endDate = subscription.endDate as DateTime;
    final totalDays = endDate.difference(startDate).inDays;
    final elapsedDays = now.difference(startDate).inDays;
    final progress = totalDays <= 0
        ? 0.0
        : (elapsedDays.clamp(0, totalDays) / totalDays).toDouble();
    final progressPercent = (progress * 100).round();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surfaceCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: AppTheme.orangeGradient,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.bolt_rounded,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const Gap(10),
              const Text(
                'Momentum Tracker',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
            ],
          ),
          const Gap(6),
          const Text(
            'Stay consistent to get the most from your current plan cycle.',
            style: TextStyle(
              fontSize: 13,
              color: AppTheme.textSecondary,
            ),
          ),
          const Gap(14),
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                backgroundColor: AppTheme.borderColor,
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppTheme.bodyHolicsOrange),
              ),
            ),
          ),
          const Gap(10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$progressPercent% completed',
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${totalDays - elapsedDays < 0 ? 0 : totalDays - elapsedDays} days left',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAccessTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color accent,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: isActive ? 1 : 0.66,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1B1B1B), Color(0xFF141414)],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isActive
                  ? accent.withOpacity(0.45)
                  : AppTheme.borderColor,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accent),
              ),
              const Gap(10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                    const Gap(3),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 14,
                color: isActive ? AppTheme.textPrimary : AppTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMembershipDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 13,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

    Widget _buildPlanCard(String planKey, String title, String price,
      double planPrice, String billing, String? badge,
      double registrationFee, bool requiresRegistrationFee,
      {bool isMostPopular = false}) {
    final Map<String, List<String>> featuresMap = {
      'monthly': [
        'Full gym access',
        '1 trainer session/month',
        'Workout tracking',
        'Community access',
      ],
      'quarterly': [
        'Full gym access',
        '4 trainer sessions/quarter',
        'Custom workout plan',
        'Nutrition guide',
        'Community access',
      ],
      'yearly': [
        'Full gym access',
        'Unlimited trainer sessions',
        'Custom workout + nutrition',
        'Body composition tracking',
        'Priority support',
        'Community access',
      ],
    };

    final features = featuresMap[planKey] ?? [];
    final color =
        planKey == 'yearly' ? const Color(0xFF9333EA) : AppTheme.bodyHolicsOrange;

    return _PlanCard(
      title: title,
      price: price,
      billing: billing,
      features: features,
      badge: badge,
      isSelected: _selectedPlan == planKey,
      color: color,
      isMostPopular: isMostPopular,
      onSelect: () => setState(() => _selectedPlan = planKey),
      onGetStarted: () => _handleSubscription(
        planKey,
        planPrice,
        registrationFee,
        requiresRegistrationFee,
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  final String title;
  final String price;
  final String billing;
  final List<String> features;
  final String? badge;
  final bool isSelected;
  final bool isMostPopular;
  final Color color;
  final VoidCallback onSelect;
  final VoidCallback onGetStarted;

  const _PlanCard({
    required this.title,
    required this.price,
    required this.billing,
    required this.features,
    this.badge,
    required this.isSelected,
    required this.color,
    this.isMostPopular = false,
    required this.onSelect,
    required this.onGetStarted,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelect,
      child: Transform.scale(
        scale: isMostPopular ? 1.05 : 1,
        child: Container(
          width: 300,
          decoration: BoxDecoration(
            color: AppTheme.surfaceCard,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? color : AppTheme.borderColor,
              width: isSelected ? 2 : 1,
            ),
            boxShadow: isMostPopular ? [AppTheme.cardShadow] : [],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (badge != null) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    badge!,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: color,
                    ),
                  ),
                ),
                const Gap(12),
              ],
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              const Gap(8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                  const Gap(4),
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Text(
                      '/mo',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const Gap(4),
              Text(
                billing,
                style: const TextStyle(
                  fontSize: 12,
                  color: AppTheme.textSecondary,
                ),
              ),
              const Gap(16),
              const Divider(color: AppTheme.borderColor),
              const Gap(16),
              ...features
                  .map(
                    (feature) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(Icons.check, color: color, size: 20),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              feature,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                  .toList(),
              const Gap(20),
              HolicsButton(
                label: 'Get Started',
                onPressed: onGetStarted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Subscription Modal - Multi-step form
class SubscriptionModal extends ConsumerStatefulWidget {
  final String plan;
  final double planPrice;
  final double registrationFee;
  final bool requiresRegistrationFee;
  final double totalAmount;
  final Function(Map<String, dynamic>) onSubmit;

  const SubscriptionModal({
    required this.plan,
    required this.planPrice,
    required this.registrationFee,
    required this.requiresRegistrationFee,
    required this.totalAmount,
    required this.onSubmit,
  });

  @override
  ConsumerState<SubscriptionModal> createState() => _SubscriptionModalState();
}

class _SubscriptionModalState extends ConsumerState<SubscriptionModal> {
  int _currentStep = 0;
  String? _selectedPaymentProof;
  String? _paymentProofUrl;
  bool _isSubmitting = false;
  bool _isUploadingProof = false;

  // Step 1: Personal Information
  final _fullNameController = TextEditingController();
  final _ageController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _emergencyContactController = TextEditingController();
  final _fitnessGoalsController = TextEditingController();

  // Step 2: Bank Details (removed - only payment proof now)
  // Bank details now come from admin settings

  @override
  void dispose() {
    _fullNameController.dispose();
    _ageController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _emergencyContactController.dispose();
    _fitnessGoalsController.dispose();
    super.dispose();
  }

  bool _isStep1Valid() {
    return _fullNameController.text.isNotEmpty &&
        _ageController.text.isNotEmpty &&
        _phoneController.text.isNotEmpty &&
        _addressController.text.isNotEmpty &&
        _emergencyContactController.text.isNotEmpty &&
        _fitnessGoalsController.text.isNotEmpty;
  }

  bool _isStep2Valid() {
    return _paymentProofUrl != null;
  }

  double get _amountDue => widget.totalAmount;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return WillPopScope(
      onWillPop: () async {
        if (_currentStep > 0) {
          setState(() => _currentStep--);
          return false;
        }
        return true;
      },
      child: Dialog(
        backgroundColor: AppTheme.surfaceCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        insetPadding: EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 24,
        ),
        child: Container(
          width: size.width > 600 ? 600 : null,
          constraints: BoxConstraints(
            maxHeight: size.height * 0.85,
          ),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text(
                    'Step ${_currentStep + 1} of 2',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const Gap(8),

              // Progress indicator
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_currentStep + 1) / 2,
                  backgroundColor: AppTheme.borderColor,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.bodyHolicsOrange,
                  ),
                  minHeight: 4,
                ),
              ),
              const Gap(20),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppTheme.darkBg,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      'Plan amount',
                      'PKR ${widget.planPrice.toStringAsFixed(0)}',
                    ),
                    const Gap(8),
                    _buildDetailRow(
                      'Registration fee',
                      widget.requiresRegistrationFee
                          ? 'PKR ${widget.registrationFee.toStringAsFixed(0)}'
                          : 'Already paid',
                    ),
                    const Gap(8),
                    _buildDetailRow(
                      'Total due',
                      'PKR ${_amountDue.toStringAsFixed(0)}',
                    ),
                  ],
                ),
              ),

              const Gap(16),

              // Content
              Expanded(
                child: SingleChildScrollView(
                  child: _currentStep == 0
                      ? _buildStep1PersonalInfo()
                      : _buildStep2BankDetails(),
                ),
              ),

              const Gap(20),

              // Buttons
              Row(
                children: [
                  if (_currentStep > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => setState(() => _currentStep--),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          side: const BorderSide(
                            color: AppTheme.bodyHolicsOrange,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Back',
                          style: TextStyle(color: AppTheme.bodyHolicsOrange),
                        ),
                      ),
                    ),
                  if (_currentStep > 0) const Gap(12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSubmitting
                          ? null
                          : () async {
                              if (_currentStep == 0) {
                                if (_isStep1Valid()) {
                                  setState(() => _currentStep++);
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please fill all personal information'),
                                    ),
                                  );
                                }
                              } else {
                                if (_isStep2Valid()) {
                                  await _submitSubscription();
                                } else {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                          'Please attach payment proof before submitting'),
                                    ),
                                  );
                                }
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.bodyHolicsOrange,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : Text(
                              _currentStep == 0 ? 'Next' : 'Submit Request',
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStep1PersonalInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Personal Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimary,
          ),
        ),
        const Gap(4),
        const Text(
          'Help us know more about you',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const Gap(20),
        _buildTextField('Full Name', _fullNameController),
        const Gap(12),
        _buildTextField('Age', _ageController, keyboardType: TextInputType.number),
        const Gap(12),
        _buildTextField('Phone Number', _phoneController,
            keyboardType: TextInputType.phone),
        const Gap(12),
        _buildTextField('Address', _addressController,
            maxLines: 2, hintText: 'Street, City, Zip'),
        const Gap(12),
        _buildTextField('Emergency Contact', _emergencyContactController),
        const Gap(12),
        _buildTextField('Fitness Goals', _fitnessGoalsController,
            maxLines: 3, hintText: 'e.g., Weight loss, Muscle gain, etc.'),
      ],
    );
  }

  Widget _buildStep2BankDetails() {
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
          'Transfer funds to the owner\'s account below',
          style: TextStyle(
            fontSize: 14,
            color: AppTheme.textSecondary,
          ),
        ),
        const Gap(20),

        if (widget.requiresRegistrationFee)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.bodyHolicsOrange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppTheme.bodyHolicsOrange.withOpacity(0.25),
              ),
            ),
            child: const Text(
              'This is your first Body Holics registration, so the one-time registration fee is included in the total.',
              style: TextStyle(
                fontSize: 12,
                color: AppTheme.textPrimary,
              ),
            ),
          ),

        if (widget.requiresRegistrationFee) const Gap(16),

        // Owner Bank Details (Read-only)
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.bodyHolicsOrange.withOpacity(0.1),
            border: Border.all(
              color: AppTheme.bodyHolicsOrange.withOpacity(0.3),
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
                  'Owner bank details not yet configured',
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
        const Gap(20),

        // Payment Proof Upload
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
          onTap: _isUploadingProof ? null : () async {
            await _pickAndUploadProof();
          },
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: AppTheme.bodyHolicsOrange.withOpacity(0.5),
                style: BorderStyle.solid,
                width: 2,
              ),
              borderRadius: BorderRadius.circular(12),
              color: AppTheme.bodyHolicsOrange.withOpacity(0.05),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Column(
              children: [
                _isUploadingProof
                    ? const SizedBox(
                        height: 40,
                        width: 40,
                        child: CircularProgressIndicator(
                          strokeWidth: 3,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.bodyHolicsOrange,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.cloud_upload_outlined,
                        color: AppTheme.bodyHolicsOrange,
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
                const Gap(4),
                const Text(
                  'Click to upload screenshot of payment',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? hintText,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Gap(6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hintText ?? label,
            hintStyle: const TextStyle(color: AppTheme.textSecondary),
            filled: true,
            fillColor: AppTheme.darkBg,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(color: AppTheme.borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: const BorderSide(
                color: AppTheme.bodyHolicsOrange,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
          ),
          style: const TextStyle(color: AppTheme.textPrimary),
        ),
      ],
    );
  }

  Future<void> _submitSubscription() async {
    setState(() => _isSubmitting = true);

    try {
      final firestoreService = ref.read(firestoreServiceProvider);
      final authService = ref.read(authServiceProvider);
      
      final uid = authService.currentUser?.uid;
      if (uid == null) {
        throw 'User not authenticated';
      }

      final personalInfo = {
        'fullName': _fullNameController.text.trim(),
        'age': int.tryParse(_ageController.text) ?? 0,
        'phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
        'emergencyContact': _emergencyContactController.text.trim(),
        'fitnessGoals': _fitnessGoalsController.text.trim(),
      };

      // Save to Firestore (bankDetails is now empty - users see owner's details instead)
      await firestoreService.createSubscriptionRequest(
        uid,
        personalInfo['fullName'] as String,
        widget.plan,
        personalInfo,
        {}, // No bank details from user - they transfer to owner's account
        _paymentProofUrl,
        widget.planPrice,
        registrationFee: widget.requiresRegistrationFee ? widget.registrationFee : 0,
        totalAmount: widget.totalAmount,
        requiresRegistrationFee: widget.requiresRegistrationFee,
        registrationFeePaid: !widget.requiresRegistrationFee,
      );

      final data = {
        'plan': widget.plan,
        'selectedPrice': widget.planPrice,
        'fullName': _fullNameController.text,
        'age': _ageController.text,
        'phone': _phoneController.text,
        'address': _addressController.text,
        'emergencyContact': _emergencyContactController.text,
        'fitnessGoals': _fitnessGoalsController.text,
        'paymentProof': _selectedPaymentProof,
        'paymentProofUrl': _paymentProofUrl,
        'registrationFee': widget.requiresRegistrationFee ? widget.registrationFee : 0,
        'totalAmount': widget.totalAmount,
        'requiresRegistrationFee': widget.requiresRegistrationFee,
      };

      widget.onSubmit(data);
    } catch (e) {
      print('Error submitting subscription: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    } finally {
      setState(() => _isSubmitting = false);
    }
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

