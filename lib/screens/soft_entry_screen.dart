import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/car_icon.dart';

class SoftEntryScreen extends StatefulWidget {
  final ValueChanged<String> onNext;
  final VoidCallback? onBack;

  const SoftEntryScreen({super.key, required this.onNext, this.onBack});

  @override
  State<SoftEntryScreen> createState() => _SoftEntryScreenState();
}

class _SoftEntryScreenState extends State<SoftEntryScreen> {
  bool loading = false;
  String loadingText = '';

  // Form Values
  String year = '2023';
  String make = 'Honda';
  String model = 'Civic';
  String trim = 'EX';

  void handleNext() {
    setState(() {
      loading = true;
      loadingText = 'Connecting to Canadian Black Book...';
    });

    Future.delayed(const Duration(milliseconds: 1500), () {
      if (!mounted) return;
      setState(() {
        loadingText = 'Analyzing local market trends...';
      });

      Future.delayed(const Duration(milliseconds: 1500), () {
        if (!mounted) return;
        setState(() {
          loading = false;
        });
        widget.onNext('teaser');
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // LOADING STATE - EXACT MATCH TO JSX
    if (loading) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Spinner: navy theme
              SizedBox(
                width: 64,
                height: 64,
                child: CircularProgressIndicator(
                  strokeWidth: 4,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    Color(0xFF003366),
                  ), // Midnight Navy
                  backgroundColor: const Color(0xFFE6F0FA), // Ice Blue
                ),
              ),
              const SizedBox(height: 24), // mb-6
              // Text: text-lg font-bold text-slate-800 animate-pulse
              AnimatedOpacity(
                duration: const Duration(milliseconds: 500),
                opacity: 1.0,
                child: Text(
                  loadingText,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E293B), // slate-800
                    fontSize: 18, // text-lg
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // MAIN UI - EXACT MATCH TO JSX
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC), // slate-50
      body: LayoutBuilder(
        builder: (context, constraints) {
          // Header: h-[35vh] min-h-[280px]
          final headerHeight = constraints.maxHeight * 0.35;
          final minHeaderHeight = 280.0;
          final actualHeaderHeight = headerHeight > minHeaderHeight
              ? headerHeight
              : minHeaderHeight;

          // Overlap: -mt-10 = 40px
          const overlapHeight = 40.0;

          return Stack(
            children: [
              // --- HEADER SECTION ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: actualHeaderHeight,
                child: Stack(
                  children: [
                    // Gradient: Midnight Navy
                    Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Color(0xFF003366), // Midnight Navy
                            Color(0xFF002E5C), // Intermediate
                            Color(0xFF002852), // Intermediate
                            Color(0xFF002347), // Intermediate
                            Color(0xFF002244), // Darker Navy
                          ],
                          stops: [0.0, 0.25, 0.5, 0.75, 1.0],
                        ),
                      ),
                    ),

                    // Dot Pattern: opacity-[0.05] bg-[radial-gradient(circle_at_center,#fff_1.5px,transparent_1.5px)] [background-size:20px_20px]
                    Positioned.fill(
                      child: Opacity(
                        opacity: 0.05,
                        child: CustomPaint(painter: DotPatternPainter()),
                      ),
                    ),

                    // Background Ambience: top-[-50%] left-[50%] w-[400px] h-[400px] blur-[80px] mix-blend-overlay
                    Positioned.fill(
                      child: CustomPaint(painter: OverlayBlobPainter()),
                    ),

                    // HEADER CONTENT - Centered
                    Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                        ), // px-6
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Icon: w-20 h-20 rounded-[2rem] with glassmorphism
                            Container(
                              width: 80,
                              height: 80,
                              margin: const EdgeInsets.only(bottom: 24), // mb-6
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(32),
                                // This base color "blocks" the shadow from bleeding into the semi-transparent center
                                color: Colors.white.withOpacity(0.05),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.12),
                                    blurRadius: 25,
                                    offset: const Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(32),
                                child: BackdropFilter(
                                  filter: ImageFilter.blur(
                                    sigmaX: 12,
                                    sigmaY: 12,
                                  ), // Adjusted for vibrancy
                                  child: Container(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.white.withOpacity(
                                            0.15,
                                          ), // Very light white
                                          const Color(0xFFE6F0FA).withOpacity(
                                            0.05,
                                          ), // Hint of Ice Blue
                                        ],
                                      ),
                                    ),
                                    child: const Center(
                                      child: CarIcon(
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // Headline: text-4xl font-black leading-tight tracking-tighter
                            Column(
                              children: [
                                Text(
                                  "Value your vehicle",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 36, // text-4xl
                                    fontWeight: FontWeight.w900, // font-black
                                    height: 1.25, // leading-tight
                                    letterSpacing: -1.8, // tracking-tighter
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  "instantly.",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    color: const Color(
                                      0xFFE6F0FA,
                                    ).withOpacity(0.9), // Ice Blue/90
                                    fontSize: 32.4, // text-[0.9em]
                                    fontWeight: FontWeight.w900,
                                    height: 1.25,
                                    letterSpacing: -1.6,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.15),
                                        blurRadius: 2,
                                        offset: const Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),

                            const SizedBox(height: 16), // mb-4 equivalent
                            // Pill: text-xs font-bold uppercase tracking-[0.2em] bg-white/10 px-4 py-1.5 rounded-full backdrop-blur-md
                            ClipRRect(
                              borderRadius: BorderRadius.circular(
                                999,
                              ), // rounded-full
                              child: BackdropFilter(
                                filter: ImageFilter.blur(
                                  sigmaX: 12,
                                  sigmaY: 12,
                                ), // backdrop-blur-md
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16, // px-4
                                    vertical: 6, // py-1.5
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(
                                      0.1,
                                    ), // bg-white/10
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    "NO VIN REQUIRED",
                                    style: GoogleFonts.outfit(
                                      color: const Color(
                                        0xFFE6F0FA,
                                      ), // Ice Blue
                                      fontSize: 12, // text-xs
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2.4, // tracking-[0.2em]
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- GRID SYSTEM BODY ---
              // -mt-10 overlap, bg-slate-50, p-6, gap-5, rounded-t-3xl, shadow-inner
              Positioned(
                top: actualHeaderHeight - overlapHeight,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(24), // p-6
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC), // slate-50
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24), // rounded-t-3xl
                      topRight: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(
                          0.03,
                        ), // subtle shadow-inner
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // ROW 1: YEAR - h-20
                      _buildTile(
                        label: "YEAR",
                        value: year,
                        items: ['2023', '2022', '2021'],
                        onChanged: (v) => setState(() => year = v!),
                        chevronRight: 24,
                      ),
                      const SizedBox(height: 20), // gap-5
                      // ROW 2: MAKE - h-20
                      _buildTile(
                        label: "MAKE",
                        value: make,
                        items: ['Honda', 'Toyota', 'Ford'],
                        onChanged: (v) => setState(() => make = v!),
                        chevronRight: 24,
                      ),
                      const SizedBox(height: 20),

                      // ROW 3: SPLIT TILES - Model & Trim - h-20
                      Row(
                        children: [
                          Expanded(
                            child: _buildTile(
                              label: "MODEL",
                              value: model,
                              items: ['Civic', 'CR-V'],
                              fontSize: 20, // text-xl
                              chevronRight: 16,
                              onChanged: (v) => setState(() => model = v!),
                            ),
                          ),
                          const SizedBox(width: 20), // gap-5
                          Expanded(
                            child: _buildTile(
                              label: "TRIM",
                              value: trim,
                              items: ['EX', 'Touring'],
                              fontSize: 20,
                              chevronRight: 16,
                              onChanged: (v) => setState(() => trim = v!),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20), // pt-2-ish
                      // ACTION BUTTON - h-20 rounded-3xl
                      SizedBox(
                        height: 80, // h-20
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: handleNext,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(
                              0xFF00CA50,
                            ), // Vibrant Green
                            foregroundColor: Colors.white,
                            elevation: 8, // shadow-xl
                            shadowColor: const Color(
                              0xFF00CA50,
                            ).withOpacity(0.3), // Green shadow
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                24,
                              ), // rounded-3xl
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 32,
                            ), // px-8
                          ),
                          child: Stack(
                            children: [
                              // Button content
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Get Estimate",
                                    style: GoogleFonts.outfit(
                                      fontSize: 20, // text-xl
                                      fontWeight: FontWeight.w700, // font-bold
                                    ),
                                  ),
                                  // Circle Icon: w-12 h-12 bg-white/10
                                  Container(
                                    width: 48, // w-12
                                    height: 48, // h-12
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(
                                        0.1,
                                      ), // bg-white/10
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      LucideIcons.chevronRight,
                                      color: Colors.white, // White on green
                                      size: 24,
                                    ),
                                  ),
                                ],
                              ),
                              // Hover gradient overlay effect
                              Positioned.fill(
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: handleNext,
                                    borderRadius: BorderRadius.circular(24),
                                    splashColor: Colors.white.withOpacity(0.05),
                                    highlightColor: Colors.transparent,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // HELPER: Tile Component - EXACT MATCH TO JSX
  Widget _buildTile({
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    double fontSize = 24, // Default text-2xl
    double chevronRight = 24, // Default right-6 (24px)
  }) {
    return SizedBox(
      height: 80, // h-20
      child: Stack(
        children: [
          // Background: bg-white rounded-3xl border border-slate-100 shadow-sm
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24), // rounded-3xl
              border: Border.all(
                color: const Color(0xFFF1F5F9), // border-slate-100
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02), // shadow-sm
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),

          // Label: absolute top-3 left-6 text-[10px] font-black text-slate-400 uppercase tracking-widest z-10
          Positioned(
            top: 12, // top-3
            left: chevronRight == 24
                ? 24
                : 20, // left-6 (24px) or left-5 (20px)
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8), // text-slate-400
                fontSize: 10, // text-[10px]
                fontWeight: FontWeight.w900, // font-black
                letterSpacing: 1.0, // tracking-widest (0.1em)
              ),
            ),
          ),

          // Dropdown: relative w-full h-full bg-transparent px-6/pt-5 text-2xl font-black text-slate-800
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                left: chevronRight == 24
                    ? 24
                    : 20, // px-6 (24px) or px-5 (20px)
                right: chevronRight + 12, // Make space for chevron
                top: 20, // pt-5
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: value,
                  icon: const SizedBox.shrink(), // Hide default icon
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E293B), // text-slate-800
                    fontSize: fontSize, // text-2xl (24px) or text-xl (20px)
                    fontWeight: FontWeight.w900, // font-black
                  ),
                  dropdownColor: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  items: items.map((String item) {
                    return DropdownMenuItem<String>(
                      value: item,
                      child: Text(item),
                    );
                  }).toList(),
                  onChanged: onChanged,
                  isExpanded: true,
                  menuMaxHeight: 300,
                ),
              ),
            ),
          ),

          // Chevron: absolute right-6 top-1/2 -translate-y-1/2 text-slate-300
          // OR right-4 for split tiles
          Positioned(
            right: chevronRight == 24
                ? 24
                : 16, // right-6 (24px) or right-4 (16px)
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: 1.5708, // rotate-90 (90 degrees)
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 22, // size={22}
                  color: const Color(0xFFCBD5E1), // text-slate-300
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Dot Pattern: opacity-[0.05] bg-[radial-gradient(circle_at_center,#fff_1.5px,transparent_1.5px)] [background-size:20px_20px]
class DotPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
          .withOpacity(1.0) // Full opacity, parent handles it
      ..style = PaintingStyle.fill;

    const double gap = 20.0;
    const double radius = 1.2;

    for (double y = 0; y < size.height; y += gap) {
      for (double x = 0; x < size.width; x += gap) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

// Background Ambience: absolute top-[-50%] left-[50%] -translate-x-1/2 w-[400px] h-[400px] bg-white/10 rounded-full blur-[80px] mix-blend-overlay
class OverlayBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
          .withOpacity(0.1) // bg-white/10
      ..blendMode = BlendMode
          .overlay // mix-blend-overlay
      ..maskFilter = const MaskFilter.blur(
        BlurStyle.normal,
        80,
      ); // blur-[80px] approximation

    // Position: top-[-50%] left-[50%] -translate-x-1/2
    final centerX = size.width / 2;
    final centerY = -size.height * 0.25; // -50% of header height
    const radius = 200.0; // w-[400px] h-[400px] -> radius 200

    canvas.drawCircle(Offset(centerX, centerY), radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
