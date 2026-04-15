import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:file_picker/file_picker.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class ScanPromptScreen extends StatefulWidget {
  final void Function(String, [Map<String, dynamic>?]) setStep;
  final VoidCallback? onBack;
  final Future<void> Function()? onSkip;

  const ScanPromptScreen({
    super.key,
    required this.setStep,
    this.onBack,
    this.onSkip,
  });

  @override
  State<ScanPromptScreen> createState() => _ScanPromptScreenState();
}

class _ScanPromptScreenState extends State<ScanPromptScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _offsetAnimation;
  bool _isProcessing = false;

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
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        widget.onBack?.call();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Stack(
            children: [
              CustomScrollView(
                slivers: [
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        children: [
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AnimatedBuilder(
                                  animation: _offsetAnimation,
                                  builder: (context, child) {
                                    return Transform.translate(
                                      offset: Offset(0, _offsetAnimation.value),
                                      child: child,
                                    );
                                  },
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    margin: const EdgeInsets.only(bottom: 24),
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
                                Text(
                                  "Verify your loan to unlock offers",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                    fontSize: 30,
                                    fontWeight: FontWeight.bold,
                                    color: colorSlate900,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Text.rich(
                                  TextSpan(
                                    text:
                                        "Scan your Loan Agreement to verify your interest rate and unlock ",
                                    style: GoogleFonts.outfit(
                                      fontSize: 18,
                                      color: colorSlate600,
                                      height: 1.625,
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
                                const SizedBox(height: 32),
                                Container(
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
                          const SizedBox(height: 24),
                          Column(
                            children: [
                              Container(
                                width: double.infinity,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: colorVibrantGreen,
                                  borderRadius: BorderRadius.circular(12),
                                  boxShadow: [
                                    BoxShadow(
                                      color: colorVibrantGreen.withValues(
                                        alpha: 0.3,
                                      ),
                                      blurRadius: 25,
                                      spreadRadius: -5,
                                      offset: const Offset(0, 20),
                                    ),
                                  ],
                                ),
                                child: Material(
                                  color: Colors.transparent,
                                  child: InkWell(
                                    onTap: _showDocumentOptionsSheet,
                                    borderRadius: BorderRadius.circular(12),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        const Icon(
                                          LucideIcons.filePlus,
                                          size: 22,
                                          color: Colors.white,
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          "Add Document",
                                          style: GoogleFonts.outfit(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              SizedBox(
                                width: double.infinity,
                                height: 60,
                                child: OutlinedButton(
                                  onPressed: () => widget.setStep('verify', {}),
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(
                                      color: colorSlate100,
                                      width: 2,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  child: Text(
                                    "Enter details manually",
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: colorSlate600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                onPressed: widget.onSkip == null
                                    ? () => widget.setStep('main-app')
                                    : () async {
                                        await widget.onSkip!();
                                      },
                                child: Text(
                                  "Skip for now",
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
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
                ],
              ),
              if (_isProcessing)
                Positioned.fill(
                  child: Container(
                    color: Colors.white.withValues(alpha: 0.8),
                    child: Center(
                      child: CircularProgressIndicator(color: colorSlate900),
                    ),
                  ),
                ),
              if (widget.onBack != null)
                Positioned(
                  top: 16,
                  left: 16,
                  child: IconButton(
                    icon: const Icon(LucideIcons.arrowLeft),
                    color: colorSlate900,
                    onPressed: widget.onBack,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _handleFileUpload() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
      );
      if (result == null || result.files.single.path == null) return;
      String filePath = result.files.single.path!;
      if (mounted) Navigator.pop(context);
      setState(() => _isProcessing = true);
      final scanResult = await ApiService.scanDocument(
        filePath,
        userId: AuthService().userId,
      );
      if (!mounted) return;
      setState(() => _isProcessing = false);
      if (scanResult.containsKey('error')) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Scan failed. Please try again or enter manually."),
          ),
        );
      } else {
        widget.setStep('verify', scanResult);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isProcessing = false);
      if (Navigator.canPop(context)) Navigator.pop(context);
    }
  }

  void _showDocumentOptionsSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "Add Document",
                  style: GoogleFonts.outfit(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 24),
                ListTile(
                  leading: const Icon(LucideIcons.camera),
                  title: const Text("Take Photo"),
                  onTap: () {
                    Navigator.pop(context);
                    widget.setStep('scanner');
                  },
                ),
                ListTile(
                  leading: const Icon(LucideIcons.uploadCloud),
                  title: const Text("Upload File"),
                  onTap: _handleFileUpload,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
