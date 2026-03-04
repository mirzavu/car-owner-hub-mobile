import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:provider/provider.dart';

import 'buyer_dashboard_components/buyer_dashboard_bottom_sheet.dart';
import 'buyer_dashboard_components/buyer_dashboard_constants.dart';
import 'buyer_dashboard_components/buyer_dashboard_inventory_card.dart';
import 'buyer_dashboard_components/buyer_dashboard_view_model.dart';
import 'buyer_dashboard_components/wizard_step_content.dart';

class BuyerDashboardScreen extends StatelessWidget {
  final VoidCallback? onLeadSubmitted;

  const BuyerDashboardScreen({super.key, this.onLeadSubmitted});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => BuyerDashboardViewModel()..loadDraft(),
      child: _BuyerDashboardContent(onLeadSubmitted: onLeadSubmitted),
    );
  }
}

class _BuyerDashboardContent extends StatefulWidget {
  final VoidCallback? onLeadSubmitted;

  const _BuyerDashboardContent({this.onLeadSubmitted});

  @override
  State<_BuyerDashboardContent> createState() => _BuyerDashboardContentState();
}

class _BuyerDashboardContentState extends State<_BuyerDashboardContent>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late final AnimationController _refreshSpinController;
  Timer? _inventoryDebounce;

  @override
  void initState() {
    super.initState();
    _refreshSpinController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    // Load inventory after a frame when the viewModel is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final vm = context.read<BuyerDashboardViewModel>();
        vm.fetchInventory(_refreshSpinController);
      }
    });
  }

  @override
  void dispose() {
    _inventoryDebounce?.cancel();
    _refreshSpinController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onBudgetChange(double value, BuyerDashboardViewModel vm) {
    vm.budget = value;

    _inventoryDebounce?.cancel();
    _inventoryDebounce = Timer(const Duration(milliseconds: 400), () {
      vm.fetchInventory(_refreshSpinController);
    });
  }

  String _formatCurrency(num value) {
    return NumberFormat.currency(
      locale: 'en_CA',
      symbol: '\$',
      decimalDigits: 0,
    ).format(value);
  }

  void _openApprovalSheet(BuyerDashboardViewModel vm) {
    if (!vm.isProfileComplete) return;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return BuyerDashboardBottomSheet(
          viewModel: vm,
          inventoryContextIds: vm.inventoryContextIds,
          onLeadSubmitted: widget.onLeadSubmitted,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<BuyerDashboardViewModel>(
      builder: (context, vm, child) {
        return Scaffold(
          backgroundColor: cLightBg,
          body: Stack(
            children: [
              SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.fromLTRB(
                        24,
                        MediaQuery.of(context).padding.top + 24,
                        24,
                        120,
                      ),
                      decoration: const BoxDecoration(
                        color: cDarkBg,
                        borderRadius: BorderRadius.vertical(
                          bottom: Radius.circular(48),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Dashboard',
                                    style: GoogleFonts.outfit(
                                      fontSize: 32,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white,
                                      letterSpacing: -0.5,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'ROADMAP TO OWNERSHIP',
                                    style: GoogleFonts.outfit(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w800,
                                      color: cNeon,
                                      letterSpacing: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.05),
                                  border: Border.all(
                                    color: Colors.white.withValues(alpha: 0.1),
                                  ),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Icon(
                                  LucideIcons.shieldCheck,
                                  size: 20,
                                  color: cNeon,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),
                          _buildProfileWizard(vm),
                        ],
                      ),
                    ),
                    Transform.translate(
                      offset: const Offset(0, -60),
                      child: Column(
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: _buildBudgetSection(vm),
                          ),
                          const SizedBox(height: 32),
                          _buildStarterMatchesSection(vm),
                          const SizedBox(height: 32),
                          _buildTipsSection(),
                          const SizedBox(height: 120),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                curve: Curves.easeOutCubic,
                bottom: vm.isProfileComplete ? 0 : -100,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        cLightBg.withValues(alpha: 0.0),
                        cLightBg.withValues(alpha: 0.9),
                        cLightBg,
                      ],
                    ),
                  ),
                  child: ElevatedButton(
                    onPressed: () => _openApprovalSheet(vm),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cNeon,
                      foregroundColor: cDarkBg,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      elevation: 12,
                      shadowColor: cNeon.withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(LucideIcons.zap, size: 20, color: cDarkBg),
                        const SizedBox(width: 8),
                        Text(
                          'EXPRESS APPROVAL',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileWizard(BuyerDashboardViewModel vm) {
    if (vm.isProfileComplete) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: cNeon,
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: cNeon.withValues(alpha: 0.2), blurRadius: 30),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: const BoxDecoration(
                color: cDarkBg,
                shape: BoxShape.circle,
              ),
              child: const Icon(LucideIcons.zap, color: cNeon, size: 24),
            ),
            const SizedBox(height: 16),
            Text(
              'Profile Optimized',
              style: GoogleFonts.outfit(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: cDarkBg,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ready for verified matches.',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: cDarkBg.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CircularProgressIndicator(
                    value: 1,
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Colors.white.withValues(alpha: 0.1),
                    ),
                  ),
                  TweenAnimationBuilder<double>(
                    tween: Tween<double>(begin: 0, end: vm.approvalProgress),
                    duration: const Duration(milliseconds: 700),
                    curve: Curves.easeOutCubic,
                    builder: (context, value, _) {
                      return CircularProgressIndicator(
                        value: value,
                        strokeWidth: 3,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(cNeon),
                      );
                    },
                  ),
                  RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: '${(vm.approvalProgress * 100).round()}',
                          style: GoogleFonts.outfit(
                            fontSize: 16,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                          ),
                        ),
                        TextSpan(
                          text: '%',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            color: cNeon,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Row(
              children: List.generate(3, (index) {
                final bool isActive = vm.currentStep == index;
                final bool isPast = index < vm.currentStep;
                return GestureDetector(
                  onTap: () => vm.setManualStep(index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.only(right: 8),
                    height: 6,
                    width: isActive ? 32 : 16,
                    decoration: BoxDecoration(
                      color: isActive
                          ? cNeon
                          : (isPast
                                ? cNeon.withValues(alpha: 0.4)
                                : Colors.white.withValues(alpha: 0.1)),
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                );
              }),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Container(
          width: double.infinity,
          decoration: BoxDecoration(
            color: cCardDark,
            borderRadius: BorderRadius.circular(32),
            border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 40,
              ),
            ],
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            transitionBuilder: (Widget child, Animation<double> animation) {
              return FadeTransition(opacity: animation, child: child);
            },
            child: _buildCurrentWizardStep(vm),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentWizardStep(BuyerDashboardViewModel vm) {
    switch (vm.currentStep) {
      case 0:
        return WizardStepContent(
          key: const ValueKey('step0'),
          title: 'Monthly income?',
          options: incomeRanges,
          selectedValue: vm.income,
          onSelect: (val) {
            vm.income = val;
            vm.saveDraft();
            vm.setManualStep(null);
          },
        );
      case 1:
        return WizardStepContent(
          key: const ValueKey('step1'),
          title: 'Employment status?',
          options: employmentOptions,
          selectedValue: vm.employment,
          onSelect: (val) {
            vm.employment = val;
            vm.saveDraft();
            vm.setManualStep(null);
          },
        );
      case 2:
        return WizardStepContent(
          key: const ValueKey('step2'),
          title: 'Estimated credit score?',
          options: creditBands,
          selectedValue: vm.credit,
          onSelect: (val) {
            vm.credit = val;
            vm.saveDraft();
            vm.setManualStep(null);
          },
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildBudgetSection(BuyerDashboardViewModel vm) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: cDarkBg.withValues(alpha: 0.08),
            blurRadius: 40,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            top: -24,
            left: 8,
            child: Container(
              width: 48,
              height: 6,
              decoration: const BoxDecoration(
                color: cNeon,
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(999),
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        'TARGET BUDGET',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          color: cDarkBg,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerRight,
                    child: RichText(
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: _formatCurrency(vm.budget),
                            style: GoogleFonts.outfit(
                              fontSize: 36,
                              fontWeight: FontWeight.w900,
                              color: cDarkBg,
                              letterSpacing: -1.0,
                              height: 1.0,
                            ),
                          ),
                          TextSpan(
                            text: '/mo',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: Colors.grey[400],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  padding: EdgeInsets.zero,
                  activeTrackColor: cNeon,
                  inactiveTrackColor: Colors.grey[100],
                  trackHeight: 8,
                  thumbColor: cDarkBg,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 16,
                    elevation: 4,
                  ),
                  overlayColor: cNeon.withValues(alpha: 0.2),
                ),
                child: Slider(
                  padding: EdgeInsets.zero,
                  min: 150,
                  max: 900,
                  divisions: 75,
                  value: vm.budget,
                  onChanged: (val) => _onBudgetChange(val, vm),
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cLightBg,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.grey[200]!),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.car, color: cDarkBg),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'VEHICLE VALUE',
                            style: GoogleFonts.outfit(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: Colors.grey[500],
                              letterSpacing: 1.5,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${_formatCurrency(vm.affordability.lowPrice)} – ${_formatCurrency(vm.affordability.highPrice)}',
                            style: GoogleFonts.outfit(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                              color: cDarkBg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStarterMatchesSection(BuyerDashboardViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'Starter Matches',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                  color: cDarkBg,
                  letterSpacing: 0.5,
                ),
              ),
              RotationTransition(
                turns: _refreshSpinController,
                child: InkWell(
                  onTap: vm.inventoryLoading
                      ? null
                      : () => vm.fetchInventory(_refreshSpinController),
                  borderRadius: BorderRadius.circular(999),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey[200]!),
                      boxShadow: const [
                        BoxShadow(color: Colors.black12, blurRadius: 4),
                      ],
                    ),
                    child: Icon(
                      LucideIcons.refreshCw,
                      size: 16,
                      color: vm.inventoryLoading ? cNeon : cDarkBg,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (vm.inventoryLoading && vm.inventory.isEmpty)
          const SizedBox(
            height: 280,
            child: Center(child: CircularProgressIndicator(color: cNeon)),
          )
        else if (vm.inventoryError != null && vm.inventory.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red[50],
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red[200]!),
              ),
              child: Text(
                vm.inventoryError!,
                style: GoogleFonts.outfit(
                  color: Colors.red[800],
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          )
        else
          SizedBox(
            height: 280,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: vm.inventory.length,
              separatorBuilder: (context, index) => const SizedBox(width: 20),
              itemBuilder: (context, index) {
                final car = vm.inventory[index];
                return BuyerDashboardInventoryCard(
                  car: car,
                  budget: vm.budget,
                  affordability: vm.affordability,
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildTipsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Text(
            'Rebuild Tips',
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w900,
              color: cDarkBg,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 160,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: creditTips.length,
            separatorBuilder: (context, index) => const SizedBox(width: 16),
            itemBuilder: (context, index) {
              final tip = creditTips[index];
              return Container(
                width: 280,
                clipBehavior: Clip.antiAlias,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: cCardDark,
                  borderRadius: BorderRadius.circular(32),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: cDarkBg.withValues(alpha: 0.1),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Positioned(
                      top: -40,
                      right: -40,
                      child: Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          color: cNeon.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: cDarkBg,
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(tip.icon, color: cNeon, size: 20),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                tip.title,
                                style: GoogleFonts.outfit(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  height: 1.1,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Spacer(),
                        Text(
                          tip.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.outfit(
                            color: Colors.white70,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
