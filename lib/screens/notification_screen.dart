import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';

import '../services/api_service.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  static const int _pageSize = 20;

  final ScrollController _scrollController = ScrollController();

  List<NotificationFeedItem> _items = [];
  bool _isLoading = true;
  bool _isLoadingMore = false;
  bool _hasMore = true;
  bool _isMarkingRead = false;
  String? _nextCursor;
  String? _error;
  int _unreadCount = 0;

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
      _error = null;
      _items = [];
      _nextCursor = null;
      _hasMore = true;
    });

    await _fetchPage(reset: true);

    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _fetchPage({bool reset = false}) async {
    try {
      final page = await ApiService.getNotifications(
        status: 'all',
        limit: _pageSize,
        cursor: reset ? null : _nextCursor,
      );

      if (!mounted) return;
      setState(() {
        _items = reset ? page.items : [..._items, ...page.items];
        _nextCursor = page.nextCursor;
        _hasMore = page.hasMore;
        _unreadCount = page.unreadCount;
        _error = null;
      });

      final unreadIds = page.items
          .where((item) => !item.isRead)
          .map((item) => item.id)
          .toList();

      if (unreadIds.isNotEmpty) {
        await _markItemsAsRead(unreadIds);
      }
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

  Future<void> _markItemsAsRead(List<String> ids) async {
    if (ids.isEmpty || _isMarkingRead) return;

    setState(() {
      _isMarkingRead = true;
    });

    try {
      final unreadCount = await ApiService.markNotificationsRead(ids: ids);
      if (!mounted) return;

      final idSet = ids.toSet();
      setState(() {
        _items = _items
            .map(
              (item) => idSet.contains(item.id)
                  ? NotificationFeedItem(
                      id: item.id,
                      type: item.type,
                      title: item.title,
                      message: item.message,
                      isRead: true,
                      actionRoute: item.actionRoute,
                      created: item.created,
                    )
                  : item,
            )
            .toList();
        _unreadCount = unreadCount;
      });
    } catch (e) {
      debugPrint('Failed to mark notifications as read: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isMarkingRead = false;
        });
      }
    }
  }

  Future<void> _markAllRead() async {
    final unreadIds = _items
        .where((item) => !item.isRead)
        .map((item) => item.id)
        .toList();

    await _markItemsAsRead(unreadIds);
  }

  Future<void> _handleTap(NotificationFeedItem item) async {
    if (!item.isRead) {
      await _markItemsAsRead([item.id]);
    }

    if (!mounted) return;

    final route = item.actionRoute.trim();
    if (route.isNotEmpty) {
      Navigator.pop(context, route);
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

  _NotificationVisual _visualForType(String type) {
    switch (type) {
      case 'rate_alert':
        return _NotificationVisual(
          icon: LucideIcons.trendingDown,
          color: Colors.red.shade600,
          bg: Colors.red.shade50,
        );
      case 'equity_unlock':
        return _NotificationVisual(
          icon: LucideIcons.dollarSign,
          color: Colors.teal.shade600,
          bg: Colors.teal.shade50,
        );
      case 'inventory_match':
        return _NotificationVisual(
          icon: LucideIcons.car,
          color: Colors.blue.shade600,
          bg: Colors.blue.shade50,
        );
      case 'doc_status':
      default:
        return _NotificationVisual(
          icon: LucideIcons.fileText,
          color: const Color(0xFF2563EB),
          bg: const Color(0xFFDBEAFE),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    const colorSlate50 = Color(0xFFF8FAFC);
    const colorSlate800 = Color(0xFF1E293B);
    const colorSlate900 = Color(0xFF0F172A);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
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
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Notifications',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: colorSlate800,
                          ),
                        ),
                        Text(
                          _unreadCount > 0
                              ? '$_unreadCount unread'
                              : 'All caught up',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.blueGrey.shade400,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _unreadCount > 0 ? _markAllRead : null,
                    child: Text(
                      'Mark all read',
                      style: GoogleFonts.outfit(
                        color: const Color(0xFF003366),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Text(
                          'Failed to load notifications. Pull to retry.\n$_error',
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
                      child: ListView.separated(
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
                        separatorBuilder: (context, index) =>
                            const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          if (_items.isEmpty && !_isLoadingMore) {
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 60),
                              child: Text(
                                'No notifications yet.',
                                textAlign: TextAlign.center,
                                style: GoogleFonts.outfit(
                                  fontSize: 13,
                                  color: Colors.blueGrey.shade400,
                                ),
                              ),
                            );
                          }

                          if (index >= _items.length) {
                            return Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(context).primaryColor,
                                ),
                              ),
                            );
                          }

                          final item = _items[index];
                          final visual = _visualForType(item.type);

                          return GestureDetector(
                            onTap: () => _handleTap(item),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: !item.isRead
                                      ? const Color(
                                          0xFF003366,
                                        ).withValues(alpha: 0.1)
                                      : const Color(0xFFF1F5F9),
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.02),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: visual.bg,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                      child: Icon(
                                        visual.icon,
                                        color: visual.color,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Expanded(
                                              child: Text(
                                                item.title,
                                                style: GoogleFonts.outfit(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.bold,
                                                  color: colorSlate900,
                                                ),
                                              ),
                                            ),
                                            if (!item.isRead)
                                              Container(
                                                width: 8,
                                                height: 8,
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF003366),
                                                  shape: BoxShape.circle,
                                                ),
                                              ),
                                          ],
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          item.message,
                                          style: GoogleFonts.outfit(
                                            fontSize: 13,
                                            color: Colors.blueGrey.shade400,
                                            height: 1.4,
                                          ),
                                        ),
                                        const SizedBox(height: 8),
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
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NotificationVisual {
  final IconData icon;
  final Color color;
  final Color bg;

  const _NotificationVisual({
    required this.icon,
    required this.color,
    required this.bg,
  });
}
