import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_theme.dart';
import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/wash_data.dart';
import '../services/booking_service.dart';
import '../widgets/booking_card.dart';
import '../widgets/cleanride_logo.dart';
import '../widgets/status_badge.dart';
import 'booking_form_sheet.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.user,
    required this.bookingService,
    required this.onLogout,
  });

  final AppUser user;
  final BookingService bookingService;
  final Future<void> Function() onLogout;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  List<Booking> _bookings = [];
  bool _loading = true;
  int _tabIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _loadBookings(),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadBookings() async {
    try {
      final list = await widget.bookingService.fetchMyBookings();
      if (mounted) {
        setState(() => _bookings = list);
      }
    } catch (_) {
      // Keep the existing dashboard data if refresh fails.
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<Booking> get _activeBookings {
    return _bookings.where((booking) {
      final status = booking.status.toLowerCase();
      return status != 'completed' && status != 'cancelled';
    }).toList();
  }

  List<Booking> get _completedBookings {
    return _bookings
        .where((booking) => booking.status.toLowerCase() == 'completed')
        .toList();
  }

  void _showBookingForm() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return BookingFormSheet(
          bookingService: widget.bookingService,
          onBookingCreated: (bookingId) {
            Navigator.pop(context);
            _loadBookings();
            context.go('/dashboard/checkout/$bookingId');
          },
        );
      },
    );
  }

  Future<void> _logout() async {
    await widget.onLogout();
    if (mounted) context.go('/');
  }

  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (context) {
        final packageInfo =
            WashData.packagePricing[booking.washPackage.toLowerCase()];
        final packageName = packageInfo?.name ?? booking.washPackage;
        final price = packageInfo?.price ?? 1000.0;

        return AlertDialog(
          backgroundColor: AppTheme.cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: AppTheme.borderColor),
          ),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Booking Details',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.foregroundColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow(
                  'Vehicle number',
                  booking.vehicleNumber.toUpperCase(),
                ),
                _buildDetailRow(
                  'Vehicle type',
                  WashData.vehicleTypeLabels[booking.vehicleType] ??
                      booking.vehicleType,
                ),
                _buildDetailRow('Package', packageName),
                _buildDetailRow('Price', 'Rs. ${price.toInt()}'),
                _buildDetailRow('Date', booking.date),
                _buildDetailRow('Time', booking.timeSlot),
                _buildDetailRow(
                  'Status',
                  WashData.statusLabels[booking.status.toLowerCase()] ??
                      booking.status,
                ),
                _buildDetailRow(
                  'Phone',
                  booking.contactPhone ?? 'Not provided',
                ),
                _buildDetailRow('Address', booking.address ?? 'Not provided'),
                if (booking.assignedStaff != null &&
                    booking.assignedStaff!.isNotEmpty)
                  _buildDetailRow('Staff', booking.assignedStaff!),
                if (booking.estimatedTime != null && booking.estimatedTime! > 0)
                  _buildDetailRow('Estimate', '${booking.estimatedTime} min'),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedForegroundColor,
                      ),
                    ),
                    if (booking.isPaid)
                      const Row(
                        children: [
                          Icon(
                            Icons.verified_outlined,
                            color: Colors.green,
                            size: 16,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Paid',
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      )
                    else
                      FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/dashboard/checkout/${booking.id}');
                        },
                        icon: const Icon(Icons.credit_card, size: 16),
                        label: const Text('Pay now'),
                      ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: AppTheme.mutedForegroundColor,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final tabs = [
      _OverviewTab(
        user: widget.user,
        bookings: _bookings,
        activeBookings: _activeBookings,
        completedBookings: _completedBookings,
        onBook: _showBookingForm,
        onBookingTap: _showBookingDetails,
        onViewActivity: () => setState(() => _tabIndex = 2),
      ),
      _BookTab(onBook: _showBookingForm),
      _ActivityTab(
        bookings: _bookings,
        activeBookings: _activeBookings,
        completedBookings: _completedBookings,
        onBookingTap: _showBookingDetails,
      ),
      _ProfileTab(
        user: widget.user,
        totalBookings: _bookings.length,
        completedBookings: _completedBookings.length,
        onEditProfile: () => context.go('/profile'),
        onLogout: _logout,
      ),
    ];

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const CleanRideLogo(fontSize: 23),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loadBookings,
            icon: const Icon(Icons.refresh),
          ),
          const SizedBox(width: 4),
        ],
      ),
      floatingActionButton: _tabIndex == 0 || _tabIndex == 2
          ? FloatingActionButton.extended(
              onPressed: _showBookingForm,
              icon: const Icon(Icons.add),
              label: const Text('Book'),
            )
          : null,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tabIndex,
        onDestinationSelected: (index) => setState(() => _tabIndex = index),
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_car_wash_outlined),
            selectedIcon: Icon(Icons.local_car_wash),
            label: 'Book',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: SafeArea(
          bottom: false,
          child: IndexedStack(index: _tabIndex, children: tabs),
        ),
      ),
    );
  }
}

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({
    required this.user,
    required this.bookings,
    required this.activeBookings,
    required this.completedBookings,
    required this.onBook,
    required this.onBookingTap,
    required this.onViewActivity,
  });

  final AppUser user;
  final List<Booking> bookings;
  final List<Booking> activeBookings;
  final List<Booking> completedBookings;
  final VoidCallback onBook;
  final ValueChanged<Booking> onBookingTap;
  final VoidCallback onViewActivity;

  @override
  Widget build(BuildContext context) {
    final totalSpent = completedBookings.fold<double>(0, (sum, booking) {
      final packageInfo =
          WashData.packagePricing[booking.washPackage.toLowerCase()];
      return sum + (packageInfo?.price ?? 0);
    });
    final loyaltyTier = completedBookings.length >= 10
        ? 'Gold'
        : completedBookings.length >= 5
        ? 'Silver'
        : 'Bronze';
    final nextBooking = activeBookings.isNotEmpty ? activeBookings.first : null;
    final recentBookings = bookings.take(3).toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        _HeroDashboardCard(
          name: user.name.split(' ').first,
          activeCount: activeBookings.length,
          onBook: onBook,
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Active',
                value: '${activeBookings.length}',
                icon: Icons.timelapse,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Spent',
                value: 'Rs. ${totalSpent.toInt()}',
                icon: Icons.account_balance_wallet_outlined,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Washes',
                value: '${completedBookings.length}',
                icon: Icons.check_circle_outline,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MetricCard(
                title: 'Tier',
                value: loyaltyTier,
                icon: Icons.workspace_premium_outlined,
                color: Colors.amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Live status',
          actionLabel: activeBookings.length > 1 ? 'View all' : null,
          onAction: onViewActivity,
        ),
        const SizedBox(height: 12),
        if (nextBooking == null)
          _EmptyPanel(
            icon: Icons.event_available_outlined,
            title: 'No active booking',
            message: 'Schedule your next wash and track it here.',
            actionLabel: 'Book a wash',
            onAction: onBook,
          )
        else
          _LiveStatusCard(
            booking: nextBooking,
            onTap: () => onBookingTap(nextBooking),
          ),
        const SizedBox(height: 24),
        _SectionHeader(
          title: 'Recent bookings',
          actionLabel: bookings.length > 3 ? 'View all' : null,
          onAction: onViewActivity,
        ),
        const SizedBox(height: 8),
        if (recentBookings.isEmpty)
          _EmptyPanel(
            icon: Icons.receipt_long_outlined,
            title: 'No bookings yet',
            message: 'Your completed and upcoming washes will appear here.',
          )
        else
          ...recentBookings.map(
            (booking) => BookingCard(
              booking: booking,
              onTap: () => onBookingTap(booking),
            ),
          ),
      ],
    );
  }
}

