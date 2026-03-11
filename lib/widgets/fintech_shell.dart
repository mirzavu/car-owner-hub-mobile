import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../screens/cash_unlock_screen.dart';
import '../screens/refinance_screen.dart';
import '../screens/success_screen.dart';
import '../state/app_flow_state.dart';
import '../state/financials_state.dart';

class FintechShell extends ConsumerWidget {
  const FintechShell({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appFlow = ref.watch(appFlowProvider);

    return Scaffold(
      body: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 480),
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
              child,
              if (appFlow.overlayScreen != null) _buildOverlay(ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOverlay(WidgetRef ref) {
    final overlayScreen = ref.read(appFlowProvider).overlayScreen;
    final financials = ref.read(financialsProvider).data;
    final appFlowNotifier = ref.read(appFlowProvider.notifier);

    if (overlayScreen == 'refinance') {
      return RefinanceScreen(
        onClose: () => appFlowNotifier.setOverlay(null),
        onStartRefinance: () {
          appFlowNotifier.setOverlay('success');
        },
        financials: financials,
      );
    }
    if (overlayScreen == 'cash-unlock') {
      return CashUnlockScreen(
        financials: financials,
        onClose: () => appFlowNotifier.setOverlay(null),
        onSelectCash: () {
          appFlowNotifier.setOverlay('success');
        },
      );
    }
    if (overlayScreen == 'success') {
      return SuccessScreen(onClose: () => appFlowNotifier.setOverlay(null));
    }
    return Positioned.fill(
      child: Container(
        color: Colors.black54,
        child: Center(child: Text('Overlay: $overlayScreen (Not Implemented)')),
      ),
    );
  }
}
