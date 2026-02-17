import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_service.dart';

class ActivityHistoryScreen extends StatefulWidget {
  const ActivityHistoryScreen({super.key});

  @override
  State<ActivityHistoryScreen> createState() => _ActivityHistoryScreenState();
}

class _ActivityHistoryScreenState extends State<ActivityHistoryScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();

  List<ActivityFeedItem> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  String? _nextCursor;
  String? _error;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _loadInitial();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    setState(() {
      _isLoading = true;
      _items = [];
      _nextCursor = null;
      _hasMore = true;
      _error = null;
    });

    await _fetchPage(reset: true);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchPage({bool reset = false}) async {
    try {
      final page = await ApiService.getActivityFeed(
        limit: _pageSize,
        cursor: reset ? null : _nextCursor,
      );

      if (!mounted) return;
      setState(() {
        _items = reset ? page.items : [..._items, ...page.items];
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoading || _isLoadingMore || !_hasMore) return;

    setState(() {
      _isLoadingMore = true;
    });

    await _fetchPage();

    if (!mounted) return;
    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _refresh() async {
    await _loadInitial();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 120) {
      _loadMore();
    }
  }

  _ActivityVisual _visualForItem(ActivityFeedItem item) {
    switch (item.iconType) {
      case 'file':
        return const _ActivityVisual(
          icon: LucideIcons.fileText,
          color: Color(0xFF2563EB),
          bg: Color(0xFFDBEAFE),
        );
      case 'check':
        return const _ActivityVisual(
          icon: LucideIcons.checkCircle2,
          color: Color(0xFF059669),
          bg: Color(0xFFD1FAE5),
        );
      case 'user':
        return const _ActivityVisual(
          icon: LucideIcons.user,
          color: Color(0xFF7C3AED),
          bg: Color(0xFFF5F3FF),
        );
      case 'clock':
      default:
        return const _ActivityVisual(
          icon: LucideIcons.clock3,
          color: Color(0xFF475569),
          bg: Color(0xFFF1F5F9),
        );
    }
  }

  String _relativeTime(String iso) {
    try {
      final created = DateTime.parse(iso).toLocal();
      final now = DateTime.now();
      final diff = now.difference(created);

      if (diff.inMinutes < 1) return 'Just now';
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      if (diff.inDays < 7) return '${diff.inDays}d ago';
      return '${created.month}/${created.day}/${created.year}';
    } catch (_) {
      return iso;
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorSlate50 = Color(0xFFF8FAFC);
    const colorSlate800 = Color(0xFF1E293B);
    const colorSlate900 = Color(0xFF0F172A);

    return Scaffold(
      backgroundColor: colorSlate50,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: const Icon(LucideIcons.chevronLeft, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Activity History',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: colorSlate800,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Failed to load activity. Pull to retry.\n$_error',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: Colors.blueGrey.shade400,
                          ),
                        ),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.builder(
                        controller: _scrollController,
                        physics: const AlwaysScrollableScrollPhysics(
                          parent: BouncingScrollPhysics(),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 8,
                        ),
                        itemCount: _items.isEmpty && !_isLoadingMore
                            ? 1
                            : _items.length + (_isLoadingMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (_items.isEmpty && !_isLoadingMore) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: Text(
                                'No activity yet.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.blueGrey.shade400,
                                ),
                              ),
                            );
                          }

                          if (index >= _items.length) {
                            return const Padding(
                              padding: EdgeInsets.symmetric(vertical: 20),
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            );
                          }

                          final item = _items[index];
                          final visual = _visualForItem(item);
                          final isLast = index == _items.length - 1;

                          return IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Column(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: visual.bg,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Center(
                                        child: Icon(
                                          visual.icon,
                                          color: visual.color,
                                          size: 18,
                                        ),
                                      ),
                                    ),
                                    if (!isLast)
                                      Expanded(
                                        child: Container(
                                          width: 2,
                                          color: const Color(0xFFE2E8F0),
                                          margin: const EdgeInsets.symmetric(
                                            vertical: 4,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(
                                      bottom: 24.0,
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item.title,
                                          style: GoogleFonts.outfit(
                                            fontSize: 15,
                                            fontWeight: FontWeight.bold,
                                            color: colorSlate900,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.description,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            color: Colors.blueGrey.shade400,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        Text(
                                          _relativeTime(item.created),
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                            color: Colors.blueGrey.shade300,
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
            ),
          ],
        ),
      ),
    );
  }
}

class _ActivityVisual {
  final IconData icon;
  final Color color;
  final Color bg;

  const _ActivityVisual({
    required this.icon,
    required this.color,
    required this.bg,
  });
}
