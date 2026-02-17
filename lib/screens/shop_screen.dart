import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/shop_budget_service.dart';

class ShopScreen extends StatefulWidget {
  final Map<String, dynamic> financials;
  final Map<String, String> carDetails;
  final Function(String) setOverlayScreen;
  final Function(String) setActiveTab;

  const ShopScreen({
    super.key,
    required this.financials,
    required this.carDetails,
    required this.setOverlayScreen,
    required this.setActiveTab,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _isLoading = true;
  int _requestId = 0;
  List<dynamic> _inventory = [];

  bool _keepPaymentSame = true;
  double _paidOffBudget = ShopBudgetService.defaultPaidOffBudget;
  int _activeStepDelta = 50;
  bool _financialFallbackChecked = false;
  double? _fallbackEquity;
  double? _fallbackMonthlyPayment;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  int? _parseCurrentYear() {
    final yearRaw = widget.carDetails['year'];
    if (yearRaw == null || yearRaw.trim().isEmpty) return null;
    return int.tryParse(yearRaw.trim());
  }

  ShopBudgetTarget _resolveTarget(double userPayment, bool isPaidOff) {
    return ShopBudgetService.resolveTarget(
      isPaidOff: isPaidOff,
      keepPaymentSame: _keepPaymentSame,
      currentPayment: userPayment,
      paidOffBudget: _paidOffBudget,
      activeStepDelta: _activeStepDelta,
    );
  }

  double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  bool _hasLocalFinancialSignal() {
    final monthly = _asDouble(widget.financials['monthlyPayment']);
    final equity = _asDouble(widget.financials['equity']);
    final est = _asDouble(widget.financials['estimatedValue']);
    final loan = _asDouble(widget.financials['userEstimatedLoan']);
    return monthly != 0 || equity != 0 || est != 0 || loan != 0;
  }

  double _effectiveUserPayment() {
    final localPayment = _asDouble(widget.financials['monthlyPayment']);
    if (localPayment != 0) return localPayment;
    return _fallbackMonthlyPayment ?? 0;
  }

  double _effectiveEquity() {
    final localEquity = _asDouble(widget.financials['equity']);
    if (localEquity != 0) return localEquity;

    final estimated = _asDouble(widget.financials['estimatedValue']);
    final loan = _asDouble(widget.financials['userEstimatedLoan']);
    final derived = estimated - loan;
    if (derived != 0) return derived;

    return _fallbackEquity ?? 0;
  }

  Future<void> _ensureFinancialFallback() async {
    if (_financialFallbackChecked) return;
    _financialFallbackChecked = true;

    if (_hasLocalFinancialSignal()) return;

    try {
      final data = await ApiService.getDashboardData();
      final financials = data['financials'] as Map<String, dynamic>? ?? {};
      final vehicleValue = _asDouble(financials['vehicleValue']);
      final loanBalance = _asDouble(financials['loanBalance']);
      double payment = _asDouble(financials['monthlyPayment']);
      if (loanBalance <= 0) payment = 0;
      final equity = vehicleValue - loanBalance;

      if (!mounted) return;
      setState(() {
        _fallbackEquity = equity;
        _fallbackMonthlyPayment = payment;
      });
    } catch (e) {
      debugPrint('Shop fallback financial fetch failed: $e');
    }
  }

  Future<void> _fetchInventory() async {
    await _ensureFinancialFallback();
    final double userPayment = _effectiveUserPayment();
    final bool isPaidOff = userPayment <= 0;
    final target = _resolveTarget(userPayment, isPaidOff);
    final currentYear = _parseCurrentYear();

    final requestId = ++_requestId;
    setState(() => _isLoading = true);

    try {
      final equity = _effectiveEquity();
      final authRecord = AuthService().pb.authStore.record;
      final profileCity = authRecord?.getStringValue('city') ?? '';
      final profileProvince = authRecord?.getStringValue('province') ?? '';
      debugPrint(
        '[SHOP] profile location city=${profileCity.isEmpty ? '-' : profileCity} province=${profileProvince.isEmpty ? '-' : profileProvince}',
      );

      final data = await ApiService.getInventory(
        equity: equity,
        currentPayment: userPayment,
        targetPayment: target.targetPayment,
        currentYear: currentYear,
        currentMake: widget.carDetails['make'],
        currentModel: widget.carDetails['model'],
        currentBodyStyle: widget.carDetails['body_style'],
        targetMode: target.targetMode,
        city: profileCity,
        province: profileProvince,
      );

      if (!mounted || requestId != _requestId) return;
      setState(() {
        _inventory = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error fetching inventory: $e');
      if (!mounted || requestId != _requestId) return;
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorBg = Color(0xFFE6F0FA);
    const colorSlate800 = Color(0xFF1E293B);
    const colorGreen = Color(0xFF00CA50);
    const colorNavy = Color(0xFF003366);

    final double userPayment = _effectiveUserPayment();
    final double equity = _effectiveEquity();
    final bool isPaidOff = userPayment <= 0;
    final target = _resolveTarget(userPayment, isPaidOff);

    final int listItemCount;
    if (_isLoading) {
      listItemCount = 2;
    } else if (_inventory.isEmpty) {
      listItemCount = 2;
    } else {
      listItemCount = _inventory.length + 1;
    }

    return Scaffold(
      backgroundColor: colorBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.setActiveTab('home'),
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
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        size: 24,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Trade-Up Shop',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorSlate800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: listItemCount,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isPaidOff) ...[
                          _buildPaidOffHero(equity),
                          const SizedBox(height: 16),
                          _buildPaidOffBudgetControls(target.targetPayment),
                          const SizedBox(height: 24),
                        ] else ...[
                          _buildEquityStrip(equity),
                          const SizedBox(height: 16),
                          _buildActivePaymentControls(
                            userPayment: userPayment,
                            targetPayment: target.targetPayment,
                            colorGreen: colorGreen,
                            colorSlate800: colorSlate800,
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    );
                  }

                  if (_isLoading && index == 1) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(
                          color: Color(0xFF003366),
                        ),
                      ),
                    );
                  }

                  if (!_isLoading && _inventory.isEmpty && index == 1) {
                    return _buildEmptyState();
                  }

                  if (index - 1 < _inventory.length) {
                    final car = _inventory[index - 1] as Map<String, dynamic>;
                    return _buildCarCard(
                      car,
                      userPayment,
                      colorNavy,
                      colorGreen,
                    );
                  }

                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaidOffHero(double equity) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF003366), Color(0xFF002244)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'You have ${_fmt(equity)} in Trade-In Power',
            style: GoogleFonts.outfit(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 20,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Your current vehicle is fully paid off. Set your target budget and see upgrades from nearby dealers first.',
            style: GoogleFonts.outfit(
              color: Colors.white.withValues(alpha: 0.9),
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaidOffBudgetControls(double targetPayment) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Set target budget',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Showing vehicles around ${_fmt(targetPayment)}/mo',
            style: GoogleFonts.outfit(fontSize: 12, color: Colors.blueGrey),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ShopBudgetService.paidOffBudgetChips.map((budget) {
              final selected = _paidOffBudget.round() == budget;
              return ChoiceChip(
                selected: selected,
                label: Text('\$$budget/mo'),
                onSelected: (_) {
                  setState(() => _paidOffBudget = budget.toDouble());
                  _fetchInventory();
                },
              );
            }).toList(),
          ),
          const SizedBox(height: 10),
          Slider(
            min: 200,
            max: 800,
            divisions: 12,
            label: '\$${_paidOffBudget.round()}/mo',
            value: _paidOffBudget,
            onChanged: (value) {
              setState(() {
                _paidOffBudget = (value / 50).round() * 50.0;
              });
            },
            onChangeEnd: (_) => _fetchInventory(),
          ),
        ],
      ),
    );
  }

  Widget _buildEquityStrip(double equity) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            equity >= 0 ? LucideIcons.trendingUp : LucideIcons.trendingDown,
            size: 16,
            color: equity >= 0 ? const Color(0xFF00CA50) : Colors.orangeAccent,
          ),
          const SizedBox(width: 8),
          RichText(
            text: TextSpan(
              style: GoogleFonts.outfit(
                fontSize: 14,
                color: const Color(0xFF1E293B),
                fontWeight: FontWeight.w500,
              ),
              children: [
                TextSpan(text: equity >= 0 ? 'You have ' : 'Rolling in '),
                TextSpan(
                  text: _fmt(equity.abs()),
                  style: GoogleFonts.outfit(
                    fontWeight: FontWeight.bold,
                    color: equity >= 0
                        ? const Color(0xFF00CA50)
                        : Colors.orangeAccent,
                  ),
                ),
                TextSpan(
                  text: equity >= 0
                      ? ' equity to use for your next vehicle.'
                      : ' from your current loan.',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivePaymentControls({
    required double userPayment,
    required double targetPayment,
    required Color colorGreen,
    required Color colorSlate800,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Keep my payment same',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: colorSlate800,
                    ),
                  ),
                  Text(
                    'Current: ${_fmt(userPayment)}/mo',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.blueGrey,
                    ),
                  ),
                ],
              ),
              Switch(
                value: _keepPaymentSame,
                activeThumbColor: colorGreen,
                onChanged: (val) {
                  setState(() {
                    _keepPaymentSame = val;
                    if (!val && _activeStepDelta == 0) {
                      _activeStepDelta = 50;
                    }
                  });
                  _fetchInventory();
                },
              ),
            ],
          ),
        ),
        if (!_keepPaymentSame) ...[
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Explore payment tiers',
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: colorSlate800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Target now: ${_fmt(targetPayment)}/mo',
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: Colors.blueGrey,
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: ShopBudgetService.activeLoanStepOptions.map((step) {
                    final selected = _activeStepDelta == step;
                    final prefix = step > 0 ? '+' : '-';
                    return ChoiceChip(
                      selected: selected,
                      label: Text('$prefix\$${step.abs()}'),
                      onSelected: (_) {
                        setState(() => _activeStepDelta = step);
                        _fetchInventory();
                      },
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        'No matching vehicles found right now. Try adjusting your target budget to widen results.',
        style: GoogleFonts.outfit(
          fontSize: 14,
          color: Colors.blueGrey.shade700,
        ),
      ),
    );
  }

  Widget _buildCarCard(
    Map<String, dynamic> car,
    double userPayment,
    Color colorNavy,
    Color colorGreen,
  ) {
    LinearGradient bgGradient;
    Color iconColor;

    if (car['image'] == 'blue') {
      bgGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFE6F0FA),
          const Color(0xFF003366).withValues(alpha: 0.2),
        ],
      );
      iconColor = const Color(0xFF003366).withValues(alpha: 0.5);
    } else if (car['image'] == 'white') {
      bgGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blueGrey.shade50, Colors.blueGrey.shade200],
      );
      iconColor = Colors.blueGrey.withValues(alpha: 0.5);
    } else {
      bgGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey.shade300, Colors.grey.shade400],
      );
      iconColor = Colors.grey.shade700.withValues(alpha: 0.5);
    }

    final double projectedPayment = (car['payment'] as num?)?.toDouble() ?? 0;
    final bool isPaidOff = projectedPayment <= 0;
    final bool isGoodDeal =
        !isPaidOff && userPayment > 0 && projectedPayment <= userPayment;

    final badges = car['badges'] is List ? (car['badges'] as List) : const [];

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: bgGradient,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Center(
                  child:
                      car['image'] != null &&
                          car['image'].toString().startsWith('http')
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: Image.network(
                            car['image'].toString(),
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              LucideIcons.car,
                              size: 80,
                              color: iconColor,
                            ),
                          ),
                        )
                      : Icon(LucideIcons.car, size: 80, color: iconColor),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    ...badges.map((badge) {
                      final badgeMap = badge as Map<String, dynamic>;
                      Color textColor;
                      switch (badgeMap['color']) {
                        case 'green':
                        case 'emerald':
                          textColor = colorGreen;
                          break;
                        case 'blue':
                          textColor = colorNavy;
                          break;
                        default:
                          textColor = Colors.blueGrey;
                      }

                      return Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badgeMap['text'].toString(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${car['year']} ${car['make']} ${car['model']}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            (car['trim'] ?? '').toString(),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: Colors.blueGrey.shade400,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isPaidOff
                              ? 'Paid in Full'
                              : '\$${projectedPayment.toInt()}/mo',
                          style: GoogleFonts.outfit(
                            fontSize: isPaidOff ? 16 : 20,
                            fontWeight: FontWeight.bold,
                            color: isPaidOff || isGoodDeal
                                ? colorGreen
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        if (!isPaidOff)
                          Text(
                            'with trade-in',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.blueGrey.shade400,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(height: 1, color: Colors.blueGrey.shade50),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Price: ${_fmt(car['price'] as num? ?? 0)}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: colorGreen,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        widget.setOverlayScreen('success');
                      },
                      child: Text(
                        (car['city'] ?? 'See Deal').toString(),
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueGrey.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(num n) {
    return NumberFormat.currency(
      locale: 'en_CA',
      symbol: '\$',
      decimalDigits: 0,
    ).format(n);
  }
}
