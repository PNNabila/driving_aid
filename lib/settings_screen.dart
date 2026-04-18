import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'edit_profile.dart';
import 'login_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});
  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int selectedIndex = 1;
  Map<String, dynamic>? userData;
  bool isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    setState(() => isLoadingProfile = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user != null) {
      try {
        final data = await Supabase.instance.client
            .from('user_profiles')
            .select()
            .eq('user_id', user.id)
            .single();
        setState(() {
          userData = data;
          userData!['email'] = user.email;
        });
      } catch (e) {
        debugPrint("Error fetching profile: $e");
      }
    }
    setState(() => isLoadingProfile = false);
  }

  Future<void> _logout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) {
      Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          title: const Text("SETTINGS"), automaticallyImplyLeading: false),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25.0),
        child: Column(
          children: [
            // ==========================================
            // BAGIAN PROFIL
            // ==========================================
            if (isLoadingProfile)
              const CircularProgressIndicator()
            else if (userData != null)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: const Color(0xFF2C4A73),
                      backgroundImage: userData!['avatar_url'] != null
                          ? NetworkImage(userData!['avatar_url'])
                          : null,
                      child: userData!['avatar_url'] == null
                          ? const Icon(Icons.person,
                              size: 40, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(height: 15),
                    Text(
                      userData!['full_name'] ??
                          userData!['username'] ??
                          "Pengguna",
                      style: const TextStyle(
                          fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      userData!['email'] ?? "",
                      style: const TextStyle(color: Colors.grey),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        OutlinedButton.icon(
                          onPressed: () async {
                            final result = await Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    EditProfileScreen(userData: userData!),
                              ),
                            );
                            if (result == true) {
                              _fetchUserData();
                            }
                          },
                          icon: const Icon(Icons.edit, size: 18),
                          label: const Text("Edit Profil"),
                        ),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.red),
                          onPressed: _logout,
                          icon: const Icon(Icons.logout, size: 18),
                          label: const Text("Logout"),
                        ),
                      ],
                    )
                  ],
                ),
              ),

            const SizedBox(height: 30),
            const Divider(thickness: 2),
            const SizedBox(height: 20),

            // ==========================================
            // BAGIAN VIBRATION CONTROL
            // ==========================================
            const Text("VIBRATION CONTROL",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            const SizedBox(height: 40),
            Container(
              height: 15,
              width: double.infinity,
              decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(10)),
              child: Row(
                children: [
                  Expanded(child: _buildBarSegment(0)),
                  Expanded(child: _buildBarSegment(1)),
                  Expanded(child: _buildBarSegment(2)),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel("LOW", 0),
                _buildLabel("MIDDLE", 1),
                _buildLabel("HIGH", 2)
              ],
            ),
            const SizedBox(
                height: 20), // Memberi ruang di bawah setelah tombol dihapus
          ],
        ),
      ),
    );
  }

  Widget _buildBarSegment(int index) {
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: Container(
          decoration: BoxDecoration(
              color: selectedIndex >= index
                  ? const Color(0xFF2C4A73)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(10))),
    );
  }

  Widget _buildLabel(String text, int index) {
    return GestureDetector(
      onTap: () => setState(() => selectedIndex = index),
      child: Text(text,
          style: TextStyle(
              fontWeight: FontWeight.bold,
              color: selectedIndex == index
                  ? const Color(0xFF2C4A73)
                  : Colors.black54)),
    );
  }
}
