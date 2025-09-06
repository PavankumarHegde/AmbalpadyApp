import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../Config/ApiConstant.dart'; // must provide kAppPackage
import '../../Config/Theme/AppTheme.dart';
import '../../Utils/NetworkCheck.dart';
import '../ComingSoonScreen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  // ------------------ API ------------------
  static const String _apiBase =
      'https://pavankumarhegde.com/RUST/api/api.php';

  // ------------------ Pref Keys ------------------
  static const String _kItemsKey = 'notif_items_v1';
  static const String _kDeletedIdsKey = 'notif_deleted_ids_v1';

  // ------------------ Filters ------------------
  static const _kFilters = ['All', 'Posts', 'Festivals', 'Wishes', 'Scheduled'];
  String _activeFilter = _kFilters.first;

  // ------------------ State ------------------
  bool _isLoading = true;
  String? _error;

  /// Normalized notifications (and persisted):
  /// { id, type, title, body, timestamp(DateTime), read(bool), deeplink?, imageUrl? }
  List<Map<String, dynamic>> _items = [];

  // Local persistence
  late SharedPreferences _prefs;
  final Set<String> _deletedIds = <String>{};

  @override
  void initState() {
    super.initState();
    _init();
  }

  // ------------------ Init / Persistence ------------------

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    // Load locally saved items (including read ones)
    final raw = _prefs.getString(_kItemsKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final list = (jsonDecode(raw) as List)
            .whereType<Map>()
            .map<Map<String, dynamic>>((m) => _decodeStoredItem(m))
            .toList();
        _items = list;
      } catch (_) {}
    }
    // Load deleted ids
    _deletedIds.addAll(_prefs.getStringList(_kDeletedIdsKey) ?? const []);
    // Remove any locally saved item that was deleted earlier
    _items.removeWhere((e) => _deletedIds.contains(e['id'] as String));
    // Show what we have immediately, then fetch new
    if (mounted) setState(() {});
    await _loadNotifications();
  }

  Map<String, dynamic> _decodeStoredItem(Map m) {
    final tsStr = (m['timestamp'] as String?) ?? '';
    DateTime ts;
    try {
      ts = DateTime.parse(tsStr).toLocal();
    } catch (_) {
      ts = DateTime.now();
    }
    return <String, dynamic>{
      'id': (m['id'] ?? '').toString(),
      'type': (m['type'] ?? 'post').toString(),
      'title': (m['title'] ?? 'Notification').toString(),
      'body': (m['body'] ?? '').toString(),
      'timestamp': ts,
      'read': m['read'] == true,
      'deeplink': (m['deeplink'] ?? '') as String?,
      'imageUrl': (m['imageUrl'] ?? '') as String?,
    };
  }

  Future<void> _saveItems() async {
    final enc = _items
        .map<Map<String, dynamic>>((n) => {
      'id': n['id'],
      'type': n['type'],
      'title': n['title'],
      'body': n['body'],
      'timestamp': (n['timestamp'] as DateTime).toIso8601String(),
      'read': n['read'] == true,
      'deeplink': n['deeplink'],
      'imageUrl': n['imageUrl'],
    })
        .toList();
    await _prefs.setString(_kItemsKey, jsonEncode(enc));
  }

  Future<void> _saveDeleted() async {
    await _prefs.setStringList(_kDeletedIdsKey, _deletedIds.toList());
  }

  // ------------------ Loading (merge new, keep old) ------------------

