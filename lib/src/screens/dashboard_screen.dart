import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../models/app_user.dart';
import '../models/booking.dart';
import '../models/wash_data.dart';
import '../services/booking_service.dart';
import '../widgets/booking_card.dart';
import '../widgets/cleanride_logo.dart';
import '../widgets/stat_card.dart';
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
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _loadBookings();
    // Auto-polling every 30 seconds
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _loadBookings());
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
        setState(() {
          _bookings = list;
        });
      }
    } catch (e) {
      // Failed to load bookings silently or handled by reload
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
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
            Navigator.pop(context); // Close sheet
            _loadBookings(); // Refresh bookings
            // Redirect to checkout
            context.go('/dashboard/checkout/$bookingId');
          },
        );
      },
    );
  }

  void _showBookingDetails(Booking booking) {
    showDialog(
      context: context,
      builder: (context) {
        final pkg = WashData.packagePricing[booking.washPackage.toLowerCase()];
        final packageName = pkg?.name ?? booking.washPackage;
        final price = pkg?.price ?? 1000.0;

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
                'BOOKING DETAILS',
                style: GoogleFonts.bebasNeue(
                  letterSpacing: 1.0,
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
                _buildDetailRow('Vehicle Number', booking.vehicleNumber.toUpperCase()),
                _buildDetailRow('Vehicle Type', WashData.vehicleTypeLabels[booking.vehicleType] ?? booking.vehicleType),
                _buildDetailRow('Package', packageName),
                _buildDetailRow('Price', 'Rs. ${price.toInt()}'),
                _buildDetailRow('Scheduled Date', booking.date),
                _buildDetailRow('Scheduled Time', booking.timeSlot),
                _buildDetailRow('Status', WashData.statusLabels[booking.status.toLowerCase()] ?? booking.status),
                _buildDetailRow('Phone', booking.contactPhone ?? 'Not provided'),
                _buildDetailRow('Address', booking.address ?? 'Not provided'),
                if (booking.assignedStaff != null && booking.assignedStaff!.isNotEmpty)
                  _buildDetailRow('Assigned Staff', booking.assignedStaff!),
                if (booking.estimatedTime != null && booking.estimatedTime! > 0)
                  _buildDetailRow('Est. Time', '${booking.estimatedTime} min'),
                const Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Payment Status',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mutedForegroundColor,
                          ),
                    ),
                    if (booking.isPaid)
                      const Row(
                        children: [
                          Icon(Icons.shield_outlined, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'PAID',
                            style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          context.go('/dashboard/checkout/${booking.id}');
                        },
                        icon: const Icon(Icons.credit_card, size: 14),
                        label: const Text('PAY NOW'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF5C2D91),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
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
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(color: AppTheme.mutedForegroundColor, fontSize: 13),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final activeBookings = _bookings.where((b) {
      final clean = b.status.toLowerCase();
      return clean != 'completed' && clean != 'cancelled';
    }).toList();

    final completedBookings = _bookings.where((b) => b.status.toLowerCase() == 'completed').toList();

    // Stats calculations
    final completedCount = completedBookings.length;
    final totalSpent = completedBookings.fold<double>(0.0, (sum, b) {
      final pkg = WashData.packagePricing[b.washPackage.toLowerCase()];
      return sum + (pkg?.price ?? 0.0);
    });

    final loyaltyTier = completedCount >= 10
        ? 'GOLD'
        : completedCount >= 5
            ? 'SILVER'
            : 'BRONZE';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const CleanRideLogo(fontSize: 24),
        actions: [
          IconButton(
            tooltip: 'My Profile',
            onPressed: () => context.go('/profile'),
            icon: const Icon(Icons.person_outline),
          ),
          IconButton(
            tooltip: 'Sign out',
            onPressed: () async {
              await widget.onLogout();
              if (context.mounted) context.go('/');
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadBookings,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Welcome & Action Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'WELCOME,',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 14,
                            color: AppTheme.primaryColor,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Text(
                          widget.user.name.split(' ')[0].toUpperCase(),
                          style: GoogleFonts.bebasNeue(
                            fontSize: 32,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showBookingForm,
                    icon: const Icon(Icons.add),
                    label: const Text('BOOK A WASH'),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Stats Row
              Row(
                children: [
                  Expanded(
                    child: StatCard(
                      title: 'ACTIVE',
                      value: '${activeBookings.length}',
                      icon: Icons.schedule,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'SPENT',
                      value: 'Rs. ${totalSpent.toInt()}',
                      icon: Icons.payments_outlined,
                      iconColor: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: StatCard(
                      title: 'LOYALTY',
                      value: loyaltyTier,
                      icon: Icons.star_border,
                      iconColor: Colors.amber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Live Vehicle Status (Active Bookings)
              if (activeBookings.isNotEmpty) ...[
                Text(
                  'LIVE VEHICLE STATUS',
                  style: GoogleFonts.bebasNeue(
                    fontSize: 16,
                    color: AppTheme.foregroundColor,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 12),
                ...activeBookings.map((b) => BookingCard(
                      booking: b,
                      onTap: () => _showBookingDetails(b),
                    )),
                const SizedBox(height: 32),
              ],

              // Booking History
              Text(
                'BOOKING HISTORY',
                style: GoogleFonts.bebasNeue(
                  fontSize: 16,
                  color: AppTheme.foregroundColor,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 12),
              if (_bookings.isEmpty)
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: AppTheme.cardColor,
                    border: Border.all(color: AppTheme.borderColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.local_car_wash_outlined, color: AppTheme.mutedForegroundColor, size: 48),
                      const SizedBox(height: 16),
                      Text(
                        'NO BOOKINGS YET',
                        style: GoogleFonts.bebasNeue(fontSize: 20, letterSpacing: 1.0),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "You haven't booked any washes with CleanRide yet.",
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppTheme.mutedForegroundColor, fontSize: 13),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton(
                        onPressed: _showBookingForm,
                        child: const Text('MAKE YOUR FIRST BOOKING'),
                      ),
                    ],
                  ),
                )
              else
                ..._bookings.map((b) => BookingCard(
                      booking: b,
                      onTap: () => _showBookingDetails(b),
                    )),
            ],
          ),
        ),
      ),
    );
  }
}
