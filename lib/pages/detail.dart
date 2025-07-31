import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:sabiki_rental_car/models/CarDetail.dart';
import 'package:sabiki_rental_car/pages/booking_page.dart';
import 'package:sabiki_rental_car/pages/customer_data_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Detail extends StatefulWidget {
  final int carId;

  const Detail({super.key, required this.carId});

  @override
  State<Detail> createState() => _DetailState();
}

class _DetailState extends State<Detail> {
  late Future<CarDetail> futureCarDetail;
  final Color primaryBlue = const Color.fromARGB(255, 1, 40, 72);
  double? averageRating;

  @override
  void initState() {
    super.initState();
    futureCarDetail = fetchCarDetail(widget.carId);
    fetchAverageRating(widget.carId);
  }

  Future<CarDetail> fetchCarDetail(int id) async {
    try {
      final response = await http.get(Uri.parse(
          'https://sabikitransindonesia.com/api/cars/$id'));

      if (response.statusCode == 200) {
        final decoded = json.decode(response.body);

        // Pastikan response sukses
        if (decoded['success'] != true) {
          throw Exception('API response indicates failure');
        }

        // Tambahkan rating ke data mobil
        decoded['data']['rating'] = averageRating ?? 4.5;
        return CarDetail.fromJson(decoded);
      } else {
        throw Exception('Failed to load car detail: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching car detail: $e');
    }
  }

  Future<void> fetchAverageRating(int carId) async {
    try {
      final response = await http.get(Uri.parse(
          'https://sabikitransindonesia.com/api/ratings/car/$carId/average'));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          averageRating =
              double.tryParse(data['average_rating'].toString()) ?? 4.7;
        });
      }
    } catch (e) {
      print('Error fetching rating: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: FutureBuilder<CarDetail>(
        future: futureCarDetail,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final car = snapshot.data!;
          return Stack(
            children: [
              // Main scrollable content
              SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Car image with back button and rating
                    _buildCarImageSection(car),

                    // Car details
                    _buildCarDetailsSection(car),

                    // Owner information
                    _buildOwnerSection(car),

                    // Distance information
                    _buildDistanceSection(car),

                    // Features grid
                    //_buildFeaturesSection(car),

                    _buildCategoriesSection(car),

                    // Spacer for floating button
                    const SizedBox(height: 80),
                  ],
                ),
              ),

              // Fixed Floating Button
              Positioned(
                bottom: 20,
                left: 24,
                right: 24,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  onPressed: () async {
                    try {
                      // Ambil user ID dari SharedPreferences
                      final prefs = await SharedPreferences.getInstance();
                      final userId = prefs.getInt('userId');

                      if (userId == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'User ID tidak ditemukan. Silakan login kembali.'),
                          ),
                        );
                        return;
                      }

                      // Cek apakah data customer sudah ada berdasarkan user_id
                      final response = await http.get(
                        Uri.parse(
                            'https://sabikitransindonesia.com/api/customers/user/$userId'),
                        headers: {'Accept': 'application/json'},
                      );

                      if (response.statusCode == 200) {
                        final data = json.decode(response.body);

                        if (data == null ||
                            data.isEmpty ||
                            data['id'] == null) {
                          // Data customer belum ada → arahkan ke form input customer
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => CustomerDataPage(
                                carId: widget.carId,
                                customerId: userId,
                              ),
                            ),
                          );
                        } else {
                          // Data customer ditemukan → ambil customer_id dan navigasi ke BookingPage
                          final customerId = data['id'];

                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => BookingPage(
                                carId: widget.carId,
                                customerId:
                                    customerId, // pakai customerId di sini
                              ),
                            ),
                          );
                        }
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Gagal mengambil data customer: ${response.statusCode}'),
                          ),
                        );
                      }
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Terjadi kesalahan: $e'),
                        ),
                      );
                    }
                  },
                  child: const Text(
                    'Reservasi Sekarang',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  // Car image section
  Widget _buildCarImageSection(CarDetail car) {
    double topPadding = MediaQuery.of(context).padding.top + 0;
    return Padding(
        padding: EdgeInsets.only(top: topPadding),
        child: Stack(
          children: [
            Image.network(
              car.imageUrl ??
                  'https://via.placeholder.com/300x200?text=No+Image',
              width: double.infinity,
              height: 220,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Image.asset(
                  'assets/toyota_camry.png',
                  width: double.infinity,
                  height: 220,
                  fit: BoxFit.cover,
                );
              },
            ),
            Positioned(
              top: MediaQuery.of(context).padding.top + 0,
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
            Positioned(
              bottom: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      car.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ));
  }

  // Car details section
  Widget _buildCarDetailsSection(CarDetail car) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${car.brand} ${car.model} ${car.year}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pasuruan',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'From Rp${car.pricePerDay.toStringAsFixed(0)}/hari',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: Colors.grey.withOpacity(0.3)),
      ],
    );
  }

  // Owner information section
  Widget _buildOwnerSection(CarDetail car) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          color: const Color.fromARGB(255, 255, 255, 255),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 30,
                backgroundColor: Colors.white,
                backgroundImage: AssetImage('assets/images/logojelajah.png'),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      car.ownerName ?? 'Sabiki Trans Indonesia',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Bergabung sejak ${car.joinDate ?? '2019'}',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      car.ownerLocation ?? 'Pasuruan, Jawa Timur',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: Colors.grey.withOpacity(0.3)),
      ],
    );
  }

  // Distance information section
  Widget _buildDistanceSection(CarDetail car) {
    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24.0),
          color: Colors.white,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
                car.description ?? 'Tidak ada deskripsi',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),
        Container(height: 1, color: Colors.grey.withOpacity(0.3)),
      ],
    );
  }

  // Features section
  // Widget _buildFeaturesSection(CarDetail car) {
  //   // List of features from API
  //   final List<String> features = car.features ?? [];

  //   return Container(
  //     width: double.infinity,
  //     padding: const EdgeInsets.all(24.0),
  //     color: Colors.white,
  //     child: Column(
  //       crossAxisAlignment: CrossAxisAlignment.start,
  //       children: [
  //         const Text(
  //           'Fasilitas',
  //           style: TextStyle(
  //             fontWeight: FontWeight.bold,
  //             fontSize: 16,
  //           ),
  //         ),
  //         const SizedBox(height: 16),
  //         GridView.count(
  //           shrinkWrap: true,
  //           physics: const NeverScrollableScrollPhysics(),
  //           crossAxisCount: 3,
  //           childAspectRatio: 1.2,
  //           children: features
  //               .map((feature) =>
  //                   _buildFeatureItem(_getFeatureIcon(feature), feature))
  //               .toList(),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  // Helper to get icon for feature
  // IconData _getFeatureIcon(String feature) {
  //   switch (feature.toLowerCase()) {
  //     case 'bluetooth':
  //       return Icons.bluetooth;
  //     case 'aux':
  //       return Icons.headset;
  //     case 'auto':
  //       return Icons.settings;
  //     case 'petrol 95':
  //       return Icons.local_gas_station;
  //     case '6 seater':
  //       return Icons.people;
  //     case '2wd':
  //       return Icons.directions_car;
  //     case 'smart tag':
  //       return Icons.tag;
  //     case 'no smoking':
  //       return Icons.smoke_free;
  //     case 'child seat':
  //       return Icons.child_friendly;
  //     default:
  //       return Icons.check;
  //   }
  // }

  // // Feature item widget
  // Widget _buildFeatureItem(IconData icon, String text, {bool enabled = true}) {
  //   return Column(
  //     mainAxisAlignment: MainAxisAlignment.center,
  //     children: [
  //       Icon(
  //         icon,
  //         size: 28,
  //         color: enabled ? Colors.black : Colors.grey,
  //       ),
  //       const SizedBox(height: 8),
  //       Text(
  //         text,
  //         textAlign: TextAlign.center,
  //         style: TextStyle(
  //           fontSize: 12,
  //           color: enabled ? Colors.black : Colors.grey,
  //         ),
  //       ),
  //     ],
  //   );
  // }

  Widget _buildCategoriesSection(CarDetail car) {
    final categories = car.categories;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24.0),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kategori Kendaraan',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 5),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 4,
            childAspectRatio: 0.9,
            children: categories.map((category) {
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(
                          0), // Bisa 0 kalau mau benar-benar kotak
                    ),
                    clipBehavior: Clip.hardEdge,
                    child: Image.network(
                      category.thumbnail ?? '',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Icon(Icons.error),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    category.name ?? '',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
