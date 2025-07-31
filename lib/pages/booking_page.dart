import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'payment_page.dart';

class BookingPage extends StatefulWidget {
  final int carId;
  final int customerId;

  const BookingPage({super.key, required this.carId, required this.customerId});

  @override
  State<BookingPage> createState() => _BookingPageState();
}

class _BookingPageState extends State<BookingPage> {
  final Color primaryBlue = const Color.fromARGB(255, 1, 40, 72);
  DateTime? _pickupDate;
  DateTime? _returnDate;
  String _pickupLocation = 'Pasuruan';
  String _returnLocation = 'Pasuruan';
  bool _withDriver = false;
  bool _isLoading = false;
  TextEditingController _discountController = TextEditingController();
  double _discountAmount = 0.0;
  Map<String, dynamic>? _appliedDiscount;
  String? _discountError;
  bool _isCheckingDiscount = false;
  List<dynamic> _drivers = [];
  int? _selectedDriverId;
  double? _carPrice;
  bool _isCheckingAvailability = false;
  String? _availabilityError;

  // Base URL untuk API
  final String _baseUrl = 'https://sabikitransindonesia.com';

  // Header untuk semua request API
  Map<String, String> get _apiHeaders {
    return {
      'ngrok-skip-browser-warning': 'true',
      'Content-Type': 'application/json'
    };
  }

  @override
  void initState() {
    super.initState();
    // Set default tanggal: pickup hari ini, return besok
    _pickupDate = DateTime.now();
    _returnDate = DateTime.now().add(const Duration(days: 1));
    _fetchCarDetail();
    _fetchAvailableDrivers();
  }

