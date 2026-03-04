import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../../services/api_service.dart';
import '../../services/auth_service.dart';
import 'buyer_dashboard_constants.dart';
import 'buyer_dashboard_view_model.dart';

class BuyerDashboardBottomSheet extends StatefulWidget {
  final BuyerDashboardViewModel viewModel;
  final VoidCallback? onLeadSubmitted;
  final Set<String> inventoryContextIds;

  const BuyerDashboardBottomSheet({
    super.key,
    required this.viewModel,
    required this.inventoryContextIds,
    this.onLeadSubmitted,
  });

  @override
  State<BuyerDashboardBottomSheet> createState() =>
      _BuyerDashboardBottomSheetState();
}

class _BuyerDashboardBottomSheetState extends State<BuyerDashboardBottomSheet> {
  late TextEditingController _homeAddressController;
  late TextEditingController _empCompanyController;
  late TextEditingController _empTitleController;
  late TextEditingController _notesController;

  bool _isSubmittingLead = false;

  @override
  void initState() {
    super.initState();
    _homeAddressController = TextEditingController(
      text: widget.viewModel.homeAddress,
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
    _homeAddressController.dispose();
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

  @override
  Widget build(BuildContext context) {
    // Note: The UI for the Bottom Sheet goes here, replicating lines 351-908
    // I will replace `setSheetState` with standard `setState` or update the viewModel directly
    // and rely on Provider to rebuild the root if necessary, but since this is a StatefulWidget
    // local `setState` handles UI feedback instantly.

    final bool showEmploymentDetails =
        widget.viewModel.employment == 'Full-time' ||
        widget.viewModel.employment == 'Part-time' ||
        widget.viewModel.employment == 'Self-employed';

    return Container(
      decoration: const BoxDecoration(
        color: cLightBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(40)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 40,
            offset: Offset(0, -10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background subtle design
          Positioned(
            top: -50,
            right: -50,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cNeon.withValues(alpha: 0.15),
              ),
            ),
          ),
          Positioned(
            top: 12,
            left: 0,
            right: 0,
            child: Center(
              child: Container(
                width: 48,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
          ),
          Positioned(
            top: 24,
            right: 24,
            child: InkWell(
              onTap: () => Navigator.of(context).pop(),
              borderRadius: BorderRadius.circular(999),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: cDarkBg.withValues(alpha: 0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Icon(LucideIcons.x, size: 16, color: cDarkBg),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: cNeon.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.zap,
                        color: cDarkBg,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Final Step',
                          style: GoogleFonts.outfit(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: cDarkBg,
                            letterSpacing: -0.5,
                            height: 1.1,
                          ),
                        ),
                        Text(
                          'Secure your approval in seconds.',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Expanded(
                  child: ListView(
                    physics: const BouncingScrollPhysics(),
                    children: [
                      _buildSheetLabel('Date of Birth'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildDropdown(
                              hint: 'Month',
                              value: widget.viewModel.dobMonth,
                              items: List.generate(
                                12,
                                (i) => (i + 1).toString().padLeft(2, '0'),
                              ),
                              onChanged: (v) {
                                setState(() => widget.viewModel.dobMonth = v);
                                widget.viewModel.saveDraft();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDropdown(
                              hint: 'Day',
                              value: widget.viewModel.dobDay,
                              items: List.generate(
                                31,
                                (i) => (i + 1).toString().padLeft(2, '0'),
                              ),
                              onChanged: (v) {
                                setState(() => widget.viewModel.dobDay = v);
                                widget.viewModel.saveDraft();
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: _buildDropdown(
                              hint: 'Year',
                              value: widget.viewModel.dobYear,
                              items: List.generate(
                                80,
                                (i) =>
                                    (DateTime.now().year - 18 - i).toString(),
                              ),
                              onChanged: (v) {
                                setState(() => widget.viewModel.dobYear = v);
                                widget.viewModel.saveDraft();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
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
                        ),
                      ),
                      const SizedBox(height: 20),
                      if (showEmploymentDetails) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: cLightBg,
                            border: Border.all(color: Colors.grey[200]!),
                            borderRadius: BorderRadius.circular(24),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildSheetLabel('Employment Details'),
                              TextField(
                                controller: _empCompanyController,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: cDarkBg,
                                ),
                                decoration: _buildInputDecoration(
                                  'Company / Institution',
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextField(
                                controller: _empTitleController,
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: cDarkBg,
                                ),
                                decoration: _buildInputDecoration(
                                  'Job Title',
                                  fillColor: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 16),
                              const Divider(height: 1),
                              const SizedBox(height: 16),
                              _buildSheetLabel('Time at Current Income'),
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdown(
                                      hint: 'Years',
                                      value: widget.viewModel.incomeYears,
                                      items: List.generate(
                                        31,
                                        (i) => i.toString(),
                                      ),
                                      onChanged: (v) {
                                        setState(
                                          () =>
                                              widget.viewModel.incomeYears = v,
                                        );
                                        widget.viewModel.saveDraft();
                                      },
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: _buildDropdown(
                                      hint: 'Months',
                                      value: widget.viewModel.incomeMonths,
                                      items: List.generate(
                                        12,
                                        (i) => i.toString(),
                                      ),
                                      onChanged: (v) {
                                        setState(
                                          () =>
                                              widget.viewModel.incomeMonths = v,
                                        );
                                        widget.viewModel.saveDraft();
                                      },
                                      fillColor: Colors.white,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildSheetLabel('Monthly Housing Cost'),
                          Text(
                            '${_formatCurrency(widget.viewModel.housingCost)}${widget.viewModel.housingCost >= 5000 ? '+' : ''}/mo',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: cDarkBg,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          padding: EdgeInsets.zero,
                          activeTrackColor: cNeon,
                          inactiveTrackColor: Colors.grey[200],
                          trackHeight: 8,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 14,
                            elevation: 4,
                          ),
                          thumbColor: cDarkBg,
                          overlayColor: cNeon.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          min: 0,
                          max: 5000,
                          divisions: 100,
                          value: widget.viewModel.housingCost,
                          onChanged: (v) =>
                              setState(() => widget.viewModel.housingCost = v),
                          onChangeEnd: (_) => widget.viewModel.saveDraft(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          _buildSheetLabel('Downpayment'),
                          Text(
                            _formatCurrency(widget.viewModel.downpayment),
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: cDarkBg,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          padding: EdgeInsets.zero,
                          activeTrackColor: cNeon,
                          inactiveTrackColor: Colors.grey[200],
                          trackHeight: 8,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 14,
                            elevation: 4,
                          ),
                          thumbColor: cDarkBg,
                          overlayColor: cNeon.withValues(alpha: 0.2),
                        ),
                        child: Slider(
                          min: 0,
                          max: 10000,
                          divisions: 100,
                          value: widget.viewModel.downpayment,
                          onChanged: (v) =>
                              setState(() => widget.viewModel.downpayment = v),
                          onChangeEnd: (_) => widget.viewModel.saveDraft(),
                        ),
                      ),
                      const SizedBox(height: 20),
                      _buildSheetLabel('Do you have a co-signer?'),
                      Row(
                        children: [
                          Expanded(
                            child: _buildToggleButton(
                              text: 'Yes',
                              isSelected: widget.viewModel.hasCosigner == 'yes',
                              onTap: () {
                                setState(
                                  () => widget.viewModel.hasCosigner = 'yes',
                                );
                                widget.viewModel.saveDraft();
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildToggleButton(
                              text: 'No',
                              isSelected: widget.viewModel.hasCosigner == 'no',
                              onTap: () {
                                setState(
                                  () => widget.viewModel.hasCosigner = 'no',
                                );
                                widget.viewModel.saveDraft();
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      _buildSheetLabel('Additional Comments (Optional)'),
                      TextField(
                        controller: _notesController,
                        maxLines: 2,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: cDarkBg,
                        ),
                        decoration: _buildInputDecoration(
                          'Any specific requirements?',
                        ),
                      ),
                      const SizedBox(height: 20),
                      InkWell(
                        onTap: () => setState(
                          () => widget.viewModel.acceptedTerms =
                              !widget.viewModel.acceptedTerms,
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 20,
                                height: 20,
                                margin: const EdgeInsets.only(top: 2),
                                decoration: BoxDecoration(
                                  color: widget.viewModel.acceptedTerms
                                      ? cNeon
                                      : Colors.white,
                                  border: Border.all(
                                    color: widget.viewModel.acceptedTerms
                                        ? cNeon
                                        : Colors.grey[300]!,
                                  ),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: widget.viewModel.acceptedTerms
                                    ? const Icon(
                                        LucideIcons.checkCircle,
                                        size: 14,
                                        color: cDarkBg,
                                      )
                                    : null,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: RichText(
                                  text: TextSpan(
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                      height: 1.5,
                                    ),
                                    children: [
                                      const TextSpan(text: 'I accept the '),
                                      TextSpan(
                                        text: 'Terms of Service',
                                        style: GoogleFonts.outfit(
                                          color: cDarkBg,
                                          fontWeight: FontWeight.w700,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                      const TextSpan(text: ' and '),
                                      TextSpan(
                                        text: 'Privacy Policy',
                                        style: GoogleFonts.outfit(
                                          color: cDarkBg,
                                          fontWeight: FontWeight.w700,
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
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed:
                            (!widget.viewModel.acceptedTerms ||
                                _isSubmittingLead)
                            ? null
                            : () async {
                                setState(() => _isSubmittingLead = true);
                                final auth = AuthService();

                                final extraDetails =
                                    '''
DOB: ${widget.viewModel.dobMonth ?? ''}/${widget.viewModel.dobDay ?? ''}/${widget.viewModel.dobYear ?? ''}
Address: ${_homeAddressController.text}
Employment: ${_empCompanyController.text}, ${_empTitleController.text} (${widget.viewModel.incomeYears ?? '0'}y ${widget.viewModel.incomeMonths ?? '0'}m)
Housing: ${_formatCurrency(widget.viewModel.housingCost)}/mo
Downpayment: ${_formatCurrency(widget.viewModel.downpayment)}
Co-signer: ${widget.viewModel.hasCosigner ?? 'unspecified'}
Notes: ${_notesController.text}
                                '''
                                        .trim();

                                final navigator = Navigator.of(context);
                                final scaffoldMessenger = ScaffoldMessenger.of(
                                  context,
                                );

                                try {
                                  await ApiService.submitBuyerPreapprovalLead(
                                    name: auth.userName.isEmpty
                                        ? 'User'
                                        : auth.userName,
                                    phone: auth.userPhone.isEmpty
                                        ? '0000000000'
                                        : auth.userPhone,
                                    monthlyBudgetTarget:
                                        widget.viewModel.budget,
                                    incomeRange: widget.viewModel.income!,
                                    employmentStatus:
                                        widget.viewModel.employment!,
                                    creditBand: widget.viewModel.credit!,
                                    notes: extraDetails,
                                    inventoryContext: widget.inventoryContextIds
                                        .take(8)
                                        .toList(),
                                  );

                                  if (!mounted) return;
                                  navigator.pop();
                                  widget.onLeadSubmitted?.call();
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Request sent successfully.',
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  if (!mounted) return;
                                  setState(() => _isSubmittingLead = false);
                                  scaffoldMessenger.showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Could not submit request right now.',
                                      ),
                                    ),
                                  );
                                }
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: cDarkBg,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[200],
                          disabledForegroundColor: Colors.grey[400],
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: widget.viewModel.acceptedTerms ? 8 : 0,
                          shadowColor: cDarkBg.withValues(alpha: 0.3),
                        ),
                        child: _isSubmittingLead
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'SUBMIT REQUEST',
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 1.0,
                                ),
                              ),
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --- Helpers for Bottom Sheet Form ---

  Widget _buildSheetLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: Colors.grey[500],
          letterSpacing: 1.5,
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration(String hint, {Color? fillColor}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.outfit(
        color: Colors.grey[400],
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: fillColor ?? Colors.white,
      contentPadding: const EdgeInsets.all(18),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: cNeon, width: 2),
      ),
    );
  }

  Widget _buildDropdown({
    required String hint,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    Color? fillColor,
  }) {
    // Safety check: ensure the value exists in our items list.
    final safeValue = items.contains(value) ? value : null;

    return DropdownButtonFormField<String>(
      isExpanded: true,
      // Use initialValue instead of value since it is deprecated.
      initialValue: safeValue,
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(
            item,
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: cDarkBg,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      icon: const Icon(LucideIcons.chevronDown, size: 16),
      decoration: _buildInputDecoration(hint, fillColor: fillColor).copyWith(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 10,
          vertical: 16,
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
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? cDarkBg : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? cDarkBg : Colors.grey[200]!,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: cDarkBg.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        alignment: Alignment.center,
        child: Text(
          text,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: isSelected ? Colors.white : Colors.grey[600],
          ),
        ),
      ),
    );
  }
}
