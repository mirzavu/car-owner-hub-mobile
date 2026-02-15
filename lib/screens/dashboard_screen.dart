import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
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
    this.onFinancialsUpdate,
  });

  final Function(Map<String, dynamic>)? onFinancialsUpdate;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  // State to track scroll for animations
  double _expandedHeaderOpacity = 1.0;
  bool _showStickyHeader = false;
  bool _useDarkBackground = false;

  // Real Data State
  double vehicleValue = 22500;
  double loanBalance = 18000;
  double monthlyPayment = 420;
  double interestRate = 8.99;

  double get equity => vehicleValue - loanBalance;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
    _fetchDashboardData();
  }

  Future<void> _fetchDashboardData() async {
    try {
      final data = await ApiService.getDashboardData();
      final financials = data['financials'] ?? {};
      setState(() {
        vehicleValue = (financials['vehicleValue'] ?? 22500).toDouble();
        loanBalance = (financials['loanBalance'] ?? 18000).toDouble();
        // If loan is paid off, payment must be 0
        if (loanBalance == 0) {
          monthlyPayment = 0.0;
        } else {
          monthlyPayment = (financials['monthlyPayment'] ?? 420).toDouble();
        }
        interestRate = (financials['interestRate'] ?? 8.99).toDouble();
      });
      if (widget.onFinancialsUpdate != null) {
        widget.onFinancialsUpdate!({
          'actualRate': interestRate,
          'monthlyPayment': monthlyPayment,
          'loanBalance': loanBalance,
          'vehicleValue': vehicleValue,
        });
      }
    } catch (e) {
      debugPrint("Error fetching dashboard data: $e");
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
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  String fmt(num n) {
    return NumberFormat.currency(
      locale: 'en_CA',
      symbol: '\$',
      decimalDigits: 0,
    ).format(n);
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

    return Scaffold(
      backgroundColor: colorSlate50,
      body: CustomScrollView(
        controller: _scrollController,
        physics: const BouncingScrollPhysics(),
        slivers: [
          // --- 1. MORPHING HEADER (SliverAppBar) ---
          SliverAppBar(
            expandedHeight: 420.0, // Height of the open header
            collapsedHeight: 60.0, // Height of the sticky bar
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
                    Container(
                      width: 36,
                      height: 36,
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
                      child: GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) =>
                                  ProfileScreen(onLogout: widget.onLogout),
                            ),
                          );
                        },
                        child: Center(
                          child: Text(
                            "MW",
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: colorSlate800,
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
                          fmt(loanBalance),
                          style: GoogleFonts.outfit(
                            fontSize: 13, // Slightly smaller to fit 3 items
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          "BAL",
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
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const NotificationScreen(),
                          ),
                        );
                      },
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
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  ProfileScreen(
                                                    onLogout: widget.onLogout,
                                                  ),
                                            ),
                                          );
                                        },
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
                                            child: Center(
                                              child: Text(
                                                "MW",
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
                                            "Mikel Wills",
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
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              const NotificationScreen(),
                                        ),
                                      );
                                    },
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
                                    margin: const EdgeInsets.only(bottom: 8),
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
                                          LucideIcons.checkCircle2,
                                          size: 12,
                                          color: Colors.greenAccent.shade400,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          "IN THE GREEN",
                                          style: GoogleFonts.outfit(
                                            color: Colors.greenAccent.shade100,
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
                                      color: Colors.white,
                                      height: 1.0,
                                      letterSpacing: -2.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "Net Equity Available",
                                    style: GoogleFonts.outfit(
                                      color: const Color(
                                        0xFFE6F0FA,
                                      ).withValues(alpha: 0.8),
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
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
                                  const SizedBox(height: 2),
                                  Text(
                                    "${widget.carDetails.year} ${widget.carDetails.make} ${widget.carDetails.model}",
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
                                            horizontal: 16,
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
                                              Text(
                                                fmt(loanBalance),
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
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
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
                      _ActionButton(
                        icon: LucideIcons.arrowRightLeft,
                        label: "Refinance",
                        onTap: () => widget.setOverlayScreen('refinance'),
                      ),
                      _ActionButton(
                        icon: LucideIcons.dollarSign,
                        label: "Get Cash",
                        onTap: () => widget.setOverlayScreen('cash-unlock'),
                      ),
                      _ActionButton(
                        icon: LucideIcons.car,
                        label: "Trade Up",
                        onTap: () => widget.setActiveTab('shop'),
                      ),
                      _ActionButton(
                        icon: LucideIcons.wrench,
                        label: "Garage",
                        onTap: () => widget.setActiveTab('garage'),
                      ),
                    ],
                  ),

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
                          "3 New",
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
                        // --- REFINE LOGIC ---
                        if (AuthService().onboardingStatus == 'skipped' ||
                            interestRate == 0)
                          _OpportunityCard(
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
                        else if (interestRate >= 9.99)
                          _OpportunityCard(
                            icon: LucideIcons.arrowRightLeft,
                            iconColor: interestRate >= 14.99
                                ? Colors.orange.shade700
                                : Colors.red.shade600,
                            iconBg: interestRate >= 14.99
                                ? Colors.orange.shade50
                                : Colors.red.shade50,
                            title: interestRate >= 14.99
                                ? "⚠️ Overpaying!"
                                : "Rate Alert",
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
                                    text: "7.99%",
                                    style: TextStyle(
                                      color: Colors.green.shade600,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  TextSpan(
                                    text: interestRate >= 14.99
                                        ? ". Save \$100+/mo immediately."
                                        : ". You could save ~\$25/mo.",
                                  ),
                                ],
                              ),
                            ),
                            buttonText: "Lower Payment",
                            buttonColor: colorSlate800,
                            buttonTextColor: Colors.white,
                            hasNotification: true,
                            onTap: () => widget.setOverlayScreen('refinance'),
                          ),
                        if (AuthService().onboardingStatus != 'skipped' &&
                            interestRate != 0 &&
                            interestRate >= 9.99)
                          const SizedBox(width: 16),
                        if (AuthService().onboardingStatus == 'skipped' ||
                            interestRate == 0)
                          const SizedBox(width: 16),
                        _OpportunityCard(
                          icon: LucideIcons.dollarSign,
                          iconColor: Colors.teal.shade600,
                          iconBg: Colors.teal.shade50,
                          title: "Unlock Cash",
                          body: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.blueGrey.shade400,
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(text: "Access up to "),
                                TextSpan(
                                  text: "\$3,000",
                                  style: TextStyle(
                                    color: colorSlate800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(
                                  text:
                                      " from your equity today without selling.",
                                ),
                              ],
                            ),
                          ),
                          buttonText: "Check Options",
                          buttonColor: Colors.white,
                          buttonBorderColor: Colors.blueGrey.shade200,
                          buttonTextColor: colorSlate800,
                          onTap: () => widget.setOverlayScreen('cash-unlock'),
                        ),
                        const SizedBox(width: 16),
                        _OpportunityCard(
                          icon: LucideIcons.car,
                          iconColor: Colors.blue.shade600,
                          iconBg: Colors.blue.shade50,
                          title: "Trade Up",
                          body: RichText(
                            text: TextSpan(
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: Colors.blueGrey.shade400,
                                height: 1.5,
                              ),
                              children: [
                                const TextSpan(text: "Drive a "),
                                TextSpan(
                                  text: "2026 Model",
                                  style: TextStyle(
                                    color: colorSlate800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(text: " for the same "),
                                TextSpan(
                                  text: "\$420/mo",
                                  style: TextStyle(
                                    color: colorSlate800,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(text: "."),
                              ],
                            ),
                          ),
                          buttonText: "See Upgrades",
                          buttonColor: Colors.white,
                          buttonBorderColor: Colors.blueGrey.shade200,
                          buttonTextColor: colorSlate800,
                          onTap: () => widget.setActiveTab('shop'),
                        ),
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
                    child: const Column(
                      children: [
                        _ActivityItem(
                          icon: LucideIcons.shieldCheck,
                          color: Color(0xFF2563EB),
                          bg: Color(0xFFDBEAFE),
                          title: "Insurance Verified",
                          desc: "Policy renewed successfully",
                          date: "Today",
                        ),
                        _ActivityItem(
                          icon: LucideIcons.trendingUp,
                          color: Color(0xFF059669),
                          bg: Color(0xFFD1FAE5),
                          title: "Equity Updated",
                          desc: "Market value increased",
                          value: "+\$150",
                        ),
                        _ActivityItem(
                          icon: LucideIcons.checkCircle2,
                          color: Color(0xFF475569),
                          bg: Color(0xFFF1F5F9),
                          title: "Payment Received",
                          desc: "Loan installment processed",
                          date: "July 28",
                        ),
                        _ActivityItem(
                          icon: LucideIcons.fileText,
                          color: Color(0xFFD97706),
                          bg: Color(0xFFFEF3C7),
                          title: "Registration Check",
                          desc: "Valid until Dec 2026",
                          date: "July 15",
                        ),
                      ],
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
  const _BellButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(LucideIcons.bell, color: Colors.white, size: 18),
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

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 60,
            height: 60, // w-14 h-14 approx
            decoration: BoxDecoration(
              color: Colors.white,
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
            child: Center(
              child: Icon(icon, color: Colors.blueGrey.shade600, size: 24),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: Colors.blueGrey.shade500,
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

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color bg;
  final String title;
  final String desc;
  final String? date;
  final String? value;

  const _ActivityItem({
    required this.icon,
    required this.color,
    required this.bg,
    required this.title,
    required this.desc,
    this.date,
    this.value,
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
          if (value != null)
            Text(
              value!,
              style: GoogleFonts.outfit(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF059669),
              ),
            )
          else
            Text(
              date!,
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
