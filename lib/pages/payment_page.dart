import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'payment_success_page.dart';

class PaymentPage extends StatefulWidget {
  final int carId;
  final DateTime pickupDate;
  final DateTime returnDate;
  final bool withDriver;
  final double totalPrice;
  final Map<String, dynamic>? discount;
  final int bookingId;

  const PaymentPage({
    super.key,
    required this.carId,
    required this.pickupDate,
    required this.returnDate,
    required this.withDriver,
    required this.totalPrice,
    this.discount,
    required this.bookingId,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  final Color primaryBlue = const Color.fromARGB(255, 1, 40, 72);
  bool _isPaying = false;
  String? _qrCodeUrl;
  String? _paymentStatus;
  // ignore: unused_field
  int? _paymentId;
  String? _orderId;
  final String baseUrl =
      'https://sabikitransindonesia.com'; // GANTI DENGAN DOMAIN ANDA
  Timer? _paymentStatusTimer;
  bool _isCheckingStatus = false;
  String? _notificationStatus;

  @override
  void initState() {
    super.initState();
    _initPaymentProcess();
  }

  @override
  void dispose() {
    _paymentStatusTimer?.cancel();
    super.dispose();
  }

  Future<String?> _getAuthToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  void _initPaymentProcess() {
    _generateQRCode();
  }

  Future<void> _generateQRCode() async {
    setState(() => _isPaying = true);

    try {
      final token = await _getAuthToken();
      if (token == null) {
        throw Exception('User not authenticated');
      }

      // Create payment with booking ID
      final response = await http.post(
        Uri.parse('$baseUrl/api/payments'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({
          'booking_id': widget.bookingId,
          'amount': widget.totalPrice,
          'payment_method': 'qris',
        }),
      );

      if (response.statusCode == 201) {
        final data = json.decode(response.body);
        setState(() {
          _qrCodeUrl = data['qr_url'];
          _paymentStatus = data['payment']['status'];
          _paymentId = data['payment']['id'];
          _orderId = data['payment']['order_id'];
          _isPaying = false;
        });
      } else {
        throw Exception(
            'Failed to create payment: ${response.statusCode}\n${response.body}');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
      setState(() => _isPaying = false);
    }
  }

  Future<void> _checkPaymentStatus() async {
    if (_isCheckingStatus || _orderId == null) return;

    setState(() => _isCheckingStatus = true);

    try {
      final token = await _getAuthToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('$baseUrl/api/payments/midtrans-status/$_orderId'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['payment_status'] != _paymentStatus) {
          setState(() => _paymentStatus = data['payment_status']);
          print('Response from midtrans-status: $data');
          print('Payment status from server: ${data['payment_status']}');

          if (['paid', 'settlement', 'capture']
              .contains(data['payment_status'])) {
            _navigateToSuccessPage();
          }
        }
      } else if (response.statusCode >= 400) {
        setState(() => _notificationStatus =
            'Error ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() => _notificationStatus = 'Connection error: $e');
      if (kDebugMode) {
        print('Error checking payment status: $e');
      }
    } finally {
      setState(() => _isCheckingStatus = false);
    }
  }

  void _navigateToSuccessPage() {
    if (mounted) {
      _paymentStatusTimer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentSuccessPage(
            carId: widget.carId,
            bookingDate: DateTime.now(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final duration = widget.returnDate.difference(widget.pickupDate).inDays;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pembayaran'),
        backgroundColor: primaryBlue,
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/background.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Ringkasan Order
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Ringkasan Pesanan',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildSummaryItem('Tanggal Pengambilan',
                          DateFormat('dd/MM/yyyy').format(widget.pickupDate)),
                      _buildSummaryItem('Tanggal Pengembalian',
                          DateFormat('dd/MM/yyyy').format(widget.returnDate)),
                      _buildSummaryItem('Durasi', '$duration Hari'),
                      _buildSummaryItem(
                          'Biaya Tambahan', widget.withDriver ? 'Ya' : 'Tidak'),
                      if (widget.discount != null)
                        _buildSummaryItem(
                            'Diskon Terpakai', widget.discount!['code']),
                      const Divider(height: 24, thickness: 1),
                      _buildSummaryItem('Total Pembayaran',
                          'Rp ${NumberFormat('#,###').format(widget.totalPrice)}',
                          isBold: true, textColor: primaryBlue),
                    ],
                  ),
                ),

                const SizedBox(height: 30),

                // Metode Pembayaran
                const Text(
                  'Lakukan Pembayaran dengan Qris',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      if (_isPaying)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Color(0xFF012848)),
                              ),
                              SizedBox(height: 20),
                              Text(
                                'Mempersiapkan pembayaran...',
                                style: TextStyle(fontSize: 16),
                              ),
                            ],
                          ),
                        )
                      else if (_qrCodeUrl != null)
                        Column(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey.shade300),
                              ),
                              child: Image.network(
                                _qrCodeUrl!,
                                width: 220,
                                height: 220,
                                fit: BoxFit.contain,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return const SizedBox(
                                    width: 220,
                                    height: 220,
                                    child: Center(
                                        child: CircularProgressIndicator()),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return const Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.error,
                                          color: Colors.red, size: 40),
                                      SizedBox(height: 10),
                                      Text('Gagal memuat QR Code'),
                                    ],
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),
                            const Text(
                              'Scan QR code di atas untuk melakukan pembayaran',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                            const SizedBox(height: 10),
                            ElevatedButton(
                              onPressed: _isCheckingStatus
                                  ? null
                                  : _checkPaymentStatus,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                disabledBackgroundColor: Colors.grey,
                              ),
                              child: _isCheckingStatus
                                  ? const Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                            color: Colors.white,
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Text('Memeriksa...'),
                                      ],
                                    )
                                  : const Text('Cek Status Pembayaran'),
                            ),
                          ],
                        )
                      else
                        Column(
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 60),
                            const SizedBox(height: 16),
                            const Text(
                              'Gagal memuat QR Code',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: Colors.red,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const Text(
                              'Terjadi kesalahan saat memproses pembayaran',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                            const SizedBox(height: 20),
                            ElevatedButton(
                              onPressed: _generateQRCode,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryBlue,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 32, vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: const Text('Coba Lagi'),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),

                      // Status Pembayaran
                      if (_paymentStatus != null)
                        _buildStatusIndicator(_paymentStatus!),

                      // Status Notifikasi
                      if (_notificationStatus != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                vertical: 12, horizontal: 16),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.red.shade200,
                              ),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.warning,
                                  color: Colors.red,
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    'Notifikasi: $_notificationStatus',
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.red,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 30),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(String status) {
    Color bgColor;
    Color borderColor;
    Color textColor;
    IconData icon;
    String message;

    switch (status) {
      case 'settlement':
      case 'capture':
        bgColor = Colors.green.shade50;
        borderColor = Colors.green.shade200;
        textColor = Colors.green;
        icon = Icons.check_circle;
        message = 'Pembayaran Berhasil!';
        break;
      case 'pending':
        bgColor = Colors.orange.shade50;
        borderColor = Colors.orange.shade200;
        textColor = Colors.orange;
        icon = Icons.access_time;
        message = 'Menunggu Pembayaran';
        break;
      case 'expire':
        bgColor = Colors.red.shade50;
        borderColor = Colors.red.shade200;
        textColor = Colors.red;
        icon = Icons.error;
        message = 'Pembayaran Kadaluarsa';
        break;
      default:
        bgColor = Colors.grey.shade50;
        borderColor = Colors.grey.shade300;
        textColor = Colors.grey;
        icon = Icons.help;
        message = 'Status: $status';
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: borderColor,
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor),
          const SizedBox(width: 12),
          Text(
            message,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value,
      {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 15,
              color: Colors.black54,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: textColor ?? Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}
