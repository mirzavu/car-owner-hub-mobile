import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';

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
  bool _keepPayment = true;

  // Mock Inventory Data
  final List<Map<String, dynamic>> _inventory = [
    {
      'id': 1,
      'year': 2021,
      'make': 'Honda',
      'model': 'CR-V',
      'trim': 'LX',
      'price': 28900.0,
      'payment': 415.0,
      'image': 'blue',
      'badge': 'Great Value',
    },
    {
      'id': 2,
      'year': 2024,
      'make': 'Honda',
      'model': 'Civic',
      'trim': 'Sport',
      'price': 32500.0,
      'payment': 460.0,
      'image': 'white',
      'badge': 'New Arrival',
    },
    {
      'id': 3,
      'year': 2020,
      'make': 'Toyota',
      'model': 'RAV4',
      'trim': 'LE',
      'price': 29500.0,
      'payment': 418.0,
      'image': 'grey',
      'badge': 'Top Safety',
    },
  ];

  @override
  Widget build(BuildContext context) {
    // Colors
    const colorBg = Color(0xFFE6F0FA); // Ice Blue background
    const colorSlate800 = Color(0xFF1E293B);
    const colorSlate500 = Color(0xFF64748B);
    const colorGreen = Color(0xFF00CA50);
    const colorNavy = Color(0xFF003366);

    // Derived Financials
    final double userPayment = widget.financials['monthlyPayment'] ?? 420.0;
    final double equity = widget.financials['equity'] ?? 0.0;

    // Filter Logic
    final displayInventory = _keepPayment
        ? (_inventory.toList()..sort(
            (a, b) =>
                (a['payment'] as double).compareTo(b['payment'] as double),
          ))
        : _inventory;

    return Scaffold(
      backgroundColor: colorBg,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Sticky Header ---
            Container(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  bottom: BorderSide(color: Colors.blueGrey.shade50),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Upgrade Power",
                        style: GoogleFonts.outfit(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: colorSlate800,
                        ),
                      ),
                      // Temporary Home Button (until BottomNav is added)
                      IconButton(
                        onPressed: () => widget.setActiveTab('home'),
                        icon: const Icon(
                          LucideIcons.home,
                          color: colorSlate500,
                        ),
                        tooltip: "Back to Dashboard",
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  RichText(
                    text: TextSpan(
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: colorSlate500,
                      ),
                      children: [
                        const TextSpan(text: "Using your "),
                        TextSpan(
                          text: _fmt(equity),
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            color: colorGreen,
                          ),
                        ),
                        const TextSpan(text: " equity as down payment."),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter Toggle
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: colorBg,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.blueGrey.shade100),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Keep payment same (${_fmt(userPayment)}/mo)",
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: colorSlate800,
                          ),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _keepPayment = !_keepPayment),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            width: 48,
                            height: 28,
                            decoration: BoxDecoration(
                              color: _keepPayment
                                  ? colorGreen
                                  : Colors.blueGrey.shade300,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Stack(
                              children: [
                                AnimatedPositioned(
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.easeOutBack,
                                  left: _keepPayment ? 22 : 2,
                                  top: 2,
                                  child: Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withOpacity(0.1),
                                          blurRadius: 4,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
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
            ),

            // --- 2. Scrollable Inventory ---
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                physics: const BouncingScrollPhysics(),
                itemCount: displayInventory.length,
                itemBuilder: (context, index) {
                  final car = displayInventory[index];
                  return _buildCarCard(car, userPayment, colorNavy, colorGreen);
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
          const Color(0xFF003366).withOpacity(0.2),
        ],
      );
      iconColor = const Color(0xFF003366).withOpacity(0.5);
    } else if (car['image'] == 'white') {
      bgGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.blueGrey.shade50, Colors.blueGrey.shade200],
      );
      iconColor = Colors.blueGrey.withOpacity(0.5);
    } else {
      bgGradient = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.grey.shade300, Colors.grey.shade400],
      );
      iconColor = Colors.grey.shade700.withOpacity(0.5);
    }

    final bool isGoodDeal = (car['payment'] as double) <= userPayment;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.blueGrey.shade50),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
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
                  child: Icon(LucideIcons.car, size: 80, color: iconColor),
                ),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Text(
                    car['badge'],
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Colors.blueGrey.shade800,
                    ),
                  ),
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
                          "\$${car['payment'].toInt()}/mo",
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: isGoodDeal
                                ? colorGreen
                                : const Color(0xFF1E293B),
                          ),
                        ),
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
                        widget.setOverlayScreen(
                          'success',
                        ); // Placeholder action
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
