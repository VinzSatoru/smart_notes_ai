import 'package:flutter/material.dart';
import 'package:smart_notes_ai/features/payment/presentation/pages/payment_waiting_screen.dart';
import 'package:smart_notes_ai/features/payment/data/services/doku_payment_service.dart';
import 'package:smart_notes_ai/services/pocketbase_service.dart';
import 'package:smart_notes_ai/injection_container.dart';

class PaymentMethodScreen extends StatefulWidget {
  const PaymentMethodScreen({super.key});

  @override
  State<PaymentMethodScreen> createState() => _PaymentMethodScreenState();
}

class _PaymentMethodScreenState extends State<PaymentMethodScreen> {
  static const Color primaryColor = Color(0xFF4F64F2);
  static const Color navyColor = Color(0xFF1E293B);
  bool _isLoading = false;

  Future<void> _selectBank(String bankChannel) async {
    setState(() => _isLoading = true);

    try {
      final pbService = sl<PocketBaseService>();
      final currentUser = pbService.currentUser;

      if (currentUser == null) {
        throw Exception('Anda harus login terlebih dahulu.');
      }

      final invoiceNumber = 'INV-${DateTime.now().millisecondsSinceEpoch}';
      final service = DokuPaymentService();

      final result = await service.createVirtualAccount(
        bankChannel: bankChannel,
        invoiceNumber: invoiceNumber,
        amount: 15000,
        customerName: currentUser.getStringValue('name'),
        customerEmail: currentUser.getStringValue('email'),
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentWaitingScreen(paymentResult: result),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat VA: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: navyColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Upgrade Premium',
          style: TextStyle(color: navyColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4F64F2), Color(0xFF3B4CEB)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.star_rounded, size: 48, color: Colors.amber),
                      const SizedBox(height: 12),
                      const Text(
                        'Smart Notes AI PRO',
                        style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'AI Tanpa Batas — Voice, Summarize, Translate',
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Text(
                          'Rp 15.000',
                          style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),

                // Pilih Metode Pembayaran
                const Text(
                  'PILIH METODE PEMBAYARAN',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: navyColor,
                    letterSpacing: 1.2,
                  ),
                ),
                const SizedBox(height: 16),

                _buildBankCard(
                  bankName: 'BCA Virtual Account',
                  bankCode: 'BCA',
                  iconColor: const Color(0xFF003E7E),
                ),
                const SizedBox(height: 12),
                _buildBankCard(
                  bankName: 'Mandiri Virtual Account',
                  bankCode: 'MANDIRI',
                  iconColor: const Color(0xFF003A70),
                ),
                const SizedBox(height: 12),
                _buildBankCard(
                  bankName: 'BRI Virtual Account',
                  bankCode: 'BRI',
                  iconColor: const Color(0xFF00529C),
                ),
                const SizedBox(height: 12),
                _buildBankCard(
                  bankName: 'BNI Virtual Account',
                  bankCode: 'BNI',
                  iconColor: const Color(0xFFEF6C00),
                ),
              ],
            ),
    );
  }

  Widget _buildBankCard({
    required String bankName,
    required String bankCode,
    required Color iconColor,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () => _selectBank(bankCode),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: navyColor.withValues(alpha: 0.06)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  bankCode,
                  style: TextStyle(
                    color: iconColor,
                    fontWeight: FontWeight.bold,
                    fontSize: bankCode.length > 3 ? 9 : 12,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  bankName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: navyColor,
                  ),
                ),
              ),
              Icon(Icons.chevron_right_rounded, color: navyColor.withValues(alpha: 0.3)),
            ],
          ),
        ),
      ),
    );
  }
}
