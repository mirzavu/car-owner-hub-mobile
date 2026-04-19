import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';

class AuthEmailScreen extends StatefulWidget {
  final Function(String, [Map<String, dynamic>?, String?, String?]) setStep;
  final VoidCallback onBack;

  const AuthEmailScreen({
    super.key,
    required this.setStep,
    required this.onBack,
  });

  @override
  State<AuthEmailScreen> createState() => _AuthEmailScreenState();
}

class _AuthEmailScreenState extends State<AuthEmailScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleContinue() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      setState(() => _errorMessage = "Please enter a valid email address.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().requestCustomOtp(email);
      widget.setStep('auth-otp', {'email': email});
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to send code. Please try again.";
      });
      debugPrint("Email Auth Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

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
    const colorVibrantGreen = Color(0xFF00CA50);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.onBack();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(LucideIcons.arrowLeft, color: colorSlate900),
            onPressed: widget.onBack,
          ),
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Icon
                  Container(
                    width: 60,
                    height: 60,
                    margin: const EdgeInsets.only(bottom: 24),
                    decoration: BoxDecoration(
                      color: colorSlate50,
                      shape: BoxShape.circle,
                      border: Border.all(color: colorSlate100),
                    ),
                    child: const Center(
                      child: Icon(
                        LucideIcons.mail,
                        size: 28,
                        color: colorSlate900,
                      ),
                    ),
                  ),

                  // Headings
                  Text(
                    "What's your email?",
                    style: GoogleFonts.outfit(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: colorSlate900,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    "We'll send you a secure verification code to sign in.",
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      color: colorSlate500,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Email Input
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _errorMessage != null ? Colors.red : colorSlate300,
                      ),
                    ),
                    child: TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        color: colorSlate700,
                      ),
                      decoration: InputDecoration(
                        hintText: "Enter your email address",
                        hintStyle: GoogleFonts.outfit(color: colorSlate400),
                        prefixIcon: const Icon(
                          LucideIcons.atSign,
                          color: colorSlate400,
                        ),
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.all(16),
                      ),
                      onSubmitted: (_) => _handleContinue(),
                    ),
                  ),

                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0, left: 4.0),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.outfit(
                          color: Colors.red,
                          fontSize: 14,
                        ),
                      ),
                    ),

                  const SizedBox(height: 32),

                  // Continue Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleContinue,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colorVibrantGreen,
                        disabledBackgroundColor: colorSlate300,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              "Continue",
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
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
