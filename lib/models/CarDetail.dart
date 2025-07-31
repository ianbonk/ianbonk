import 'CarCategory.dart';

class CarDetail {
  final int id;
  final String brand;
  final String model;
  final int year;
  final double pricePerDay;
  final String? description;
  final String? imageUrl;
  final List<CarCategory> categories;
  final double rating;
  final String? ownerName;
  final String? joinDate;
  final String? ownerLocation;
  final List<String>? features;

  CarDetail({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
    required this.pricePerDay,
    required this.categories,
    required this.imageUrl,
    required this.rating,
    this.description,
    this.ownerName,
    this.joinDate,
    this.ownerLocation,
    this.features,
  });

  factory CarDetail.fromJson(Map<String, dynamic> json) {
    final carData = json['data'] as Map<String, dynamic>;
    
    return CarDetail(
      id: carData['id'] as int? ?? 0,
      brand: carData['brand'] as String? ?? '',
      model: carData['model'] as String? ?? '',
      year: carData['year'] as int? ?? 0,
      pricePerDay: double.tryParse(carData['price_per_day']?.toString() ?? '0') ?? 0.0,
      categories: (carData['categories'] as List? ?? [])
          .map((item) => CarCategory.fromJson(item))
          .toList(),
      imageUrl: carData['thumbnail'] as String?,
      rating: (carData['average_rating'] as num?)?.toDouble() ?? 4.5,
      description: carData['description'] as String?,
      ownerName: carData['owner_name'] as String?,
      joinDate: carData['join_date'] as String?,
      ownerLocation: carData['owner_location'] as String?,
      //features: (carData['features'] as List?)?.cast<String>(),
    );
  }
}