import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:smart_notes_ai/features/payment/data/services/doku_payment_service.dart';
import 'package:smart_notes_ai/features/payment/presentation/pages/payment_success_screen.dart';
import 'package:smart_notes_ai/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:smart_notes_ai/features/auth/presentation/bloc/auth_event.dart';
import 'package:smart_notes_ai/services/pocketbase_service.dart';
import 'package:smart_notes_ai/injection_container.dart';

class PaymentWaitingScreen extends StatefulWidget {
  final DokuPaymentResult paymentResult;

  const PaymentWaitingScreen({super.key, required this.paymentResult});

  @override
  State<PaymentWaitingScreen> createState() => _PaymentWaitingScreenState();
}

class _PaymentWaitingScreenState extends State<PaymentWaitingScreen> {
  static const Color primaryColor = Color(0xFF4F64F2);
  static const Color navyColor = Color(0xFF1E293B);

  Timer? _pollingTimer;
  int _remainingMinutes = 60;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startPolling();
    _startCountdown();
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    _countdownTimer?.cancel();
    super.dispose();
  }

  /// Polling DOKU setiap 5 detik untuk mengecek status pembayaran
  void _startPolling() {
    _pollingTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      final service = DokuPaymentService();
      final isPaid = await service.checkPaymentStatus(
        widget.paymentResult.invoiceNumber,
      );

      if (isPaid && mounted) {
        timer.cancel();
        _countdownTimer?.cancel();
        await _handlePaymentSuccess();
      }
    });
  }

  /// Countdown timer untuk menampilkan sisa waktu pembayaran
  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      if (_remainingMinutes > 0) {
        setState(() => _remainingMinutes--);
      } else {
        timer.cancel();
        _pollingTimer?.cancel();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Waktu pembayaran telah habis.'),
              backgroundColor: Colors.red,
            ),
          );
          Navigator.pop(context);
        }
      }
    });
  }

  /// Proses setelah pembayaran terdeteksi sukses
  Future<void> _handlePaymentSuccess() async {
    try {
      final pbService = sl<PocketBaseService>();
      final user = pbService.currentUser;

      if (user != null) {
        // Update tier ke 'pro' di PocketBase
        await pbService.pb.collection('users').update(user.id, body: {
          'tier': 'pro',
        });

        // Refresh AuthStore lokal
        await pbService.pb.collection('users').authRefresh();

        // Refresh AuthBloc agar seluruh app tahu
        if (mounted) {
          context.read<AuthBloc>().add(AuthRefreshUserRequested());
        }
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const PaymentSuccessScreen()),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = NumberFormat('#,###', 'id_ID');
    final formattedAmount = formatter.format(widget.paymentResult.amount);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: navyColor),
          onPressed: () {
            _pollingTimer?.cancel();
            _countdownTimer?.cancel();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Menunggu Pembayaran',
          style: TextStyle(color: navyColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Status Indicator
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.amber.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.amber.shade200),
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation(Colors.amber.shade700),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Menunggu Pembayaran...',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Sisa waktu: $_remainingMinutes menit',
                        style: TextStyle(fontSize: 12, color: Colors.amber.shade800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // VA Details Card
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: navyColor.withValues(alpha: 0.06)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Bank Channel
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.paymentResult.bankChannel,
                        style: const TextStyle(
                          color: primaryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'Virtual Account',
                      style: TextStyle(
                        color: navyColor.withValues(alpha: 0.4),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Nomor VA
                Text(
                  'Nomor Virtual Account',
                  style: TextStyle(
                    color: navyColor.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.paymentResult.vaNumber,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(
                          ClipboardData(text: widget.paymentResult.vaNumber),
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Nomor VA disalin!'),
                            behavior: SnackBarBehavior.floating,
                            duration: Duration(seconds: 2),
                          ),
                        );
                      },
                      icon: const Icon(Icons.copy_rounded, color: primaryColor),
                      tooltip: 'Salin Nomor VA',
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Divider(),
                const SizedBox(height: 16),

                // Jumlah Pembayaran
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Pembayaran',
                      style: TextStyle(
                        color: navyColor.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      'Rp $formattedAmount',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Instruksi
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: navyColor.withValues(alpha: 0.06)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cara Pembayaran:',
                  style: TextStyle(fontWeight: FontWeight.bold, color: navyColor),
                ),
                const SizedBox(height: 12),
                _buildStep('1', 'Buka aplikasi mobile banking atau ATM bank pilihan Anda'),
                _buildStep('2', 'Pilih menu Transfer → Virtual Account'),
                _buildStep('3', 'Masukkan nomor Virtual Account di atas'),
                _buildStep('4', 'Konfirmasi dan selesaikan pembayaran'),
                _buildStep('5', 'Layar ini akan otomatis berubah saat pembayaran terdeteksi'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(
                color: primaryColor,
                fontSize: 12,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: navyColor.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
