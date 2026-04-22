import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart' hide TextDirection; // <--- ADD THIS HIDE
import '../components/custom_slider_components.dart';

// --- Data Models ---
class CarDetails {
  final String year;
  final String make;
  final String model;
  CarDetails({required this.year, required this.make, required this.model});
}

class Financials {
  double estimatedValue;
  double userEstimatedLoan;
  double get equity => estimatedValue - userEstimatedLoan;

  Financials({required this.estimatedValue, required this.userEstimatedLoan});
}

class TeaserEquityScreen extends StatefulWidget {
  final CarDetails carDetails;
  final Financials financials;
  final VoidCallback onNext;
  final VoidCallback? onBack;

  const TeaserEquityScreen({
    super.key,
    required this.carDetails,
    required this.financials,
    required this.onNext,
    this.onBack,
  });

  @override
  State<TeaserEquityScreen> createState() => _TeaserEquityScreenState();
}

class _TeaserEquityScreenState extends State<TeaserEquityScreen> {
  late double sliderValue;

  @override
  void initState() {
    super.initState();
    sliderValue = widget.financials.userEstimatedLoan;
  }

  void _updateSlider(double value) {
    setState(() {
      sliderValue = value;
      widget.financials.userEstimatedLoan = value;
    });
  }

  // FIXED: Changed symbol to '$' only
  String fmt(num n) {
    return NumberFormat.currency(
      locale: 'en_CA',
      symbol: '\$',
      decimalDigits: 0,
    ).format(n);
  }

