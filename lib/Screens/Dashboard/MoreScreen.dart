import 'dart:convert';

import 'package:ambalpady/Screens/AboutScreen.dart';
import 'package:ambalpady/Screens/BankAccount/AccountsScreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Config/Theme/AppTheme.dart';
import '../../Utils/NetworkCheck.dart';
import '../ComingSoonScreen.dart';
import '../Setting/SettingScreen.dart';

class MoreScreen extends StatefulWidget {
  const MoreScreen({super.key});

  @override
  State<MoreScreen> createState() => _MoreScreenState();
}

class _MoreScreenState extends State<MoreScreen> {
  String _version = '';
  String _userName = 'Guest';
  String _userEmail = 'unknown@example.com';
  String _userPhone = '';
  String _userCode = '';

  // Contact person
  static const String _contactName = 'Abhay Naik';
  static const String _contactPhone = '8970816089'; // India
  static const String _trusteesApi =
      'https://pavankumarhegde.com/RUST/api/api.php?resource=trustees';
  static const String _appPackageHeader = 'in.orgspace.ambalpady'; // must match server


  @override
  void initState() {
    super.initState();
    _loadVersion();
    _loadUserData();
  }

  Future<void> _loadVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      final v = '${info.version}${info.buildNumber.isNotEmpty ? '+${info.buildNumber}' : ''}';
      if (!mounted) return;
      setState(() => _version = v);
    } catch (_) {}
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      final name = (prefs.getString('userName') ?? 'Guest').trim();
      _userName = name.isEmpty ? 'Guest' : name;
      _userEmail = prefs.getString('userEmail') ?? 'unknown@example.com';
      _userPhone = prefs.getString('userPhone') ?? '';
      _userCode  = prefs.getString('userCode')  ?? '';
    });
  }

  // Server base
  static const String _apiBase = 'https://pavankumarhegde.com/RUST/api/api.php';

  Future<List<Map<String, dynamic>>> _fetchTrustees() async {
    if (!await NetworkCheck.isOnline()) throw 'offline';

    // 1) Use the server-allowed id first (release id), then try runtime, then strip ".debug"
    final info = await PackageInfo.fromPlatform();
    final runtimePkg = info.packageName; // e.g., in.orgspace.ambalpady.debug
    final candidates = <String>[
      _appPackageHeader, // "in.orgspace.ambalpady" (matches server)
      runtimePkg,
      if (runtimePkg.endsWith('.debug'))
        runtimePkg.substring(0, runtimePkg.length - '.debug'.length),
    ];

    http.Response? lastResp;

    for (final pkg in candidates) {
      final uri = Uri.parse('$_apiBase?resource=trustees&raw=1&pkg=$pkg');
      final resp = await http.get(uri, headers: {'X-App-Package': pkg});
      lastResp = resp;

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final decoded = jsonDecode(resp.body);

        // Accept raw list or signed envelope
        final List items = decoded is List
            ? decoded
            : (decoded is Map &&
            decoded['payload'] is Map &&
            decoded['payload']['items'] is List)
            ? decoded['payload']['items'] as List
            : const [];

        // Normalize + canonicalize roles
        final list = items.map<Map<String, dynamic>>((e) {
          final m = (e is Map) ? e : const <String, dynamic>{};
          String role = (m['role'] ?? '').toString().trim();
          final rl = role.toLowerCase();
          if (rl == 'secretery') role = 'Secretary';
          if (rl == 'honarary president') role = 'Honarary President';
          if (rl == 'honorary president') role = 'Honorary President';

          return {
            'id'   : (m['id'] ?? '').toString().trim(),
            'role' : role,
            'name' : (m['name'] ?? '').toString().trim(),
            'phone': (m['phone'] ?? '').toString().trim(),
            'order': int.tryParse((m['order'] ?? '').toString()) ?? 9999,
          };
        }).where((m) => (m['name'] as String).isNotEmpty).toList();

        // Sort: order then name
        list.sort((a, b) {
          final ao = a['order'] as int, bo = b['order'] as int;
          if (ao != bo) return ao.compareTo(bo);
          return (a['name'] as String)
              .toLowerCase()
              .compareTo((b['name'] as String).toLowerCase());
        });

        return list;
      }

      // If 403 with this pkg, try next candidate
      if (resp.statusCode == 403) continue;

      // Any other error: break and report
      break;
    }

    final sc = lastResp?.statusCode ?? -1;
    throw 'http_$sc';
  }






  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ---------------- Contact sheet ----------------

  void _openContactSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final isDark = theme.brightness == Brightness.dark;
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryRed.withOpacity(0.12),
                  child: Icon(Icons.person, color: AppTheme.primaryRed),
                ),
                title: Text(
                  _contactName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                subtitle: Text(
                  _contactPhone,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
                trailing: IconButton(
                  tooltip: 'Copy number',
                  icon: const Icon(Icons.copy),
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: _contactPhone));
                    if (mounted) _showSnackBar('Phone number copied');
                  },
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _actionButton(
                      icon: Icons.chat_bubble_outline, // <- was Icons.whatsapp (not available)
                      label: 'WhatsApp',
                      onTap: () => _launchWhatsApp(_contactPhone, 'Hello $_contactName'),
                    ),
                  ),

                  const SizedBox(width: 12),
                  Expanded(
                    child: _actionButton(
                      icon: Icons.call,
                      label: 'Call',
                      onTap: () => _launchCall(_contactPhone),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _actionButton({required IconData icon, required String label, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        elevation: 0,
      ),
    );
  }

  Future<void> _launchCall(String phone) async {
    final uri = Uri(scheme: 'tel', path: phone);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      _showSnackBar('Could not open dialer');
    }
  }



  void _openTrusteesSheet() async {
    // Quick network gate using your utility
    final online = await NetworkCheck.isOnline();
    if (!mounted) return;

    // If offline, show a compact sheet with retry
    if (!online) {
      showModalBottomSheet(
        context: context,
        showDragHandle: true,
        isScrollControlled: false,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        builder: (ctx) {
          final theme = Theme.of(ctx);
          return Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('No Internet',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
                const SizedBox(height: 8),
                Text(
                  'Please check your Wi-Fi or mobile data and try again.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => Navigator.pop(ctx),
                        icon: const Icon(Icons.close),
                        label: const Text('Close'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: () async {
                          final ok = await NetworkCheck.isOnline();
                          if (ok && ctx.mounted) {
                            Navigator.pop(ctx);
                            _openTrusteesSheet(); // reopen when online
                          }
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
      return;
    }

    // Online: load from API
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        final theme = Theme.of(ctx);

        return FutureBuilder<List<Map<String, dynamic>>>(
          future: _fetchTrustees(), // uses API with X-App-Package header
          builder: (context, snap) {
            // Loading state
            if (snap.connectionState != ConnectionState.done) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(child: CircularProgressIndicator()),
              );
            }

            // Error / parse failure
            if (snap.hasError) {
              final err = snap.error?.toString() ?? 'unknown';
              final friendly = err.startsWith('http_403')
                  ? 'Access denied (package mismatch). Install the build with the correct package ID.'
                  : 'Failed to load trustees ($err).';
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(friendly, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 12),
                        TextButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            _openTrusteesSheet(); // retry
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final data = (snap.data ?? []) as List<Map<String, dynamic>>;
            if (data.isEmpty) {
              return SizedBox(
                height: MediaQuery.of(context).size.height * 0.5,
                child: const Center(child: Text('No trustees found.')),
              );
            }

            // Partition into office bearers and members
            const topOrder = <String, int>{
              'honorary president': 0,
              'honarary president': 0, // tolerate spelling in data
              'president': 1,
              'secretary': 2,
              'secretery': 2, // tolerate spelling in data
              'treasurer': 3,
            };

            final officeBearers = <Map<String, dynamic>>[];
            final others = <Map<String, dynamic>>[];

            for (final m in data) {
              final role = (m['role'] as String).toLowerCase();
              if (topOrder.containsKey(role)) {
                officeBearers.add(m);
              } else {
                others.add(m);
              }
            }

            officeBearers.sort((a, b) {
              final ar = topOrder[(a['role'] as String).toLowerCase()] ?? 999;
              final br = topOrder[(b['role'] as String).toLowerCase()] ?? 999;
              if (ar != br) return ar.compareTo(br);
              return (a['order'] as int).compareTo(b['order'] as int);
            });

            others.sort((a, b) {
              final ao = a['order'] as int;
              final bo = b['order'] as int;
              if (ao != bo) return ao.compareTo(bo);
              return (a['name'] as String)
                  .toLowerCase()
                  .compareTo((b['name'] as String).toLowerCase());
            });

            final entriesTop = officeBearers.map<List<String>>((m) {
              final r = (m['role'] as String).trim();
              final rl = r.toLowerCase();
              final display = rl == 'honarary president'
                  ? 'Honarary President'
                  : rl == 'honorary president'
                  ? 'Honorary President'
                  : rl == 'secretery'
                  ? 'Secretary'
                  : r.isNotEmpty
                  ? r[0].toUpperCase() + r.substring(1)
                  : r;
              return [display, (m['name'] as String).trim()];
            }).toList();

            final members = others.map<String>((m) => (m['name'] as String).trim()).toList();

            return DraggableScrollableSheet(
              initialChildSize: 0.6,
              minChildSize: 0.4,
              maxChildSize: 0.9,
              expand: false,
              builder: (context, scrollCtrl) {
                return ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                  children: [
                    Text(
                      'Trustees Details',
                      style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 12),

                    // Office bearers (API)
                    ...entriesTop.map((e) => _trusteeTile(role: e[0], name: e[1])),

                    const SizedBox(height: 16),
                    Text(
                      'Members',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 8),

                    // Members list (API)
                    ...members.map((m) => _trusteeTile(role: null, name: m)),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }



  Future<void> _launchWhatsApp(String phone, String message) async {
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    final intl = digits.startsWith('91') ? digits : '91$digits'; // default to India code
    final url = Uri.parse('https://wa.me/$intl?text=${Uri.encodeComponent(message)}');
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      _showSnackBar('WhatsApp not available');
    }
  }

  // ---------------- Trustees sheet ----------------

  Widget _trusteeTile({String? role, required String name}) {
    final theme = Theme.of(context);
    final hasRole = role != null && role.trim().isNotEmpty;
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryRed.withOpacity(0.12),
          child: Icon(hasRole ? Icons.badge_outlined : Icons.person_outline, color: AppTheme.primaryRed),
        ),
        title: Text(
          name,
          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        subtitle: hasRole
            ? Text(role!, style: theme.textTheme.bodySmall?.copyWith(color: Colors.black54))
            : null,
      ),
    );
  }


  Future<void> _launchURL(String url) async {
    final uri = Uri.parse(url);
    try {
      // Try external browser first
      final extOk = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (extOk) return;

      // Fallback to Chrome Custom Tabs / SFSafariViewController
      await launchUrl(uri, mode: LaunchMode.inAppBrowserView);
    } catch (e) {
      _showSnackBar('Could not open $url');
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 24),

            // ==== PROFILE HEADER (as earlier) ====
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryRed.withOpacity(0.15),
              child: Icon(Icons.person, size: 55, color: AppTheme.primaryRed),
            ),
            const SizedBox(height: 20),
            Text(
              _userName,
              textAlign: TextAlign.center,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.blue : Colors.black87,
                fontFamily: 'Poppins',
                fontSize: 18,
              ),
            ),
            if (_userPhone.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                '📞 $_userPhone',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isDark ? Colors.white54 : Colors.black45,
                  fontFamily: 'Poppins',
                ),
              ),
            ],

            if (_userCode.isNotEmpty) ...[
              const SizedBox(height: 30),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey.shade900 : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: isDark ? Colors.grey.shade700 : Colors.grey.shade200),
                  boxShadow: [
                    BoxShadow(
                      color: (isDark ? Colors.black : Colors.grey.shade200).withOpacity(0.5),
                      spreadRadius: 1,
                      blurRadius: 5,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Text(
                      'Your Unique Code',
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: isDark ? Colors.white60 : Colors.black54,
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            _userCode,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryRed,
                              fontFamily: 'Poppins',
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Tooltip(
                          message: 'Copy Code',
                          child: IconButton(
                            icon: Icon(Icons.copy,
                                size: 22, color: isDark ? Colors.white70 : Colors.grey.shade700),
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: _userCode));
                              _showSnackBar('User code copied!');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 30),

            // Invite Friends (Play Store link only)
            SizedBox(
              width: screenWidth * 0.7,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.share_outlined, size: 20),
                label: const Text(
                  'Invite Friends',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryRed,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 5,
                ),
                onPressed: () {
                  //  Replace this with your app’s actual Play Store URL
                  const playStoreLink =
                      'https://play.google.com/store/apps/details?id=in.orgspace.ambalpady'; // example pkg
                  Share.share(
                    'Check out this app — available on the Play Store:\n$playStoreLink',
                    subject: 'Ambalpady App',
                  );
                },
              ),
            ),


            const SizedBox(height: 40),

            // ==== Requested items ====
            _tile(context, Icons.account_balance_outlined, 'Account Details for Donations', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AccountsScreen()));
            }),
            _tile(context, Icons.people_outline, 'Trustees Details', () {
              _openTrusteesSheet();
            }),
            _tile(context, Icons.contact_mail_outlined, 'Contact Us', () {
              _openContactSheet();
            }),
            const Divider(height: 28),
            _tile(context, Icons.settings_outlined, 'Settings', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
            }),
            _tile(context, Icons.privacy_tip_outlined, 'Privacy Policy', () {
              _launchURL('https://pavankumarhegde.com/ambalpady/privacy.html');
            }),
            _tile(context, Icons.description_outlined, 'Terms & Conditions', () {
              _launchURL('https://pavankumarhegde.com/ambalpady/terms.html');
            }),

            _tile(context, Icons.info_outline, 'About', () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const AboutScreen()));
            }),

            // Developer credit after About
            const SizedBox(height: 24),
            Text(
              'Developed By Pavankumar Hegde',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: isDark ? Colors.white38 : Colors.black38,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            if (_version.isNotEmpty)
              Text(
                'v$_version',
                textAlign: TextAlign.center,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: isDark ? Colors.white38 : Colors.black38,
                  fontWeight: FontWeight.w600,
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // Reusable tile
  Widget _tile(BuildContext context, IconData icon, String label, VoidCallback onTap) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppTheme.primaryRed.withOpacity(0.12),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 22, color: AppTheme.primaryRed),
        ),
        title: Text(
          label,
          style: theme.textTheme.titleMedium?.copyWith(
            color: isDark ? Colors.white : Colors.black87,
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
          ),
        ),
        trailing: Icon(Icons.arrow_forward_ios_rounded,
            size: 18, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400),
        onTap: onTap,
        splashColor: AppTheme.primaryRed.withOpacity(0.1),
      ),
    );
  }
}
