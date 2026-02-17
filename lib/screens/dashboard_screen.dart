import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import '../services/finance_service.dart';
import '../services/refinance_service.dart';
import 'profile_screen.dart';
import 'notification_screen.dart';
import 'activity_history_screen.dart';

// --- Types for Props ---
class CarDetails {
  final String year;
  final String make;
  final String model;
  CarDetails({required this.year, required this.make, required this.model});
}

class DashboardScreen extends StatefulWidget {
  final CarDetails carDetails;
  final Function(String) setOverlayScreen;
  final Function(String) setActiveTab;
  final VoidCallback onLogout;
  final VoidCallback onReverify;

  const DashboardScreen({
    super.key,
    required this.carDetails,
    required this.setOverlayScreen,
    required this.setActiveTab,
    required this.onLogout,
    required this.onReverify,
    required this.initialFinancials,
    this.onFinancialsUpdate,
    this.onCarDetailsUpdate,
  });

  final Map<String, dynamic> initialFinancials;
  final Function(Map<String, dynamic>)? onFinancialsUpdate;
  final Function(Map<String, dynamic>)? onCarDetailsUpdate;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with WidgetsBindingObserver {
  final ScrollController _scrollController = ScrollController();

  // State to track scroll for animations
  double _expandedHeaderOpacity = 1.0;
  bool _showStickyHeader = false;
  bool _useDarkBackground = false;

  // Real Data State - Initialized from props
  late double vehicleValue;
  late double loanBalance;
  late double monthlyPayment;
  late double interestRate;
  late String _vehicleYear;
  late String _vehicleMake;
  late String _vehicleModel;
  double? marketRate;
  int _tradePreviewRequestId = 0;
  String _tradePreviewYear = '';
  String _tradePreviewMake = '';
  String _tradePreviewModel = '';
  double _tradePreviewPayment = 0;
  int _unreadNotificationCount = 0;
  List<ActivityFeedItem> _recentActivities = [];

  double get equity => vehicleValue - loanBalance;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize state from what the app already knows
    vehicleValue = (widget.initialFinancials['estimatedValue'] ?? 0.0)
        .toDouble();
    loanBalance = (widget.initialFinancials['userEstimatedLoan'] ?? 0.0)
        .toDouble();
    monthlyPayment = (widget.initialFinancials['monthlyPayment'] ?? 0.0)
        .toDouble();
    interestRate = (widget.initialFinancials['actualRate'] ?? 0.0).toDouble();
    _vehicleYear = widget.carDetails.year;
    _vehicleMake = widget.carDetails.make;
    _vehicleModel = widget.carDetails.model;

    _scrollController.addListener(_scrollListener);
    _fetchDashboardData();
    _fetchMarketRate();
    AuthService().addListener(_onAuthChanged);
  }

  void _onAuthChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _fetchDashboardData() async {
    try {
      final data = await ApiService.getDashboardData();
      final financials = data['financials'] ?? {};
      final carDetails = data['carDetails'] as Map<String, dynamic>? ?? {};
      final activity = data['activity'] as List<dynamic>? ?? const [];
      final notificationSummary =
          data['notificationSummary'] as Map<String, dynamic>? ?? const {};
      setState(() {
        vehicleValue = (financials['vehicleValue'] ?? 22500).toDouble();
        loanBalance = (financials['loanBalance'] ?? 18000).toDouble();
        // If loan is paid off, payment must be 0
        if (loanBalance == 0) {
          monthlyPayment = 0.0;
        } else {
          monthlyPayment = (financials['monthlyPayment'] ?? 420).toDouble();
        }
        interestRate = (financials['interestRate'] ?? 0.0).toDouble();

        final yearText = (carDetails['year'] ?? '').toString().trim();
        final makeText = (carDetails['make'] ?? '').toString().trim();
        final modelText = (carDetails['model'] ?? '').toString().trim();
        if (yearText.isNotEmpty) _vehicleYear = yearText;
        if (makeText.isNotEmpty) _vehicleMake = makeText;
        if (modelText.isNotEmpty) _vehicleModel = modelText;
        _unreadNotificationCount =
            (notificationSummary['unreadCount'] as num?)?.toInt() ?? 0;
        _recentActivities = activity
            .whereType<Map<String, dynamic>>()
            .map(ActivityFeedItem.fromJson)
            .toList();
      });
      if (widget.onFinancialsUpdate != null) {
        widget.onFinancialsUpdate!({
          'actualRate': interestRate,
          'monthlyPayment': monthlyPayment,
          'userEstimatedLoan': loanBalance,
          'estimatedValue': vehicleValue,
        });
      }
      if (widget.onCarDetailsUpdate != null) {
        widget.onCarDetailsUpdate!(carDetails);
      }
      await _fetchTradeUpPreview();
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
    }
  }

