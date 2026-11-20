/// Premium rules for Banana Compass — pure Dart, no store access.
///
/// Free tier: the compass (True/Magnetic North, coordinates, mils), the
/// level tool, altitude + pressure, and current weather + hourly forecast.
/// Premium unlocks the extras: advanced forecast charts, exclusive
/// compass shapes and themes, the wind direction indicator on the rose,
/// extended metrics (Feels Like, Dew Point, Visibility, Air Quality),
/// and faster weather/elevation refresh.
///
/// Premium can be bought two ways, same unlock either way:
/// - `banana_premium_monthly`: $0.99/month subscription. The 7-day free
///   trial is configured on the subscription in Google Play Console —
///   there is no trial logic in this code.
/// - `banana_premium_lifetime`: $10 one-time purchase, yours forever.
///
/// On the web app there is no Play Billing, so Premium never unlocks
/// there: the web app is the free tier, and the paywall points at the
/// Android app instead (see PurchaseService).
///
/// There are NO ads in this app, ever.
class PremiumRules {
  /// Product id for the $0.99/month subscription.
  static const monthlyProductId = 'banana_premium_monthly';

  /// Product id for the $10 one-time lifetime license.
  static const lifetimeProductId = 'banana_premium_lifetime';

  /// Both product ids the store is asked about.
  static const productIds = {monthlyProductId, lifetimeProductId};

  /// Is the advanced forecast chart locked for this user?
  static bool isChartsLocked({required bool isPremium}) => !isPremium;

  /// Are the exclusive compass shapes and themes locked?
  static bool isCompassShapesLocked({required bool isPremium}) =>
      !isPremium;

  /// Is the wind direction indicator on the compass rose locked?
  static bool isWindIndicatorLocked({required bool isPremium}) =>
      !isPremium;

  /// Are the extended metrics (Feels Like, Dew Point, Visibility,
  /// Air Quality) locked?
  static bool isExtendedMetricsLocked({required bool isPremium}) =>
      !isPremium;

  /// Is the faster weather/elevation refresh locked?
  static bool isFastRefreshLocked({required bool isPremium}) => !isPremium;
}

/// A saved record that this device owns Premium.
///
/// Kept in SharedPreferences so a paying user stays Premium even when the
/// store can't be reached (offline, or the app isn't on the store yet).
/// A record only ever exists because a real purchase (or restore) created
/// it — with no record and no store confirmation, the user is free tier.
class PremiumEntitlement {
  const PremiumEntitlement({
    required this.productId,
    required this.grantedAt,
  });

  /// The product that granted Premium: one of [PremiumRules.productIds].
  final String productId;

  /// When the purchase (or restore) happened.
  final DateTime grantedAt;

  Map<String, dynamic> toJson() => {
        'productId': productId,
        'grantedAt': grantedAt.toIso8601String(),
      };

  factory PremiumEntitlement.fromJson(Map<String, dynamic> json) {
    final productId = json['productId'] as String? ?? '';
    final grantedAtRaw = json['grantedAt'] as String? ?? '';
    return PremiumEntitlement(
      productId: productId,
      grantedAt: DateTime.tryParse(grantedAtRaw) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }

  /// True only for a record that names one of our two products.
  bool get isValid => PremiumRules.productIds.contains(productId);
}
