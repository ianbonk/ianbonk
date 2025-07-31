import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:sabiki_rental_car/models/CarDetail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OrderDetail extends StatefulWidget {
  final Map<String, dynamic> order;

  const OrderDetail({super.key, required this.order});

  @override
  State<OrderDetail> createState() => _OrderDetailState();
}

class _OrderDetailState extends State<OrderDetail> {
  String? userName;
  bool _isLoadingName = true;
  late Future<CarDetail> futureCarDetail;
  final String baseUrl =
      'https://sabikitransindonesia.com';
  final primaryBlue = const Color(0xFF012848);

  @override
  void initState() {
    super.initState();
    _loadUserName();
    final carData = widget.order['booking']?['car'] ?? {};
    final carId = carData['id'] is int
        ? carData['id']
        : (carData['id'] is String ? int.tryParse(carData['id']) ?? 0 : 0);

    print('Fetching car detail for ID: $carId');
    futureCarDetail = fetchCarDetail(carId);
  }

  Future<void> _loadUserName() async {
    setState(() {
      _isLoadingName = true;
      userName = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getInt('userId');

      if (userId == null) {
        setState(() {
          userName = 'Guest';
          _isLoadingName = false;
        });
        return;
      }

      // Check SharedPreferences first
      final savedName = prefs.getString('user_name');

      if (savedName != null && savedName.isNotEmpty) {
        setState(() {
          userName = savedName;
          _isLoadingName = false;
        });
        return;
      }

      // If not in SharedPreferences, fetch from API
      final response = await http.get(
        Uri.parse('$baseUrl/api/user-profile/$userId'),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final name = jsonData['name']?.toString() ?? 'Guest';

        await prefs.setString('user_name', name);

        if (mounted) {
          setState(() {
            userName = name;
            _isLoadingName = false;
          });
        }
      } else {
        setState(() {
          userName = 'Guest';
          _isLoadingName = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user name: $e');
      if (mounted) {
        setState(() {
          userName = 'Guest';
          _isLoadingName = false;
        });
      }
    }
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
        description: '',
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
    final pickupLocation =
        widget.order['pickup_location']?.toString() ?? 'Tangerang';
    final returnLocation =
        widget.order['return_location']?.toString() ?? 'Bandung';
    final pickupDate = widget.order['pickup_date']?.toString();
    final returnDate = widget.order['return_date']?.toString();
    final amount = payment['amount'] is num ? payment['amount'] as num : 300000;
    final paymentStatus = payment['status']?.toString() ?? 'pending';
    final userName = widget.order['booking']['customer']['name'] ?? 'Guest';

    return Scaffold(
      backgroundColor: Colors.grey[100],
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
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: primaryBlue,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 4,
                            offset: const Offset(0, 2)),
                      ],
                    ),
                    child: Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child:
                              const Icon(Icons.arrow_back, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        const CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            child: Icon(Icons.person)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ' ${userName}',
                                style: const TextStyle(
                                    color: Colors.white, fontSize: 16),
                              ),
                              Text(
                                '${car['brand'] ?? ''} ${car['model'] ?? ''} ${car['year'] ?? ''}',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Expanded(
                  child: FutureBuilder<CarDetail>(
                    future: futureCarDetail,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
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

                      return SingleChildScrollView(
                        child: Container(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black12, blurRadius: 4)
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: const BorderRadius.only(
                                    topLeft: Radius.circular(16),
                                    topRight: Radius.circular(16)),
                                child: carDetail.imageUrl != null
                                    ? Image.network(carDetail.imageUrl!,
                                        height: 200,
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                        errorBuilder:
                                            (context, error, stackTrace) =>
                                                _buildPlaceholderImage())
                                    : _buildPlaceholderImage(),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Detail Pesanan',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 5),
                              Container(height: 1, color: Colors.grey[300]),
                              const SizedBox(height: 5),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  carDetail.description ??
                                      'Tidak ada deskripsi',
                                  style: TextStyle(color: Colors.grey[600]),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildDetailItem(
                                      title: 'Kode Pesanan',
                                      value: payment['order_id']?.toString() ??
                                          'N/A',
                                    ),
                                    _buildDetailItem(
                                      title: 'Total Pembayaran',
                                      value: payment['amount'] != null
                                          ? 'Rp${NumberFormat("#,###").format(double.tryParse(payment['amount'].toString()) ?? 0)} '
                                              '(${_translatePaymentStatus(payment['status']?.toString() ?? 'N/A')})'
                                          : 'N/A',
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 16),
                              Container(height: 1, color: Colors.grey[300]),
                              Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(children: [
                                      Text(_formatDateOnly(pickupDate)),
                                      Text(_formatTimeOnly(pickupDate)),
                                      Text('${_calculateDays()} hari')
                                    ]),
                                    const Icon(Icons.arrow_forward),
                                    Column(
                                      children: [
                                        Text(_formatDateOnly(returnDate)),
                                        Text(_formatTimeOnly(returnDate)),
                                        Text('${_calculateDays()} hari')
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      height: 180,
      width: double.infinity,
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

  String _formatDateOnly(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatTimeOnly(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/A';

    try {
      final date = DateTime.parse(dateString);
      return DateFormat('HH:mm').format(date);
    } catch (e) {
      return dateString;
    }
  }

  int _calculateDays() {
    try {
      final pickup =
          DateTime.parse(widget.order['pickup_date']?.toString() ?? '');
      final returnDate =
          DateTime.parse(widget.order['return_date']?.toString() ?? '');
      return returnDate.difference(pickup).inDays;
    } catch (e) {
      return 1;
    }
  }

  String _translatePaymentStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return 'Lunas';
      case 'pending':
        return 'Menunggu Pembayaran';
      case 'failed':
        return 'Gagal';
      default:
        return status;
    }
  }
}
