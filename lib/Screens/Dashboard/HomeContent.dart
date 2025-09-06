import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../Config/ApiConstant.dart'; // provides kAppPackage
import '../../Config/Theme/AppTheme.dart';
import '../../Utils/NetworkCheck.dart';

class HomeContent extends StatefulWidget {
  const HomeContent({super.key});

  @override
  State<HomeContent> createState() => _HomeContentState();
}

class _HomeContentState extends State<HomeContent> {
  // ---- API ----
  static const String _apiBase =
      'https://pavankumarhegde.com/RUST/api/api.php?resource=posts';

  bool _loading = true;
  String? _error;
  List<PostItem> _posts = [];

  @override
  void initState() {
    super.initState();
    _loadPosts();
  }

  // REPLACE the whole _loadPosts() with this version:
  Future<void> _loadPosts() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // ✅ Check connectivity first; show dialog if offline & skip network calls
    final online = await NetworkCheck.ensureConnected(context);
    if (!online) {
      if (!mounted) return;
      setState(() {
        _loading = false; // keep existing/cached UI without noisy lookup errors
        _error = null;
      });
      return;
    }

    try {
      final uri = Uri.parse(
        '$_apiBase&pkg=${Uri.encodeComponent(ApiConstant.kAppPackage)}',
      );
      final resp = await http.get(uri, headers: {
        'X-App-Package': ApiConstant.kAppPackage,
      });

      if (resp.statusCode != 200) {
        throw Exception('HTTP ${resp.statusCode}');
      }
      if (resp.body.isEmpty) {
        if (!mounted) return;
        setState(() {
          _posts = [];
        });
        return;
      }

      final decoded = jsonDecode(resp.body);

      // Signed envelope: payload.items (list)
      dynamic items;
      if (decoded is Map && decoded['payload'] is Map) {
        items = (decoded['payload'] as Map)['items'];
      } else {
        items = decoded;
      }

      final List<PostItem> parsed = [];
      if (items is List) {
        for (final it in items) {
          if (it is Map) {
            final p = PostItem.fromJson(it);
            if (p != null) parsed.add(p);
          }
        }
      } else if (items is Map) {
        final p = PostItem.fromJson(items);
        if (p != null) parsed.add(p);
      }

      // newest first
      parsed.sort((a, b) {
        final ta = a.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        final tb = b.timestamp ?? DateTime.fromMillisecondsSinceEpoch(0);
        return tb.compareTo(ta);
      });

      if (!mounted) return;
      setState(() {
        _posts = parsed;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Couldn’t load posts right now. Please try again.';
      });
    } finally {
      if (!mounted) return;
      setState(() {
        _loading = false;
      });
    }
  }


  void _openPostDetails(PostItem post, {int initialIndex = 0}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => PostDetailsScreen(
          post: post,
          initialIndex: initialIndex,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      );
    }

    if (_error != null) {
      return RefreshIndicator(
        color: AppTheme.primaryRed,
        onRefresh: _loadPosts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              'Failed to load posts:\n$_error',
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.error),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: _loadPosts,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_posts.isEmpty) {
      return RefreshIndicator(
        color: AppTheme.primaryRed,
        onRefresh: _loadPosts,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            const SizedBox(height: 80),
            Icon(Icons.collections_bookmark_outlined,
                size: 72, color: theme.disabledColor),
            const SizedBox(height: 12),
            Center(
              child: Text(
                'No posts yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                'Pull to refresh.',
                style:
                theme.textTheme.bodyMedium?.copyWith(color: theme.hintColor),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: AppTheme.primaryRed,
      onRefresh: _loadPosts,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final p = _posts[index];
          return _PostCard(
            post: p,
            onOpen: () => _openPostDetails(p, initialIndex: 0),
            onOpenImageAt: (i) => _openPostDetails(p, initialIndex: i),
          );
        },
      ),
    );
  }
}

// ---------------- Models & helpers ----------------

class PostItem {
  final int id;
  final List<String> images;
  final String title;
  final String description;
  final String? date; // 'YYYY-MM-DD' (string from API)
  final String? time; // 'HH:mm'     (string from API)

  PostItem({
    required this.id,
    required this.images,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
  });

  DateTime? get timestamp {
    if ((date ?? '').isEmpty) return null;
    final d = date!;
    final t = (time ?? '').isEmpty ? '00:00:00' : _normalizeHms(time!);
    try {
      return DateTime.parse('${d}T$t').toLocal();
    } catch (_) {
      try {
        return DateTime.parse(d).toLocal();
      } catch (_) {
        return null;
      }
    }
  }

