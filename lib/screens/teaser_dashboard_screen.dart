import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons/lucide_icons.dart';
import 'buyer_dashboard_components/buyer_dashboard_constants.dart';

class TeaserDashboardScreen extends StatefulWidget {
  final Map<String, String> carDetails;
  final double estimatedValue;
  final VoidCallback onScanClick;
  final VoidCallback onLogout;
  final bool isGuest;

  const TeaserDashboardScreen({
    super.key,
    required this.carDetails,
    required this.estimatedValue,
    required this.onScanClick,
    required this.onLogout,
    this.isGuest = false,
  });

  @override
  State<TeaserDashboardScreen> createState() => _TeaserDashboardScreenState();
}

class _TeaserDashboardScreenState extends State<TeaserDashboardScreen>
    with SingleTickerProviderStateMixin {
  final GlobalKey _scanButtonKey = GlobalKey();
  late AnimationController _highlightController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _highlightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(
          begin: 1.0,
          end: 1.02,
        ).chain(CurveTween(curve: Curves.easeOutCubic)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween(
          begin: 1.02,
          end: 1.0,
        ).chain(CurveTween(curve: Curves.easeInCubic)),
        weight: 50,
      ),
    ]).animate(_highlightController);
  }

  @override
  void dispose() {
    _highlightController.dispose();
    super.dispose();
  }

  final List<Map<String, dynamic>> _mockInventory = [
    {
      'id': '1',
      'year': 2024,
      'make': 'Toyota',
      'model': '4Runner',
      'trim': 'TRD Pro',
      'price': 54400,
      'image':
          'https://images.unsplash.com/photo-1590362891991-f776e747a588?auto=format&fit=crop&q=80&w=600&h=800',
    },
    {
      'id': '2',
      'year': 2023,
      'make': 'Ford',
      'model': 'Bronco',
      'trim': 'Outer Banks',
      'price': 48200,
      'image':
          'https://images.unsplash.com/photo-1511919884226-fd3cad34687c?auto=format&fit=crop&q=80&w=600&h=800',
    },
    {
      'id': '3',
      'year': 2024,
      'make': 'Jeep',
      'model': 'Wrangler',
      'trim': 'Rubicon',
      'price': 51500,
      'image':
          'https://images.unsplash.com/photo-1533106418989-88406c7cc8ca?auto=format&fit=crop&q=80&w=600&h=800',
    },
    {
      'id': '4',
      'year': 2023,
      'make': 'GMC',
      'model': 'Canyon',
      'trim': 'AT4',
      'price': 45800,
      'image':
          'https://images.unsplash.com/photo-1566274360936-cebcfa2fa8e4?auto=format&fit=crop&q=80&w=600&h=800',
    },
  ];

  bool _isScanning = false;

  void _handleScanClick() async {
    setState(() => _isScanning = true);
    widget.onScanClick();
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() => _isScanning = false);
    }
  }

  String _formatCurrency(num value) {
    return NumberFormat.currency(
      locale: 'en_CA',
      symbol: '\$',
      decimalDigits: 0,
    ).format(value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: cLightBg,
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              children: [
                Container(
                  width: double.infinity,
                  padding: EdgeInsets.fromLTRB(
                    24,
                    MediaQuery.of(context).padding.top + 24,
                    24,
                    110,
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
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Portfolio',
                                style: GoogleFonts.outfit(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                  height: 1.0,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'ASSET MANAGEMENT',
                                style: GoogleFonts.outfit(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.grey[400],
                                  letterSpacing: 1.5,
                                ),
                              ),
                            ],
                          ),
                          GestureDetector(
                            onTap: widget.onLogout,
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.05),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.1),
                                ),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: Icon(
                                widget.isGuest
                                    ? LucideIcons.user
                                    : LucideIcons.logOut,
                                size: 16,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      _buildAssetCard(),
                      const SizedBox(height: 24),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text.rich(
                          TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.grey[400],
                              height: 1.5,
                            ),
                            children: [
                              const TextSpan(
                                text: 'You hold a valuable asset. ',
                              ),
                              TextSpan(
                                text: 'Scan your loan statement',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              const TextSpan(
                                text: ' to unlock its full equity potential.',
                              ),
                            ],
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
                Transform.translate(
                  offset: const Offset(0, -48),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Column(
                          children: [
                            _buildLockedFeatureCard(
                              title: 'Access Equity Cash',
                              description:
                                  'Discover exactly how much cash you can extract from your ${widget.carDetails['make']}.',
                              iconType: 'car',
                              onTap: _scrollToAndHighlightCTA,
                            ),
                            const SizedBox(height: 16),
                            _buildLockedFeatureCard(
                              title: 'Trade-Up Options',
                              description:
                                  'Calculate precise trade-in power to shop new verified inventory.',
                              iconType: 'car',
                              onTap: _scrollToAndHighlightCTA,
                            ),
                            const SizedBox(height: 28),
                            _buildScanButton(),
                          ],
                        ),
                      ),
                      const SizedBox(height: 40),
                      _buildInventoryTeaser(),
                      const SizedBox(height: 40),
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

  Widget _buildAssetCard() {
    return Container(
      height: 210,
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(32),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0x991E3A8A), Color(0xFF112240), Color(0xFF060D1A)],
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.5),
            blurRadius: 50,
            offset: const Offset(0, 20),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 120,
            child: CustomPaint(painter: _SparklinePainter()),
          ),
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.shieldCheck,
                          size: 14,
                          color: cNeon,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'VERIFIED ASSET',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey[400],
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${widget.carDetails['year'] ?? ''} ${widget.carDetails['make'] ?? ''} ${widget.carDetails['model'] ?? ''}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white.withValues(alpha: 0.9),
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          LucideIcons.trendingUp,
                          size: 14,
                          color: cNeon,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'MARKET ESTIMATE',
                          style: GoogleFonts.outfit(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: cNeon,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          _formatCurrency(widget.estimatedValue),
                          style: GoogleFonts.outfit(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            letterSpacing: -1.0,
                            height: 1.0,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'CAD',
                          style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: Colors.grey[500],
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _scrollToAndHighlightCTA() {
    if (_scanButtonKey.currentContext != null) {
      Scrollable.ensureVisible(
        _scanButtonKey.currentContext!,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOut,
        alignment: 0.5,
      ).then((_) {
        _highlightController.forward(from: 0);
      });
    }
  }

  Widget _buildLockedFeatureCard({
    required String title,
    required String description,
    required String iconType,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.grey[200]!.withValues(alpha: 0.8)),
          boxShadow: [
            BoxShadow(
              color: cDarkBg.withValues(alpha: 0.08),
              blurRadius: 35,
              offset: const Offset(0, 15),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: cDarkBg,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      description,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Colors.grey[500],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Color(0xFFF8FAFC), Color(0xFFF1F5F9)],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey[200]!.withValues(alpha: 0.8),
                ),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Stack(
                  fit: StackFit.expand,
                  alignment: Alignment.center,
                  children: [
                    Center(
                      child: Opacity(
                        opacity: 0.3,
                        child: ImageFiltered(
                          imageFilter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                          child: iconType == 'cash'
                              ? Text(
                                  '\$\$\$',
                                  style: GoogleFonts.outfit(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: cNeon,
                                  ),
                                )
                              : const Icon(
                                  LucideIcons.car,
                                  size: 40,
                                  color: cDarkBg,
                                ),
                        ),
                      ),
                    ),
                    BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                      child: Container(
                        color: Colors.white.withValues(alpha: 0.3),
                        alignment: Alignment.center,
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.grey[100]!),
                            boxShadow: const [
                              BoxShadow(
                                color: Colors.black12,
                                blurRadius: 6,
                                offset: Offset(0, 2),
                              ),
                            ],
                          ),
                          child: const Icon(
                            LucideIcons.lock,
                            size: 16,
                            color: Color(0xFF1E293B),
                          ),
                        ),
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

  Widget _buildScanButton() {
    return Column(
      key: _scanButtonKey,
      children: [
        ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedBuilder(
            animation: _highlightController,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                ),
                child: child,
              );
            },
            child: ElevatedButton(
              onPressed: _isScanning ? null : _handleScanClick,
              style: ElevatedButton.styleFrom(
                backgroundColor: cNeon,
                foregroundColor: cDarkBg,
                disabledBackgroundColor: cNeon.withValues(alpha: 0.8),
                padding: const EdgeInsets.symmetric(vertical: 20),
                elevation: 8,
                shadowColor: cNeon.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: _isScanning
                    ? [
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cDarkBg,
                          ),
                        ),
                      ]
                    : [
                        Icon(
                          LucideIcons.fileText,
                          size: 20,
                          color: cDarkBg.withValues(alpha: 0.5),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'SCAN LOAN TO UNLOCK',
                          style: GoogleFonts.outfit(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(LucideIcons.arrowRight, size: 20),
                      ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'SECURE & ENCRYPTED • TAKES 30 SECONDS',
          style: GoogleFonts.outfit(
            fontSize: 11,
            fontWeight: FontWeight.w800,
            color: Colors.grey[400],
            letterSpacing: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildInventoryTeaser() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                'Recently Added Deals',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: cDarkBg,
                  letterSpacing: 0.5,
                ),
              ),
              InkWell(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'VIEW ALL',
                      style: GoogleFonts.outfit(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.grey[500],
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      LucideIcons.chevronRight,
                      size: 14,
                      color: Colors.grey[500],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 230,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _mockInventory.length,
            separatorBuilder: (context, index) => const SizedBox(width: 20),
            itemBuilder: (context, index) {
              final car = _mockInventory[index];
              return Container(
                width: 220,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  boxShadow: [
                    BoxShadow(
                      color: cDarkBg.withValues(alpha: 0.06),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 120,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(28),
                            ),
                            child: Image.network(
                              car['image'],
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [
                                    cDarkBg.withValues(alpha: 0.6),
                                    Colors.transparent,
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${car['year']} ${car['make']}',
                              style: GoogleFonts.outfit(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.grey[400],
                                letterSpacing: 1.5,
                              ),
                            ),
                            const SizedBox(height: 2),
                            RichText(
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              text: TextSpan(
                                style: GoogleFonts.outfit(
                                  fontSize: 15,
                                  color: cDarkBg,
                                  height: 1.2,
                                ),
                                children: [
                                  TextSpan(
                                    text: '${car['model']} ',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  TextSpan(
                                    text: car['trim'],
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                      color: Colors.grey[500],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Spacer(),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.only(top: 12),
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(color: Colors.grey[100]!),
                                ),
                              ),
                              child: Text(
                                _formatCurrency(car['price']),
                                style: GoogleFonts.outfit(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w900,
                                  color: cDarkBg,
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
            },
          ),
        ),
      ],
    );
  }
}

class _SparklinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final Path path = Path();
    final double w = size.width;
    final double h = size.height;

    path.moveTo(0, h * 0.8);
    path.quadraticBezierTo(w * 0.15, h * 0.7, w * 0.25, h * 0.5);
    path.quadraticBezierTo(w * 0.35, h * 0.3, w * 0.45, h * 0.3);
    path.quadraticBezierTo(w * 0.55, h * 0.3, w * 0.65, h * 0.4);
    path.quadraticBezierTo(w * 0.75, h * 0.5, w * 0.85, h * 0.1);
    path.quadraticBezierTo(w * 0.925, h * -0.1, w * 1.0, h * 0.2);

    final Path fillPath = Path.from(path);
    fillPath.lineTo(w, h);
    fillPath.lineTo(0, h);
    fillPath.close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF00E676).withValues(alpha: 0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(0, 0, w, h));

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF00E676).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawPath(path, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
