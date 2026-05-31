import 'package:flutter/material.dart';
import '../config/app_theme.dart';
import '../models/booking.dart';
import '../models/wash_data.dart';
import 'status_badge.dart';

class BookingCard extends StatelessWidget {
  const BookingCard({
    super.key,
    required this.booking,
    this.onTap,
  });

  final Booking booking;
  final VoidCallback? onTap;

  double _getProgress(String status) {
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
        return 1.0;
      default:
        return 0.0;
    }
  }

  IconData _getVehicleIcon(String type) {
    switch (type.toLowerCase()) {
      case 'bike':
        return Icons.motorcycle;
      case 'suv':
        return Icons.directions_car_filled;
      case 'car':
      default:
        return Icons.directions_car;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _getProgress(booking.status);
    final isCancelled = booking.status.toLowerCase() == 'cancelled';
    final packageInfo = WashData.packagePricing[booking.washPackage.toLowerCase()];
    final packageName = packageInfo?.name ?? booking.washPackage;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Icon(
                    _getVehicleIcon(booking.vehicleType),
                    color: AppTheme.primaryColor,
                    size: 24,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.vehicleNumber.toUpperCase(),
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                  ),
                  const Spacer(),
                  StatusBadge(status: booking.status),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Text(
                    packageName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.foregroundColor,
                          fontWeight: FontWeight.w500,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    booking.date,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    booking.timeSlot,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    booking.isPaid ? Icons.check_circle_outline : Icons.error_outline,
                    color: booking.isPaid ? Colors.green : Colors.amber,
                    size: 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    booking.isPaid ? 'Paid' : 'Unpaid',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: booking.isPaid ? Colors.green : Colors.amber,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  if (booking.queuePosition != null && booking.queuePosition! > 0 && !isCancelled && booking.status != 'completed') ...[
                    const Spacer(),
                    const Icon(
                      Icons.people_outline,
                      color: AppTheme.mutedForegroundColor,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Queue Position: ${booking.queuePosition}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
              if (!isCancelled && booking.status != 'completed' && progress > 0.0) ...[
                const SizedBox(height: 16),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Wash Progress',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.mutedForegroundColor,
                              ),
                        ),
                        Text(
                          '${(progress * 100).toInt()}%',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6,
                        backgroundColor: AppTheme.secondaryColor,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
