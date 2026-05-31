import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/time_slot.dart';
import '../models/wash_data.dart';
import '../services/booking_service.dart';
import '../widgets/glow_button.dart';

class BookingFormSheet extends StatefulWidget {
  const BookingFormSheet({
    super.key,
    required this.bookingService,
    required this.onBookingCreated,
  });

  final BookingService bookingService;
  final ValueChanged<String> onBookingCreated; // Returns booking ID on success

  @override
  State<BookingFormSheet> createState() => _BookingFormSheetState();
}

class _BookingFormSheetState extends State<BookingFormSheet> {
  final _formKey = GlobalKey<FormState>();
  final _numberController = TextEditingController();
  
  String _vehicleType = 'car';
  String _washPackage = 'standard';
  DateTime? _selectedDate;
  String? _selectedSlot;

  List<TimeSlot> _slots = [];
  bool _loadingSlots = false;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    _numberController.dispose();
    super.dispose();
  }

  Future<void> _fetchSlots() async {
    if (_selectedDate == null) return;
    setState(() {
      _loadingSlots = true;
      _slots = [];
      _selectedSlot = null;
      _error = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final list = await widget.bookingService.fetchSlots(dateStr, _washPackage);
      setState(() {
        _slots = list;
      });
    } catch (e) {
      setState(() {
        _error = 'Failed to load available slots.';
      });
    } finally {
      setState(() {
        _loadingSlots = false;
      });
    }
  }

  Future<void> _selectDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 30)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppTheme.primaryColor,
              onPrimary: AppTheme.primaryForegroundColor,
              surface: AppTheme.cardColor,
              onSurface: AppTheme.foregroundColor,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
      _fetchSlots();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null || _selectedSlot == null) return;

    setState(() {
      _submitting = true;
      _error = null;
    });

    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      final booking = await widget.bookingService.createBooking(
        vehicleType: _vehicleType,
        vehicleNumber: _numberController.text.trim(),
        washPackage: _washPackage,
        date: dateStr,
        timeSlot: _selectedSlot!,
      );
      widget.onBookingCreated(booking.id);
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _submitting = false;
      });
    }
  }

  Map<String, List<TimeSlot>> _categorizeSlots() {
    final Map<String, List<TimeSlot>> categorized = {
      'Morning': [],
      'Afternoon': [],
      'Evening': [],
    };

    for (final slot in _slots) {
      try {
        final timeParts = slot.time.split(':');
        final hour = int.parse(timeParts[0]);
        final isPM = slot.time.toUpperCase().contains('PM');
        final hour24 = (isPM && hour != 12) ? hour + 12 : (!isPM && hour == 12 ? 0 : hour);

        if (hour24 < 12) {
          categorized['Morning']!.add(slot);
        } else if (hour24 < 16) {
          categorized['Afternoon']!.add(slot);
        } else {
          categorized['Evening']!.add(slot);
        }
      } catch (_) {
        // Fallback to Evening if parsing fails
        categorized['Evening']!.add(slot);
      }
    }

    return categorized;
  }

  @override
  Widget build(BuildContext context) {
    final categorized = _categorizeSlots();

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'NEW BOOKING',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 24,
                        color: AppTheme.foregroundColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),
                
                // Vehicle Type
                Text(
                  'Vehicle Type',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedForegroundColor,
                      ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: WashData.vehicleTypeLabels.entries.map((entry) {
                    final vt = entry.key;
                    final label = entry.value;
                    final isSelected = _vehicleType == vt;

                    return Expanded(
                      child: Container(
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        child: OutlinedButton(
                          onPressed: () => setState(() => _vehicleType = vt),
                          style: OutlinedButton.styleFrom(
                            backgroundColor: isSelected ? AppTheme.primaryColor : Colors.transparent,
                            foregroundColor: isSelected ? AppTheme.primaryForegroundColor : Colors.white,
                            side: BorderSide(
                              color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                            ),
                          ),
                          child: Text(label),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // Vehicle Number
                TextFormField(
                  controller: _numberController,
                  decoration: const InputDecoration(
                    labelText: 'Vehicle Number',
                    hintText: 'e.g. BA 1 KHA 2345',
                    prefixIcon: Icon(Icons.directions_car_outlined),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Please enter vehicle number';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Package Selection
                Text(
                  'Select Package',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mutedForegroundColor,
                      ),
                ),
                const SizedBox(height: 8),
                ...WashData.packagePricing.entries.map((entry) {
                  final pkg = entry.key;
                  final info = entry.value;
                  final isSelected = _washPackage == pkg;

                  return GestureDetector(
                    onTap: () {
                      setState(() => _washPackage = pkg);
                      if (_selectedDate != null) _fetchSlots();
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.cardColor,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                          width: isSelected ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  info.name,
                                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                                Text(
                                  'Duration: ~${info.duration} mins',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          Text(
                            'Rs. ${info.price.toInt()}',
                            style: GoogleFonts.bebasNeue(
                              fontSize: 22,
                              color: AppTheme.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // Date Picker
                Text(
                  '1. Pick a Date',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _selectedDate == null
                              ? 'SELECT DATE'
                              : DateFormat('yyyy-MM-dd').format(_selectedDate!),
                          style: GoogleFonts.bebasNeue(
                            fontSize: 18,
                            letterSpacing: 1.0,
                            color: Colors.white,
                          ),
                        ),
                        const Icon(Icons.calendar_month, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Time Slot Grid
                Text(
                  '2. Choose Time',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const SizedBox(height: 8),
                if (_selectedDate == null)
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppTheme.cardColor,
                      border: Border.all(color: AppTheme.borderColor, style: BorderStyle.solid),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      children: [
                        Icon(Icons.schedule, color: AppTheme.mutedForegroundColor.withValues(alpha: 0.5), size: 36),
                        const SizedBox(height: 8),
                        Text(
                          'PLEASE SELECT A DATE FIRST',
                          style: GoogleFonts.bebasNeue(
                            color: AppTheme.mutedForegroundColor,
                            fontSize: 16,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  )
                else if (_loadingSlots)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else
                  ...categorized.entries.map((catEntry) {
                    final period = catEntry.key;
                    final slots = catEntry.value;
                    if (slots.isEmpty) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 8.0, bottom: 6.0),
                          child: Text(
                            period.toUpperCase(),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: AppTheme.mutedForegroundColor,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.0,
                                ),
                          ),
                        ),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 2.2,
                          ),
                          itemCount: slots.length,
                          itemBuilder: (context, idx) {
                            final slot = slots[idx];
                            final isSelected = _selectedSlot == slot.time;
                            final isDisabled = !slot.available;

                            return InkWell(
                              onTap: isDisabled ? null : () => setState(() => _selectedSlot = slot.time),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? AppTheme.primaryColor
                                      : isDisabled
                                          ? AppTheme.secondaryColor.withValues(alpha: 0.3)
                                          : AppTheme.cardColor,
                                  border: Border.all(
                                    color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  slot.time,
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color: isSelected
                                            ? AppTheme.primaryForegroundColor
                                            : isDisabled
                                                ? AppTheme.mutedForegroundColor.withValues(alpha: 0.3)
                                                : AppTheme.foregroundColor,
                                        fontWeight: FontWeight.bold,
                                      ),
                                ),
                              ),
                            );
                          },
                        ),
                      ],
                    );
                  }),
                const SizedBox(height: 18),
                if (_error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.destructiveColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(_error!, style: const TextStyle(color: AppTheme.destructiveColor)),
                  ),
                  const SizedBox(height: 14),
                ],
                GlowButton(
                  onPressed: (_selectedSlot == null || _submitting) ? null : _submit,
                  isLoading: _submitting,
                  child: Text(
                    _selectedSlot != null
                        ? 'CONFIRM AT $_selectedSlot'
                        : 'SELECT A TIME',
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
