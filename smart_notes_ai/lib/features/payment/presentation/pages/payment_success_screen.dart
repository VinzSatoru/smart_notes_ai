import 'package:flutter/material.dart';

class PaymentSuccessScreen extends StatelessWidget {
  const PaymentSuccessScreen({super.key});

  static const Color primaryColor = Color(0xFF4F64F2);
  static const Color navyColor = Color(0xFF1E293B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              // Ikon Sukses
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: Colors.green.shade400,
                ),
              ),
              const SizedBox(height: 32),
              const Text(
                'Pembayaran Berhasil!',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: navyColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'Terima kasih! Anda telah membeli Premium.\nNikmati akses AI tanpa batas sekarang juga! 🎉',
                style: TextStyle(
                  fontSize: 15,
                  color: navyColor.withValues(alpha: 0.6),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Fitur yang didapat
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    _buildFeature(Icons.mic_rounded, 'Voice-to-Text Tanpa Batas'),
                    const SizedBox(height: 12),
                    _buildFeature(Icons.auto_awesome_rounded, 'Summarize Tanpa Batas'),
                    const SizedBox(height: 12),
                    _buildFeature(Icons.translate_rounded, 'Translate Kapan Saja'),
                  ],
                ),
              ),

              const Spacer(),

              // Tombol kembali
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () {
                    // Pop sampai ke Home Screen
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Mulai Gunakan PRO',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeature(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, color: primaryColor, size: 22),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: navyColor),
          ),
        ),
        const Icon(Icons.check_circle_rounded, color: Colors.green, size: 20),
      ],
    );
  }
}
