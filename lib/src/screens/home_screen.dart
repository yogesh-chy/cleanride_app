import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../config/app_theme.dart';
import '../models/wash_data.dart';
import '../widgets/cleanride_logo.dart';
import '../widgets/glow_button.dart';
import '../widgets/gradient_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({
    super.key,
    required this.isLoggedIn,
  });

  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppTheme.backgroundColor,
        surfaceTintColor: Colors.transparent,
        title: const CleanRideLogo(fontSize: 24),
        actions: [
          TextButton(
            onPressed: () {
              if (isLoggedIn) {
                context.go('/dashboard');
              } else {
                context.go('/login');
              }
            },
            child: Text(isLoggedIn ? 'DASHBOARD' : 'SIGN IN'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeroSection(context),
            _buildServicesSection(context),
            _buildPricingSection(context),
            _buildHowItWorksSection(context),
            _buildGallerySection(context),
            _buildContactSection(context),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 60),
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/hero-carwash.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.78),
            BlendMode.darken,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(100),
              border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.3)),
            ),
            child: Text(
              'REVOLUTIONIZING CAR CARE',
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 24),
          GradientText(
            'THE FUTURE OF CLEAN',
            gradient: AppTheme.primaryGradient,
            textAlign: TextAlign.center,
            style: GoogleFonts.bebasNeue(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'DRIVE TRANSFORMED',
            style: GoogleFonts.bebasNeue(
              fontSize: 28,
              letterSpacing: 1.0,
              color: Colors.white70,
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Premium car wash and detailing service powered by technology. Book, track, and pay seamlessly.',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.mutedForegroundColor,
                  ),
            ),
          ),
          const SizedBox(height: 32),
          GlowButton(
            onPressed: () {
              if (isLoggedIn) {
                context.go('/dashboard');
              } else {
                context.go('/login');
              }
            },
            width: 200,
            child: Text(isLoggedIn ? 'GO TO DASHBOARD' : 'BOOK YOUR WASH'),
          ),
        ],
      ),
    );
  }

  Widget _buildServicesSection(BuildContext context) {
    final services = [
      _ServiceItem(
        icon: Icons.local_car_wash,
        title: 'Exterior Detailing',
        desc: 'Advanced foam bath wash, hand dry, and premium paint protection.',
      ),
      _ServiceItem(
        icon: Icons.cleaning_services,
        title: 'Interior Deep Clean',
        desc: 'Steam cleaning, leather conditioning, vacuuming, and deodorizing.',
      ),
      _ServiceItem(
        icon: Icons.eco,
        title: 'Eco-Wash System',
        desc: 'Waterless wash option using biodegradable cleaning solutions.',
      ),
    ];

    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'OUR SERVICES',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Engineered for maximum shine and protection',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedForegroundColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...services.map((s) => Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(s.icon, color: AppTheme.primaryColor, size: 28),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              s.title,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              s.desc,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: AppTheme.mutedForegroundColor,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildPricingSection(BuildContext context) {
    return Container(
      color: AppTheme.cardColor.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'PRICING PLANS',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Select the package that fits your vehicle best',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedForegroundColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          ...WashData.packagePricing.entries.map((entry) {
            final key = entry.key;
            final pkg = entry.value;
            final isStandard = key == 'standard';

            return Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppTheme.cardColor,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isStandard ? AppTheme.primaryColor : AppTheme.borderColor,
                  width: isStandard ? 2 : 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        pkg.name.toUpperCase(),
                        style: GoogleFonts.bebasNeue(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: isStandard ? AppTheme.primaryColor : Colors.white,
                        ),
                      ),
                      if (isStandard)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'POPULAR',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.primaryForegroundColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        'Rs. ${pkg.price.toInt()}',
                        style: GoogleFonts.bebasNeue(
                          fontSize: 36,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '/ wash',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Duration: ~${pkg.duration} mins',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  const Divider(height: 32),
                  ...pkg.features.map((f) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          children: [
                            const Icon(Icons.check, color: AppTheme.primaryColor, size: 16),
                            const SizedBox(width: 8),
                            Text(f, style: Theme.of(context).textTheme.bodyMedium),
                          ],
                        ),
                      )),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      if (isLoggedIn) {
                        context.go('/dashboard');
                      } else {
                        context.go('/login');
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isStandard ? AppTheme.primaryColor : AppTheme.secondaryColor,
                      foregroundColor: isStandard ? AppTheme.primaryForegroundColor : Colors.white,
                    ),
                    child: const Text('BOOK NOW'),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildHowItWorksSection(BuildContext context) {
    final steps = [
      _StepItem(
        num: '01',
        title: 'BOOK A SLOT',
        desc: 'Select your vehicle type, pick a wash package, and reserve your time slot online.',
      ),
      _StepItem(
        num: '02',
        title: 'BRING VEHICLE',
        desc: 'Drive into our detailing bay or drop your vehicle with our team at your selected slot.',
      ),
      _StepItem(
        num: '03',
        title: 'SMART WASHING',
        desc: 'Monitor real-time progress of your wash from queued through to completed.',
      ),
      _StepItem(
        num: '04',
        title: 'DRIVE AWAY',
        desc: 'Inspect your premium finished vehicle, complete payments, and hit the road glowing.',
      ),
    ];

    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'HOW IT WORKS',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Simple four-step hassle-free booking and washing process',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedForegroundColor,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GridView.count(
            crossAxisCount: 1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            childAspectRatio: 2.2,
            mainAxisSpacing: 16,
            children: steps.map((s) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.num,
                          style: GoogleFonts.bebasNeue(
                            fontSize: 42,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor.withValues(alpha: 0.3),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                s.title,
                                style: GoogleFonts.bebasNeue(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  s.desc,
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        color: AppTheme.mutedForegroundColor,
                                      ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildGallerySection(BuildContext context) {
    final galleryItems = [
      {"src": "assets/images/gallery-1.jpg", "category": "Detailing"},
      {"src": "assets/images/gallery-2.jpg", "category": "Exterior Wash"},
      {"src": "assets/images/gallery-3.jpg", "category": "Bike Wash"},
      {"src": "assets/images/gallery-4.jpg", "category": "Interior"},
      {"src": "assets/images/gallery-5.jpg", "category": "Results"},
      {"src": "assets/images/gallery-6.jpg", "category": "Ceramic Coating"},
    ];

    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'OUR WORK',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.primaryColor,
                  letterSpacing: 3.0,
                  fontWeight: FontWeight.bold,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          GradientText(
            'OUR GALLERY',
            gradient: AppTheme.primaryGradient,
            textAlign: TextAlign.center,
            style: GoogleFonts.bebasNeue(
              fontSize: 36,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'See the quality of our work — from exterior washes to full ceramic coating applications.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.mutedForegroundColor,
                ),
          ),
          const SizedBox(height: 32),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: galleryItems.length,
            itemBuilder: (context, idx) {
              final item = galleryItems[idx];
              return GestureDetector(
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (context) => Dialog(
                      backgroundColor: Colors.transparent,
                      insetPadding: const EdgeInsets.all(12),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.asset(
                              item["src"]!,
                              fit: BoxFit.contain,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: IconButton(
                              icon: const Icon(Icons.close, color: Colors.white, size: 28),
                              onPressed: () => Navigator.pop(context),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: AppTheme.cardShadow,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.asset(
                          item["src"]!,
                          fit: BoxFit.cover,
                        ),
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                Colors.black.withValues(alpha: 0.8),
                                Colors.transparent,
                              ],
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 12,
                          left: 12,
                          right: 12,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.85),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  item["category"]!.toUpperCase(),
                                  style: GoogleFonts.bebasNeue(
                                    fontSize: 10,
                                    color: AppTheme.primaryForegroundColor,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildContactSection(BuildContext context) {
    return Container(
      color: AppTheme.cardColor.withValues(alpha: 0.4),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'GET IN TOUCH',
            style: Theme.of(context).textTheme.displayMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Row(
            children: [
              const Icon(Icons.location_on, color: AppTheme.primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'Kathmandu, Nepal',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.phone, color: AppTheme.primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  '+977 1 4400000',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.email, color: AppTheme.primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  'contact@cleanride.com.np',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      color: AppTheme.backgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: Column(
        children: [
          const CleanRideLogo(fontSize: 20),
          const SizedBox(height: 12),
          Text(
            '© 2026 CleanRide Inc. All rights reserved.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.mutedForegroundColor,
                ),
          ),
        ],
      ),
    );
  }
}

class _ServiceItem {
  _ServiceItem({
    required this.icon,
    required this.title,
    required this.desc,
  });

  final IconData icon;
  final String title;
  final String desc;
}

class _StepItem {
  _StepItem({
    required this.num,
    required this.title,
    required this.desc,
  });

  final String num;
  final String title;
  final String desc;
}
