import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:the_holics/core/theme/app_theme.dart';
import 'package:the_holics/core/router/app_routes.dart';
import 'package:the_holics/shared/widgets/common_widgets.dart';
import 'package:the_holics/shared/widgets/holics_buttons.dart';
import 'package:the_holics/shared/widgets/holics_bottom_nav.dart';
import 'package:the_holics/shared/widgets/state_widgets.dart';
import 'package:the_holics/shared/providers/user_provider.dart';
import 'package:the_holics/shared/providers/subscription_provider.dart';
import 'package:the_holics/shared/providers/content_provider.dart';
import 'package:the_holics/shared/providers/providers.dart';
import 'package:gap/gap.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  int _daysRemaining(DateTime endDate) {
    final days = endDate.difference(DateTime.now()).inDays;
    return days < 0 ? 0 : days;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);
    final subscriptionAsync = ref.watch(currentUserSubscriptionProvider);
    final appointmentsAsync = ref.watch(currentUserAppointmentsProvider);

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        title: const Text('Profile'),
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
      ),
      bottomNavigationBar: const HolicsBottomNav(currentIndex: 3),
      body: userAsync.when(
        data: (user) => user == null
            ? const Center(child: Text('Not logged in'))
            : Stack(
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
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
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
                              colors: [Color(0xFF2A180C), Color(0xFF171717)],
                            ),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: AppTheme.bodyHolicsOrange.withOpacity(0.28),
                            ),
                          ),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 34,
                                backgroundColor: AppTheme.bodyHolicsOrange,
                                child: Text(
                                  user.name.isNotEmpty
                                      ? user.name[0].toUpperCase()
                                      : 'U',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                              const Gap(14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text(
                                      'Account',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                    const Gap(3),
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.textPrimary,
                                      ),
                                    ),
                                    const Gap(2),
                                    Text(
                                      user.email,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Gap(24),

                        const Text(
                          'Current Subscription',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Gap(10),
                        subscriptionAsync.when(
                          data: (subscription) => HolicsCard(
                            child: subscription == null
                                ? Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'No active subscription',
                                        style: TextStyle(
                                          color: AppTheme.textSecondary,
                                        ),
                                      ),
                                      const Gap(12),
                                      HolicsButton(
                                        label: 'Browse Plans',
                                        isSmall: true,
                                        onPressed: () =>
                                            context.push(AppRoutes.bodyHolics),
                                      ),
                                    ],
                                  )
                                : Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            subscription.plan.toUpperCase(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: AppTheme.bodyHolicsOrange,
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: subscription.isActive
                                                  ? AppTheme.successGreen.withOpacity(0.2)
                                                  : AppTheme.errorRed.withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(20),
                                            ),
                                            child: Text(
                                              subscription.isActive
                                                  ? 'Active'
                                                  : 'Inactive',
                                              style: TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w700,
                                                color: subscription.isActive
                                                    ? AppTheme.successGreen
                                                    : AppTheme.errorRed,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Gap(10),
                                      const Divider(color: AppTheme.borderColor),
                                      const Gap(10),
                                      _ProfileItem(
                                        label: 'Start Date',
                                        value: _formatDate(subscription.startDate),
                                      ),
                                      _ProfileItem(
                                        label: 'End Date',
                                        value: _formatDate(subscription.endDate),
                                      ),
                                      _ProfileItem(
                                        label: 'Days Remaining',
                                        value: '${_daysRemaining(subscription.endDate)} days',
                                      ),
                                    ],
                                  ),
                          ),
                          loading: () => ShimmerLoader(
                            width: double.infinity,
                            height: 120,
                          ),
                          error: (error, stack) => Text('Error: $error'),
                        ),
                        const Gap(24),

                        const Text(
                          'Upcoming Appointments',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const Gap(10),
                        appointmentsAsync.when(
                          data: (appointments) {
                            final upcomingAppointments = appointments
                                .where((apt) => apt.isUpcoming)
                                .toList()
                              ..sort((a, b) => a.date.compareTo(b.date));

                            if (upcomingAppointments.isEmpty) {
                              return const EmptyStateWidget(
                                title: 'No Appointments',
                                subtitle: 'Book an appointment to get started',
                                icon: Icons.calendar_today,
                              );
                            }

                            return ListView.builder(
                              itemCount: upcomingAppointments.length.clamp(0, 3),
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemBuilder: (context, index) {
                                final apt = upcomingAppointments[index];
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 10),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: AppTheme.surfaceCard,
                                    borderRadius: BorderRadius.circular(14),
                                    border: Border.all(color: AppTheme.borderColor),
                                  ),
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 38,
                                        height: 38,
                                        decoration: BoxDecoration(
                                          color: AppTheme.bodyHolicsOrange.withOpacity(0.16),
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                        child: const Icon(
                                          Icons.event_note,
                                          size: 20,
                                          color: AppTheme.bodyHolicsOrange,
                                        ),
                                      ),
                                      const Gap(12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              apt.service,
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                                color: AppTheme.textPrimary,
                                              ),
                                            ),
                                            const Gap(2),
                                            Text(
                                              '${apt.date.day}/${apt.date.month} at ${apt.time}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(
                                        Icons.arrow_forward_ios_rounded,
                                        size: 16,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                          loading: () => ShimmerCardLoader(),
                          error: (error, stack) => Text('Error: $error'),
                        ),
                        const Gap(24),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppTheme.surfaceCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppTheme.borderColor),
                          ),
                          child: Column(
                            children: [
                              HolicsButton(
                                label: 'Change Password',
                                isSecondary: true,
                                onPressed: () async {
                                  final changed = await showDialog<bool>(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (_) => const _ChangePasswordDialog(),
                                  );

                                  if (context.mounted && changed == true) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Password updated successfully.'),
                                      ),
                                    );
                                  }
                                },
                              ),
                              const Gap(10),
                              HolicsButton(
                                label: 'Logout',
                                isSecondary: true,
                                onPressed: () async {
                                  await ref.read(authServiceProvider).signOut();
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => ErrorStateWidget(
          message: error.toString(),
          onRetry: () {},
        ),
      ),
    );
  }

}