class _BookTab extends StatelessWidget {
  const _BookTab({required this.onBook});

  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        Text(
          'Choose your wash',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontFamily: GoogleFonts.inter(
              fontWeight: FontWeight.w800,
            ).fontFamily,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Pick a package, choose a time, and confirm your booking in one flow.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTheme.mutedForegroundColor,
          ),
        ),
        const SizedBox(height: 18),
        ...WashData.packagePricing.entries.map((entry) {
          final packageKey = entry.key;
          final packageInfo = entry.value;
          final highlighted = packageKey == 'standard';

          return Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: highlighted
                  ? AppTheme.primaryColor.withValues(alpha: 0.08)
                  : AppTheme.cardColor,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: highlighted
                    ? AppTheme.primaryColor.withValues(alpha: 0.65)
                    : AppTheme.borderColor,
              ),
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
                        color: AppTheme.primaryColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.local_car_wash,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            packageInfo.name,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          Text(
                            '~${packageInfo.duration} min service',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Rs. ${packageInfo.price.toInt()}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: packageInfo.features.take(4).map((feature) {
                    return _FeaturePill(label: feature);
                  }).toList(),
                ),
              ],
            ),
          );
        }),
        const SizedBox(height: 8),
        FilledButton.icon(
          onPressed: onBook,
          icon: const Icon(Icons.calendar_month),
          label: const Text('Start booking'),
          style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
        ),
      ],
    );
  }
}

class _ActivityTab extends StatelessWidget {
  const _ActivityTab({
    required this.bookings,
    required this.activeBookings,
    required this.completedBookings,
    required this.onBookingTap,
  });

  final List<Booking> bookings;
  final List<Booking> activeBookings;
  final List<Booking> completedBookings;
  final ValueChanged<Booking> onBookingTap;

