// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'order_detail.dart';

class Process extends StatefulWidget {
  const Process({super.key});

  @override
  State<Process> createState() => _ProcessState();
}

class _ProcessState extends State<Process> {
  final Color primaryBlue = const Color.fromARGB(255, 1, 40, 72);
  bool showOperating = false;
  bool showCompleted = true;
  bool isLoading = true;
  String errorMessage = '';

  // Data akan diambil dari API
  List<dynamic> operatingOrders = [];
  List<dynamic> completedOrders = [];

  int? userId; 

  String _shortenOrderId(String orderId, {int maxLength = 8}) {
    if (orderId.length <= maxLength) {
      return orderId;
    }
    return '${orderId.substring(0, maxLength)}...';
  }

  @override
  void initState() {
    super.initState();
    _getUserId().then((_) {
      _fetchOrders();
    });
  }

  // Fungsi untuk mendapatkan user ID dari SharedPreferences
  Future<void> _getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userId = prefs.getInt('userId');
    });
  }

  Future<void> _fetchOrders() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      // Pastikan userId sudah didapatkan
      if (userId == null) {
        setState(() {
          errorMessage = 'User tidak terautentikasi';
          isLoading = false;
        });
        return;
      }

      // Tambahkan parameter user_id ke URL
      final response = await http.get(Uri.parse(
          'https://sabikitransindonesia.com/api/rentals-with-details?user_id=$userId'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          // Kelompokkan data berdasarkan status
          operatingOrders =
              data.where((order) => order['status'] == 'ongoing').toList();
          completedOrders = data
              .where((order) =>
                  order['status'] == 'completed' ||
                  order['status'] == 'overdue')
              .toList();
        });
      } else {
        setState(() {
          errorMessage = 'Gagal memuat data: ${response.statusCode}';
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = 'Terjadi kesalahan: $e';
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  // Fungsi untuk menerjemahkan status
  String _translateStatus(String status) {
    switch (status) {
      case 'ongoing':
        return 'Sedang beroperasi';
      case 'completed':
        return 'Selesai';
      case 'overdue':
        return 'Terlambat';
      default:
        return status;
    }
  }

  // Format tanggal dari API
  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 50),
                Row(
                  children: [
                    Expanded(
                      child: _buildStatusButton(
                        text: 'Sedang beroperasi',
                        isActive: showOperating,
                        onTap: () {
                          setState(() {
                            showOperating = true;
                            showCompleted = false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _buildStatusButton(
                        text: 'Telah selesai',
                        isActive: showCompleted,
                        onTap: () {
                          setState(() {
                            showOperating = false;
                            showCompleted = true;
                          });
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (isLoading)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100.0),
                      child: CircularProgressIndicator(),
                    ),
                  )
                else if (errorMessage.isNotEmpty)
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 100.0),
                      child: Text(
                        errorMessage,
                        style: TextStyle(color: Colors.red, fontSize: 16),
                      ),
                    ),
                  )
                else if (showOperating)
                  operatingOrders.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100.0),
                            child: Text(
                              'Tidak ada data sedang beroperasi',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (final order in operatingOrders) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(order['pickup_date']),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildOrderCard(order),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                if (showCompleted && !isLoading && errorMessage.isEmpty)
                  completedOrders.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.only(top: 100.0),
                            child: Text(
                              'Tidak ada data yang selesai',
                              style: TextStyle(
                                  color: Colors.grey[600], fontSize: 16),
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            for (final order in completedOrders) ...[
                              Padding(
                                padding: const EdgeInsets.only(bottom: 20.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _formatDate(order['pickup_date']),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    _buildOrderCard(order),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusButton({
    required String text,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? primaryBlue : Colors.white.withOpacity(0.9),
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isActive ? primaryBlue : Colors.grey.shade300,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Center(
          child: Text(
            text,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order) {
  // Handle jika ada data yang null
  final booking = order['booking'] ?? {};
  final customer = booking['customer'] ?? {};
  final car = booking['car'] ?? {};
  final payment = order['payment'] ?? {};

  return GestureDetector(
    onTap: () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => OrderDetail(order: order),
        ),
      );
    },
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: primaryBlue,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1),
            ),
            child: Icon(Icons.person, color: Colors.grey[600], size: 50),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  customer['name'] ?? 'Nama tidak tersedia',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  car['model'] ?? 'Mobil tidak tersedia',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Kode Pesanan : ${payment['order_id'] != null ? _shortenOrderId(payment['order_id']) : 'N/A'}',
                  style: const TextStyle(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  'Status : ${_translateStatus(order['status'])}',
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
}
