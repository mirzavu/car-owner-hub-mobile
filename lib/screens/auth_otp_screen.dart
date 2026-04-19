import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';

class AuthOtpScreen extends StatefulWidget {
  final Function(String, [Map<String, dynamic>?, String?, String?]) setStep;
  final VoidCallback onBack;
  final String email;
  final Future<void> Function()? onAuthSuccess;

  const AuthOtpScreen({
    super.key,
    required this.setStep,
    required this.onBack,
    required this.email,
    this.onAuthSuccess,
  });

  @override
  State<AuthOtpScreen> createState() => _AuthOtpScreenState();
}

class _AuthOtpScreenState extends State<AuthOtpScreen> {
  final TextEditingController _otpController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _handleVerify() async {
    final otp = _otpController.text.trim();
    if (otp.length != 6) {
      setState(() => _errorMessage = "Please enter a 6-digit code.");
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await AuthService().verifyCustomOtp(widget.email, otp);
      if (widget.onAuthSuccess != null) {
        await widget.onAuthSuccess!();
        return;
      }

      // On success, progress through onboarding (similar to Google login flow)
      if (AuthService().userPhone.isNotEmpty) {
        widget.setStep('scan-intro');
      } else {
        widget.setStep('auth-phone');
      }
    } catch (e) {
      setState(() {
        _errorMessage = "Invalid or expired code.";
      });
      debugPrint("OTP Verify Error: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _handleResend() async {
    setState(() {
      _errorMessage = "Requesting new code...";
    });
    try {
      await AuthService().requestCustomOtp(widget.email);
      setState(() {
        _errorMessage = "A new code has been sent.";
      });
    } catch (e) {
      setState(() {
        _errorMessage = "Failed to resend code. Please try again later.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorSlate50 = Color(0xFFF8FAFC);
    const colorSlate100 = Color(0xFFF1F5F9);
    const colorSlate300 = Color(0xFFCBD5E1);
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
          child: Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(32.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
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
                          LucideIcons.key,
                          size: 28,
                          color: colorSlate900,
                        ),
                      ),
                    ),

                    // Headings
                    Text(
                      "Enter code",
                      style: GoogleFonts.outfit(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: colorSlate900,
                      ),
                    ),
                    const SizedBox(height: 12),
                    RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: colorSlate500,
                          height: 1.5,
                        ),
                        children: [
                          const TextSpan(
                            text: "We sent a 6-digit verification code to\n",
                          ),
                          TextSpan(
                            text: widget.email,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: colorSlate700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),

                    // OTP Input
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              _errorMessage != null &&
                                  _errorMessage!.contains("Invalid")
                              ? Colors.red
                              : colorSlate300,
                        ),
                      ),
                      child: TextField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        autofocus: true,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.outfit(
                          fontSize: 32,
                          letterSpacing: 8,
                          fontWeight: FontWeight.bold,
                          color: colorSlate900,
                        ),
                        decoration: const InputDecoration(
                          counterText: "",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 16),
                        ),
                        onChanged: (val) {
                          if (val.length == 6) {
                            _handleVerify();
                          }
                        },
                      ),
                    ),

                    if (_errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Center(
                          child: Text(
                            _errorMessage!,
                            style: GoogleFonts.outfit(
                              color: _errorMessage!.contains("sent")
                                  ? colorVibrantGreen
                                  : Colors.red,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),

                    // Verify Button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleVerify,
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
                                "Verify and Sign In",
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Resend Text Link
                    Center(
                      child: TextButton(
                        onPressed: _isLoading ? null : _handleResend,
                        child: Text(
                          "Didn't receive a code?",
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorSlate500,
                            decoration: TextDecoration.underline,
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
      ),
    );
  }
}
