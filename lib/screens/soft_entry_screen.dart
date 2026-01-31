import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/car_icon.dart';
import '../services/api_service.dart'; // Import API Service

class SoftEntryScreen extends StatefulWidget {
  final ValueChanged<String> onNext;
  final VoidCallback? onBack;
  final Function(double value, Map<String, String> details)? onEstimateComplete;

  const SoftEntryScreen({
    super.key,
    required this.onNext,
    this.onBack,
    this.onEstimateComplete,
  });

  @override
  State<SoftEntryScreen> createState() => _SoftEntryScreenState();
}

class _SoftEntryScreenState extends State<SoftEntryScreen> {
  bool loading = false;
  String loadingText = '';

  // --- SELECTION STATE ---
  String? selectedYear;
  String? selectedMake;
  String? selectedModel;
  String? selectedTrim;

  // --- DATA LISTS (From API) ---
  List<String> years = [];
  List<String> makes = [];
  List<String> models = [];

  // --- LOADING STATES FOR DROPDOWNS ---
  bool isLoadingYears = true;
  bool isLoadingMakes = false;
  bool isLoadingModels = false;

  @override
  void initState() {
    super.initState();
    _loadYears();
  }

  // --- API CALLS ---
  Future<void> _loadYears() async {
    final data = await ApiService.getVehicleOptions(type: 'years');
    if (mounted)
      setState(() {
        years = data;
        isLoadingYears = false;
      });
  }

  Future<void> _loadMakes(String year) async {
    setState(() {
      isLoadingMakes = true;
      makes = [];
      selectedMake = null;
      models = [];
      selectedModel = null;
      selectedTrim = null;
    });

    final data = await ApiService.getVehicleOptions(type: 'makes', year: year);
    if (mounted)
      setState(() {
        makes = data;
        isLoadingMakes = false;
      });
  }

  Future<void> _loadModels(String make) async {
    setState(() {
      isLoadingModels = true;
      models = [];
      selectedModel = null;
      selectedTrim = null; // Reset trim on model change
    });

    final data = await ApiService.getVehicleOptions(
      type: 'models',
      make: make,
      year: selectedYear,
    );
    if (mounted)
      setState(() {
        models = data;
        isLoadingModels = false;
      });
  }

  // --- HANDLERS ---
  void handleNext() {
    // Basic Validation
    if (selectedYear == null || selectedMake == null || selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your vehicle details")),
      );
      return;
    }

    setState(() {
      loading = true;
      loadingText = 'Connecting to Canadian Black Book...';
    });

