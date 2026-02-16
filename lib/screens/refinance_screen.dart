import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../services/refinance_service.dart';

class RefinanceScreen extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onStartRefinance;
  final Map<String, dynamic> financials;

  const RefinanceScreen({
    super.key,
    required this.onClose,
    required this.onStartRefinance,
    required this.financials,
  });

  @override
  State<RefinanceScreen> createState() => _RefinanceScreenState();
}

class _RefinanceScreenState extends State<RefinanceScreen> {
  bool _loading = true;
  bool _submitting = false;
  bool _paidOff = false;
  String? _error;
  int _selectedTermMonths = 72;
  double? _marketRate;
  LoanSnapshot? _loanSnapshot;
  RefinanceQuote? _quote;

  @override
  void initState() {
    super.initState();
    _initializeRefinance();
  }

  double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  String _fmtCurrency(num value) {
    return NumberFormat.currency(
      locale: 'en_CA',
      symbol: '\$',
      decimalDigits: 0,
    ).format(value);
  }

  Future<void> _initializeRefinance() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      _loanSnapshot = await ApiService.getCurrentLoanSnapshot();

      final double balanceFromFinancials = _asDouble(
        widget.financials['loanBalance'] ??
            widget.financials['userEstimatedLoan'],
      );
      final double activeBalance =
          _loanSnapshot?.currentBalance ?? balanceFromFinancials;
      _paidOff = activeBalance <= FinanceService.paidOffLoanThreshold;
      if (_paidOff) {
        _quote = null;
        if (!mounted) return;
        setState(() {
          _loading = false;
        });
        return;
      }

      final double rateFromMap = _asDouble(widget.financials['marketRate'], -1);
      _marketRate = rateFromMap >= 0
          ? rateFromMap
          : await ApiService.getMarketRateFromSettings();

