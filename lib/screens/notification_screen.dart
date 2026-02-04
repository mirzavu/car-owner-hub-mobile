import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

class NotificationScreen extends StatelessWidget {
  const NotificationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const colorSlate50 = Color(0xFFF8FAFC);
    const colorSlate800 = Color(0xFF1E293B);
    const colorSlate900 = Color(0xFF0F172A);

    final List<Map<String, dynamic>> notifications = [
      {
        'icon': LucideIcons.trendingDown,
        'color': Colors.red.shade600,
        'bg': Colors.red.shade50,
        'title': 'Rate Drop Alert',
        'desc': 'Market rates dropped to 6.99%. You could save \$52/mo.',
        'time': '2h ago',
        'isNew': true,
      },
      {
        'icon': LucideIcons.fileText,
        'color': const Color(0xFF2563EB),
        'bg': const Color(0xFFDBEAFE),
        'title': 'Document Verified',
        'desc': 'Your insurance document has been successfully verified.',
        'time': '5h ago',
        'isNew': true,
      },
      {
        'icon': LucideIcons.dollarSign,
        'color': Colors.teal.shade600,
        'bg': Colors.teal.shade50,
        'title': 'Cash Unlock Available',
        'desc': 'You have \$3,000 in equity available to unlock.',
        'time': 'Yesterday',
        'isNew': false,
      },
      {
        'icon': LucideIcons.car,
        'color': Colors.blue.shade600,
        'bg': Colors.blue.shade50,
        'title': 'New Inventory Match',
        'desc':
            'A 2026 Honda Civic is available for your current monthly payment.',
        'time': '2 days ago',
        'isNew': false,
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
                  Expanded(
                    child: Text(
                      "Notifications",
                      style: GoogleFonts.outfit(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: colorSlate800,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () {},
                    child: Text(
                      "Mark all read",
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF003366),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                itemCount: notifications.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 16),
                itemBuilder: (context, index) {
                  // ...
                  final item = notifications[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: item['isNew']
                            ? const Color(0xFF003366).withValues(alpha: 0.1)
                            : const Color(0xFFF1F5F9),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: item['bg'],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Icon(
                              item['icon'],
                              color: item['color'],
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['title'],
                                    style: GoogleFonts.outfit(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: colorSlate900,
                                    ),
                                  ),
                                  if (item['isNew'])
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: Color(0xFF003366),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Text(
                                item['desc'],
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.blueGrey.shade400,
                                  height: 1.4,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                item['time'],
                                style: GoogleFonts.outfit(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.blueGrey.shade300,
                                ),
                              ),
                            ],
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
