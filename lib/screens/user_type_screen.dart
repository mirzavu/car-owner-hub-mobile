import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class UserTypeScreen extends StatelessWidget {
  final Function(String) onSelect;
  final VoidCallback onBack;

  const UserTypeScreen({
    super.key,
    required this.onSelect,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    const colorSlate50 = Color(0xFFF8FAFC);
    const colorSlate500 = Color(0xFF64748B);
    const colorSlate800 = Color(0xFF1E293B);
    const colorNavy = Color(0xFF003366);
    const colorVibrantGreen = Color(0xFF00CA50);

    return Scaffold(
      backgroundColor: colorSlate50,
      body: SafeArea(
        child: Column(
          children: [
            // Header with Back Button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: onBack,
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
                      child: const Icon(LucideIcons.chevronLeft, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 24),
                    Text(
                      "What brings you here today?",
                      style: GoogleFonts.outfit(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: colorSlate800,
                        height: 1.2,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "We'll customize your experience based on your current situation.",
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        color: colorSlate500,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 40),

                    // Option 1: Car Owner
                    _buildOptionCard(
                      icon: LucideIcons.car,
                      iconColor: colorNavy,
                      title: "I own a vehicle",
                      subtitle:
                          "Track my equity, lower my loan payments, or unlock cash back.",
                      onTap: () => onSelect('owner'),
                    ),

                    const SizedBox(height: 16),

                    // Option 2: Buyer / Non-Owner
                    _buildOptionCard(
                      icon: LucideIcons.shoppingBag,
                      iconColor: colorVibrantGreen,
                      title: "I'm looking to buy",
                      subtitle:
                          "Shop vehicles that match my budget and explore financing options.",
                      onTap: () => onSelect('buyer'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.blueGrey.shade50, width: 2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1E293B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    subtitle,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Align(
              alignment: Alignment.center,
              child: Icon(LucideIcons.chevronRight, color: Color(0xFFCBD5E1)),
            ),
          ],
        ),
      ),
    );
  }
}
