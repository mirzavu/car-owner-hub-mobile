import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class PhoneCaptureScreen extends StatefulWidget {
  final Function(String) setStep;

  const PhoneCaptureScreen({super.key, required this.setStep});

  @override
  State<PhoneCaptureScreen> createState() => _PhoneCaptureScreenState();
}

class _PhoneCaptureScreenState extends State<PhoneCaptureScreen> {
  final TextEditingController _controller = TextEditingController();

  String _error = '';
  bool _isValid = false;

  // Tailwind Color Palette (exact hex values)
  static const colorSlate50 = Color(0xFFF8FAFC);
  static const colorSlate100 = Color(0xFFF1F5F9);
  static const colorSlate200 = Color(0xFFE2E8F0);
  static const colorSlate300 = Color(0xFFCBD5E1);
  static const colorSlate400 = Color(0xFF94A3B8);
  static const colorSlate900 = Color(0xFF0F172A);
  static const colorRed50 = Color(0xFFFEF2F2);
  static const colorRed500 = Color(0xFFEF4444);

  // Gradient colors - Midnight Navy palette
  static const gradientColors = [
    Color(0xFF003366), // Midnight Navy
    Color(0xFF002852), // Intermediate
    Color(0xFF002244), // Navy Dark
  ];

  @override
  void initState() {
    super.initState();
    // Auto focus on start
    WidgetsBinding.instance.addPostFrameCallback((_) {
      FocusScope.of(context).requestFocus(
        FocusNode(),
      ); // Mocking auto-focus behavior if needed, or just removing the old local focus logic
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  // Exact logic from React 'formatPhone' function
  void _handlePhoneChange(String value) {
    String numbers = value.replaceAll(RegExp(r'\D'), '');

    // Prevent typing more than 10 digits
    if (numbers.length > 10) {
      numbers = numbers.substring(0, 10);
    }

    String formatted = numbers;
    if (numbers.isNotEmpty) {
      formatted =
          '(${numbers.substring(0, numbers.length >= 3 ? 3 : numbers.length)}';
    }
    if (numbers.length > 3) {
      formatted +=
          ') ${numbers.substring(3, numbers.length >= 6 ? 6 : numbers.length)}';
    }
    if (numbers.length > 6) {
      formatted += '-${numbers.substring(6, numbers.length)}';
    }

    // Update text and keep cursor at the end
    _controller.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    setState(() {
      _error = '';
      // Check full length: (555) 555-5555 is 14 chars
      _isValid = formatted.length == 14;
    });
  }

  void _handleContinue() {
    if (!_isValid) {
      setState(() {
        _error = 'Please enter a valid 10-digit number.';
      });
      return;
    }
    widget.setStep('scan-intro');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: colorSlate50,
      body: Stack(
        children: [
          // --- 1. Header (Background) ---
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.only(
                top: 44,
                bottom: 48,
                left: 24,
                right: 24,
              ),
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: gradientColors,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF002244).withOpacity(0.2),
                    blurRadius: 25,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Icon Circle
                  Container(
                    width: 52,
                    height: 52,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.smartphone,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    "What is your number?",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Text(
                      "We'll send you a 6-digit code to verify your account.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withOpacity(0.8),
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                  ),
                  // Extra padding at bottom to account for the overlap safe area
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // --- 2. Input & Footer (Foreground) ---
          Positioned.fill(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.zero,
                    children: [
                      // Spacer to push content down - adjusted to overlap header
                      // Header content is approx 44+48+52+20+28+8+14+24 = ~240px
                      const SizedBox(height: 240),

                      // Input Section
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // Input Container
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: colorSlate100,
                                  width: 1,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 30,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  // Country Code Pill
                                  Container(
                                    width: 56,
                                    height: 56,
                                    margin: const EdgeInsets.only(right: 12),
                                    decoration: BoxDecoration(
                                      color: colorSlate50,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: colorSlate100),
                                    ),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Text(
                                          "🇨🇦",
                                          style: TextStyle(
                                            fontSize: 20,
                                            height: 1,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          "+1",
                                          style: GoogleFonts.jetBrainsMono(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: colorSlate400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Input Field
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Text(
                                          "MOBILE NUMBER",
                                          style: GoogleFonts.outfit(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                            color: colorSlate400,
                                            letterSpacing: 0.8,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        TextField(
                                          controller: _controller,
                                          autofocus: true,
                                          keyboardType: TextInputType.phone,
                                          onChanged: _handlePhoneChange,
                                          style: GoogleFonts.outfit(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            color: colorSlate900,
                                          ),
                                          decoration: InputDecoration(
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                            hintText: "(555) 000-0000",
                                            hintStyle: GoogleFonts.outfit(
                                              fontSize: 24,
                                              fontWeight: FontWeight.w900,
                                              color: colorSlate200,
                                            ),
                                            border: InputBorder.none,
                                            focusedBorder: InputBorder.none,
                                            enabledBorder: InputBorder.none,
                                          ),
                                          cursorColor: colorSlate900,
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Error Message
                            AnimatedOpacity(
                              duration: const Duration(milliseconds: 300),
                              opacity: _error.isNotEmpty ? 1.0 : 0.0,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                margin: const EdgeInsets.only(top: 16),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 12,
                                ),
                                decoration: BoxDecoration(
                                  color: colorRed50,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                transform: Matrix4.translationValues(
                                  0,
                                  _error.isNotEmpty ? 0 : -8,
                                  0,
                                ),
                                child: Row(
                                  children: [
                                    const Icon(
                                      LucideIcons.alertCircle,
                                      size: 16,
                                      color: colorRed500,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _error,
                                      style: GoogleFonts.outfit(
                                        color: colorRed500,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Bottom spacing for list view
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Footer Action
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.5),
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          width: double.infinity,
                          height: 56,
                          decoration: BoxDecoration(
                            color: _isValid
                                ? const Color(0xFF00CA50)
                                : colorSlate100,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: _isValid
                                ? [
                                    BoxShadow(
                                      color: const Color(
                                        0xFF00CA50,
                                      ).withOpacity(0.3),
                                      blurRadius: 25,
                                      spreadRadius: -5,
                                      offset: const Offset(0, 20),
                                    ),
                                  ]
                                : [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 25,
                                      spreadRadius: -5,
                                      offset: const Offset(0, 20),
                                    ),
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 10,
                                      spreadRadius: -6,
                                      offset: const Offset(0, 8),
                                    ),
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isValid ? _handleContinue : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    "Continue",
                                    style: GoogleFonts.outfit(
                                      color: _isValid
                                          ? Colors.white
                                          : colorSlate300,
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    LucideIcons.chevronRight,
                                    size: 18,
                                    color: _isValid
                                        ? Colors.white
                                        : colorSlate300,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            "By clicking Continue, you agree to receive SMS notifications. Message rates may apply.",
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(
                              color: colorSlate400,
                              fontSize: 10,
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
        ],
      ),
    );
  }
}
