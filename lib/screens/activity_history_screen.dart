import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class ActivityHistoryScreen extends StatelessWidget {
  const ActivityHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const colorSlate50 = Color(0xFFF8FAFC);
    const colorSlate800 = Color(0xFF1E293B);
    const colorSlate900 = Color(0xFF0F172A);

    final List<Map<String, dynamic>> activities = [
      {
        'icon': LucideIcons.shieldCheck,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFDBEAFE),
        'title': 'Insurance Verified',
        'desc': 'Policy renewed successfully',
        'date': 'Today, 2:45 PM',
      },
      {
        'icon': LucideIcons.trendingUp,
        'color': const Color(0xFF059669),
        'bg': const Color(0xFFD1FAE5),
        'title': 'Equity Updated',
        'desc': 'Market value increased by \$150',
        'date': 'Yesterday, 10:20 AM',
      },
      {
        'icon': LucideIcons.checkCircle2,
        'color': const Color(0xFF475569),
        'bg': const Color(0xFFF1F5F9),
        'title': 'Payment Received',
        'desc': 'Monthly installment of \$420 processed',
        'date': 'July 28, 2025',
      },
      {
        'icon': LucideIcons.fileText,
        'color': const Color(0xFFD97706),
        'bg': const Color(0xFFFEF3C7),
        'title': 'Registration Check',
        'desc': 'Registration valid until Dec 2026',
        'date': 'July 15, 2025',
      },
      {
        'icon': LucideIcons.plusCircle,
        'color': const Color(0xFF7C3AED),
        'bg': const Color(0xFFF5F3FF),
        'title': 'Vehicle Added',
        'desc': '2021 Honda Civic added to garage',
        'date': 'July 10, 2025',
      },
      {
        'icon': LucideIcons.userPlus,
        'color': const Color(0xFFDB2777),
        'bg': const Color(0xFFFDF2F8),
        'title': 'Account Created',
        'desc': 'Welcome to AutoAssets!',
        'date': 'July 10, 2025',
      },
    ];

    return Scaffold(
      backgroundColor: colorSlate50,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
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
                  const SizedBox(width: 16),
                  Text(
                    "Activity History",
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorSlate800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                itemCount: activities.length,
                itemBuilder: (context, index) {
                  final item = activities[index];
                  final bool isLast = index == activities.length - 1;

                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Timeline Line
                        Column(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: item['bg'],
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Icon(
                                  item['icon'],
                                  color: item['color'],
                                  size: 18,
                                ),
                              ),
                            ),
                            if (!isLast)
                              Expanded(
                                child: Container(
                                  width: 2,
                                  color: const Color(0xFFE2E8F0),
                                  margin: const EdgeInsets.symmetric(
                                    vertical: 4,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        // Content
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(bottom: 24.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item['title'],
                                  style: GoogleFonts.outfit(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: colorSlate900,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item['desc'],
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    color: Colors.blueGrey.shade400,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  item['date'],
                                  style: GoogleFonts.outfit(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.blueGrey.shade300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
