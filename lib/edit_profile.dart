import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';

class EditProfileScreen extends StatefulWidget {
  final Map<String, dynamic> userData;
  const EditProfileScreen({super.key, required this.userData});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  // --- CONTROLLER LAMA ---
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();

  // --- CONTROLLER BARU ---
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  // --- VARIABLE VISIBILITY PASSWORD ---
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isLoading = false;

  // Gunakan Uint8List untuk Web/Mobile yang kompatibel
  Uint8List? _imageBytes;
  String? _currentAvatarUrl;

  // Nama Bucket (PASTIKAN SAMA PERSIS DENGAN DASHBOARD)
  final String bucketName = 'avatars';

  @override
  void initState() {
    super.initState();
    final user = Supabase.instance.client.auth.currentUser;

    // Load data lama
    _fullNameController.text = widget.userData['full_name'] ?? '';
    _usernameController.text = widget.userData['username'] ?? '';
    _currentAvatarUrl = widget.userData['avatar_url'];

    // Load data baru
    _emailController.text = user?.email ?? widget.userData['email'] ?? '';
    _phoneController.text = widget.userData['phone_number'] ?? '';
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (pickedFile != null) {
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _saveProfile() async {
    // Validasi Password Baru sebelum loading
    if (_newPasswordController.text.isNotEmpty) {
      if (_newPasswordController.text != _confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("New Password dan Confirm Password tidak cocok!"),
            backgroundColor: Colors.red));
        return;
      }
    }

    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      String? newAvatarUrl = _currentAvatarUrl;

      if (_imageBytes != null) {
        final fileName = '${user.id}/avatar.png';

        // PROSES UPLOAD FOTO
        await supabase.storage.from(bucketName).uploadBinary(
              fileName,
              _imageBytes!,
              fileOptions: const FileOptions(upsert: true),
            );

        newAvatarUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);
      }

      // UPDATE DATABASE PROFIL (Mencegah Error 409 Conflict)
      final Map<String, dynamic> updateData = {
        'full_name': _fullNameController.text.trim(),
        'phone_number': _phoneController.text.trim(), // Data baru
        if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
      };

      if (_usernameController.text.trim() != widget.userData['username']) {
        updateData['username'] = _usernameController.text.trim();
      }

      await supabase
          .from('user_profiles')
          .update(updateData)
          .eq('user_id', user.id);

      // UPDATE PASSWORD KE SUPABASE AUTH (Jika diisi)
      if (_newPasswordController.text.isNotEmpty) {
        await supabase.auth.updateUser(
          UserAttributes(password: _newPasswordController.text),
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Profil berhasil diperbarui"),
            backgroundColor: Colors.green));
        Navigator.pop(context, true);
      }
    } catch (e) {
      debugPrint("ERROR DETAIL: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Gagal: ${e.toString()}"),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    const Color deepNavy = Color(0xFF2C4A73);

    return Scaffold(
      appBar: AppBar(title: const Text("EDIT PROFIL")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ================= FOTO PROFIL =================
            Center(
              child: GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 60,
                      backgroundColor: Colors.grey[300],
                      backgroundImage: _imageBytes != null
                          ? MemoryImage(_imageBytes!)
                          : (_currentAvatarUrl != null &&
                                  _currentAvatarUrl!.isNotEmpty
                              ? NetworkImage(
                                  "$_currentAvatarUrl?t=${DateTime.now().millisecondsSinceEpoch}")
                              : null) as ImageProvider?,
                      child: (_imageBytes == null &&
                              (_currentAvatarUrl == null ||
                                  _currentAvatarUrl!.isEmpty))
                          ? const Icon(Icons.person,
                              size: 60, color: Colors.white)
                          : null,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                            color: deepNavy, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt,
                            color: Colors.white, size: 20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),

            // ================= PERSONAL INFORMATION =================
            const Text("Personal Information",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: deepNavy)),
            const Divider(thickness: 1.5),
            const SizedBox(height: 15),

            TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                    labelText: "Full Name",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0)))),
            const SizedBox(height: 15),

            TextField(
                controller: _usernameController,
                decoration: InputDecoration(
                    labelText: "Username",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0)))),
            const SizedBox(height: 15),

            TextField(
                controller: _emailController,
                readOnly:
                    true, // Email sebaiknya Read-Only karena terikat dengan Auth
                decoration: InputDecoration(
                    labelText: "Email",
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0)))),
            const SizedBox(height: 15),

            TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                    labelText: "Phone Number",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0)))),
            const SizedBox(height: 40),

            // ================= CHANGE PASSWORD =================
            const Text("Change Password",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: deepNavy)),
            const Divider(thickness: 1.5),
            const SizedBox(height: 15),

            TextField(
                controller: _currentPasswordController,
                obscureText: _obscureCurrent,
                decoration: InputDecoration(
                    labelText: "Current Password",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureCurrent
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureCurrent = !_obscureCurrent),
                    ))),
            const SizedBox(height: 15),

            TextField(
                controller: _newPasswordController,
                obscureText: _obscureNew,
                decoration: InputDecoration(
                    labelText: "New Password",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureNew
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureNew = !_obscureNew),
                    ))),
            const SizedBox(height: 15),

            TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                decoration: InputDecoration(
                    labelText: "Confirm New Password",
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(15.0)),
                    suffixIcon: IconButton(
                      icon: Icon(_obscureConfirm
                          ? Icons.visibility_off
                          : Icons.visibility),
                      onPressed: () =>
                          setState(() => _obscureConfirm = !_obscureConfirm),
                    ))),
            const SizedBox(height: 40),

            // ================= BUTTONS =================
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : Row(
                    children: [
                      // Tombol Cancel
                      Expanded(
                        child: OutlinedButton(
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            side: const BorderSide(color: deepNavy),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                          onPressed: () => Navigator.pop(context),
                          child: const Text("Cancel",
                              style: TextStyle(color: deepNavy, fontSize: 16)),
                        ),
                      ),
                      const SizedBox(width: 15),
                      // Tombol Save Changes
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 15),
                            backgroundColor: deepNavy,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15.0),
                            ),
                          ),
                          onPressed: _saveProfile,
                          child: const Text("Save Changes",
                              style:
                                  TextStyle(color: Colors.white, fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
