import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'screens/splash_screen.dart';
import 'screens/soft_entry_screen.dart';
import 'screens/teaser_screen.dart' as teaser;
import 'screens/login_screen.dart';
import 'screens/phone_capture_screen.dart';
import 'screens/scan_prompt_screen.dart';
import 'screens/scanner_screen.dart';
import 'screens/verify_scan_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/refinance_screen.dart';
import 'screens/cash_unlock_screen.dart';

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
        textTheme: GoogleFonts.outfitTextTheme(ThemeData.light().textTheme),
        // Ice Blue = #E6F0FA
        scaffoldBackgroundColor: const Color(0xFFE6F0FA),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003366), // Midnight Navy
          primary: const Color(0xFF003366),
          // Near Black = #1A1A1B (For text)
          onSurface: const Color(0xFF1A1A1B),
        ),
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
  String step =
      'splash'; // splash, details, teaser, scan-intro, scanner, verify, main-app
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
    'plate': 'BS4 92X',
  };

  Map<String, dynamic> financials = {
    'estimatedValue': 22500.0,
    'userEstimatedLoan': 18000.0,
    'actualRate': 8.99,
    'monthlyPayment': 420.0,
    'lender': 'TD Auto Finance',
    'equity': 0.0,
  };

  @override
  void initState() {
    super.initState();
    _calculateEquity();
  }

  void _calculateEquity() {
    setState(() {
      financials['equity'] =
          financials['estimatedValue'] - financials['userEstimatedLoan'];
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
        return SplashScreen(onNext: () => setStep('details'));
      case 'details':
        return SoftEntryScreen(onNext: (nextStep) => setStep(nextStep));
      case 'teaser':
        return teaser.TeaserScreen(
          carDetails: teaser.CarDetails(
            year: carDetails['year']!,
            make: carDetails['make']!,
            model: carDetails['model']!,
          ),
          financials: teaser.Financials(
            estimatedValue: financials['estimatedValue'],
            userEstimatedLoan: financials['userEstimatedLoan'],
          ),
          onNext: () => setStep('auth-login'),
          onBack: () => setStep('details'),
        );
      case 'auth-login':
        return LoginScreen(setStep: (nextStep) => setStep(nextStep));
      case 'auth-phone':
        return PhoneCaptureScreen(setStep: (nextStep) => setStep(nextStep));
      case 'scan-intro':
        return ScanPromptScreen(
          setStep: (nextStep) => setStep(nextStep),
          onBack: () => setStep('auth-phone'),
        );
      case 'scanner':
        return ScannerScreen(setStep: (nextStep) => setStep(nextStep));
      case 'verify':
        return VerifyScanScreen(setStep: (nextStep) => setStep(nextStep));
      case 'main-app':
        return DashboardScreen(
          carDetails: CarDetails(year: '2022', make: 'Honda', model: 'Civic'),
          setOverlayScreen: (screen) => setOverlay(screen),
          setActiveTab: (tab) => setActiveTab(tab),
        );
      default:
        return Center(child: Text("Unknown Step: $step"));
    }
  }

  Widget _buildOverlay() {
    if (overlayScreen == 'refinance') {
      return RefinanceScreen(
        onClose: () => setOverlay(null),
        onStartRefinance: () {
          // TODO: handle refinance start
          setOverlay(null);
        },
      );
    }
    if (overlayScreen == 'cash-unlock') {
      return CashUnlockScreen(
        financials: financials,
        onClose: () => setOverlay(null),
        onSelectCash: () {
          // TODO: handle cash selection
          setOverlay(null);
        },
      );
    }
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(child: Text("Overlay: $overlayScreen (Not Implemented)")),
      ),
    );
  }
}
