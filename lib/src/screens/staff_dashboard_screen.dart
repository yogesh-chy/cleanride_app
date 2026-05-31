import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_theme.dart';
import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/wash_data.dart';
import '../services/booking_service.dart';
import '../widgets/cleanride_logo.dart';
import '../widgets/status_badge.dart';

class StaffDashboardScreen extends StatefulWidget {
  const StaffDashboardScreen({
    super.key,
    required this.user,
    required this.bookingService,
    required this.onLogout,
  });

  final AppUser user;
  final BookingService bookingService;
  final Future<void> Function() onLogout;

  @override
  State<StaffDashboardScreen> createState() => _StaffDashboardScreenState();
}

class _StaffDashboardScreenState extends State<StaffDashboardScreen> {
  final List<String> _statusFlow = [
    'queued',
    'in-progress',
    'washing',
    'drying',
    'completed',
  ];

  List<Booking> _bookings = [];
  bool _loading = true;
  bool _mineOnly = false;
  int _tabIndex = 0;
  String _activityFilter = 'all';
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadQueue();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadQueue());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _loadQueue() async {
    try {
      final list = await widget.bookingService.fetchQueue(mine: _mineOnly);
      if (mounted) {
        setState(() => _bookings = list);
      }
    } catch (_) {
      // Keep current queue data if refresh fails.
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _advanceStatus(Booking booking) async {
    final currentIndex = _statusFlow.indexOf(booking.status.toLowerCase());
    if (currentIndex < 0 || currentIndex >= _statusFlow.length - 1) return;

    final nextStatus = _statusFlow[currentIndex + 1];
    try {
      await widget.bookingService.updateStatus(booking.id, nextStatus);
      await _loadQueue();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Updated to ${WashData.statusLabels[nextStatus] ?? nextStatus}',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error.toString()),
            backgroundColor: AppTheme.destructiveColor,
          ),
        );
      }
    }
  }

  Future<void> _logout() async {
    await widget.onLogout();
    if (mounted) context.go('/');
  }

  Booking? get _activeJob {
    final myId = widget.user.id.toString();
    try {
      return _bookings.firstWhere(
        (booking) =>
            booking.assignedStaffId == myId &&
            booking.status.toLowerCase() != 'completed' &&
            booking.status.toLowerCase() != 'cancelled',
      );
    } catch (_) {
      return null;
    }
  }

  List<Booking> get _availableQueue {
    return _bookings.where((booking) {
      final isUnassigned =
          booking.assignedStaffId == null ||
          booking.assignedStaffId!.isEmpty ||
          booking.assignedStaffId == 'null';
      return isUnassigned && booking.status.toLowerCase() == 'queued';
    }).toList();
  }

  List<Booking> get _activeQueue {
    return _bookings.where((booking) {
      final status = booking.status.toLowerCase();
      return status != 'completed' && status != 'cancelled';
    }).toList();
  }

  List<Booking> get _completedJobs {
    return _bookings
        .where((booking) => booking.status.toLowerCase() == 'completed')
        .toList();
  }

  List<Booking> get _filteredActivity {
    if (_activityFilter == 'all') return _bookings;
    return _bookings
        .where((booking) => booking.status.toLowerCase() == _activityFilter)
        .toList();
  }

  void _toggleMineOnly() {
    setState(() => _mineOnly = !_mineOnly);
    _loadQueue();
  }

  IconData _statusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'queued':
        return Icons.schedule;
      case 'in-progress':
        return Icons.play_arrow_outlined;
      case 'washing':
        return Icons.water_drop_outlined;
      case 'drying':
        return Icons.air_outlined;
      case 'completed':
        return Icons.check_circle_outline;
      case 'cancelled':
        return Icons.cancel_outlined;
      default:
        return Icons.receipt_long_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final activeJob = _activeJob;
    final availableQueue = _availableQueue;
    final tabs = [
      _StaffTodayTab(
        user: widget.user,
        activeJob: activeJob,
        availableCount: availableQueue.length,
        activeCount: _activeQueue.length,
        completedCount: _completedJobs.length,
        onNextStage: activeJob == null ? null : () => _advanceStatus(activeJob),
        onOpenQueue: () => setState(() => _tabIndex = 1),
      ),
      _StaffQueueTab(
        activeJob: activeJob,
        availableQueue: availableQueue,
        mineOnly: _mineOnly,
        onToggleMineOnly: _toggleMineOnly,
        onStart: _advanceStatus,
      ),
      _StaffActivityTab(
        bookings: _filteredActivity,
        selectedFilter: _activityFilter,
        onFilterChanged: (filter) => setState(() => _activityFilter = filter),
        statusIcon: _statusIcon,
      ),
      _StaffProfileTab(
        user: widget.user,
        activeCount: _activeQueue.length,
        completedCount: _completedJobs.length,
        mineOnly: _mineOnly,
        onToggleMineOnly: _toggleMineOnly,
        onLogout: _logout,
      ),
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
                'Staff',
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
            onPressed: _loadQueue,
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
            icon: Icon(Icons.assignment_outlined),
            selectedIcon: Icon(Icons.assignment),
            label: 'Task',
          ),
          NavigationDestination(
            icon: Icon(Icons.format_list_bulleted),
            selectedIcon: Icon(Icons.playlist_add_check),
            label: 'Queue',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Activity',
          ),
          NavigationDestination(
            icon: Icon(Icons.badge_outlined),
            selectedIcon: Icon(Icons.badge),
            label: 'Profile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadQueue,
        child: SafeArea(
          bottom: false,
          child: IndexedStack(index: _tabIndex, children: tabs),
        ),
      ),
    );
  }
}

