import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class GarageScreen extends StatefulWidget {
  final Map<String, String> carDetails;
  final Function(String) setActiveTab;

  const GarageScreen({
    super.key,
    required this.carDetails,
    required this.setActiveTab,
  });

  @override
  State<GarageScreen> createState() => _GarageScreenState();
}

class _GarageScreenState extends State<GarageScreen> {
  // Toggle States
  bool _insuranceExpiry = true;
  bool _equityAlerts = true;

  @override
  Widget build(BuildContext context) {
    const colorBg = Color(0xFFE6F0FA); // Ice Blue
    const colorSlate800 = Color(0xFF1E293B);
    const colorGreen = Color(0xFF00CA50);
    const colorNavy = Color(0xFF003366);

    final car = widget.carDetails;

    return Scaffold(
      backgroundColor: colorBg,
      body: SafeArea(
        child: Column(
          children: [
            // --- 1. Minimal Header (Transparent/Ice Blue) ---
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "My Garage",
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: colorSlate800,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // --- 2. Scrollable Content ---
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  // Vehicle Card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueGrey.shade50),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: colorBg,
                                shape: BoxShape.circle,
                              ),
                              child: const Center(
                                child: Icon(
                                  LucideIcons.car,
                                  size: 24,
                                  color: colorNavy,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "${car['year']} ${car['make']} ${car['model']}",
                                  style: GoogleFonts.outfit(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: colorSlate800,
                                  ),
                                ),
                                Text(
                                  "${car['trim']} • ${car['plate']}",
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.blueGrey.shade400,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: colorBg,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "VIN",
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.blueGrey.shade600,
                                    ),
                                  ),
                                  Text(
                                    car['vin'] ?? 'N/A',
                                    style: GoogleFonts.robotoMono(
                                      fontSize: 12,
                                      color: colorSlate800,
                                    ),
                                  ),
                                ],
                              ),
                              InkWell(
                                onTap: () {}, // Simple copy logic placeholder
                                child: const Padding(
                                  padding: EdgeInsets.all(8.0),
                                  child: Icon(
                                    LucideIcons.copy,
                                    size: 16,
                                    color: Colors.blueGrey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Documents Section
                  _sectionTitle("DOCUMENTS"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueGrey.shade50),
                    ),
                    child: Column(
                      children: [
                        _buildDocItem("Bill of Sale", true),
                        _buildDocItem("Insurance Policy", true),
                        _buildDocItem("Registration", false),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Notifications Section
                  _sectionTitle("NOTIFICATIONS"),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.blueGrey.shade50),
                    ),
                    child: Column(
                      children: [
                        _buildToggleItem(
                          "Insurance Expiry",
                          LucideIcons.bell,
                          _insuranceExpiry,
                          (v) => setState(() => _insuranceExpiry = v),
                          true,
                          colorGreen,
                        ),
                        _buildToggleItem(
                          "Equity Alerts",
                          LucideIcons.trendingUp,
                          _equityAlerts,
                          (v) => setState(() => _equityAlerts = v),
                          false,
                          colorGreen,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Support Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      color: colorNavy,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: colorNavy.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {},
                        borderRadius: BorderRadius.circular(16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              LucideIcons.phone,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              "Call Support Agent",
                              style: GoogleFonts.outfit(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Text(
        title,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: const Color(0xFF1E293B),
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildDocItem(String title, bool showDivider) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F0FA),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(
                  LucideIcons.fileText,
                  size: 18,
                  color: Color(0xFF003366),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B),
                  ),
                ),
              ),
              Icon(
                LucideIcons.chevronRight,
                size: 16,
                color: Colors.blueGrey.shade300,
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: Colors.blueGrey.shade50),
      ],
    );
  }

  Widget _buildToggleItem(
    String title,
    IconData icon,
    bool value,
    Function(bool) onChanged,
    bool showDivider,
    Color activeColor,
  ) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Row(
            children: [
              Icon(icon, size: 18, color: Colors.blueGrey.shade400),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.outfit(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF1E293B), // colorSlate700 equiv
                  ),
                ),
              ),
              Switch.adaptive(
                value: value,
                onChanged: onChanged,
                activeColor: activeColor,
                activeTrackColor: activeColor.withOpacity(0.2),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(height: 1, thickness: 1, color: Colors.blueGrey.shade50),
      ],
    );
  }
}
