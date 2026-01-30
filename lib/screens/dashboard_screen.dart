import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

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

  const DashboardScreen({
    super.key,
    required this.carDetails,
    required this.setOverlayScreen,
    required this.setActiveTab,
  });

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ScrollController _scrollController = ScrollController();

  // State to track scroll for animations
  bool _isScrolled = false;

  // Derived Numbers
  final double vehicleValue = 22500;
  final double loanBalance = 18000;
  double get equity => vehicleValue - loanBalance;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_scrollListener);
  }

  void _scrollListener() {
    setState(() {
      // Trigger "Scrolled" state slightly before the top to smooth the transition
      if (_scrollController.offset > 50 && !_isScrolled) {
        _isScrolled = true;
      } else if (_scrollController.offset <= 50 && _isScrolled) {
        _isScrolled = false;
      }
    });
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
            collapsedHeight: 80.0, // Height of the sticky bar
            toolbarHeight: 80.0,
            pinned: true,
            stretch: true,
            backgroundColor: gradientColors[1], // Fallback color
            elevation: _isScrolled ? 10 : 0,
            shadowColor: const Color(0xFF002244).withOpacity(0.3),

            // --- The Compact Sticky Title (Visible when scrolled) ---
            title: AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isScrolled ? 1.0 : 0.0,
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
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        "LOAN",
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE6F0FA), // Ice Blue
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Bell Icon
                  const _BellButton(),
                ],
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
                    // Texture Overlay (Simulated)
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.1,
                        child: CustomPaint(painter: _PatternPainter()),
                      ),
                    ),

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
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 200),
                              opacity: _isScrolled ? 0.0 : 1.0,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Container(
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
                                  const _BellButton(),
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
                                      ).withOpacity(0.8),
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
                                          padding: const EdgeInsets.only(
                                            left: 16,
                                          ),
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "LOAN BAL",
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
                                    ],
                                  ),
                                ],
                              ),
                            ),

                            const SizedBox(height: 16),
                            Center(
                              child: Text(
                                "Break-even date passed 4 months ago",
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withValues(alpha: 0.4),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
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
                        _OpportunityCard(
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
                                  text: "8.99%",
                                  style: TextStyle(
                                    color: Colors.red.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(text: ". Market is "),
                                TextSpan(
                                  text: "6.99%",
                                  style: TextStyle(
                                    color: Colors.green.shade600,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const TextSpan(text: ". Save \$52/mo."),
                              ],
                            ),
                          ),
                          buttonText: "Lower Payment",
                          buttonColor: colorSlate800,
                          buttonTextColor: Colors.white,
                          hasNotification: true,
                          onTap: () => widget.setOverlayScreen('refinance'),
                        ),
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
                      Text(
                        "See all",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.blueGrey.shade300,
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
  const _BellButton();

  @override
  Widget build(BuildContext context) {
    return Container(
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

// Simple texture painter to replicate the "cubes" pattern
class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    for (double i = 0; i < size.width; i += 20) {
      for (double j = 0; j < size.height; j += 20) {
        if ((i + j) % 40 == 0) {
          canvas.drawCircle(Offset(i, j), 1, paint..style = PaintingStyle.fill);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