class _StaffTodayTab extends StatelessWidget {
  const _StaffTodayTab({
    required this.user,
    required this.activeJob,
    required this.availableCount,
    required this.activeCount,
    required this.completedCount,
    required this.onNextStage,
    required this.onOpenQueue,
  });

  final AppUser user;
  final Booking? activeJob;
  final int availableCount;
  final int activeCount;
  final int completedCount;
  final VoidCallback? onNextStage;
  final VoidCallback onOpenQueue;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF17323A), Color(0xFF11171D)],
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
              Text(
                'Staff dashboard',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Hi ${user.name.split(' ').first},',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontFamily: GoogleFonts.inter(
                    fontWeight: FontWeight.w900,
                  ).fontFamily,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Claim queued vehicles, update wash stages, and keep customers informed.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.secondaryForegroundColor,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: _StaffMetric(
                title: 'Active',
                value: '$activeCount',
                icon: Icons.local_car_wash_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StaffMetric(
                title: 'Available',
                value: '$availableCount',
                icon: Icons.inbox_outlined,
                color: Colors.orangeAccent,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StaffMetric(
          title: 'Completed today',
          value: '$completedCount',
          icon: Icons.verified_outlined,
          color: Colors.green,
          wide: true,
        ),
        const SizedBox(height: 24),
        _StaffSectionHeader(title: 'Current task'),
        const SizedBox(height: 12),
        if (activeJob == null)
          _StaffEmptyPanel(
            icon: Icons.assignment_turned_in_outlined,
            title: 'No active task',
            message: 'Open the queue and start the next available wash.',
            actionLabel: 'Open queue',
            onAction: onOpenQueue,
          )
        else
          _ActiveJobCard(booking: activeJob!, onNextStage: onNextStage!),
      ],
    );
  }
}

class _StaffQueueTab extends StatelessWidget {
  const _StaffQueueTab({
    required this.activeJob,
    required this.availableQueue,
    required this.mineOnly,
    required this.onToggleMineOnly,
    required this.onStart,
  });

  final Booking? activeJob;
  final List<Booking> availableQueue;
  final bool mineOnly;
  final VoidCallback onToggleMineOnly;
  final ValueChanged<Booking> onStart;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
      children: [
        _StaffSectionHeader(
          title: 'Queue',
          action: FilterChip(
            selected: mineOnly,
            onSelected: (_) => onToggleMineOnly(),
            avatar: Icon(
              mineOnly ? Icons.person : Icons.groups_outlined,
              size: 18,
            ),
            label: Text(mineOnly ? 'Mine' : 'All'),
          ),
        ),
        const SizedBox(height: 12),
        if (activeJob != null)
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppTheme.primaryColor.withValues(alpha: 0.24),
              ),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Finish your current task before starting a new vehicle.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppTheme.secondaryForegroundColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (availableQueue.isEmpty)
          const _StaffEmptyPanel(
            icon: Icons.inbox_outlined,
            title: 'Queue is clear',
            message: 'No unassigned vehicles are waiting right now.',
          )
        else
          ...availableQueue.map(
            (booking) => _QueueJobCard(
              booking: booking,
              disabled: activeJob != null,
              onStart: () => onStart(booking),
            ),
          ),
      ],
    );
  }
}

class _StaffActivityTab extends StatelessWidget {
  const _StaffActivityTab({
    required this.bookings,
    required this.selectedFilter,
    required this.onFilterChanged,
    required this.statusIcon,
  });

  final List<Booking> bookings;
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final IconData Function(String status) statusIcon;

  @override
  Widget build(BuildContext context) {
    final filters = ['all', 'queued', 'washing', 'drying', 'completed'];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 104),
      children: [
        _StaffSectionHeader(title: 'Activity'),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: filters.map((filter) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selectedFilter == filter,
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
        const SizedBox(height: 16),
        if (bookings.isEmpty)
          const _StaffEmptyPanel(
            icon: Icons.history_outlined,
            title: 'No activity',
            message: 'Job updates will show here as the queue moves.',
          )
        else
          ...bookings.map(
            (booking) => _ActivityRow(
              booking: booking,
              icon: statusIcon(booking.status),
            ),
          ),
      ],
    );
  }
}

