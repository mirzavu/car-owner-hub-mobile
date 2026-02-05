import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
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
import 'services/api_service.dart';
import 'screens/refinance_screen.dart';
import 'screens/cash_unlock_screen.dart';
import 'screens/shop_screen.dart';
import 'screens/garage_screen.dart';
import 'screens/success_screen.dart';

import 'package:mobile_app/services/auth_service.dart'; // Import AuthService

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides(); // Bypass SSL errors for dev
  await AuthService().init();
  runApp(const FintechApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
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
  String step = 'loading'; // Default to loading while we check auth
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

  Map<String, dynamic>? lastScanData;

  @override
  void initState() {
    super.initState();
    _calculateEquity();
    _initApp();
  }

  Future<void> _initApp() async {
    final auth = AuthService();

    debugPrint("--- APP INITIALIZATION ---");

    // Give it a tiny delay for splash feel if needed, but let's be fast
    await Future.delayed(const Duration(milliseconds: 500));

    debugPrint("Is Authenticated: ${auth.isAuthenticated}");
    if (!auth.isAuthenticated) {
      debugPrint("Routing to: splash");
      setState(() => step = 'splash');
      return;
    }

    debugPrint("Onboarding Status: ${auth.onboardingStatus}");
    debugPrint("Onboarding Completed: ${auth.isOnboardingCompleted}");
    debugPrint("Has Phone: ${auth.hasPhone} (${auth.userPhone})");

    // Determine where to land based on progress
    if (auth.isOnboardingCompleted) {
      debugPrint("Routing to: main-app");
      setState(() => step = 'main-app');
    } else if (!auth.hasPhone) {
      debugPrint("Routing to: auth-phone");
      setState(() => step = 'auth-phone');
    } else {
      // Land on scan prompt if phone is already provided
      debugPrint("Routing to: scan-intro");
      setState(() => step = 'scan-intro');
    }
    debugPrint("--------------------------");
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
  void setStep(String newStep, [Map<String, dynamic>? data]) {
    setState(() {
      step = newStep;
      if (data != null) {
        lastScanData = data;
        // Optionally update financials directly
        if (data['interest_rate'] != null)
          financials['actualRate'] = data['interest_rate'];
        if (data['lender_name'] != null)
          financials['lender'] = data['lender_name'];
        if (data['monthly_payment'] != null)
          financials['monthlyPayment'] = data['monthly_payment'];
        if (data['current_balance'] != null)
          financials['userEstimatedLoan'] = data['current_balance'];
        _calculateEquity();
      }
    });
  }

  Future<void> _runTimeTravel() async {
    if (lastScanData == null) return;

    final originalBalance = (lastScanData!['current_balance'] ?? 0).toDouble();
    final interestRate = (lastScanData!['interest_rate'] ?? 0).toDouble();
    final termMonths = (lastScanData!['term_months'] ?? 0).toInt();
    final startDate = lastScanData!['contract_date']?.toString();
    final monthlyPayment =
        (lastScanData!['monthly_payment'] ??
                (lastScanData!['bi_weekly_payment'] ?? 0) * 2.16)
            .toDouble();

    if (originalBalance == 0 ||
        interestRate == 0 ||
        termMonths == 0 ||
        startDate == null) {
      return;
    }

    try {
      final result = await ApiService.calculateLoanEquity(
        originalBalance: originalBalance,
        interestRate: interestRate,
        termMonths: termMonths,
        startDate: startDate,
        monthlyPayment: monthlyPayment,
      );

      setState(() {
        if (result['calculated_balance'] != null) {
          financials['userEstimatedLoan'] = result['calculated_balance']
              .toDouble();
          _calculateEquity();
        }
      });
    } catch (e) {
      debugPrint("Time Travel Error: $e");
    }
  }

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
        return SoftEntryScreen(
          onNext: (nextStep) => setStep(nextStep),
          onEstimateComplete: (value, details) {
            setState(() {
              financials['estimatedValue'] = value;
              // Map details to carDetails
              carDetails['year'] = details['year']!;
              carDetails['make'] = details['make']!;
              carDetails['model'] = details['model']!;
              carDetails['trim'] = details['trim']!;
              // Reset VIN/Plate as we don't have them yet from this flow
              carDetails['vin'] = 'Fetching...';
              carDetails['plate'] = 'Pending';
            });
            _calculateEquity();
          },
        );
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
      case 'loading':
        return Scaffold(
          backgroundColor: Colors.white,
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const CircularProgressIndicator(color: Color(0xFF003366)),
                const SizedBox(height: 24),
                Text(
                  "Connecting securely...",
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
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
        return ScannerScreen(
          setStep: (nextStep, data) => setStep(nextStep, data),
        );
      case 'verify':
        return VerifyScanScreen(
          setStep: (nextStep) async {
            if (nextStep == 'main-app') {
              await _runTimeTravel();
            }
            setStep(nextStep);
          },
          scanData: lastScanData ?? {},
          carDetails: carDetails,
          onUpdateCarDetails: (updates) {
            setState(() {
              carDetails.addAll(updates);
            });
          },
          onBack: () => setStep('scanner'),
        );
      case 'main-app':
        return Stack(
          children: [
            // 1. Content
            _buildMainAppContent(),

            // 2. Professional Sleek Bottom Nav
            Positioned(
              left: 48,
              right: 48,
              bottom: 24,
              child: _buildBottomNavBar(),
            ),
          ],
        );
      default:
        return Center(child: Text("Unknown Step: $step"));
    }
  }

  Widget _buildMainAppContent() {
    if (activeTab == 'shop') {
      return ShopScreen(
        financials: financials,
        setOverlayScreen: (screen) => setOverlay(screen),
        setActiveTab: (tab) => setActiveTab(tab),
      );
    }
    if (activeTab == 'garage') {
      return GarageScreen(
        carDetails: carDetails,
        setActiveTab: (tab) => setActiveTab(tab),
      );
    }
    // Default to Dashboard
    return DashboardScreen(
      carDetails: CarDetails(year: '2022', make: 'Honda', model: 'Civic'),
      setOverlayScreen: (screen) => setOverlay(screen),
      setActiveTab: (tab) => setActiveTab(tab),
      onLogout: () => setStep('auth-login'),
      onReverify: () => setStep('scan-intro'),
    );
  }

  Widget _buildBottomNavBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF003366), // Midnight Navy bg
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003366).withOpacity(0.25), // Lighter shadow
            blurRadius: 12, // Reduced blur
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem('home', LucideIcons.home, "Home"),
          _buildNavItem('shop', LucideIcons.car, "Shop"),
          _buildNavItem('garage', LucideIcons.wrench, "Garage"),
        ],
      ),
    );
  }

  Widget _buildNavItem(String tabKey, IconData icon, String label) {
    final bool isActive = activeTab == tabKey;
    const colorActive = Colors.white; // White for active
    final colorInactive = Colors.white.withOpacity(
      0.5,
    ); // Faded white for inactive

    return GestureDetector(
      onTap: () => setActiveTab(tabKey),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withOpacity(0.15)
              : Colors.transparent, // Glassy active pill
          borderRadius: BorderRadius.circular(30),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: isActive ? colorActive : colorInactive),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: colorActive,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOverlay() {
    if (overlayScreen == 'refinance') {
      return RefinanceScreen(
        onClose: () => setOverlay(null),
        onStartRefinance: () {
          setOverlay('success');
        },
      );
    }
    if (overlayScreen == 'cash-unlock') {
      return CashUnlockScreen(
        financials: financials,
        onClose: () => setOverlay(null),
        onSelectCash: () {
          setOverlay('success');
        },
      );
    }
    if (overlayScreen == 'success') {
      return SuccessScreen(onClose: () => setOverlay(null));
    }
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(child: Text("Overlay: $overlayScreen (Not Implemented)")),
      ),
    );
  }
}
