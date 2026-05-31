import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../config/app_theme.dart';
import '../models/wash_data.dart';
import '../widgets/cleanride_logo.dart';
import '../widgets/gradient_text.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key, required this.isLoggedIn});

  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 108),
          children: [
            Row(
              children: [
                const CleanRideLogo(fontSize: 24),
                const Spacer(),
                IconButton.filledTonal(
                  tooltip: isLoggedIn ? 'Open dashboard' : 'Sign in',
                  onPressed: () =>
                      context.go(isLoggedIn ? '/dashboard' : '/login'),
                  icon: Icon(
                    isLoggedIn ? Icons.dashboard_outlined : Icons.login,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _HeroCard(isLoggedIn: isLoggedIn),
            const SizedBox(height: 18),
            const Row(
              children: [
                Expanded(
                  child: _QuickStat(
                    icon: Icons.flash_on_outlined,
                    title: 'Fast slots',
                    value: '30 min',
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _QuickStat(
                    icon: Icons.verified_outlined,
                    title: 'Live status',
                    value: 'Tracked',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _SectionHeader(
              title: 'Wash packages',
              actionLabel: isLoggedIn ? 'Book' : 'Sign in',
              onAction: () => context.go(isLoggedIn ? '/dashboard' : '/login'),
            ),
            const SizedBox(height: 12),
            ...WashData.packagePricing.entries.map(
              (entry) => _PackageTile(
                title: entry.value.name,
                price: entry.value.price.toInt(),
                duration: entry.value.duration,
                popular: entry.key == 'standard',
              ),
            ),
            const SizedBox(height: 20),
            const _SectionHeader(title: 'How it works'),
            const SizedBox(height: 12),
            const _StepTile(
              icon: Icons.calendar_month_outlined,
              title: 'Book a slot',
              subtitle: 'Choose package, date, and time.',
            ),
            const _StepTile(
              icon: Icons.local_car_wash_outlined,
              title: 'Track the wash',
              subtitle: 'Follow queue and cleaning status live.',
            ),
            const _StepTile(
              icon: Icons.payments_outlined,
              title: 'Pay and go',
              subtitle: 'Confirm details and complete payment.',
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
          child: FilledButton.icon(
            onPressed: () => context.go(isLoggedIn ? '/dashboard' : '/login'),
            icon: Icon(isLoggedIn ? Icons.dashboard : Icons.local_car_wash),
            label: Text(isLoggedIn ? 'Open dashboard' : 'Book your wash'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(54),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.isLoggedIn});

  final bool isLoggedIn;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 360,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: AppTheme.borderColor),
        image: DecorationImage(
          image: const AssetImage('assets/images/hero-carwash.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withValues(alpha: 0.48),
            BlendMode.darken,
          ),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.14),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: AppTheme.primaryColor.withValues(alpha: 0.26),
                ),
              ),
              child: const Text(
                'Premium car care',
                style: TextStyle(
                  color: AppTheme.primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const Spacer(),
            GradientText(
              'Clean ride,\nless waiting.',
              gradient: AppTheme.primaryGradient,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                fontSize: 42,
                height: 0.95,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Book a wash, track your vehicle, and handle payment from one mobile dashboard.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.secondaryForegroundColor,
                height: 1.45,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickStat extends StatelessWidget {
  const _QuickStat({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppTheme.primaryColor),
          const SizedBox(height: 16),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 2),
          Text(title, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _PackageTile extends StatelessWidget {
  const _PackageTile({
    required this.title,
    required this.price,
    required this.duration,
    required this.popular,
  });

  final String title;
  final int price;
  final int duration;
  final bool popular;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: popular
            ? AppTheme.primaryColor.withValues(alpha: 0.08)
            : AppTheme.cardColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: popular
              ? AppTheme.primaryColor.withValues(alpha: 0.55)
              : AppTheme.borderColor,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
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
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                    ),
                    if (popular) ...[
                      const SizedBox(width: 8),
                      const _PopularBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '~$duration min service',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            'Rs. $price',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: AppTheme.primaryColor,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _PopularBadge extends StatelessWidget {
  const _PopularBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Popular',
        style: TextStyle(
          color: AppTheme.primaryForegroundColor,
          fontSize: 10,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _StepTile extends StatelessWidget {
  const _StepTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: AppTheme.secondaryColor,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppTheme.primaryColor),
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
                  ),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
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
