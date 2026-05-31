import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/wash_data.dart';
import '../services/booking_service.dart';
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
  final List<String> _statusFlow = ['queued', 'in-progress', 'washing', 'drying', 'completed'];

  List<Booking> _bookings = [];
  bool _loading = true;
  Timer? _timer;
  bool _mineOnly = false;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _loadQueue();
    // Auto-polling every 30 seconds
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
        setState(() {
          _bookings = list;
        });
      }
    } catch (e) {
      // Failed to load queue data silently
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _advanceStatus(Booking booking) async {
    final currentIdx = _statusFlow.indexOf(booking.status.toLowerCase());
    if (currentIdx < _statusFlow.length - 1) {
      final nextStatus = _statusFlow[currentIdx + 1];
      try {
        await widget.bookingService.updateStatus(booking.id, nextStatus);
        _loadQueue();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Updated vehicle to ${WashData.statusLabels[nextStatus] ?? nextStatus}'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: AppTheme.destructiveColor,
            ),
          );
        }
      }
    }
  }

  Booking? _getMyActiveJob() {
    final myIdStr = widget.user.id.toString();
    try {
      return _bookings.firstWhere(
        (b) =>
            b.assignedStaffId == myIdStr &&
            b.status.toLowerCase() != 'completed' &&
            b.status.toLowerCase() != 'cancelled',
      );
    } catch (_) {
      return null;
    }
  }

  List<Booking> _getAvailableQueue() {
    return _bookings.where((b) {
      final isUnassigned = b.assignedStaffId == null ||
          b.assignedStaffId!.isEmpty ||
          b.assignedStaffId == 'null';
      return isUnassigned && b.status.toLowerCase() == 'queued';
    }).toList();
  }

  List<Booking> _getOtherActivity(Booking? activeJob, List<Booking> available) {
    final availableIds = available.map((b) => b.id).toSet();
    return _bookings.where((b) {
      if (activeJob != null && b.id == activeJob.id) return false;
      return !availableIds.contains(b.id);
    }).toList();
  }

  IconData _getStatusIcon(String status) {
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
      default:
        return Icons.schedule;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activeJob = _getMyActiveJob();
    final available = _getAvailableQueue();
    final otherActivity = _getOtherActivity(activeJob, available);

    final filteredOther = _filter == 'all'
        ? otherActivity
        : otherActivity.where((b) => b.status.toLowerCase() == _filter).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Text(
              'CLEAN',
              style: GoogleFonts.bebasNeue(
                color: AppTheme.primaryColor,
                fontSize: 24,
                letterSpacing: 1.0,
              ),
            ),
            Text(
              'RIDE',
              style: GoogleFonts.bebasNeue(
                color: Colors.white,
                fontSize: 24,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                'STAFF PANEL',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Logout',
            onPressed: () async {
              await widget.onLogout();
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadQueue,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Active Task Section
              Text(
                'MY ACTIVE TASK',
                style: GoogleFonts.bebasNeue(
                  fontSize: 14,
                  color: AppTheme.primaryColor,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),
              if (activeJob != null) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.03),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2)),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Job #${activeJob.id}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.5),
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                          StatusBadge(status: activeJob.status),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        activeJob.vehicleNumber.toUpperCase(),
                        style: GoogleFonts.bebasNeue(
                          fontSize: 32,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${activeJob.customerName} | ${WashData.packagePricing[activeJob.washPackage.toLowerCase()]?.name ?? activeJob.washPackage}',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: AppTheme.mutedForegroundColor,
                            ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              activeJob.address ?? 'No address provided',
                              style: const TextStyle(fontSize: 12),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.phone_outlined, size: 16, color: AppTheme.primaryColor),
                          const SizedBox(width: 8),
                          Text(
                            activeJob.contactPhone ?? 'No phone provided',
                            style: const TextStyle(fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: () => _advanceStatus(activeJob),
                        style: ElevatedButton.styleFrom(
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text('NEXT STAGE'),
                            SizedBox(width: 8),
                            Icon(Icons.chevron_right),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 36),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor, style: BorderStyle.solid),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.directions_car_outlined, color: AppTheme.mutedForegroundColor.withValues(alpha: 0.3), size: 36),
                      const SizedBox(height: 12),
                      const Text(
                        'NO ACTIVE TASK ASSIGNED',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Claim a wash from the queue below to begin.',
                        style: TextStyle(color: AppTheme.mutedForegroundColor, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 32),

              // Available Queue Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'AVAILABLE TO CLAIM',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 14,
                      color: AppTheme.mutedForegroundColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  InkWell(
                    onTap: () {
                      setState(() {
                        _mineOnly = !_mineOnly;
                      });
                      _loadQueue();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: _mineOnly ? AppTheme.primaryColor.withValues(alpha: 0.15) : AppTheme.secondaryColor,
                        border: Border.all(
                          color: _mineOnly ? AppTheme.primaryColor : AppTheme.borderColor,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.person,
                            size: 14,
                            color: _mineOnly ? AppTheme.primaryColor : AppTheme.mutedForegroundColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            _mineOnly ? 'SHOWING MY ASSIGNED' : 'SHOW ALL ACTIVE',
                            style: GoogleFonts.bebasNeue(
                              fontSize: 11,
                              color: _mineOnly ? AppTheme.primaryColor : AppTheme.foregroundColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (available.isEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No unassigned vehicles in queue.',
                      style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                    ),
                  ),
                ),
              ] else ...[
                ...available.map((booking) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: ListTile(
                        leading: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.secondaryColor,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.directions_car, color: AppTheme.mutedForegroundColor),
                        ),
                        title: Text(
                          booking.vehicleNumber.toUpperCase(),
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Text(
                          '${WashData.packagePricing[booking.washPackage.toLowerCase()]?.name ?? booking.washPackage} • ${booking.timeSlot}\nPayment: ${booking.isPaid ? 'PAID' : 'UNPAID'}',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: ElevatedButton(
                          onPressed: activeJob != null ? null : () => _advanceStatus(booking),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.secondaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: Text(activeJob != null ? 'BUSY' : 'START WASH'),
                        ),
                      ),
                    )),
              ],
              const SizedBox(height: 32),

              // Other Activity Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'OTHER ACTIVITY',
                    style: GoogleFonts.bebasNeue(
                      fontSize: 14,
                      color: AppTheme.mutedForegroundColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  Row(
                    children: ['all', 'completed'].map((f) {
                      final isSelected = _filter == f;
                      return GestureDetector(
                        onTap: () => setState(() => _filter = f),
                        child: Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Text(
                            f.toUpperCase(),
                            style: GoogleFonts.bebasNeue(
                              fontSize: 12,
                              color: isSelected ? AppTheme.primaryColor : AppTheme.mutedForegroundColor,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Opacity(
                opacity: 0.7,
                child: Column(
                  children: filteredOther.isEmpty
                      ? [
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Text(
                              'No other activity logs.',
                              style: TextStyle(fontStyle: FontStyle.italic, fontSize: 13),
                            ),
                          )
                        ]
                      : filteredOther
                          .map((booking) => Container(
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.cardColor,
                                  border: Border.all(color: AppTheme.borderColor),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      _getStatusIcon(booking.status),
                                      color: WashData.statusColors[booking.status.toLowerCase()] ?? Colors.grey,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        '${booking.vehicleNumber.toUpperCase()} by ${booking.assignedStaff ?? "Unassigned"}',
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      (WashData.statusLabels[booking.status.toLowerCase()] ?? booking.status).toUpperCase(),
                                      style: TextStyle(
                                        color: WashData.statusColors[booking.status.toLowerCase()] ?? Colors.grey,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ))
                          .toList(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
