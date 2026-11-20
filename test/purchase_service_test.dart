import 'package:banana_compass/services/purchase_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PurchaseService debug unlock', () {
    testWidgets('test builds have Premium unlocked', (tester) async {
      // Flutter tests run with kDebugMode true, same as the CI debug
      // APKs — so constructing the service must leave Premium on. This
      // guards the unlock line; it says nothing about release builds,
      // where kDebugMode is false and Premium comes from a real purchase.
      // On web (kIsWeb) the unlock is skipped — the web app is always
      // the free tier — but flutter test runs on the VM, not the web,
      // so the unlock applies here.
      // initialize() is deliberately NOT called here: it talks to the
      // store, and the store never answers in a test.
      final service = PurchaseService();
      expect(service.isPremium.value, isTrue);
      expect(service.productsReady.value, isFalse);
    });

    testWidgets('buying without store products returns false', (tester) async {
      final service = PurchaseService();
      expect(await service.buyMonthly(), isFalse);
      expect(await service.buyLifetime(), isFalse);
      expect(await service.restorePurchases(), isTrue);
    });
  });
}
