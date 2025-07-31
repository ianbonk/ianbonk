import 'package:flutter/material.dart';
import 'package:sabiki_rental_car/navbar.dart';
import 'package:sabiki_rental_car/pages/dashboard.dart';
import 'package:sabiki_rental_car/pages/search.dart';
import 'package:sabiki_rental_car/pages/process.dart';
import 'package:sabiki_rental_car/pages/profile.dart';

class MainWrapper extends StatefulWidget {
  final int customerId; // Tambahkan parameter customerId
  
  const MainWrapper({super.key, required this.customerId});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;
  late final List<Widget> _pages; // Gunakan late final untuk inisialisasi non-const

  @override
  void initState() {
    super.initState();
    _pages = [
      const Dashboard(),
      const Search(),
      Process(), // Gunakan customerId dari widget
      const Profile(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: Navbar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
      ),
    );
  }
}