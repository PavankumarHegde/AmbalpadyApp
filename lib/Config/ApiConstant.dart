// lib/Config/Api/api_constant.dart
import 'dart:io' show Platform;
import 'package:package_info_plus/package_info_plus.dart';

/// Centralized API constants + helpers.
///
/// IMPORTANT: Your server's signing_meta.json currently has:
///   app_package = 'in.orgaspace.ambalpady'   (note the extra 'a')
/// If your real app id is 'in.orgspace.ambalpady', either:
///   1) fix signing_meta.json to 'in.orgspace.ambalpady', OR
///   2) temporarily call ApiConstant.headers(forceServerPackage: true)
///      so requests use the server's value until you fix it.
/// Central place for API + crypto constants used by the app.
class ApiConstant {
  // ---- App / store ----
  /// Android applicationId (also sent to your PHP API as pkg and header)
  static const String kAppPackage = 'in.orgspace.ambalpady';

  // ---- Signed API (ECDSA P-256) ----
  /// Key ID from your keygen tool
  static const String kP256Kid = 'acc-p256-20250906-050704';

  /// Uncompressed P-256 public key (65 bytes) in base64
  /// Starts with 0x04, matches the PHP private key pair you generated.
  static const String kP256PublicKeyUncompressedB64 =
      'BEi/EPCEAHNXw4+MTiXcl7gb/YBPmuJNLrcI6j6yuLxYxwXR3VHVmgu6Ip0Il78rjEvozuFtuzdjnWnTp1QoThY=';

  // ---- API root (optional helper) ----
  static const String kApiRoot =
      'https://pavankumarhegde.com/RUST/api/api.php';

  /// Helper to build the page endpoint with the pkg gate applied.
  static Uri pageUri(String slug) =>
      Uri.parse('$kApiRoot?resource=page&slug=$slug&pkg=$kAppPackage');
}
