import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Config/Theme/AppTheme.dart';
import '../../Config/ApiConstant.dart'; // uses kAppPackage

class AboutScreen extends StatefulWidget {
  const AboutScreen({super.key});

  @override
  State<AboutScreen> createState() => _AboutScreenState();
}

class _AboutScreenState extends State<AboutScreen> {
  // --- API config ---
  static const String _apiBase =
      'https://pavankumarhegde.com/RUST/api/api.php?resource=page&slug=';

  // Public fallbacks (files published at /ambalpady/)
  static const String _privacyPublicFallback =
      'https://pavankumarhegde.com/ambalpady/privacy.html';
  static const String _termsPublicFallback =
      'https://pavankumarhegde.com/ambalpady/terms.html';

  // --- Developer / store links ---
  static const String _developerName = 'Pavankumar Hegde';
  static const String _developerWebsite = 'https://pavankumarhegde.com';
  static const String _developerEmail = 'contact@pavankumarhegde.com';

  static String get _playUrl =>
      'https://play.google.com/store/apps/details?id=${ApiConstant.kAppPackage}';
  static const String _appStoreUrl =
      'https://apps.apple.com/app/id0000000000'; // replace if available

  // --- State ---
  String _aboutText =
      'Ambalpady Nayak Trust (R) serves the community with cultural, social '
      'and charitable initiatives. Thank you for your support.';
  String _version = '';
  String _privacyUrl = _privacyPublicFallback;
  String _termsUrl = _termsPublicFallback;

  bool _loading = true;

  String _urlWithPkg(String slug) {
    final pkgQuery = '&pkg=${Uri.encodeComponent(ApiConstant.kAppPackage)}';
    return '$_apiBase$slug$pkgQuery';
  }

  @override
  void initState() {
    super.initState();
    _load(); // first load shows full-screen loader
  }

