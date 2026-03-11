import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../components/car_icon.dart';
import '../components/custom_slider_components.dart';
import '../services/api_service.dart'; // Import API Service

class VehicleInfoScreen extends StatefulWidget {
  final ValueChanged<String> onNext;
  final VoidCallback? onBack;
  final Function(double value, Map<String, String> details)? onEstimateComplete;

  const VehicleInfoScreen({
    super.key,
    required this.onNext,
    this.onBack,
    this.onEstimateComplete,
  });

  @override
  State<VehicleInfoScreen> createState() => _VehicleInfoScreenState();
}

class _VehicleInfoScreenState extends State<VehicleInfoScreen> {
  bool loading = false;
  String loadingText = '';

  // --- SELECTION STATE ---
  double selectedYear = 2020; // Default value for slider
  String? selectedMake;
  String? selectedModel;
  double selectedMileage = 80000; // Default value for slider

  // --- DATA LISTS (From API) ---
  List<String> makes = [];
  List<String> models = [];

  // --- LOADING STATES FOR DROPDOWNS ---
  bool isLoadingMakes = true;
  bool isLoadingModels = false;

  @override
  void initState() {
    super.initState();
    _loadMakes();
  }

  // --- API CALLS ---
  Future<void> _loadMakes() async {
    setState(() {
      isLoadingMakes = true;
      makes = [];
      selectedMake = null;
      models = [];
      selectedModel = null;
    });

    try {
      final data = await ApiService.getVehicleOptions(
        type: 'makes',
      );
      debugPrint("[VEHICLE-INFO] API returned makes: $data");
      if (mounted) {
        setState(() {
          makes = data;
          isLoadingMakes = false;
        });
      }
    } catch (e) {
      debugPrint("[VEHICLE-INFO] Error loading makes: $e");
      if (mounted) {
        setState(() {
          isLoadingMakes = false;
        });
      }
    }
  }

  Future<void> _loadModels(String make) async {
    setState(() {
      isLoadingModels = true;
      models = [];
      selectedModel = null;
    });

    try {
      final data = await ApiService.getVehicleOptions(
        type: 'models',
        make: make,
      );
      debugPrint("[VEHICLE-INFO] API returned models for $make: $data");
      if (mounted) {
        setState(() {
          models = data;
          isLoadingModels = false;
        });
      }
    } catch (e) {
      debugPrint("[VEHICLE-INFO] Error loading models for $make: $e");
      if (mounted) {
        setState(() {
          isLoadingModels = false;
        });
      }
    }
  }

  // --- HANDLERS ---
  void handleNext() {
    // Basic Validation
    if (selectedMake == null || selectedModel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please select your Make and Model")),
      );
      return;
    }

    debugPrint(
      "[VEHICLE-INFO] Getting estimate for: ${selectedYear.toInt()} $selectedMake $selectedModel (Mileage: ${selectedMileage.toInt()})",
    );

    setState(() {
      loading = true;
      loadingText = 'Estimating market value...';
    });

