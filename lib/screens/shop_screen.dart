import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';

class ShopScreen extends StatefulWidget {
  final Map<String, dynamic> financials;
  final Function(String) setOverlayScreen;
  final Function(String) setActiveTab;

  const ShopScreen({
    super.key,
    required this.financials,
    required this.setOverlayScreen,
    required this.setActiveTab,
  });

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  bool _isLoading = true;
  List<dynamic> _inventory = [];
  bool _keepPaymentSame = true;

  @override
  void initState() {
    super.initState();
    _fetchInventory();
  }

  Future<void> _fetchInventory() async {
    setState(() => _isLoading = true);
    try {
      final equity = (widget.financials['equity'] as num?)?.toDouble() ?? 0.0;
      final targetPayment =
          (widget.financials['monthlyPayment'] as num?)?.toDouble() ?? 0.0;

      final data = await ApiService.getInventory(
        equity: equity,
        targetPayment: targetPayment,
      );

      setState(() {
        _inventory = data;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint("Error fetching inventory: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorBg = Color(0xFFE6F0FA);
    const colorSlate800 = Color(0xFF1E293B);
    const colorGreen = Color(0xFF00CA50);
    const colorNavy = Color(0xFF003366);

    final double userPayment =
        (widget.financials['monthlyPayment'] as num?)?.toDouble() ?? 0.0;
    final double equity =
        (widget.financials['equity'] as num?)?.toDouble() ?? 0.0;
    final bool isPaidOff = userPayment <= 0;

    // Sorting Logic
    List<dynamic> displayInventory = List.from(_inventory);
    if (!isPaidOff && _keepPaymentSame) {
      // Sort to show cars closest to current payment first
      displayInventory.sort(
        (a, b) =>
            (a['payment_diff'] as num).compareTo(b['payment_diff'] as num),
      );
    }

    return Scaffold(
      backgroundColor: colorBg,
      body: SafeArea(
        child: Column(
          children: [
            // --- Header ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => widget.setActiveTab('home'),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(
                        LucideIcons.chevronLeft,
                        size: 24,
                        color: Color(0xFF1E293B),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    "Upgrade Power",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorSlate800,
                    ),
                  ),
                ],
              ),
            ),

            // --- Scrollable Content ---
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: _isLoading ? 2 : displayInventory.length + 1,
                itemBuilder: (context, index) {
                  // Index 0: Headers & Filters
                  if (index == 0) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (isPaidOff) ...[
                          // Paid Off Archetype UI
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(20),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF003366), Color(0xFF002244)],
                              ),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "No Monthly Payments 🎉",
                                  style: GoogleFonts.outfit(
                                    color: Colors.greenAccent,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Use your ${_fmt(equity)} equity to upgrade entirely, or keep your next car's payments incredibly low.",
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ] else ...[
                          // Standard & Underwater Archetype UI
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  equity >= 0
                                      ? LucideIcons.trendingUp
                                      : LucideIcons.trendingDown,
                                  size: 16,
                                  color: equity >= 0
                                      ? colorGreen
                                      : Colors.orangeAccent,
                                ),
                                const SizedBox(width: 8),
                                RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      color: colorSlate800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                    children: [
                                      TextSpan(
                                        text: equity >= 0
                                            ? "You have "
                                            : "Rolling in ",
                                      ),
                                      TextSpan(
                                        text: _fmt(equity.abs()),
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.bold,
                                          color: equity >= 0
                                              ? colorGreen
                                              : Colors.orangeAccent,
                                        ),
                                      ),
                                      TextSpan(
                                        text: equity >= 0
                                            ? " equity to use."
                                            : " from current loan.",
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Keep Payment Same Toggle
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "Keep my payment same",
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: colorSlate800,
                                      ),
                                    ),
                                    Text(
                                      "Around ${_fmt(userPayment)}/mo",
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: Colors.blueGrey,
                                      ),
                                    ),
                                  ],
                                ),
                                Switch(
                                  value: _keepPaymentSame,
                                  activeColor: colorGreen,
                                  onChanged: (val) {
                                    setState(() => _keepPaymentSame = val);
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ],
                    );
                  }

                  // Loading Indicator
                  if (_isLoading && index == 1) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 40),
                        child: CircularProgressIndicator(
                          color: Color(0xFF003366),
                        ),
                      ),
                    );
                  }

                  // Inventory Items
                  if (index - 1 < displayInventory.length) {
                    final car = displayInventory[index - 1];
                    return _buildCarCard(
                      car,
                      userPayment,
                      colorNavy,
                      colorGreen,
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCarCard(
    Map<String, dynamic> car,
    double userPayment,
    Color colorNavy,
    Color colorGreen,
  ) {
    // Determine Gradient based on 'image' key
    LinearGradient bgGradient;
    Color iconColor;

    if (car['image'] == 'blue') {
      bgGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          const Color(0xFFE6F0FA),
          const Color(0xFF003366).withValues(alpha: 0.2),
        ],
      );
      iconColor = const Color(0xFF003366).withValues(alpha: 0.5);
    } else if (car['image'] == 'white') {
      bgGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blueGrey.shade50, Colors.blueGrey.shade200],
      );
      iconColor = Colors.blueGrey.withValues(alpha: 0.5);
    } else {
      bgGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey.shade300, Colors.grey.shade400],
      );
      iconColor = Colors.grey.shade700.withValues(alpha: 0.5);
    }

    final double projectedPayment = (car['payment'] as num).toDouble();
    final bool isPaidOff = projectedPayment <= 0;

    // Quick fallback check to highlight card text if it's equal to or under target
    final bool isGoodDeal =
        !isPaidOff && userPayment > 0 && projectedPayment <= userPayment;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Image Area
          Stack(
            children: [
              Container(
                height: 160,
                decoration: BoxDecoration(
                  gradient: bgGradient,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Center(
                  child:
                      car['image'] != null &&
                          car['image'].toString().startsWith('http')
                      ? ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(24),
                          ),
                          child: Image.network(
                            car['image'],
                            width: double.infinity,
                            height: 160,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => Icon(
                              LucideIcons.car,
                              size: 80,
                              color: iconColor,
                            ),
                          ),
                        )
                      : Icon(LucideIcons.car, size: 80, color: iconColor),
                ),
              ),

              // Dynamic Badges Rendered from API
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    ...(car['badges'] as List).map((badge) {
                      Color textColor;
                      switch (badge['color']) {
                        case 'green':
                        case 'emerald':
                          textColor = colorGreen;
                          break;
                        case 'blue':
                          textColor = colorNavy;
                          break;
                        default:
                          textColor = Colors.blueGrey;
                      }

                      return Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge['text'].toString(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),

          // Content Area
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "${car['year']} ${car['make']} ${car['model']}",
                          style: GoogleFonts.outfit(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1E293B),
                          ),
                        ),
                        Text(
                          car['trim'],
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.blueGrey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          isPaidOff
                              ? "Paid in Full"
                              : "\$${projectedPayment.toInt()}/mo",
                          style: GoogleFonts.outfit(
                            fontSize: isPaidOff ? 16 : 20,
                            fontWeight: FontWeight.bold,
                            color: isPaidOff || isGoodDeal
                                ? colorGreen
                                : const Color(0xFF1E293B),
                          ),
                        ),
                        if (!isPaidOff)
                          Text(
                            "with trade-in",
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              color: Colors.blueGrey.shade400,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),
                Container(height: 1, color: Colors.blueGrey.shade50),
                const SizedBox(height: 12),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Price: ${_fmt(car['price'])}",
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade500,
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        widget.setOverlayScreen('success');
                      },
                      child: Row(
                        children: [
                          Text(
                            "See Deal",
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: colorGreen,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            LucideIcons.arrowRight,
                            size: 16,
                            color: colorGreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(num n) {
    return NumberFormat.currency(
      locale: 'en_CA',
      symbol: '\$',
      decimalDigits: 0,
    ).format(n);
  }
}