class _StaffProfileTab extends StatelessWidget {
  const _StaffProfileTab({
    required this.user,
    required this.activeCount,
    required this.completedCount,
    required this.mineOnly,
    required this.onToggleMineOnly,
    required this.onLogout,
  });

  final AppUser user;
  final int activeCount;
  final int completedCount;
  final bool mineOnly;
  final VoidCallback onToggleMineOnly;
  final VoidCallback onLogout;

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
                  user.name.isNotEmpty
                      ? user.name.substring(0, 1).toUpperCase()
                      : 'S',
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
              StatusBadge(status: 'Staff'),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _StaffMetric(
                title: 'Active',
                value: '$activeCount',
                icon: Icons.local_car_wash_outlined,
                color: AppTheme.primaryColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StaffMetric(
                title: 'Done',
                value: '$completedCount',
                icon: Icons.verified_outlined,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _StaffAction(
          icon: mineOnly ? Icons.person : Icons.groups_outlined,
          title: mineOnly ? 'Showing my jobs' : 'Showing all jobs',
          subtitle: 'Tap to switch queue scope',
          onTap: onToggleMineOnly,
        ),
        _StaffAction(
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

class _ActiveJobCard extends StatelessWidget {
  const _ActiveJobCard({required this.booking, required this.onNextStage});

  final Booking booking;
  final VoidCallback onNextStage;

  @override
  Widget build(BuildContext context) {
    final packageName =
        WashData.packagePricing[booking.washPackage.toLowerCase()]?.name ??
        booking.washPackage;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.35),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Job #${booking.id}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              StatusBadge(status: booking.status),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            booking.vehicleNumber.toUpperCase(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontFamily: GoogleFonts.inter(
                fontWeight: FontWeight.w900,
              ).fontFamily,
              fontSize: 28,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${booking.customerName} | $packageName',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.mutedForegroundColor,
            ),
          ),
          const SizedBox(height: 16),
          _JobInfoLine(
            icon: Icons.schedule,
            text: '${booking.date} at ${booking.timeSlot}',
          ),
          _JobInfoLine(
            icon: Icons.phone_outlined,
            text: booking.contactPhone ?? booking.customerPhone,
          ),
          _JobInfoLine(
            icon: Icons.location_on_outlined,
            text: booking.address ?? 'No address provided',
          ),
          const SizedBox(height: 18),
          FilledButton.icon(
            onPressed: onNextStage,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Move to next stage'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
            ),
          ),
        ],
      ),
    );
  }
}

class _QueueJobCard extends StatelessWidget {
  const _QueueJobCard({
    required this.booking,
    required this.disabled,
    required this.onStart,
  });

  final Booking booking;
  final bool disabled;
  final VoidCallback onStart;

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
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppTheme.secondaryColor,
                  borderRadius: BorderRadius.circular(14),
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
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '$packageName | ${booking.timeSlot}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              StatusBadge(status: booking.isPaid ? 'Paid' : 'Unpaid'),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  booking.customerName.isEmpty
                      ? 'Customer details pending'
                      : booking.customerName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.mutedForegroundColor,
                  ),
                ),
              ),
              FilledButton(
                onPressed: disabled ? null : onStart,
                child: Text(disabled ? 'Busy' : 'Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.booking, required this.icon});

  final Booking booking;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final color =
        WashData.statusColors[booking.status.toLowerCase()] ?? Colors.grey;
    final packageName =
        WashData.packagePricing[booking.washPackage.toLowerCase()]?.name ??
        booking.washPackage;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.vehicleNumber.toUpperCase(),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$packageName | ${booking.assignedStaff ?? 'Unassigned'}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          StatusBadge(status: booking.status),
        ],
      ),
    );
  }
}

class _StaffMetric extends StatelessWidget {
  const _StaffMetric({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    this.wide = false,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(minHeight: wide ? 82 : 104),
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
                    fontFamily: GoogleFonts.inter(
                      fontWeight: FontWeight.w900,
                    ).fontFamily,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 2),
                Text(title, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffSectionHeader extends StatelessWidget {
  const _StaffSectionHeader({required this.title, this.action});

  final String title;
  final Widget? action;

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
        ?action,
      ],
    );
  }
}

class _StaffEmptyPanel extends StatelessWidget {
  const _StaffEmptyPanel({
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

class _JobInfoLine extends StatelessWidget {
  const _JobInfoLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor, size: 17),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.secondaryForegroundColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffAction extends StatelessWidget {
  const _StaffAction({
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
