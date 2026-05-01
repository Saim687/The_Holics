import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:the_holics/core/theme/app_theme.dart';
import 'package:the_holics/core/router/app_routes.dart';
import 'package:the_holics/shared/models/appointment_model.dart';
import 'package:the_holics/shared/models/subscription_model.dart';
import 'package:the_holics/shared/models/user_model.dart';
import 'package:the_holics/shared/models/skin_models.dart';
import 'package:the_holics/shared/widgets/common_widgets.dart';
import 'package:the_holics/shared/widgets/state_widgets.dart';
import 'package:the_holics/shared/providers/user_provider.dart';
import 'package:the_holics/shared/providers/subscription_provider.dart';
import 'package:the_holics/shared/providers/content_provider.dart';
import 'package:the_holics/shared/providers/providers.dart';
import 'package:gap/gap.dart';

class _AdminTabItem {
  final String label;
  final IconData icon;

  const _AdminTabItem({required this.label, required this.icon});
}

const _adminTabs = [
  _AdminTabItem(label: 'Dashboard', icon: Icons.dashboard),
  _AdminTabItem(label: 'Members', icon: Icons.people),
  _AdminTabItem(label: 'Subscriptions', icon: Icons.card_membership),
  _AdminTabItem(label: 'Appointments', icon: Icons.calendar_today),
  _AdminTabItem(label: 'Services', icon: Icons.spa),
  _AdminTabItem(label: 'Specialists', icon: Icons.person),
  _AdminTabItem(label: 'Settings', icon: Icons.settings),
];

class AdminDashboard extends ConsumerStatefulWidget {
  const AdminDashboard({Key? key}) : super(key: key);

  @override
  ConsumerState<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends ConsumerState<AdminDashboard> {
  int _selectedTab = 0;

  Future<void> _handleLogout() async {
    try {
      final authService = ref.read(authServiceProvider);
      await authService.signOut();
      if (!mounted) return;
      context.go(AppRoutes.login);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Logout failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width >= 1024;

    return Scaffold(
      backgroundColor: AppTheme.darkBg,
      appBar: AppBar(
        title: Text(isDesktop ? 'Admin Dashboard' : _adminTabs[_selectedTab].label),
        backgroundColor: AppTheme.darkBg,
        elevation: 0,
        actions: isDesktop
            ? [
                IconButton(
                  tooltip: 'Logout',
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout),
                ),
              ]
            : [
                PopupMenuButton<int>(
                  icon: const Icon(Icons.menu),
                  onSelected: (tab) => setState(() => _selectedTab = tab),
                  itemBuilder: (context) => [
                    for (int i = 0; i < _adminTabs.length; i++)
                      PopupMenuItem<int>(
                        value: i,
                        child: Row(
                          children: [
                            Icon(
                              _adminTabs[i].icon,
                              size: 18,
                              color: _selectedTab == i
                                  ? AppTheme.bodyHolicsOrange
                                  : AppTheme.textSecondary,
                            ),
                            const Gap(10),
                            Text(_adminTabs[i].label),
                          ],
                        ),
                      ),
                  ],
                ),
                IconButton(
                  tooltip: 'Logout',
                  onPressed: _handleLogout,
                  icon: const Icon(Icons.logout),
                ),
              ],
      ),
      body: Stack(
        children: [
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.bodyHolicsOrange.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: -130,
            left: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.skinHolichPink.withOpacity(0.05),
              ),
            ),
          ),
          isDesktop
              ? Row(
                  children: [
                    // Sidebar
                    Container(
                      width: 250,
                      margin: const EdgeInsets.fromLTRB(14, 14, 10, 14),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [Color(0xFF1E1E1E), Color(0xFF161616)],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: _AdminSidebar(
                        selectedTab: _selectedTab,
                        onTabChanged: (tab) => setState(() => _selectedTab = tab),
                      ),
                    ),
                    // Main content
                    Expanded(
                      child: _AdminContent(tab: _selectedTab),
                    ),
                  ],
                )
              : Column(
                  children: [
                    SizedBox(
                      height: 52,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        scrollDirection: Axis.horizontal,
                        itemCount: _adminTabs.length,
                        separatorBuilder: (_, __) => const Gap(8),
                        itemBuilder: (context, index) {
                          final tab = _adminTabs[index];
                          final selected = _selectedTab == index;
                          return ChoiceChip(
                            selected: selected,
                            label: Text(tab.label),
                            avatar: Icon(
                              tab.icon,
                              size: 16,
                              color: selected ? AppTheme.bodyHolicsOrange : AppTheme.textSecondary,
                            ),
                            onSelected: (_) => setState(() => _selectedTab = index),
                            selectedColor: AppTheme.bodyHolicsOrange.withOpacity(0.2),
                            backgroundColor: AppTheme.surfaceCard,
                            side: BorderSide(
                              color: selected
                                  ? AppTheme.bodyHolicsOrange
                                  : AppTheme.borderColor,
                            ),
                            labelStyle: TextStyle(
                              color: selected
                                  ? AppTheme.bodyHolicsOrange
                                  : AppTheme.textPrimary,
                              fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                            ),
                          );
                        },
                      ),
                    ),
                    const Divider(height: 1, color: AppTheme.borderColor),
                    Expanded(child: _AdminContent(tab: _selectedTab)),
                  ],
                ),
        ],
      ),
    );
  }
}

class _AdminSidebar extends StatelessWidget {
  final int selectedTab;
  final Function(int) onTabChanged;

  const _AdminSidebar({
    required this.selectedTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 16),
      children: [
        for (int i = 0; i < _adminTabs.length; i++)
          _SidebarItem(
            label: _adminTabs[i].label,
            icon: _adminTabs[i].icon,
            isSelected: selectedTab == i,
            onTap: () => onTabChanged(i),
          ),
      ],
    );
  }
}

class _SidebarItem extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.bodyHolicsOrange.withOpacity(0.2)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isSelected
                      ? AppTheme.bodyHolicsOrange
                      : AppTheme.textSecondary,
                ),
                const Gap(12),
                Expanded(
                  child: Text(
                    label,
                    style: TextStyle(
                      color: isSelected
                          ? AppTheme.bodyHolicsOrange
                          : AppTheme.textPrimary,
                      fontWeight:
                          isSelected ? FontWeight.w600 : FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AdminContent extends ConsumerWidget {
  final int tab;

  const _AdminContent({required this.tab});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Widget tabBody;
    switch (tab) {
      case 0:
        tabBody = const _DashboardOverview();
        break;
      case 1:
        tabBody = _MembersTab(ref: ref);
        break;
      case 2:
        tabBody = _SubscriptionsTab(ref: ref);
        break;
      case 3:
        tabBody = _AppointmentsTab(ref: ref);
        break;
      case 4:
        tabBody = _ServicesTab(ref: ref);
        break;
      case 5:
        tabBody = _SpecialistsTab(ref: ref);
        break;
      case 6:
        tabBody = _SettingsTab(ref: ref);
        break;
      default:
        tabBody = const SizedBox();
        break;
    }

    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 280),
      switchInCurve: Curves.easeOutCubic,
      switchOutCurve: Curves.easeInCubic,
      transitionBuilder: (child, animation) {
        final slide = Tween<Offset>(
          begin: const Offset(0.02, 0),
          end: Offset.zero,
        ).animate(animation);
        return FadeTransition(
          opacity: animation,
          child: SlideTransition(position: slide, child: child),
        );
      },
      child: KeyedSubtree(
        key: ValueKey<int>(tab),
        child: tabBody,
      ),
    );
  }
}

