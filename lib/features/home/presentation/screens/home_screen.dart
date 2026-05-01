
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_holics/core/theme/app_theme.dart';
import 'package:the_holics/core/router/app_routes.dart';
import 'package:the_holics/shared/widgets/common_widgets.dart';
import 'package:the_holics/shared/widgets/state_widgets.dart';
import 'package:the_holics/shared/models/appointment_model.dart';
import 'package:the_holics/shared/models/skin_models.dart';
import 'package:the_holics/shared/providers/user_provider.dart';
import 'package:the_holics/shared/providers/providers.dart';
import 'package:the_holics/shared/providers/content_provider.dart';
import 'package:the_holics/shared/widgets/holics_bottom_nav.dart';
import 'package:gap/gap.dart';
import 'package:url_launcher/url_launcher.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Future<void> _handleLogout() async {
    await ref.read(authServiceProvider).signOut();
  }

  Future<void> _openWhatsApp(String whatsappNumber, String specialistName) async {
    final normalizedNumber = whatsappNumber.replaceAll(RegExp(r'\D'), '');
    final message = Uri.encodeComponent(
      'Hi $specialistName! I have an approved consultation appointment with you. Looking forward to our session!'
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

        if (!fallbackLaunched && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Unable to open WhatsApp')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final appointments = ref.watch(currentUserAppointmentsProvider);
    final specialists = ref.watch(specialistsProvider);
    final firestoreService = ref.watch(firestoreServiceProvider);
    final size = MediaQuery.of(context).size;
    final isMobile = size.width < 600;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        leading: const Padding(
          padding: EdgeInsets.all(8.0),
          child: HolicsLogo(size: 40),
        ),
        title: const Text('Holics'),
        actions: [
          if (!isMobile) ...[
            TextButton(
              onPressed: () => context.go(AppRoutes.home),
              child: const Text('Home'),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.bodyHolics),
              child: const Text('Body Holics'),
            ),
            TextButton(
              onPressed: () => context.push(AppRoutes.skinHolics),
              child: const Text('Skin Holics'),
            ),
          ],
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: PopupMenuButton<String>(
              onSelected: (value) async {
                if (value == 'profile') {
                  context.push(AppRoutes.profile);
                  return;
                }
                if (value == 'logout') {
                  await _handleLogout();
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem<String>(
                  value: 'profile',
                  child: const Text('Profile'),
                ),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: const Text('Logout'),
                ),
              ],
              child: user.maybeWhen(
                data: (userData) => CircleAvatar(
                  backgroundColor: AppTheme.bodyHolicsOrange,
                  child: Text(
                    userData?.name.isNotEmpty == true
                        ? userData!.name[0].toUpperCase()
                        : 'U',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                orElse: () => const CircleAvatar(),
              ),
            ),
          ),
        ],
      ),
      body: _buildBody(user, appointments, specialists, isMobile),
      bottomNavigationBar: const HolicsBottomNav(currentIndex: 0),
    );
  }

  Widget _buildBody(
    AsyncValue<dynamic> user,
    AsyncValue<List<Appointment>> appointments,
    AsyncValue<List<Specialist>> specialists,
    bool isMobile,
  ) {
    return Stack(
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
          bottom: -120,
          left: -100,
          child: Container(
            width: 260,
            height: 260,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.skinHolichPink.withOpacity(0.08),
            ),
          ),
        ),
        SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 760),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF2A190D), Color(0xFF171717)],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppTheme.bodyHolicsOrange.withOpacity(0.28),
                        ),
                      ),
                      child: user.maybeWhen(
                        data: (userData) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Good morning',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                            const Gap(6),
                            Text(
                              userData?.name ?? 'User',
                              style: const TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            const Gap(4),
                            const Text(
                              'Choose a service and keep your routine on track.',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        orElse: () => ShimmerLoader(
                          width: double.infinity,
                          height: 70,
                        ),
                      ),
                    ),
                    const Gap(24),

                    _HeroCard(
                      title: 'Body Holics',
                      subtitle: 'Gym subscriptions, workout plans & nutrition',
                      icon: Icons.fitness_center,
                      color: AppTheme.bodyHolicsOrange,
                      onTap: () => context.push(AppRoutes.bodyHolics),
                    ),
                    const Gap(14),
                    _HeroCard(
                      title: 'Skin Holics',
                      subtitle: 'Skincare appointments & beauty treatments',
                      icon: Icons.spa,
                      color: AppTheme.skinHolichPink,
                      onTap: () => context.push(AppRoutes.skinHolics),
                    ),
                    const Gap(26),

                    const Text(
                      'Upcoming Sessions',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                    const Gap(10),
                    appointments.when(
              data: (appts) {
                final upcomingAppointments = appts.where((apt) => apt.isUpcoming).toList();

                return upcomingAppointments.isEmpty
                  ? const EmptyStateWidget(
                      title: 'No Upcoming Sessions',
                      subtitle: 'Book an appointment to get started',
                      icon: Icons.calendar_today,
                    )
                  : specialists.when(
                      data: (specialistList) {
                        final specialistById = {
                          for (final specialist in specialistList)
                            specialist.id: specialist,
                        };

                        final sortedAppointments = [...upcomingAppointments]
                          ..sort((a, b) => a.date.compareTo(b.date));

                        return ListView.builder(
                          itemCount: sortedAppointments.length.clamp(0, 3),
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemBuilder: (context, index) {
                            final appointment = sortedAppointments[index];
                            final specialist =
                                specialistById[appointment.specialistId];
                            final specialistName =
                                (specialist?.title.isNotEmpty == true)
                                    ? specialist!.title
                                    : (specialist?.name.isNotEmpty == true)
                                        ? specialist!.name
                                        : 'Specialist not assigned';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceCard,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    appointment.service,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.textPrimary,
                                    ),
                                  ),
                                  const Gap(10),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.calendar_today,
                                        size: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const Gap(6),
                                      Text(
                                        '${appointment.date.day}/${appointment.date.month}/${appointment.date.year}',
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const Gap(14),
                                      const Icon(
                                        Icons.access_time,
                                        size: 14,
                                        color: AppTheme.textSecondary,
                                      ),
                                      const Gap(6),
                                      Text(
                                        appointment.time,
                                        style: const TextStyle(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Gap(8),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.person,
                                        size: 14,
                                        color: AppTheme.skinHolichPink,
                                      ),
                                      const Gap(6),
                                      Expanded(
                                        child: Text(
                                          specialistName,
                                          style: const TextStyle(
                                            color: AppTheme.textPrimary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Gap(10),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: appointment.status.toLowerCase() == 'pending'
                                          ? Colors.amber.withOpacity(0.2)
                                          : appointment.status.toLowerCase() == 'cancelled'
                                              ? Colors.red.withOpacity(0.2)
                                          : Colors.green.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      appointment.status.toLowerCase() == 'pending'
                                          ? 'Pending Approval'
                                          : appointment.status.toLowerCase() == 'cancelled'
                                              ? 'Cancelled'
                                          : appointment.status.toLowerCase() == 'approved'
                                              ? 'Approved'
                                              : appointment.status.toUpperCase(),
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: appointment.status.toLowerCase() == 'pending'
                                            ? Colors.amber.shade700
                                            : appointment.status.toLowerCase() == 'cancelled'
                                                ? Colors.red.shade700
                                            : Colors.green.shade700,
                                      ),
                                    ),
                                  ),
                                  if (appointment.status.toLowerCase() == 'cancelled') ...[
                                    const Gap(10),
                                    StreamBuilder<Map<String, dynamic>?> (
                                      stream: ref
                                          .watch(firestoreServiceProvider)
                                          .supportContactStream(),
                                      builder: (context, snapshot) {
                                        if (snapshot.hasError) {
                                          return const Text(
                                            'Unable to load support contact',
                                            style: TextStyle(
                                              color: AppTheme.errorRed,
                                              fontSize: 12,
                                            ),
                                          );
                                        }

                                        final supportNumber = snapshot.data?['whatsappNumber']?.toString();
                                        if (supportNumber == null || supportNumber.trim().isEmpty) {
                                          return const Text(
                                            'Support contact not configured',
                                            style: TextStyle(
                                              color: AppTheme.textSecondary,
                                              fontSize: 12,
                                            ),
                                          );
                                        }

                                        return GestureDetector(
                                          onTap: () => _openWhatsApp(
                                            supportNumber,
                                            'Support Team',
                                          ),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 12,
                                              vertical: 8,
                                            ),
                                            decoration: BoxDecoration(
                                              color: Colors.red.withOpacity(0.15),
                                              borderRadius: BorderRadius.circular(8),
                                              border: Border.all(
                                                color: Colors.red.withOpacity(0.5),
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                const Icon(
                                                  Icons.support_agent,
                                                  size: 16,
                                                  color: Colors.red,
                                                ),
                                                const Gap(6),
                                                const Text(
                                                  'Contact Support on WhatsApp',
                                                  style: TextStyle(
                                                    color: Colors.red,
                                                    fontWeight: FontWeight.w600,
                                                    fontSize: 12,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ] else if ((appointment.status.toLowerCase() == 'approved' || appointment.status.toLowerCase() == 'confirmed') && specialist?.whatsappNumber != null) ...[
                                    const Gap(10),
                                    GestureDetector(
                                      onTap: () => _openWhatsApp(
                                        specialist!.whatsappNumber!,
                                        specialistName,
                                      ),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 8,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.green.withOpacity(0.15),
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: Colors.green.withOpacity(0.5),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(
                                              Icons.chat,
                                              size: 16,
                                              color: Colors.green,
                                            ),
                                            const Gap(6),
                                            const Text(
                                              'Contact on WhatsApp',
                                              style: TextStyle(
                                                color: Colors.green,
                                                fontWeight: FontWeight.w600,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        );
                      },
                      loading: () => ShimmerCardLoader(),
                      error: (error, stack) => ErrorStateWidget(
                        message: error.toString(),
                        onRetry: () {},
                      ),
                    );
              },
              loading: () => ShimmerCardLoader(),
              error: (error, stack) => ErrorStateWidget(
                message: error.toString(),
                onRetry: () {},
              ),
            ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _HeroCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 170,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.24),
              const Color(0xFF181818),
            ],
          ),
          border: Border.all(color: AppTheme.borderColor),
        ),
        padding: const EdgeInsets.all(18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.24),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 28),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Gap(4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
            Align(
              alignment: Alignment.bottomRight,
              child: Icon(Icons.arrow_forward, color: color, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}
