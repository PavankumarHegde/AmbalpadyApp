// lib/Utils/network_check.dart
import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// If you don't want this dependency, you can remove it and rely on the HTTP/DNS checks.
// Add to pubspec.yaml: connectivity_plus: ^6.0.4 (or latest)
import 'package:connectivity_plus/connectivity_plus.dart';

/// NetworkCheck
/// - Call `await NetworkCheck.ensureConnected(context)` before hitting the API.
/// - Returns true when online (no dialog shown), false when offline (dialog shown).
class NetworkCheck {
  NetworkCheck._();

  static bool _dialogOpen = false;

  /// Fast online check:
  /// 1) connectivity_plus says not none
  /// 2) quick GET to Google's 204 endpoint (or DNS fallback)
  static Future<bool> isOnline({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    try {
      // 1) Transport availability
      try {
        final conn = await Connectivity().checkConnectivity();
        if (conn == ConnectivityResult.none) return false;
      } catch (_) {
        // If connectivity_plus is unavailable, continue with HTTP/DNS checks.
      }

      // 2) HTTP reachability check (very fast 204/200)
      final uri = Uri.parse('https://www.google.com/generate_204');
      final resp = await http.get(uri).timeout(timeout);
      if (resp.statusCode == 204 || resp.statusCode == 200) return true;

      // 3) Fallback DNS lookup (rare path)
      final result =
      await InternetAddress.lookup('pavankumarhegde.com').timeout(timeout);
      return result.isNotEmpty && result.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } on TimeoutException {
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Ensures connectivity. Only shows a dialog if we are still offline after a short re-check.
  static Future<bool> ensureConnected(
      BuildContext context, {
        bool showDialogOnFail = true,
      }) async {
    // First pass
    if (await isOnline()) return true;

    // Small delay + second pass to avoid false negatives on app start
    await Future.delayed(const Duration(milliseconds: 350));
    if (await isOnline()) return true;

    if (!showDialogOnFail) return false;
    if (_dialogOpen) return false;
    if (!context.mounted) return false;

    _dialogOpen = true;
    try {
      final theme = Theme.of(context);
      final isDark = theme.brightness == Brightness.dark;

      final result = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          return AlertDialog(
            backgroundColor:
            isDark ? theme.colorScheme.surface : Colors.white,
            title: Text(
              'No Internet',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            content: Text(
              'Please check your Wi-Fi or mobile data and try again.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Close'),
              ),
              FilledButton(
                onPressed: () async {
                  // Retry without closing to avoid flicker
                  final ok = await isOnline();
                  if (ok && ctx.mounted) {
                    Navigator.of(ctx).pop(true);
                  }
                },
                child: const Text('Retry'),
              ),
            ],
          );
        },
      );

      return result == true;
    } finally {
      _dialogOpen = false;
    }
  }
}
