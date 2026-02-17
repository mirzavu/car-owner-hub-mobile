import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class VerifyScanScreen extends StatefulWidget {
  final Function(String) setStep;
  final Map<String, dynamic> scanData;
  final Map<String, String> carDetails;
  final double estimatedValue;
  final Function(Map<String, String>) onUpdateCarDetails;
  final VoidCallback onBack;

  const VerifyScanScreen({
    super.key,
    required this.setStep,
    required this.scanData,
    required this.carDetails,
    required this.estimatedValue,
    required this.onUpdateCarDetails,
    required this.onBack,
  });

  @override
  State<VerifyScanScreen> createState() => _VerifyScanScreenState();
}

class _VerifyScanScreenState extends State<VerifyScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;
  Map<String, String>? _vinDetails;
  bool _isVinLookupInProgress = false;
  String? _vinLookupError;

  bool _isEditing = false;
  late TextEditingController _vehicleController;
  late TextEditingController _vinController;
  late TextEditingController _dateController;
  late TextEditingController _termController;
  late TextEditingController _lenderController;
  late TextEditingController _aprController;
  late TextEditingController _paymentController;
  late TextEditingController _balanceController;

  bool get _isManualEntry => widget.scanData.isEmpty;

  @override
  void initState() {
    super.initState();

    // Auto-enable editing if no scan data was provided
    if (_isManualEntry) {
      _isEditing = true;
    }

    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 0.95,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();

    _initControllers();

    // Only lookup VIN if we actually scanned one
    if (!_isManualEntry) {
      _loadVinDetails();
    }
  }

  void _initControllers() {
    final userVehicle = _formatVehicle(
      widget.carDetails['year'],
      widget.carDetails['make'],
      widget.carDetails['model'],
    );
    _vehicleController = TextEditingController(text: userVehicle);
    _vinController = TextEditingController(
      text: _normalizeVin(widget.scanData['vin']?.toString()),
    );
    _dateController = TextEditingController(
      text: widget.scanData['contract_date']?.toString() ?? "",
    );
    _termController = TextEditingController(
      text: widget.scanData['term_months']?.toString() ?? "",
    );
    _lenderController = TextEditingController(
      text: widget.scanData['lender_name']?.toString() ?? "",
    );
    _aprController = TextEditingController(
      text: widget.scanData['interest_rate']?.toString() ?? "",
    );

    String paymentStr = "";
    if (widget.scanData['bi_weekly_payment'] != null) {
      paymentStr = NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 2,
      ).format(widget.scanData['bi_weekly_payment']);
    } else if (widget.scanData['monthly_payment'] != null) {
      paymentStr = NumberFormat.currency(
        symbol: '\$',
        decimalDigits: 2,
      ).format(widget.scanData['monthly_payment']);
    }
    _paymentController = TextEditingController(text: paymentStr);

    final balanceValue =
        widget.scanData['original_amount_financed'] ??
        widget.scanData['current_balance'];

    _balanceController = TextEditingController(
      text: balanceValue != null
          ? NumberFormat.currency(
              symbol: '\$',
              decimalDigits: 0,
            ).format(balanceValue)
          : "",
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    _vehicleController.dispose();
    _vinController.dispose();
    _dateController.dispose();
    _termController.dispose();
    _lenderController.dispose();
    _aprController.dispose();
    _paymentController.dispose();
    _balanceController.dispose();
    super.dispose();
  }

  String _normalizeToken(String value) {
    return value.trim().toUpperCase();
  }

  String _normalizeVin(String? vin) {
    if (vin == null) return '';
    return vin.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
  }

  String _formatVehicle(String? year, String? make, String? model) {
    final parts = [
      if ((year ?? '').trim().isNotEmpty) year!.trim(),
      if ((make ?? '').trim().isNotEmpty) make!.trim(),
      if ((model ?? '').trim().isNotEmpty) model!.trim(),
    ];
    return parts.isEmpty ? 'Unknown' : parts.join(' ');
  }

  Future<void> _loadVinDetails() async {
    final normalizedVin = _normalizeVin(widget.scanData['vin']?.toString());
    if (normalizedVin.length != 17) {
      return;
    }

    setState(() {
      _isVinLookupInProgress = true;
      _vinLookupError = null;
    });

    final details = await ApiService.decodeVin(normalizedVin);
    if (!mounted) return;

    setState(() {
      _vinDetails = details.isEmpty ? null : details;
      _isVinLookupInProgress = false;
      if (details.isEmpty) {
        _vinLookupError = 'Unable to decode VIN';
      }
    });
  }

  bool _matchesIfPresent(String? a, String? b) {
    if ((a ?? '').trim().isEmpty || (b ?? '').trim().isEmpty) return true;
    return _normalizeToken(a!) == _normalizeToken(b!);
  }

  bool get _hasVinDetected {
    final normalizedVin = _normalizeVin(widget.scanData['vin']?.toString());
    return normalizedVin.length == 17;
  }

  bool get _hasConflict {
    if (_vinDetails == null) return false;
    final user = widget.carDetails;
    final yearOk = _matchesIfPresent(user['year'], _vinDetails!['year']);
    final makeOk = _matchesIfPresent(user['make'], _vinDetails!['make']);
    final modelOk = _matchesIfPresent(user['model'], _vinDetails!['model']);
    return !(yearOk && makeOk && modelOk);
  }

  Future<void> _handleUseDocumentDetails() async {
    debugPrint("[VERIFY] User chose: Use Document Details");
    final normalizedVin = _normalizeVin(widget.scanData['vin']?.toString());
    final updates = <String, String>{};
    if (_vinDetails != null) {
      if ((_vinDetails!['year'] ?? '').isNotEmpty) {
        updates['year'] = _vinDetails!['year']!;
      }
      if ((_vinDetails!['make'] ?? '').isNotEmpty) {
        updates['make'] = _vinDetails!['make']!;
      }
      if ((_vinDetails!['model'] ?? '').isNotEmpty) {
        updates['model'] = _vinDetails!['model']!;
      }
    }
    if (normalizedVin.isNotEmpty) {
      updates['vin'] = normalizedVin;
    }

    if (updates.isNotEmpty) {
      debugPrint(
        "[VERIFY] Applying car detail updates from document: $updates",
      );
      widget.onUpdateCarDetails(updates);
    }

    // Create/Update in DB
    debugPrint("[VERIFY] Syncing data with isVerified=true");
    await ApiService.syncOnboardingData(
      carDetails: widget.carDetails,
      scanData: widget.scanData,
      estimatedValue: widget.estimatedValue,
      isVerified: true,
      documentId: widget.scanData['documentId']?.toString(),
    );

    await AuthService().updateOnboardingStatus('completed');
    widget.setStep('main-app');
  }

  void _handleVerify() async {
    debugPrint("[VERIFY] User chose: Save & Verify (Final)");
    if (_isEditing) {
      debugPrint("[VERIFY] Editing was active. Capturing manual input.");
      // 1. Update Scan Data from controllers
      final balanceText = _balanceController.text.replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      final paymentText = _paymentController.text.replaceAll(
        RegExp(r'[^0-9.]'),
        '',
      );
      final aprText = _aprController.text.replaceAll(RegExp(r'[^0-9.]'), '');
      final termText = _termController.text.replaceAll(RegExp(r'[^0-9]'), '');

      widget.scanData['vin'] = _vinController.text.trim();
      widget.scanData['contract_date'] = _dateController.text.trim();
      widget.scanData['term_months'] = int.tryParse(termText);
      widget.scanData['lender_name'] = _lenderController.text.trim();
      widget.scanData['interest_rate'] = double.tryParse(aprText);

      if (widget.scanData['bi_weekly_payment'] != null) {
        widget.scanData['bi_weekly_payment'] = double.tryParse(paymentText);
      } else {
        widget.scanData['monthly_payment'] = double.tryParse(paymentText);
      }
      widget.scanData['original_amount_financed'] = double.tryParse(
        balanceText,
      );
      widget.scanData['current_balance'] = double.tryParse(balanceText);

      // 2. Update Car Details if vehicle string was changed
      final vehicleText = _vehicleController.text.trim();
      final vehicleParts = vehicleText.split(' ');
      if (vehicleParts.length >= 3) {
        final updates = {
          'year': vehicleParts[0],
          'make': vehicleParts[1],
          'model': vehicleParts.sublist(2).join(' '),
        };
        debugPrint("[VERIFY] Manual vehicle updates: $updates");
        widget.onUpdateCarDetails(updates);
      }
      debugPrint(
        "[VERIFY] Final Scan Data (Manually Edited): ${widget.scanData}",
      );
    } else {
      debugPrint(
        "[VERIFY] User confirmed data as correct without manual edits.",
      );
      debugPrint("[VERIFY] Final Scan Data: ${widget.scanData}");
    }

    final normalizedVin = _normalizeVin(widget.scanData['vin']?.toString());
    if (normalizedVin.isNotEmpty) {
      widget.onUpdateCarDetails({'vin': normalizedVin});
    }

    debugPrint("[VERIFY] Final sync start...");
    await ApiService.syncOnboardingData(
      carDetails: widget.carDetails,
      scanData: widget.scanData,
      estimatedValue: widget.estimatedValue,
      isVerified: true,
      documentId: widget.scanData['documentId']?.toString(),
    );

    await AuthService().updateOnboardingStatus('completed');
    widget.setStep('main-app');
  }

  @override
  Widget build(BuildContext context) {
    // Colors
    const colorSlate50 = Color(0xFFF8FAFC);
    const colorSlate100 = Color(0xFFF1F5F9);
    const colorSlate400 = Color(0xFF94A3B8);
    const colorSlate500 = Color(0xFF64748B);
    const colorSlate800 = Color(0xFF1E293B);
    const colorSlate900 = Color(0xFF0F172A);
    const colorGreen100 = Color(0xFFDCFCE7);
    const colorVibrantGreen = Color(0xFF00CA50);
    const colorRed100 = Color(0xFFFEE2E2);
    const colorRed700 = Color(0xFFB91C1C);
    const colorAmber50 = Color(0xFFFFFBEB);
    const colorAmber100 = Color(0xFFFEF3C7);
    const colorAmber200 = Color(0xFFFDE68A);
    const colorAmber800 = Color(0xFF92400E);

    final normalizedVin = _normalizeVin(widget.scanData['vin']?.toString());
    final userVehicle = _formatVehicle(
      widget.carDetails['year'],
      widget.carDetails['make'],
      widget.carDetails['model'],
    );
    final docVehicle = _vinDetails == null
        ? "Unavailable"
        : _formatVehicle(
            _vinDetails!['year'],
            _vinDetails!['make'],
            _vinDetails!['model'],
          );
    final hasConflict = _hasConflict;
    final statusIconBg = hasConflict ? colorAmber50 : colorGreen100;
    final statusIconColor = hasConflict ? colorAmber800 : colorVibrantGreen;
    final statusIcon = hasConflict
        ? LucideIcons.alertTriangle
        : LucideIcons.checkCircle2;

    return Scaffold(
      backgroundColor: colorSlate50,
      // 1. SAFE AREA ADDED
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  // 2. INCREASED TOP PADDING (60 -> 90) to prevent camera overlap
                  // Since the icon is -36, we need about 80-90 padding to clear it comfortably
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: ScaleTransition(
                        scale: _scaleAnimation,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // --- Back Button (Now properly in the layout flow) ---
                            IconButton(
                              icon: const Icon(
                                LucideIcons.arrowLeft,
                                color: colorSlate500,
                              ),
                              onPressed: widget.onBack,
                              // Shift it slightly left so it aligns with the card edge
                              padding: EdgeInsets.zero,
                              alignment: Alignment.centerLeft,
                            ),

                            // Added spacing between the back button and the floating icon
                            const SizedBox(height: 32),

                            // --- The Card & Floating Icon ---
                            Stack(
                              clipBehavior: Clip.none,
                              alignment: Alignment.topCenter,
                              children: [
                                // --- The Card ---
                                Container(
                                  width: double.infinity,
                                  constraints: const BoxConstraints(
                                    maxWidth: 420,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(
                                          alpha: 0.08,
                                        ),
                                        blurRadius: 24,
                                        offset: const Offset(0, 12),
                                      ),
                                    ],
                                  ),
                                  padding: const EdgeInsets.fromLTRB(
                                    24,
                                    48,
                                    24,
                                    24,
                                  ),
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      // Title
                                      Text(
                                        _isManualEntry
                                            ? "Enter Loan Details"
                                            : (hasConflict
                                                  ? "Review Discrepancy"
                                                  : "Confirm Details"),
                                        textAlign: TextAlign.center,
                                        style: GoogleFonts.outfit(
                                          fontSize: 24,
                                          fontWeight: FontWeight.bold,
                                          color: colorSlate900,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (_hasVinDetected &&
                                          !hasConflict &&
                                          !_isManualEntry)
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 6,
                                          ),
                                          decoration: BoxDecoration(
                                            color: colorGreen100,
                                            borderRadius: BorderRadius.circular(
                                              999,
                                            ),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                LucideIcons.badgeCheck,
                                                size: 16,
                                                color: colorVibrantGreen,
                                              ),
                                              const SizedBox(width: 6),
                                              Text(
                                                "VIN Verified",
                                                style: GoogleFonts.outfit(
                                                  color: colorVibrantGreen,
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      if (_isVinLookupInProgress) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          "Checking VIN details...",
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: colorSlate400,
                                          ),
                                        ),
                                      ],
                                      if (_vinLookupError != null &&
                                          !_isVinLookupInProgress) ...[
                                        const SizedBox(height: 8),
                                        Text(
                                          _vinLookupError!,
                                          style: GoogleFonts.outfit(
                                            fontSize: 12,
                                            color: colorSlate400,
                                          ),
                                        ),
                                      ],
                                      const SizedBox(height: 24),

                                      // 3. IMPROVED COMPARISON UI
                                      if (hasConflict && !_isManualEntry) ...[
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            color: colorAmber50,
                                            borderRadius: BorderRadius.circular(
                                              16,
                                            ),
                                            border: Border.all(
                                              color: colorAmber200,
                                            ),
                                          ),
                                          child: Column(
                                            children: [
                                              // Header
                                              Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 12,
                                                      vertical: 8,
                                                    ),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    const Icon(
                                                      LucideIcons
                                                          .arrowLeftRight,
                                                      size: 14,
                                                      color: colorAmber800,
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Text(
                                                      "Data Mismatch Detected",
                                                      style: GoogleFonts.outfit(
                                                        fontSize: 12,
                                                        fontWeight:
                                                            FontWeight.w700,
                                                        color: colorAmber800,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                              const Divider(
                                                height: 1,
                                                color: colorAmber200,
                                              ),
                                              // Comparison Body
                                              IntrinsicHeight(
                                                child: Row(
                                                  children: [
                                                    // User Side
                                                    Expanded(
                                                      child: Padding(
                                                        padding:
                                                            const EdgeInsets.all(
                                                              12,
                                                            ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                  LucideIcons
                                                                      .user,
                                                                  size: 14,
                                                                  color:
                                                                      colorSlate400,
                                                                ),
                                                                const SizedBox(
                                                                  width: 6,
                                                                ),
                                                                Flexible(
                                                                  child: Text(
                                                                    "You Entered"
                                                                        .toUpperCase(),
                                                                    style: GoogleFonts.outfit(
                                                                      fontSize:
                                                                          11,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w600,
                                                                      color:
                                                                          colorSlate500,
                                                                      letterSpacing:
                                                                          0.5,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              userVehicle,
                                                              style: GoogleFonts.outfit(
                                                                fontSize: 14,
                                                                color:
                                                                    colorSlate500,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                height: 1.2,
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                    // Vertical Divider
                                                    Container(
                                                      width: 1,
                                                      color: colorAmber200,
                                                    ),
                                                    // Scanned Side
                                                    Expanded(
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                          color: colorAmber100
                                                              .withValues(
                                                                alpha: 0.3,
                                                              ),
                                                          borderRadius:
                                                              const BorderRadius.only(
                                                                bottomRight:
                                                                    Radius.circular(
                                                                      15,
                                                                    ),
                                                              ),
                                                        ),
                                                        padding:
                                                            const EdgeInsets.all(
                                                              12,
                                                            ),
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Row(
                                                              children: [
                                                                const Icon(
                                                                  LucideIcons
                                                                      .scanLine,
                                                                  size: 14,
                                                                  color:
                                                                      colorAmber800,
                                                                ),
                                                                const SizedBox(
                                                                  width: 6,
                                                                ),
                                                                Flexible(
                                                                  child: Text(
                                                                    "Scanned"
                                                                        .toUpperCase(),
                                                                    style: GoogleFonts.outfit(
                                                                      fontSize:
                                                                          11,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold,
                                                                      color:
                                                                          colorAmber800,
                                                                      letterSpacing:
                                                                          0.5,
                                                                    ),
                                                                    overflow:
                                                                        TextOverflow
                                                                            .ellipsis,
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                            const SizedBox(
                                                              height: 8,
                                                            ),
                                                            Text(
                                                              docVehicle,
                                                              style: GoogleFonts.outfit(
                                                                fontSize: 14,
                                                                color:
                                                                    colorSlate900,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w700,
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
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 24),
                                      ],

                                      // Details List
                                      Column(
                                        children: [
                                          _DetailRow(
                                            label: "Vehicle",
                                            value: userVehicle,
                                            isEditing: _isEditing,
                                            controller: _vehicleController,
                                            colorSlate100: colorSlate100,
                                            colorSlate500: colorSlate500,
                                            colorSlate800: colorSlate800,
                                          ),
                                          _DetailRow(
                                            label: "VIN",
                                            value: normalizedVin.isNotEmpty
                                                ? normalizedVin
                                                : "Not detected",
                                            isMono: true,
                                            isEditing: _isEditing,
                                            controller: _vinController,
                                            colorSlate100: colorSlate100,
                                            colorSlate500: colorSlate500,
                                            colorSlate800: colorSlate800,
                                          ),
                                          _DetailRow(
                                            label: "Term",
                                            value:
                                                widget.scanData['term_months'] !=
                                                    null
                                                ? "${widget.scanData['term_months']} months"
                                                : "N/A",
                                            isEditing: _isEditing,
                                            controller: _termController,
                                            colorSlate100: colorSlate100,
                                            colorSlate500: colorSlate500,
                                            colorSlate800: colorSlate800,
                                          ),
                                          _DetailRow(
                                            label: "Lender",
                                            value:
                                                widget
                                                    .scanData['lender_name'] ??
                                                "Unknown",
                                            isEditing: _isEditing,
                                            controller: _lenderController,
                                            colorSlate100: colorSlate100,
                                            colorSlate500: colorSlate500,
                                            colorSlate800: colorSlate800,
                                          ),
                                          _DetailRow(
                                            label: "Contract Date",
                                            value:
                                                widget
                                                    .scanData['contract_date'] ??
                                                "Unknown",
                                            isEditing: _isEditing,
                                            controller: _dateController,
                                            colorSlate100: colorSlate100,
                                            colorSlate500: colorSlate500,
                                            colorSlate800: colorSlate800,
                                          ),
                                          _DetailRow(
                                            label: "APR Rate",
                                            value:
                                                widget.scanData['interest_rate'] !=
                                                    null
                                                ? "${widget.scanData['interest_rate']}%"
                                                : "N/A",
                                            isHigh:
                                                (widget.scanData['interest_rate'] ??
                                                    0) >
                                                10,
                                            isEditing: _isEditing,
                                            controller: _aprController,
                                            colorSlate100: colorSlate100,
                                            colorSlate500: colorSlate500,
                                            colorSlate800: colorSlate800,
                                            colorRed100: colorRed100,
                                            colorRed700: colorRed700,
                                          ),
                                          _DetailRow(
                                            label: "Payment",
                                            value:
                                                widget.scanData['bi_weekly_payment'] !=
                                                    null
                                                ? "${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(widget.scanData['bi_weekly_payment'])}/bw"
                                                : widget.scanData['monthly_payment'] !=
                                                      null
                                                ? "${NumberFormat.currency(symbol: '\$', decimalDigits: 2).format(widget.scanData['monthly_payment'])}/mo"
                                                : "N/A",
                                            isEditing: _isEditing,
                                            controller: _paymentController,
                                            colorSlate100: colorSlate100,
                                            colorSlate500: colorSlate500,
                                            colorSlate800: colorSlate800,
                                          ),
                                          _DetailRow(
                                            label: "Financed Amount",
                                            value:
                                                widget.scanData['current_balance'] !=
                                                    null
                                                ? NumberFormat.currency(
                                                    symbol: '\$',
                                                    decimalDigits: 0,
                                                  ).format(
                                                    widget
                                                        .scanData['current_balance'],
                                                  )
                                                : "N/A",
                                            isEditing: _isEditing,
                                            controller: _balanceController,
                                            colorSlate100: colorSlate100,
                                            colorSlate500: colorSlate500,
                                            colorSlate800: colorSlate800,
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 32),
                                      // Unified Action Buttons
                                      SizedBox(
                                        width: double.infinity,
                                        child: ElevatedButton(
                                          onPressed: () {
                                            if (_isEditing) {
                                              _handleVerify();
                                            } else if (hasConflict) {
                                              _handleUseDocumentDetails();
                                            } else {
                                              _handleVerify();
                                            }
                                          },
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: colorVibrantGreen,
                                            foregroundColor: Colors.white,
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 18,
                                            ),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            elevation: _isEditing ? 4 : 2,
                                            shadowColor: colorVibrantGreen
                                                .withValues(alpha: 0.3),
                                          ),
                                          child: Text(
                                            _isEditing
                                                ? "Save & Verify"
                                                : (hasConflict
                                                      ? "Update with Scanned Data"
                                                      : "Looks Correct"),
                                            style: GoogleFonts.outfit(
                                              fontSize: _isEditing ? 18 : 16,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (!_isManualEntry)
                                        SizedBox(
                                          width: double.infinity,
                                          child: TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _isEditing = !_isEditing;
                                              });
                                            },
                                            style: TextButton.styleFrom(
                                              foregroundColor: _isEditing
                                                  ? colorSlate400
                                                  : colorSlate500,
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    vertical: 16,
                                                  ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                            ),
                                            child: Text(
                                              _isEditing
                                                  ? "Cancel editing"
                                                  : "Edit manually",
                                              style: GoogleFonts.outfit(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                // --- The Floating Icon ---
                                Positioned(
                                  top: -36,
                                  child: Container(
                                    width: 72,
                                    height: 72,
                                    decoration: BoxDecoration(
                                      color: statusIconBg,
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 4,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.black.withValues(
                                            alpha: 0.1,
                                          ),
                                          blurRadius: 10,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                    child: Center(
                                      child: Icon(
                                        statusIcon,
                                        size: 36,
                                        color: statusIconColor,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// Helper Widget for Rows (Unchanged from your code mostly, just cleaner logic)
class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isHigh;
  final bool isMono;
  final bool isEditing;
  final TextEditingController? controller;
  final Color colorSlate50 = const Color(0xFFF8FAFC);
  final Color colorSlate100;
  final Color colorSlate500;
  final Color colorSlate800;
  final Color? colorRed100;
  final Color? colorRed700;

  const _DetailRow({
    required this.label,
    required this.value,
    this.isHigh = false,
    this.isMono = false,
    this.isEditing = false,
    this.controller,
    required this.colorSlate100,
    required this.colorSlate500,
    required this.colorSlate800,
    this.colorRed100,
    this.colorRed700,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: colorSlate100)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.outfit(color: colorSlate500, fontSize: 16),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (isHigh && !isEditing) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      color: colorRed100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      "HIGH",
                      style: GoogleFonts.outfit(
                        color: colorRed700,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
                if (isEditing && controller != null)
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: colorSlate50,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: TextField(
                        controller: controller,
                        textAlign: TextAlign.right,
                        style:
                            (isMono
                                    ? GoogleFonts.robotoMono()
                                    : GoogleFonts.outfit())
                                .copyWith(
                                  color: colorSlate800,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                        decoration: const InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  )
                else
                  Flexible(
                    child: Text(
                      value,
                      textAlign: TextAlign.right,
                      style:
                          (isMono
                                  ? GoogleFonts.robotoMono()
                                  : GoogleFonts.outfit())
                              .copyWith(
                                color: colorSlate800,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