  @override
  void didUpdateWidget(covariant DashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync state if props changed from parent (e.g. after Time Travel)
    if (widget.initialFinancials != oldWidget.initialFinancials) {
      setState(() {
        vehicleValue =
            (widget.initialFinancials['estimatedValue'] ?? vehicleValue)
                .toDouble();
        loanBalance =
            (widget.initialFinancials['userEstimatedLoan'] ?? loanBalance)
                .toDouble();
        monthlyPayment =
            (widget.initialFinancials['monthlyPayment'] ?? monthlyPayment)
                .toDouble();
        interestRate = (widget.initialFinancials['actualRate'] ?? interestRate)
            .toDouble();
      });
    }
  }

  Future<void> _fetchMarketRate() async {
    try {
      final rate = await ApiService.getMarketRateFromSettings();
      if (!mounted) return;
      setState(() {
        marketRate = rate;
      });
      if (widget.onFinancialsUpdate != null) {
        widget.onFinancialsUpdate!({'marketRate': rate});
      }
    } catch (e) {
      debugPrint("Error fetching market rate: $e");
    }
  }

  void _openProfileScreen() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            ProfileScreen(onLogout: widget.onLogout),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          final tween = Tween<Offset>(
            begin: const Offset(-1.0, 0.0),
            end: Offset.zero,
          ).chain(CurveTween(curve: Curves.easeOutCubic));

