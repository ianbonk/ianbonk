import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sabiki_rental_car/models/CarDetail.dart';

class OrderDetail extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetail({super.key, required this.order});

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  late Future<CarDetail> futureCarDetail;
  final String baseUrl =
      'https://sabikitransindonesia.com';

  @override
  void initState() {
    super.initState();
    // Ambil ID mobil dari data pesanan
    final carData = widget.order['booking']?['car'] ?? {};
    final carId = carData['id'] is int
        ? carData['id']
        : (carData['id'] is String ? int.tryParse(carData['id']) ?? 0 : 0);

    print('Fetching car detail for ID: $carId');
    futureCarDetail = fetchCarDetail(carId);
  }

  Future<CarDetail> fetchCarDetail(int id) async {
    if (id <= 0) {
      print('Invalid car ID: $id');
      return CarDetail(
        id: 0,
        brand: '',
        model: '',
        year: 0,
        pricePerDay: 0,
        categories: [],
        imageUrl: null,
        rating: 0,
      );
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/cars/$id'),
        headers: {'Accept': 'application/json'},
      );

      print('API Response: ${response.statusCode}');
      print('Response Body: ${response.body}');

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);
        if (decoded['success'] == true) {
          return CarDetail.fromJson(decoded);
        } else {
          throw Exception('API response not successful: ${decoded['message']}');
        }
      } else {
        throw Exception('HTTP error ${response.statusCode}');
      }
    } catch (e) {
      print('Error fetching car details: $e');
      return CarDetail(
        id: 0,
        brand: '',
        model: '',
        year: 0,
        pricePerDay: 0,
        categories: [],
        imageUrl: null,
        rating: 0,
        description: '',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.order['booking'] ?? {};
    final car = booking['car'] ?? {};
    final payment = widget.order['payment'] ?? {};

    return Scaffold(
      body: Column(
        children: [
          // Bagian gambar mobil
          SizedBox(
            height: 220,
            child: FutureBuilder<CarDetail>(
              future: futureCarDetail,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Container(
                    color: Colors.grey[200],
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                final carDetail = snapshot.data ??
                    CarDetail(
                      id: 0,
                      brand: '',
                      model: '',
                      year: 0,
                      pricePerDay: 0,
                      categories: [],
                      imageUrl: null,
                      rating: 0,
        description: '',
                    );

                final imageUrl = carDetail.imageUrl;

                return Stack(
                  children: [
                    // Gambar utama
                    if (imageUrl != null && imageUrl.isNotEmpty)
                      Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _buildPlaceholderImage();
                        },
                      )
                    else
                      _buildPlaceholderImage(),

                    // Tombol back
                    Positioned(
                      top: MediaQuery.of(context).padding.top + 10,
                      left: 10,
                      child: GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // Bagian detail pesanan (scrollable)
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Judul mobil
                    Text(
                      car['model']?.toString() ?? 'Mobil tidak tersedia',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Lokasi
                    Text(
                      'Pasuruan',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Detail Pesanan
                    const Text(
                      'Detail Pesanan',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Informasi Pesanan
                    _buildDetailItem(
                      title: 'Kode Pesanan',
                      value: payment['order_id']?.toString() ?? 'N/A',
                    ),

                    _buildDetailItem(
                      title: 'Total Pembayaran',
                      value: payment['amount'] != null
                          ? 'Rp${NumberFormat("#,###").format(double.tryParse(payment['amount'].toString()) ?? 0)} '
                              '(${_translatePaymentStatus(payment['status']?.toString() ?? 'N/A')})'
                          : 'N/A',
                    ),

                    const SizedBox(height: 16),

                    // Jarak Tempuh
                    const Text(
                      'Deskripsi',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      //'Jarak tempuh maksimal yang diperbolehkan adalah 400km per hari. Penggunaan yang melebihi batasan akan dikenakan sebesar Rp.1500 per km.',
                      car['description']?.toString() ?? 'Tidak ada deskripsi',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Periode Sewa
                    const Text(
                      'Periode Sewa',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _buildDateItem(
                            title: 'Pickup',
                            value: _formatDate(
                                widget.order['pickup_date']?.toString()),
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: Icon(Icons.arrow_forward, size: 20),
                        ),
                        Expanded(
                          child: _buildDateItem(
                            title: 'Kembali',
                            value: _formatDate(
                                widget.order['return_date']?.toString()),
                          ),
                        ),
                      ],
                    ),

                    // Tambahkan spacer untuk menghindari terpotong
                    const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      width: double.infinity,
      height: 220,
      color: Colors.grey[300],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.image_not_supported, size: 50, color: Colors.grey),
          const SizedBox(height: 10),
          Text(
            'Gambar tidak tersedia',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem({
    required String title,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateItem({
    required String title,
    required String value,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          title,
          style: TextStyle(
            color: Colors.grey[600],
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  String _formatDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy HH:mm:ss').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _translatePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Lunas';
      case 'pending':
        return 'Menunggu';
      case 'failed':
        return 'Gagal';
      default:
        return status;
    }
  }
}