  static PostItem? fromJson(Map json) {
    try {
      final id = json['id'] is int
          ? json['id'] as int
          : int.tryParse((json['id'] ?? '').toString()) ?? 0;

      final title = (json['title'] ?? '').toString().trim();
      final description = (json['description'] ?? '').toString().trim();

      final imgs = <String>[];
      final rawImgs = json['images'];
      if (rawImgs is List) {
        for (final v in rawImgs) {
          final s = v?.toString().trim() ?? '';
          if (s.isNotEmpty) imgs.add(s);
        }
      }

      final date = (json['date'] ?? '').toString().trim();
      final time = (json['time'] ?? '').toString().trim();

      return PostItem(
        id: id,
        images: imgs,
        title: title.isEmpty ? 'Untitled' : title,
        description: description,
        date: date.isEmpty ? null : date,
        time: time.isEmpty ? null : time,
      );
    } catch (_) {
      return null;
    }
  }

  static String _normalizeHms(String t) {
    final s = t.trim();
    if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(s)) return s;
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(s)) return '$s:00';
    try {
      final dt = DateFormat('H:mm').parse(s);
      return DateFormat('HH:mm:ss').format(dt);
    } catch (_) {
      return '00:00:00';
    }
  }
}

// ---------------- UI widgets ----------------

class _PostCard extends StatelessWidget {
  final PostItem post;
  final VoidCallback onOpen;
  final void Function(int index) onOpenImageAt;

