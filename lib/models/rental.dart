class Rental {
  final int id;
  final String status;
  final DateTime pickupDate;
  final DateTime returnDate;
  final Booking booking;
  final bool canRate;

  Rental({
    required this.id,
    required this.status,
    required this.pickupDate,
    required this.returnDate,
    required this.booking,
    required this.canRate,
  });

  factory Rental.fromJson(Map<String, dynamic> json) {
    return Rental(
      id: json['id'],
      status: json['status'],
      pickupDate: DateTime.parse(json['pickup_date']),
      returnDate: DateTime.parse(json['return_date']),
      booking: Booking.fromJson(json['booking']),
      canRate: json['can_rate'] ?? false,
    );
  }
}

class Booking {
  final int id;
  final User user;
  final Car car;
  final Payment? payment;

  Booking({
    required this.id,
    required this.user,
    required this.car,
    this.payment,
  });

  factory Booking.fromJson(Map<String, dynamic> json) {
    return Booking(
      id: json['id'],
      user: User.fromJson(json['user']),
      car: Car.fromJson(json['car']),
      payment: json['payment'] != null ? Payment.fromJson(json['payment']) : null,
    );
  }
}

class User {
  final int id;
  final String name;

  User({required this.id, required this.name});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      name: json['name'],
    );
  }
}

class Car {
  final int id;
  final String brand;
  final String model;
  final int year;

  Car({
    required this.id,
    required this.brand,
    required this.model,
    required this.year,
  });

  factory Car.fromJson(Map<String, dynamic> json) {
    return Car(
      id: json['id'],
      brand: json['brand'],
      model: json['model'],
      year: json['year'],
    );
  }
}

class Payment {
  final String orderId;

  Payment({required this.orderId});

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      orderId: json['order_id'],
    );
  }
}