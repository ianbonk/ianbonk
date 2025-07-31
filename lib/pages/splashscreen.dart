import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:sabiki_rental_car/pages/login.dart';

class Splash extends StatefulWidget {
  const Splash({super.key});

  @override
  State<Splash> createState() => _SplashState();
}

class _SplashState extends State<Splash> {
  late VideoPlayerController _controller;

  @override
  void initState() {
    super.initState();

    // Inisialisasi video controller
    _controller = VideoPlayerController.asset('assets/videos/splash.mp4')
      ..initialize().then((_) {
        // Setelah video siap, mulai putar dan set state
        setState(() {});
        _controller.play();
        _controller.setLooping(false);

        // Navigasi setelah video selesai atau waktu tertentu
        _controller.addListener(() {
          if (_controller.value.position >= _controller.value.duration) {
            navigateToLogin();
          }
        });

        // Backup navigasi setelah 5 detik jika video terlalu panjang
        Future.delayed(const Duration(seconds: 5), navigateToLogin);
      });
  }

  void navigateToLogin() {
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const Login()),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: _controller.value.isInitialized
            ? AspectRatio(
                aspectRatio: _controller.value.aspectRatio,
                child: VideoPlayer(_controller),
              )
            : const CircularProgressIndicator(),
      ),
    );
  }
}
