import 'dart:math';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EmailService {
  Future<String> sendOtp(String recipientEmail, String userName) async {
    // Generate 6 digit OTP
    final random = Random();
    final otp = (100000 + random.nextInt(900000)).toString();

    // Ambil kredensial dari file .env untuk keamanan Tugas Akhir
    final String email = dotenv.env['SMTP_EMAIL'] ?? 'your.email@gmail.com';
    final String password = dotenv.env['SMTP_PASSWORD'] ?? '';

    // Pastikan Anda menggunakan Gmail App Password (bukan password akun biasa)
    final smtpServer = gmail(email, password);

    final message = Message()
      ..from = Address(email, 'Smart Notes AI')
      ..recipients.add(recipientEmail)
      ..subject = 'Kode Verifikasi Anda - Smart Notes AI'
      ..html = '''
      <div style="font-family: Arial, sans-serif; color: #1E293B; max-width: 600px; margin: 0 auto; padding: 20px; border: 1px solid #E2E8F0; border-radius: 12px;">
        <div style="text-align: center; margin-bottom: 24px;">
          <h2 style="color: #4F64F2; margin: 0;">Smart Notes AI</h2>
        </div>
        <p>Halo <b>$userName</b>,</p>
        <p>Terima kasih telah mendaftar! Untuk menyelesaikan proses pendaftaran Anda, silakan gunakan kode verifikasi (OTP) berikut:</p>
        <div style="background-color: #F8FAFC; border: 1px dashed #4F64F2; padding: 16px; text-align: center; border-radius: 8px; margin: 24px 0;">
          <h1 style="color: #4F64F2; margin: 0; font-size: 32px; letter-spacing: 4px;">$otp</h1>
        </div>
        <p style="color: #64748B; font-size: 14px;">Kode ini akan kadaluarsa dalam waktu 10 menit. Jangan bagikan kode ini kepada siapa pun.</p>
        <br/>
        <p>Salam hangat,<br/><b>Tim Smart Notes AI</b></p>
      </div>
      ''';

    try {
      if (email == 'your.email@gmail.com' || email.isEmpty) {
        // Jika belum disetting, kita lempar exception atau return dummy untuk testing
        print('----------------------------------------------------');
        print('DUMMY OTP KARENA KREDENSIAL SMTP BELUM DIISI: $otp');
        print('----------------------------------------------------');
        throw Exception('Kredensial SMTP belum disetel di EmailService. Silakan perbarui file email_service.dart');
      }

      // Cetak ke console agar mudah dicek saat pengujian
      print('=================================');
      print('OTP BERHASIL DIBUAT: $otp');
      print('Mengirim email ke: $recipientEmail');
      print('=================================');

      await send(message, smtpServer);
      return otp;
    } catch (e) {
      if (e is Exception && e.toString().contains('Kredensial SMTP belum disetel')) {
        rethrow;
      }
      throw Exception('Gagal mengirim OTP: $e');
    }
  }
}
