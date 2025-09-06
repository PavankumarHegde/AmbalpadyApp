import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../Config/ApiConstant.dart';
import '../../Utils/NetworkCheck.dart'; // uses ApiConstant.kAppPackage

class FestivalCalendarScreen extends StatefulWidget {
  const FestivalCalendarScreen({super.key});

  @override
  State<FestivalCalendarScreen> createState() => _FestivalCalendarScreenState();
}

class _FestivalCalendarScreenState extends State<FestivalCalendarScreen> {
  // ---------- API ----------
  static const String _apiBase =
      'https://pavankumarhegde.com/RUST/api/api.php';

  // ---------- State ----------
  late final DateTime _today;
  int _monthOffset = 0; // 0 = current month; +/- moves months
  bool _loading = true;
  String? _error;

  /// Events for the currently visible month, normalized as:
  /// { 'date': DateTime, 'label': String }
  List<Map<String, dynamic>> _events = [];

  DateTime get _visibleMonthStart =>
      DateTime(_today.year, _today.month + _monthOffset, 1);

  @override
  void initState() {
    super.initState();
    _today = DateTime.now();
    _loadMonth(_visibleMonthStart);
  }

  // ---------- Data loading ----------
  // ⬇️ REPLACE the whole _loadMonth(...) with this version:
  Future<void> _loadMonth(DateTime monthStart) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    // ✅ Check connectivity first; show dialog if offline & skip network calls
    final online = await NetworkCheck.ensureConnected(context);
    if (!online) {
      if (!mounted) return;
      setState(() {
        _loading = false;   // stop spinner
        _error = null;      // no noisy lookup error
        _events = [];       // avoid showing stale events for another month
      });
      return;
    }