  @override
  Widget build(BuildContext context) {
    final cancelledBookings = bookings
        .where((booking) => booking.status.toLowerCase() == 'cancelled')
        .toList();

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
      children: [
        _SectionHeader(title: 'Activity'),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SmallSummary(
                title: 'Active',
                value: '${activeBookings.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmallSummary(
                title: 'Completed',
                value: '${completedBookings.length}',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmallSummary(
                title: 'Cancelled',
                value: '${cancelledBookings.length}',
              ),
            ),
          ],
        ),
        const SizedBox(height: 22),
        if (activeBookings.isNotEmpty) ...[
          _SectionHeader(title: 'In progress'),
          const SizedBox(height: 8),
          ...activeBookings.map(
            (booking) => BookingCard(
              booking: booking,
              onTap: () => onBookingTap(booking),
            ),
          ),
          const SizedBox(height: 22),
        ],
        _SectionHeader(title: 'All bookings'),
        const SizedBox(height: 8),
        if (bookings.isEmpty)
          const _EmptyPanel(
            icon: Icons.receipt_long_outlined,
            title: 'No activity yet',
            message: 'Bookings and payments will show up here.',
          )
        else
          ...bookings.map(
            (booking) => BookingCard(
              booking: booking,
              onTap: () => onBookingTap(booking),
            ),
          ),
      ],
    );
  }
}

class _ProfileTab extends StatelessWidget {
  const _ProfileTab({
    required this.user,
    required this.totalBookings,
    required this.completedBookings,
    required this.onEditProfile,
    required this.onLogout,
  });

  final AppUser user;
  final int totalBookings;
  final int completedBookings;
  final VoidCallback onEditProfile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
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
                  user.name.isNotEmpty
                      ? user.name.substring(0, 1).toUpperCase()
                      : 'C',
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                  ).fontFamily,
                  fontWeight: FontWeight.w900,
                ),
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
              StatusBadge(status: user.role),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _SmallSummary(title: 'Bookings', value: '$totalBookings'),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SmallSummary(
                title: 'Completed',
                value: '$completedBookings',
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ProfileAction(
          icon: Icons.manage_accounts_outlined,
          title: 'Edit profile',
          subtitle: 'Update name, phone, and password',
          onTap: onEditProfile,
        ),
        _ProfileAction(
          icon: Icons.support_agent_outlined,
          title: 'Support',
          subtitle: 'contact@cleanride.com.np',
          onTap: () {},
        ),
        _ProfileAction(
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

class _HeroDashboardCard extends StatelessWidget {
  const _HeroDashboardCard({
    required this.name,
    required this.activeCount,
    required this.onBook,
  });

  final String name;
  final int activeCount;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF12333A), Color(0xFF11171D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.22),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.bolt,
                      color: AppTheme.primaryColor,
                      size: 16,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      activeCount == 0
                          ? 'Ready to book'
                          : '$activeCount active',
                      style: const TextStyle(
                        color: AppTheme.foregroundColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Hi $name,',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
              ).fontFamily,
              fontWeight: FontWeight.w900,
              fontSize: 28,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Book your next wash and track the vehicle status from your dashboard.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.secondaryForegroundColor,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onBook,
            icon: const Icon(Icons.local_car_wash),
            label: const Text('Book a wash'),
          ),
        ],
      ),
    );
  }
}

class _LiveStatusCard extends StatelessWidget {
  const _LiveStatusCard({required this.booking, required this.onTap});

  final Booking booking;
  final VoidCallback onTap;

  double _progressFor(String status) {
    switch (status.toLowerCase()) {
      case 'queued':
        return 0.15;
      case 'in-progress':
        return 0.35;
      case 'washing':
        return 0.60;
      case 'drying':
        return 0.85;
      case 'completed':
        return 1;
      default:
        return 0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _progressFor(booking.status);
    final packageInfo =
        WashData.packagePricing[booking.washPackage.toLowerCase()];

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppTheme.cardColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.directions_car_filled,
                    color: AppTheme.primaryColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        booking.vehicleNumber.toUpperCase(),
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      Text(
                        '${packageInfo?.name ?? booking.washPackage} | ${booking.timeSlot}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                StatusBadge(status: booking.status),
              ],
            ),
            const SizedBox(height: 18),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: AppTheme.secondaryColor,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  AppTheme.primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Text(
                  WashData.statusLabels[booking.status.toLowerCase()] ??
                      booking.status,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const Spacer(),
                Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    color: AppTheme.primaryColor,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 104),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
              ).fontFamily,
              fontSize: 21,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 2),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.actionLabel, this.onAction});

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

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({
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

class _FeaturePill extends StatelessWidget {
  const _FeaturePill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.secondaryColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.secondaryForegroundColor,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SmallSummary extends StatelessWidget {
  const _SmallSummary({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w900,
              color: AppTheme.foregroundColor,
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
    );
  }
}

class _ProfileAction extends StatelessWidget {
  const _ProfileAction({
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

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
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
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
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
      ),
    );
  }
}
