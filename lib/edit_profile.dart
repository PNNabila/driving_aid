import 'dart:io';
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
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;
  File? _imageFile;
  String? _currentAvatarUrl;

  @override
  void initState() {
    super.initState();
    _fullNameController.text = widget.userData['full_name'] ?? '';
    _usernameController.text = widget.userData['username'] ?? '';
    _currentAvatarUrl = widget.userData['avatar_url'];
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile =
        await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (pickedFile != null) {
      setState(() => _imageFile = File(pickedFile.path));
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return;

    try {
      String? newAvatarUrl = _currentAvatarUrl;

      // Jika ada gambar baru yang dipilih, upload ke Supabase Storage
      if (_imageFile != null) {
        final fileExt = _imageFile!.path.split('.').last;
        // Nama file unik per user
        final fileName = '${user.id}/avatar.$fileExt';

        // 1. Upload ke bucket 'AVATARS' (Harus huruf besar semua sesuai dashboard)
        // upsert: true artinya replace file lama jika sudah ada
        await Supabase.instance.client.storage.from('AVATARS').upload(
            fileName, _imageFile!,
            fileOptions: const FileOptions(upsert: true));

        // 2. Dapatkan URL publik
        newAvatarUrl = Supabase.instance.client.storage
            .from('AVATARS')
            .getPublicUrl(fileName);
      }

      // 3. Update data di tabel user_profiles
      await Supabase.instance.client.from('user_profiles').update({
        'full_name': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
      }).eq('user_id', user.id);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Profil berhasil diperbarui"),
            backgroundColor: Colors.green));
        Navigator.pop(context, true); // Kembali ke setting dan refresh data
      }
    } catch (e) {
      debugPrint("Error save profile: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text("Gagal memperbarui profil: $e"),
            backgroundColor: Colors.red));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("EDIT PROFIL")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(30.0),
        child: Column(
          children: [
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[300],
                    backgroundImage: _imageFile != null
                        ? FileImage(_imageFile!)
                        : (_currentAvatarUrl != null
                            ? NetworkImage(_currentAvatarUrl!)
                            : null) as ImageProvider?,
                    child: (_imageFile == null && _currentAvatarUrl == null)
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
                          color: Color(0xFF2C4A73), shape: BoxShape.circle),
                      child: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 30),
            TextField(
                controller: _fullNameController,
                decoration: const InputDecoration(
                    labelText: "Nama Lengkap", border: OutlineInputBorder())),
            const SizedBox(height: 20),
            TextField(
                controller: _usernameController,
                decoration: const InputDecoration(
                    labelText: "Username", border: OutlineInputBorder())),
            const SizedBox(height: 40),
            _isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2C4A73),
                        minimumSize: const Size(double.infinity, 50)),
                    onPressed: _saveProfile,
                    child: const Text("SIMPAN",
                        style: TextStyle(color: Colors.white)),
                  ),
          ],
        ),
      ),
    );
  }
}
