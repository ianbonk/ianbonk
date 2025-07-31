class Car {
  final int id;
  final String brand;
  final String model;
  final double rating;
  final String price;
  final String status;
  final bool isAvailable;
  final String? imageUrl;

  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.rating,
    required this.price,
    required this.status,
    required this.isAvailable,
    this.imageUrl,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    // Handle perbedaan struktur response
    final dynamic statusValue =
        json['status'] ?? json['car_status'] ?? 'unknown';
    final status = statusValue.toString().toLowerCase();

    // Handle perbedaan field harga
    final dynamic priceValue =
        json['price'] ?? json['price_per_day'] ?? json['rental_price'];

    int parsedId = 0;
    if (json['id'] != null) {
      parsedId = int.tryParse(json['id'].toString()) ?? 0;
    }

    return Car(
      id: parsedId,
      brand: json['brand'],
      model: json['model'],
      rating: double.tryParse(json['rating']?.toString() ?? '0') ?? 0.0,
      price: priceValue?.toString() ?? '0',
      status: status,
      isAvailable: status == 'available',
      imageUrl: json['image_url'] != null
          ? 'https://your-domain/storage/${json['image_url']}'
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'brand': brand,
      'model': model,
      'rating': rating,
      'price': price,
      'status': status,
      'isAvailable': isAvailable,
      'imageUrl': imageUrl,
    };
  }
}
