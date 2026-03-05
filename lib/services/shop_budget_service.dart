class ShopBudgetTarget {
  final double targetPayment;
  final String targetMode;

  const ShopBudgetTarget({
    required this.targetPayment,
    required this.targetMode,
  });
}

class ShopBudgetService {
  static const double defaultPaidOffBudget = 350;
  static const List<int> paidOffBudgetChips = [250, 350, 450, 550];
  static const List<int> activeLoanStepOptions = [
    -150,
    -100,
    -50,
    0,
    50,
    100,
    150,
  ];

  static ShopBudgetTarget resolveTarget({
    required bool isPaidOff,
    required bool keepPaymentSame,
    required double currentPayment,
    required double paidOffBudget,
    required int activeStepDelta,
  }) {
    if (isPaidOff) {
      return ShopBudgetTarget(
        targetPayment: paidOffBudget <= 0
            ? defaultPaidOffBudget
            : paidOffBudget,
        targetMode: 'paid_off_budget',
      );
    }

    if (keepPaymentSame) {
      return ShopBudgetTarget(
        targetPayment: currentPayment <= 0
            ? defaultPaidOffBudget
            : currentPayment,
        targetMode: 'keep_same',
      );
    }

    final target = currentPayment + activeStepDelta;
    return ShopBudgetTarget(
      targetPayment: target < 0 ? 0 : target,
      targetMode: 'step_adjusted',
    );
  }
}
