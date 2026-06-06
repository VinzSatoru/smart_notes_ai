import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:smart_notes_ai/core/constants/api_constants.dart';
import 'package:smart_notes_ai/features/payment/data/services/doku_signature_helper.dart';

/// Model hasil pembuatan Virtual Account dari DOKU
class DokuPaymentResult {
  final String vaNumber;
  final String bankChannel;
  final String invoiceNumber;
  final int amount;
  final String? expiryTime;

  DokuPaymentResult({
    required this.vaNumber,
    required this.bankChannel,
    required this.invoiceNumber,
    required this.amount,
    this.expiryTime,
  });
}

/// Service untuk berkomunikasi langsung dengan DOKU API v2 (Server-to-Server).
///
/// ⚠️ PERINGATAN: Lihat komentar di doku_signature_helper.dart
/// mengenai keamanan Client Secret di sisi client.
class DokuPaymentService {
  /// Mapping channel bank ke endpoint DOKU
  static const Map<String, String> _bankEndpoints = {
    'BCA': '/bca-virtual-account/v2/payment-code',
    'MANDIRI': '/mandiri-virtual-account/v2/payment-code',
    'BRI': '/bri-virtual-account/v2/payment-code',
    'BNI': '/bni-virtual-account/v2/payment-code',
  };

  /// Membuat Virtual Account pembayaran baru via DOKU API.
  Future<DokuPaymentResult> createVirtualAccount({
    required String bankChannel,
    required String invoiceNumber,
    required int amount,
    required String customerName,
    required String customerEmail,
  }) async {
    final requestTarget = _bankEndpoints[bankChannel.toUpperCase()];
    if (requestTarget == null) {
      throw Exception('Bank channel "$bankChannel" tidak didukung.');
    }

    // 1. Siapkan request body
    final body = jsonEncode({
      'order': {
        'invoice_number': invoiceNumber,
        'amount': amount,
      },
      'virtual_account_info': {
        'expired_time': 60, // Expired dalam 60 menit
        'reusable_status': false,
        'info1': 'Smart Notes AI Premium',
      },
      'customer': {
        'name': customerName,
        'email': customerEmail,
      },
    });

    // 2. Generate komponen keamanan
    final clientId = ApiConstants.dokuClientId;
    final secretKey = ApiConstants.dokuSecretKey;
    final requestId = _generateRequestId();
    final timestamp = _generateTimestamp();
    final digest = DokuSignatureHelper.generateDigest(body);
    final signature = DokuSignatureHelper.generateSignature(
      clientId: clientId,
      requestId: requestId,
      requestTimestamp: timestamp,
      requestTarget: requestTarget,
      digest: digest,
      secretKey: secretKey,
    );

    // 3. Kirim HTTP POST ke DOKU
    final url = '${ApiConstants.dokuBaseUrl}$requestTarget';
    final response = await http.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Client-Id': clientId,
        'Request-Id': requestId,
        'Request-Timestamp': timestamp,
        'Signature': signature,
      },
      body: body,
    );

    // 4. Proses respons
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body);

      final vaInfo = json['virtual_account_info'];
      final orderInfo = json['order'];

      return DokuPaymentResult(
        vaNumber: vaInfo?['virtual_account_number'] ?? 'N/A',
        bankChannel: bankChannel.toUpperCase(),
        invoiceNumber: orderInfo?['invoice_number'] ?? invoiceNumber,
        amount: amount,
        expiryTime: vaInfo?['expired_date'],
      );
    } else {
      throw Exception(
        'DOKU API Error (${response.statusCode}): ${response.body}',
      );
    }
  }

  /// Cek apakah pembayaran untuk invoice tertentu sudah lunas.
  Future<bool> checkPaymentStatus(String invoiceNumber) async {
    try {
      final requestTarget = '/orders/v1/status/$invoiceNumber';
      final clientId = ApiConstants.dokuClientId;
      final secretKey = ApiConstants.dokuSecretKey;
      final requestId = _generateRequestId();
      final timestamp = _generateTimestamp();

      // GET request — signature tanpa Digest
      final componentString =
          'Client-Id:$clientId\n'
          'Request-Id:$requestId\n'
          'Request-Timestamp:$timestamp\n'
          'Request-Target:$requestTarget';

      final hmac = Hmac(sha256, utf8.encode(secretKey));
      final sig = hmac.convert(utf8.encode(componentString));
      final signature = 'HMACSHA256=${base64.encode(sig.bytes)}';

      final url = '${ApiConstants.dokuBaseUrl}$requestTarget';
      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Client-Id': clientId,
          'Request-Id': requestId,
          'Request-Timestamp': timestamp,
          'Signature': signature,
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final status = json['transaction']?['status'];
        return status == 'SUCCESS' || status == 'PAID';
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Generate Request-Id unik
  String _generateRequestId() {
    final now = DateTime.now().millisecondsSinceEpoch;
    return 'REQ-$now-${now % 99999}';
  }

  /// Generate timestamp ISO8601 UTC
  String _generateTimestamp() {
    return '${DateTime.now().toUtc().toIso8601String().split('.').first}Z';
  }
}
