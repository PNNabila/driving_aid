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
  final _fullNameController = TextEditingController();
  final _usernameController = TextEditingController();
  bool _isLoading = false;

  // Gunakan Uint8List untuk Web/Mobile yang kompatibel
  Uint8List? _imageBytes;
  String? _currentAvatarUrl;

  // Nama Bucket (PASTIKAN SAMA PERSIS DENGAN DASHBOARD)
  final String bucketName = 'avatars';

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
      final bytes = await pickedFile.readAsBytes();
      setState(() => _imageBytes = bytes);
    }
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    final supabase = Supabase.instance.client;
    final user = supabase.auth.currentUser;

    if (user == null) return;

    try {
      String? newAvatarUrl = _currentAvatarUrl;

      if (_imageBytes != null) {
        final fileName = '${user.id}/avatar.png';

        // PROSES UPLOAD
        await supabase.storage.from(bucketName).uploadBinary(
              fileName,
              _imageBytes!,
              fileOptions: const FileOptions(upsert: true),
            );

        newAvatarUrl = supabase.storage.from(bucketName).getPublicUrl(fileName);
      }

      // UPDATE DATABASE
      await supabase.from('user_profiles').update({
        'full_name': _fullNameController.text.trim(),
        'username': _usernameController.text.trim(),
        if (newAvatarUrl != null) 'avatar_url': newAvatarUrl,
      }).eq('user_id', user.id);

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
                    backgroundImage: _imageBytes != null
                        ? MemoryImage(_imageBytes!)
                        : (_currentAvatarUrl != null &&
                                _currentAvatarUrl!.isNotEmpty
                            ? NetworkImage(_currentAvatarUrl!)
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
