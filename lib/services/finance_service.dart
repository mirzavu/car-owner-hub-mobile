class FinanceService {
  static const double paidOffLoanThreshold = 500.0;
  static const double minimumEquityForCashback = 2000.0;
  static const double cashbackLtvFactor = 0.75;
  static const double cashbackAdminFee = 500.0;
  static const double sliderMinimumCash = 1000.0;
  static const double roundingStep = 100.0;

  static CashbackOffer getCashbackOffer({
    required double vehicleValue,
    required double loanBalance,
  }) {
    final double equity = vehicleValue - loanBalance;
    final bool isPaidOff = loanBalance <= paidOffLoanThreshold;
    final double shortfallToUnlock = (minimumEquityForCashback - equity).clamp(
      0.0,
      double.infinity,
    );

    if (equity <= 0) {
      return CashbackOffer(
        equity: equity,
        maxCash: 0.0,
        shortfallToUnlock: shortfallToUnlock,
        eligibility: CashbackEligibility.underwater,
        isPaidOff: isPaidOff,
      );
    }

    if (equity < minimumEquityForCashback) {
      return CashbackOffer(
        equity: equity,
        maxCash: 0.0,
        shortfallToUnlock: shortfallToUnlock,
        eligibility: CashbackEligibility.equityPoor,
        isPaidOff: isPaidOff,
      );
    }

    final double rawMaxCash = (equity * cashbackLtvFactor) - cashbackAdminFee;
    final double roundedMaxCash = _roundDown(rawMaxCash, roundingStep);

    return CashbackOffer(
      equity: equity,
      maxCash: roundedMaxCash.clamp(0.0, double.infinity),
      shortfallToUnlock: 0.0,
      eligibility: CashbackEligibility.eligible,
      isPaidOff: isPaidOff,
    );
  }

  static double estimateNewBalanceAfterCashOut({
    required double currentLoanBalance,
    required double selectedCashAmount,
  }) {
    return currentLoanBalance + selectedCashAmount + cashbackAdminFee;
  }

  static double _roundDown(double value, double step) {
    if (value <= 0) {
      return 0.0;
    }
    return (value / step).floor() * step;
  }
}

enum CashbackEligibility { eligible, equityPoor, underwater }

class CashbackOffer {
  final double equity;
  final double maxCash;
  final double shortfallToUnlock;
  final CashbackEligibility eligibility;
  final bool isPaidOff;

  const CashbackOffer({
    required this.equity,
    required this.maxCash,
    required this.shortfallToUnlock,
    required this.eligibility,
    required this.isPaidOff,
  });

  bool get isAvailable => maxCash >= FinanceService.sliderMinimumCash;
  bool get isLocked => !isAvailable;
}
