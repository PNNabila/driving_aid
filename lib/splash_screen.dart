import 'package:flutter/material.dart';
import 'dart:async';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Warna awal gelap (Navy), warna akhir cerah (Putih)
  bool _isBright = false;

  @override
  void initState() {
    super.initState();

    // 1. Setelah 0.5 detik, ubah status menjadi bright (memulai transisi warna)
    Timer(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          _isBright = true;
        });
      }
    });

    // 2. Navigasi ke Login setelah 2 detik
    Timer(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // AnimatedContainer ini yang membuat efek "gelap ke terang"
      body: AnimatedContainer(
        duration: const Duration(seconds: 1), // Durasi transisi warna
        curve: Curves.easeInOut,
        color: _isBright ? Colors.white : const Color(0xFF2C4A73),
        child: Center(
          child: Image.asset(
            'assets/logodrivingaid.png',
            width: 200,
            height: 200,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) =>
                const Icon(Icons.motorcycle, size: 150, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
