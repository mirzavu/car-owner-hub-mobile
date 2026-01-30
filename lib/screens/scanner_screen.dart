import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';

enum ScanPhase { align, scanning, complete }

class ScannerScreen extends StatefulWidget {
  final Function(String) setStep;

  const ScannerScreen({super.key, required this.setStep});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  ScanPhase _scanPhase = ScanPhase.align;
  String _statusText = 'Position document within frame';

  // Camera Controllers
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  bool _isCameraPermissionGranted = false;

  // Animation Controllers
  late AnimationController _laserController;
  late AnimationController _pulseController;
  late Animation<double> _laserAnimation;

  static const colorRed500 = Color(0xFFEF4444);

  @override
  void initState() {
    super.initState();
    _initAnimations();
    _initCamera();
  }

  void _initAnimations() {
    _laserController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );
    _laserAnimation = CurvedAnimation(
      parent: _laserController,
      curve: Curves.easeInOut,
    );

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);
  }

  Future<void> _initCamera() async {
    // 1. Request Permission
    var status = await Permission.camera.request();
    if (status.isDenied) {
      // Handle permission denied (show dialog or fallback)
      return;
    }

    setState(() {
      _isCameraPermissionGranted = true;
    });

    // 2. Setup Camera
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) return;

      // Select back camera
      final firstCamera = cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      _cameraController = CameraController(
        firstCamera,
        ResolutionPreset.high, // Good quality for text scanning
        enableAudio: false,
        imageFormatGroup: ImageFormatGroup.jpeg,
      );

      _initializeControllerFuture = _cameraController!.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      debugPrint("Camera initialization error: $e");
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _laserController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleCapture() async {
    setState(() {
      _scanPhase = ScanPhase.scanning;
    });

    _laserController.repeat();
    _runScanSequence();
  }

  Future<void> _runScanSequence() async {
    setState(() => _statusText = "Enhancing image...");

    await Future.delayed(const Duration(milliseconds: 1200));
    if (!mounted) return;
    setState(() => _statusText = "Scanning document...");

    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _statusText = "Extracting details...");

    await Future.delayed(const Duration(milliseconds: 1000));
    if (!mounted) return;
    setState(() {
      _statusText = "Scan Complete!";
      _laserController.stop();
    });

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _scanPhase = ScanPhase.complete);

    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    widget.setStep('verify');
  }

  @override
  Widget build(BuildContext context) {
    // Helper to calculate camera aspect ratio cover
    var camera = _cameraController?.value;
    final size = MediaQuery.of(context).size;
    var scale = 1.0;

    if (camera != null && camera.isInitialized) {
      scale = 1 / (camera.aspectRatio * size.aspectRatio);
      // Ensure we always cover
      if (scale < 1) scale = 1 / scale;
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // --- 1. REAL CAMERA FEED ---
          if (_isCameraPermissionGranted && _cameraController != null)
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.done) {
                  // Center the camera preview and scale it to cover
                  return Transform.scale(
                    scale: scale,
                    alignment: Alignment.topCenter,
                    child: CameraPreview(_cameraController!),
                  );
                } else {
                  // Loading state (black screen)
                  return Container(color: Colors.black);
                }
              },
            )
          else
            // Fallback / Loading gradient
            Container(
              decoration: const BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.center,
                  radius: 1.0,
                  colors: [Color(0xFF1E293B), Color(0xFF020617)],
                ),
              ),
            ),

          // --- 2. DARK OVERLAY WITH CUTOUT ---
          ColorFiltered(
            colorFilter: const ColorFilter.mode(
              Colors.black54,
              BlendMode.srcOut,
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    color: Colors.transparent,
                    backgroundBlendMode: BlendMode.dstOut,
                  ),
                ),
                // The Cutout Box
                Center(
                  child: Container(
                    width: MediaQuery.of(context).size.width * 0.85,
                    height: MediaQuery.of(context).size.height * 0.65,
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // --- 3. UI OVERLAYS ---
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.only(
                left: 24,
                right: 24,
                top: 24,
                bottom: 48,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Top Bar (Close Button)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InkWell(
                      onTap: () => widget.setStep('scan-intro'),
                      borderRadius: BorderRadius.circular(50),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: const Icon(
                              LucideIcons.x,
                              color: Colors.white70,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Bottom Controls
                  Column(
                    children: [
                      // Status Pill
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _scanPhase == ScanPhase.align
                              ? Colors.black.withValues(alpha: 0.6)
                              : Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(50),
                          border: _scanPhase != ScanPhase.align
                              ? Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                )
                              : null,
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(50),
                          child: BackdropFilter(
                            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (_scanPhase == ScanPhase.scanning) ...[
                                  FadeTransition(
                                    opacity: _pulseController,
                                    child: Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: colorRed500,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  _statusText,
                                  style: GoogleFonts.outfit(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Capture Button
                      SizedBox(
                        height: 80,
                        child: _scanPhase == ScanPhase.align
                            ? GestureDetector(
                                onTap: _handleCapture,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.white.withValues(
                                            alpha: 0.3,
                                          ),
                                          width: 5,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white.withValues(
                                              alpha: 0.3,
                                            ),
                                            blurRadius: 20,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : const SizedBox.shrink(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // --- 4. CORNERS & LASER (Visuals Only) ---
          Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.85,
              height: MediaQuery.of(context).size.height * 0.65,
              child: Stack(
                children: [
                  // Top Left
                  const Positioned(
                    top: 0,
                    left: 0,
                    child: _Corner(isTop: true, isLeft: true),
                  ),
                  // Top Right
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: _Corner(isTop: true, isLeft: false),
                  ),
                  // Bottom Left
                  const Positioned(
                    bottom: 0,
                    left: 0,
                    child: _Corner(isTop: false, isLeft: true),
                  ),
                  // Bottom Right
                  const Positioned(
                    bottom: 0,
                    right: 0,
                    child: _Corner(isTop: false, isLeft: false),
                  ),

                  // LASER
                  if (_scanPhase == ScanPhase.scanning)
                    AnimatedBuilder(
                      animation: _laserAnimation,
                      builder: (context, child) {
                        return Positioned(
                          top:
                              MediaQuery.of(context).size.height *
                              0.65 *
                              _laserAnimation.value,
                          left: -10,
                          right: -10,
                          child: child!,
                        );
                      },
                      child: Container(
                        height: 2,
                        decoration: const BoxDecoration(
                          color: colorRed500,
                          boxShadow: [
                            BoxShadow(
                              color: colorRed500,
                              blurRadius: 20,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Simple widget for the corner brackets to reduce code repetition
class _Corner extends StatelessWidget {
  final bool isTop;
  final bool isLeft;

  const _Corner({required this.isTop, required this.isLeft});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        border: Border(
          top: isTop
              ? BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 4)
              : BorderSide.none,
          bottom: !isTop
              ? BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 4)
              : BorderSide.none,
          left: isLeft
              ? BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 4)
              : BorderSide.none,
          right: !isLeft
              ? BorderSide(color: Colors.white.withValues(alpha: 0.8), width: 4)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: isTop && isLeft ? const Radius.circular(12) : Radius.zero,
          topRight: isTop && !isLeft ? const Radius.circular(12) : Radius.zero,
          bottomLeft: !isTop && isLeft
              ? const Radius.circular(12)
              : Radius.zero,
          bottomRight: !isTop && !isLeft
              ? const Radius.circular(12)
              : Radius.zero,
        ),
      ),
    );
  }
}
