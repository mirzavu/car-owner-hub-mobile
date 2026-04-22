import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import '../../services/data_service.dart';
import '../../widgets/login_prompt_dialog.dart';
import '../../components/custom_slider_components.dart';
import 'buyer_dashboard_constants.dart';
import 'buyer_dashboard_view_model.dart';

class BuyerDashboardBottomSheet extends StatefulWidget {
  final BuyerDashboardViewModel viewModel;
  final VoidCallback? onLeadSubmitted;
  final VoidCallback? onRequireLogin;
  final Set<String> inventoryContextIds;

  const BuyerDashboardBottomSheet({
    super.key,
    required this.viewModel,
    required this.inventoryContextIds,
    this.onLeadSubmitted,
    this.onRequireLogin,
  });

  @override
  State<BuyerDashboardBottomSheet> createState() =>
      _BuyerDashboardBottomSheetState();
}

class _BuyerDashboardBottomSheetState extends State<BuyerDashboardBottomSheet>
    with SingleTickerProviderStateMixin {
  late final TextEditingController _homeAddressController;
  TextEditingController? _guestEmailController;
  TextEditingController? _guestPhoneController;
  late final TextEditingController _empCompanyController;
  late final TextEditingController _empTitleController;
  late final TextEditingController _notesController;

  late final AnimationController _entryController;

  bool _isSubmittingLead = false;

  @override
  void initState() {
    super.initState();

    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    )..forward();

    _homeAddressController = TextEditingController(
      text: widget.viewModel.homeAddress,
    );
    _guestEmailController = TextEditingController(
      text: widget.viewModel.guestEmail,
    );
    _guestPhoneController = TextEditingController(
      text: widget.viewModel.guestPhone,
    );
    _empCompanyController = TextEditingController(
      text: widget.viewModel.empCompany,
    );
    _empTitleController = TextEditingController(
      text: widget.viewModel.empTitle,
    );
    _notesController = TextEditingController(text: widget.viewModel.notes);

    _homeAddressController.addListener(() {
      widget.viewModel.homeAddress = _homeAddressController.text;
      widget.viewModel.saveDraft();
    });
    _guestEmailController?.addListener(() {
      widget.viewModel.guestEmail = _guestEmailController?.text;
      widget.viewModel.saveDraft();
    });
    _guestPhoneController?.addListener(() {
      widget.viewModel.guestPhone = _guestPhoneController?.text;
      widget.viewModel.saveDraft();
    });
    _empCompanyController.addListener(() {
      widget.viewModel.empCompany = _empCompanyController.text;
      widget.viewModel.saveDraft();
    });
    _empTitleController.addListener(() {
      widget.viewModel.empTitle = _empTitleController.text;
      widget.viewModel.saveDraft();
    });
    _notesController.addListener(() {
      widget.viewModel.notes = _notesController.text;
      widget.viewModel.saveDraft();
    });
  }

  @override
  void dispose() {
    _entryController.dispose();
    _homeAddressController.dispose();
    _guestEmailController?.dispose();
    _guestPhoneController?.dispose();
    _empCompanyController.dispose();
    _empTitleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _formatCurrency(num value) {
    if (value >= 1000) {
      return '\$${(value / 1000).toStringAsFixed(1).replaceAll('.0', '')}k';
    }
    return '\$${value.toInt()}';
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r"^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$",
    ).hasMatch(email);
  }

  bool _isValidPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return digits.length == 10;
  }

  String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    return '+1$digits';
  }

  Future<void> _submitLead() async {
    if (_isSubmittingLead || !widget.viewModel.acceptedTerms) return;

    setState(() => _isSubmittingLead = true);

    final auth = AuthService();
    final isGuest = !auth.isAuthenticated;
    final guestEmail = _guestEmailController?.text.trim() ?? '';
    final guestPhone = _guestPhoneController?.text.trim() ?? '';

    final extraDetails =
        '''
DOB: ${widget.viewModel.dobMonth ?? ''}/${widget.viewModel.dobDay ?? ''}/${widget.viewModel.dobYear ?? ''}
Address: ${_homeAddressController.text}
${isGuest ? 'Guest Email: $guestEmail\nGuest Phone: $guestPhone' : ''}
Employment: ${_empCompanyController.text}, ${_empTitleController.text} (${widget.viewModel.incomeYears ?? '0'}y ${widget.viewModel.incomeMonths ?? '0'}m)
Housing: ${_formatCurrency(widget.viewModel.housingCost)}/mo
Downpayment: ${_formatCurrency(widget.viewModel.downpayment)}
Co-signer: ${widget.viewModel.hasCosigner ?? 'unspecified'}
Notes: ${_notesController.text}
        '''
            .trim();

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      if (isGuest) {
        if (guestEmail.isEmpty || !_isValidEmail(guestEmail)) {
          setState(() => _isSubmittingLead = false);
          messenger.showSnackBar(
            const SnackBar(content: Text('Enter a valid email address.')),
          );
          return;
        }
        if (guestPhone.isEmpty || !_isValidPhone(guestPhone)) {
          setState(() => _isSubmittingLead = false);
          messenger.showSnackBar(
            const SnackBar(content: Text('Enter a valid phone number.')),
          );
          return;
        }
      }

      final appData = await DataService().loadAppData(
        fallbackUserType: 'buyer',
      );
      final fallbackPhone = appData.profilePhone.trim();
      final resolvedName = auth.userName.isNotEmpty
          ? auth.userName
          : (appData.profileName.isEmpty ? 'Guest Lead' : appData.profileName);
      final resolvedPhone = isGuest
          ? _normalizePhone(guestPhone)
          : (auth.userPhone.isNotEmpty
                ? auth.userPhone
                : (fallbackPhone.isEmpty ? '0000000000' : fallbackPhone));
      final resolvedEmail = isGuest
          ? guestEmail
          : (auth.userEmail.isNotEmpty ? auth.userEmail : null);

      await ApiService.submitBuyerPreapprovalLead(
        name: resolvedName,
        phone: resolvedPhone,
        email: resolvedEmail,
        monthlyBudgetTarget: widget.viewModel.budget,
        incomeRange: widget.viewModel.income!,
        employmentStatus: widget.viewModel.employment!,
        creditBand: widget.viewModel.credit!,
        notes: extraDetails,
        inventoryContext: widget.inventoryContextIds.take(8).toList(),
      );

      if (!mounted) return;
      navigator.pop();
      widget.onLeadSubmitted?.call();
      messenger.showSnackBar(
        const SnackBar(content: Text('Request sent successfully.')),
      );

      if (!isGuest) return;
      final wantsToSignUp = await showLoginPromptDialog(navigator.context);
      if (wantsToSignUp) {
        widget.onRequireLogin?.call();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmittingLead = false);
      messenger.showSnackBar(
        const SnackBar(content: Text('Could not submit request right now.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.viewModel;
    final isGuest = !AuthService().isAuthenticated;
    _guestEmailController ??= TextEditingController(text: vm.guestEmail);
    _guestPhoneController ??= TextEditingController(text: vm.guestPhone);
    final showEmploymentDetails =
        vm.employment == 'Full-time' ||
        vm.employment == 'Part-time' ||
        vm.employment == 'Self-employed';

    final media = MediaQuery.of(context);

    return AnimatedBuilder(
      animation: _entryController,
      builder: (context, child) {
        final eased = Curves.easeOutCubic.transform(_entryController.value);
        final dy = (1 - eased) * 56;

        return Transform.translate(
          offset: Offset(0, dy),
          child: Opacity(opacity: eased, child: child),
        );
      },
      child: Padding(
        padding: EdgeInsets.only(bottom: media.viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: media.size.height * 0.90),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
            boxShadow: [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 30,
                offset: Offset(0, -8),
              ),
            ],
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
                child: Column(
                  children: [
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Complete Application',
                            style: GoogleFonts.outfit(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: cDarkBg,
                              letterSpacing: -0.3,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () => Navigator.of(context).pop(),
                          borderRadius: BorderRadius.circular(999),
                          child: Container(
                            width: 34,
                            height: 34,
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: const Icon(
                              LucideIcons.x,
                              size: 16,
                              color: cDarkBg,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        _infoPill(
                          icon: LucideIcons.wallet,
                          label: 'Budget',
                          value: '${_formatCurrency(vm.budget)}/mo',
                        ),
                        const SizedBox(width: 8),
                        _infoPill(
                          icon: LucideIcons.badgeCheck,
                          label: 'Profile',
                          value: '${(vm.approvalProgress * 100).round()}%',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Divider(color: Colors.grey[200], height: 1),
              Expanded(
                child: ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                  children: [
                    _sectionCard(
                      icon: LucideIcons.user,
                      title: 'Personal Details',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSheetLabel('Date of Birth'),
                          Row(
                            children: [
                              Expanded(
                                child: _buildDropdown(
                                  hint: 'Month',
                                  value: vm.dobMonth,
                                  items: List.generate(
                                    12,
                                    (i) => (i + 1).toString().padLeft(2, '0'),
                                  ),
                                  onChanged: (v) {
                                    setState(() => vm.dobMonth = v);
                                    vm.saveDraft();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDropdown(
                                  hint: 'Day',
                                  value: vm.dobDay,
                                  items: List.generate(
                                    31,
                                    (i) => (i + 1).toString().padLeft(2, '0'),
                                  ),
                                  onChanged: (v) {
                                    setState(() => vm.dobDay = v);
                                    vm.saveDraft();
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: _buildDropdown(
                                  hint: 'Year',
                                  value: vm.dobYear,
                                  items: List.generate(
                                    80,
                                    (i) => (DateTime.now().year - 18 - i)
                                        .toString(),
                                  ),
                                  onChanged: (v) {
                                    setState(() => vm.dobYear = v);
                                    vm.saveDraft();
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 14),
                          _buildSheetLabel('Home Address'),
                          TextField(
                            controller: _homeAddressController,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: cDarkBg,
                            ),
                            decoration: _buildInputDecoration(
                              '123 Main St, City, Prov',
                              prefix: const Icon(
                                LucideIcons.home,
                                size: 16,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          if (isGuest) ...[
                            const SizedBox(height: 14),
                            _buildSheetLabel('Email'),
                            TextField(
                              controller: _guestEmailController,
                              keyboardType: TextInputType.emailAddress,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cDarkBg,
                              ),
                              decoration: _buildInputDecoration(
                                'you@email.com',
                                prefix: const Icon(
                                  LucideIcons.mail,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                            const SizedBox(height: 12),
                            _buildSheetLabel('Phone'),
                            TextField(
                              controller: _guestPhoneController,
                              keyboardType: TextInputType.phone,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                                LengthLimitingTextInputFormatter(10),
                              ],
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cDarkBg,
                              ),
                              decoration: _buildInputDecoration(
                                '(555) 123-4567',
                                prefix: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      const Icon(
                                        LucideIcons.phone,
                                        size: 16,
                                        color: Colors.grey,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '+1',
                                        style: GoogleFonts.outfit(
                                          fontWeight: FontWeight.w800,
                                          color: Colors.grey[700],
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (showEmploymentDetails) ...[
                      _sectionCard(
                        icon: LucideIcons.briefcase,
                        title: 'Employment Details',
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildSheetLabel('Company / Institution'),
                            TextField(
                              controller: _empCompanyController,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cDarkBg,
                              ),
                              decoration: _buildInputDecoration('Company name'),
                            ),
                            const SizedBox(height: 12),
                            _buildSheetLabel('Job Title'),
                            TextField(
                              controller: _empTitleController,
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: cDarkBg,
                              ),
                              decoration: _buildInputDecoration('Job title'),
                            ),
                            const SizedBox(height: 12),
                            _buildSheetLabel('Time at Current Income'),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildDropdown(
                                    hint: 'Years',
                                    value: vm.incomeYears,
                                    items: List.generate(
                                      31,
                                      (i) => i.toString(),
                                    ),
                                    onChanged: (v) {
                                      setState(() => vm.incomeYears = v);
                                      vm.saveDraft();
                                    },
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildDropdown(
                                    hint: 'Months',
                                    value: vm.incomeMonths,
                                    items: List.generate(
                                      12,
                                      (i) => i.toString(),
                                    ),
                                    onChanged: (v) {
                                      setState(() => vm.incomeMonths = v);
                                      vm.saveDraft();
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    _sectionCard(
                      icon: LucideIcons.piggyBank,
                      title: 'Financial Inputs',
                      child: Column(
                        children: [
                          _sliderField(
                            label: 'Monthly Housing Cost',
                            valueLabel:
                                '${_formatCurrency(vm.housingCost)}${vm.housingCost >= 5000 ? '+' : ''}/mo',
                            value: vm.housingCost,
                            min: 0,
                            max: 5000,
                            onChanged: (v) =>
                                setState(() => vm.housingCost = v),
                            onChangeEnd: (_) => vm.saveDraft(),
                          ),
                          const SizedBox(height: 14),
                          _sliderField(
                            label: 'Downpayment',
                            valueLabel: _formatCurrency(vm.downpayment),
                            value: vm.downpayment,
                            min: 0,
                            max: 10000,
                            onChanged: (v) =>
                                setState(() => vm.downpayment = v),
                            onChangeEnd: (_) => vm.saveDraft(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionCard(
                      icon: LucideIcons.users,
                      title: 'Co-signer',
                      child: Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              text: 'Yes',
                              isSelected: vm.hasCosigner == 'yes',
                              onTap: () {
                                setState(() => vm.hasCosigner = 'yes');
                                vm.saveDraft();
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildToggleButton(
                              text: 'No',
                              isSelected: vm.hasCosigner == 'no',
                              onTap: () {
                                setState(() => vm.hasCosigner = 'no');
                                vm.saveDraft();
                              },
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _sectionCard(
                      icon: LucideIcons.messageSquare,
                      title: 'Additional Notes',
                      child: TextField(
                        controller: _notesController,
                        maxLines: 3,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cDarkBg,
                        ),
                        decoration: _buildInputDecoration(
                          'Any specific requirements?',
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () {
                        setState(() => vm.acceptedTerms = !vm.acceptedTerms);
                        vm.saveDraft();
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 22,
                              height: 22,
                              margin: const EdgeInsets.only(top: 1),
                              decoration: BoxDecoration(
                                color: vm.acceptedTerms ? cNeon : Colors.white,
                                border: Border.all(
                                  color: vm.acceptedTerms
                                      ? cNeon
                                      : Colors.grey[300]!,
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: vm.acceptedTerms
                                  ? const Icon(
                                      LucideIcons.check,
                                      size: 14,
                                      color: cDarkBg,
                                    )
                                  : null,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text.rich(
                                TextSpan(
                                  style: GoogleFonts.outfit(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                    fontWeight: FontWeight.w500,
                                    height: 1.45,
                                  ),
                                  children: [
                                    const TextSpan(text: 'I accept the '),
                                    TextSpan(
                                      text: 'Terms of Service',
                                      style: GoogleFonts.outfit(
                                        color: cDarkBg,
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const TextSpan(text: ' and '),
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: GoogleFonts.outfit(
                                        color: cDarkBg,
                                        fontWeight: FontWeight.w800,
                                        decoration: TextDecoration.underline,
                                      ),
                                    ),
                                    const TextSpan(text: '.'),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 96),
                  ],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: (!vm.acceptedTerms || _isSubmittingLead)
                        ? null
                        : _submitLead,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: cNeon,
                      foregroundColor: cDarkBg,
                      disabledBackgroundColor: Colors.grey[200],
                      disabledForegroundColor: Colors.grey[400],
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: vm.acceptedTerms ? 6 : 0,
                      shadowColor: cNeon.withValues(alpha: 0.3),
                    ),
                    child: _isSubmittingLead
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: cDarkBg,
                            ),
                          )
                        : Text(
                            'SUBMIT REQUEST',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoPill({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: cLightBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[200]!),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: cDarkBg),
            const SizedBox(width: 8),
            Expanded(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$label\n',
                      style: GoogleFonts.outfit(
                        fontSize: 10,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w700,
                        height: 1.1,
                      ),
                    ),
                    TextSpan(
                      text: value,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: cDarkBg,
                        fontWeight: FontWeight.w900,
                        height: 1.2,
                      ),
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

  Widget _sectionCard({
    required IconData icon,
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: cLightBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 14, color: cDarkBg),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: cDarkBg,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  Widget _sliderField({
    required String label,
    required String valueLabel,
    required double value,
    required double min,
    required double max,
    required ValueChanged<double> onChanged,
    required ValueChanged<double> onChangeEnd,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: _buildSheetLabel(label)),
            Text(
              valueLabel,
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: cDarkBg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: cDarkBg,
            inactiveTrackColor: Colors.grey[200],
            trackHeight: 7,
            trackShape: const CustomSliderTrackShape(),
            thumbShape: const RoundSliderThumbShape(
              enabledThumbRadius: 11,
              elevation: 2,
            ),
            thumbColor: Colors.white,
            overlayColor: cDarkBg.withValues(alpha: 0.10),
          ),
          child: Slider(
            min: min,
            max: max,
            divisions: 100,
            value: value,
            onChanged: onChanged,
            onChangeEnd: onChangeEnd,
          ),
        ),
      ],
    );
  }

  Widget _buildSheetLabel(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 2, bottom: 6),
        child: Text(
          text,
          textAlign: TextAlign.left,
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.grey[500],
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {Widget? prefix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: prefix,
      hintStyle: GoogleFonts.outfit(
        color: Colors.grey[400],
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: Colors.grey[50],
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(color: Colors.grey[200]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: cDarkBg, width: 1.5),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    final safeValue = items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      isExpanded: true,
      initialValue: safeValue,
      items: items
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                item,
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: cDarkBg,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      icon: const Icon(LucideIcons.chevronDown, size: 16),
      decoration: _buildInputDecoration(hint).copyWith(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 12,
        ),
      ),
      dropdownColor: Colors.white,
    );
  }

  Widget _buildToggleButton({
    required String text,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? cDarkBg : Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? cDarkBg : Colors.grey[200]!),
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