class _ChangePasswordDialog extends ConsumerStatefulWidget {
  const _ChangePasswordDialog();

  @override
  ConsumerState<_ChangePasswordDialog> createState() =>
      _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends ConsumerState<_ChangePasswordDialog> {
  late final TextEditingController _currentPasswordController;
  late final TextEditingController _newPasswordController;
  late final TextEditingController _confirmPasswordController;
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _currentPasswordController = TextEditingController();
    _newPasswordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final currentPassword = _currentPasswordController.text.trim();
    final newPassword = _newPasswordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (currentPassword.isEmpty || newPassword.isEmpty || confirmPassword.isEmpty) {
      setState(() => _errorMessage = 'Please fill all password fields.');
      return;
    }

    if (newPassword.length < 6) {
      setState(() => _errorMessage = 'New password must be at least 6 characters.');
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _errorMessage = 'New passwords do not match.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authServiceProvider).changePassword(
            currentPassword: currentPassword,
            newPassword: newPassword,
          );

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppTheme.surfaceCard,
      title: const Text('Change Password'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Current Password',
              ),
            ),
            const Gap(12),
            TextField(
              controller: _newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'New Password',
              ),
            ),
            const Gap(12),
            TextField(
              controller: _confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Confirm New Password',
              ),
            ),
            if (_errorMessage != null) ...[
              const Gap(12),
              Text(
                _errorMessage!,
                style: const TextStyle(
                  color: AppTheme.errorRed,
                  fontSize: 12,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isSubmitting ? null : _submit,
          child: _isSubmitting
              ? const SizedBox(
                  height: 18,
                  width: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Update'),
        ),
      ],
    );
  }
}

class _ProfileItem extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileItem({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
