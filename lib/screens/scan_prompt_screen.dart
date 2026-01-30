import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ScanPromptScreen extends StatefulWidget {
  final Function(String) setStep;

  const ScanPromptScreen({super.key, required this.setStep});

  @override
  State<ScanPromptScreen> createState() => _ScanPromptScreenState();
}

class _ScanPromptScreenState extends State<ScanPromptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;

  // Tailwind Color Palette
  static const colorSlate50 = Color(0xFFF8FAFC);
  static const colorSlate100 = Color(0xFFF1F5F9);
  static const colorSlate400 = Color(0xFF94A3B8);
  static const colorSlate600 = Color(0xFF475569);
  static const colorSlate900 = Color(0xFF0F172A);
  static const colorGreen100 = Color(0xFFDCFCE7);
  static const colorGreen600 = Color(0xFF16A34A);
  static const colorVibrantGreen = Color(0xFF00CA50);

  @override
  void initState() {
    super.initState();
    // Replicating Tailwind 'animate-bounce':
    // 1s duration, moving up and down infinitely
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _offsetAnimation = Tween<double>(
      begin: 0,
      end: -15,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32.0), // p-8
          child: Column(
            children: [
              // --- 1. Centered Content (flex-1) ---
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Bouncing Icon
                    AnimatedBuilder(
                      animation: _offsetAnimation,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _offsetAnimation.value),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 80, // w-20
                        height: 80, // h-20
                        margin: const EdgeInsets.only(bottom: 24), // mb-6
                        decoration: const BoxDecoration(
                          color: colorGreen100,
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Icon(
                            LucideIcons.trendingUp,
                            size: 40,
                            color: colorGreen600,
                          ),
                        ),
                      ),
                    ),

                    // Heading
                    Text(
                      "Let's make this official.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 30, // text-3xl
                        fontWeight: FontWeight.bold,
                        color: colorSlate900,
                      ),
                    ),
                    const SizedBox(height: 16), // mb-4
                    // Rich Text Paragraph
                    Text.rich(
                      TextSpan(
                        text:
                            "Scan your Bill of Sale or Loan Agreement to verify your interest rate and unlock ",
                        style: GoogleFonts.outfit(
                          fontSize: 18, // text-lg
                          color: colorSlate600,
                          height: 1.625, // leading-relaxed
                        ),
                        children: [
                          TextSpan(
                            text: "Refinance",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: colorSlate900,
                            ),
                          ),
                          const TextSpan(text: " or "),
                          TextSpan(
                            text: "Cash Back",
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              color: colorSlate900,
                            ),
                          ),
                          const TextSpan(text: " offers."),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),

                    const SizedBox(height: 32), // mb-8
                    // Security Badge
                    Container(
                      constraints: BoxConstraints(
                        maxWidth: MediaQuery.of(context).size.width - 64,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: colorSlate50,
                        borderRadius: BorderRadius.circular(50),
                        border: Border.all(color: colorSlate100),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            LucideIcons.shieldCheck,
                            size: 14,
                            color: colorSlate400,
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              "Bank-level security. Data stays in Canada 🇨🇦",
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: colorSlate400,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // --- 2. Action Buttons ---
              Column(
                children: [
                  // Primary Button
                  Container(
                    width: double.infinity,
                    height: 60, // py-4 approx
                    decoration: BoxDecoration(
                      color: colorVibrantGreen,
                      borderRadius: BorderRadius.circular(12), // rounded-xl
                      boxShadow: [
                        // shadow-xl with green glow
                        BoxShadow(
                          color: colorVibrantGreen.withOpacity(0.3),
                          blurRadius: 25,
                          spreadRadius: -5,
                          offset: const Offset(0, 20),
                        ),
                        BoxShadow(
                          color: colorVibrantGreen.withOpacity(0.2),
                          blurRadius: 10,
                          spreadRadius: -6,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => widget.setStep('scanner'),
                        borderRadius: BorderRadius.circular(12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.camera,
                              size: 22,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 12), // gap-3
                            Text(
                              "Scan Document",
                              style: GoogleFonts.outfit(
                                fontSize: 18, // text-lg
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 16), // space-y-4
                  // Secondary Button
                  TextButton(
                    onPressed: () => widget.setStep('main-app'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorSlate600, // hover text color
                      padding: const EdgeInsets.symmetric(vertical: 8),
                    ),
                    child: Text(
                      "Skip for now",
                      style: GoogleFonts.outfit(
                        fontSize: 14, // text-sm
                        fontWeight: FontWeight.w500,
                        color: colorSlate400,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