enum _DateRangeOption { weekly, monthly, yearly }

class _DashboardOverview extends ConsumerStatefulWidget {
  const _DashboardOverview();

  @override
  ConsumerState<_DashboardOverview> createState() => _DashboardOverviewState();
}

class _DashboardOverviewState extends ConsumerState<_DashboardOverview> {
  _DateRangeOption _selectedRange = _DateRangeOption.monthly;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isCompact = screenWidth < 700;

    final usersAsync = ref.watch(allUsersProvider);
    final subscriptionsAsync = ref.watch(allSubscriptionsProvider);
    final appointmentsAsync = ref.watch(allAppointmentsProvider);

    final users = usersAsync.maybeWhen(
      data: (value) => value,
      orElse: () => <User>[],
    );
    final subscriptions = subscriptionsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => <Subscription>[],
    );
    final appointments = appointmentsAsync.maybeWhen(
      data: (value) => value,
      orElse: () => <Appointment>[],
    );

    final now = DateTime.now();
    final filteredSubscriptions = subscriptions
        .where((s) => _isInRange(s.startDate, _selectedRange, now))
        .toList();
    final filteredAppointments = appointments
        .where((a) => _isInRange(a.createdAt, _selectedRange, now))
        .toList();

    final bodyRevenue = _bodyRevenue(filteredSubscriptions);
    final skinRevenue = _skinRevenue(filteredAppointments);
    final totalRevenue = bodyRevenue + skinRevenue;
    final bodyUsers = _bodyPanelUsers(filteredSubscriptions);
    final skinUsers = _skinPanelUsers(filteredAppointments);
    final trendData = _revenueTrendForRange(
      range: _selectedRange,
      now: now,
      subscriptions: subscriptions,
      appointments: appointments,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isCompact)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Dashboard Overview',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Gap(10),
                OutlinedButton.icon(
                  onPressed: () => _exportCsvReport(
                    users: users,
                    subscriptions: filteredSubscriptions,
                    appointments: filteredAppointments,
                    bodyRevenue: bodyRevenue,
                    skinRevenue: skinRevenue,
                    totalRevenue: totalRevenue,
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                ),
              ],
            )
          else
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Dashboard Overview',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _exportCsvReport(
                    users: users,
                    subscriptions: filteredSubscriptions,
                    appointments: filteredAppointments,
                    bodyRevenue: bodyRevenue,
                    skinRevenue: skinRevenue,
                    totalRevenue: totalRevenue,
                  ),
                  icon: const Icon(Icons.download),
                  label: const Text('Export CSV'),
                ),
              ],
            ),
          const Gap(14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _RangeChip(
                label: 'This Week',
                selected: _selectedRange == _DateRangeOption.weekly,
                onTap: () => setState(() => _selectedRange = _DateRangeOption.weekly),
              ),
              _RangeChip(
                label: 'This Month',
                selected: _selectedRange == _DateRangeOption.monthly,
                onTap: () => setState(() => _selectedRange = _DateRangeOption.monthly),
              ),
              _RangeChip(
                label: 'This Year',
                selected: _selectedRange == _DateRangeOption.yearly,
                onTap: () => setState(() => _selectedRange = _DateRangeOption.yearly),
              ),
            ],
          ),
          const Gap(24),

          // Stats grid (responsive to avoid overflow on mobile)
          LayoutBuilder(
            builder: (context, constraints) {
              final crossAxisCount = constraints.maxWidth >= 1200
                  ? 4
                  : constraints.maxWidth >= 700
                      ? 2
                      : 1;
              final childAspectRatio = crossAxisCount == 4
                  ? 1.5
                  : crossAxisCount == 2
                      ? 1.35
                    : 2.1;

              return GridView.count(
                crossAxisCount: crossAxisCount,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: childAspectRatio,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                children: [
                  _StatCard(
                    title: 'Members (All Time)',
                    value: users.length.toString(),
                    icon: Icons.people,
                    color: AppTheme.bodyHolicsOrange,
                  ),
                  _StatCard(
                    title: 'Body Users',
                    value: bodyUsers.toString(),
                    icon: Icons.fitness_center,
                    color: AppTheme.bodyHolicsOrange,
                  ),
                  _StatCard(
                    title: 'Skin Users',
                    value: skinUsers.toString(),
                    icon: Icons.spa,
                    color: AppTheme.skinHolichPink,
                  ),
                  _StatCard(
                    title: 'Revenue (${_rangeLabel(_selectedRange)})',
                    value: 'PKR ${totalRevenue.toStringAsFixed(0)}',
                    icon: Icons.trending_up,
                    color: AppTheme.successGreen,
                  ),
                ],
              );
            },
          ),
          const Gap(32),

          const Text(
            'Panel Insights',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const Gap(12),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 1100;

              if (isWide) {
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: _PanelUsersChart(
                        bodyUsers: bodyUsers,
                        skinUsers: skinUsers,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: _PanelRevenueChart(
                        bodyRevenue: bodyRevenue,
                        skinRevenue: skinRevenue,
                      ),
                    ),
                    const Gap(16),
                    Expanded(
                      child: _RevenueSharePieChart(
                        bodyRevenue: bodyRevenue,
                        skinRevenue: skinRevenue,
                      ),
                    ),
                  ],
                );
              }

              return Column(
                children: [
                  _PanelUsersChart(bodyUsers: bodyUsers, skinUsers: skinUsers),
                  const Gap(16),
                  _PanelRevenueChart(
                    bodyRevenue: bodyRevenue,
                    skinRevenue: skinRevenue,
                  ),
                  const Gap(16),
                  _RevenueSharePieChart(
                    bodyRevenue: bodyRevenue,
                    skinRevenue: skinRevenue,
                  ),
                ],
              );
            },
          ),
          const Gap(16),
          _MonthlyRevenueTrendChart(
            data: trendData,
            title: _trendTitle(_selectedRange),
          ),
          const Gap(32),

          // Tables
          const Text(
            'Recent Appointments',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
          const Gap(12),
          appointmentsAsync.when(
            data: (appointments) => appointments.isEmpty
                ? const EmptyStateWidget(
                    title: 'No Appointments',
                    subtitle: 'No bookings yet',
                    icon: Icons.calendar_today,
                  )
                : HolicsCard(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        columns: const [
                          DataColumn(
                              label: Text('Service',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600))),
                          DataColumn(
                              label: Text('Date',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600))),
                          DataColumn(
                              label: Text('Status',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600))),
                        ],
                        rows: appointments.take(5).map((apt) {
                          return DataRow(cells: [
                            DataCell(Text(apt.service)),
                            DataCell(Text(
                                '${apt.date.day}/${apt.date.month}/${apt.date.year}')),
                            DataCell(Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: apt.status == 'approved' || apt.status == 'confirmed'
                                    ? AppTheme.successGreen.withOpacity(0.2)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                apt.status,
                                style: TextStyle(
                                  color: apt.status == 'approved' || apt.status == 'confirmed'
                                      ? AppTheme.successGreen
                                      : AppTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            )),
                          ]);
                        }).toList(),
                      ),
                    ),
                  ),
            loading: () => ShimmerCardLoader(),
            error: (error, stack) =>
                ErrorStateWidget(message: error.toString(), onRetry: () {}),
          ),
        ],
      ),
    );
  }

  double _bodyRevenue(List<Subscription> subscriptions) {
    return subscriptions.fold<double>(0, (sum, s) => sum + (s.price ?? 0));
  }

  double _skinRevenue(List<Appointment> appointments) {
    return appointments
        .where((a) => _isRevenueEligibleAppointment(a))
        .fold<double>(0, (sum, a) => sum + a.price);
  }

  bool _isRevenueEligibleAppointment(Appointment appointment) {
    final status = appointment.status.toLowerCase();
    return status == 'approved' || status == 'confirmed' || status == 'completed';
  }

  int _bodyPanelUsers(List<Subscription> subscriptions) {
    return subscriptions
        .where((s) => s.isActive)
        .map((s) => s.userId)
        .toSet()
        .length;
  }

  int _skinPanelUsers(List<Appointment> appointments) {
    return appointments
        .where((a) => a.status != 'cancelled')
        .map((a) => a.userId)
        .toSet()
        .length;
  }

  bool _isInRange(DateTime date, _DateRangeOption range, DateTime now) {
    switch (range) {
      case _DateRangeOption.weekly:
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        final endOfWeek = startOfWeek.add(const Duration(days: 7));
        return !date.isBefore(startOfWeek) && date.isBefore(endOfWeek);
      case _DateRangeOption.monthly:
        return date.year == now.year && date.month == now.month;
      case _DateRangeOption.yearly:
        return date.year == now.year;
    }
  }

  String _rangeLabel(_DateRangeOption range) {
    switch (range) {
      case _DateRangeOption.weekly:
        return 'Week';
      case _DateRangeOption.monthly:
        return 'Month';
      case _DateRangeOption.yearly:
        return 'Year';
    }
  }

  String _trendTitle(_DateRangeOption range) {
    switch (range) {
      case _DateRangeOption.weekly:
        return 'Revenue Trend (This Week)';
      case _DateRangeOption.monthly:
        return 'Revenue Trend (This Month)';
      case _DateRangeOption.yearly:
        return 'Revenue Trend (This Year)';
    }
  }

  List<_MonthlyRevenuePoint> _revenueTrendForRange({
    required _DateRangeOption range,
    required DateTime now,
    required List<Subscription> subscriptions,
    required List<Appointment> appointments,
  }) {
    switch (range) {
      case _DateRangeOption.weekly:
        final startOfWeek = DateTime(now.year, now.month, now.day)
            .subtract(Duration(days: now.weekday - 1));
        const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        return List.generate(7, (index) {
          final day = startOfWeek.add(Duration(days: index));
          final body = subscriptions
              .where(
                (s) =>
                    s.startDate.year == day.year &&
                    s.startDate.month == day.month &&
                    s.startDate.day == day.day,
              )
              .fold<double>(0, (sum, s) => sum + (s.price ?? 0));
          final skin = appointments
              .where(
                (a) =>
                    a.createdAt.year == day.year &&
                    a.createdAt.month == day.month &&
                    a.createdAt.day == day.day &&
                    _isRevenueEligibleAppointment(a),
              )
              .fold<double>(0, (sum, a) => sum + a.price);
          return _MonthlyRevenuePoint(
            label: weekdayLabels[index],
            bodyRevenue: body,
            skinRevenue: skin,
          );
        });
      case _DateRangeOption.monthly:
        final monthStart = DateTime(now.year, now.month, 1);
        final monthEnd = DateTime(now.year, now.month + 1, 1);
        final daysInMonth = monthEnd.difference(monthStart).inDays;
        final weekCount = (daysInMonth / 7).ceil();

        return List.generate(weekCount, (index) {
          final weekStart = monthStart.add(Duration(days: index * 7));
          final weekEnd = weekStart.add(const Duration(days: 7));

          final body = subscriptions
              .where(
                (s) =>
                    !s.startDate.isBefore(weekStart) &&
                    s.startDate.isBefore(weekEnd) &&
                    s.startDate.month == now.month &&
                    s.startDate.year == now.year,
              )
              .fold<double>(0, (sum, s) => sum + (s.price ?? 0));

          final skin = appointments
              .where(
                (a) =>
                    !a.createdAt.isBefore(weekStart) &&
                    a.createdAt.isBefore(weekEnd) &&
                    a.createdAt.month == now.month &&
                    a.createdAt.year == now.year &&
                    _isRevenueEligibleAppointment(a),
              )
              .fold<double>(0, (sum, a) => sum + a.price);

          return _MonthlyRevenuePoint(
            label: 'W${index + 1}',
            bodyRevenue: body,
            skinRevenue: skin,
          );
        });
      case _DateRangeOption.yearly:
        return List.generate(12, (index) {
          final monthDate = DateTime(now.year, index + 1, 1);

          final body = subscriptions
              .where(
                (s) => s.startDate.month == monthDate.month && s.startDate.year == now.year,
              )
              .fold<double>(0, (sum, s) => sum + (s.price ?? 0));

          final skin = appointments
              .where(
                (a) =>
                    a.createdAt.month == monthDate.month &&
                    a.createdAt.year == now.year &&
                    _isRevenueEligibleAppointment(a),
              )
              .fold<double>(0, (sum, a) => sum + a.price);

          return _MonthlyRevenuePoint(
            label: _monthShort(monthDate.month),
            bodyRevenue: body,
            skinRevenue: skin,
          );
        });
    }
  }

  Future<void> _exportCsvReport({
    required List<User> users,
    required List<Subscription> subscriptions,
    required List<Appointment> appointments,
    required double bodyRevenue,
    required double skinRevenue,
    required double totalRevenue,
  }) async {
    final now = DateTime.now();
    final fileName =
        'holics_report_${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}_${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}.csv';

    final csv = StringBuffer()
      ..writeln('report,range,value')
      ..writeln('members,all_time,${users.length}')
      ..writeln('body_users,filtered,${_bodyPanelUsers(subscriptions)}')
      ..writeln('skin_users,filtered,${_skinPanelUsers(appointments)}')
      ..writeln('body_revenue,filtered,${bodyRevenue.toStringAsFixed(2)}')
      ..writeln('skin_revenue,filtered,${skinRevenue.toStringAsFixed(2)}')
      ..writeln('total_revenue,filtered,${totalRevenue.toStringAsFixed(2)}');

    try {
      if (kIsWeb) {
        await Share.share(
          csv.toString(),
          subject: fileName,
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final file = File('${tempDir.path}/$fileName');
        await file.writeAsString(csv.toString());

        await Share.shareXFiles(
          [XFile(file.path)],
          subject: 'The Holics Admin Report',
          text: 'Admin analytics export (${_rangeLabel(_selectedRange)})',
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('CSV report ready to save/share')),
        );
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: csv.toString()));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not create file. CSV copied to clipboard instead.')),
        );
      }
    }
  }

  String _monthShort(int month) {
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return months[month - 1];
  }
}

