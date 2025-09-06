import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Config/ApiConstant.dart'; // must expose: const String kAppPackage;
import '../../Config/Theme/AppTheme.dart';
import '../../Utils/NetworkCheck.dart'; // must expose: static Future<bool> isConnected()
import '../ComingSoonScreen.dart';

class AccountsScreen extends StatefulWidget {
  const AccountsScreen({super.key});

  @override
  State<AccountsScreen> createState() => _AccountsScreenState();
}

class _AccountsScreenState extends State<AccountsScreen> {
  static const String _apiBase = 'https://pavankumarhegde.com/RUST/api/api.php';

  bool _loading = true;
  String? _error;
  List<Account> _accounts = const [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final online = await NetworkCheck.isOnline();
    if (!online) {
      setState(() {
        _loading = false;
        _error = 'No internet connection.';
      });
      return;
    }

    try {
      final uri = Uri.parse('$_apiBase?resource=accounts&raw=1'); // raw = direct list
      final resp = await http.get(
        uri,
        headers: {'X-App-Package': ApiConstant.kAppPackage}, // package gate
      );

      if (resp.statusCode == 200) {
        final dec = json.decode(resp.body);
        if (dec is List) {
          final list = dec.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList();
          setState(() {
            _accounts = list;
            _loading = false;
          });
        } else {
          setState(() {
            _error = 'Unexpected response shape.';
            _loading = false;
          });
        }
      } else if (resp.statusCode == 403) {
        setState(() {
          _error = 'Forbidden (package mismatch). Check kAppPackage.';
          _loading = false;
        });
      } else {
        setState(() {
          _error = 'Server error ${resp.statusCode}.';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to load accounts: $e';
        _loading = false;
      });
    }
  }

  Future<void> _openUpi(String upiUrl) async {
    // Check connectivity (UPI apps usually need network to proceed)
    final online = await NetworkCheck.isOnline();
    if (!online) {
      _snack('No internet connection.', isError: true);
      return;
    }
    final uri = Uri.parse(upiUrl);
    try {
      // Prefer opening a non-browser app (UPI handler)
      final ok = await launchUrl(uri, mode: LaunchMode.externalNonBrowserApplication);
      if (!ok) {
        _snack('No UPI app found to handle this link.', isError: true);
      }
    } catch (e) {
      _snack('Could not open UPI link: $e', isError: true);
    }
  }

  void _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    _snack('$label copied.');
  }

  void _snack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError ? Colors.red : AppTheme.primaryRed,
        duration: const Duration(seconds: 2),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.black : Colors.white,
        foregroundColor: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black, // title & icons
        iconTheme: IconThemeData(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
        ),
        titleTextStyle: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: Theme.of(context).brightness == Brightness.dark ? Colors.white : Colors.black,
          fontWeight: FontWeight.w600,
        ),
        centerTitle: true,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: Theme.of(context).brightness == Brightness.dark
            ? SystemUiOverlayStyle.light
            : SystemUiOverlayStyle.dark, // import 'package:flutter/services.dart';
        title: const Text('Account Details'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? ListView(
          children: [
            const SizedBox(height: 120),
            Icon(Icons.wifi_off_rounded,
                size: 56, color: isDark ? Colors.white54 : Colors.black38),
            const SizedBox(height: 12),
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            ),
          ],
        )
            : ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _accounts.length,
          itemBuilder: (context, i) {
            final a = _accounts[i];
            return _AccountCard(
              a: a,
              onCopyAccount: () => _copy('Account number', a.account),
              onCopyIfsc: () => _copy('IFSC', a.ifsc),
              onCopyLink: () => _copy('UPI link', a.qrUrl),
              onOpenUpi: () => _openUpi(a.qrUrl),
            );
          },
        ),
      ),
    );
  }
}

class _AccountCard extends StatelessWidget {
  final Account a;
  final VoidCallback onCopyAccount;
  final VoidCallback onCopyIfsc;
  final VoidCallback onCopyLink;
  final VoidCallback onOpenUpi;

  const _AccountCard({
    required this.a,
    required this.onCopyAccount,
    required this.onCopyIfsc,
    required this.onCopyLink,
    required this.onOpenUpi,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      color: isDark ? Colors.grey.shade900 : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Icon(Icons.account_balance, color: AppTheme.primaryRed),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    a.trust,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryRed.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(a.bank, style: theme.textTheme.labelMedium),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Details + QR
            LayoutBuilder(
              builder: (_, c) {
                final isWide = c.maxWidth > 440;
                final details = _AccountDetails(
                  a: a,
                  onCopyAccount: onCopyAccount,
                  onCopyIfsc: onCopyIfsc,
                );
                final qr = _AccountQr(
                  upiUrl: a.qrUrl,
                  onOpenUpi: onOpenUpi,
                  onCopyLink: onCopyLink,
                );
                return isWide
                    ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: details),
                    const SizedBox(width: 16),
                    qr,
                  ],
                )
                    : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    details,
                    const SizedBox(height: 12),
                    qr,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountDetails extends StatelessWidget {
  final Account a;
  final VoidCallback onCopyAccount;
  final VoidCallback onCopyIfsc;

  const _AccountDetails({
    required this.a,
    required this.onCopyAccount,
    required this.onCopyIfsc,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget row(String label, String value, {VoidCallback? onCopy}) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: 88, child: Text(label, style: theme.textTheme.bodySmall)),
            const SizedBox(width: 8),
            Expanded(
              child: SelectableText(
                value,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            if (onCopy != null)
              IconButton(
                tooltip: 'Copy $label',
                icon: const Icon(Icons.copy, size: 18),
                onPressed: onCopy,
              ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        row('Trust', a.trust),
        row('Branch', a.branch),
        row('Account', a.account, onCopy: onCopyAccount),
        row('IFSC', a.ifsc, onCopy: onCopyIfsc),
      ],
    );
  }
}

class _AccountQr extends StatelessWidget {
  final String upiUrl;
  final VoidCallback onOpenUpi;
  final VoidCallback onCopyLink;

  const _AccountQr({
    required this.upiUrl,
    required this.onOpenUpi,
    required this.onCopyLink,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        // QR code
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).dividerColor),
            borderRadius: BorderRadius.circular(12),
          ),
          child: QrImageView(
            data: upiUrl,
            size: 180,
            gapless: true,
            backgroundColor: Colors.white, // ensure scanner contrast
          ),
        ),
        const SizedBox(height: 8),
        // Link actions
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton.icon(
              onPressed: onOpenUpi,
              icon: const Icon(Icons.open_in_new),
              label: const Text('Open UPI Link'),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: onCopyLink,
              icon: const Icon(Icons.link),
              label: const Text('Copy Link'),
            ),
          ],
        ),
      ],
    );
  }
}

class Account {
  final String id;
  final String trust;
  final String bank;
  final String account;
  final String ifsc;
  final String branch;
  final String qrUrl;

  Account({
    required this.id,
    required this.trust,
    required this.bank,
    required this.account,
    required this.ifsc,
    required this.branch,
    required this.qrUrl,
  });

  factory Account.fromJson(Map<String, dynamic> j) => Account(
    id: (j['id'] ?? '').toString(),
    trust: (j['trust'] ?? '').toString(),
    bank: (j['bank'] ?? '').toString(),
    account: (j['account'] ?? '').toString(),
    ifsc: (j['ifsc'] ?? '').toString(),
    branch: (j['branch'] ?? '').toString(),
    qrUrl: (j['qr_url'] ?? '').toString(),
  );
}
