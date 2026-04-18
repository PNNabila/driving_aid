import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async'; // Import ini wajib untuk fungsi Timer
import 'login_screen.dart';

class OtpScreen extends StatefulWidget {
  final String email;
  const OtpScreen({super.key, required this.email});

  @override
  State<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends State<OtpScreen> {
  final _otpController = TextEditingController();
  bool _isLoading = false;

  // --- Variabel untuk Timer ---
  Timer? _timer;
  int _secondsRemaining = 60; // Waktu hitung mundur (60 detik)
  bool _canResend = false; // Status apakah tombol Kirim Ulang bisa diklik

  @override
  void initState() {
    super.initState();
    _startTimer(); // Mulai timer saat halaman pertama kali dibuka
  }

  // Fungsi untuk menjalankan waktu hitung mundur
  void _startTimer() {
    setState(() {
      _secondsRemaining = 60;
      _canResend = false;
    });
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        setState(() {
          _canResend = true;
          _timer?.cancel(); // Matikan timer jika sudah 0
        });
      }
    });
  }

  // Fungsi untuk mengirim ulang kode OTP
  Future<void> _resendOtp() async {
    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.resend(
        type: OtpType.signup,
        email: widget.email,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kode OTP baru telah dikirim!"),
            backgroundColor: Colors.blue,
          ),
        );
        _startTimer(); // Ulangi timer dari 60 detik lagi
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal mengirim ulang kode OTP"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Masukkan 6 digit kode OTP")),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      await Supabase.instance.client.auth.verifyOTP(
        token: _otpController.text.trim(),
        type: OtpType.signup,
        email: widget.email,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Email Berhasil Diverifikasi! Silakan Login."),
            backgroundColor: Colors.green,
          ),
        );

        await Supabase.instance.client.auth.signOut();

        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false,
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Kode OTP salah atau sudah kadaluarsa"),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _timer
        ?.cancel(); // Pastikan timer dimatikan saat pindah halaman agar tidak error memori
    _otpController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("VERIFIKASI OTP")),
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Masukkan kode verifikasi yang dikirim ke:\n${widget.email}",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 30),

            // --- INPUT OTP YANG MELENGKUNG ---
            TextField(
              controller: _otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              style: const TextStyle(fontSize: 24, letterSpacing: 10),
              decoration: InputDecoration(
                hintText: "000000",
                counterText: "", // Menghilangkan tulisan "0/6" di bawah input
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15.0), // Ujung melengkung
                ),
              ),
            ),
            const SizedBox(height: 30),

            // --- TOMBOL VERIFIKASI YANG MELENGKUNG ---
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C4A73),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(15.0), // Tombol melengkung
                        )),
                    onPressed: _verifyOtp,
                    child: const Text("VERIFIKASI",
                        style: TextStyle(color: Colors.white)),
                  ),
            const SizedBox(height: 20),

            // --- BAGIAN TIMER & KIRIM ULANG ---
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  _canResend
                      ? "Belum menerima kode?"
                      : "Kirim ulang OTP dalam 00:${_secondsRemaining.toString().padLeft(2, '0')}",
                  style: TextStyle(color: Colors.grey[700]),
                ),
                if (_canResend) ...[
                  TextButton(
                    onPressed: _isLoading ? null : _resendOtp,
                    child: const Text("Kirim Ulang",
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ]
              ],
            ),

            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Ganti Email atau Kembali",
                  style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      ),
    );
  }
}
