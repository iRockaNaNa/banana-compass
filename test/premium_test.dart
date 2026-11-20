import 'package:banana_compass/services/premium.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PremiumRules', () {
    test('product ids are the Banana Compass products', () {
      expect(
        PremiumRules.monthlyProductId,
        'banana_premium_monthly',
      );
      expect(
        PremiumRules.lifetimeProductId,
        'banana_premium_lifetime',
      );
      expect(PremiumRules.productIds, hasLength(2));
    });

    test('everything Premium is locked on the free tier', () {
      const isPremium = false;
      expect(
        PremiumRules.isChartsLocked(isPremium: isPremium),
        isTrue,
      );
      expect(
        PremiumRules.isCompassShapesLocked(isPremium: isPremium),
        isTrue,
      );
      expect(
        PremiumRules.isWindIndicatorLocked(isPremium: isPremium),
        isTrue,
      );
      expect(
        PremiumRules.isExtendedMetricsLocked(isPremium: isPremium),
        isTrue,
      );
      expect(
        PremiumRules.isFastRefreshLocked(isPremium: isPremium),
        isTrue,
      );
    });

    test('everything Premium is unlocked for Premium users', () {
      const isPremium = true;
      expect(
        PremiumRules.isChartsLocked(isPremium: isPremium),
        isFalse,
      );
      expect(
        PremiumRules.isCompassShapesLocked(isPremium: isPremium),
        isFalse,
      );
      expect(
        PremiumRules.isWindIndicatorLocked(isPremium: isPremium),
        isFalse,
      );
      expect(
        PremiumRules.isExtendedMetricsLocked(isPremium: isPremium),
        isFalse,
      );
      expect(
        PremiumRules.isFastRefreshLocked(isPremium: isPremium),
        isFalse,
      );
    });
  });

  group('PremiumEntitlement', () {
    test('round-trips through JSON', () {
      final entitlement = PremiumEntitlement(
        productId: PremiumRules.lifetimeProductId,
        grantedAt: DateTime.utc(2026, 11, 20),
      );
      final restored =
          PremiumEntitlement.fromJson(entitlement.toJson());
      expect(restored.productId, entitlement.productId);
      expect(restored.grantedAt, entitlement.grantedAt);
      expect(restored.isValid, isTrue);
    });

    test('an unknown product id is not a valid entitlement', () {
      final entitlement = PremiumEntitlement(
        productId: 'someone_elses_product',
        grantedAt: DateTime.now(),
      );
      expect(entitlement.isValid, isFalse);
    });
  });
}
