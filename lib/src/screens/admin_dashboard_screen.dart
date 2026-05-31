import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_theme.dart';
import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/wash_data.dart';
import '../services/booking_service.dart';
import '../widgets/cleanride_logo.dart';
import '../widgets/status_badge.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({
    super.key,
    required this.user,
    required this.bookingService,
    required this.onLogout,
  });

  final AppUser user;
  final BookingService bookingService;
  final Future<void> Function() onLogout;

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  final _searchController = TextEditingController();
  Timer? _timer;

  bool _loading = true;
  int _tabIndex = 0;
  String _statusFilter = 'all';
  String? _error;
  Map<String, dynamic> _stats = {};
  Map<String, dynamic> _teamStats = {};
  List<Booking> _bookings = [];

  @override
  void initState() {
    super.initState();
    _loadAdminData();
    _timer = Timer.periodic(
      const Duration(seconds: 45),
      (_) => _loadAdminData(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAdminData() async {
    try {
      final results = await Future.wait([
        widget.bookingService.fetchAdminStats(),
        widget.bookingService.fetchAdminTeamStats(),
        widget.bookingService.fetchAdminBookings(
          status: _statusFilter,
          search: _searchController.text,
        ),
      ]);

      if (mounted) {
        setState(() {
          _stats = results[0] as Map<String, dynamic>;
          _teamStats = results[1] as Map<String, dynamic>;
          _bookings = results[2] as List<Booking>;
          _error = null;
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = error.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _logout() async {
    await widget.onLogout();
    if (mounted) context.go('/');
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = [
      _AdminOverviewTab(
        stats: _stats,
        teamStats: _teamStats,
        recentBookings: _bookings.take(5).toList(),
        onOpenBookings: () => setState(() => _tabIndex = 1),
      ),
      _AdminBookingsTab(
        bookings: _bookings,
        statusFilter: _statusFilter,
        searchController: _searchController,
        onFilterChanged: (value) {
          setState(() => _statusFilter = value);
          _loadAdminData();
        },
        onSearch: _loadAdminData,
      ),
      _AdminTeamTab(teamStats: _teamStats),
      _AdminProfileTab(user: widget.user, stats: _stats, onLogout: _logout),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CleanRideLogo(fontSize: 23),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(999),
              ),
              child: const Text(
                'Admin',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadAdminData,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: _logout,
            icon: const Icon(Icons.logout),
          ),
          const SizedBox(width: 4),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard),
            label: 'Admin',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Bookings',
          ),
          NavigationDestination(
            icon: Icon(Icons.groups_outlined),
            selectedIcon: Icon(Icons.groups),
            label: 'Team',
          ),
          NavigationDestination(
            icon: Icon(Icons.admin_panel_settings_outlined),
            selectedIcon: Icon(Icons.admin_panel_settings),
            label: 'Profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadAdminData,
        child: SafeArea(
          bottom: false,
          child: _error == null
              ? IndexedStack(index: _tabIndex, children: tabs)
              : ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(24),
                  children: [
                    _AdminEmptyPanel(
                      icon: Icons.error_outline,
                      title: 'Could not load admin data',
                      message: _error!,
                      actionLabel: 'Try again',
                      onAction: _loadAdminData,
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class _AdminOverviewTab extends StatelessWidget {
  const _AdminOverviewTab({
    required this.stats,
    required this.teamStats,
    required this.recentBookings,
    required this.onOpenBookings,
  });

  final Map<String, dynamic> stats;
  final Map<String, dynamic> teamStats;
  final List<Booking> recentBookings;
  final VoidCallback onOpenBookings;

  num _num(Map<String, dynamic> source, String key) {
    final value = source[key];
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
      children: [
        Text(
          'Admin Dash',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        Text(
          'Business performance overview',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.primaryColor,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _AdminMetric(
                title: 'Total Revenue',
                value: 'Rs. ${_num(stats, 'total_revenue').toInt()}',
                icon: Icons.payments_outlined,
                color: Colors.green,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AdminMetric(
                title: 'Bookings',
                value: '${_num(stats, 'total_bookings').toInt()}',
                icon: Icons.assignment_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _AdminMetric(
                title: 'Staff',
                value: '${_num(stats, 'total_staff_count').toInt()}',
                icon: Icons.shield_outlined,
                color: Colors.amber,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AdminMetric(
                title: 'Customers',
                value: '${_num(stats, 'total_customers').toInt()}',
                icon: Icons.people_outline,
                color: Colors.lightBlueAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            Expanded(
              child: _AdminMetric(
                title: 'Active',
                value: '${_num(stats, 'active_bookings').toInt()}',
                icon: Icons.local_car_wash_outlined,
                color: Colors.orangeAccent,
                compact: true,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AdminMetric(
                title: 'On Duty',
                value: '${_num(teamStats, 'on_duty_today').toInt()}',
                icon: Icons.engineering_outlined,
                color: AppTheme.primaryColor,
                compact: true,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _AdminSectionHeader(
          title: 'Recent bookings',
          actionLabel: 'View all',
          onAction: onOpenBookings,
        ),
        const SizedBox(height: 10),
        if (recentBookings.isEmpty)
          const _AdminEmptyPanel(
            icon: Icons.calendar_month_outlined,
            title: 'No bookings yet',
            message: 'Admin bookings will appear here once customers book.',
          )
        else
          ...recentBookings.map(
            (booking) => _AdminBookingCard(booking: booking),
          ),
      ],
    );
  }
}

class _AdminBookingsTab extends StatelessWidget {
  const _AdminBookingsTab({
    required this.bookings,
    required this.statusFilter,
    required this.searchController,
    required this.onFilterChanged,
    required this.onSearch,
  });

  final List<Booking> bookings;
  final String statusFilter;
  final TextEditingController searchController;
  final ValueChanged<String> onFilterChanged;
  final VoidCallback onSearch;

  @override
  Widget build(BuildContext context) {
    final filters = ['all', 'queued', 'washing', 'drying', 'completed'];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
      children: [
        const _AdminSectionHeader(title: 'Recent Bookings'),
        const SizedBox(height: 12),
        TextField(
          controller: searchController,
          textInputAction: TextInputAction.search,
          onSubmitted: (_) => onSearch(),
          decoration: InputDecoration(
            hintText: 'Search by name or plate',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: IconButton(
              tooltip: 'Search',
              onPressed: onSearch,
              icon: const Icon(Icons.arrow_forward),
            ),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: statusFilter == filter,
                  onSelected: (_) => onFilterChanged(filter),
                  label: Text(
                    filter == 'all'
                        ? 'All'
                        : WashData.statusLabels[filter] ?? filter,
                  ),
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 14),
        if (bookings.isEmpty)
          const _AdminEmptyPanel(
            icon: Icons.search_off,
            title: 'No matching bookings',
            message: 'Try another search term or status filter.',
          )
        else
          ...bookings.map((booking) => _AdminBookingCard(booking: booking)),
      ],
    );
  }
}

class _AdminTeamTab extends StatelessWidget {
  const _AdminTeamTab({required this.teamStats});

  final Map<String, dynamic> teamStats;

  num _num(String key) {
    final value = teamStats[key];
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
      children: [
        const _AdminSectionHeader(title: 'Team overview'),
        const SizedBox(height: 12),
        _AdminMetric(
          title: 'On-duty today',
          value:
              '${_num('on_duty_today').toInt()} / ${_num('total_staff').toInt()}',
          icon: Icons.groups_outlined,
          color: AppTheme.primaryColor,
          compact: true,
        ),
        const SizedBox(height: 12),
        _AdminMetric(
          title: 'Avg tasks per day',
          value: _num('avg_tasks_per_day').toString(),
          icon: Icons.trending_up,
          color: Colors.green,
          compact: true,
        ),
        const SizedBox(height: 12),
        _AdminMetric(
          title: 'Team rating',
          value: _num('team_rating').toString(),
          icon: Icons.star_outline,
          color: Colors.amber,
          compact: true,
        ),
      ],
    );
  }
}

class _AdminProfileTab extends StatelessWidget {
  const _AdminProfileTab({
    required this.user,
    required this.stats,
    required this.onLogout,
  });

  final AppUser user;
  final Map<String, dynamic> stats;
  final VoidCallback onLogout;

  num _num(String key) {
    final value = stats[key];
    if (value is num) return value;
    if (value is String) return num.tryParse(value) ?? 0;
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppTheme.cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppTheme.borderColor),
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: 38,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.14),
                child: Text(
                  user.name.isNotEmpty ? user.name[0].toUpperCase() : 'A',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontSize: 30,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                user.name,
                textAlign: TextAlign.center,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 4),
              Text(
                user.email,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedForegroundColor,
                ),
              ),
              const SizedBox(height: 14),
              const StatusBadge(status: 'admin'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _AdminMetric(
                title: 'Bookings',
                value: '${_num('total_bookings').toInt()}',
                icon: Icons.assignment_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _AdminMetric(
                title: 'Customers',
                value: '${_num('total_customers').toInt()}',
                icon: Icons.people_outline,
                color: Colors.lightBlueAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _AdminAction(
          icon: Icons.logout,
          title: 'Sign out',
          subtitle: 'Leave this device safely',
          danger: true,
          onTap: onLogout,
        ),
      ],
    );
  }
}

class _AdminMetric extends StatelessWidget {
  const _AdminMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.compact = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: compact ? 78 : 106),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontSize: compact ? 20 : 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminBookingCard extends StatelessWidget {
  const _AdminBookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    final packageName =
        WashData.packagePricing[booking.washPackage.toLowerCase()]?.name ??
        booking.washPackage;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.customerName.isEmpty
                      ? 'Customer'
                      : booking.customerName,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            booking.vehicleNumber.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '$packageName | ${booking.date} at ${booking.timeSlot}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(
                booking.isPaid ? Icons.verified_outlined : Icons.error_outline,
                color: booking.isPaid ? Colors.green : Colors.amber,
                size: 16,
              ),
              const SizedBox(width: 6),
              Text(
                booking.isPaid ? 'Paid' : 'Unpaid',
                style: TextStyle(
                  color: booking.isPaid ? Colors.green : Colors.amber,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              const Spacer(),
              Text(
                booking.customerPhone,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdminSectionHeader extends StatelessWidget {
  const _AdminSectionHeader({
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
        ),
        const Spacer(),
        if (actionLabel != null)
          TextButton(onPressed: onAction, child: Text(actionLabel!)),
      ],
    );
  }
}

class _AdminEmptyPanel extends StatelessWidget {
  const _AdminEmptyPanel({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Icon(icon, color: AppTheme.mutedForegroundColor, size: 38),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedForegroundColor,
            ),
          ),
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 16),
            OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
  }
}

class _AdminAction extends StatelessWidget {
  const _AdminAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppTheme.destructiveColor : AppTheme.primaryColor;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: danger
                          ? AppTheme.destructiveColor
                          : AppTheme.foregroundColor,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: AppTheme.mutedForegroundColor.withValues(alpha: 0.7),
            ),
          ],
        ),
      ),
    );
  }
}
