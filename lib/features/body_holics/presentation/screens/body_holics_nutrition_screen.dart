import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:the_holics/core/theme/app_theme.dart';
import 'package:the_holics/shared/providers/providers.dart';
import 'package:the_holics/shared/providers/content_provider.dart';
import 'package:the_holics/shared/providers/subscription_provider.dart';
import 'package:the_holics/shared/widgets/holics_bottom_nav.dart';

class BodyHolicsNutritionScreen extends ConsumerWidget {
  const BodyHolicsNutritionScreen({super.key});

  Future<void> _openWhatsApp(
    BuildContext context,
    String whatsappNumber,
  ) async {
    final normalizedNumber = whatsappNumber.replaceAll(RegExp(r'\D'), '');
    final message = Uri.encodeComponent(
      'Hi Dr Zunair Azam! I want my personalized nutrition plan from Body Holics.',
    );

    final whatsappUri = Uri.parse(
      'whatsapp://send?phone=$normalizedNumber&text=$message',
    );
    final fallbackUri = Uri.parse(
      'https://wa.me/$normalizedNumber?text=$message',
    );

    try {
      final launched = await launchUrl(
        whatsappUri,
        mode: LaunchMode.externalApplication,
      );

      if (!launched) {
        final fallbackLaunched = await launchUrl(
          fallbackUri,
          mode: LaunchMode.externalApplication,
        );

        if (!fallbackLaunched && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open WhatsApp')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(currentUserIdProvider);
    final firestore = ref.watch(firestoreServiceProvider);
    final hasActiveSubscriptionAsync =
        ref.watch(currentUserHasActiveSubscriptionProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: const Text('Body Holics Nutrition'),
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
      ),
      bottomNavigationBar: const HolicsBottomNav(currentIndex: 1),
      body: Stack(
        children: [
          Positioned(
            top: -90,
            right: -80,
            child: Container(
              width: 220,
              height: 220,
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
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.skinHolichPink.withOpacity(0.06),
              ),
            ),
          ),
          uid == null
          ? const Center(
              child: Text(
                'Please sign in first.',
                style: TextStyle(color: AppTheme.textSecondary),
              ),
            )
          : StreamBuilder<Map<String, dynamic>?>(
              stream: firestore.userSubscriptionRequestStream(uid),
              builder: (context, subSnap) {
                final requestStatus =
                    (subSnap.data?['status']?.toString().toLowerCase() ?? 'inactive');
                final isActive = hasActiveSubscriptionAsync.maybeWhen(
                  data: (isActive) => isActive,
                  orElse: () => false,
                );

                if (!isActive) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: _StaggerReveal(
                        delayFactor: 0.10,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock, color: AppTheme.textSecondary, size: 40),
                              const Gap(12),
                              Text(
                                requestStatus == 'pending'
                                    ? 'Your subscription is pending admin approval.'
                                    : 'You need an active subscription to access nutrition plans.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppTheme.textSecondary),
                              ),
                              const Gap(16),
                              ElevatedButton(
                                onPressed: () => context.pop(),
                                child: const Text('Back to Body Holics'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }

                final specialistsAsync = ref.watch(specialistsProvider);
                return specialistsAsync.when(
                  data: (specialists) {
                    final drZunair = specialists.where((s) {
                      final name = s.name.toLowerCase();
                      final title = s.title.toLowerCase();
                      return name.contains('zunair azam') ||
                          title.contains('zunair azam');
                    }).toList();
                    final specialist = drZunair.isNotEmpty ? drZunair.first : null;
                    final whatsappNumber = specialist?.whatsappNumber;

                    return ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _StaggerReveal(
                          delayFactor: 0.06,
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(18),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [Color(0xFF2A190D), Color(0xFF171717)],
                              ),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppTheme.bodyHolicsOrange.withOpacity(0.24),
                              ),
                            ),
                            child: const Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Personal Nutrition Plan',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                Gap(6),
                                Text(
                                  'Body Holics nutrition is managed only by Dr Zunair Azam. Contact him directly on WhatsApp for your custom plan.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Gap(14),
                        _StaggerReveal(
                          delayFactor: 0.12,
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [AppTheme.surfaceCard, Color(0xFF1A1A1A)],
                              ),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppTheme.borderColor),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        color: AppTheme.bodyHolicsOrange.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(
                                        Icons.medical_services,
                                        color: AppTheme.bodyHolicsOrange,
                                      ),
                                    ),
                                    const Gap(12),
                                    const Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Dr Zunair Azam',
                                            style: TextStyle(
                                              color: AppTheme.textPrimary,
                                              fontSize: 16,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                          Gap(2),
                                          Text(
                                            'Gym & Nutrition Specialist',
                                            style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(14),
                                const Text(
                                  'Share your goal, current weight, schedule, and food preferences on WhatsApp to receive your personalized plan.',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                                const Gap(16),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    onPressed: (whatsappNumber == null ||
                                            whatsappNumber.trim().isEmpty)
                                        ? null
                                        : () => _openWhatsApp(
                                              context,
                                              whatsappNumber,
                                            ),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF1FAE57),
                                      foregroundColor: Colors.white,
                                      minimumSize: const Size.fromHeight(52),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    icon: const Icon(Icons.chat),
                                    label: const Text(
                                      'Contact on WhatsApp',
                                      style: TextStyle(fontWeight: FontWeight.w700),
                                    ),
                                  ),
                                ),
                                if (specialist == null) ...[
                                  const Gap(10),
                                  const Text(
                                    'Dr Zunair profile not found in specialists collection.',
                                    style: TextStyle(
                                      color: AppTheme.errorRed,
                                      fontSize: 12,
                                    ),
                                  ),
                                ] else if (whatsappNumber == null ||
                                    whatsappNumber.trim().isEmpty) ...[
                                  const Gap(10),
                                  const Text(
                                    'Dr Zunair WhatsApp number is not configured in specialists collection.',
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => Center(
                    child: Text(
                      e.toString(),
                      style: const TextStyle(color: AppTheme.textSecondary),
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _StaggerReveal extends StatelessWidget {
  final Widget child;
  final double delayFactor;

  const _StaggerReveal({
    required this.child,
    required this.delayFactor,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, widgetChild) {
        final progress = Interval(delayFactor, 1.0, curve: Curves.easeOutCubic)
            .transform(value.clamp(0.0, 1.0));
        return Opacity(
          opacity: progress,
          child: Transform.translate(
            offset: Offset(0, (1 - progress) * 18),
            child: widgetChild,
          ),
        );
      },
      child: child,
    );
  }
}
