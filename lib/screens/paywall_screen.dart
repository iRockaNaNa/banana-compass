import 'package:flutter/foundation.dart';
import 'package:material_ui/material_ui.dart';

import '../services/purchase_service.dart';

/// Go Premium: the two ways to unlock Premium, in plain words.
///
/// - Monthly: $0.99 a month, first 7 days free. (The free trial is set up
///   on the subscription in Google Play Console, not in this code.)
/// - Lifetime: $10 once, yours forever.
///
/// Until the products exist in Play Console, the screen says "Premium is
/// coming soon" and shows no buy buttons — the free app keeps working.
///
/// WEB: there is no Play Billing in a browser, so the web app is the
/// free tier. The paywall says so and points at the Android app — it
/// never shows buy buttons on web.
class PaywallScreen extends StatelessWidget {
  const PaywallScreen({super.key, required this.purchaseService});

  final PurchaseService purchaseService;

  static void open(BuildContext context, PurchaseService service) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PaywallScreen(purchaseService: service),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final service = purchaseService;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Go Premium'),
      ),
      body: SafeArea(
        child: ValueListenableBuilder<bool>(
          valueListenable: service.isPremium,
          builder: (context, isPremium, _) {
            if (isPremium) return _buildPremiumState(context);
            if (kIsWeb) return _buildWebOffer(context);
            return _buildOffer(context, service);
          },
        ),
      ),
    );
  }

  Widget _buildPremiumState(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 84,
            height: 84,
            decoration: BoxDecoration(
              color: scheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.star,
              color: scheme.onPrimary,
              size: 44,
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            "You're Premium!",
            style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 10),
          Text(
            'Thank you! You have the advanced forecast chart, the '
            'exclusive compass shapes, the wind indicator on the rose, '
            'the extended metrics, and faster refresh.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              color: scheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
          const SizedBox(height: 28),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 6),
                child: Text('Done', style: TextStyle(fontSize: 17)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Web: no store, no payments. The web app is the free tier, and
  /// Premium lives in the Android app.
  Widget _buildWebOffer(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Premium lives on Android',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'This web app is the free tier: the compass, the level, '
            'altitude, and the weather all work here. Premium — the '
            'advanced forecast chart, exclusive compass shapes, the '
            'wind indicator, extended metrics, and faster refresh — '
            'is part of the Banana Compass Android app.',
            style: TextStyle(
              fontSize: 15,
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          _featureList(context),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: scheme.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: scheme.primary,
                width: 1.5,
              ),
            ),
            child: Column(
              children: [
                Icon(Icons.phone_android, size: 36, color: scheme.primary),
                const SizedBox(height: 10),
                const Text(
                  'Get Banana Compass for Android',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'The Android app is coming to Google Play. Once it\'s '
                  'there, Premium is \$0.99 a month (first 7 days free) '
                  'or \$10 once, yours forever.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: scheme.onSurface.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'No ads in this app, ever — on web or on Android.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureList(BuildContext context) {
    const features = [
      'Advanced forecast chart',
      'Exclusive compass shapes and themes',
      'Wind direction on the compass rose',
      'Extended metrics: Feels Like, Dew Point, Visibility, Air Quality',
      'Faster weather and elevation refresh',
    ];
    return Column(
      children: [
        for (final feature in features)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Icon(
                  Icons.check,
                  size: 18,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(feature, style: const TextStyle(fontSize: 15)),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildOffer(BuildContext context, PurchaseService service) {
    final scheme = Theme.of(context).colorScheme;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Get the most out of your compass.',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            'Premium unlocks the advanced forecast chart, exclusive '
            'compass shapes and themes, the wind direction indicator on '
            'the rose, extended metrics (Feels Like, Dew Point, '
            'Visibility, Air Quality), and faster weather and elevation '
            'refresh. The compass, level, altitude, and weather stay free.',
            style: TextStyle(
              fontSize: 15,
              color: scheme.onSurface.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 20),
          ValueListenableBuilder<bool>(
            valueListenable: service.productsReady,
            builder: (context, productsReady, _) {
              if (!productsReady) return _buildComingSoon(context);
              return Column(
                children: [
                  _buildOptionCard(
                    context: context,
                    service: service,
                    title: 'Monthly',
                    price: service.monthlyPrice ?? '\$0.99',
                    priceSuffix: '/month',
                    points: const [
                      'First 7 days free',
                      'Then \$0.99 a month',
                      'Cancel anytime',
                    ],
                    buttonLabel: 'Start free trial',
                    onBuy: () => _buy(context, service, true),
                  ),
                  const SizedBox(height: 14),
                  _buildOptionCard(
                    context: context,
                    service: service,
                    title: 'Lifetime',
                    price: service.lifetimePrice ?? '\$10',
                    priceSuffix: 'once',
                    points: const [
                      'Pay once, yours forever',
                      'No monthly payments',
                      'Same Premium as monthly',
                    ],
                    buttonLabel: 'Buy lifetime',
                    onBuy: () => _buy(context, service, false),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 16),
          ValueListenableBuilder<bool>(
            valueListenable: service.purchaseInProgress,
            builder: (context, inProgress, _) {
              if (!inProgress) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 10),
                    Text('Working with the store…'),
                  ],
                ),
              );
            },
          ),
          ValueListenableBuilder<String?>(
            valueListenable: service.lastError,
            builder: (context, error, _) {
              if (error == null || error.isEmpty) {
                return const SizedBox.shrink();
              }
              return Container(
                width: double.infinity,
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDECEA),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(error, style: const TextStyle(fontSize: 14)),
              );
            },
          ),
          Center(
            child: TextButton(
              onPressed: () => _restore(context, service),
              child: const Text('Restore purchases'),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Payments go through Google Play. No ads in this app, ever.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: Color(0xFF888888)),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        children: [
          Icon(Icons.hourglass_top, size: 36, color: scheme.primary),
          const SizedBox(height: 10),
          const Text(
            'Premium is coming soon',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Premium is not in the store yet. Everything free keeps '
            'working — check back soon.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: scheme.onSurface.withValues(alpha: 0.75),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required PurchaseService service,
    required String title,
    required String price,
    required String priceSuffix,
    required List<String> points,
    required String buttonLabel,
    required VoidCallback onBuy,
  }) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border.all(color: scheme.primary, width: 1.5),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                price,
                style: const TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                priceSuffix,
                style: TextStyle(
                  fontSize: 15,
                  color: scheme.onSurface.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          for (final point in points)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(Icons.check, size: 18, color: scheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(point, style: const TextStyle(fontSize: 15)),
                  ),
                ],
              ),
            ),
          const SizedBox(height: 12),
          ValueListenableBuilder<bool>(
            valueListenable: service.purchaseInProgress,
            builder: (context, inProgress, _) {
              return SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: inProgress ? null : onBuy,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      buttonLabel,
                      style: const TextStyle(fontSize: 16),
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

  Future<void> _buy(
    BuildContext context,
    PurchaseService service,
    bool monthly,
  ) async {
    final ok =
        monthly ? await service.buyMonthly() : await service.buyLifetime();
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Premium isn't available right now. Try again later."),
        ),
      );
    }
  }

  Future<void> _restore(
    BuildContext context,
    PurchaseService service,
  ) async {
    final found = await service.restorePurchases();
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          found
              ? "Welcome back — you're Premium!"
              : 'Nothing to restore on this account.',
        ),
      ),
    );
  }
}
