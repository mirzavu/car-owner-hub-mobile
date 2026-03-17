import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class LoginScreen extends StatelessWidget {
  final Function(String) setStep;
  final Future<void> Function()? onLoginGoogle;
  final VoidCallback? onBack;

  const LoginScreen({
    super.key,
    required this.setStep,
    this.onLoginGoogle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    // Tailwind Color Palette Mapping
    const colorSlate50 = Color(0xFFF8FAFC);
    const colorSlate100 = Color(0xFFF1F5F9);
    const colorSlate300 = Color(0xFFCBD5E1);
    const colorSlate400 = Color(0xFF94A3B8);
    const colorSlate500 = Color(0xFF64748B);
    const colorSlate700 = Color(0xFF334155);
    const colorSlate900 = Color(0xFF0F172A);
    const colorGreen600 = Color(0xFF16A34A);
    const colorNavy = Color(0xFF003366);
    const colorVibrantGreen = Color(0xFF00CA50);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        onBack?.call();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: CustomScrollView(
                  slivers: [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Padding(
                        padding: const EdgeInsets.all(32.0), // p-8
                        child: Column(
                          children: [
                            // --- Main Content (flex-1) ---
                            Expanded(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  // Icon Circle
                                  Container(
                                    width: 80, // w-20
                                    height: 80, // h-20
                                    margin: const EdgeInsets.only(
                                      bottom: 24,
                                    ), // mb-6
                                    decoration: BoxDecoration(
                                      color: colorSlate50,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: colorSlate100,
                                      ), // ring-1
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          blurRadius: 2,
                                          offset: const Offset(0, 1),
                                        ), // shadow-sm
                                      ],
                                    ),
                                    child: const Center(
                                      child: Icon(
                                        LucideIcons.lock,
                                        size: 32,
                                        color: colorSlate900,
                                      ),
                                    ),
                                  ),

                                  // Headings
                                  Text(
                                    "Save your Garage",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 30, // 3xl approx
                                      fontWeight: FontWeight.bold,
                                      color: colorSlate900,
                                    ),
                                  ),
                                  const SizedBox(height: 12), // mb-3
                                  Text(
                                    "Create a secure account to track your equity and unlock refinance offers.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 18, // text-lg
                                      color: colorSlate500,
                                      height: 1.625, // leading-relaxed
                                    ),
                                  ),
                                  const SizedBox(height: 40), // mb-10
                                  // Buttons Container
                                  SizedBox(
                                    width: double.infinity,
                                    child: Column(
                                      children: [
                                        // Google Button Mock
                                        _LoginButton(
                                          onTap: () async {
                                            if (onLoginGoogle != null) {
                                              try {
                                                await onLoginGoogle!();
                                              } catch (e) {
                                                if (context.mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    SnackBar(
                                                      content:
                                                          Text("Login failed: $e"),
                                                      backgroundColor: Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            }
                                          },
                                          backgroundColor: Colors.white,
                                          borderColor: colorSlate300,
                                          shadowColor: Colors.black.withValues(
                                            alpha: 0.05,
                                          ),
                                          overlayColor:
                                              colorSlate50, // hover effect
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              // Mock Google 'G' Icon
                                              Container(
                                                width: 20,
                                                height: 20,
                                                decoration: const BoxDecoration(
                                                  color: colorNavy,
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Center(
                                                  child: Text(
                                                    "G",
                                                    style: GoogleFonts.notoSerif(
                                                      color: Colors.white,
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.bold,
                                                    ),
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                "Continue with Google",
                                                style: GoogleFonts.outfit(
                                                  color: colorSlate700,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),

                                        const SizedBox(height: 16), // space-y-4
                                        // Email Fallback Button
                                        _LoginButton(
                                          onTap: () => setStep('auth-email'),
                                          backgroundColor: colorVibrantGreen,
                                          shadowColor: colorVibrantGreen
                                              .withValues(alpha: 0.3),
                                          elevation: 8, // shadow-lg approx
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                LucideIcons.mail,
                                                size: 20,
                                                color: Colors.white,
                                              ),
                                              const SizedBox(width: 12),
                                              Text(
                                                "Sign up with Email",
                                                style: GoogleFonts.outfit(
                                                  color: Colors.white,
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // --- Footer ---
                            Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: Text(
                                    "By continuing, you agree to our Terms of Service and Privacy Policy.",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 12, // text-xs
                                      color: colorSlate400,
                                    ),
                                  ),
                                ),

                                // Security Badge
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFDCFCE7),
                                    borderRadius: BorderRadius.circular(50),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        LucideIcons.shield,
                                        size: 12,
                                        color: colorGreen600,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        "Bank-Level Encryption",
                                        style: GoogleFonts.outfit(
                                          fontSize: 12, // text-xs
                                          fontWeight: FontWeight.bold,
                                          color: colorGreen600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Back Button
              if (onBack != null)
                Positioned(
                  top: 0,
                  left: 0,
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft, color: colorSlate900),
                    onPressed: onBack,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

// Helper widget to handle the button styling and touch interactions consistently
class _LoginButton extends StatelessWidget {
  final VoidCallback onTap;
  final Widget child;
  final Color backgroundColor;
  final Color? borderColor;
  final Color? shadowColor;
  final Color? overlayColor;
  final double elevation;

  const _LoginButton({
    required this.onTap,
    required this.child,
    required this.backgroundColor,
    this.borderColor,
    this.shadowColor,
    this.overlayColor,
    this.elevation = 0,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 60, // py-4 approx (16px top + 16px bottom + line height)
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12), // rounded-xl
        border: borderColor != null ? Border.all(color: borderColor!) : null,
        boxShadow: shadowColor != null
            ? [
                BoxShadow(
                  color: shadowColor!,
                  offset: Offset(0, elevation > 0 ? 4 : 1),
                  blurRadius: elevation > 0 ? 10 : 2,
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          overlayColor: overlayColor != null
              ? WidgetStateProperty.all(overlayColor)
              : null,
          child: Center(child: child),
        ),
      ),
    );
  }
}