      _rebuildQuote();
    } catch (e) {
      _error = "Unable to load refinance data right now.";
      debugPrint("Refinance initialization error: $e");
    }

    if (!mounted) return;
    setState(() {
      _loading = false;
    });
  }

  void _rebuildQuote() {
    if (_marketRate == null) return;

    final double currentApr =
        _loanSnapshot?.interestRate ??
        _asDouble(widget.financials['actualRate'], 0.0);
    final double currentPayment =
        _loanSnapshot?.monthlyPayment ??
        _asDouble(widget.financials['monthlyPayment'], 0.0);
    final double currentBalance =
        _loanSnapshot?.currentBalance ??
        _asDouble(
          widget.financials['loanBalance'] ??
              widget.financials['userEstimatedLoan'],
          0.0,
        );

    _quote = RefinanceService.buildQuote(
      currentApr: currentApr,
      marketApr: _marketRate!,
      currentPayment: currentPayment,
      currentBalance: currentBalance,
      targetTermMonths: _selectedTermMonths,
    );
  }

  Future<void> _submitRefinanceApplication() async {
    if (_quote == null || !_quote!.qualifies || _paidOff) return;

    final String loanId = _loanSnapshot?.loanId ?? '';
    if (loanId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "We couldn't find your active loan. Verify your loan first.",
          ),
        ),
      );
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      await ApiService.submitLead('refinance', {
        'user_id': AuthService().userId,
        'loan_id': loanId,
        'current_rate': _quote!.currentApr,
        'market_rate': _quote!.marketApr,
        'new_rate': _quote!.marketApr,
        'current_payment': _quote!.currentPayment,
        'new_payment': _quote!.newPayment,
        'monthly_savings': _quote!.monthlySavings,
        'current_balance': _quote!.currentBalance,
        'target_term_months': _quote!.targetTermMonths,
      });
      if (!mounted) return;
      widget.onStartRefinance();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit application.")),
      );
      debugPrint("Refinance submit error: $e");
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }

  Widget _buildTermChip(int months) {
    final bool selected = _selectedTermMonths == months;
    const colorGreen = Color(0xFF00CA50);

    return Expanded(
      child: GestureDetector(
        onTap: () {
          setState(() {
            _selectedTermMonths = months;
            _rebuildQuote();
          });
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: selected ? colorGreen : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? colorGreen : Colors.blueGrey.shade100,
            ),
          ),
          child: Text(
            "$months months",
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : const Color(0xFF334155),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildComparisonRow({
    required String label,
    required String current,
    required String updated,
    TextStyle? currentStyle,
    TextStyle? updatedStyle,
    Color? bgColor,
    BorderRadius? borderRadius,
  }) {
    return Container(
      decoration: BoxDecoration(color: bgColor, borderRadius: borderRadius),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              current,
              textAlign: TextAlign.center,
              style:
                  currentStyle ??
                  GoogleFonts.outfit(
                    color: Colors.blueGrey.shade500,
                    decoration: TextDecoration.lineThrough,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              updated,
              textAlign: TextAlign.center,
              style:
                  updatedStyle ??
                  GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF00CA50),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const colorBg = Color(0xFFF8FAFC);
    const colorTextDark = Color(0xFF1A1A1B);
    const colorGreen = Color(0xFF00CA50);

    return Scaffold(
      backgroundColor: colorBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.chevronLeft, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Refinance Estimate",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorTextDark,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _paidOff
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.blueGrey.shade100),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                LucideIcons.shieldCheck,
                                size: 28,
                                color: Color(0xFF047857),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Loan Already Paid Off",
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colorTextDark,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "Refinance is only available for active loans. You can use Trade Up or Cash options instead.",
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: Colors.blueGrey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: _initializeRefinance,
                              child: const Text("Retry"),
                            ),
                          ],
                        ),
                      ),
                    )
                  : _quote == null
                  ? const SizedBox.shrink()
                  : SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      physics: const BouncingScrollPhysics(),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (!_quote!.qualifies)
                            Container(
                              margin: const EdgeInsets.only(bottom: 16),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: const Color(0xFFA7F3D0),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    LucideIcons.shieldCheck,
                                    color: Color(0xFF047857),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      "Rate Shield Active: your rate is within ${RefinanceService.qualificationAprDelta.toStringAsFixed(2)}% of market.",
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF065F46),
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.06),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorBg,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(20),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          "ITEM",
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "CURRENT",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.blueGrey,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        child: Text(
                                          "NEW",
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                            color: colorGreen,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                _buildComparisonRow(
                                  label: "Rate",
                                  current:
                                      "${_quote!.currentApr.toStringAsFixed(2)}%",
                                  updated:
                                      "${_quote!.marketApr.toStringAsFixed(2)}%",
                                ),
                                _buildComparisonRow(
                                  label: "Term",
                                  current:
                                      _loanSnapshot != null &&
                                          _loanSnapshot!.termMonths > 0
                                      ? "${_loanSnapshot!.termMonths} mo"
                                      : "--",
                                  updated: "${_quote!.targetTermMonths} mo",
                                ),
                                _buildComparisonRow(
                                  label: "Payment",
                                  current: _fmtCurrency(_quote!.currentPayment),
                                  updated: _fmtCurrency(_quote!.newPayment),
                                  updatedStyle: GoogleFonts.outfit(
                                    color: colorGreen,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 20,
                                  ),
                                  bgColor: colorBg.withValues(alpha: 0.5),
                                  borderRadius: const BorderRadius.vertical(
                                    bottom: Radius.circular(20),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              color: colorGreen,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: colorGreen.withValues(alpha: 0.25),
                                  blurRadius: 20,
                                  offset: const Offset(0, 10),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Text(
                                  "Estimated Monthly Savings",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _fmtCurrency(_quote!.monthlySavings),
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 40,
                                    letterSpacing: -1.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Choose Refinance Term",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorTextDark,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              _buildTermChip(60),
                              const SizedBox(width: 10),
                              _buildTermChip(72),
                            ],
                          ),
                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
            ),
            if (!_loading && (_paidOff || (_error == null && _quote != null)))
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(
                    top: BorderSide(color: Colors.blueGrey.shade50),
                  ),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _paidOff
                        ? null
                        : _quote!.qualifies && !_submitting
                        ? _submitRefinanceApplication
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colorGreen,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.blueGrey.shade200,
                      disabledForegroundColor: Colors.blueGrey.shade600,
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: Text(
                      _paidOff
                          ? "Loan Paid Off"
                          : _submitting
                          ? "Submitting..."
                          : _quote!.qualifies
                          ? "Submit Application"
                          : "Rate Shield Active",
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