    // Real API Call
    ApiService.getEstimate(
          year: int.parse(selectedYear!),
          make: selectedMake!,
          model: selectedModel!,
          trim: selectedTrim,
        )
        .then((data) {
          if (!mounted) return;

          setState(() => loadingText = 'Analyzing local market trends...');

          // Artificial delay for UX (optional, kept for consistency)
          Future.delayed(const Duration(milliseconds: 1000), () {
            if (!mounted) return;
            setState(() => loading = false);

            final double val = (data['value'] as num).toDouble();

            // Pass data back
            if (widget.onEstimateComplete != null) {
              widget.onEstimateComplete!(val, {
                'year': selectedYear!,
                'make': selectedMake!,
                'model': selectedModel!,
                'trim': selectedTrim ?? '',
              });
            }

            widget.onNext('teaser');
          });
        })
        .catchError((e) {
          if (!mounted) return;
          setState(() {
            loading = false;
          });
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text("Error getting estimate: $e")));
        });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return _buildLoadingScreen();
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final headerHeight = constraints.maxHeight * 0.45;
          const minHeaderHeight = 360.0;
          final actualHeaderHeight = headerHeight > minHeaderHeight
              ? headerHeight
              : minHeaderHeight;
          const overlapHeight = 24.0;

          return Stack(
            children: [
              // --- HEADER SECTION ---
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: actualHeaderHeight,
                child: _buildHeader(),
              ),

              // --- GRID SYSTEM BODY ---
              Positioned(
                top: actualHeaderHeight - overlapHeight,
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(24),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.03),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ROW 1: YEAR
                        _buildTile(
                          label: "YEAR",
                          value: selectedYear,
                          items: years,
                          isLoading: isLoadingYears,
                          onChanged: (v) {
                            setState(() => selectedYear = v);
                            if (v != null) _loadMakes(v);
                          },
                        ),
                        const SizedBox(height: 20),

                        // ROW 2: MAKE
                        _buildTile(
                          label: "MAKE",
                          value: selectedMake,
                          items: makes,
                          isLoading: isLoadingMakes,
                          onChanged: (v) {
                            setState(() => selectedMake = v);
                            if (v != null) _loadModels(v);
                          },
                        ),
                        const SizedBox(height: 20),

                        // ROW 3: MODEL & TRIM
                        Row(
                          children: [
                            Expanded(
                              child: _buildTile(
                                label: "MODEL",
                                value: selectedModel,
                                items: models,
                                fontSize: 20,
                                isLoading: isLoadingModels,
                                chevronRight: 16,
                                onChanged: (v) {
                                  setState(() => selectedModel = v);
                                },
                              ),
                            ),
                            const SizedBox(width: 20),
                            Expanded(
                              child: _buildTextTile(
                                label: "TRIM (OPTIONAL)",
                                value: selectedTrim,
                                onChanged: (v) =>
                                    setState(() => selectedTrim = v),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        // ACTION BUTTON
                        _buildSubmitButton(),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // --- WIDGET HELPERS ---

  Widget _buildTextTile({
    required String label,
    required String? value,
    required ValueChanged<String> onChanged,
  }) {
    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: 20,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: const EdgeInsets.only(left: 20, right: 20, bottom: 8),
              child: Center(
                child: TextField(
                  controller: TextEditingController(text: value)
                    ..selection = TextSelection.fromPosition(
                      TextPosition(offset: value?.length ?? 0),
                    ),
                  onChanged: onChanged,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E293B),
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                  decoration: InputDecoration(
                    hintText: "SE / SEL",
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.grey.shade300,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.only(top: 24),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 64,
              height: 64,
              child: CircularProgressIndicator(
                strokeWidth: 4,
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF003366),
                ),
                backgroundColor: const Color(0xFFE6F0FA),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              loadingText,
              textAlign: TextAlign.center,
              style: GoogleFonts.outfit(
                color: const Color(0xFF1E293B),
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF003366), Color(0xFF002244)],
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: OverlayBlobPainter())),
        SafeArea(
          bottom: false,
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  margin: const EdgeInsets.only(bottom: 24),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(32),
                    color: Colors.white.withOpacity(0.05),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(32),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: const Center(
                        child: CarIcon(size: 40, color: Colors.white),
                      ),
                    ),
                  ),
                ),
                Text(
                  "Value your vehicle",
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  "instantly.",
                  style: GoogleFonts.outfit(
                    color: const Color(0xFFE6F0FA).withOpacity(0.9),
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    "NO VIN REQUIRED",
                    style: GoogleFonts.outfit(
                      color: const Color(0xFFE6F0FA),
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 80,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: handleNext,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF00CA50),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Get Estimate",
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.chevronRight,
                color: Colors.white,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTile({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    bool isLoading = false,
    double fontSize = 24,
    double chevronRight = 24,
  }) {
    return SizedBox(
      height: 80,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFFF1F5F9)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 2,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
          ),
          Positioned(
            top: 12,
            left: chevronRight == 24 ? 24 : 20,
            child: Text(
              label,
              style: GoogleFonts.outfit(
                color: const Color(0xFF94A3B8),
                fontSize: 10,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
            ),
          ),
          Positioned.fill(
            child: Padding(
              padding: EdgeInsets.only(
                left: chevronRight == 24 ? 24 : 20,
                right: chevronRight + 12,
                top: 20,
              ),
              child: isLoading
                  ? const Align(
                      alignment: Alignment.centerLeft,
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: value,
                        hint: Text(
                          "Select",
                          style: GoogleFonts.outfit(
                            color: Colors.grey.shade300,
                            fontSize: fontSize,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        icon: const SizedBox.shrink(),
                        style: GoogleFonts.outfit(
                          color: const Color(0xFF1E293B),
                          fontSize: fontSize,
                          fontWeight: FontWeight.w900,
                        ),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        items: items.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Text(item),
                          );
                        }).toList(),
                        onChanged: onChanged,
                        isExpanded: true,
                        menuMaxHeight: 300,
                      ),
                    ),
            ),
          ),
          Positioned(
            right: chevronRight == 24 ? 24 : 16,
            top: 0,
            bottom: 0,
            child: IgnorePointer(
              child: Transform.rotate(
                angle: 1.5708,
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 22,
                  color: const Color(0xFFCBD5E1),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class OverlayBlobPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.1)
      ..blendMode = BlendMode.overlay
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 80);
    final centerX = size.width / 2;
    final centerY = -size.height * 0.25;
    const radius = 200.0;
    canvas.drawCircle(Offset(centerX, centerY), radius, paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}