class _PanelUsersChart extends StatelessWidget {
  final int bodyUsers;
  final int skinUsers;

  const _PanelUsersChart({
    required this.bodyUsers,
    required this.skinUsers,
  });

  @override
  Widget build(BuildContext context) {
    final maxY = math.max(bodyUsers, skinUsers).toDouble() + 2;

    return HolicsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Users By Panel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Gap(4),
          const Text(
            'Active users in Body and Skin panels',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const Gap(16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 2,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.borderColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 2,
                      reservedSize: 32,
                      getTitlesWidget: (value, _) => Text(
                        value.toInt().toString(),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final title = value.toInt() == 0 ? 'Body' : 'Skin';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: bodyUsers.toDouble(),
                        color: AppTheme.bodyHolicsOrange,
                        width: 22,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: skinUsers.toDouble(),
                        color: AppTheme.skinHolichPink,
                        width: 22,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PanelRevenueChart extends StatelessWidget {
  final double bodyRevenue;
  final double skinRevenue;

  const _PanelRevenueChart({
    required this.bodyRevenue,
    required this.skinRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final maxY =
        math.max(math.max(bodyRevenue, skinRevenue) + 50000, 400000).toDouble();
    final yInterval = _chartAxisInterval(maxY);

    return HolicsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue By Panel',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Gap(4),
          const Text(
            'Separate earnings from Body and Skin',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const Gap(16),
          SizedBox(
            height: 220,
            child: BarChart(
              BarChartData(
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.borderColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      reservedSize: 60,
                      getTitlesWidget: (value, _) => Text(
                        _formatPkrAxisLabel(value),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, _) {
                        final title = value.toInt() == 0 ? 'Body' : 'Skin';
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            title,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                barGroups: [
                  BarChartGroupData(
                    x: 0,
                    barRods: [
                      BarChartRodData(
                        toY: bodyRevenue,
                        color: AppTheme.bodyHolicsOrange,
                        width: 22,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                  BarChartGroupData(
                    x: 1,
                    barRods: [
                      BarChartRodData(
                        toY: skinRevenue,
                        color: AppTheme.skinHolichPink,
                        width: 22,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Gap(10),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Body: PKR ${bodyRevenue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    color: AppTheme.bodyHolicsOrange,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Skin: PKR ${skinRevenue.toStringAsFixed(0)}',
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    color: AppTheme.skinHolichPink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RangeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.bodyHolicsOrange.withOpacity(0.18)
              : AppTheme.surfaceCard,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.bodyHolicsOrange : AppTheme.borderColor,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: selected ? AppTheme.bodyHolicsOrange : AppTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _RevenueSharePieChart extends StatelessWidget {
  final double bodyRevenue;
  final double skinRevenue;

  const _RevenueSharePieChart({
    required this.bodyRevenue,
    required this.skinRevenue,
  });

  @override
  Widget build(BuildContext context) {
    final total = bodyRevenue + skinRevenue;
    final bodyPercent = total <= 0 ? 0.0 : (bodyRevenue / total) * 100;
    final skinPercent = total <= 0 ? 0.0 : (skinRevenue / total) * 100;

    return HolicsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revenue Share %',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Gap(4),
          const Text(
            'Distribution between Body and Skin',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const Gap(16),
          SizedBox(
            height: 220,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 42,
                sectionsSpace: 2,
                sections: [
                  PieChartSectionData(
                    value: bodyRevenue <= 0 ? 0.1 : bodyRevenue,
                    color: AppTheme.bodyHolicsOrange,
                    title: '${bodyPercent.toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  PieChartSectionData(
                    value: skinRevenue <= 0 ? 0.1 : skinRevenue,
                    color: AppTheme.skinHolichPink,
                    title: '${skinPercent.toStringAsFixed(1)}%',
                    radius: 60,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Gap(8),
          const Row(
            children: [
              Icon(Icons.circle, size: 10, color: AppTheme.bodyHolicsOrange),
              Gap(6),
              Text(
                'Body',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Gap(14),
              Icon(Icons.circle, size: 10, color: AppTheme.skinHolichPink),
              Gap(6),
              Text(
                'Skin',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyRevenueTrendChart extends StatelessWidget {
  final List<_MonthlyRevenuePoint> data;
  final String title;

  const _MonthlyRevenueTrendChart({required this.data, required this.title});

  @override
  Widget build(BuildContext context) {
    final maxValue = data
        .map((point) => math.max(point.bodyRevenue, point.skinRevenue))
        .fold<double>(0, (prev, element) => math.max(prev, element));
    final double maxY = math.max(maxValue + 50000, 500000).toDouble();
    final yInterval = _chartAxisInterval(maxY);

    return HolicsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Gap(4),
          const Text(
            'Body vs Skin monthly earnings',
            style: TextStyle(
              fontSize: 12,
              color: AppTheme.textSecondary,
            ),
          ),
          const Gap(16),
          SizedBox(
            height: 240,
            child: LineChart(
              LineChartData(
                minY: 0,
                maxY: maxY,
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: yInterval,
                  getDrawingHorizontalLine: (_) => FlLine(
                    color: AppTheme.borderColor,
                    strokeWidth: 1,
                  ),
                ),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: yInterval,
                      reservedSize: 60,
                      getTitlesWidget: (value, _) => Text(
                        _formatPkrAxisLabel(value),
                        style: const TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      interval: 1,
                      getTitlesWidget: (value, _) {
                        if (value % 1 != 0) {
                          return const SizedBox.shrink();
                        }
                        final index = value.toInt();
                        if (index < 0 || index >= data.length) {
                          return const SizedBox.shrink();
                        }
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            data[index].label,
                            style: const TextStyle(
                              color: AppTheme.textSecondary,
                              fontSize: 11,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    spots: data
                        .asMap()
                        .entries
                        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.bodyRevenue))
                        .toList(),
                    isCurved: true,
                    color: AppTheme.bodyHolicsOrange,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                  LineChartBarData(
                    spots: data
                        .asMap()
                        .entries
                        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.skinRevenue))
                        .toList(),
                    isCurved: true,
                    color: AppTheme.skinHolichPink,
                    barWidth: 3,
                    dotData: const FlDotData(show: true),
                  ),
                ],
              ),
            ),
          ),
          const Gap(10),
          const Row(
            children: [
              Icon(Icons.circle, size: 10, color: AppTheme.bodyHolicsOrange),
              Gap(6),
              Text(
                'Body Revenue',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
              Gap(16),
              Icon(Icons.circle, size: 10, color: AppTheme.skinHolichPink),
              Gap(6),
              Text(
                'Skin Revenue',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MonthlyRevenuePoint {
  final String label;
  final double bodyRevenue;
  final double skinRevenue;

  const _MonthlyRevenuePoint({
    required this.label,
    required this.bodyRevenue,
    required this.skinRevenue,
  });
}

double _chartAxisInterval(double maxY) {
  if (maxY >= 500000) return 100000;
  if (maxY >= 200000) return 50000;
  if (maxY >= 100000) return 20000;
  if (maxY >= 50000) return 10000;
  final rough = maxY / 4;
  const steps = <double>[10, 20, 50, 100, 200, 500, 1000, 2000, 5000, 10000];
  for (final step in steps) {
    if (rough <= step) return step;
  }
  return 20000;
}

String _formatPkrAxisLabel(double value) {
  if (value >= 1000) {
    final thousands = value / 1000;
    final decimals = value % 1000 == 0 ? 0 : 1;
    return 'PKR ${thousands.toStringAsFixed(decimals)}k';
  }
  return 'PKR ${value.toInt()}';
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 700;

    return HolicsCard(
      padding: EdgeInsets.symmetric(
        horizontal: isNarrow ? 12 : 16,
        vertical: isNarrow ? 10 : 16,
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: isNarrow ? 24 : 32),
            Gap(isNarrow ? 6 : 8),
            Text(
              title,
              style: TextStyle(
                fontSize: isNarrow ? 11 : 12,
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Gap(isNarrow ? 2 : 4),
            Text(
              value,
              style: TextStyle(
                fontSize: isNarrow ? 18 : 20,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersTab extends ConsumerWidget {
  final WidgetRef ref;

  const _MembersTab({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    IconData iconForMetric(String title) {
      switch (title.toLowerCase()) {
        case 'total members':
          return Icons.groups_rounded;
        case 'monthly':
          return Icons.calendar_view_month_rounded;
        case 'quarterly':
          return Icons.calendar_view_week_rounded;
        case 'yearly':
          return Icons.event_available_rounded;
        default:
          return Icons.bar_chart_rounded;
      }
    }

    final usersAsync = ref.watch(allUsersProvider);
    final subscriptionsAsync = ref.watch(allSubscriptionsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
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
                colors: [Color(0xFF1B1B1B), Color(0xFF141414)],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.bodyHolicsOrange.withValues(alpha: 0.22),
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Members Management',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Gap(6),
                Text(
                  'Track active members and subscription distribution at a glance.',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Gap(18),
          usersAsync.when(
            data: (users) => subscriptionsAsync.when(
              data: (subscriptions) {
                final activeSubscriptions = subscriptions
                    .where((subscription) => subscription.isActive)
                    .toList();
                final activeSubscriptionUserIds =
                  activeSubscriptions.map((subscription) => subscription.userId).toSet();
                final monthlyCount = activeSubscriptions
                    .where((subscription) =>
                        subscription.plan.toLowerCase() == 'monthly')
                    .length;
                final quarterlyCount = activeSubscriptions
                    .where((subscription) =>
                        subscription.plan.toLowerCase() == 'quarterly')
                    .length;
                final yearlyCount = activeSubscriptions
                    .where((subscription) =>
                        subscription.plan.toLowerCase() == 'yearly')
                    .length;

                return Column(
                  children: [
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isMobile = constraints.maxWidth < 900;

                        return Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            SizedBox(
                              width: isMobile
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 36) / 4,
                              child: _MembersMetricCard(
                                title: 'Total Members',
                                value: users.length.toString(),
                                accentColor: AppTheme.bodyHolicsOrange,
                                icon: iconForMetric('Total Members'),
                              ),
                            ),
                            SizedBox(
                              width: isMobile
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 36) / 4,
                              child: _MembersMetricCard(
                                title: 'Monthly',
                                value: monthlyCount.toString(),
                                accentColor: AppTheme.successGreen,
                                icon: iconForMetric('Monthly'),
                              ),
                            ),
                            SizedBox(
                              width: isMobile
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 36) / 4,
                              child: _MembersMetricCard(
                                title: 'Quarterly',
                                value: quarterlyCount.toString(),
                                accentColor: AppTheme.skinHolichPink,
                                icon: iconForMetric('Quarterly'),
                              ),
                            ),
                            SizedBox(
                              width: isMobile
                                  ? constraints.maxWidth
                                  : (constraints.maxWidth - 36) / 4,
                              child: _MembersMetricCard(
                                title: 'Yearly',
                                value: yearlyCount.toString(),
                                accentColor: AppTheme.warningYellow,
                                icon: iconForMetric('Yearly'),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const Gap(16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceCard,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.borderColor),
                      ),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Theme(
                          data: Theme.of(context).copyWith(
                            dividerColor: AppTheme.borderColor,
                            dataTableTheme: DataTableThemeData(
                              headingRowColor: WidgetStateProperty.all(
                                const Color(0xFF232323),
                              ),
                              dataRowMinHeight: 58,
                              dataRowMaxHeight: 58,
                              headingTextStyle: const TextStyle(
                                color: AppTheme.textPrimary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          child: DataTable(
                            headingRowHeight: 52,
                            columnSpacing: 36,
                            columns: const [
                              DataColumn(label: Text('Name')),
                              DataColumn(label: Text('Email')),
                              DataColumn(label: Text('Phone')),
                              DataColumn(label: Text('Role')),
                              DataColumn(label: Text('Status')),
                            ],
                            rows: users.asMap().entries.map((entry) {
                              final index = entry.key;
                              final user = entry.value;
                              final hasActiveGymSubscription =
                                  activeSubscriptionUserIds.contains(user.id);

                              return DataRow(
                                color: WidgetStateProperty.all(
                                  index.isEven
                                      ? Colors.white.withValues(alpha: 0.01)
                                      : Colors.transparent,
                                ),
                                cells: [
                                  DataCell(
                                    Text(
                                      user.name,
                                      style: const TextStyle(
                                        color: AppTheme.textPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      user.email,
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Text(
                                      (user.phoneNumber?.trim().isNotEmpty ?? false)
                                          ? user.phoneNumber!
                                          : '-',
                                      style: const TextStyle(
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.borderColor,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        user.role,
                                        style: const TextStyle(
                                          color: AppTheme.textPrimary,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 10, vertical: 5),
                                      decoration: BoxDecoration(
                                        color: hasActiveGymSubscription
                                            ? AppTheme.successGreen.withValues(alpha: 0.14)
                                            : AppTheme.errorRed.withValues(alpha: 0.14),
                                        borderRadius: BorderRadius.circular(999),
                                        border: Border.all(
                                          color: hasActiveGymSubscription
                                              ? AppTheme.successGreen.withValues(alpha: 0.28)
                                              : AppTheme.errorRed.withValues(alpha: 0.28),
                                        ),
                                      ),
                                      child: Text(
                                        hasActiveGymSubscription ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          color: hasActiveGymSubscription
                                              ? AppTheme.successGreen
                                              : AppTheme.errorRed,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
              loading: () => ShimmerCardLoader(),
              error: (error, stack) =>
                  ErrorStateWidget(message: error.toString(), onRetry: () {}),
            ),
            loading: () => ShimmerCardLoader(),
            error: (error, stack) =>
                ErrorStateWidget(message: error.toString(), onRetry: () {}),
          ),
        ],
      ),
    );
  }
}

class _MembersMetricCard extends StatelessWidget {
  final String title;
  final String value;
  final Color accentColor;
  final IconData icon;

  const _MembersMetricCard({
    required this.title,
    required this.value,
    required this.accentColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1D1D1D), Color(0xFF171717)],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.borderColor),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: AppTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const Gap(8),
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: accentColor),
              ),
            ],
          ),
          const Gap(10),
          Text(
            value,
            style: TextStyle(
              color: accentColor,
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionsTab extends ConsumerWidget {
  final WidgetRef ref;

  const _SubscriptionsTab({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subsAsync = ref.watch(allSubscriptionsProvider);
    final firestoreService = ref.read(firestoreServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Gym Subscription Requests',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Gap(8),
            const Text('Members with pending gym membership requests',
              style: TextStyle(fontSize: 14, color: AppTheme.textSecondary)),
          const Gap(16),

          // Subscription Requests Stream
          StreamBuilder<List<Map<String, dynamic>>>(
            stream: firestoreService.subscriptionRequestsStream(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return ShimmerCardLoader();
              }

              if (snapshot.hasError) {
                return ErrorStateWidget(
                  message: snapshot.error.toString(),
                  onRetry: () {},
                );
              }

              if (!snapshot.hasData || snapshot.data!.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No pending subscription requests'),
                  ),
                );
              }

              final requests = snapshot.data!;

              return Column(
                children: requests.map((req) {
                  final id = req['id'] as String;
                  final data = req['data'] as Map<String, dynamic>;
                  final userName = data['userName'] ?? 'Unknown';
                  final plan = data['planSelected'] ?? 'N/A';
                  final status = data['status'] ?? 'pending';
                  final personalInfo = data['personalInfo'] as Map<String, dynamic>?;
                  final paymentProof = (data['paymentProof'] ??
                          data['paymentProofUrl'] ??
                          data['paymentProofPath'])
                      ?.toString();
                  final selectedPrice = (data['selectedPrice'] as num?)?.toDouble();
                  final registrationFee = (data['registrationFee'] as num?)?.toDouble();
                  final totalAmount = (data['totalAmount'] as num?)?.toDouble();
                  final requiresRegistrationFee =
                      data['requiresRegistrationFee'] as bool? ??
                          (registrationFee ?? 0) > 0;
                  final createdAt = data['createdAt'] as dynamic;

                  String createdDate = 'N/A';
                  if (createdAt != null) {
                    try {
                      final dt = (createdAt as dynamic).toDate();
                      createdDate = '${dt.day}/${dt.month}/${dt.year}';
                    } catch (e) {
                      createdDate = 'N/A';
                    }
                  }

                  return HolicsCard(
                    child: ExpansionTile(
                      title: Text(
                        userName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      subtitle: Text('Plan: $plan | Status: $status'),
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Personal Info
                              const Text(
                                'Personal Information',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Gap(8),
                              _InfoRow('Full Name', personalInfo?['fullName'] ?? 'N/A'),
                              _InfoRow('Age', '${personalInfo?['age'] ?? 'N/A'}'),
                              _InfoRow('Phone', personalInfo?['phone'] ?? 'N/A'),
                              _InfoRow('Address', personalInfo?['address'] ?? 'N/A'),
                              _InfoRow('Emergency Contact',
                                  personalInfo?['emergencyContact'] ?? 'N/A'),
                              _InfoRow(
                                  'Fitness Goals', personalInfo?['fitnessGoals'] ?? 'N/A'),
                              const Gap(16),

                              // Payment Proof
                              const Text(
                                'Payment Proof',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Gap(8),
                              if (paymentProof == null || paymentProof.isEmpty)
                                const Text(
                                  'No payment proof uploaded',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                )
                              else ...[
                                if (paymentProof.startsWith('http://') ||
                                    paymentProof.startsWith('https://'))
                                  GestureDetector(
                                    onTap: () {
                                      showDialog(
                                        context: context,
                                        builder: (_) => Dialog(
                                          backgroundColor: Colors.black,
                                          insetPadding: const EdgeInsets.all(16),
                                          child: Stack(
                                            children: [
                                              InteractiveViewer(
                                                minScale: 0.5,
                                                maxScale: 4,
                                                child: Center(
                                                  child: Image.network(
                                                    paymentProof,
                                                    fit: BoxFit.contain,
                                                    errorBuilder: (_, __, ___) => const Padding(
                                                      padding: EdgeInsets.all(20),
                                                      child: Text(
                                                        'Unable to load proof image',
                                                        style: TextStyle(
                                                          color: AppTheme.textSecondary,
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              Positioned(
                                                top: 8,
                                                right: 8,
                                                child: IconButton(
                                                  icon: const Icon(
                                                    Icons.close,
                                                    color: Colors.white,
                                                  ),
                                                  onPressed: () => Navigator.pop(context),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Container(
                                        color: Colors.black,
                                        width: double.infinity,
                                        height: 220,
                                        child: Image.network(
                                          paymentProof,
                                          fit: BoxFit.contain,
                                          errorBuilder: (_, __, ___) => const Center(
                                            child: Text(
                                              'Unable to load proof image',
                                              style: TextStyle(
                                                color: AppTheme.textSecondary,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                else
                                  Text(
                                    paymentProof,
                                    style: const TextStyle(
                                        color: AppTheme.textSecondary),
                                  ),
                                if (paymentProof.startsWith('http://') ||
                                    paymentProof.startsWith('https://'))
                                  const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Tap image to view full size',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                              ],
                              const Gap(16),

                              // Plan & Status
                              const Text(
                                'Subscription Details',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                              const Gap(8),
                              _InfoRow('Plan Selected', plan),
                              _InfoRow(
                                'Plan Amount',
                                selectedPrice == null
                                    ? 'N/A'
                                    : 'PKR ${selectedPrice.toStringAsFixed(0)}',
                              ),
                              _InfoRow(
                                'Registration Fee',
                                requiresRegistrationFee
                                    ? 'PKR ${(registrationFee ?? 0).toStringAsFixed(0)}'
                                    : 'Already paid',
                              ),
                              _InfoRow(
                                'Total Amount',
                                totalAmount == null
                                    ? 'N/A'
                                    : 'PKR ${totalAmount.toStringAsFixed(0)}',
                              ),
                              _InfoRow('Request Date', createdDate),
                              _InfoRow(
                                'Current Status',
                                status.toUpperCase(),
                                statusColor: status == 'active'
                                    ? Colors.green
                                  : status == 'inactive'
                                        ? Colors.red
                                        : AppTheme.bodyHolicsOrange,
                              ),
                              const Gap(16),

                              // Action Buttons
                              if (status == 'pending')
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          await firestoreService
                                              .approveSubscriptionRequest(id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content: Text(
                                                    'Subscription activated!'),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.check),
                                        label: const Text('Approve'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.green,
                                        ),
                                      ),
                                    ),
                                    const Gap(8),
                                    Expanded(
                                      child: ElevatedButton.icon(
                                        onPressed: () async {
                                          await firestoreService
                                              .rejectSubscriptionRequest(id);
                                          if (context.mounted) {
                                            ScaffoldMessenger.of(context)
                                                .showSnackBar(
                                              const SnackBar(
                                                content:
                                                    Text('Subscription marked inactive'),
                                              ),
                                            );
                                          }
                                        },
                                        icon: const Icon(Icons.close),
                                        label: const Text('Reject'),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? statusColor;

  const _InfoRow(this.label, this.value, {this.statusColor});

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
              color: AppTheme.textSecondary,
              fontSize: 12,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: statusColor ?? AppTheme.textPrimary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AppointmentsTab extends ConsumerWidget {
  final WidgetRef ref;

  const _AppointmentsTab({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final aptsAsync = ref.watch(allAppointmentsProvider);
    final usersAsync = ref.watch(allUsersProvider);
    final specialistsAsync = ref.watch(specialistsProvider);
    final firestoreService = ref.read(firestoreServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Appointments Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Gap(16),
          aptsAsync.when(
            data: (apts) {
              final upcomingAppointments = apts.where((apt) => apt.isUpcoming && apt.status.trim().toLowerCase() == 'approved').toList();

              return usersAsync.when(
              data: (users) => specialistsAsync.when(
                data: (specialists) {
                  upcomingAppointments.sort((a, b) => a.date.compareTo(b.date));

                  final userById = {
                    for (final user in users) user.id: user,
                  };
                  final specialistById = {
                    for (final specialist in specialists) specialist.id: specialist,
                  };

                  String resolveUserName(Appointment apt) {
                    if (apt.userName != null && apt.userName!.trim().isNotEmpty) {
                      return apt.userName!.trim();
                    }
                    final user = userById[apt.userId];
                    return user?.name.isNotEmpty == true ? user!.name : apt.userId;
                  }

                  String resolveSpecialistName(Appointment apt) {
                    final specialist = specialistById[apt.specialistId];
                    if (specialist == null) return apt.specialistId;
                    if (specialist.title.trim().isNotEmpty) {
                      return specialist.title.trim();
                    }
                    return specialist.name;
                  }

                  String formatDate(DateTime date) {
                    return '${date.day}/${date.month}/${date.year}';
                  }

                  Widget buildPaymentProofWidget(String? paymentProof) {
                    if (paymentProof == null || paymentProof.isEmpty) {
                      return const Text(
                        'No payment proof uploaded',
                        style: TextStyle(color: AppTheme.textSecondary),
                      );
                    }

                    if (paymentProof.startsWith('http://') ||
                        paymentProof.startsWith('https://')) {
                      return GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => Dialog(
                              backgroundColor: Colors.black,
                              insetPadding: const EdgeInsets.all(16),
                              child: Stack(
                                children: [
                                  InteractiveViewer(
                                    minScale: 0.5,
                                    maxScale: 4,
                                    child: Center(
                                      child: Image.network(
                                        paymentProof,
                                        fit: BoxFit.contain,
                                        errorBuilder: (_, __, ___) => const Padding(
                                          padding: EdgeInsets.all(20),
                                          child: Text(
                                            'Unable to load proof image',
                                            style: TextStyle(
                                              color: AppTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.close,
                                        color: Colors.white,
                                      ),
                                      onPressed: () => Navigator.pop(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            color: Colors.black,
                            width: double.infinity,
                            height: 220,
                            child: Image.network(
                              paymentProof,
                              fit: BoxFit.contain,
                              errorBuilder: (_, __, ___) => const Center(
                                child: Text(
                                  'Unable to load proof image',
                                  style: TextStyle(color: AppTheme.textSecondary),
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }

                    return Text(
                      paymentProof,
                      style: const TextStyle(color: AppTheme.textSecondary),
                    );
                  }

                  Widget buildAppointmentRequestCard(Appointment apt) {
                    final paymentProof = apt.paymentProofUrl?.trim();
                    final requestDate = formatDate(apt.createdAt);
                    final status = apt.status.trim().toLowerCase();

                    return HolicsCard(
                      child: ExpansionTile(
                        title: Text(
                          resolveUserName(apt),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        subtitle: Text(
                          'Service: ${apt.service} | Status: ${apt.status}',
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Appointment Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const Gap(8),
                                _InfoRow('Service', apt.service),
                                _InfoRow('Specialist', resolveSpecialistName(apt)),
                                _InfoRow('Date', formatDate(apt.date)),
                                _InfoRow('Time', apt.time),
                                _InfoRow('Duration', '${apt.durationMin} min'),
                                _InfoRow('Price', 'PKR ${apt.price.toStringAsFixed(0)}'),
                                const Gap(16),
                                const Text(
                                  'Payment Details',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const Gap(8),
                                _InfoRow(
                                  'Payment Method',
                                  apt.paymentMethod == 'manual'
                                      ? 'Pay Now (Manual)'
                                      : apt.paymentMethod == 'pay_physical'
                                          ? 'Pay Physical'
                                          : '-',
                                ),
                                _InfoRow(
                                  'Payment Status',
                                  apt.paymentStatus ?? '-',
                                ),
                                const Gap(8),
                                buildPaymentProofWidget(paymentProof),
                                if (paymentProof != null && paymentProof.isNotEmpty &&
                                    (paymentProof.startsWith('http://') ||
                                        paymentProof.startsWith('https://')))
                                  const Padding(
                                    padding: EdgeInsets.only(top: 6),
                                    child: Text(
                                      'Tap image to view full size',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: AppTheme.textSecondary,
                                      ),
                                    ),
                                  ),
                                const Gap(16),
                                const Text(
                                  'Request Info',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppTheme.textPrimary,
                                  ),
                                ),
                                const Gap(8),
                                _InfoRow('Request Date', requestDate),
                                _InfoRow(
                                  'Current Status',
                                  apt.status.toUpperCase(),
                                  statusColor: status == 'approved'
                                      ? Colors.green
                                      : status == 'cancelled'
                                          ? Colors.red
                                          : AppTheme.bodyHolicsOrange,
                                ),
                                const Gap(16),
                                if (status == 'pending')
                                  Row(
                                    children: [
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            try {
                                              await firestoreService
                                                  .updateAppointment(
                                                apt.userId,
                                                apt.id,
                                                {
                                                  'status': 'approved',
                                                },
                                              );
                                              ref.invalidate(
                                                allAppointmentsProvider,
                                              );
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Appointment approved',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Failed to approve: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.check),
                                          label: const Text('Approve'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                          ),
                                        ),
                                      ),
                                      const Gap(8),
                                      Expanded(
                                        child: ElevatedButton.icon(
                                          onPressed: () async {
                                            try {
                                              await firestoreService
                                                  .updateAppointment(
                                                apt.userId,
                                                apt.id,
                                                {
                                                  'status': 'cancelled',
                                                },
                                              );
                                              ref.invalidate(
                                                allAppointmentsProvider,
                                              );
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Appointment rejected',
                                                  ),
                                                ),
                                              );
                                            } catch (e) {
                                              if (!context.mounted) return;
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                  content: Text(
                                                    'Failed to reject: $e',
                                                  ),
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.close),
                                          label: const Text('Reject'),
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  Widget buildAppointmentsTable(List<Appointment> items) {
                    if (items.isEmpty) {
                      return const EmptyStateWidget(
                        title: 'No appointments',
                        subtitle: 'No records available for this section',
                        icon: Icons.calendar_today,
                      );
                    }

                    return HolicsCard(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: DataTable(
                          columns: const [
                            DataColumn(label: Text('User')),
                            DataColumn(label: Text('Service')),
                            DataColumn(label: Text('Date & Time')),
                            DataColumn(label: Text('Specialist')),
                            DataColumn(label: Text('Phone')),
                          ],
                          rows: items.map((apt) {
                            final user = userById[apt.userId];
                            final phone = user?.phoneNumber ?? '-';

                            return DataRow(
                              cells: [
                                DataCell(Text(resolveUserName(apt))),
                                DataCell(Text(apt.service)),
                                DataCell(Text(
                                    '${apt.date.day}/${apt.date.month}/${apt.date.year} ${apt.time}')),
                                DataCell(Text(resolveSpecialistName(apt))),
                                DataCell(Text(phone)),
                              ],
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  }

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Appointment Requests',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Gap(8),
                      const Text(
                        'Patients with pending appointment requests',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Gap(12),
                      StreamBuilder<List<Appointment>>(
                        stream: firestoreService.appointmentRequestsStream(),
                        builder: (context, requestSnapshot) {
                          if (requestSnapshot.connectionState == ConnectionState.waiting) {
                            return const ShimmerCardLoader();
                          }

                          if (requestSnapshot.hasError) {
                            return ErrorStateWidget(
                              message: requestSnapshot.error.toString(),
                              onRetry: () {},
                            );
                          }

                          final requests = requestSnapshot.data ?? <Appointment>[];
                          if (requests.isEmpty) {
                            return const Center(
                              child: Padding(
                                padding: EdgeInsets.all(24),
                                child: Text('No pending appointment requests'),
                              ),
                            );
                          }

                          return Column(
                            children: requests.map(buildAppointmentRequestCard).toList(),
                          );
                        },
                      ),
                      const Gap(20),
                      const Text(
                        'Upcoming Appointments',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.textPrimary,
                        ),
                      ),
                      const Gap(12),
                      buildAppointmentsTable(upcomingAppointments),
                    ],
                  );
                },
                loading: () => ShimmerCardLoader(),
                error: (error, stack) =>
                    ErrorStateWidget(message: error.toString(), onRetry: () {}),
              ),
              loading: () => ShimmerCardLoader(),
              error: (error, stack) =>
                  ErrorStateWidget(message: error.toString(), onRetry: () {}),
                );
              },
            loading: () => ShimmerCardLoader(),
            error: (error, stack) =>
                ErrorStateWidget(message: error.toString(), onRetry: () {}),
          ),
        ],
      ),
    );
  }
}

class _WorkoutsTab extends ConsumerWidget {
  final WidgetRef ref;

  const _WorkoutsTab({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutsAsync = ref.watch(workoutsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Workouts Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Gap(16),
          workoutsAsync.when(
            data: (workouts) => HolicsCard(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Title')),
                    DataColumn(label: Text('Duration')),
                    DataColumn(label: Text('Difficulty')),
                    DataColumn(label: Text('Required Plan')),
                  ],
                  rows: workouts.map((workout) {
                    return DataRow(cells: [
                      DataCell(Text(workout.title)),
                      DataCell(Text('${workout.durationMin} min')),
                      DataCell(Text(workout.difficulty)),
                      DataCell(Text(workout.requiredPlan)),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            loading: () => ShimmerCardLoader(),
            error: (error, stack) =>
                ErrorStateWidget(message: error.toString(), onRetry: () {}),
          ),
        ],
      ),
    );
  }
}

class _ServicesTab extends ConsumerWidget {
  final WidgetRef ref;

  const _ServicesTab({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final servicesAsync = ref.watch(skinServicesProvider);
    final appointmentsAsync = ref.watch(allAppointmentsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Services Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Gap(16),
          servicesAsync.when(
            data: (services) => HolicsCard(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Duration')),
                    DataColumn(label: Text('Price')),
                    DataColumn(label: Text('Badge')),
                  ],
                  rows: services.map((service) {
                    return DataRow(cells: [
                      DataCell(Text(service.name)),
                      DataCell(Text('${service.durationMin} min')),
                      DataCell(Text('PKR ${service.price.toStringAsFixed(0)}')),
                      DataCell(Text(service.badge ?? 'None')),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            loading: () => ShimmerCardLoader(),
            error: (error, stack) =>
                ErrorStateWidget(message: error.toString(), onRetry: () {}),
          ),
        ],
      ),
    );
  }
}

class _SpecialistsTab extends ConsumerWidget {
  final WidgetRef ref;

  const _SpecialistsTab({required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final specialistsAsync = ref.watch(specialistsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Specialists Management',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Gap(16),
          specialistsAsync.when(
            data: (specialists) => HolicsCard(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: DataTable(
                  columns: const [
                    DataColumn(label: Text('Name')),
                    DataColumn(label: Text('Specialty')),
                    DataColumn(label: Text('Availability')),
                  ],
                  rows: specialists.map((specialist) {
                    return DataRow(cells: [
                      DataCell(Text(specialist.name)),
                      DataCell(Text(specialist.specialty)),
                      DataCell(Text(specialist.isAvailable
                          ? 'Available'
                          : 'Unavailable')),
                    ]);
                  }).toList(),
                ),
              ),
            ),
            loading: () => ShimmerCardLoader(),
            error: (error, stack) =>
                ErrorStateWidget(message: error.toString(), onRetry: () {}),
          ),
        ],
      ),
    );
  }
}

class _SettingsTab extends ConsumerStatefulWidget {
  final WidgetRef ref;

  const _SettingsTab({required this.ref});

  @override
  ConsumerState<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends ConsumerState<_SettingsTab> {
  late TextEditingController _bankNameController;
  late TextEditingController _accountHolderController;
  late TextEditingController _accountNumberController;
  late TextEditingController _ifscController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _bankNameController = TextEditingController();
    _accountHolderController = TextEditingController();
    _accountNumberController = TextEditingController();
    _ifscController = TextEditingController();
  }

  @override
  void dispose() {
    _bankNameController.dispose();
    _accountHolderController.dispose();
    _accountNumberController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService = ref.read(firestoreServiceProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Settings & Bank Details',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const Gap(8),
          const Text(
            'Configure your bank account for receiving member payments',
            style: TextStyle(fontSize: 14, color: AppTheme.textSecondary),
          ),
          const Gap(24),

          // Current Bank Details Display
          StreamBuilder<Map<String, dynamic>?>(
            stream: firestoreService.adminBankDetailsStream(),
            builder: (context, snapshot) {
              final bankDetails = snapshot.data;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Current Bank Details',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const Gap(12),
                  if (bankDetails == null)
                    const Text(
                      'No bank details configured yet',
                      style: TextStyle(color: AppTheme.textSecondary),
                    )
                  else
                    HolicsCard(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildDetailRow(
                            'Bank Name',
                            bankDetails['bankName'] ?? 'N/A',
                          ),
                          const Gap(12),
                          _buildDetailRow(
                            'Account Holder',
                            bankDetails['accountHolder'] ?? 'N/A',
                          ),
                          const Gap(12),
                          _buildDetailRow(
                            'Account Number',
                            bankDetails['accountNumber'] ?? 'N/A',
                          ),
                          const Gap(12),
                          _buildDetailRow(
                            'IFSC Code',
                            bankDetails['ifscCode'] ?? 'N/A',
                          ),
                        ],
                      ),
                    ),
                  const Gap(24),
                  const Divider(),
                  const Gap(24),
                ],
              );
            },
          ),

          // Update Bank Details Form
          const Text(
            'Update Bank Details',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppTheme.textPrimary,
            ),
          ),
          const Gap(12),
          HolicsCard(
            child: Column(
              children: [
                _buildTextField('Bank Name', _bankNameController),
                const Gap(12),
                _buildTextField(
                  'Account Holder Name',
                  _accountHolderController,
                ),
                const Gap(12),
                _buildTextField(
                  'Account Number',
                  _accountNumberController,
                  keyboardType: TextInputType.number,
                ),
                const Gap(12),
                _buildTextField(
                  'IFSC Code',
                  _ifscController,
                ),
                const Gap(20),
                ElevatedButton(
                  onPressed: _isSaving
                      ? null
                      : () async {
                          if (_bankNameController.text.isEmpty ||
                              _accountHolderController.text.isEmpty ||
                              _accountNumberController.text.isEmpty ||
                              _ifscController.text.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Please fill all fields'),
                              ),
                            );
                            return;
                          }

                          setState(() => _isSaving = true);
                          try {
                            await firestoreService.setAdminBankDetails({
                              'bankName': _bankNameController.text.trim(),
                              'accountHolder':
                                  _accountHolderController.text.trim(),
                              'accountNumber':
                                  _accountNumberController.text.trim(),
                              'ifscCode': _ifscController.text.trim(),
                            });

                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text(
                                    'Bank details updated successfully!',
                                  ),
                                ),
                              );
                              _bankNameController.clear();
                              _accountHolderController.clear();
                              _accountNumberController.clear();
                              _ifscController.clear();
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e')),
                              );
                            }
                          } finally {
                            if (mounted) {
                              setState(() => _isSaving = false);
                            }
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.bodyHolicsOrange,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  child: _isSaving
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
                      : const Text('Save Bank Details'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
        const Gap(6),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: label,
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

  Widget _buildDetailRow(String label, String value) {
    return Row(
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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppTheme.textPrimary,
          ),
        ),
      ],
    );
  }
}
