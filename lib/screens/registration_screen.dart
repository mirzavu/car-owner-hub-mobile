import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';

class RegistrationScreen extends StatefulWidget {
  final Function(String) setStep;
  final String initialValue;
  final Function(String) onChanged;

  const RegistrationScreen({
    super.key,
    required this.setStep,
    this.initialValue = '',
    required this.onChanged,
  });

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  String _error = '';
  bool _isValid = false;
  bool _isUpdating = false;

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

    // Pre-populate name from Google/AuthService
    _nameController.text = AuthService().userName;

    if (widget.initialValue.isNotEmpty) {
      _phoneController.text = widget.initialValue;
    }

    _validate();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _validate() {
    setState(() {
      _isValid =
          _nameController.text.trim().length >= 2 &&
          _phoneController.text.length == 14;
    });
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
    _phoneController.value = TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );

    _validate();
    widget.onChanged(formatted);
  }

  Future<void> _handleContinue() async {
    if (!_isValid) {
      setState(() {
        _error = 'Please enter your name and a valid 10-digit number.';
      });
      return;
    }

    setState(() {
      _isUpdating = true;
      _error = '';
    });

    try {
      debugPrint(
        "[REGISTRATION] Submitting: ${_nameController.text}, ${_phoneController.text}",
      );
      // Save name and phone to PocketBase
      await AuthService().updateProfile(
        _nameController.text.trim(),
        _phoneController.text,
      );

      if (!mounted) return;
      widget.setStep('scan-intro');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isUpdating = false;
        _error = 'Failed to save profile: $e';
      });
    }
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
                    color: const Color(0xFF002244).withValues(alpha: 0.2),
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
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.userPlus,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  Text(
                    "Welcome!",
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
                      "Let's get your profile set up to simplify your car loan journey.",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: Colors.white.withValues(alpha: 0.8),
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
                      const SizedBox(height: 240),

                      // Input Section
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            // 1. Name Input
                            _buildInputContainer(
                              label: "FULL NAME",
                              icon: LucideIcons.user,
                              child: TextField(
                                controller: _nameController,
                                autofocus: true,
                                textCapitalization: TextCapitalization.words,
                                onChanged: (_) => _validate(),
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: colorSlate900,
                                ),
                                decoration: InputDecoration(
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                  hintText: "Enter your name",
                                  hintStyle: GoogleFonts.outfit(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: colorSlate200,
                                  ),
                                  border: InputBorder.none,
                                ),
                                cursorColor: colorSlate900,
                              ),
                            ),

                            const SizedBox(height: 16),

                            // 2. Phone Input
                            _buildInputContainer(
                              label: "MOBILE NUMBER",
                              icon: LucideIcons.smartphone,
                              child: Row(
                                children: [
                                  Text(
                                    "+1 ",
                                    style: GoogleFonts.jetBrainsMono(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                      color: colorSlate400,
                                    ),
                                  ),
                                  Expanded(
                                    child: TextField(
                                      controller: _phoneController,
                                      keyboardType: TextInputType.phone,
                                      onChanged: _handlePhoneChange,
                                      style: GoogleFonts.outfit(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w700,
                                        color: colorSlate900,
                                      ),
                                      decoration: InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        hintText: "(555) 000-0000",
                                        hintStyle: GoogleFonts.outfit(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: colorSlate200,
                                        ),
                                        border: InputBorder.none,
                                      ),
                                      cursorColor: colorSlate900,
                                    ),
                                  ),
                                ],
                              ),
                            ),

                            // Error Message
                            if (_error.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colorRed50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        LucideIcons.alertCircle,
                                        size: 16,
                                        color: colorRed500,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          _error,
                                          style: GoogleFonts.outfit(
                                            color: colorRed500,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w500,
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
                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                // Footer Action
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.5),
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
                                      ).withValues(alpha: 0.3),
                                      blurRadius: 25,
                                      spreadRadius: -5,
                                      offset: const Offset(0, 20),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: (_isValid && !_isUpdating)
                                  ? _handleContinue
                                  : null,
                              borderRadius: BorderRadius.circular(16),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  if (_isUpdating)
                                    const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  else ...[
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

  Widget _buildInputContainer({
    required String label,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorSlate100, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            margin: const EdgeInsets.only(right: 12),
            decoration: BoxDecoration(
              color: colorSlate50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: colorSlate400, size: 20),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: colorSlate400,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
