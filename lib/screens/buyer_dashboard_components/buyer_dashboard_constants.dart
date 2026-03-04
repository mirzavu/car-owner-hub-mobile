import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

// --- Colors ---
const Color cDarkBg = Color(0xFF0A192F);
const Color cNeon = Color(0xFF00E676);
const Color cCardDark = Color(0xFF112240);
const Color cLightBg = Color(0xFFF4F7F9);

// --- Static Lists ---
const List<String> incomeRanges = [
  '<\$2,500/mo',
  '\$2,500 - \$4,000/mo',
  '\$4,000+/mo',
];

const List<String> employmentOptions = [
  'Full-time',
  'Part-time',
  'Self-employed',
  'Other',
];

const List<String> creditBands = [
  'Rebuilding (300-579)',
  'Fair (580-669)',
  'Good (670-739)',
  'Excellent (740+)',
];

const List<CreditTip> creditTips = [
  CreditTip(
    title: 'Pay Auto On Time',
    body:
        'On-time auto payments stabilize your profile fastest after hardship.',
    icon: LucideIcons.trendingUp,
  ),
  CreditTip(
    title: 'Keep Utilization Low',
    body:
        'Keep credit card balances below 30% of limits while building history.',
    icon: LucideIcons.creditCard,
  ),
  CreditTip(
    title: 'Avoid Hard-Pull Stacking',
    body: 'Submit one strong application rather than many scattered ones.',
    icon: LucideIcons.shieldCheck,
  ),
];

// --- Models ---
class CreditTip {
  final String title;
  final String body;
  final IconData icon;

  const CreditTip({
    required this.title,
    required this.body,
    required this.icon,
  });
}

class AffordabilityEstimate {
  final double lowPrice;
  final double highPrice;

  const AffordabilityEstimate({
    required this.lowPrice,
    required this.highPrice,
  });
}

AffordabilityEstimate estimateAffordability(double payment) {
  // Rough math: payment * 60 months roughly equals finance amount
  // We'll give a range: [payment * 50, payment * 65]
  final low = payment * 50;
  final high = payment * 65;
  return AffordabilityEstimate(lowPrice: low, highPrice: high);
}