  Future<void> _fetchCarDetail() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/cars/${widget.carId}'),
        headers: _apiHeaders,
      );

      if (response.statusCode == 200) {
        final car = json.decode(response.body);
        setState(() {
          _carPrice = double.parse(car['price_per_day'].toString());
        });
      } else {
        print('Error fetching car detail: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching car detail: $e');
    }
  }

  Future<void> _fetchAvailableDrivers() async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/drivers'),
        headers: _apiHeaders,
      );

      if (response.statusCode == 200) {
        setState(() {
          _drivers = json.decode(response.body);
          if (_drivers.isNotEmpty) {
            _selectedDriverId = _drivers[0]['id'];
          }
        });
      } else {
        print('Error fetching drivers: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error fetching drivers: $e');
    }
  }

  Future<void> _selectDate(BuildContext context, bool isPickup) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: isPickup ? _pickupDate! : _returnDate!,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime:
            TimeOfDay.fromDateTime(isPickup ? _pickupDate! : _returnDate!),
      );

      if (pickedTime != null) {
        final DateTime picked = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        setState(() {
          if (isPickup) {
            _pickupDate = picked;
            // Default return: 1 hari + 1 jam setelah pickup
            //_returnDate = picked.add(const Duration(days: 1));
            _returnDate = DateTime(
              picked.year,
              picked.month,
              picked.day + 1, // tambah 1 hari dari picked
              23, // jam 23:00 (11 malam)
              0, // menit 0
            );
          } else {
            // Validasi: Return harus > Pickup
            if (!picked.isAfter(_pickupDate!)) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content:
                      Text('Jam pengembalian harus setelah jam pengambilan.'),
                ),
              );
            } else {
              _returnDate = picked;
            }
          }
        });
      }
    }
  }

  Future<bool> _checkCarAvailability() async {
    if (_pickupDate == null || _returnDate == null) return false;

    setState(() {
      _isCheckingAvailability = true;
      _availabilityError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/rentals/check-availability'),
        headers: _apiHeaders,
        body: json.encode({
          'car_id': widget.carId,
          'start_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(_pickupDate!),
          'end_date': DateFormat('yyyy-MM-dd').format(_returnDate!),
        }),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['available'] == true) {
          return true;
        } else {
          setState(() {
            _availabilityError = data['message'] ??
                'Mobil tidak tersedia untuk tanggal yang dipilih';
          });
          return false;
        }
      } else {
        setState(() {
          _availabilityError =
              'Error checking availability: ${response.statusCode}';
        });
        return false;
      }
    } catch (e) {
      setState(() {
        _availabilityError =
            'Terjadi kesalahan saat memeriksa ketersediaan: $e';
      });
      return false;
    } finally {
      setState(() {
        _isCheckingAvailability = false;
      });
    }
  }

  void _showAvailabilityErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mobil Tidak Tersedia'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  // int get _totalDays {
  //   if (_pickupDate == null || _returnDate == null) return 0;
  //   return _returnDate!.difference(_pickupDate!).inDays;
  // }

  int get _totalDays {
    if (_pickupDate == null || _returnDate == null) return 0;

    final diffInHours = _returnDate!.difference(_pickupDate!).inHours;

    // Minimal 1 hari
    if (diffInHours <= 24) {
      return 1;
    }

    // Untuk lebih dari 24 jam, hitung hari kalender (termasuk awal dan akhir)
    final pickupDateOnly =
        DateTime(_pickupDate!.year, _pickupDate!.month, _pickupDate!.day);
    final returnDateOnly =
        DateTime(_returnDate!.year, _returnDate!.month, _returnDate!.day);

    return returnDateOnly.difference(pickupDateOnly).inDays + 1;
  }

  double get _carPriceValue => _carPrice ?? 200000.0;
  double get _driverFee => _withDriver && _selectedDriverId != null
      ? double.parse(_drivers
          .firstWhere((driver) => driver['id'] == _selectedDriverId,
              orElse: () => {'driver_fee': '0'})['driver_fee']
          .toString())
      : 0.0;
  double get _subtotal => _carPriceValue * _totalDays;
  double get _discountedSubtotal => _subtotal - _discountAmount;
  double get _total => _discountedSubtotal + _driverFee;

  Future<void> _applyDiscount() async {
    if (_discountController.text.isEmpty) return;

    setState(() {
      _isCheckingDiscount = true;
      _discountError = null;
    });

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/discounts/check'),
        headers: _apiHeaders,
        body: json.encode({
          'code': _discountController.text,
          'subtotal': _subtotal,
        }),
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data['valid']) {
            setState(() {
              _discountAmount = data['discount_amount'].toDouble();
              _appliedDiscount = data['discount'];
              _discountError = null;
            });
          } else {
            setState(() => _discountError = data['error']);
          }
        } catch (e) {
          setState(() => _discountError = 'Invalid server response format');
        }
      } else {
        setState(() => _discountError = 'Server error: ${response.statusCode}');
      }
    } catch (e) {
      setState(() => _discountError = 'Terjadi kesalahan: $e');
    } finally {
      setState(() => _isCheckingDiscount = false);
    }
  }

  Future<void> _recordDiscountUsage(int bookingId) async {
    if (_appliedDiscount == null) return;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/discount-usages/record'),
        headers: _apiHeaders,
        body: json.encode({
          'discount_id': _appliedDiscount!['id'],
          'user_id': widget.customerId,
          'booking_id': bookingId,
          'subtotal': _subtotal,
        }),
      );

      if (response.statusCode == 201) {
        print('Discount usage recorded successfully');
      } else {
        print('Failed to record discount usage: ${response.statusCode}');
        print('Response body: ${response.body}');
      }
    } catch (e) {
      print('Error recording discount usage: $e');
    }
  }

  Future<Map<String, dynamic>> _createBooking() async {
    final response = await http.post(
      Uri.parse('$_baseUrl/bookings'),
      headers: _apiHeaders,
      body: json.encode({
        'customer_id': widget.customerId,
        'car_id': widget.carId,
        'discount_id': _appliedDiscount?['id'],
        'start_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(_pickupDate!),
        'end_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(_returnDate!),
        'status': 'pending',
        'pickup_location': _pickupLocation,
        'return_location': _returnLocation,
      }),
    );

    if (response.statusCode == 201) {
      return json.decode(response.body);
    }

    print('Failed to create booking: ${response.statusCode}');
    print('Response body: ${response.body}');
    throw Exception('Failed to create booking: ${response.statusCode}');
  }

  Future<void> _createRental(int bookingId) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/rentals'),
      headers: _apiHeaders,
      body: json.encode({
        'booking_id': bookingId,
        'pickup_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(_pickupDate!),
        'return_date': DateFormat('yyyy-MM-dd HH:mm:ss').format(_returnDate!),
        'status': 'pending',
        'driver_id': _withDriver ? _selectedDriverId : null,
        'pickup_location': _pickupLocation,
        'return_location': _returnLocation,
      }),
    );

    if (response.statusCode != 201) {
      print('Failed to create rental: ${response.statusCode}');
      print('Response body: ${response.body}');
      throw Exception('Failed to create rental: ${response.statusCode}');
    }
  }

  void _proceedToPayment() async {
    if (_pickupDate == null || _returnDate == null) {
      _showAvailabilityErrorDialog(
          'Pilih tanggal pengambilan dan pengembalian');
      return;
    }

    if (!_returnDate!.isAfter(_pickupDate!)) {
      _showAvailabilityErrorDialog(
          'Tanggal pengembalian harus setelah tanggal pengambilan');
      return;
    }

    if (_totalDays <= 0 || _total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Durasi sewa minimal 1 hari dan total pembayaran tidak boleh 0.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final available = await _checkCarAvailability();

      if (!available) {
        _showAvailabilityErrorDialog(_availabilityError ??
            'Mobil tidak tersedia untuk tanggal yang dipilih');
        return;
      }

      final booking = await _createBooking();
      final bookingId = booking['id'];

      await _createRental(bookingId);

      if (_appliedDiscount != null) {
        await _recordDiscountUsage(bookingId);
      }

      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PaymentPage(
            carId: widget.carId,
            pickupDate: _pickupDate!,
            returnDate: _returnDate!,
            withDriver: _withDriver,
            totalPrice: _total,
            discount: _appliedDiscount,
            bookingId: bookingId,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pemesanan Mobil'),
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
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detail Pemesanan',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),

                // Tanggal Pengambilan
                _buildDatePicker(
                  label: 'Tanggal Pengambilan',
                  date: _pickupDate,
                  onTap: () => _selectDate(context, true),
                ),

                const SizedBox(height: 20),

                // Tanggal Pengembalian
                _buildDatePicker(
                  label: 'Tanggal Pengembalian',
                  date: _returnDate,
                  onTap: () => _selectDate(context, false),
                ),

                // Tampilkan indikator loading atau error ketersediaan
                if (_isCheckingAvailability)
                  const Padding(
                    padding: EdgeInsets.only(top: 8),
                    child: Row(
                      children: [
                        SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator()),
                        SizedBox(width: 8),
                        Text('Memeriksa ketersediaan mobil...'),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Lokasi
                _buildLocationField(
                  label: 'Lokasi Pengambilan',
                  value: _pickupLocation,
                ),

                const SizedBox(height: 20),

                _buildLocationField(
                  label: 'Lokasi Pengembalian',
                  value: _returnLocation,
                ),

                const SizedBox(height: 20),

                // Driver Option
                SwitchListTile(
                  title: const Text('Opsi Tambahan'),
                  value: _withDriver,
                  onChanged: (value) => setState(() => _withDriver = value),
                  activeColor: primaryBlue,
                ),

                if (_withDriver && _drivers.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  _buildDriverDropdown(),
                ],

                const SizedBox(height: 20),

                // Discount Input
                _buildDiscountInput(),

                const SizedBox(height: 30),

                // Ringkasan Pembayaran
                _buildPaymentSummary(),

                const SizedBox(height: 30),

                // Tombol Lanjut
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _proceedToPayment,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Lanjut ke Pembayaran',
                            style: TextStyle(color: Colors.white, fontSize: 16),
                          ),
                  ),
                )
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDatePicker(
      {required String label, DateTime? date, required VoidCallback onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.grey),
                const SizedBox(width: 16),
                Text(
                  date != null
                      ? '${DateFormat('dd MMMM yyyy').format(date)} (${_getDayName(date)})'
                      : 'Pilih tanggal',
                  style: TextStyle(
                    color: date != null ? Colors.black : Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  String _getDayName(DateTime date) {
    return [
      'Minggu',
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu'
    ][date.weekday % 7];
  }

  Widget _buildLocationField({required String label, required String value}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value,
          items: ['Pasuruan', 'Bangil', 'Pandaan', 'Purwosari']
              .map((location) => DropdownMenuItem(
                    value: location,
                    child: Text(location),
                  ))
              .toList(),
          onChanged: (newValue) {
            if (newValue != null) {
              setState(() {
                if (label.contains('Pengambilan')) {
                  _pickupLocation = newValue;
                } else {
                  _returnLocation = newValue;
                }
              });
            }
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.location_on),
          ),
        ),
      ],
    );
  }

  Widget _buildDriverDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Pilih Opsi',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<int>(
          value: _selectedDriverId,
          items: _drivers.map((driver) {
            return DropdownMenuItem<int>(
              value: driver['id'],
              child: Text(
                  '${driver['service']} - Rp ${double.parse(driver['driver_fee'].toString()).toStringAsFixed(0)}'),
            );
          }).toList(),
          onChanged: (newValue) {
            setState(() {
              _selectedDriverId = newValue;
            });
          },
          decoration: const InputDecoration(
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.person),
          ),
        ),
      ],
    );
  }

  Widget _buildDiscountInput() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kode Diskon (Opsional)',
          style: TextStyle(fontWeight: FontWeight.w500),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _discountController,
                decoration: const InputDecoration(
                  hintText: 'Masukkan kode diskon',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.discount),
                ),
                onChanged: (value) {
                  // Reset discount when user types
                  if (value.isEmpty) {
                    setState(() {
                      _discountAmount = 0.0;
                      _appliedDiscount = null;
                      _discountError = null;
                    });
                  }
                },
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _isCheckingDiscount ? null : _applyDiscount,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              child: _isCheckingDiscount
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text('Terapkan',
                      style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        if (_discountError != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              _discountError!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        if (_appliedDiscount != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Diskon diterapkan: ${_appliedDiscount!['code']}',
              style: const TextStyle(color: Colors.green),
            ),
          ),
      ],
    );
  }

  Widget _buildPaymentSummary() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildSummaryRow(
              'Harga Mobil', 'Rp ${_carPriceValue.toStringAsFixed(0)}/hari'),
          _buildSummaryRow('Durasi', '$_totalDays Hari'),
          _buildSummaryRow(
              'Subtotal Mobil', 'Rp ${_subtotal.toStringAsFixed(0)}'),
          if (_discountAmount > 0) ...[
            _buildSummaryRow('Potongan Diskon',
                '- Rp ${_discountAmount.toStringAsFixed(0)}'),
            _buildSummaryRow('Subtotal Setelah Diskon',
                'Rp ${_discountedSubtotal.toStringAsFixed(0)}'),
          ],
          if (_withDriver)
            _buildSummaryRow(
                'Biaya Sopir', 'Rp ${_driverFee.toStringAsFixed(0)}'),
          const Divider(),
          _buildSummaryRow(
            'Total Pembayaran',
            'Rp ${_total.toStringAsFixed(0)}',
            isBold: true,
            textColor: primaryBlue,
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value,
      {bool isBold = false, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              )),
          Text(value,
              style: TextStyle(
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: textColor,
              )),
        ],
      ),
    );
  }
}
