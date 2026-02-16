class RefinanceService {
  static const double qualificationAprDelta = 2.0;

  static RefinanceQuote buildQuote({
    required double currentApr,
    required double marketApr,
    required double currentPayment,
    required double currentBalance,
    required int targetTermMonths,
  }) {
    final double aprGap = currentApr - marketApr;
    final bool qualifies = aprGap >= qualificationAprDelta;
    final double newPayment = _calculateMonthlyPayment(
      principal: currentBalance,
      annualRatePercent: marketApr,
      termMonths: targetTermMonths,
    );
    final double monthlySavings = (currentPayment - newPayment).clamp(
      0.0,
      double.infinity,
    );

    return RefinanceQuote(
      currentApr: currentApr,
      marketApr: marketApr,
      currentPayment: currentPayment,
      currentBalance: currentBalance,
      targetTermMonths: targetTermMonths,
      aprGap: aprGap,
      qualifies: qualifies,
      newPayment: newPayment,
      monthlySavings: monthlySavings,
    );
  }

  static double _calculateMonthlyPayment({
    required double principal,
    required double annualRatePercent,
    required int termMonths,
  }) {
    if (principal <= 0 || termMonths <= 0) {
      return 0.0;
    }

    final double monthlyRate = (annualRatePercent / 100) / 12;
    if (monthlyRate == 0) {
      return principal / termMonths;
    }

    final double denominator = 1 - (1 / _pow(1 + monthlyRate, termMonths));
    if (denominator == 0) {
      return 0.0;
    }
    return principal * monthlyRate / denominator;
  }

  static double _pow(double value, int exponent) {
    var result = 1.0;
    for (var i = 0; i < exponent; i++) {
      result *= value;
    }
    return result;
  }
}

class RefinanceQuote {
  final double currentApr;
  final double marketApr;
  final double currentPayment;
  final double currentBalance;
  final int targetTermMonths;
  final double aprGap;
  final bool qualifies;
  final double newPayment;
  final double monthlySavings;

  const RefinanceQuote({
    required this.currentApr,
    required this.marketApr,
    required this.currentPayment,
    required this.currentBalance,
    required this.targetTermMonths,
    required this.aprGap,
    required this.qualifies,
    required this.newPayment,
    required this.monthlySavings,
  });
}