    try {
      final raw = await _fetchScheduledFromApi();
      final normalized = _normalizeAndFilter(raw, monthStart)
        ..sort((a, b) {
          final da = a['date'] as DateTime;
          final db = b['date'] as DateTime;
          return da.compareTo(db);
        });

      if (!mounted) return;
      setState(() {
        _events = normalized;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }


  /// GET /RUST/api/api.php?resource=scheduled_notifications&pkg=...
  /// Accepts both the signed envelope and raw arrays.
  Future<dynamic> _fetchScheduledFromApi() async {
    final uri = Uri.parse(
      '$_apiBase?resource=scheduled_notifications'
          '&pkg=${Uri.encodeComponent(ApiConstant.kAppPackage)}',
    );
    final resp = await http.get(
      uri,
      headers: {'X-App-Package': ApiConstant.kAppPackage},
    );
    if (resp.statusCode != 200) {
      throw Exception('HTTP ${resp.statusCode}');
    }
    if (resp.body.isEmpty) return const [];
    final jsonResp = jsonDecode(resp.body);

    // Signed envelope: payload.items is the list
    if (jsonResp is Map && jsonResp['payload'] is Map) {
      final items = (jsonResp['payload'] as Map)['items'];
      return (items is List) ? items : const [];
    }

    // Raw list
    if (jsonResp is List) return jsonResp;

    return const [];
  }

  /// Keep only events in [monthStart .. nextMonthStart), normalized to {date, label}
  List<Map<String, dynamic>> _normalizeAndFilter(dynamic raw, DateTime monthStart) {
    final List<Map<String, dynamic>> out = [];
    if (raw is! List) return out;

    final nextMonth = DateTime(monthStart.year, monthStart.month + 1, 1);

    for (final item in raw) {
      if (item is! Map) continue;

      final dt = _parseScheduled(item);
      final label = _extractLabel(item);

      if (dt == null || label == null || label.trim().isEmpty) continue;
      if (dt.isBefore(monthStart) || !dt.isBefore(nextMonth)) continue;

      out.add({'date': dt, 'label': label.trim()});
    }
    return out;
  }

  /// Parse one scheduled item from API, tolerant to fields:
  /// scheduled_date (YYYY-MM-DD) + scheduled_time (HH:MM[:SS]) preferred.
  /// Falls back to date/time if needed.
  DateTime? _parseScheduled(Map item) {
    String? ds = _asString(item['scheduled_date']) ?? _asString(item['date']);
    String? time = _asString(item['scheduled_time']) ?? _asString(item['time']);

    if (ds != null && ds.isNotEmpty) {
      ds = ds.trim();
      // Normalize time
      time = _normalizeHms(time);
      // If only date, assume midnight local
      if (time == null || time.isEmpty) {
        try {
          return DateTime.parse(ds).toLocal();
        } catch (_) {}
      } else {
        // Build ISO-like string
        try {
          return DateTime.parse('${ds}T$time').toLocal();
        } catch (_) {}
      }
    }

    // Nothing parsed
    return null;
  }

  String? _asString(dynamic v) => (v is String) ? v : null;

  /// Normalize "H[:M[:S]]" -> "HH:MM:SS"
  String? _normalizeHms(String? t) {
    if (t == null || t.trim().isEmpty) return null;
    final s = t.trim();

    // Already HH:MM:SS
    if (RegExp(r'^\d{2}:\d{2}:\d{2}$').hasMatch(s)) return s;

    // HH:MM
    if (RegExp(r'^\d{2}:\d{2}$').hasMatch(s)) return '$s:00';

    // H:MM or H:MM:SS or H:MM AM/PM (loose)
    try {
      // Try DateTime.parse on a fake date
      final dt = DateTime.parse('2000-01-01T$s');
      return DateFormat('HH:mm:ss').format(dt);
    } catch (_) {
      // Try common "g:i A" formats using DateFormat
      try {
        final dt = DateFormat('h:mm a').parse(s);
        return DateFormat('HH:mm:ss').format(dt);
      } catch (_) {
        try {
          final dt = DateFormat('h:mm a').parse(s.toUpperCase());
          return DateFormat('HH:mm:ss').format(dt);
        } catch (_) {}
      }
    }
    // As a last resort, return null to drop time
    return null;
  }

  String? _extractLabel(Map m) {
    for (final k in const ['title', 'name', 'description', 'label', 'event', 'festival', 'text']) {
      final v = m[k];
      if (v is String && v.trim().isNotEmpty) return v;
    }
    return null;
  }

  // ---------- Calendar helpers ----------
  Iterable<DateTime> _daysForGrid(DateTime monthStart) {
    // 6x7 grid starting Sunday..Saturday
    final int leading = (monthStart.weekday % 7); // Sun=0, Mon=1..Sat=6
    final DateTime gridStart =
    monthStart.subtract(Duration(days: leading));
    return List.generate(42, (i) {
      final d = gridStart.add(Duration(days: i));
      return DateTime(d.year, d.month, d.day);
    });
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  bool _inSameMonth(DateTime a, DateTime m) =>
      a.year == m.year && a.month == m.month;

  bool _hasEventOn(DateTime day) {
    for (final e in _events) {
      final d = e['date'];
      if (d is DateTime && _isSameDay(d, day)) return true;
    }
    return false;
  }

  void _prevMonth() {
    setState(() => _monthOffset -= 1);
    _loadMonth(_visibleMonthStart);
  }

  void _nextMonth() {
    setState(() => _monthOffset += 1);
    _loadMonth(_visibleMonthStart);
  }

  // ---------- UI ----------
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final monthLabel = DateFormat('MMMM yyyy').format(_visibleMonthStart);

    final width = MediaQuery.of(context).size.width;
    final isWide = width >= 700.0;

    // Tile aspect ratio: tune for your design
    // Slightly wider than tall so 6 rows fit nicely.
    final childAspect = isWide ? 1.25 : 1.15;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => _loadMonth(_visibleMonthStart),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Month header with arrows (NO swipe)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                child: Row(
                  children: [
                    IconButton(
                      tooltip: 'Previous month',
                      onPressed: _loading ? null : _prevMonth,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          monthLabel,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Next month',
                      onPressed: _loading ? null : _nextMonth,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ),

              // Weekday header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: const [
                    _WeekdayCell('Sun'),
                    _WeekdayCell('Mon'),
                    _WeekdayCell('Tue'),
                    _WeekdayCell('Wed'),
                    _WeekdayCell('Thu'),
                    _WeekdayCell('Fri'),
                    _WeekdayCell('Sat'),
                  ],
                ),
              ),

              // Calendar grid (no internal scrolling; parent scrolls)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final days = _daysForGrid(_visibleMonthStart).toList();
                    return GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        mainAxisSpacing: 6.0,
                        crossAxisSpacing: 6.0,
                        childAspectRatio: childAspect,
                      ),
                      itemCount: days.length,
                      itemBuilder: (context, i) {
                        final day = days[i];
                        final isCurrentMonth = _inSameMonth(day, _visibleMonthStart);
                        final isToday = _isSameDay(day, _today);
                        final showEvent = _hasEventOn(day);

                        final textColor = isCurrentMonth
                            ? (isDark ? Colors.white : Colors.black87)
                            : (isDark ? Colors.white38 : Colors.black38);

                        return Container(
                          decoration: BoxDecoration(
                            color: isToday
                                ? (isDark ? Colors.white10 : Colors.black12)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(10),
                            border: showEvent
                                ? Border.all(
                              color: theme.colorScheme.primary.withOpacity(0.45),
                              width: 1,
                            )
                                : null,
                          ),
                          child: Stack(
                            children: [
                              Align(
                                alignment: Alignment.topRight,
                                child: Padding(
                                  padding: const EdgeInsets.only(top: 6, right: 6),
                                  child: Text(
                                    '${day.day}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                      color: textColor,
                                    ),
                                  ),
                                ),
                              ),
                              if (showEvent)
                                const Positioned(
                                  left: 8,
                                  bottom: 6,
                                  child: _EventDot(),
                                ),
                            ],
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              // Loading / error states
              if (_loading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(child: CircularProgressIndicator()),
                ),
              if (!_loading && _error != null)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Text(
                    _error!,
                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.error),
                  ),
                ),

              // Divider
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Divider(height: 1, color: theme.dividerColor.withOpacity(0.5)),
              ),

              // Events list (parent scrolls; list itself doesn't)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
                child: !_loading && _events.isEmpty
                    ? const _EmptyEvents()
                    : ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _events.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) {
                    final e = _events[i];
                    final d = e['date'] as DateTime;
                    final label = (e['label'] as String?) ?? '';
                    final dateStr = DateFormat('EEE, d MMM').format(d);
                    return Container(
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: theme.dividerColor.withOpacity(0.25),
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.primary.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              dateStr,
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              label,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w600,
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
          ),
        ),
      ),
    );
  }
}

// ---------- small UI helpers ----------

class _WeekdayCell extends StatelessWidget {
  final String label;
  const _WeekdayCell(this.label);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Center(
        child: Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _EventDot extends StatelessWidget {
  const _EventDot();
  @override
  Widget build(BuildContext context) {
    final c = Theme.of(context).colorScheme.primary;
    return Container(
      width: 8.0,
      height: 8.0,
      decoration: BoxDecoration(color: c, shape: BoxShape.circle),
    );
  }
}

class _EmptyEvents extends StatelessWidget {
  const _EmptyEvents();
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          children: [
            Icon(Icons.event_busy, size: 36, color: theme.disabledColor),
            const SizedBox(height: 8),
            Text(
              'No festival events this month',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              'Tap the arrows to switch months or check back later.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.hintColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
