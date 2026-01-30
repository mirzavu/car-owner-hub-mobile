import 'dart:ui'; // REQUIRED for ImageFilter
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class SplashScreen extends StatelessWidget {
  final VoidCallback onNext;

  const SplashScreen({super.key, required this.onNext});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 1. MIDNIGHT NAVY GRADIENT BACKGROUND (same as dashboard)
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF003366), // Midnight Navy
                  Color(0xFF002852),
                  Color(0xFF002244),
                ],
              ),
            ),
          ),

          // 2. CONTENT
          SafeArea(
            child: Padding(
              // Tailwind p-8 = 32px
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Tailwind mt-12 = 48px
                  const SizedBox(height: 48),

                  // BADGE (With Glass Effect)
                  // Matches: bg-white/20 backdrop-blur-sm rounded-full
                  ClipRRect(
                    borderRadius: BorderRadius.circular(9999), // rounded-full
                    child: BackdropFilter(
                      filter: ImageFilter.blur(
                        sigmaX: 4.0,
                        sigmaY: 4.0,
                      ), // backdrop-blur-sm
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2), // bg-white/20
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text("🇨🇦", style: TextStyle(fontSize: 16)),
                            const SizedBox(width: 8),
                            Text(
                              "Made for Canadian Owners",
                              style: GoogleFonts.outfit(
                                color: Colors.white,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24), // mb-6
                  // HEADLINE
                  Text(
                    "Is Your Car Making You Money?",
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w700,
                      height: 1.25, // leading-tight
                      letterSpacing: -1.2,
                    ),
                  ),

                  const SizedBox(height: 16), // mb-4
                  // SUBTITLE
                  Text(
                    "Track equity, lower payments, and find hidden cash. No credit check required.",
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFE6F0FA), // Ice Blue
                      fontSize: 18,
                      height: 1.625,
                      fontWeight: FontWeight.w400,
                    ),
                  ),

                  const Spacer(),

                  // CTA BUTTON - Vibrant Green
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: onNext,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(
                          0xFF00CA50,
                        ), // Vibrant Green
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        elevation: 4,
                        shadowColor: const Color(0xFF00CA50).withOpacity(0.3),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Get Started",
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(LucideIcons.chevronRight, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
