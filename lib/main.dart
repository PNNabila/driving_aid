import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'splash_screen.dart'; // Import halaman splash screen

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load file .env sebelum inisialisasi Supabase
  await dotenv.load(fileName: ".env");

  // Panggil URL dan Anon Key dari file .env
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );

  runApp(const DrivingAidApp());
}

class DrivingAidApp extends StatelessWidget {
  const DrivingAidApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Driving Aid for Deaf',
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF2C4A73),
          elevation: 0,
          centerTitle: true,
          titleTextStyle: TextStyle(
              color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
          iconTheme: IconThemeData(color: Colors.white),
        ),
      ),
      // HALAMAN PERTAMA KALI DIBUKA ADALAH SPLASH SCREEN
      home: const SplashScreen(),
    );
  }
}
