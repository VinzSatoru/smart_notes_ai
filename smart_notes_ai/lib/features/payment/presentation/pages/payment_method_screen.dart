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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
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
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.3),
                      width: 1,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF0F172A).withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.workspace_premium_rounded, size: 48, color: Color(0xFFF59E0B)),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Smart Notes AI PRO',
                        style: TextStyle(
                          color: Colors.white, 
                          fontSize: 24, 
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Buka semua fitur cerdas tanpa batas.\nTermasuk Voice, Summarize, dan Translate.',
                        style: TextStyle(
                          color: Colors.white70, 
                          fontSize: 14,
                          height: 1.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 28),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                          ),
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                              blurRadius: 12,
                              offset: const Offset(0, 6),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            const Text(
                              'Rp',
                              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(width: 4),
                            const Text(
                              '15.000',
                              style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900, height: 1),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                // Pilih Metode Pembayaran
                Padding(
                  padding: const EdgeInsets.only(left: 4, bottom: 16),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 16,
                        decoration: BoxDecoration(
                          color: primaryColor,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'PILIH METODE PEMBAYARAN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),

                _buildBankCard(
                  bankName: 'BCA Virtual Account',
                  bankCode: 'BCA',
                  iconColor: const Color(0xFF005CAA),
                ),
                _buildBankCard(
                  bankName: 'Mandiri Virtual Account',
                  bankCode: 'MANDIRI',
                  iconColor: const Color(0xFF003A70),
                ),
                _buildBankCard(
                  bankName: 'BRI Virtual Account',
                  bankCode: 'BRI',
                  iconColor: const Color(0xFF00529C),
                ),
                _buildBankCard(
                  bankName: 'BNI Virtual Account',
                  bankCode: 'BNI',
                  iconColor: const Color(0xFFEF6C00),
                ),
                const SizedBox(height: 24),
              ],
            ),
    );
  }

  Widget _buildBankCard({
    required String bankName,
    required String bankCode,
    required Color iconColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: navyColor.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: navyColor.withValues(alpha: 0.04)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectBank(bankCode),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: navyColor.withValues(alpha: 0.06)),
                    boxShadow: [
                      BoxShadow(
                        color: navyColor.withValues(alpha: 0.02),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    bankCode,
                    style: TextStyle(
                      color: iconColor,
                      fontWeight: FontWeight.w900,
                      fontSize: bankCode.length > 3 ? 10 : 15,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        bankName,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: navyColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.check_circle_rounded, size: 12, color: Colors.green.shade600),
                          const SizedBox(width: 4),
                          Text(
                            'Otomatis terverifikasi',
                            style: TextStyle(
                              fontSize: 12,
                              color: navyColor.withValues(alpha: 0.5),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: navyColor.withValues(alpha: 0.05)),
                  ),
                  child: Icon(Icons.arrow_forward_rounded, size: 18, color: navyColor.withValues(alpha: 0.4)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