    // Real API Call
    ApiService.getEstimate(
          year: selectedYear.toInt(),
          make: selectedMake!,
          model: selectedModel!,
          mileage: selectedMileage.toInt(),
        )
        .then((data) {
          if (!mounted) return;

          setState(() => loading = false);

          final double val = (data['value'] as num).toDouble();

          // Pass data back
          if (widget.onEstimateComplete != null) {
            widget.onEstimateComplete!(val, {
              'year': selectedYear.toInt().toString(),
              'make': selectedMake!,
              'model': selectedModel!,
              'mileage': selectedMileage.toInt().toString(),
            });
          }

          widget.onNext('teaser');
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

  // --- FORMATTERS ---
  String _formatMileage(double value) {
    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
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
                        color: Colors.black.withValues(alpha: 0.03),
                        blurRadius: 4,
                        offset: const Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        // ROW 1: MAKE & MODEL
                        Row(
                          children: [
                            Expanded(
                              child: _buildTile(
                                label: "MAKE",
                                value: selectedMake,
                                items: makes,
                                fontSize: 16,
                                chevronRight: 12,
                                isLoading: isLoadingMakes,
                                onChanged: (v) {
                                  setState(() => selectedMake = v);
                                  if (v != null) _loadModels(v);
                                },
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildTile(
                                label: "MODEL",
                                value: selectedModel,
                                items: models,
                                fontSize: 16,
                                chevronRight: 12,
                                isLoading: isLoadingModels,
                                onChanged: (v) {
                                  setState(() => selectedModel = v);
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // ROW 2: YEAR SLIDER
                        _buildSliderTile(
                          label: "YEAR",
                          value: selectedYear,
                          min: 2000,
                          max: 2026,
                          divisions: 26,
                          displayValue: selectedYear.toInt().toString(),
                          onChanged: (v) => setState(() => selectedYear = v),
                        ),
                        const SizedBox(height: 12),

                        // ROW 3: MILEAGE SLIDER
                        _buildSliderTile(
                          label: "MILEAGE (KM)",
                          value: selectedMileage,
                          min: 0,
                          max: 300000,
                          divisions: 300,
                          displayValue: _formatMileage(selectedMileage),
                          onChanged: (v) => setState(() => selectedMileage = v),
                        ),

                        const SizedBox(height: 24),

                        // ACTION BUTTON
                        _buildSubmitButton(),

                        const SizedBox(height: 20),
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

  Widget _buildSliderTile({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String displayValue,
    required ValueChanged<double> onChanged,
    ValueChanged<double>? onChangeEnd,
  }) {
    const colorGreen = Color(0xFF00CA50);
    return Container(
      height: 96,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF94A3B8),
                    fontSize: 10,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.0,
                  ),
                ),
                Text(
                  displayValue,
                  style: GoogleFonts.outfit(
                    color: const Color(0xFF1E293B),
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 2),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                trackHeight: 12,
                activeTrackColor: colorGreen,
                inactiveTrackColor: const Color(0xFFF1F5F9),
                overlayColor: Colors.transparent,
                trackShape: const CustomSliderTrackShape(),
                thumbShape: const CustomSliderThumbShape(
                  thumbRadius: 16,
                  borderWidth: 4,
                  borderColor: colorGreen,
                ),
                tickMarkShape: SliderTickMarkShape.noTickMark,
              ),
              child: Slider(
                value: value,
                min: min,
                max: max,
                divisions: divisions,
                onChanged: onChanged,
                onChangeEnd: onChangeEnd,
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
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
            const SizedBox(height: 24),
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
            child: SingleChildScrollView(
              physics: const NeverScrollableScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(32),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
                        child: const Center(
                          child: CarIcon(size: 40, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                  FittedBox(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        children: [
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
                              color: const Color(
                                0xFFE6F0FA,
                              ).withValues(alpha: 0.9),
                              fontSize: 32,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      "INSTANT ESTIMATE",
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
        ),
      ],
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      height: 72,
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
                color: Colors.white.withValues(alpha: 0.1),
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
    return Container(
      height: 72,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFF1F5F9)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: 8,
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
              padding: const EdgeInsets.only(top: 14),
              child: isLoading
                  ? Align(
                      alignment: Alignment.centerLeft,
                      child: Padding(
                        padding: EdgeInsets.only(left: chevronRight == 24 ? 24 : 20),
                        child: const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                    )
                  : DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: value,
                        isExpanded: true,
                        icon: const SizedBox.shrink(),
                        dropdownColor: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        hint: Padding(
                          padding: EdgeInsets.only(left: chevronRight == 24 ? 24 : 20, right: chevronRight + 12),
                          child: Text(
                            "Select",
                            style: GoogleFonts.outfit(
                              color: Colors.grey.shade400,
                              fontSize: fontSize,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                        selectedItemBuilder: (BuildContext context) {
                          return items.map<Widget>((String item) {
                            return Padding(
                              padding: EdgeInsets.only(left: chevronRight == 24 ? 24 : 20, right: chevronRight + 12),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  item,
                                  style: GoogleFonts.outfit(
                                    color: const Color(0xFF1E293B),
                                    fontSize: fontSize,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                            );
                          }).toList();
                        },
                        items: items.map((String item) {
                          return DropdownMenuItem<String>(
                            value: item,
                            child: Padding(
                              padding: EdgeInsets.only(left: chevronRight == 24 ? 8 : 4),
                              child: Text(
                                item,
                                style: GoogleFonts.outfit(
                                  color: const Color(0xFF1E293B),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: onChanged,
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
                child: const Icon(
                  LucideIcons.chevronRight,
                  size: 22,
                  color: Color(0xFFCBD5E1),
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
      ..color = Colors.white.withValues(alpha: 0.1)
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
