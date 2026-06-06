import 'dart:convert';
import 'package:crypto/crypto.dart';

/// ============================================================
/// ⚠️  PERINGATAN KEAMANAN (SECURITY WARNING)
/// ============================================================
/// Proses pembuatan Digest dan Signature HMAC-SHA256 ini
/// idealnya HARUS dilakukan di server backend Anda sendiri,
/// BUKAN di dalam kode Flutter (client-side).
///
/// Alasannya: Secret Key yang tertanam di dalam aplikasi mobile
/// bisa diextract oleh pihak tidak bertanggung jawab melalui
/// reverse-engineering APK.
///
/// Kode ini ditulis di sisi Flutter HANYA untuk keperluan
/// testing/sandbox dan tugas akademik. Untuk produksi,
/// buatlah endpoint backend (misal PocketBase hooks / Node.js)
/// yang menerima data transaksi dari Flutter, lalu backend
/// yang melakukan signing dan meneruskan ke DOKU API.
/// ============================================================

class DokuSignatureHelper {
  /// Membuat Digest dari JSON Body menggunakan SHA-256 lalu encode Base64.
  ///
  /// Digest = Base64(SHA-256(requestBody))
  /// Digunakan sebagai salah satu komponen pembentuk Signature.
  static String generateDigest(String jsonBody) {
    final bytes = utf8.encode(jsonBody);
    final hash = sha256.convert(bytes);
    return base64.encode(hash.bytes);
  }

  /// Membuat HMAC-SHA256 Signature sesuai standar keamanan DOKU API v2.
  ///
  /// Komponen Signature (dipisahkan oleh newline \n):
  /// 1. Client-Id
  /// 2. Request-Id
  /// 3. Request-Timestamp (ISO8601 UTC)
  /// 4. Request-Target (path endpoint, misal: /doku-virtual-account/v2/payment-code)
  /// 5. Digest (SHA-256 hash dari request body)
  ///
  /// Formula: HMACSHA256=Base64(HMAC-SHA256(SecretKey, componentString))
  static String generateSignature({
    required String clientId,
    required String requestId,
    required String requestTimestamp,
    required String requestTarget,
    required String digest,
    required String secretKey,
  }) {
    // Susun komponen dengan separator newline
    final componentString =
        'Client-Id:$clientId\n'
        'Request-Id:$requestId\n'
        'Request-Timestamp:$requestTimestamp\n'
        'Request-Target:$requestTarget\n'
        'Digest:$digest';

    // Hash menggunakan HMAC-SHA256 dengan Secret Key
    final hmac = Hmac(sha256, utf8.encode(secretKey));
    final signature = hmac.convert(utf8.encode(componentString));

    // Format akhir: HMACSHA256=<base64_encoded_signature>
    return 'HMACSHA256=${base64.encode(signature.bytes)}';
  }
}
