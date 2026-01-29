import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onNext;

  const SplashScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. EXACT GRADIENT BACKGROUND
          // Matches Tailwind "bg-gradient-to-br from-red-600 to-red-800"
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFDC2626), // Tailwind Red-600 (Start)
                  Color(0xFF991B1B), // Tailwind Red-800 (End)
                ],
              ),
            ),
          ),

          // 2. DECORATIVE BLOB (Matches React "absolute top-0 right-0... blur-3xl")
          // React: w-64 (256px), h-64 (256px), translate-x-1/2 (move right 50%), -translate-y-1/2 (move up 50%)
          Positioned(
            top: -128, // Negative half of height (256/2)
            right: -128, // Negative half of width (256/2)
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1), // bg-white/10
              ),
              child: BackdropFilter(
                filter:
                    MaterialStateProperty.resolveAs(0, {}) == 0
                        ? const ColorFilter.mode(Colors.transparent, BlendMode.dst)
                        : null, // Hack to force redraw if needed, but mainly we rely on the container blur below
              ),
            ),
          ),
          // Applying the Blur separately to ensure it spreads like "blur-3xl"
          Positioned(
            top: -128,
            right: -128,
            child: Container(
              width: 256,
              height: 256,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withOpacity(0.1),
                    blurRadius: 100, // Matches blur-3xl (approx 64px-100px spread)
                    spreadRadius: 20,
                  ),
                ],
              ),
            ),
          ),

          // 3. CONTENT
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 40),

                  // BADGE
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2), // bg-white/20
                      borderRadius: BorderRadius.circular(999), // rounded-full
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text("🇨🇦", style: TextStyle(fontSize: 16)),
                        const SizedBox(width: 8),
                        Text(
                          "Made for Canadian Owners",
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // HEADLINE
                  Text(
                    "Is Your Car Making You Money?",
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 44, // text-5xl
                      fontWeight: FontWeight.bold,
                      height: 1.1, // leading-tight
                      letterSpacing: -1.0,
                    ),
                  ),

                  const SizedBox(height: 16),

                  // SUBTITLE
                  Text(
                    "Track equity, lower payments, and find hidden cash. No credit check required.",
                    style: GoogleFonts.inter(
                      color: const Color(0xFFFECACA), // Tailwind Red-100
                      fontSize: 18, // text-lg
                      height: 1.6, // leading-relaxed
                    ),
                  ),

                  const Spacer(),

                  // BUTTON
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFFB91C1C), // Tailwind Red-700
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        elevation: 10,
                        shadowColor: Colors.black.withOpacity(0.2),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16), // rounded-xl
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Get Started",
                            style: GoogleFonts.inter(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.chevronRight, size: 24),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}