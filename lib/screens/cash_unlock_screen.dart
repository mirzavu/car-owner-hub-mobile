import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

class CashUnlockScreen extends StatefulWidget {
  final Map<String, dynamic> financials;
  final VoidCallback onClose;
  final VoidCallback onSelectCash;

  const CashUnlockScreen({
    super.key,
    required this.financials,
    required this.onClose,
    required this.onSelectCash,
  });

  @override
  State<CashUnlockScreen> createState() => _CashUnlockScreenState();
}

class _CashUnlockScreenState extends State<CashUnlockScreen> {
  // Config
  final double maxCash = 5000;
  final double minCash = 500;

  // State
  double _cashNeeded = 3000;

  @override
  Widget build(BuildContext context) {
    // Colors
    const colorBg = Color(0xFFF8FAFC); // Slate 50
    const colorTextDark = Color(0xFF1A1A1B);
    const colorSlate500 = Color(0xFF64748B);
    const colorGreen = Color(0xFF00CA50);
    const colorNavy = Color(0xFF003366);

    // Derived Values
    // Logic: adding ~$35 payment per $3k taken (Simplified for demo)
    final double paymentIncrease = ((_cashNeeded / 3000) * 35).roundToDouble();
    final double currentPayment = widget.financials['monthlyPayment'] ?? 0.0;
    final double newPayment = currentPayment + paymentIncrease;

    return Scaffold(
      backgroundColor: colorBg,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Header ---
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 24.0,
                vertical: 16,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        size: 20,
                        color: colorSlate500,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      Text(
                        "EQUITY ACCESS",
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: colorSlate500,
                          letterSpacing: 1.5,
                        ),
                      ),
                      Text(
                        "Unlock Cash",
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: colorTextDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 40), // Spacer
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    const SizedBox(height: 20),

                    // --- 2. Cash Dial / Amount Selector ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
                          Text(
                            "I want to withdraw",
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: colorSlate500,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  "\$",
                                  style: GoogleFonts.outfit(
                                    fontSize: 32,
                                    fontWeight: FontWeight.bold,
                                    color: colorGreen,
                                  ),
                                ),
                              ),
                              Text(
                                _fmtNoSymbol(_cashNeeded),
                                style: GoogleFonts.outfit(
                                  fontSize: 72,
                                  fontWeight: FontWeight.bold,
                                  color: colorTextDark,
                                  height: 1.0,
                                  letterSpacing: -2.0,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colorGreen.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: colorGreen.withOpacity(0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LucideIcons.wallet,
                                  size: 14,
                                  color: colorGreen,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "Max Available: \$${_fmtNoSymbol(maxCash)}",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: colorGreen,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // --- 3. Slider Control ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        children: [
                          SliderTheme(
                            data: SliderTheme.of(context).copyWith(
                              activeTrackColor: colorGreen,
                              inactiveTrackColor: Colors.blueGrey.shade100,
                              trackHeight: 6.0,
                              thumbColor: Colors.white,
                              thumbShape: const RoundSliderThumbShape(
                                enabledThumbRadius: 14,
                                elevation: 4,
                              ),
                              overlayColor: colorGreen.withOpacity(0.1),
                              overlayShape: const RoundSliderOverlayShape(
                                overlayRadius: 24,
                              ),
                            ),
                            child: Slider(
                              value: _cashNeeded,
                              min: minCash,
                              max: maxCash,
                              divisions: ((maxCash - minCash) / 100).round(),
                              onChanged: (value) {
                                setState(() {
                                  _cashNeeded = value;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              _buildStepButton(LucideIcons.minus, () {
                                setState(() {
                                  _cashNeeded = (_cashNeeded - 100).clamp(
                                    minCash,
                                    maxCash,
                                  );
                                });
                              }),
                              _buildStepButton(LucideIcons.plus, () {
                                setState(() {
                                  _cashNeeded = (_cashNeeded + 100).clamp(
                                    minCash,
                                    maxCash,
                                  );
                                });
                              }),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 48),

                    // --- 4. Impact Card ---
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 4, bottom: 12),
                            child: Text(
                              "PAYMENT IMPACT",
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: colorSlate500,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.05),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      // Current
                                      Row(
                                        children: [
                                          Container(
                                            width: 40,
                                            height: 40,
                                            decoration: BoxDecoration(
                                              color: colorBg,
                                              shape: BoxShape.circle,
                                            ),
                                            child: const Icon(
                                              LucideIcons.info,
                                              size: 20,
                                              color: colorSlate500,
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                "Current",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w500,
                                                  color: colorSlate500,
                                                ),
                                              ),
                                              Text(
                                                "\$${currentPayment.toInt()}/mo",
                                                style: GoogleFonts.outfit(
                                                  fontSize: 16,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorTextDark
                                                      .withOpacity(0.5),
                                                  decoration: TextDecoration
                                                      .lineThrough,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),

                                      // Arrow
                                      const Icon(
                                        LucideIcons.arrowRight,
                                        size: 20,
                                        color: Color(0xFFE2E8F0),
                                      ),

                                      // New
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            "+\$${paymentIncrease.toInt()}/mo",
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              fontWeight: FontWeight.bold,
                                              color: Colors.redAccent,
                                            ),
                                          ),
                                          Text(
                                            "\$${newPayment.toInt()}/mo",
                                            style: GoogleFonts.outfit(
                                              fontSize: 24,
                                              fontWeight: FontWeight.bold,
                                              color: colorNavy,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Divider line gradient (subtle red hint)
                                Container(
                                  height: 1,
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.transparent,
                                        Colors.red.withOpacity(0.1),
                                        Colors.transparent,
                                      ],
                                    ),
                                  ),
                                ),
                                Container(
                                  width: double.infinity,
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: colorBg.withOpacity(0.5),
                                    borderRadius: const BorderRadius.vertical(
                                      bottom: Radius.circular(24),
                                    ),
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Icon(
                                          LucideIcons.info,
                                          size: 14,
                                          color: colorSlate500,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: RichText(
                                          text: TextSpan(
                                            style: GoogleFonts.outfit(
                                              fontSize: 12,
                                              color: colorSlate500,
                                              height: 1.4,
                                            ),
                                            children: [
                                              const TextSpan(
                                                text:
                                                    "You are accessing equity. Your rate remains ",
                                              ),
                                              TextSpan(
                                                text: "8.99%",
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorTextDark,
                                                ),
                                              ),
                                              const TextSpan(
                                                text:
                                                    ", but current balance passes to ",
                                              ),
                                              TextSpan(
                                                text:
                                                    "\$${_fmtNoSymbol(_cashNeeded)}",
                                                style: GoogleFonts.outfit(
                                                  fontWeight: FontWeight.bold,
                                                  color: colorTextDark,
                                                ),
                                              ),
                                              const TextSpan(text: "."),
                                            ],
                                          ),
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
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // --- 5. Footer Action ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.blueGrey.shade50)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onSelectCash,
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        colorNavy, // Dark Navy for professional look
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Get \$${_fmtNoSymbol(_cashNeeded)} Cash",
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Icon(
                        LucideIcons.arrowRight,
                        size: 20,
                        color: Colors.white54,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStepButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueGrey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(icon, size: 20, color: Color(0xFF64748B)),
      ),
    );
  }

  String _fmtNoSymbol(num n) {
    return NumberFormat.currency(
      locale: 'en_CA',
      symbol: '',
      decimalDigits: 0,
    ).format(n).trim();
  }
}
