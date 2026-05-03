import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'register_screen.dart';
import 'main_navigation.dart'; // Import MainNavigation (Dashboard)

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  // --- VARIABEL UNTUK VISIBILITAS PASSWORD ---
  bool _obscurePassword = true;

  // --- SECURITY VARIABLES ---
  int _failedAttempts = 0;
  bool _isAccountLocked = false;

  Future<void> _handleLogin() async {
    // 1. CHECK LOCK STATUS
    if (_isAccountLocked) {
      _showWarningDialog();
      return;
    }

    setState(() => _isLoading = true);

    try {
      await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      if (mounted) {
        // RESET ATTEMPTS IF LOGIN SUCCESS
        setState(() {
          _failedAttempts = 0;
        });

        // SETELAH LOGIN SUKSES, PINDAH KE DASHBOARD (MainNavigation)
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => const MainNavigation()));
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _failedAttempts++; // INCREMENT FAILED ATTEMPTS

          if (_failedAttempts >= 3) {
            _isAccountLocked = true;
            _showWarningDialog();
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text(
                  "Incorrect Email/Password! Remaining attempts: ${3 - _failedAttempts}x."),
              backgroundColor: Colors.orange.shade800,
            ));
          }
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // --- WARNING DIALOG FUNCTION ---
  void _showWarningDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Row(
          children: [
            const Icon(Icons.gpp_bad_rounded, color: Colors.red, size: 28),
            const SizedBox(width: 10),
            Text("Account Locked!",
                style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: 20)),
          ],
        ),
        content: const Text(
            "There have been 3 failed login attempts.\n\nFor security reasons, we have sent a warning email to your address. Please try again later or check your inbox.",
            style: TextStyle(fontSize: 14, height: 1.5)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TESTING TIP: Uncomment the code below to reset the lock after clicking "Understood" for testing purposes
              // setState(() {
              //   _isAccountLocked = false;
              //   _failedAttempts = 0;
              // });
            },
            child: const Text("Understood",
                style: TextStyle(
                    color: Color(0xFF2C4A73), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text("LOGIN",
                style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2C4A73))),
            const SizedBox(height: 40),

            // --- INPUT EMAIL DENGAN SUDUT MELENGKUNG ---
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: "Email",
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15.0), // Membuat sudut melengkung
                ),
              ),
            ),
            const SizedBox(height: 20),

            // --- INPUT PASSWORD DENGAN FITUR LIHAT PASSWORD ---
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword, // Menggunakan variabel boolean
              decoration: InputDecoration(
                labelText: "Password",
                border: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(15.0), // Membuat sudut melengkung
                ),
                // Menambahkan Ikon Mata (Suffix Icon)
                suffixIcon: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    // Membalikkan status saat ikon diklik
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 30),

            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isAccountLocked
                          ? Colors.red
                          : const Color(0xFF2C4A73),
                      minimumSize: const Size(double.infinity, 50),
                      // Membuat tombol ikut melengkung senada dengan input text
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15.0),
                      ),
                    ),
                    onPressed: _handleLogin,
                    child: Text(_isAccountLocked ? "ACCOUNT LOCKED" : "LOGIN",
                        style: const TextStyle(color: Colors.white)),
                  ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const RegisterScreen())),
              child: const Text("Don't have an account yet? Register"),
            ),
          ],
        ),
      ),
    );
  }
}
