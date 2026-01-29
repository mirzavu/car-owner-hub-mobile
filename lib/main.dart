import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'screens/splash_screen.dart';
void main() {
  runApp(const FintechApp());
}

class FintechApp extends StatelessWidget {
  const FintechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AutoAssets',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        // Tailwind Slate-50 = #F8FAFC
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFDC2626), // Tailwind Red-600
          primary: const Color(0xFFDC2626),
          // Tailwind Slate-900 = #0F172A (For dark elements)
          onSurface: const Color(0xFF0F172A),
        ),
        textTheme: GoogleFonts.interTextTheme(),
      ),
      home: const FintechAutoFlow(),
    );
  }
}

class FintechAutoFlow extends StatefulWidget {
  const FintechAutoFlow({super.key});

  @override
  State<FintechAutoFlow> createState() => _FintechAutoFlowState();
}

class _FintechAutoFlowState extends State<FintechAutoFlow> {
  // --- STATE MANAGEMENT (Matches React useState) ---

  // Flow State
  String step = 'splash'; // splash, details, teaser, scan-intro, scanner, verify, main-app
  String activeTab = 'home'; // home, shop, garage
  String? overlayScreen; // null, 'cash-unlock', 'refinance'

  // Loading State
  bool loading = false;
  String loadingText = '';

  // User Data State
  Map<String, String> carDetails = {
    'year': '2021',
    'make': 'Honda',
    'model': 'Civic',
    'trim': 'EX',
    'vin': '2HGFC2F60MH59....',
    'plate': 'BS4 92X'
  };

  Map<String, dynamic> financials = {
    'estimatedValue': 22500.0,
    'userEstimatedLoan': 18000.0,
    'actualRate': 8.99,
    'monthlyPayment': 420.0,
    'lender': 'TD Auto Finance',
    'equity': 0.0
  };

  @override
  void initState() {
    super.initState();
    _calculateEquity();
  }

  void _calculateEquity() {
    setState(() {
      financials['equity'] = financials['estimatedValue'] - financials['userEstimatedLoan'];
    });
  }

  // Helper for Currency Formatting
  String fmt(num n) {
    return NumberFormat.currency(
      locale: 'en_CA',
      symbol: '\$',
      decimalDigits: 0,
    ).format(n);
  }

  // --- NAVIGATION HELPERS ---
  void setStep(String newStep) => setState(() => step = newStep);
  void setActiveTab(String tab) => setState(() => activeTab = tab);
  void setOverlay(String? overlay) => setState(() => overlayScreen = overlay);

  @override
  Widget build(BuildContext context) {
    // This MobileContainer mimics the max-w-md and shadow from React
    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480), // max-w-md
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Main Content Switcher
              _buildCurrentStep(),
              
              // Overlays (if any)
              if (overlayScreen != null) _buildOverlay(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (step) {
      case 'splash':
  return SplashScreen(
    onNext: () => setStep('details'),
  );case 'details':
        return const Center(child: Text("Soft Entry Placeholder"));
      case 'teaser':
        return const Center(child: Text("Teaser Placeholder"));
      case 'scan-intro':
        return const Center(child: Text("Scan Intro Placeholder"));
      case 'scanner':
        return const Center(child: Text("Scanner Placeholder"));
      case 'verify':
        return const Center(child: Text("Verify Placeholder"));
      case 'main-app':
        return const Center(child: Text("Main Dashboard Placeholder"));
      default:
        return const Center(child: Text("Unknown Step"));
    }
  }

  Widget _buildOverlay() {
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(child: Text("Overlay: $overlayScreen")),
      ),
    );
  }
}
