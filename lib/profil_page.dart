import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'login_page.dart';

final supabase = Supabase.instance.client;

class ProfilTokoPage extends StatefulWidget {
  final bool canEdit; // kalau false, user cuma bisa lihat

  const ProfilTokoPage({super.key, this.canEdit = true});

  @override
  State<ProfilTokoPage> createState() => _ProfilTokoPageState();
}

class _ProfilTokoPageState extends State<ProfilTokoPage> {
  final _namaController = TextEditingController();
  final _alamatController = TextEditingController();
  final _teleponController = TextEditingController();
  final _emailController = TextEditingController();

  bool _loading = true;
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _fetchToko();
  }

  @override
  void dispose() {
    _namaController.dispose();
    _alamatController.dispose();
    _teleponController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _fetchToko() async {
    setState(() => _loading = true);
    try {
      final response = await supabase.from('toko').select().limit(1);
      if ((response as List).isNotEmpty) {
        final toko = response[0];
        _namaController.text = toko['nama'] ?? '';
        _alamatController.text = toko['alamat'] ?? '';
        _teleponController.text = toko['telepon'] ?? '';
        _emailController.text = toko['email'] ?? '';
      }
    } catch (e) {
      debugPrint("Gagal fetch data toko: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _saveToko() async {
    if (!widget.canEdit) return; // jika tidak boleh edit, langsung return

    final nama = _namaController.text.trim();
    final alamat = _alamatController.text.trim();
    final telepon = _teleponController.text.trim();
    final email = _emailController.text.trim();

    if (nama.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Nama toko wajib diisi")));
      return;
    }

    try {
      final data = {
        'nama': nama,
        'alamat': alamat,
        'telepon': telepon,
        'email': email,
      };

      final response = await supabase.from('toko').select().limit(1);
      final check = (response as List).isNotEmpty ? response[0] : null;

      if (check == null) {
        await supabase.from('toko').insert(data);
      } else {
        final id = check['id'];
        await supabase.from('toko').update(data).eq('id', id);
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Profil toko berhasil disimpan")),
      );
      setState(() => _isEditing = false);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Gagal simpan profil toko: $e")));
    }
  }

  Future<void> _logout(BuildContext context) async {
    await supabase.auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final canEdit = widget.canEdit;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Profil Toko"),
        backgroundColor: Colors.blue,
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isEditing ? Icons.cancel : Icons.logout),
            onPressed: () {
              if (_isEditing) {
                setState(() => _isEditing = false);
              } else {
                _logout(context);
              }
            },
            tooltip: _isEditing ? "Batal Edit" : "Logout",
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.vertical(
                        bottom: Radius.circular(24),
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white,
                      child: Icon(Icons.store, size: 45, color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 20),

                  /// ======= MODE VIEW =======
                  InfoTile(
                    icon: Icons.store,
                    title: "Nama Toko",
                    value: _namaController.text,
                  ),
                  InfoTile(
                    icon: Icons.location_on,
                    title: "Alamat",
                    value: _alamatController.text,
                  ),
                  InfoTile(
                    icon: Icons.phone,
                    title: "Telepon",
                    value: _teleponController.text,
                  ),
                  InfoTile(
                    icon: Icons.email,
                    title: "Email",
                    value: _emailController.text,
                  ),
                  const SizedBox(height: 20),

                  /// Tombol edit hanya muncul jika bisa edit
                  if (canEdit && !_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit),
                        label: const Text("Edit Profil"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),

                  /// Mode edit hanya jika bisa edit
                  if (canEdit && _isEditing) ...[
                    TextField(
                      controller: _namaController,
                      decoration: InputDecoration(
                        labelText: "Nama Toko",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _alamatController,
                      decoration: InputDecoration(
                        labelText: "Alamat",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _teleponController,
                      decoration: InputDecoration(
                        labelText: "No. Telepon",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _emailController,
                      decoration: InputDecoration(
                        labelText: "Email",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _saveToko,
                        icon: const Icon(Icons.save),
                        label: const Text("Simpan Profil Toko"),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

/// InfoTile untuk view
class InfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const InfoTile({
    Key? key,
    required this.icon,
    required this.title,
    required this.value,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Icon(icon, color: Colors.blue),
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}
