import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart' hide TextDirection; // <--- ADD THIS HIDE

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

class TeaserScreen extends StatefulWidget {
  final CarDetails carDetails;
  final Financials financials;
  final VoidCallback onNext;

  const TeaserScreen({
    super.key,
    required this.carDetails,
    required this.financials,
    required this.onNext,
  });

  @override
  State<TeaserScreen> createState() => _TeaserScreenState();
}

class _TeaserScreenState extends State<TeaserScreen> {
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

    return Scaffold(
      backgroundColor: colorIceBlue,
      body: SizedBox(
        height: MediaQuery.of(context).size.height,
        child: Column(
          children: [
            // --- 1. THE ORGANIC HEADER (Red Surface) ---
            Stack(
              children: [
                // Background Gradient
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.only(
                    top: 60,
                    bottom: 96,
                    left: 32,
                    right: 32,
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
                          color: Colors.white.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.1),
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
                          fontSize: 48,
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
                          color: colorIceBlue.withOpacity(0.9),
                          fontSize: 18,
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
                          Colors.white.withOpacity(0.1),
                          Colors.white.withOpacity(0.0),
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
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // --- 2. THE OVERLAPPING SHEET (Content Layer) ---
            Expanded(
              child: Transform.translate(
                offset: const Offset(0, -48),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colorIceBlue,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(40),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 40,
                        offset: const Offset(0, -10),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: const EdgeInsets.only(
                      top: 40,
                      left: 32,
                      right: 32,
                      bottom: 24,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Handle Bar
                        Center(
                          child: Container(
                            width: 48,
                            height: 6,
                            margin: const EdgeInsets.only(bottom: 30),
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
                                fontSize: 20,
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

                        const SizedBox(height: 32),

                        // Interactive Slider Card
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: const Color(0xFFF1F5F9)),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
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
                                      fontSize: 30,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: -0.5,
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 24),
                              // Custom Slider
                              SizedBox(
                                height: 32, // Height for thumb touch target
                                child: SliderTheme(
                                  data: SliderTheme.of(context).copyWith(
                                    trackHeight: 16,
                                    activeTrackColor: colorVibrantGreen,
                                    inactiveTrackColor: const Color(0xFFF1F5F9),
                                    overlayColor: Colors.transparent,
                                    trackShape: const _CustomTrackShape(),
                                    // Custom thumb shape with green accent
                                    thumbShape: const _CustomThumbShape(
                                      thumbRadius: 16, // w-8 = 32px diameter
                                      borderWidth: 4, // border-4
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
                                        // FIXED: Changed to 14px to match React text-sm
                                        fontSize: 14,
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
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Insight Text
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            "Based on this balance, you could qualify for lower monthly payments.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: const Color(0xFF94A3B8),
                              fontSize: 14,
                            ),
                          ),
                        ),

                        const Spacer(),

                        // --- 3. CTA BUTTON ---
                        Container(
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colorVibrantGreen,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: colorVibrantGreen.withOpacity(0.3),
                                blurRadius: 20,
                                offset: const Offset(0, 10),
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
                                      fontSize: 18,
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

                        const SizedBox(height: 8),

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

class _CustomThumbShape extends SliderComponentShape {
  final double thumbRadius;
  final double borderWidth;
  final Color borderColor;

  const _CustomThumbShape({
    required this.thumbRadius,
    required this.borderWidth,
    required this.borderColor,
  });

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double
    textScaleFactor, // Remove this line if on older Flutter, keep for compatibility check
    required Size sizeWithOverflow,
  }) {
    // Note: If you are on the absolute latest Flutter (3.27+), 'textScaleFactor' is removed completely.
    // If you get an error saying "paint has too many arguments", delete the 'required double textScaleFactor,' line above.

    final Canvas canvas = context.canvas;

    // 1. Draw Shadow
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    canvas.drawCircle(center + const Offset(0, 4), thumbRadius, shadowPaint);

    // 2. Draw Red Border
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, thumbRadius, borderPaint);

    // 3. Draw White Inner Circle
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, thumbRadius - borderWidth, innerPaint);
  }
}

class _CustomTrackShape extends RoundedRectSliderTrackShape {
  const _CustomTrackShape();

  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight!;
    final double trackLeft = offset.dx;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