  @override
  Widget build(BuildContext context) {
    // Updated color palette
    const colorIceBlue = Color(0xFFE6F0FA);
    const colorNearBlack = Color(0xFF1A1A1B);
    const colorMidnightNavy = Color(0xFF003366);
    const colorNavyDark = Color(0xFF002244);
    const colorVibrantGreen = Color(0xFF00CA50);
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final compact = viewportHeight < 840;
    final veryCompact = viewportHeight < 740;

    final headerTopPadding = veryCompact ? 24.0 : (compact ? 36.0 : 60.0);
    final headerBottomPadding = veryCompact ? 44.0 : (compact ? 64.0 : 96.0);
    final headerValueSize = veryCompact ? 40.0 : (compact ? 44.0 : 48.0);
    final headerCarNameSize = veryCompact ? 16.0 : 18.0;
    final overlapOffset = veryCompact ? -26.0 : (compact ? -34.0 : -48.0);
    final contentHorizontalPadding = veryCompact ? 20.0 : 32.0;
    final contentTopPadding = veryCompact ? 18.0 : (compact ? 24.0 : 40.0);
    final contentBottomPadding = veryCompact ? 14.0 : 20.0;
    final sectionTitleSize = veryCompact ? 18.0 : 20.0;
    final sectionGap = veryCompact ? 14.0 : (compact ? 20.0 : 32.0);
    final cardPadding = veryCompact ? 16.0 : (compact ? 20.0 : 24.0);
    final loanValueSize = veryCompact ? 24.0 : (compact ? 26.0 : 30.0);
    final sliderTrackHeight = veryCompact ? 12.0 : 16.0;
    final sliderThumbRadius = veryCompact ? 14.0 : 16.0;
    final sliderThumbBorderWidth = veryCompact ? 3.0 : 4.0;
    final equityLabelSize = veryCompact ? 12.0 : 14.0;
    final equityValueSize = veryCompact ? 18.0 : 20.0;
    final ctaHeight = veryCompact ? 50.0 : 56.0;
    final ctaTextSize = veryCompact ? 16.0 : 18.0;
    final showInsight = !veryCompact;
    final showCreditNote = !veryCompact;

    return Scaffold(
      backgroundColor: colorIceBlue,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // --- 1. THE ORGANIC HEADER (Red Surface) ---
            Stack(
              children: [
                // Background Gradient
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.only(
                    top: headerTopPadding,
                    bottom: headerBottomPadding,
                    left: contentHorizontalPadding,
                    right: contentHorizontalPadding,
                  ),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        colorMidnightNavy,
                        Color(0xFF002E5C),
                        Color(0xFF002852),
                        Color(0xFF002347),
                        colorNavyDark,
                      ],
                      stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              LucideIcons.trendingUp,
                              color: Colors.white,
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              "Market Value Updated",
                              style: GoogleFonts.outfit(
                                color: const Color(0xFFFEF2F2),
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Value
                      Text(
                        fmt(widget.financials.estimatedValue),
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontSize: headerValueSize,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1.0,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Car Name
                      Text(
                        "${widget.carDetails.year} ${widget.carDetails.make} ${widget.carDetails.model}",
                        style: GoogleFonts.outfit(
                          color: colorIceBlue.withValues(alpha: 0.9),
                          fontSize: headerCarNameSize,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Abstract Depth Blobs
                Positioned(
                  top: -150,
                  left: -100,
                  child: Container(
                    width: 400,
                    height: 400,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.1),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -80,
                  right: -50,
                  child: Container(
                    width: 300,
                    height: 300,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withValues(alpha: 0.15),
                          Colors.white.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                ),

                // Back Button (Moved to end to be on top)
                Positioned(
                  top: 48,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(
                      LucideIcons.arrowLeft,
                      color: Colors.white,
                    ),
                    onPressed:
                        widget.onBack ?? () => Navigator.of(context).pop(),
                  ),
                ),
              ],
            ),

            // --- 2. THE OVERLAPPING SHEET (Content Layer) ---
            Expanded(
              child: Transform.translate(
                offset: Offset(0, overlapOffset),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorIceBlue,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 14,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: contentTopPadding,
                      left: contentHorizontalPadding,
                      right: contentHorizontalPadding,
                      bottom: contentBottomPadding,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Handle Bar
                        Center(
                          child: Container(
                            width: 48,
                            height: 6,
                            margin: EdgeInsets.only(bottom: compact ? 14 : 24),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE2E8F0),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ),

                        // Section Title
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "What do you owe?",
                              style: GoogleFonts.outfit(
                                fontSize: sectionTitleSize,
                                fontWeight: FontWeight.bold,
                                color: colorNearBlack,
                              ),
                            ),
                            Tooltip(
                              message: "Estimate your remaining loan balance.",
                              triggerMode: TooltipTriggerMode.tap,
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1E293B),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              textStyle: GoogleFonts.outfit(
                                color: Colors.white,
                                fontSize: 10,
                              ),
                              child: const Icon(
                                LucideIcons.info,
                                size: 20,
                                color: Color(0xFFCBD5E1),
                              ),
                            ),
                          ],
                        ),

                        SizedBox(height: sectionGap),

                        // Interactive Slider Card
                        Container(
                          padding: EdgeInsets.all(cardPadding),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.05),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              // Label Row
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Est. Loan",
                                    style: GoogleFonts.outfit(
                                      color: const Color(0xFF64748B),
                                      fontWeight: FontWeight.w500,
                                      fontSize: 14,
                                    ),
                                  ),
                                  Text(
                                    fmt(sliderValue),
                                    style: GoogleFonts.outfit(
                                      color: colorNearBlack,
                                      fontSize: loanValueSize,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),

                              SizedBox(height: compact ? 16 : 24),
                              // Custom Slider
                              SizedBox(
                                height: compact ? 28 : 32,
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: sliderTrackHeight,
                                    activeTrackColor: colorVibrantGreen,
                                    inactiveTrackColor: const Color(0xFFF1F5F9),
                                    overlayColor: Colors.transparent,
                                    trackShape: const CustomSliderTrackShape(),
                                    // Custom thumb shape with green accent
                                    thumbShape: CustomSliderThumbShape(
                                      thumbRadius: sliderThumbRadius,
                                      borderWidth: sliderThumbBorderWidth,
                                      borderColor: colorVibrantGreen,
                                    ),
                                  ),
                                  child: Slider(
                                    value: sliderValue,
                                    min: 0,
                                    max: 35000,
                                    divisions: (35000 / 500).round(),
                                    onChanged: _updateSlider,
                                  ),
                                ),
                              ),

                              const SizedBox(height: 24),

                              // Net Equity Result
                              Container(
                                padding: const EdgeInsets.only(top: 16),
                                decoration: const BoxDecoration(
                                  border: Border(
                                    top: BorderSide(color: Color(0xFFF1F5F9)),
                                  ),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      "YOUR EQUITY",
                                      style: GoogleFonts.outfit(
                                        color: const Color(0xFF94A3B8),
                                        fontSize: equityLabelSize,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.0,
                                      ),
                                    ),
                                    Text(
                                      "${widget.financials.equity > 0 ? '+' : ''}${fmt(widget.financials.equity)}",
                                      style: GoogleFonts.outfit(
                                        color: widget.financials.equity > 0
                                            ? colorVibrantGreen
                                            : const Color(0xFF94A3B8),
                                        fontSize: equityValueSize,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        SizedBox(height: compact ? 10 : 16),

                        // Insight Text
                        if (showInsight)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              "Based on this balance, you could qualify for lower monthly payments.",
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                color: const Color(0xFF94A3B8),
                                fontSize: compact ? 12 : 14,
                              ),
                            ),
                          ),

                        SizedBox(height: compact ? 12 : 24),

                        // --- 3. CTA BUTTON ---
                        Container(
                          width: double.infinity,
                          height: ctaHeight,
                          decoration: BoxDecoration(
                            color: colorVibrantGreen,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorVibrantGreen.withValues(
                                  alpha: 0.14,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 0),
                              ),
                            ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: widget.onNext,
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Check My Actual Rate",
                                    style: GoogleFonts.outfit(
                                      color: Colors.white,
                                      fontSize: ctaTextSize,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Icon(
                                    LucideIcons.arrowRight,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        SizedBox(height: compact ? 6 : 8),

                        if (showCreditNote)
                          Text(
                            "NO IMPACT TO CREDIT SCORE",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFFCBD5E1),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.5,
                            ),
                          ),
                      ],
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
