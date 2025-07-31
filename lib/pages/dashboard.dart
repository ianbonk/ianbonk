import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:sabiki_rental_car/models/photo_banner.dart';
import 'package:sabiki_rental_car/pages/detail.dart';
import 'package:sabiki_rental_car/models/Car.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  bool _showCarList = true;
  String? _selectedPickup;
  DateTime? _selectedStartDate;
  DateTime? _selectedEndDate;
  final Color primaryBlue = const Color.fromARGB(255, 1, 48, 86);
  final Color accentRed = const Color.fromARGB(255, 236, 46, 33);
  List<Car> _cars = [];
  List<Car> _filteredCars = [];
  List<PhotoBanner> _banners = [];
  bool _isLoading = false;
  String? _errorMessage;

  final PageController _bannerController = PageController();
  int _currentBannerPage = 0;

  @override
  void initState() {
    super.initState();
    fetchCars();
    fetchBanners();
  }

  Future<void> fetchBanners() async {
    try {
      final response = await http.get(
        Uri.parse(
            'https://sabikitransindonesia.com/api/banner'),
      );

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        final List<dynamic> bannerList = jsonData['data'];

        setState(() {
          _banners = bannerList.map((e) => PhotoBanner.fromJson(e)).toList();
        });
      } else {
        throw Exception('Failed to load banner');
      }
    } catch (e) {
      print('Error fetching banner: $e');
    }
  }

  Future<void> fetchCars() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
            'https://sabikitransindonesia.com/api/cars'),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final List<dynamic> jsonData = jsonDecode(response.body);
        setState(() {
          _cars = jsonData.map((json) => Car.fromJson(json)).toList();
          _filteredCars = _cars; // Tampilkan semua mobil saat pertama kali
        });
      } else {
        throw Exception(
            'Failed to load cars. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load cars: ${e.toString()}';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> filterAvailableCars() async {
    // Tampilkan semua mobil jika tanggal belum dipilih
    if (_selectedStartDate == null || _selectedEndDate == null) {
      setState(() {
        _filteredCars = _cars;
      });
      return;
    }

    final startDateStr = DateFormat('yyyy-MM-dd').format(_selectedStartDate!);
    final endDateStr = DateFormat('yyyy-MM-dd').format(_selectedEndDate!);

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await http.get(
        Uri.parse(
          'https://sabikitransindonesia.com/api/get-available-cars?start_date=$startDateStr&end_date=$endDateStr',
        ),
        headers: {'Connection': 'close'},
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        print('RAW API RESPONSE: $responseBody');
        final List<dynamic> availableCarsJson = responseBody['available_cars'];

        // Debug: Print the raw response
        print('API Response: $responseBody');

        // Langsung konversi JSON ke objek Car
        List<Car> filteredCars = [];

        for (final carJson in availableCarsJson) {
          // Debug: Print each car data
          print('Car JSON: $carJson');

          // Buat objek Car langsung dari JSON
          final car = Car.fromJson(carJson);
          filteredCars.add(car);

          // Debug: Print created car
          print('Created car: ${car.id} - ${car.brand} ${car.model} | '
              'Status: ${car.status}, available: ${car.isAvailable}');
        }

        setState(() {
          _filteredCars = filteredCars;
        });

        print('Filtered cars count: ${filteredCars.length}');
      } else {
        throw Exception(
            'Failed to filter cars. Status code: ${response.statusCode}');
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to filter cars: ${e.toString()}';
        _filteredCars = [];
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_errorMessage!)),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SizedBox.expand(
        child: Stack(
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(top: 40),
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Column(
                        children: [
                          SizedBox(
                            height: 160,
                            child: _banners.isNotEmpty
                                ? PageView.builder(
                                    controller: _bannerController,
                                    onPageChanged: (index) {
                                      setState(
                                          () => _currentBannerPage = index);
                                    },
                                    itemCount: _banners.length,
                                    itemBuilder: (context, index) {
                                      return ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          _banners[index].filePath ?? '',
                                          width: double.infinity,
                                          height: 160,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Image.asset(
                                            'assets/images/background.png',
                                            width: double.infinity,
                                            height: 160,
                                            fit: BoxFit.cover,
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                : ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.asset(
                                      'assets/images/background.png',
                                      width: double.infinity,
                                      height: 160,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                          ),
                          const SizedBox(height: 10),
                          if (_banners.length > 1)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(3, (index) {
                                return AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin:
                                      const EdgeInsets.symmetric(horizontal: 4),
                                  width: _currentBannerPage == index ? 12 : 8,
                                  height: _currentBannerPage == index ? 12 : 8,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _currentBannerPage == index
                                        ? primaryBlue
                                        : Colors.grey[400],
                                  ),
                                );
                              }),
                            ),
                        ],
                      ),
                    ),

                    SizedBox(height: 10),
                    // Dropdown Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16.0,
                              vertical: 20.40,
                            ),
                            height: 120,
                            decoration: BoxDecoration(
                              color: primaryBlue,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    // Pick Up Location
                                    Expanded(
                                      child: Padding(
                                        padding:
                                            const EdgeInsets.only(right: 4),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: accentRed,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 12.0,
                                                ),
                                              ),
                                              onPressed:
                                                  _showPickupLocationDialog,
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          _selectedPickup ??
                                                              'Pick Up Location',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                        const Text(
                                                          'Choose Pick Up Location',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 6,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.arrow_drop_down,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    // Date & Time
                                    Expanded(
                                      child: Padding(
                                        padding: const EdgeInsets.only(left: 4),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ElevatedButton(
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: accentRed,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(10),
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                  vertical: 12.0,
                                                  horizontal: 12.0,
                                                ),
                                              ),
                                              onPressed: () =>
                                                  _showDateTimeDialog(context),
                                              child: Row(
                                                mainAxisAlignment:
                                                    MainAxisAlignment
                                                        .spaceBetween,
                                                children: [
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .start,
                                                      children: [
                                                        Text(
                                                          _selectedStartDate !=
                                                                      null &&
                                                                  _selectedEndDate !=
                                                                      null
                                                              ? '${DateFormat('dd/MM/yy').format(_selectedStartDate!)} - ${DateFormat('dd/MM/yy').format(_selectedEndDate!)}'
                                                              : 'Date & Time',
                                                          style:
                                                              const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 10,
                                                          ),
                                                        ),
                                                        const Text(
                                                          'Choose Date & Time',
                                                          style: TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 6,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                  const Icon(
                                                    Icons.arrow_drop_down,
                                                    color: Colors.white,
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          // Floating Action Button
                          Positioned(
                            bottom: -35,
                            left: 0,
                            right: 0,
                            child: Center(
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    height: 60,
                                    width: 60,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Container(
                                    height: 50,
                                    width: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: accentRed,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.arrow_forward_outlined,
                                        color: Colors.white,
                                      ),
                                      onPressed: filterAvailableCars,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 40),

                    // Car and Location Buttons
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 40.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _showCarList
                                    ? Colors.white
                                    : Colors.grey[300],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _showCarList = true;
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  'CAR',
                                  style: TextStyle(
                                    color: _showCarList
                                        ? Colors.black
                                        : Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: !_showCarList
                                    ? Colors.white
                                    : Colors.grey[300],
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(100),
                                ),
                              ),
                              onPressed: () {
                                setState(() {
                                  _showCarList = false;
                                });
                              },
                              child: Padding(
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12.0),
                                child: Text(
                                  'LOCATION',
                                  style: TextStyle(
                                    color: !_showCarList
                                        ? Colors.black
                                        : Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Available Car List
                    if (_showCarList) ...[
                      const SizedBox(height: 20),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 40.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              '   Available Car',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_isLoading)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 40),
                          child: Center(
                            child: CircularProgressIndicator(),
                          ),
                        )
                      else if (_errorMessage != null)
                        _buildErrorWidget()
                      else if (_filteredCars.isEmpty)
                        _buildNoCarsWidget()
                      else
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 40.0),
                          child: Column(
                            children: _filteredCars.map((car) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _buildCarCard(car),
                              );
                            }).toList(),
                          ),
                        ),
                    ],

                    const SizedBox(height: 60),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildCarCard(Car car) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            // Left side - Car details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${car.brand} ${car.model}'.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.star, size: 16, color: Colors.amber),
                      const SizedBox(width: 4),
                      Text(
                        car.rating.toStringAsFixed(1),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.attach_money,
                          size: 16, color: Colors.black),
                      const SizedBox(width: 4),
                      Text(car.price),
                      const Spacer(),
                      Text(
                        '/day',
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Detail(carId: car.id),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accentRed,
                      minimumSize: const Size(double.infinity, 36),
                    ),
                    child: const Text(
                      'Detail',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Car image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                car.imageUrl ??
                    'https://via.placeholder.com/100x60?text=No+Image',
                width: 90,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Image.network(
                  'https://via.placeholder.com/100x60?text=No+Image',
                  width: 90,
                  height: 60,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoCarsWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          Icon(Icons.car_rental, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          const Text(
            'No cars available for selected dates',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            _selectedStartDate == null || _selectedEndDate == null
                ? 'Please select date range first'
                : 'Please try different dates or location',
            style: const TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: filterAvailableCars,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              _errorMessage ?? 'An error occurred',
              style: const TextStyle(fontSize: 16, color: Colors.red),
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: filterAvailableCars,
            style: ElevatedButton.styleFrom(
              backgroundColor: accentRed,
            ),
            child: const Text(
              'Try Again',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showPickupLocationDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Choose Pickup location'),
          content: SingleChildScrollView(
            child: Column(
              children: [
                _buildLocationOption('Pasuruan'),
                _buildLocationOption('Bangil'),
                _buildLocationOption('Pandaan'),
                _buildLocationOption('Purwosari'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationOption(String location) {
    return ListTile(
      title: Text(location),
      onTap: () {
        setState(() {
          _selectedPickup = location;
        });
        Navigator.pop(context);
      },
    );
  }

  Future<void> _showDateTimeDialog(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime(DateTime.now().year + 1),
      initialDateRange: DateTimeRange(
        start: _selectedStartDate ?? DateTime.now(),
        end: _selectedEndDate ?? DateTime.now().add(const Duration(days: 1)),
      ),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: ColorScheme.light(
              primary: primaryBlue,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Colors.black,
            ),
            dialogBackgroundColor: Colors.white,
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedStartDate = picked.start;
        _selectedEndDate = picked.end;
      });
    }
  }
}
