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
  // Initialize with a default, will update in initState or build if needed
  double _maxPayment = 0.0;
  bool _isInit = true;
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
      final equity = widget.financials['equity']?.toDouble() ?? 0.0;
      final data = await ApiService.getInventory(equity: equity);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      // Set initial max payment to user's current payment
      final double userPayment =
          widget.financials['monthlyPayment']?.toDouble() ?? 420.0;
      _maxPayment = userPayment;
      _isInit = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    const colorBg = Color(0xFFE6F0FA); // Light Blue to match other screens
    const colorSlate800 = Color(0xFF1E293B);
    const colorGreen = Color(0xFF00CA50);
    const colorNavy = Color(0xFF003366);

    // Derived Financials
    final double userPayment =
        widget.financials['monthlyPayment']?.toDouble() ?? 420.0;

    // Sort logic
    List<dynamic> displayInventory = List.from(_inventory);
    if (_keepPaymentSame) {
      displayInventory.sort(
        (a, b) =>
            (a['payment_diff'] as num).compareTo(b['payment_diff'] as num),
      );
    }

    return Scaffold(
      backgroundColor: colorBg, // Match Refinance Light Blue
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Minimal Fixed Header ---
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
                            color: Colors.black.withOpacity(0.05),
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
                      fontSize: 20, // Match Refinance Title Size
                      fontWeight: FontWeight.bold,
                      color: colorSlate800,
                    ),
                  ),
                ],
              ),
            ),

            // --- 2. Scrollable Content (Equity + Filters + List) ---
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                physics: const BouncingScrollPhysics(),
                itemCount: _isLoading ? 2 : displayInventory.length + 1,
                itemBuilder: (context, index) {
                  // Index 0: Header Content (Equity & Filter)
                  if (index == 0) {
                    final double equity =
                        widget.financials['equity']?.toDouble() ?? 0.0;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Equity Badge
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.white),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            children: [
                              Icon(
                                LucideIcons.trendingUp,
                                size: 16,
                                color: colorGreen,
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
                                    const TextSpan(text: "You have "),
                                    TextSpan(
                                      text: _fmt(equity),
                                      style: GoogleFonts.outfit(
                                        fontWeight: FontWeight.bold,
                                        color: colorGreen,
                                      ),
                                    ),
                                    const TextSpan(text: " equity to use."),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Payment Slider Control
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.02),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    "Max Payment",
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: colorSlate800,
                                    ),
                                  ),
                                  Text(
                                    _fmt(_maxPayment),
                                    style: GoogleFonts.outfit(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: colorGreen,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: SliderTheme(
                                      data: SliderTheme.of(context).copyWith(
                                        activeTrackColor: colorGreen,
                                        inactiveTrackColor:
                                            Colors.blueGrey.shade100,
                                        trackHeight: 4.0,
                                        thumbShape: const RoundSliderThumbShape(
                                          enabledThumbRadius: 10,
                                        ),
                                        overlayShape:
                                            const RoundSliderOverlayShape(
                                              overlayRadius: 20,
                                            ),
                                        thumbColor: Colors.white,
                                        overlayColor: colorGreen.withOpacity(
                                          0.1,
                                        ),
                                      ),
                                      child: Slider(
                                        value: _maxPayment,
                                        min: userPayment,
                                        max: userPayment + 500,
                                        divisions: 50,
                                        onChanged: (value) {
                                          setState(() {
                                            _maxPayment = value;
                                          });
                                        },
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    decoration: BoxDecoration(
                                      color: colorNavy,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        LucideIcons.check,
                                        size: 20,
                                        color: Colors.white,
                                      ),
                                      onPressed: () {
                                        // TODO: Implement actual filtering
                                      },
                                      constraints: const BoxConstraints(
                                        minWidth: 44,
                                        minHeight: 44,
                                      ),
                                      padding: EdgeInsets.zero,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }

                  // Loading State
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
              Positioned(
                top: 12,
                right: 12,
                child: Row(
                  children: [
                    ...(car['badges'] as List).map(
                      (badge) => Container(
                        margin: const EdgeInsets.only(left: 4),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          badge['text'].toString(),
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badge['color'] == 'blue'
                                ? colorNavy
                                : colorGreen,
                          ),
                        ),
                      ),
                    ),
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
