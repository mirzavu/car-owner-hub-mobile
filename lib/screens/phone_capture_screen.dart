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
      body: Column(
        children: [
          // --- 1. Elegant Header ---
          // pt-12 pb-16 px-6 rounded-b-[2.5rem] shadow-2xl shadow-red-900/20
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(
              top: 44, // reduced from 48px
              bottom: 56, // reduced from 64px
              left: 24,
              right: 24,
            ),
            decoration: BoxDecoration(
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(40), // 2.5rem = 40px
                bottomRight: Radius.circular(40),
              ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: gradientColors,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(
                    0xFF002244,
                  ).withOpacity(0.2), // Navy shadow
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              children: [
                // Icon Circle - w-14 h-14 rounded-2xl bg-white/10 border border-white/20 mb-6 mx-auto
                Container(
                  width: 56, // w-14 = 56px
                  height: 56, // h-14 = 56px
                  margin: const EdgeInsets.only(bottom: 24), // mb-6 = 24px
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1), // bg-white/10
                    borderRadius: BorderRadius.circular(
                      16,
                    ), // rounded-2xl = 16px
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2), // border-white/20
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      LucideIcons.smartphone,
                      color: Colors.white,
                      size: 28,
                    ),
                  ),
                ),

                // Heading - text-3xl font-bold text-white mb-2 tracking-tight text-center
                Text(
                  "What is your number?",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 30, // text-3xl = 30px
                    fontWeight: FontWeight.w700, // font-bold
                    letterSpacing: -0.5, // tracking-tight
                  ),
                ),
                const SizedBox(height: 8), // mb-2 = 8px
                // Subtitle - text-red-100/80 text-sm leading-relaxed max-w-[80%] text-center mx-auto
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8, // max-w-[80%]
                  child: Text(
                    "We use this to verify your identity and secure your account.",
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      color: const Color(
                        0xFFE6F0FA,
                      ).withOpacity(0.8), // Ice Blue/80
                      fontSize: 14, // text-sm = 14px
                      height: 1.625, // leading-relaxed
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 2. Input Section ---
          // flex-1 px-6 -mt-8 relative z-10
          Expanded(
            child: SingleChildScrollView(
              child: Transform.translate(
                offset: const Offset(0, -32), // -mt-8 = -32px
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                  ), // px-6 = 24px
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Input Container - bg-white rounded-3xl p-2 shadow-[0_8px_30px_rgb(0,0,0,0.04)] border
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          padding: const EdgeInsets.all(
                            16,
                          ), // Uniform p-4 equivalent
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(
                              16,
                            ), // rounded-2xl = 16px
                            border: Border.all(color: colorSlate100, width: 1),
                            boxShadow: [
                              // shadow-[0_8px_30px_rgb(0,0,0,0.04)]
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 30,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // Country Code Pill - flex flex-col items-center justify-center bg-slate-50 w-16 h-16 rounded-2xl mr-4 border border-slate-100
                              Container(
                                width: 56, // w-14 = 56px (reduced from 64)
                                height: 56, // h-14 = 56px
                                margin: const EdgeInsets.only(
                                  right: 12,
                                ), // mr-3 = 12px
                                decoration: BoxDecoration(
                                  color: colorSlate50,
                                  borderRadius: BorderRadius.circular(
                                    14,
                                  ), // slightly smaller radius
                                  border: Border.all(color: colorSlate100),
                                ),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // text-xl leading-none mb-1
                                    const Text(
                                      "🇨🇦",
                                      style: TextStyle(
                                        fontSize: 20, // text-xl = 20px
                                        height: 1, // leading-none
                                      ),
                                    ),
                                    const SizedBox(height: 4), // mb-1 = 4px
                                    // text-[10px] font-bold text-slate-400 font-mono
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

                              // Input Field - constrained width
                              SizedBox(
                                width: 180, // more constrained width
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    // label - text-[10px] font-bold text-slate-400 uppercase tracking-wider mb-0.5
                                    Text(
                                      "MOBILE NUMBER",
                                      style: GoogleFonts.outfit(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: colorSlate400,
                                        letterSpacing: 0.8, // tracking-wider
                                      ),
                                    ),
                                    const SizedBox(height: 2), // mb-0.5 = 2px
                                    // input - text-2xl font-black text-slate-900 font-outfit placeholder:text-slate-200
                                    TextField(
                                      controller: _controller,
                                      autofocus: true,
                                      keyboardType: TextInputType.phone,
                                      onChanged: _handlePhoneChange,
                                      style: GoogleFonts.outfit(
                                        fontSize: 24, // text-2xl = 24px
                                        fontWeight:
                                            FontWeight.w900, // font-black
                                        color: colorSlate900,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        hintText: "(555) 000-0000",
                                        hintStyle: GoogleFonts.outfit(
                                          fontSize: 24,
                                          fontWeight: FontWeight.w900,
                                          color:
                                              colorSlate200, // placeholder:text-slate-200
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
                      ),

                      // Error Message - mt-4 flex items-center gap-2 text-red-500 text-xs font-medium bg-red-50 px-4 py-3 rounded-xl
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 300),
                        opacity: _error.isNotEmpty ? 1.0 : 0.0,
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          margin: const EdgeInsets.only(top: 16), // mt-4 = 16px
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16, // px-4 = 16px
                            vertical: 12, // py-3 = 12px
                          ),
                          decoration: BoxDecoration(
                            color: colorRed50,
                            borderRadius: BorderRadius.circular(
                              12,
                            ), // rounded-xl = 12px
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
                              const SizedBox(width: 8), // gap-2 = 8px
                              Text(
                                _error,
                                style: GoogleFonts.outfit(
                                  color: colorRed500,
                                  fontSize: 12, // text-xs = 12px
                                  fontWeight: FontWeight.w500, // font-medium
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
            ),
          ),

          // --- 3. Footer Action ---
          // p-6 mt-auto bg-white/50 backdrop-blur-sm
          Container(
            padding: const EdgeInsets.all(24), // p-6 = 24px
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.5), // bg-white/50
            ),
            child: SafeArea(
              top: false,
              child: Column(
                children: [
                  // Button - w-full py-4 rounded-2xl font-bold text-base shadow-xl
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: double.infinity,
                    height: 56, // py-4 = 16px * 2 + ~24px line height
                    decoration: BoxDecoration(
                      color: _isValid ? const Color(0xFF00CA50) : colorSlate100,
                      borderRadius: BorderRadius.circular(
                        16,
                      ), // rounded-2xl = 16px
                      boxShadow: _isValid
                          ? [
                              BoxShadow(
                                color: const Color(0xFF00CA50).withOpacity(0.3),
                                blurRadius: 25,
                                spreadRadius: -5,
                                offset: const Offset(0, 20),
                              ),
                              BoxShadow(
                                color: const Color(0xFF00CA50).withOpacity(0.2),
                                blurRadius: 10,
                                spreadRadius: -6,
                                offset: const Offset(0, 8),
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
                                color: _isValid ? Colors.white : colorSlate300,
                                fontSize: 16, // text-base = 16px
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(width: 8), // gap-2 = 8px
                            Icon(
                              LucideIcons.chevronRight,
                              size: 18,
                              color: _isValid ? Colors.white : colorSlate300,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16), // mt-4 = 16px
                  // Disclaimer - text-center text-[10px] text-slate-400 px-8
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                    ), // px-8 = 32px
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
    );
  }
}
