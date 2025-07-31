import 'package:flutter/material.dart';
import 'package:sabiki_rental_car/pages/splashscreen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Splash(),
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        fontFamily: 'Poppins'
      ),
    );
  }
}

// HAPUS SELURUH KELAS MainWrapper DI BAWAH INI 
// (Sudah didefinisikan di main_wrapper.dart)