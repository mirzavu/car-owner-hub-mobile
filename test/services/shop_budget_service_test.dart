import 'package:flutter_test/flutter_test.dart';
import 'package:mobile_app/services/shop_budget_service.dart';

void main() {
  group('ShopBudgetService.resolveTarget', () {
    test('uses paid-off budget and mode for paid-off users', () {
      final target = ShopBudgetService.resolveTarget(
        isPaidOff: true,
        keepPaymentSame: false,
        currentPayment: 420,
        paidOffBudget: 450,
        activeStepDelta: 100,
      );

      expect(target.targetPayment, 450);
      expect(target.targetMode, 'paid_off_budget');
    });

    test('uses current payment when keep same is enabled', () {
      final target = ShopBudgetService.resolveTarget(
        isPaidOff: false,
        keepPaymentSame: true,
        currentPayment: 420,
        paidOffBudget: 350,
        activeStepDelta: 100,
      );

      expect(target.targetPayment, 420);
      expect(target.targetMode, 'keep_same');
    });

    test('uses stepped adjustment when keep same is disabled', () {
      final target = ShopBudgetService.resolveTarget(
        isPaidOff: false,
        keepPaymentSame: false,
        currentPayment: 420,
        paidOffBudget: 350,
        activeStepDelta: 100,
      );

      expect(target.targetPayment, 520);
      expect(target.targetMode, 'step_adjusted');
    });

    test('never returns negative payment for stepped adjustment', () {
      final target = ShopBudgetService.resolveTarget(
        isPaidOff: false,
        keepPaymentSame: false,
        currentPayment: 40,
        paidOffBudget: 350,
        activeStepDelta: -50,
      );

      expect(target.targetPayment, 0);
      expect(target.targetMode, 'step_adjusted');
    });
  });
}