  const _PostCard({
    required this.post,
    required this.onOpen,
    required this.onOpenImageAt,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ts = post.timestamp;
    String meta = '';
    if (ts != null) {
      meta = DateFormat('EEE, MMM d • h:mm a').format(ts);
    } else if ((post.date ?? '').isNotEmpty) {
      meta = post.date!;
      if ((post.time ?? '').isNotEmpty) {
        meta = '$meta • ${post.time}';
      }
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onOpen,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (post.images.isNotEmpty)
              _ImagesGrid(
                postId: post.id,
                images: post.images,
                onTapImageAt: onOpenImageAt,
              ),

            Padding(
              padding:
              const EdgeInsets.symmetric(horizontal: 14.0, vertical: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (meta.isNotEmpty) ...[
                    Row(
                      children: [
                        Icon(Icons.event,
                            size: 14,
                            color: isDark ? Colors.white54 : Colors.black54),
                        const SizedBox(width: 6),
                        Text(
                          meta,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: isDark ? Colors.white60 : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                  Text(
                    post.title,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (post.description.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      post.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.4,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ],
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: AppTheme.primaryRed,
                      ),
                      onPressed: onOpen,
                      icon: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
                      label: const Text('View'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Grid preview (up to 4 thumbs). If more than 4, the last cell shows +N overlay.
class _ImagesGrid extends StatelessWidget {
  final int postId;
  final List<String> images;
  final void Function(int index) onTapImageAt;

  const _ImagesGrid({
    required this.postId,
    required this.images,
    required this.onTapImageAt,
  });

  @override
  Widget build(BuildContext context) {
    final show = images.length <= 4 ? images.length : 4;

    return LayoutBuilder(
      builder: (_, constraints) {
        final isWide = constraints.maxWidth >= 520;
        final crossAxisCount = isWide ? 3 : 2;
        final rows = (show / crossAxisCount).ceil();
        // height to keep cells square
        final cellSpacing = 4.0;
        final totalSpacingY = cellSpacing * (rows - 1);
        final cellWidth =
            (constraints.maxWidth - cellSpacing * (crossAxisCount - 1)) /
                crossAxisCount;
        final gridHeight = rows * cellWidth + totalSpacingY;

        return Padding(
          padding: const EdgeInsets.all(10.0),
          child: SizedBox(
            height: gridHeight,
            child: GridView.builder(
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: cellSpacing,
                mainAxisSpacing: cellSpacing,
                childAspectRatio: 1,
              ),
              itemCount: show,
              itemBuilder: (_, i) {
                final isLastAndMore = i == show - 1 && images.length > show;
                return GestureDetector(
                  onTap: () => onTapImageAt(i),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      Hero(
                        tag: 'post_$postId#$i',
                        child: _NetworkImage(
                          url: images[i],
                          fit: BoxFit.cover,
                          borderRadius: 8,
                        ),
                      ),
                      if (isLastAndMore)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '+${images.length - show}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                            ),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Network image with progress/error + optional rounded corners.
class _NetworkImage extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final double borderRadius;

  const _NetworkImage({
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius = 0,
  });

  @override
  Widget build(BuildContext context) {
    final img = Image.network(
      url,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        color: Colors.black12,
        alignment: Alignment.center,
        child: const Icon(Icons.broken_image_outlined),
      ),
      loadingBuilder: (context, child, progress) {
        if (progress == null) return child;
        return Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(24),
          child: const CircularProgressIndicator(strokeWidth: 2),
        );
      },
    );

    if (borderRadius > 0) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: img,
      );
    }
    return img;
  }
}

// ========================= Post Details =========================

class PostDetailsScreen extends StatefulWidget {
  final PostItem post;
  final int initialIndex;

  const PostDetailsScreen({
    super.key,
    required this.post,
    this.initialIndex = 0,
  });

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  late final PageController _pc;

  @override
  void initState() {
    super.initState();
    _pc = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _openFullScreen(int startIndex) {
    final p = widget.post;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => FullscreenGallery(
          images: p.images,
          initialIndex: startIndex,
          heroPrefix: 'post_${p.id}#',
        ),
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final p = widget.post;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final ts = p.timestamp;
    String meta = '';
    if (ts != null) {
      meta = DateFormat('EEE, MMM d • h:mm a').format(ts);
    } else if ((p.date ?? '').isNotEmpty) {
      meta = p.date!;
      if ((p.time ?? '').isNotEmpty) {
        meta = '$meta • ${p.time}';
      }
    }


    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actionsIconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
          'Post Details',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: isDark ? Brightness.light : Brightness.dark,
          statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
        ),
      ),
      // body: ...
    body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          if (p.images.isNotEmpty) ...[
            SizedBox(
              height: 280,
              child: PageView.builder(
                controller: _pc,
                itemCount: p.images.length,
                // inside PageView.builder(...)
                itemBuilder: (_, i) {
                  return GestureDetector(
                    onTap: () => _openFullScreen(i),
                    child: Hero(
                      tag: 'post_${p.id}#$i',
                      child: _NetworkImage(url: p.images[i], fit: BoxFit.cover),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Center(
              child: _Dots(
                count: p.images.length,
                controller: _pc,
              ),
            ),
            const SizedBox(height: 16),
          ],

          if (meta.isNotEmpty) ...[
            Row(
              children: [
                Icon(Icons.event,
                    size: 16, color: isDark ? Colors.white60 : Colors.black54),
                const SizedBox(width: 6),
                Text(
                  meta,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],

          Text(
            p.title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          if (p.description.isNotEmpty)
            Text(
              p.description,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),
        ],
      ),
    );
  }
}

class _Dots extends StatefulWidget {
  final int count;
  final PageController controller;
  const _Dots({required this.count, required this.controller});

  @override
  State<_Dots> createState() => _DotsState();
}

class _DotsState extends State<_Dots> {
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.controller.initialPage.toDouble();
    widget.controller.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() => _page = widget.controller.page ?? widget.controller.initialPage.toDouble());
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.count, (i) {
        final active = (i - _page).abs() < 0.5;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          width: active ? 14.0 : 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: active ? primary : Colors.grey.shade400,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

class FullscreenGallery extends StatefulWidget {
  final List<String> images;
  final int initialIndex;
  final String heroPrefix;

  const FullscreenGallery({
    super.key,
    required this.images,
    required this.initialIndex,
    required this.heroPrefix,
  });

  @override
  State<FullscreenGallery> createState() => _FullscreenGalleryState();
}

class _FullscreenGalleryState extends State<FullscreenGallery> {
  late final PageController _pc;

  @override
  void initState() {
    super.initState();
    _pc = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Always use a dark backdrop; pick icon color based on theme for contrast
    final Color bg = Colors.black;
    final Color iconColor = Colors.white;

    return Scaffold(
      backgroundColor: bg,
      body: Stack(
        children: [
          // Images
          PageView.builder(
            controller: _pc,
            itemCount: widget.images.length,
            itemBuilder: (_, i) {
              // One controller per page for smooth double-tap toggle
              final tc = TransformationController();

              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTap: () {
                  final isIdentity = tc.value.storage[0] == 1.0;
                  tc.value = Matrix4.identity()..scale(isIdentity ? 2.5 : 1.0);
                },
                child: Center(
                  child: Hero(
                    tag: '${widget.heroPrefix}$i',
                    child: InteractiveViewer(
                      transformationController: tc,
                      panEnabled: true,
                      minScale: 1.0,
                      maxScale: 4.0,
                      child: _NetworkImage(
                        url: widget.images[i],
                        fit: BoxFit.contain, // contain for full-screen
                      ),
                    ),
                  ),
                ),
              );
            },
          ),

          // Close button (top-left)
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: IconButton.filled(
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all(Colors.black54),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close, color: iconColor),
                ),
              ),
            ),
          ),

          // Dots indicator (bottom-center)
          if (widget.images.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 20,
              child: _FullscreenDots(
                controller: _pc,
                count: widget.images.length,
              ),
            ),
        ],
      ),
    );
  }
}

class _FullscreenDots extends StatefulWidget {
  final PageController controller;
  final int count;
  const _FullscreenDots({required this.controller, required this.count});

  @override
  State<_FullscreenDots> createState() => _FullscreenDotsState();
}

class _FullscreenDotsState extends State<_FullscreenDots> {
  double _page = 0;

  @override
  void initState() {
    super.initState();
    _page = widget.controller.initialPage.toDouble();
    widget.controller.addListener(_onScroll);
  }

  void _onScroll() {
    setState(() => _page = widget.controller.page ?? _page);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onScroll);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(widget.count, (i) {
        final active = (i - _page).abs() < 0.5;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: active ? 14.0 : 8.0,
          height: 8.0,
          margin: const EdgeInsets.symmetric(horizontal: 4.0),
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white38,
            borderRadius: BorderRadius.circular(999),
          ),
        );
      }),
    );
  }
}