// Replace _loadNotifications() with this version:
  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final online = await NetworkCheck.ensureConnected(context);
    if (!online) {
      if (!mounted) return;
      setState(() {
        _isLoading = false; // show cached items (if any), no error text
        _error = null;
      });
      return;
    }

    try {
      // Fetch both resources
      final both = await Future.wait<List<dynamic>>([
        _fetchList('notifications'),
        _fetchList('scheduled_notifications'),
      ]);

      // Normalize all fetched
      final fetched = <Map<String, dynamic>>[];
      for (final item in both[0]) {
        if (item is Map) {
          final n = _normalizeOne(item, 'notifications');
          if (n != null) fetched.add(n);
        }
      }
      for (final item in both[1]) {
        if (item is Map) {
          final n = _normalizeOne(item, 'scheduled');
          if (n != null) fetched.add(n);
        }
      }

      // Build map of existing local items by id
      final localById = {for (final it in _items) it['id'] as String: it};

      // Merge fetched into local, honoring deletions & read state
      for (final n in fetched) {
        final id = n['id'] as String;
        if (_deletedIds.contains(id)) continue; // never show again once deleted
        if (localById.containsKey(id)) {
          final existing = localById[id]!;
          existing['type'] = n['type'];
          existing['title'] = n['title'];
          existing['body'] = n['body'];
          existing['timestamp'] = n['timestamp'];
          existing['deeplink'] = n['deeplink'];
          existing['imageUrl'] = n['imageUrl'];
          // keep existing['read']
        } else {
          localById[id] = n; // new & unread
        }
      }

      final now = DateTime.now();
      final merged = localById.values
          .where((e) =>
      !_deletedIds.contains(e['id'] as String) &&
          !(e['timestamp'] as DateTime).isAfter(now))
          .toList();


      // Sort DESC by time
      merged.sort((a, b) {
        final ta = a['timestamp'] as DateTime;
        final tb = b['timestamp'] as DateTime;
        return tb.compareTo(ta);
      });

      if (!mounted) return;
      setState(() {
        _items = merged;
      });

      await _saveItems();
      await _saveDeleted();
    } catch (e) {
      if (!mounted) return;
      // If something else fails while online, show a friendly message
      setState(() => _error = 'Couldn’t refresh right now. Please try again.');
    } finally {
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }


  /// GET resource helper that understands both signed envelope and raw list
  Future<List<dynamic>> _fetchList(String resource) async {
    final uri = Uri.parse(
      '$_apiBase?resource=$resource&pkg=${Uri.encodeComponent(ApiConstant.kAppPackage)}',
    );
    final resp = await http.get(uri, headers: {
      'X-App-Package': ApiConstant.kAppPackage,
    });

    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode} for $resource');
    }
    if (resp.body.isEmpty) return const [];

    final jsonResp = jsonDecode(resp.body);

    // Signed envelope: payload.items
    if (jsonResp is Map && jsonResp['payload'] is Map) {
      final items = (jsonResp['payload'] as Map)['items'];
      if (items is List) return items;
      if (items is Map) return [items];
      return const [];
    }

    // Raw list
    if (jsonResp is List) return jsonResp;

    // Raw map (unlikely here)
    if (jsonResp is Map) return [jsonResp];

    return const [];
  }

  // ------------------ Normalization ------------------

  Map<String, dynamic>? _normalizeOne(Map raw, String source) {
    // ID
    String? id = _firstString(raw, ['id', 'nid', 'uid', 'notification_id']);
    id ??= _intLikeToString(raw['id']);
    if (id == null || id.trim().isEmpty) {
      final composed = '${_firstString(raw, ['scheduled_date', 'date']) ?? ''}|'
          '${_firstString(raw, ['scheduled_time', 'time']) ?? ''}|'
          '${_firstString(raw, ['title', 'heading']) ?? ''}';
      if (composed.trim().isEmpty) return null;
      id = 'auto_${composed.hashCode}';
    }

    // TYPE
    String type =
    (_firstString(raw, ['type', 'kind', 'category']) ?? '').toLowerCase();
    if (type.isEmpty) {
      type = source == 'scheduled' ? 'scheduled' : 'post';
    }

    // TITLE / BODY
    final title = _firstString(raw, ['title', 'heading']) ??
        _firstString(raw, ['description', 'desc', 'message', 'body']) ??
        'Notification';
    final body =
        _firstString(raw, ['description', 'desc', 'message', 'body']) ?? '';

    // TIMESTAMP
    DateTime? ts;
    if (source == 'scheduled') {
      final ds = _firstString(raw, ['scheduled_date', 'date']) ?? '';
      final tm = _normalizeHms(_firstString(raw, ['scheduled_time', 'time']));
      ts = _parseDatePair(ds, tm) ??
          _firstDate(raw, [
            'timestamp',
            'time',
            'date',
            'date_time',
            'date_str',
            'time_epoch_ms',
            'time_epoch',
            'time_epoch_sec',
          ]);
    } else {
      final ds = _firstString(raw, ['date']) ?? '';
      final tm = _normalizeHms(_firstString(raw, ['time']));
      ts = _parseDatePair(ds, tm) ??
          _firstDate(raw, [
            'timestamp',
            'time',
            'date',
            'date_time',
            'date_str',
            'created_at',
            'time_epoch_ms',
            'time_epoch',
            'time_epoch_sec',
          ]);
    }
    ts ??= DateTime.now();

    final deeplink = _firstString(raw, ['deeplink', 'link', 'url']);
    final imageUrl = _firstString(raw, ['image', 'imageUrl', 'icon']);

    // Preserve read if already in _items
    final existing =
    _items.firstWhere((e) => e['id'] == id, orElse: () => {});
    final read = existing.isNotEmpty ? (existing['read'] == true) : false;

    return <String, dynamic>{
      'id': id,
      'type': type,
      'title': title,
      'body': body,
      'timestamp': ts,
      'read': read, // default false if new
      'deeplink': deeplink,
      'imageUrl': imageUrl,
    };
  }

  String? _firstString(Map m, List<String> keys) {
    for (final k in keys) {
      final v = m[k];
      if (v is String && v.trim().isNotEmpty) return v.trim();
    }
    return null;
  }

  String? _intLikeToString(dynamic v) {
    if (v is int) return v.toString();
    if (v is String && RegExp(r'^\d+$').hasMatch(v)) return v;
    return null;
  }

  DateTime? _firstDate(Map m, List<String> keys) {
    for (final k in keys) {
      if (!m.containsKey(k)) continue;
      final d = _parseDateFlexible(m[k]);
      if (d != null) return d;
    }
    return null;
  }

  DateTime? _parseDatePair(String dateStr, String? hms) {
    final ds = dateStr.trim();
    if (ds.isEmpty) return null;
    if (hms == null || hms.isEmpty) {
      try {
        return DateTime.parse(ds).toLocal();
      } catch (_) {
        return null;
      }
    }
    try {
      return DateTime.parse('${ds}T$hms').toLocal();
    } catch (_) {
      return null;
    }
  }

  /// Normalize "H[:M[:S]]" -> "HH:MM:SS" if possible
  String? _normalizeHms(String? t) {
    if (t == null || t.trim().isEmpty) return null;
    final s = t.trim();

    if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(s)) return s;
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(s)) return '$s:00';

    // attempt DateTime.parse with dummy date
    try {
      final dt = DateTime.parse('2000-01-01T$s');
      return DateFormat('HH:mm:ss').format(dt);
    } catch (_) {
      // AM/PM
      for (final fmt in ['h:mm a', 'h:mma', 'hh:mm a', 'hh:mma']) {
        try {
          final dt = DateFormat(fmt).parse(s);
          return DateFormat('HH:mm:ss').format(dt);
        } catch (_) {}
      }
    }
    return null;
  }

  DateTime? _parseDateFlexible(dynamic v) {
    if (v == null) return null;
    if (v is DateTime) return v;

    if (v is String) {
      final s = v.trim();
      // digits -> epoch
      if (RegExp(r'^\d+$').hasMatch(s)) {
        if (s.length >= 13) {
          final ms = int.tryParse(s);
          if (ms != null) {
            return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
          }
        } else if (s.length >= 10) {
          final sec = int.tryParse(s);
          if (sec != null) {
            return DateTime.fromMillisecondsSinceEpoch(sec * 1000).toLocal();
          }
        }
      }
      // ISO8601
      try {
        return DateTime.parse(s).toLocal();
      } catch (_) {}
      // "yyyy-MM-dd HH:mm:ss"
      try {
        final f = DateFormat('yyyy-MM-dd HH:mm:ss');
        return f.parse(s).toLocal();
      } catch (_) {}
    }

    if (v is int) {
      // >= 10^12 => ms else sec
      if (v >= 1000000000000) {
        return DateTime.fromMillisecondsSinceEpoch(v).toLocal();
      }
      return DateTime.fromMillisecondsSinceEpoch(v * 1000).toLocal();
    }

    if (v is Map) {
      final y = v['y'] ?? v['year'];
      final mo = v['m'] ?? v['month'];
      final d = v['d'] ?? v['day'];
      final h = v['h'] ?? v['hour'] ?? 0;
      final mi = v['min'] ?? v['minute'] ?? 0;
      if (y is int && mo is int && d is int) {
        return DateTime(y, mo, d, h is int ? h : 0, mi is int ? mi : 0);
      }
    }

    return null;
  }

  // ------------------ Filters / helpers ------------------

  bool _passesFilter(Map<String, dynamic> n) {
    if (_activeFilter == 'All') return true;
    if (_activeFilter == 'Scheduled') {
      return (n['type'] == 'scheduled') ||
          (n['timestamp'] as DateTime).isAfter(DateTime.now());
    }
    final t = (n['type'] as String?) ?? '';
    switch (_activeFilter) {
      case 'Posts':
        return t == 'post';
      case 'Festivals':
        return t == 'festival';
      case 'Wishes':
        return t == 'wish';
      default:
        return true;
    }
  }

  IconData _iconFor(Map n) {
    final t = (n['type'] as String?) ?? '';
    if (t == 'festival') return Icons.event;
    if (t == 'wish') return Icons.celebration;
    if (t == 'scheduled') return Icons.schedule;
    return Icons.article;
  }

  Color _tintFor(BuildContext context, Map n) {
    final t = (n['type'] as String?) ?? '';
    if (t == 'festival') return Colors.deepPurple;
    if (t == 'wish') return Colors.orange;
    if (t == 'scheduled') return Colors.teal;
    return Theme.of(context).colorScheme.primary;
  }

  String _timeAgo(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.isNegative) {
      final ahead = d.difference(now);
      if (ahead.inMinutes < 60) return 'In ${ahead.inMinutes}m';
      if (ahead.inHours < 24) return 'In ${ahead.inHours}h';
      return 'In ${ahead.inDays}d';
    }
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Map<String, List<Map<String, dynamic>>> _groupByDay(
      List<Map<String, dynamic>> list) {
    final map = <String, List<Map<String, dynamic>>>{};
    for (final n in list) {
      final ts = (n['timestamp'] as DateTime);
      final key = DateFormat('yyyy-MM-dd').format(ts);
      map.putIfAbsent(key, () => []).add(n);
    }
    final sortedKeys = map.keys.toList()..sort((a, b) => b.compareTo(a));
    return {for (final k in sortedKeys) k: map[k]!};
  }

  String _sectionLabelFromKey(String key) {
    final dt = DateTime.parse(key);
    final today = DateTime.now();
    final yday = today.subtract(const Duration(days: 1));
    if (DateUtils.isSameDay(dt, today)) return 'Today';
    if (DateUtils.isSameDay(dt, yday)) return 'Yesterday';
    return DateFormat('EEE, MMM d').format(dt);
  }

  // ------------------ Local actions (persisted) ------------------

  Future<void> _markRead(String id, bool read) async {
    final idx = _items.indexWhere((e) => e['id'] == id);
    if (idx >= 0) {
      _items[idx]['read'] = read;
      await _saveItems();
      if (mounted) setState(() {});
    }
  }

  Future<void> _delete(String id) async {
    _deletedIds.add(id);
    _items.removeWhere((e) => e['id'] == id);
    await _saveItems();
    await _saveDeleted();
    if (mounted) setState(() {});
  }

  void _markAllRead() async {
    for (final n in _items) {
      if (_passesFilter(n)) n['read'] = true;
    }
    await _saveItems();
    if (mounted) setState(() {});
  }

  // ------------------ UI ------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final filtered = _items.where(_passesFilter).toList(growable: false);
    final grouped = _groupByDay(filtered);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      // No AppBar (as requested)
      body: SafeArea(
        child: Column(
          children: [
            // Top actions (row) instead of AppBar
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              child: Row(
                children: [
                  Text(
                    'Notifications',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Refresh',
                    onPressed: _loadNotifications,
                    icon: const Icon(Icons.refresh),
                  ),
                  IconButton(
                    tooltip: 'Mark all as read',
                    onPressed: _markAllRead,
                    icon: const Icon(Icons.done_all),
                  ),
                ],
              ),
            ),

            // Filter chips
            SizedBox(
              height: 44,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                scrollDirection: Axis.horizontal,
                itemBuilder: (_, i) {
                  final f = _kFilters[i];
                  final selected = f == _activeFilter;
                  return ChoiceChip(
                    label: Text(f),
                    selected: selected,
                    onSelected: (_) => setState(() => _activeFilter = f),
                    selectedColor: AppTheme.primaryRed.withOpacity(0.15),
                    labelStyle: TextStyle(
                      color: selected
                          ? AppTheme.primaryRed
                          : (isDark ? Colors.white70 : Colors.black87),
                      fontWeight: FontWeight.w600,
                    ),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemCount: _kFilters.length,
              ),
            ),

            const SizedBox(height: 8),

            Expanded(
              child: _isLoading
                  ? const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryRed,
                ),
              )
                  : RefreshIndicator(
                color: AppTheme.primaryRed,
                onRefresh: _loadNotifications,
                child: _error != null
                    ? ListView(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      child: Text(
                        _error!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.error,
                        ),
                      ),
                    ),
                  ],
                )
                    : grouped.isEmpty
                    ? _EmptyNotifications(isDark: isDark)
                    : ListView.builder(
                  padding:
                  const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: grouped.length,
                  itemBuilder: (context, groupIndex) {
                    final key =
                    grouped.keys.elementAt(groupIndex);
                    final label = _sectionLabelFromKey(key);
                    final list = grouped[key]!;

                    return Column(
                      crossAxisAlignment:
                      CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 8),
                          child: Text(
                            label,
                            style: theme
                                .textTheme.titleMedium
                                ?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white70
                                  : Colors.black54,
                            ),
                          ),
                        ),
                        ...list
                            .map((n) =>
                            _notificationTile(context, n))
                            .toList(),
                        const SizedBox(height: 4),
                      ],
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

  Widget _notificationTile(BuildContext context, Map<String, dynamic> n) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final ts = n['timestamp'] as DateTime;
    final scheduled =
        (n['type'] == 'scheduled') || ts.isAfter(DateTime.now());
    final read = n['read'] == true;
    final id = n['id'] as String;

    final tint = _tintFor(context, n);
    final icon = _iconFor(n);
    final title = (n['title'] as String?) ?? '';
    final body = (n['body'] as String?) ?? '';
    final timeStr = _timeAgo(ts);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () async {
          // Mark read on open & persist (do NOT delete)
          await _markRead(id, true);
          if (!mounted) return;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => NotificationDetailsScreen(data: n),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Leading icon / image
              Container(
                width: 42.0,
                height: 42.0,
                decoration: BoxDecoration(
                  color: tint.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10.0),
                ),
                child: Center(
                  child: Icon(icon, color: tint, size: 22.0),
                ),
              ),
              const SizedBox(width: 12.0),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title + badges row
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        if (!read)
                          Container(
                            width: 8.0,
                            height: 8.0,
                            decoration: const BoxDecoration(
                              color: AppTheme.primaryRed,
                              shape: BoxShape.circle,
                            ),
                          ),
                        if (scheduled) ...[
                          const SizedBox(width: 6),
                          _badge('Scheduled', tint),
                        ],
                      ],
                    ),

                    if (body.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark ? Colors.white70 : Colors.black87,
                        ),
                      ),
                    ],

                    const SizedBox(height: 8),

                    // Footer: time ago + actions
                    Row(
                      children: [
                        Icon(Icons.access_time,
                            size: 14.0,
                            color: isDark ? Colors.white38 : Colors.black38),
                        const SizedBox(width: 4.0),
                        Text(
                          timeStr,
                          style: theme.textTheme.labelSmall?.copyWith(
                            color:
                            isDark ? Colors.white54 : Colors.black54,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        PopupMenuButton<String>(
                          padding: EdgeInsets.zero,
                          onSelected: (value) async {
                            if (value == 'read') {
                              await _markRead(id, true);
                            } else if (value == 'unread') {
                              await _markRead(id, false);
                            } else if (value == 'delete') {
                              await _delete(id);
                            }
                          },
                          itemBuilder: (_) => [
                            if (!read)
                              const PopupMenuItem(
                                  value: 'read',
                                  child: Text('Mark as read')),
                            if (read)
                              const PopupMenuItem(
                                  value: 'unread',
                                  child: Text('Mark as unread')),
                            const PopupMenuItem(
                                value: 'delete', child: Text('Delete')),
                          ],
                          child: Icon(Icons.more_horiz,
                              color: isDark
                                  ? Colors.white54
                                  : Colors.black54),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _badge(String text, Color tint) {
    return Container(
      padding:
      const EdgeInsets.symmetric(horizontal: 8.0, vertical: 2.0),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(color: tint.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: tint),
      ),
    );
  }
}

// ------------------ Empty state ------------------

class _EmptyNotifications extends StatelessWidget {
  final bool isDark;
  const _EmptyNotifications({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_off_outlined,
                size: 72,
                color: isDark
                    ? Colors.grey.shade700
                    : Colors.grey.shade300),
            const SizedBox(height: 14),
            Text(
              'No notifications',
              style: theme.textTheme.titleMedium?.copyWith(
                color:
                isDark ? Colors.white70 : Colors.black54,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'You’re all caught up for now.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color:
                isDark ? Colors.white54 : Colors.black45,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}


// ===================== NEW: NotificationDetailsScreen =====================
class NotificationDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> data;
  const NotificationDetailsScreen({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final String title = (data['title'] as String?) ?? 'Notification';
    final String body = (data['body'] as String?) ?? '';
    final DateTime ts = (data['timestamp'] as DateTime);
    final String? imageUrl = data['imageUrl'] as String?;
    final String? deeplink = data['deeplink'] as String?;
    final String type = (data['type'] as String?) ?? 'post';

    final scheduled = type == 'scheduled' || ts.isAfter(DateTime.now());
    final timeStr = DateFormat('EEE, MMM d • h:mm a').format(ts);

    return Scaffold(
      appBar: AppBar(
        backgroundColor: isDark ? theme.colorScheme.surface : Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actionsIconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        title: Text(
          'Notification',
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

      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        children: [
          // Title row + chips
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _iconFor(data),
                color: _tintFor(context, data),
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ),
              if (scheduled) ...[
                const SizedBox(width: 8),
                _DetailsBadge(text: 'Scheduled', tint: _tintFor(context, data)),
              ],
            ],
          ),

          const SizedBox(height: 8),

          // Time
          Row(
            children: [
              Icon(Icons.access_time,
                  size: 16, color: isDark ? Colors.white60 : Colors.black54),
              const SizedBox(width: 6),
              Text(
                timeStr,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isDark ? Colors.white70 : Colors.black,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Optional image
          if (imageUrl != null && imageUrl.trim().isNotEmpty) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                loadingBuilder: (c, child, p) =>
                p == null ? child : const SizedBox(height: 180, child: Center(child: CircularProgressIndicator(strokeWidth: 2))),
                errorBuilder: (_, __, ___) => Container(
                  height: 160,
                  color: Colors.black12,
                  alignment: Alignment.center,
                  child: const Icon(Icons.broken_image_outlined),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Body text
          if (body.isNotEmpty)
            Text(
              body,
              style: theme.textTheme.bodyLarge?.copyWith(height: 1.5),
            ),

          // Optional deeplink/info
          if (deeplink != null && deeplink.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Text(
              'Link: $deeplink',
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white60 : Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Reuse same helpers used in list tile:
  IconData _iconFor(Map n) {
    final t = (n['type'] as String?) ?? '';
    if (t == 'festival') return Icons.event;
    if (t == 'wish') return Icons.celebration;
    if (t == 'scheduled') return Icons.schedule;
    return Icons.article;
  }

  Color _tintFor(BuildContext context, Map n) {
    final t = (n['type'] as String?) ?? '';
    if (t == 'festival') return Colors.deepPurple;
    if (t == 'wish') return Colors.orange;
    if (t == 'scheduled') return Colors.teal;
    return Theme.of(context).colorScheme.primary;
  }
}

class _DetailsBadge extends StatelessWidget {
  final String text;
  final Color tint;
  const _DetailsBadge({required this.text, required this.tint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tint.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: tint.withOpacity(0.35)),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: tint),
      ),
    );
  }
}