import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class RefinanceScreen extends StatefulWidget {
  final VoidCallback onClose;
  final VoidCallback onStartRefinance;

  const RefinanceScreen({
    super.key,
    required this.onClose,
    required this.onStartRefinance,
  });

  @override
  State<RefinanceScreen> createState() => _RefinanceScreenState();
}

class _RefinanceScreenState extends State<RefinanceScreen> {
  String _selectedCreditScore = 'Good';

  @override
  Widget build(BuildContext context) {
    // Colors
    const colorBg = Color(0xFFE6F0FA); // Ice Blue
    const colorTextDark = Color(0xFF1A1A1B);
    const colorGreen = Color(0xFF00CA50);
    const colorNavy = Color(0xFF003366);

    return Scaffold(
      backgroundColor: colorBg,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: widget.onClose,
                    child: Container(
                      padding: const EdgeInsets.all(8),
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
                      child: const Icon(LucideIcons.chevronLeft, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Refinance Estimate",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorTextDark,
                    ),
                  ),
                ],
              ),
            ),

            // --- Scrollable Content ---
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // 1. Comparison Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        // Removed border, relying on shadow and clean bg
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          // Header Row
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: colorBg.withOpacity(0.5),
                              borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24),
                              ),
                              // Removed bottom border
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    "ITEM",
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "CURRENT",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueGrey,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    "NEW",
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: colorGreen,
                                      letterSpacing: 1.0,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Rate Row
                          _buildComparisonRow(
                            label: "Rate",
                            current: "8.99%",
                            currentStyle: GoogleFonts.outfit(
                              color: colorNavy.withOpacity(0.6),
                              decoration: TextDecoration.lineThrough,
                              decorationColor: colorNavy.withOpacity(0.3),
                              fontWeight: FontWeight.w500,
                            ),
                            novel: "6.99%",
                            novelWidget: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: colorGreen.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                "6.99%",
                                style: GoogleFonts.outfit(
                                  color: colorGreen,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                          // Removed Divider

                          // Term Row
                          _buildComparisonRow(
                            label: "Term",
                            current: "48 mo",
                            novel: "48 mo",
                            novelStyle: GoogleFonts.outfit(
                              color: colorTextDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          // Removed Divider

                          // Payment Row
                          _buildComparisonRow(
                            label: "Payment",
                            current: "\$420",
                            currentStyle: GoogleFonts.outfit(
                              color: Colors.blueGrey,
                              decoration: TextDecoration.lineThrough,
                            ),
                            novel: "\$380",
                            novelStyle: GoogleFonts.outfit(
                              color: colorGreen,
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                            bgColor: colorBg.withOpacity(0.4),
                            // Add bottom radius for the last item
                            borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(24),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // 2. Savings Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: colorGreen,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: colorGreen.withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Background Blob
                          Positioned(
                            top: -40,
                            right: -40,
                            child: Container(
                              width: 200,
                              height: 200,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: RadialGradient(
                                  colors: [
                                    Colors.white.withOpacity(0.2),
                                    Colors.white.withOpacity(0.0),
                                  ],
                                ),
                              ),
                            ),
                          ),
                          Column(
                            children: [
                              Text(
                                "Total Savings over loan life",
                                style: GoogleFonts.outfit(
                                  color: Colors.white.withOpacity(0.9),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                "\$1,920",
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -1.0,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // 3. Credit Score Selector
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        "My credit score is roughly...",
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: colorTextDark,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildCreditOption("Fair"),
                        const SizedBox(width: 12),
                        _buildCreditOption("Good"),
                        const SizedBox(width: 12),
                        _buildCreditOption("Excel."),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Center(
                      child: Text(
                        "*Rates depend on approved credit.",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: Colors.blueGrey,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),

            // --- Bottom Action Button ---
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: Colors.blueGrey.shade50)),
              ),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: widget.onStartRefinance,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 5,
                    shadowColor: colorGreen.withOpacity(0.4),
                  ),
                  child: Text(
                    "Start My Refinance",
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonRow({
    required String label,
    required String current,
    TextStyle? currentStyle,
    required String novel,
    TextStyle? novelStyle,
    Widget? novelWidget,
    Color? bgColor,
    BorderRadius? borderRadius, // Added radius parameter
  }) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor ?? Colors.transparent,
        borderRadius: borderRadius,
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontWeight: FontWeight.w500,
                color: Colors.blueGrey.shade700,
              ),
            ),
          ),
          Expanded(
            child: Text(
              current,
              textAlign: TextAlign.center,
              style: currentStyle ?? GoogleFonts.outfit(color: Colors.blueGrey),
            ),
          ),
          Expanded(
            child: Center(
              child:
                  novelWidget ??
                  Text(
                    novel,
                    textAlign: TextAlign.center,
                    style:
                        novelStyle ??
                        GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1A1B),
                        ),
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCreditOption(String label) {
    bool isSelected = _selectedCreditScore == label;
    const colorGreen = Color(0xFF00CA50);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCreditScore = label),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? colorGreen : Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: isSelected
                    ? colorGreen.withOpacity(0.3)
                    : Colors.black.withOpacity(0.02),
                blurRadius: isSelected ? 12 : 5,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.outfit(
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? Colors.white : Colors.blueGrey,
            ),
          ),
        ),
      ),
    );
  }
}
