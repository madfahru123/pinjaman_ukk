import 'dart:typed_data';
import 'dart:io' show File;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TambahPetugasPage extends StatefulWidget {
  final int? id;
  final String? nama;
  final String? alamat;
  final String? email;
  final String? foto;

  const TambahPetugasPage({
    super.key,
    this.id,
    this.nama,
    this.alamat,
    this.email,
    this.foto,
  });

  @override
  State<TambahPetugasPage> createState() => _TambahPetugasPageState();
}

class _TambahPetugasPageState extends State<TambahPetugasPage> {
  final supabase = Supabase.instance.client;

  late TextEditingController namaController;
  late TextEditingController alamatController;
  late TextEditingController emailController;
  final passwordController = TextEditingController();

  XFile? pickedFile;
  Uint8List? imageBytes;

  bool loading = false;
  bool get isEdit => widget.id != null;

  @override
  void initState() {
    super.initState();
    namaController = TextEditingController(text: widget.nama ?? '');
    alamatController = TextEditingController(text: widget.alamat ?? '');
    emailController = TextEditingController(text: widget.email ?? '');
  }

  // ================= PICK IMAGE =================
  Future<void> pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );

    if (picked != null) {
      if (kIsWeb) imageBytes = await picked.readAsBytes();
      pickedFile = picked;
      if (mounted) setState(() {});
    }
  }

  // ================= UPLOAD FOTO =================
  Future<String?> uploadFoto() async {
    if (pickedFile == null) return widget.foto;

    final fileName = 'petugas_${DateTime.now().millisecondsSinceEpoch}.jpg';

    if (kIsWeb) {
      await supabase.storage
          .from('petugas')
          .uploadBinary(
            fileName,
            imageBytes!,
            fileOptions: const FileOptions(upsert: true),
          );
    } else {
      await supabase.storage
          .from('petugas')
          .upload(
            fileName,
            File(pickedFile!.path),
            fileOptions: const FileOptions(upsert: true),
          );
    }

    return supabase.storage.from('petugas').getPublicUrl(fileName);
  }

  // ================= SIMPAN =================
  Future<void> simpan() async {
    setState(() => loading = true);

    try {
      final fotoUrl = await uploadFoto();

      if (isEdit) {
        await supabase
            .from('petugas')
            .update({
              'nama': namaController.text,
              'alamat': alamatController.text,
              'email': emailController.text.trim(),
              'foto': fotoUrl,
            })
            .eq('id', widget.id!);
      } else {
        final authRes = await supabase.auth.signUp(
          email: emailController.text.trim(),
          password: passwordController.text,
        );

        final user = authRes.user;
        if (user == null) throw 'Gagal membuat akun petugas';

        await supabase.from('petugas').insert({
          'userid': user.id,
          'nama': namaController.text,
          'email': emailController.text.trim(),
          'alamat': alamatController.text,
          'foto': fotoUrl,
        });
      }

      if (!mounted) return;
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal: $e')));
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Petugas' : 'Tambah Petugas'),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // ===== FOTO =====
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 130,
                width: 130,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                  image: pickedFile != null
                      ? DecorationImage(
                          image: kIsWeb
                              ? MemoryImage(imageBytes!)
                              : FileImage(File(pickedFile!.path))
                                    as ImageProvider,
                          fit: BoxFit.cover,
                        )
                      : widget.foto != null
                      ? DecorationImage(
                          image: NetworkImage(widget.foto!),
                          fit: BoxFit.cover,
                        )
                      : null,
                  color: Colors.grey.shade300,
                ),
                child: pickedFile == null && widget.foto == null
                    ? const Icon(Icons.camera_alt, size: 40)
                    : null,
              ),
            ),

            const SizedBox(height: 32),

            // ===== FORM CARD =====
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _input(
                      controller: namaController,
                      label: 'Nama',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),
                    _input(
                      controller: alamatController,
                      label: 'Alamat',
                      icon: Icons.location_on,
                    ),
                    const SizedBox(height: 12),
                    _input(
                      controller: emailController,
                      label: 'Email',
                      icon: Icons.email,
                    ),
                    if (!isEdit) ...[
                      const SizedBox(height: 12),
                      _input(
                        controller: passwordController,
                        label: 'Password',
                        icon: Icons.lock,
                        obscure: true,
                      ),
                    ],
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // ===== BUTTON =====
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : simpan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        isEdit ? 'UPDATE' : 'SIMPAN',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== INPUT STYLE =====
  Widget _input({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscure = false,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: Colors.grey.shade100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
