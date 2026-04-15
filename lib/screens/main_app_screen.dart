import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../services/auth_service.dart';
import '../state/app_flow_state.dart';
import '../state/financials_state.dart';
import '../state/user_state.dart';
import '../state/vehicle_state.dart';
import 'buyer_dashboard_screen.dart';
import 'dashboard_screen.dart';
import 'garage_screen.dart';
import 'shop_screen.dart';
import 'teaser_dashboard_screen.dart';

class MainAppScreen extends ConsumerWidget {
  const MainAppScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appFlow = ref.watch(appFlowProvider);
    final user = ref.watch(userProvider);
    final vehicle = ref.watch(vehicleProvider);
    final financialsState = ref.watch(financialsProvider);

    final appFlowNotifier = ref.read(appFlowProvider.notifier);
    final financialsNotifier = ref.read(financialsProvider.notifier);
    final vehicleNotifier = ref.read(vehicleProvider.notifier);

    final userType = user.userType;
    final activeTab = appFlow.activeTab;
    final loanId = financialsState.loanId;
    final isGuest = user.isGuest && !AuthService().isAuthenticated;

    Widget content;

    if (userType == 'buyer') {
      content = BuyerDashboardScreen(
        isGuest: isGuest,
        onRequireLogin: () => appFlowNotifier.setStep('auth-login'),
        onResetData: () => appFlowNotifier.logoutToSplash(),
        onAddCar: () => appFlowNotifier.startOwnerVehicleFlow(),
        onLogout: () => appFlowNotifier.logoutToSplash(),
        onLeadSubmitted: () {
          debugPrint('[BUYER] Preapproval lead submitted.');
        },
      );
    } else if (activeTab == 'shop') {
      content = ShopScreen(
        financials: financialsState.data,
        carDetails: vehicle.carDetails,
        setOverlayScreen: (screen) => appFlowNotifier.setOverlay(screen),
        setActiveTab: (String tab, {int? stepDelta}) =>
            appFlowNotifier.setActiveTab(tab, stepDelta: stepDelta),
        initialStepDelta: appFlow.shopInitialStepDelta,
      );
    } else if (activeTab == 'garage') {
      content = GarageScreen(
        carDetails: vehicle.carDetails,
        loanId: loanId,
        setActiveTab: (String tab, {int? stepDelta}) =>
            appFlowNotifier.setActiveTab(tab, stepDelta: stepDelta),
      );
    } else if (userType == 'owner' && (loanId == null || loanId.isEmpty)) {
      content = TeaserDashboardScreen(
        isGuest: isGuest,
        carDetails: vehicle.carDetails,
        estimatedValue: (financialsState.data['estimatedValue'] as num)
            .toDouble(),
        onScanClick: () => appFlowNotifier.setStep('scan-intro'),
        onLogout: () {
          if (isGuest) {
            appFlowNotifier.setStep('auth-login');
            return;
          }
          appFlowNotifier.logoutToSplash();
        },
      );
    } else {
      content = DashboardScreen(
        isGuest: isGuest,
        profileName: user.profileName,
        profilePhone: user.profilePhone,
        onboardingStatus: user.onboardingStatus,
        carDetails: CarDetails(
          year: vehicle.carDetails['year'] ?? '',
          make: vehicle.carDetails['make'] ?? '',
          model: vehicle.carDetails['model'] ?? '',
        ),
        initialFinancials: financialsState.data,
        setOverlayScreen: (screen) => appFlowNotifier.setOverlay(screen),
        setActiveTab: (String tab, {int? stepDelta}) =>
            appFlowNotifier.setActiveTab(tab, stepDelta: stepDelta),
        onLogout: () => appFlowNotifier.logoutToSplash(),
        onRequireLogin: () => appFlowNotifier.setStep('auth-login'),
        onReverify: () => appFlowNotifier.setStep('scan-intro'),
        onFinancialsUpdate: (data) {
          financialsNotifier.update(data);
          financialsNotifier.calculateEquity();
        },
        onCarDetailsUpdate: (data) {
          vehicleNotifier.updateCarDetails(
            Map<String, String>.from(
              data.map((key, value) => MapEntry(key, value.toString())),
            ),
          );
        },
      );
    }

    return Stack(
      children: [
        content,
        if (userType != 'buyer')
          Positioned(
            left: 48,
            right: 48,
            bottom: 24,
            child: _buildBottomNavBar(
              activeTab: activeTab,
              isBuyer: userType == 'buyer',
              onSelect: (tab) => appFlowNotifier.setActiveTab(tab),
            ),
          ),
      ],
    );
  }

  Widget _buildBottomNavBar({
    required String activeTab,
    required bool isBuyer,
    required void Function(String tabKey) onSelect,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF003366),
        borderRadius: BorderRadius.circular(50),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF003366).withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: isBuyer
            ? MainAxisAlignment.center
            : MainAxisAlignment.spaceBetween,
        children: [
          _buildNavItem('home', LucideIcons.home, 'Home', activeTab, onSelect),
          if (!isBuyer) ...[
            _buildNavItem('shop', LucideIcons.car, 'Shop', activeTab, onSelect),
            _buildNavItem(
              'garage',
              LucideIcons.wrench,
              'Garage',
              activeTab,
              onSelect,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNavItem(
    String tabKey,
    IconData icon,
    String label,
    String activeTab,
    void Function(String tabKey) onSelect,
  ) {
    final bool isActive = activeTab == tabKey;
    const colorActive = Colors.white;
    final colorInactive = Colors.white.withValues(alpha: 0.5);

    return GestureDetector(
      onTap: () => onSelect(tabKey),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(
          horizontal: isActive ? 16 : 10,
          vertical: 6,
        ),
        decoration: BoxDecoration(
          color: isActive
              ? Colors.white.withValues(alpha: 0.15)
              : Colors.transparent,
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
}
