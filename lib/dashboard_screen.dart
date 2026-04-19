import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  // --- STATUS INDEPENDEN ---
  bool isOn = true;
  bool isConnected = true;
  int batteryLevel = 75;
  String activeWarning = "TENGAH";

  Map<String, dynamic>? userData;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchProfile();
  }

  Future<void> _fetchProfile() async {
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('user_profiles')
            .select('full_name, username, avatar_url')
            .eq('user_id', user.id)
            .maybeSingle(); // Menggunakan maybeSingle agar tidak crash
        if (mounted && data != null) {
          setState(() {
            userData = data;
            isLoading = false;
          });
        }
      } catch (e) {
        debugPrint("Error loading profile: $e");
        setState(() => isLoading = false);
      }
    }
  }

  Future<void> _toggleSwitch(bool value) async {
    final String action = value ? "Menghidupkan" : "Mematikan";
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Konfirmasi"),
        content: Text("Apakah Anda yakin ingin $action sistem?"),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2C4A73)),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ya"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      setState(() {
        isOn = value;
        isConnected = value;
      });
    }
  }

  IconData _getBatteryIcon() {
    if (batteryLevel >= 90) return Icons.battery_full;
    if (batteryLevel >= 70) return Icons.battery_6_bar;
    if (batteryLevel >= 50) return Icons.battery_5_bar;
    return Icons.battery_std;
  }

  @override
  Widget build(BuildContext context) {
    const Color deepNavy = Color(0xFF2C4A73);
    const Color mutedRed = Color(0xFF8B0000);
    const Color mutedGrey = Color(0xFF757575);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          // --- HEADER BIRU ---
          Container(
            padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
            width: double.infinity,
            color: deepNavy,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 25,
                  backgroundColor: Colors.white,
                  backgroundImage:
                      (userData != null && userData!['avatar_url'] != null)
                          ? NetworkImage(userData!['avatar_url'])
                          : null,
                  child: (userData == null || userData!['avatar_url'] == null)
                      ? const Icon(Icons.person, size: 30, color: deepNavy)
                      : null,
                ),
                const SizedBox(width: 15),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("Halo,",
                        style: TextStyle(color: Colors.white70, fontSize: 12)),
                    // BAGIAN INI YANG DIUBAH: Mengambil full_name atau username
                    Text(
                      isLoading
                          ? "Memuat..."
                          : (userData?['full_name'] ??
                              userData?['username'] ??
                              "User"),
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18),
                    ),
                  ],
                ),
              ],
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // BATERAI & KONEKSI
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        Icon(_getBatteryIcon(),
                            color: Colors.green.shade700, size: 35),
                        Text(" $batteryLevel%",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16)),
                      ]),
                      Text(isConnected ? "CONNECTED" : "DISCONNECTED",
                          style: TextStyle(
                              color: isConnected
                                  ? Colors.green.shade700
                                  : mutedRed,
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                    ],
                  ),
                  const Divider(height: 40, thickness: 1),

                  // ALERT
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _buildAlertBox("KIRI", Icons.arrow_back_ios, "KIRI",
                          mutedRed, mutedGrey),
                      _buildAlertBox("TENGAH", Icons.warning, "TENGAH",
                          mutedRed, mutedGrey),
                      _buildAlertBox("KANAN", Icons.arrow_forward_ios, "KANAN",
                          mutedRed, mutedGrey),
                    ],
                  ),
                  const SizedBox(height: 50),

                  // SWITCH
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 35, vertical: 12),
                    decoration: BoxDecoration(
                        color: deepNavy,
                        borderRadius: BorderRadius.circular(50)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(isOn ? "ON" : "OFF",
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 22)),
                        const SizedBox(width: 20),
                        Transform.scale(
                          scale: 1.3,
                          child: Switch(
                            value: isOn,
                            onChanged: _toggleSwitch,
                            activeColor: Colors.white,
                            activeTrackColor: Colors.green.shade400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAlertBox(String title, IconData icon, String direction,
      Color activeColor, Color inactiveColor) {
    bool isActive = (activeWarning == direction);
    return Container(
      width: 110,
      height: 140,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isActive ? activeColor.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
            color:
                isActive ? activeColor.withOpacity(0.7) : Colors.grey.shade300,
            width: isActive ? 4 : 2),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 50, color: isActive ? activeColor : inactiveColor),
          const SizedBox(height: 10),
          Text(title,
              style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontSize: 14,
                  fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