  Future<void> _load() async {
    if (mounted) setState(() => _loading = true);
    try {
      final pkg = await PackageInfo.fromPlatform();
      if (mounted) {
        _version = '${pkg.version}+${pkg.buildNumber}';
      }

      // timeouts so UI won’t hang forever
      await _fetchAbout().timeout(const Duration(seconds: 12));
      await Future.wait([
        _fetchPagePublicUrl('privacy'),
        _fetchPagePublicUrl('terms'),
      ]).timeout(const Duration(seconds: 12));
    } catch (_) {
      // keep defaults on error
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _fetchAbout() async {
    try {
      final resp = await http
          .get(
        Uri.parse(_urlWithPkg('about')),
        headers: {'X-App-Package': ApiConstant.kAppPackage},
      )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final jsonResp = jsonDecode(resp.body);

        String? content;
        // Signed envelope
        if (jsonResp is Map && jsonResp['payload'] is Map) {
          final payload = jsonResp['payload'] as Map;
          final items = payload['items'];
          if (items is Map && items['content'] is String) {
            content = items['content'] as String;
          }
        }
        // Raw
        content ??= (jsonResp is Map && jsonResp['content'] is String)
            ? jsonResp['content'] as String
            : null;

        if (content != null && content.trim().isNotEmpty && mounted) {
          setState(() {
            _aboutText = _stripHtml(content!);
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _fetchPagePublicUrl(String slug) async {
    try {
      final resp = await http
          .get(
        Uri.parse(_urlWithPkg(slug)),
        headers: {'X-App-Package': ApiConstant.kAppPackage},
      )
          .timeout(const Duration(seconds: 10));

      if (resp.statusCode == 200 && resp.body.isNotEmpty) {
        final j = jsonDecode(resp.body);
        String? url;

        // Signed envelope -> payload.items.public_url
        if (j is Map && j['payload'] is Map) {
          final payload = j['payload'] as Map;
          final items = payload['items'];
          if (items is Map && items['public_url'] is String) {
            url = items['public_url'] as String;
          }
        }
        // Raw -> public_url
        url ??=
        (j is Map && j['public_url'] is String) ? j['public_url'] as String : null;

        if (url != null && url.trim().isNotEmpty && mounted) {
          setState(() {
            if (slug == 'privacy') _privacyUrl = url!;
            if (slug == 'terms') _termsUrl = url!;
          });
        }
      }
    } catch (_) {
      // keep fallbacks
    }
  }

  String _stripHtml(String html) {
    final withoutTags = html.replaceAll(RegExp(r'<[^>]+>'), ' ');
    return withoutTags.replaceAll(RegExp(r'\s+'), ' ').trim();
  }

  void _shareApp() {
    final link = Platform.isIOS ? _appStoreUrl : _playUrl;
    Share.share(
      'Check out the Ambalpady Nayak Trust (R) app:\n$link',
      subject: 'Ambalpady Nayak Trust (R)',
    );
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _emailTo(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  TableRow _row(
      BuildContext context, {
        required String label,
        required Widget value,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    return TableRow(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
              fontFamily: 'Poppins',
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: value,
        ),
      ],
    );
  }

  Widget _valueText(
      BuildContext context,
      String text, {
        bool emphasis = false,
        VoidCallback? onTap,
      }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final base = theme.textTheme.bodyMedium?.copyWith(
      color: isDark ? Colors.white70 : Colors.black87,
      fontFamily: 'Poppins',
      fontWeight: emphasis ? FontWeight.w600 : FontWeight.w400,
    );

    final child = Text(
      text,
      style: base,
      textAlign: TextAlign.right,
      overflow: TextOverflow.ellipsis,
      maxLines: 2,
    );

    return onTap == null
        ? Align(alignment: Alignment.centerRight, child: child)
        : Align(
      alignment: Alignment.centerRight,
      child: InkWell(
        onTap: onTap,
        child: Text(
          text,
          style: base?.copyWith(
            color: AppTheme.primaryRed,
            decoration: TextDecoration.underline,
          ),
          textAlign: TextAlign.right,
          overflow: TextOverflow.ellipsis,
          maxLines: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'About',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
            fontFamily: 'Poppins',
          ),
        ),
        centerTitle: true,
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        iconTheme: IconThemeData(color: isDark ? Colors.white : Colors.black),
        actions: [
          // quick manual refresh; shows a small spinner while loading
          if (_loading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              tooltip: 'Refresh',
              icon: const Icon(Icons.refresh),
              onPressed: _load,
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _shareApp,
        backgroundColor: AppTheme.primaryRed,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.share),
        label: const Text(
          'Share app with friends',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
      ),
      body: _loading
          ? const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryRed),
      )
          : RefreshIndicator(
        onRefresh: _load,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= 680;
            final logoSize = wide ? 120.0 : 90.0;
            final titleSize = wide ? 24.0 : 20.0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(
                  horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Header (logo + trust name)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 8.0),
                          child: Image.asset(
                            'assets/images/ambalpady.png',
                            width: logoSize,
                            height: logoSize,
                            fit: BoxFit.contain,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Text(
                            'Ambalpady Nayak Trust (R)',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontSize: titleSize,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'Poppins',
                              color: isDark
                                  ? Colors.white
                                  : Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 18),

                  // About text
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'About',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                      boxShadow: [
                        if (!isDark)
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                      ],
                    ),
                    child: Text(
                      _aboutText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        height: 1.5,
                        fontFamily: 'Poppins',
                        color: isDark
                            ? Colors.white70
                            : Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // 2-column "App Information"
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'App Information',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        fontFamily: 'Poppins',
                        color: isDark
                            ? Colors.white
                            : Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade900
                          : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark
                            ? Colors.grey.shade800
                            : Colors.grey.shade200,
                      ),
                    ),
                    child: Table(
                      columnWidths: const {
                        0: FlexColumnWidth(1.0),
                        1: FlexColumnWidth(1.4),
                      },
                      defaultVerticalAlignment:
                      TableCellVerticalAlignment.middle,
                      children: [
                        _row(
                          context,
                          label: 'Developer',
                          value: _valueText(
                            context,
                            _developerName,
                            emphasis: true,
                          ),
                        ),
                        _row(
                          context,
                          label: 'Website',
                          value: _valueText(
                            context,
                            _developerWebsite,
                            onTap: () => _openUrl(_developerWebsite),
                          ),
                        ),
                        _row(
                          context,
                          label: 'Email',
                          value: _valueText(
                            context,
                            _developerEmail,
                            onTap: () => _emailTo(_developerEmail),
                          ),
                        ),
                        _row(
                          context,
                          label: 'App Version',
                          value: _valueText(context, _version),
                        ),
                        _row(
                          context,
                          label: Platform.isIOS
                              ? 'App Store'
                              : 'Play Store',
                          value: _valueText(
                            context,
                            Platform.isIOS ? _appStoreUrl : _playUrl,
                            onTap: () => _openUrl(
                              Platform.isIOS
                                  ? _appStoreUrl
                                  : _playUrl,
                            ),
                          ),
                        ),
                        _row(
                          context,
                          label: 'Privacy Policy',
                          value: _valueText(
                            context,
                            _privacyUrl,
                            onTap: () => _openUrl(_privacyUrl),
                          ),
                        ),
                        _row(
                          context,
                          label: 'Terms & Conditions',
                          value: _valueText(
                            context,
                            _termsUrl,
                            onTap: () => _openUrl(_termsUrl),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Developed by $_developerName',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontFamily: 'Poppins',
                      color: isDark
                          ? Colors.white54
                          : Colors.black45,
                    ),
                  ),
                  const SizedBox(height: 80), // spacing for FAB
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