          return SlideTransition(
            position: animation.drive(tween),
            child: child,
          );
        },
        transitionDuration: const Duration(milliseconds: 280),
        reverseTransitionDuration: const Duration(milliseconds: 220),
      ),
    );
  }

  Future<void> _openNotificationScreen() async {
    final route = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (context) => const NotificationScreen()),
    );

    if (!mounted) return;
    await _fetchDashboardData();

    if (route != null && route.trim().isNotEmpty) {
      _handleNotificationRoute(route);
    }
  }

  void _handleNotificationRoute(String rawRoute) {
    final route = rawRoute.trim().replaceFirst(RegExp(r'^/+'), '');

    switch (route) {
      case 'refinance':
        widget.setOverlayScreen('refinance');
        break;
      case 'cash-unlock':
        widget.setOverlayScreen('cash-unlock');
        break;
      case 'shop':
        widget.setActiveTab('shop');
        break;
      case 'garage':
        widget.setActiveTab('garage');
        break;
      default:
        break;
    }
  }

  void _scrollListener() {
    final offset = _scrollController.offset;

    // 1. Fade out the expanded header slowly (0 to 200px)
    // We want it to be fully gone before the sticky header appears
    double newOpacity = (1.0 - (offset / 200)).clamp(0.0, 1.0);

    // 2. Trigger sticky header ONLY when Quick Actions (approx) reaches top
    // Expanded Height (420) - Collapsed Height (60) = 360
    bool shouldShowSticky =
        offset >= 350; // 350 for slightly earlier trigger for smoothness

    // 3. Switch background color earlier to avoid "flash of white"
    // User requested "halfway through", so around 150-200px.
    bool shouldUseDarkBg = offset > 160;

    if (newOpacity != _expandedHeaderOpacity ||
        shouldShowSticky != _showStickyHeader ||
        shouldUseDarkBg != _useDarkBackground) {
      setState(() {
        _expandedHeaderOpacity = newOpacity;
        _showStickyHeader = shouldShowSticky;
        _useDarkBackground = shouldUseDarkBg;
      });
    }
  }

  @override
  void dispose() {
    AuthService().removeListener(_onAuthChanged);
    WidgetsBinding.instance.removeObserver(this);
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _fetchTradeUpPreview();
      _fetchDashboardData();
    }
  }

  double _asDouble(dynamic value, [double fallback = 0.0]) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? fallback;
    return fallback;
  }

  Future<void> _fetchTradeUpPreview() async {
    final requestId = ++_tradePreviewRequestId;

    try {
      final data = await ApiService.getTradeUpPreview();
      if (!mounted || requestId != _tradePreviewRequestId) return;

      final vehicleRaw = data['vehicle'];
      final vehicleLog = vehicleRaw is Map
          ? Map<String, dynamic>.from(vehicleRaw)
          : <String, dynamic>{};
      debugPrint(
        '[DASHBOARD][TRADE_PREVIEW] year=${(vehicleLog['year'] ?? '-').toString()} make=${(vehicleLog['make'] ?? '-').toString()} model=${(vehicleLog['model'] ?? '-').toString()} payment=${(vehicleLog['monthlyPayment'] ?? '-').toString()}',
      );
      if (vehicleRaw is! Map) {
        setState(() {
          _tradePreviewYear = '';
          _tradePreviewMake = '';
          _tradePreviewModel = '';
          _tradePreviewPayment = 0;
        });
        return;
      }

      final vehicle = Map<String, dynamic>.from(vehicleRaw);
      setState(() {
        _tradePreviewYear = (vehicle['year'] ?? '').toString().trim();
        _tradePreviewMake = (vehicle['make'] ?? '').toString().trim();
        _tradePreviewModel = (vehicle['model'] ?? '').toString().trim();
        _tradePreviewPayment = _asDouble(vehicle['monthlyPayment']);
      });
    } catch (e) {
      debugPrint('Error fetching trade-up preview: $e');
      if (!mounted || requestId != _tradePreviewRequestId) return;
      setState(() {
        _tradePreviewYear = '';
        _tradePreviewMake = '';
        _tradePreviewModel = '';
        _tradePreviewPayment = 0;
      });
    }
  }

  bool _hasTradeUpPreview() {
    return _tradePreviewYear.isNotEmpty ||
        _tradePreviewMake.isNotEmpty ||
        _tradePreviewModel.isNotEmpty;
  }

  String _tradePreviewVehicleLabel() {
    final parts = [
      _tradePreviewYear,
      _tradePreviewMake,
      _tradePreviewModel,
    ].where((part) => part.trim().isNotEmpty).toList();

    if (parts.isEmpty) return 'upgrade options';
    return parts.join(' ');
  }

  String fmt(num n) {
    return NumberFormat.currency(
      locale: 'en_CA',
      symbol: '\$',
      decimalDigits: 0,
    ).format(n);
  }

  String _fmtNoSymbol(num n) {
    return NumberFormat.currency(
      locale: 'en_CA',
      symbol: '',
      decimalDigits: 0,
    ).format(n).trim();
  }

  String _vehicleDisplayName() {
    final parts = [
      _vehicleYear,
      _vehicleMake,
      _vehicleModel,
    ].map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    if (parts.isEmpty) return "Unknown Vehicle";
    return parts.join(' ');
  }

  String _relativeTime(String iso) {
    try {
      final created = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(created);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${created.month}/${created.day}/${created.year}';
    } catch (_) {
      return iso;
    }
  }

  _ActivityVisual _activityVisual(ActivityFeedItem activity) {
    switch (activity.iconType) {
      case 'file':
        return const _ActivityVisual(
          icon: LucideIcons.fileText,
          color: Color(0xFF2563EB),
          bg: Color(0xFFDBEAFE),
        );
      case 'check':
        return const _ActivityVisual(
          icon: LucideIcons.checkCircle2,
          color: Color(0xFF059669),
          bg: Color(0xFFD1FAE5),
        );
      case 'user':
        return const _ActivityVisual(
          icon: LucideIcons.user,
          color: Color(0xFF7C3AED),
          bg: Color(0xFFF5F3FF),
        );
      case 'clock':
      default:
        return const _ActivityVisual(
          icon: LucideIcons.clock3,
          color: Color(0xFF475569),
          bg: Color(0xFFF1F5F9),
        );
    }
  }

  void _showCashLockedDialog(CashbackOffer offer) {
    final String message = offer.eligibility == CashbackEligibility.underwater
        ? "Equity too low. You need at least ${fmt(FinanceService.minimumEquityForCashback)} in positive equity to unlock cash."
        : "Almost there. Pay down ${fmt(offer.shortfallToUnlock)} more to unlock Cash Mode.";

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Cash Locked"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showRateShieldDialog({
    required double currentRate,
    required double marketRate,
  }) {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Rate Shield Active"),
          content: Text(
            "Your ${currentRate.toStringAsFixed(2)}% APR is already within ${RefinanceService.qualificationAprDelta.toStringAsFixed(2)}% of market (${marketRate.toStringAsFixed(2)}%). Refinance is currently not recommended.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _showRefinanceUnavailableDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Refinance Unavailable"),
          content: const Text(
            "Your loan is already paid off. Refinance is only available for active auto loans.",
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  String _getInitials(String name) {
    if (name.isEmpty) return "??";
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[parts.length - 1].substring(0, 1))
        .toUpperCase();
  }

  int _actionPriority(_DashboardActionKind kind) {
    switch (kind) {
      case _DashboardActionKind.tradeUp:
        return 0;
      case _DashboardActionKind.getCash:
        return 1;
      case _DashboardActionKind.refinance:
        return 2;
    }
  }

  List<Widget> _orderedActionWidgets(List<_DashboardActionItem> items) {
    final sorted = List<_DashboardActionItem>.from(items)
      ..sort((a, b) {
        if (a.isTerminalAction != b.isTerminalAction) {
          return a.isTerminalAction ? 1 : -1;
        }
        return _actionPriority(a.kind) - _actionPriority(b.kind);
      });
    return sorted.map((item) => item.widget).toList();
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    const colorSlate50 = Color(0xFFF8FAFC);
    const colorSlate800 = Color(0xFF1E293B);

    // Midnight Navy Gradient
    const gradientColors = [
      Color(0xFF003366), // Midnight Navy
      Color(0xFF002852),
      Color(0xFF002244),
    ];
    final CashbackOffer cashOffer = FinanceService.getCashbackOffer(
      vehicleValue: vehicleValue,
      loanBalance: loanBalance,
    );
    final bool isUnderwater =
        cashOffer.eligibility == CashbackEligibility.underwater;
    final bool isPaidOff = cashOffer.isPaidOff;
    final bool showCashProgress =
        cashOffer.eligibility == CashbackEligibility.equityPoor;
    final String statusBadgeText = isPaidOff
        ? "FREEDOM ACHIEVED"
        : isUnderwater
        ? "BUILDING EQUITY"
        : "IN THE GREEN";
    final IconData statusBadgeIcon = isPaidOff
        ? LucideIcons.trophy
        : isUnderwater
        ? LucideIcons.trendingDown
        : LucideIcons.checkCircle2;
    final Color statusBadgeColor = isPaidOff
        ? Colors.amberAccent.shade200
        : isUnderwater
        ? Colors.amberAccent.shade100
        : Colors.greenAccent.shade100;
    final Color equityAmountColor = isUnderwater
        ? Colors.redAccent.shade100
        : Colors.white;
    final String balanceDisplayText = isPaidOff ? "PAID OFF" : fmt(loanBalance);
    const String stickyBalanceCaption = "BALANCE";
    final RefinanceQuote? refinancePreview = marketRate == null
        ? null
        : RefinanceService.buildQuote(
            currentApr: interestRate,
            marketApr: marketRate!,
            currentPayment: monthlyPayment,
            currentBalance: loanBalance,
            targetTermMonths: 72,
          );
    final bool refinanceUnavailableForPaidOff =
        loanBalance <= FinanceService.paidOffLoanThreshold;
    final bool hasRefinanceData =
        interestRate > 0 &&
        marketRate != null &&
        !refinanceUnavailableForPaidOff;
    final bool refinanceQualifies = refinancePreview?.qualifies ?? true;
    final bool showScanRateOpportunity =
        !refinanceUnavailableForPaidOff &&
        (AuthService().onboardingStatus == 'skipped' || interestRate == 0);
    final bool showRateAlertOpportunity =
        !refinanceUnavailableForPaidOff &&
        hasRefinanceData &&
        refinanceQualifies;
    final bool refinancePopupOnly =
        refinanceUnavailableForPaidOff ||
        (hasRefinanceData && !refinanceQualifies);

    final quickActionItems = <_DashboardActionItem>[
      _DashboardActionItem(
        kind: _DashboardActionKind.tradeUp,
        isTerminalAction: false,
        widget: _ActionButton(
          icon: LucideIcons.car,
          label: "Trade Up",
          onTap: () => widget.setActiveTab('shop'),
        ),
      ),
      _DashboardActionItem(
        kind: _DashboardActionKind.getCash,
        isTerminalAction: cashOffer.isLocked,
        widget: _ActionButton(
          icon: LucideIcons.dollarSign,
          label: "Get Cash",
          isLocked: cashOffer.isLocked,
          onTap: () {
            if (cashOffer.isLocked) {
              _showCashLockedDialog(cashOffer);
              return;
            }
            widget.setOverlayScreen('cash-unlock');
          },
        ),
      ),
      _DashboardActionItem(
        kind: _DashboardActionKind.refinance,
        isTerminalAction: refinancePopupOnly,
        widget: refinanceUnavailableForPaidOff
            ? _ActionButton(
                icon: LucideIcons.arrowRightLeft,
                label: "Refinance",
                isLocked: true,
                onTap: _showRefinanceUnavailableDialog,
              )
            : hasRefinanceData && !refinanceQualifies
            ? _ActionButton(
                icon: LucideIcons.shieldCheck,
                label: "Rate Shield",
                onTap: () => _showRateShieldDialog(
                  currentRate: interestRate,
                  marketRate: marketRate!,
                ),
              )
            : _ActionButton(
                icon: LucideIcons.arrowRightLeft,
                label: "Refinance",
                onTap: () => widget.setOverlayScreen('refinance'),
              ),
      ),
    ];
    final orderedQuickActionWidgets = _orderedActionWidgets(quickActionItems);

    final Widget tradeUpOpportunityCard = _OpportunityCard(
      icon: LucideIcons.car,
      iconColor: Colors.blue.shade600,
      iconBg: Colors.blue.shade50,
      title: "Trade Up",
      body: _hasTradeUpPreview()
          ? RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.blueGrey.shade400,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: "Drive a "),
                  TextSpan(
                    text: _tradePreviewVehicleLabel(),
                    style: TextStyle(
                      color: colorSlate800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: " for about "),
                  TextSpan(
                    text: "\$${_fmtNoSymbol(_tradePreviewPayment)}/mo",
                    style: TextStyle(
                      color: colorSlate800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: "."),
                ],
              ),
            )
          : Text(
              "See what you can upgrade to with your equity.",
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.blueGrey.shade400,
                height: 1.5,
              ),
            ),
      buttonText: "See Upgrades",
      buttonColor: Colors.white,
      buttonBorderColor: Colors.blueGrey.shade200,
      buttonTextColor: colorSlate800,
      onTap: () => widget.setActiveTab('shop'),
    );

    final Widget getCashOpportunityCard = _OpportunityCard(
      icon: LucideIcons.dollarSign,
      iconColor: Colors.teal.shade600,
      iconBg: Colors.teal.shade50,
      title: cashOffer.isLocked
          ? (isUnderwater ? "Building Equity" : "Almost Cash-Ready")
          : "Unlock Your Equity",
      body: cashOffer.isLocked
          ? RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.blueGrey.shade400,
                  height: 1.5,
                ),
                children: [
                  TextSpan(
                    text: isUnderwater
                        ? "You need at least ${fmt(FinanceService.minimumEquityForCashback)} in positive equity to unlock cash access."
                        : "Pay down ",
                  ),
                  if (!isUnderwater)
                    TextSpan(
                      text: fmt(cashOffer.shortfallToUnlock),
                      style: TextStyle(
                        color: colorSlate800,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  if (!isUnderwater)
                    const TextSpan(text: " more to unlock your cash options."),
                ],
              ),
            )
          : RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.blueGrey.shade400,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: "Access up to "),
                  TextSpan(
                    text: "\$${_fmtNoSymbol(cashOffer.maxCash)}",
                    style: TextStyle(
                      color: colorSlate800,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(
                    text: " from your equity today without selling.",
                  ),
                ],
              ),
            ),
      buttonText: cashOffer.isLocked ? "Keep Building" : "Check Options",
      buttonColor: Colors.white,
      buttonBorderColor: Colors.blueGrey.shade200,
      buttonTextColor: colorSlate800,
      onTap: () {
        if (cashOffer.isLocked) {
          _showCashLockedDialog(cashOffer);
          return;
        }
        widget.setOverlayScreen('cash-unlock');
      },
    );

    final Widget? refinanceOpportunityCard = showScanRateOpportunity
        ? _OpportunityCard(
            icon: LucideIcons.scan,
            iconColor: Colors.blue.shade600,
            iconBg: Colors.blue.shade50,
            title: "Check Your Rate",
            body: Text(
              "You might be overpaying. Scan your documents to see if you can lower your payment.",
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.blueGrey.shade400,
                height: 1.5,
              ),
            ),
            buttonText: "Scan Now",
            buttonColor: colorSlate800,
            buttonTextColor: Colors.white,
            onTap: widget.onReverify,
          )
        : showRateAlertOpportunity
        ? _OpportunityCard(
            icon: LucideIcons.arrowRightLeft,
            iconColor: Colors.red.shade600,
            iconBg: Colors.red.shade50,
            title: "Rate Alert",
            body: RichText(
              text: TextSpan(
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  color: Colors.blueGrey.shade400,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: "You pay "),
                  TextSpan(
                    text: "${interestRate.toStringAsFixed(2)}%",
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const TextSpan(text: ". Market is "),
                  TextSpan(
                    text: "${marketRate!.toStringAsFixed(2)}%",
                    style: TextStyle(
                      color: Colors.green.shade600,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextSpan(
                    text:
                        ". You could save ${fmt(refinancePreview!.monthlySavings)}/mo.",
                  ),
                ],
              ),
            ),
            buttonText: "Lower Payment",
            buttonColor: colorSlate800,
            buttonTextColor: Colors.white,
            hasNotification: true,
            onTap: () => widget.setOverlayScreen('refinance'),
          )
        : null;

    final opportunityItems = <_DashboardActionItem>[
      _DashboardActionItem(
        kind: _DashboardActionKind.tradeUp,
        isTerminalAction: false,
        widget: tradeUpOpportunityCard,
      ),
      _DashboardActionItem(
        kind: _DashboardActionKind.getCash,
        isTerminalAction: cashOffer.isLocked,
        widget: getCashOpportunityCard,
      ),
      if (refinanceOpportunityCard != null)
        _DashboardActionItem(
          kind: _DashboardActionKind.refinance,
          isTerminalAction: false,
          widget: refinanceOpportunityCard,
        ),
    ];
    final orderedOpportunityCards = _orderedActionWidgets(opportunityItems);

    return Scaffold(
      backgroundColor: colorSlate50,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- 1. MORPHING HEADER (SliverAppBar) ---
          SliverAppBar(
            expandedHeight:
                460.0, // Increased from 420 to fix 5px overflow and add breathing room
            collapsedHeight: 60.0,
            toolbarHeight: 60.0,
            pinned: true,
            stretch: true,
            backgroundColor: _useDarkBackground
                ? gradientColors[1]
                : colorSlate50, // Matches scaffold to show rounded corners
            systemOverlayStyle: SystemUiOverlayStyle.light,
            elevation: _showStickyHeader ? 10 : 0,
            shadowColor: const Color(0xFF002244).withValues(alpha: 0.3),

            // --- The Compact Sticky Title (Visible when scrolled) ---
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 400),
              curve: Curves.easeOut,
              opacity: _showStickyHeader ? 1.0 : 0.0,
              child: AnimatedSlide(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeOut,
                offset: _showStickyHeader
                    ? Offset.zero
                    : const Offset(0, 0.5), // Slide up from 50% down
                child: Row(
                  children: [
                    // Avatar
                    GestureDetector(
                      onTap: _openProfileScreen,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 44, // Increased from 36
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                            width: 2,
                          ),
                          gradient: LinearGradient(
                            colors: [
                              Colors.blueGrey.shade200,
                              Colors.blueGrey.shade400,
                            ],
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child:
                              AuthService().getAvatarUrl(thumb: '100x100') !=
                                  null
                              ? Image.network(
                                  AuthService().getAvatarUrl(thumb: '100x100')!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Center(
                                        child: Text(
                                          _getInitials(AuthService().userName),
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                            color: colorSlate800,
                                          ),
                                        ),
                                      ),
                                )
                              : Center(
                                  child: Text(
                                    _getInitials(AuthService().userName),
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: colorSlate800,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Compact Stats
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fmt(equity),
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "EQUITY",
                          style: GoogleFonts.outfit(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE6F0FA), // Ice Blue
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 24,
                      width: 1,
                      color: Colors.white24,
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          balanceDisplayText,
                          style: GoogleFonts.outfit(
                            fontSize: isPaidOff ? 12 : 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          stickyBalanceCaption,
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE6F0FA),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      height: 20,
                      width: 1,
                      color: Colors.white24,
                      margin: const EdgeInsets.symmetric(horizontal: 12),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fmt(monthlyPayment),
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "PAYMENT",
                          style: GoogleFonts.outfit(
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFE6F0FA),
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    // Bell Icon
                    _BellButton(
                      onTap: _openNotificationScreen,
                      showBadge: _unreadNotificationCount > 0,
                    ),
                  ],
                ),
              ),
            ),
            centerTitle: true,
            automaticallyImplyLeading: false,

            // --- The Expanded Background ---
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: gradientColors,
                  ),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(48),
                  ), // rounded-b-[3rem]
                ),
                child: Stack(
                  children: [
                    // Removed texture pattern for cleaner appearance

                    // Content Wrapper
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24.0,
                          vertical: 12,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Top Row (Expanded State - Avatar & Bell)
                            // We hide this with Opacity as we scroll up
                            Opacity(
                              opacity: _expandedHeaderOpacity,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      GestureDetector(
                                        onTap: _openProfileScreen,
                                        child: Container(
                                          width: 44,
                                          height: 44,
                                          padding: const EdgeInsets.all(2),
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white.withValues(
                                                alpha: 0.2,
                                              ),
                                            ),
                                          ),
                                          child: Container(
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: LinearGradient(
                                                colors: [
                                                  Colors.blueGrey.shade200,
                                                  Colors.blueGrey.shade400,
                                                ],
                                              ),
                                            ),
                                            child: ClipRRect(
                                              borderRadius:
                                                  BorderRadius.circular(50),
                                              child:
                                                  AuthService().getAvatarUrl(
                                                        thumb: '100x100',
                                                      ) !=
                                                      null
                                                  ? Image.network(
                                                      AuthService()
                                                          .getAvatarUrl(
                                                            thumb: '100x100',
                                                          )!,
                                                      fit: BoxFit.cover,
                                                      errorBuilder:
                                                          (
                                                            context,
                                                            error,
                                                            stackTrace,
                                                          ) => Center(
                                                            child: Text(
                                                              _getInitials(
                                                                AuthService()
                                                                    .userName,
                                                              ),
                                                              style: GoogleFonts.outfit(
                                                                fontSize: 12,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .bold,
                                                                color:
                                                                    colorSlate800,
                                                              ),
                                                            ),
                                                          ),
                                                    )
                                                  : Center(
                                                      child: Text(
                                                        _getInitials(
                                                          AuthService()
                                                              .userName,
                                                        ),
                                                        style:
                                                            GoogleFonts.outfit(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .bold,
                                                              color:
                                                                  colorSlate800,
                                                            ),
                                                      ),
                                                    ),
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "OWNER",
                                            style: GoogleFonts.outfit(
                                              color: const Color(0xFFE6F0FA),
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.0,
                                            ),
                                          ),
                                          Text(
                                            AuthService().userName.isNotEmpty
                                                ? AuthService().userName
                                                : "Car Owner",
                                            style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 14,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  _BellButton(
                                    onTap: _openNotificationScreen,
                                    showBadge: _unreadNotificationCount > 0,
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Large Net Equity
                            Center(
                              child: Column(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 4,
                                    ),
                                    margin: const EdgeInsets.only(
                                      bottom: 12,
                                    ), // Increased from 8
                                    decoration: BoxDecoration(
                                      color: Colors.black.withValues(
                                        alpha: 0.2,
                                      ),
                                      borderRadius: BorderRadius.circular(50),
                                      border: Border.all(
                                        color: Colors.white.withValues(
                                          alpha: 0.05,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          statusBadgeIcon,
                                          size: 12,
                                          color: statusBadgeColor,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          statusBadgeText,
                                          style: GoogleFonts.outfit(
                                            color: statusBadgeColor,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w600,
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    fmt(equity),
                                    style: GoogleFonts.outfit(
                                      fontSize: 56,
                                      fontWeight: FontWeight.bold,
                                      color: equityAmountColor,
                                      height: 1.0,
                                      letterSpacing: -2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Net Equity Available",
                                    style: GoogleFonts.outfit(
                                      color: const Color(
                                        0xFFE6F0FA,
                                      ).withValues(alpha: 0.8),
                                      fontSize: 12,
                                      fontWeight:
                                          FontWeight.w600, // Slightly bolder
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            const Spacer(),

                            // Glass Info Bar
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(24),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "VEHICLE",
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFFE6F0FA),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8), // Increased from 2
                                  Text(
                                    _vehicleDisplayName(),
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),

                                  const SizedBox(height: 16),
                                  Container(
                                    height: 1,
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                  const SizedBox(height: 16),

                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              "EST. VALUE",
                                              style: GoogleFonts.outfit(
                                                color: const Color(0xFFE6F0FA),
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold,
                                                letterSpacing: 1.0,
                                              ),
                                            ),
                                            Text(
                                              fmt(vehicleValue),
                                              style: GoogleFonts.outfit(
                                                color: Colors.white,
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal:
                                                12, // Reduced from 16 to give more text room
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "BALANCE",
                                                style: GoogleFonts.outfit(
                                                  color: const Color(
                                                    0xFFE6F0FA,
                                                  ),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                              FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: Text(
                                                  balanceDisplayText,
                                                  style: GoogleFonts.outfit(
                                                    color: Colors.white,
                                                    fontSize: isPaidOff
                                                        ? 14
                                                        : 16,
                                                    fontWeight: isPaidOff
                                                        ? FontWeight.bold
                                                        : FontWeight.w600,
                                                    letterSpacing: isPaidOff
                                                        ? 0.5
                                                        : 0,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 30,
                                        color: Colors.white.withValues(
                                          alpha: 0.1,
                                        ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 16,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "PAYMENT",
                                                style: GoogleFonts.outfit(
                                                  color: const Color(
                                                    0xFFE6F0FA,
                                                  ),
                                                  fontSize: 10,
                                                  fontWeight: FontWeight.bold,
                                                  letterSpacing: 1.0,
                                                ),
                                              ),
                                              Text(
                                                fmt(monthlyPayment),
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    "Break-even date passed 4 months ago",
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withValues(
                                        alpha: 0.4,
                                      ),
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "*Balance estimated based on standard payment schedule.",
                                    style: GoogleFonts.outfit(
                                      color: Colors.white.withValues(
                                        alpha: 0.3,
                                      ),
                                      fontSize: 9,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- 2. SCROLLABLE BODY CONTENT ---
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 40,
              ), // Increased from 32
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Verification Required Banner for Skipped Users
                  if (AuthService().onboardingStatus == 'skipped')
                    Container(
                      margin: const EdgeInsets.only(bottom: 32),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF9C3), // Yellow-100
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: const Color(0xFFFDE047)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Icon(
                                LucideIcons.alertTriangle,
                                color: Color(0xFF854D0E),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  "Verification Required",
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF854D0E),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Scan your loan documents to unlock precise equity tracking and personalized refinance offers.",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: const Color(0xFF713F12),
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: widget.onReverify,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF854D0E),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text("Verify Now"),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // A. Quick Actions
                  Text(
                    "Quick Actions",
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: colorSlate800,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      ...orderedQuickActionWidgets,
                      _ActionButton(
                        icon: LucideIcons.wrench,
                        label: "Garage",
                        onTap: () => widget.setActiveTab('garage'),
                      ),
                    ],
                  ),
                  if (showCashProgress) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blueGrey.shade50),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                LucideIcons.lock,
                                size: 14,
                                color: Colors.blueGrey.shade500,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  "Pay down ${fmt(cashOffer.shortfallToUnlock)} more to unlock Cash Mode.",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF1E293B),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          LinearProgressIndicator(
                            value:
                                (cashOffer.equity /
                                        FinanceService.minimumEquityForCashback)
                                    .clamp(0.0, 1.0),
                            minHeight: 8,
                            borderRadius: BorderRadius.circular(100),
                            backgroundColor: Colors.blueGrey.shade100,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.green.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),

                  // B. Opportunities
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Opportunities",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorSlate800,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: colorSlate50,
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          _unreadNotificationCount > 0
                              ? "$_unreadNotificationCount New"
                              : "Live",
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: Colors.blueGrey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Horizontal List
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    clipBehavior: Clip.none, // Allow shadows to overflow
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: [
                        for (
                          int i = 0;
                          i < orderedOpportunityCards.length;
                          i++
                        ) ...[
                          orderedOpportunityCards[i],
                          if (i < orderedOpportunityCards.length - 1)
                            const SizedBox(width: 16),
                        ],
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // C. Recent Activity
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Recent Activity",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorSlate800,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  const ActivityHistoryScreen(),
                            ),
                          );
                        },
                        child: Text(
                          "See all",
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.blueGrey.shade300,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(color: colorSlate50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(4),
                    child: _recentActivities.isEmpty
                        ? Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              "No recent activity yet.",
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: Colors.blueGrey.shade400,
                              ),
                            ),
                          )
                        : Column(
                            children: _recentActivities.take(4).map((activity) {
                              final visual = _activityVisual(activity);
                              return _ActivityItem(
                                icon: visual.icon,
                                color: visual.color,
                                bg: visual.bg,
                                title: activity.title,
                                desc: activity.description,
                                date: _relativeTime(activity.created),
                              );
                            }).toList(),
                          ),
                  ),

                  // Bottom Padding
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SUB-WIDGETS ---

class _BellButton extends StatelessWidget {
  final VoidCallback onTap;
  final bool showBadge;
  const _BellButton({required this.onTap, this.showBadge = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        width: 44, // Increased from 40
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(LucideIcons.bell, color: Colors.white, size: 18),
            if (showBadge)
              Positioned(
                top: 10,
                right: 10,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.red.shade400,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.shade400.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

enum _DashboardActionKind { tradeUp, getCash, refinance }

class _DashboardActionItem {
  final _DashboardActionKind kind;
  final bool isTerminalAction;
  final Widget widget;

  const _DashboardActionItem({
    required this.kind,
    required this.isTerminalAction,
    required this.widget,
  });
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isLocked;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isLocked = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color iconColor = isLocked
        ? Colors.blueGrey.shade300
        : Colors.blueGrey.shade600;
    final Color labelColor = isLocked
        ? Colors.blueGrey.shade300
        : Colors.blueGrey.shade500;
    final Color bgColor = isLocked ? Colors.blueGrey.shade50 : Colors.white;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60, // w-14 h-14 approx
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blueGrey.shade50),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(child: Icon(icon, color: iconColor, size: 24)),
              ),
              if (isLocked)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: const Icon(
                      LucideIcons.lock,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: labelColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _OpportunityCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Widget body;
  final String buttonText;
  final Color buttonColor;
  final Color buttonTextColor;
  final Color? buttonBorderColor;
  final bool hasNotification;
  final VoidCallback onTap;

  const _OpportunityCard({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.body,
    required this.buttonText,
    required this.buttonColor,
    required this.buttonTextColor,
    this.buttonBorderColor,
    this.hasNotification = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          if (hasNotification)
            Positioned(
              right: 0,
              top: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
            ),

          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(child: Icon(icon, color: iconColor, size: 20)),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              body,
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onTap,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    foregroundColor: buttonTextColor,
                    elevation: 0,
                    side: buttonBorderColor != null
                        ? BorderSide(color: buttonBorderColor!)
                        : BorderSide.none,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        buttonText,
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (hasNotification) ...[
                        const SizedBox(width: 8),
                        const Icon(LucideIcons.chevronRight, size: 14),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActivityVisual {
  final IconData icon;
  final Color color;
  final Color bg;

  const _ActivityVisual({
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String desc;
  final String? date;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.desc,
    this.date,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
            child: Center(child: Icon(icon, color: color, size: 18)),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                Text(
                  desc,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    color: Colors.blueGrey.shade300,
                  ),
                ),
              ],
            ),
          ),
          Text(
            date ?? '-',
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey.shade300,
            ),
          ),
        ],
      ),
    );
  }
}
