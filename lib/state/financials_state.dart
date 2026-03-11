import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';

class FinancialsState {
  final Map<String, dynamic> data;
  final String? loanId;

  const FinancialsState({
    required this.data,
    required this.loanId,
  });

  factory FinancialsState.initial() {
    return const FinancialsState(
      data: {
        'estimatedValue': 0.0,
        'userEstimatedLoan': 0.0,
        'actualRate': 0.0,
        'marketRate': null,
        'monthlyPayment': 0.0,
        'lender': 'Pending...',
        'equity': 0.0,
      },
      loanId: null,
    );
  }

  FinancialsState copyWith({
    Map<String, dynamic>? data,
    String? loanId,
    bool keepLoanId = true,
  }) {
    return FinancialsState(
      data: data ?? this.data,
      loanId: keepLoanId ? (loanId ?? this.loanId) : loanId,
    );
  }
}

class FinancialsNotifier extends StateNotifier<FinancialsState> {
  FinancialsNotifier() : super(FinancialsState.initial());

  void update(Map<String, dynamic> patch) {
    debugPrint("[FINANCIALS] State update: $patch");
    state = state.copyWith(
      data: {
        ...state.data,
        ...patch,
      },
    );
  }

  void setLoanId(String? value) {
    state = state.copyWith(loanId: value, keepLoanId: false);
  }

  void calculateEquity() {
    final estimatedValue = (state.data['estimatedValue'] ?? 0).toDouble();
    final userEstimatedLoan =
        (state.data['userEstimatedLoan'] ?? 0).toDouble();
    final equity = estimatedValue - userEstimatedLoan;
    debugPrint("[FINANCIALS] Equity: $equity (Value: $estimatedValue, Loan: $userEstimatedLoan)");
    update({'equity': equity});
  }

  void applySnapshot(LoanSnapshot snapshot) {
    update({
      'userEstimatedLoan': snapshot.currentBalance,
      'actualRate': snapshot.interestRate,
      'monthlyPayment': snapshot.monthlyPayment,
      'estimatedValue': snapshot.estimatedValue,
    });
    setLoanId(snapshot.loanId);
    calculateEquity();
  }

  void updateFromScanData(Map<String, dynamic> data) {
    if (data['interest_rate'] != null) {
      update({'actualRate': data['interest_rate']});
    }
    if (data['estimatedValue'] != null) {
      update({'estimatedValue': data['estimatedValue']});
    }
    if (data['lender_name'] != null) {
      update({'lender': data['lender_name']});
    }
    if (data['monthly_payment'] != null) {
      update({'monthlyPayment': data['monthly_payment']});
    }
    if (data['original_amount_financed'] != null) {
      update({'userEstimatedLoan': data['original_amount_financed']});
    } else if (data['current_balance'] != null) {
      update({'userEstimatedLoan': data['current_balance']});
    }
    calculateEquity();
  }
}

final financialsProvider =
    StateNotifierProvider<FinancialsNotifier, FinancialsState>(
  (ref) => FinancialsNotifier(),
);
