import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../config/app_theme.dart';
import '../models/booking.dart';
import '../models/wash_data.dart';
import '../services/booking_service.dart';
import '../services/payment_service.dart';
import '../widgets/glow_button.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({
    super.key,
    required this.bookingId,
    required this.bookingService,
    required this.paymentService,
  });

  final String bookingId;
  final BookingService bookingService;
  final PaymentService paymentService;

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();

  Booking? _booking;
  bool _loading = true;
  bool _paying = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadBooking();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _loadBooking() async {
    try {
      final b = await widget.bookingService.fetchBookingById(widget.bookingId);
      if (b != null) {
        setState(() {
          _booking = b;
          _phoneController.text = b.contactPhone ?? '';
          _addressController.text = b.address ?? '';
        });
      } else {
        setState(() {
          _error = 'Booking not found.';
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load booking details.';
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  Future<void> _initiateKhaltiPayment() async {
    if (!_formKey.currentState!.validate()) return;
    if (_booking == null) return;

    setState(() {
      _paying = true;
      _error = null;
    });

    try {
      // 1. Update booking contact info
      await widget.bookingService.updateBooking(_booking!.id, {
        'contact_phone': _phoneController.text.trim(),
        'address': _addressController.text.trim(),
      });

      final result = await widget.paymentService.initiatePayment(
        bookingId: _booking!.id,
        returnUrl: ApiConfig.paymentReturnUrl,
      );

      final paymentUrl = result['payment_url'] as String?;
      final pidx = result['pidx'] as String?;

      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        final uri = Uri.parse(paymentUrl);
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);

          if (mounted) {
            _showVerificationDialog(pidx);
          }
        } else {
          throw 'Could not launch payment portal.';
        }
      } else {
        throw 'Payment portal URL not returned.';
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _paying = false;
      });
    }
  }

  void _showVerificationDialog(String? pidx) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        bool verifying = false;
        String? dialogError;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.cardColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.borderColor),
              ),
              title: Text(
                'PAYMENT IN PROGRESS',
                style: GoogleFonts.bebasNeue(
                  letterSpacing: 1.0,
                  color: AppTheme.foregroundColor,
                ),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.payment,
                    color: AppTheme.primaryColor,
                    size: 48,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'We opened the Khalti portal in your browser. Once you complete the payment, tap below to verify.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.mutedForegroundColor,
                    ),
                  ),
                  if (dialogError != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      dialogError!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppTheme.destructiveColor,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (verifying) ...[
                    const SizedBox(height: 16),
                    const CircularProgressIndicator(),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: verifying
                      ? null
                      : () {
                          Navigator.pop(context);
                        },
                  child: const Text('CANCEL'),
                ),
                ElevatedButton(
                  onPressed: verifying
                      ? null
                      : () async {
                          setDialogState(() {
                            verifying = true;
                            dialogError = null;
                          });

                          try {
                            // 1. Verify with backend using pidx if present, or check booking paid status directly
                            if (pidx != null && pidx.isNotEmpty) {
                              try {
                                await widget.paymentService.verifyPayment(
                                  pidx: pidx,
                                );
                              } catch (_) {
                                // Ignore verify error and check booking directly as fallback
                              }
                            }

                            // 2. Fetch booking status
                            final b = await widget.bookingService
                                .fetchBookingById(widget.bookingId);
                            if (b != null && b.isPaid) {
                              if (context.mounted) {
                                Navigator.pop(context); // Close dialog
                                context.go('/dashboard'); // Go to dashboard
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      'Payment verified successfully!',
                                    ),
                                    backgroundColor: Colors.green,
                                  ),
                                );
                              }
                            } else {
                              setDialogState(() {
                                dialogError =
                                    'Payment not completed or verified yet. Please try again.';
                                verifying = false;
                              });
                            }
                          } catch (e) {
                            setDialogState(() {
                              dialogError = 'Verification failed. Try again.';
                              verifying = false;
                            });
                          }
                        },
                  child: const Text('I HAVE PAID'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_error != null || _booking == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('CHECKOUT'),
          backgroundColor: AppTheme.backgroundColor,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: AppTheme.destructiveColor,
                  size: 48,
                ),
                const SizedBox(height: 16),
                Text(
                  _error ?? 'An error occurred.',
                  style: const TextStyle(color: AppTheme.destructiveColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => context.go('/dashboard'),
                  child: const Text('BACK TO DASHBOARD'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final pkg = WashData.packagePricing[_booking!.washPackage.toLowerCase()];
    final packageName = pkg?.name ?? _booking!.washPackage;
    final price = pkg?.price ?? 1000.0;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'CONFIRM & PAY',
          style: GoogleFonts.bebasNeue(letterSpacing: 1.0),
        ),
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Summary Card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.cardColor,
                  border: Border.all(color: AppTheme.borderColor),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: AppTheme.cardShadow,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'BOOKING SUMMARY',
                      style: GoogleFonts.bebasNeue(
                        fontSize: 18,
                        color: AppTheme.primaryColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildSummaryRow(
                      'Vehicle Number',
                      _booking!.vehicleNumber.toUpperCase(),
                    ),
                    _buildSummaryRow(
                      'Vehicle Type',
                      WashData.vehicleTypeLabels[_booking!.vehicleType] ??
                          _booking!.vehicleType,
                    ),
                    _buildSummaryRow('Wash Package', packageName),
                    _buildSummaryRow('Scheduled Date', _booking!.date),
                    _buildSummaryRow('Scheduled Time', _booking!.timeSlot),
                    const Divider(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Net Payable',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.mutedForegroundColor),
                        ),
                        Text(
                          'Rs. ${price.toInt()}',
                          style: GoogleFonts.bebasNeue(
                            fontSize: 24,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Contact Details Form
              Text(
                'CONTACT & SERVICE INFO',
                style: GoogleFonts.bebasNeue(
                  fontSize: 18,
                  color: AppTheme.foregroundColor,
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Mobile Number',
                  prefixText: '+977 ',
                  prefixIcon: Icon(Icons.phone),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter mobile number';
                  }
                  if (value.trim().length < 10) {
                    return 'Please enter a valid 10-digit number';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _addressController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Service / Pickup Address',
                  prefixIcon: Padding(
                    padding: EdgeInsets.only(bottom: 40.0),
                    child: Icon(Icons.map),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter your address';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              if (_error != null) ...[
                Text(
                  _error!,
                  style: const TextStyle(color: AppTheme.destructiveColor),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 14),
              ],
              GlowButton(
                onPressed: _paying ? null : _initiateKhaltiPayment,
                isLoading: _paying,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.payment, size: 20),
                    const SizedBox(width: 8),
                    Text('PAY Rs. ${price.toInt()} WITH KHALTI'),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => context.go('/dashboard'),
                child: const Text('CANCEL & RETURN'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.mutedForegroundColor,
              fontSize: 13,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
