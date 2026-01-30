import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class VerifyScanScreen extends StatefulWidget {
  final Function(String) setStep;

  const VerifyScanScreen({super.key, required this.setStep});

  @override
  State<VerifyScanScreen> createState() => _VerifyScanScreenState();
}

class _VerifyScanScreenState extends State<VerifyScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    // Simulate 'animate-in zoom-in-95 duration-300'
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    const colorSlate50 = Color(0xFFF8FAFC);
    const colorSlate100 = Color(0xFFF1F5F9);
    const colorSlate400 = Color(0xFF94A3B8);
    const colorSlate500 = Color(0xFF64748B);
    const colorSlate800 = Color(0xFF1E293B);
    const colorSlate900 = Color(0xFF0F172A);
    const colorGreen100 = Color(0xFFDCFCE7);
    const colorGreen600 = Color(0xFF16A34A);
    const colorRed100 = Color(0xFFFEE2E2);
    const colorRed700 = Color(0xFFB91C1C);

    return Scaffold(
      backgroundColor: colorSlate50,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0), // p-6
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Stack(
                clipBehavior: Clip.none, // Allows the icon to overflow the top
                alignment: Alignment.topCenter,
                children: [
                  // --- The Card ---
                  Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(
                      maxWidth: 420,
                    ), // increased from 384
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16), // rounded-2xl
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ), // shadow-xl
                      ],
                    ),
                    padding: const EdgeInsets.fromLTRB(
                      24,
                      48,
                      24,
                      24,
                    ), // Top padding accounts for icon space
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Title
                        Text(
                          "Confirm Details",
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 24, // increased from 20
                            fontWeight: FontWeight.bold,
                            color: colorSlate900,
                          ),
                        ),
                        const SizedBox(height: 28), // increased from 24
                        // Details List (space-y-4)
                        Column(
                          children: [
                            _DetailRow(
                              label: "Lender",
                              value: "TD Auto Finance",
                              colorSlate100: colorSlate100,
                              colorSlate500: colorSlate500,
                              colorSlate800: colorSlate800,
                            ),
                            _DetailRow(
                              label: "APR Rate",
                              value: "8.99%",
                              isHigh: true, // Special badge case
                              colorSlate100: colorSlate100,
                              colorSlate500: colorSlate500,
                              colorSlate800: colorSlate800,
                              colorRed100: colorRed100,
                              colorRed700: colorRed700,
                            ),
                            _DetailRow(
                              label: "Payment",
                              value: "\$420.00/mo",
                              colorSlate100: colorSlate100,
                              colorSlate500: colorSlate500,
                              colorSlate800: colorSlate800,
                            ),
                            _DetailRow(
                              label: "Est. Balance",
                              value: "\$18,402.00",
                              colorSlate100: colorSlate100,
                              colorSlate500: colorSlate500,
                              colorSlate800: colorSlate800,
                            ),
                          ],
                        ),

                        const SizedBox(height: 32), // mb-8
                        // Buttons
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => widget.setStep('main-app'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorSlate900,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                vertical: 18,
                              ), // increased from 16
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  14,
                                ), // increased from 12
                              ),
                              elevation: 4, // shadow-lg
                              shadowColor: Colors.black.withValues(alpha: 0.3),
                            ),
                            child: Text(
                              "Looks Correct",
                              style: GoogleFonts.outfit(
                                fontSize: 18, // increased from 16
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 12), // mt-3

                        TextButton(
                          onPressed: () {
                            // Edit logic
                          },
                          style: TextButton.styleFrom(
                            foregroundColor: colorSlate400,
                            minimumSize: const Size(double.infinity, 40),
                          ),
                          child: Text(
                            "Edit manually",
                            style: GoogleFonts.outfit(
                              fontSize: 16, // increased from 14
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // --- The Floating Icon (Negative Margin Effect) ---
                  // Positioned at top -32 (half of height 64)
                  Positioned(
                    top: -36, // adjusted for larger icon
                    child: Container(
                      width: 72, // increased from 64
                      height: 72, // increased from 64
                      decoration: BoxDecoration(
                        color: colorGreen100,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white,
                          width: 4,
                        ), // border-4 border-white
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 2,
                            offset: const Offset(0, 1),
                          ), // shadow-sm
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          LucideIcons.checkCircle2,
                          size: 36, // increased from 32
                          color: colorGreen600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// Helper Widget for Rows
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHigh;
  final Color colorSlate100;
  final Color colorSlate500;
  final Color colorSlate800;
  final Color? colorRed100;
  final Color? colorRed700;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isHigh = false,
    required this.colorSlate100,
    required this.colorSlate500,
    required this.colorSlate800,
    this.colorRed100,
    this.colorRed700,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14), // increased from 12
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: colorSlate100), // border-b
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(
              color: colorSlate500,
              fontSize: 16, // increased from 14
            ),
          ),
          Row(
            children: [
              if (isHigh) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  margin: const EdgeInsets.only(right: 8),
                  decoration: BoxDecoration(
                    color: colorRed100,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    "HIGH",
                    style: GoogleFonts.outfit(
                      color: colorRed700,
                      fontSize: 11, // increased from 10
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
              Text(
                value,
                style: GoogleFonts.outfit(
                  color: colorSlate800,
                  fontSize: 16, // added explicit size
                  fontWeight: FontWeight.w600, // font-semibold
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
