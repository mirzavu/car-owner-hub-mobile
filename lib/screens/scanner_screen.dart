import 'dart:async';
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'package:permission_handler/permission_handler.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

enum ScanPhase { align, scanning, complete, error }

class ScannerScreen extends StatefulWidget {
  final Function(String, Map<String, dynamic>?) setStep;
  final Future<void> Function()? onSkip;

  const ScannerScreen({super.key, required this.setStep, this.onSkip});

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen>
    with TickerProviderStateMixin {
  ScanPhase _scanPhase = ScanPhase.align;
  String _statusText = 'Position document within frame';
  XFile? _capturedFile;
  Map<String, dynamic>? _scanResult;

  // Camera Controllers
  CameraController? _cameraController;
  Future<void>? _initializeControllerFuture;
  bool _isCameraPermissionGranted = false;

  // Animation Controllers
  late AnimationController _laserController;
  late AnimationController _pulseController;
  late Animation<double> _laserAnimation;

  static const colorBrightBlue = Color(0xFF007BFF);

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
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }

    try {
      debugPrint("[SCAN] Taking picture...");
      final image = await _cameraController!.takePicture();
      setState(() {
        _capturedFile = image;
        _scanPhase = ScanPhase.scanning;
      });

      _laserController.repeat();
      _runScanSequence(image.path);
    } catch (e) {
      debugPrint("Error capturing image: $e");
      setState(() {
        _statusText = "Capture failed. Try again.";
        _scanPhase = ScanPhase.align;
      });
    }
  }

  Future<void> _runScanSequence(String filePath) async {
    try {
      setState(() => _statusText = "Enhancing image...");
      await Future.delayed(const Duration(milliseconds: 1000));

      if (!mounted) return;
      setState(() => _statusText = "Fetching details...");

      debugPrint("[SCAN] Starting OCR scan for file: $filePath");
      // Call real OCR API
      final result = await ApiService.scanDocument(
        filePath,
        userId: AuthService().userId,
      );

      if (!mounted) return;

      if (result.containsKey('error')) {
        setState(() {
          _statusText = "Low quality scan. Please try again.";
          _scanPhase = ScanPhase.error;
          _laserController.stop();
        });
        return;
      }

      debugPrint("[SCAN] OCR Success. Result: $result");
      setState(() {
        _scanResult = result;
        _statusText = "Scan Complete!";
        _laserController.stop();
      });

      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      setState(() => _scanPhase = ScanPhase.complete);

      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      widget.setStep('verify', _scanResult);
    } catch (e) {
      debugPrint("OCR error: $e");
      if (!mounted) return;
      setState(() {
        _statusText = "Scan failed. Please try again or enter manually.";
        _scanPhase = ScanPhase.error;
        _laserController.stop();
      });
    }
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
          // --- 1. REAL CAMERA FEED OR CAPTURED IMAGE ---
          if (_capturedFile != null)
            Image.file(
              File(_capturedFile!.path),
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            )
          else if (_isCameraPermissionGranted && _cameraController != null)
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
                    width: MediaQuery.of(context).size.width * 0.92,
                    height: MediaQuery.of(context).size.height * 0.75,
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
                  // Top Bar (Close and Skip Buttons)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      InkWell(
                        onTap: () => widget.setStep('scan-intro', null),
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

                      // Skip Button
                      InkWell(
                        onTap: () async {
                          if (widget.onSkip != null) {
                            await widget.onSkip!();
                          } else {
                            widget.setStep('main-app', null);
                          }
                        },
                        borderRadius: BorderRadius.circular(50),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            borderRadius: BorderRadius.circular(50),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(50),
                            child: BackdropFilter(
                              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                              child: Text(
                                "Skip",
                                style: GoogleFonts.outfit(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
                                        color: colorBrightBlue,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                ],
                                Text(
                                  _statusText,
                                  style: GoogleFonts.outfit(
                                    color: _scanPhase == ScanPhase.error
                                        ? Colors.redAccent
                                        : Colors.white,
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
                        child:
                            (_scanPhase == ScanPhase.align ||
                                _scanPhase == ScanPhase.error)
                            ? GestureDetector(
                                onTap: () {
                                  if (_scanPhase == ScanPhase.error) {
                                    setState(() {
                                      _scanPhase = ScanPhase.align;
                                      _capturedFile = null;
                                      _statusText =
                                          'Position document within frame';
                                    });
                                  } else {
                                    _handleCapture();
                                  }
                                },
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color:
                                              (_scanPhase == ScanPhase.error
                                                      ? Colors.redAccent
                                                      : Colors.white)
                                                  .withValues(alpha: 0.3),
                                          width: 5,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      width: 64,
                                      height: 64,
                                      decoration: BoxDecoration(
                                        color: _scanPhase == ScanPhase.error
                                            ? Colors.redAccent
                                            : Colors.white,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color:
                                                (_scanPhase == ScanPhase.error
                                                        ? Colors.redAccent
                                                        : Colors.white)
                                                    .withValues(alpha: 0.3),
                                            blurRadius: 20,
                                            spreadRadius: 0,
                                          ),
                                        ],
                                      ),
                                      child: _scanPhase == ScanPhase.error
                                          ? const Icon(
                                              LucideIcons.refreshCw,
                                              color: Colors.white,
                                            )
                                          : null,
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
              width: MediaQuery.of(context).size.width * 0.92,
              height: MediaQuery.of(context).size.height * 0.75,
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
                              0.75 *
                              _laserAnimation.value,
                          left: -10,
                          right: -10,
                          child: child!,
                        );
                      },
                      child: Container(
                        height: 2,
                        decoration: const BoxDecoration(
                          color: colorBrightBlue,
                          boxShadow: [
                            BoxShadow(
                              color: colorBrightBlue,
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
