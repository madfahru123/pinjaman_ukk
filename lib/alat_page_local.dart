import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'peminjam/ajukan_peminjaman_page.dart';
import 'kategori_page.dart';

/// =======================================================
/// ====================== LIST ALAT ======================
/// =======================================================

class AlatPage extends StatefulWidget {
  final bool fromPeminjam; // ✅ TAMBAHAN

  const AlatPage({
    super.key,
    this.fromPeminjam = false, // ✅ DEFAULT DI CONSTRUCTOR
  });

  @override
  State<AlatPage> createState() => _AlatPageState();
}

class _AlatPageState extends State<AlatPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> alatList = [];
  List<Map<String, dynamic>> filteredAlatList = [];
  String selectedKategori = "Semua";
  List<String> kategoriList = ["Semua"];

  Future<void> fetchKategori() async {
    final data = await supabase.from('kategori').select('nama');

    setState(() {
      kategoriList = ["Semua", ...data.map<String>((k) => k['nama']).toList()];
    });
  }

  bool isAdmin = false;

  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchAlat();
    loadRole();
    fetchKategori(); // 🔥 WAJIB
  }

  Future<void> fetchAlat() async {
    final data = await supabase
        .from('alat')
        .select('''
        id,
        nama_alat,
        stok,
        denda,
        foto,
        kategori:kategori_id (
          id,
          nama
        )
      ''')
        .order('created_at');

    setState(() {
      alatList = List<Map<String, dynamic>>.from(data);
      filteredAlatList = alatList;
    });
  }

  Future<void> loadRole() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final data = await supabase
          .from('profiles')
          .select('role')
          .eq('userid', user.id)
          .maybeSingle();
      if (!mounted) return;
      setState(() {
        isAdmin = data != null && data['role'] == 'admin';
      });
    } catch (e) {
      debugPrint("❌ loadRole error: $e");
    }
  }

  void filterAlat(String query) {
    final filtered = alatList.where((alat) {
      final nama = alat['nama_alat']?.toLowerCase() ?? '';
      final kategoriNama = alat['kategori']?['nama']?.toLowerCase() ?? '';

      final cocokNama = nama.contains(query.toLowerCase());
      final cocokKategori =
          selectedKategori == "Semua" ||
          kategoriNama == selectedKategori.toLowerCase();

      return cocokNama && cocokKategori;
    }).toList();

    setState(() {
      searchQuery = query;
      filteredAlatList = filtered;
    });
  }

  Future<void> hapusAlat(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi Hapus"),
        content: const Text("Yakin ingin menghapus alat ini?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus"),
          ),
        ],
      ),
    );

    if (confirm != true) return;
    await supabase.from('alat').delete().eq('id', id);

    await supabase.from('log_aktivitas').insert({
      'aksi': 'Admin hapus alat ID $id',
      'userid': supabase.auth.currentUser!.id,
    });

    fetchAlat();

    fetchAlat();

    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text("Alat berhasil dihapus")));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: (isAdmin || widget.fromPeminjam == true)
          ? AppBar(
              backgroundColor: Colors.blue,
              title: const Text("Daftar Alat"),
              centerTitle: true,
            )
          : null,

      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              onChanged: filterAlat, // fungsi filter
              decoration: InputDecoration(
                hintText: "Cari alat...",
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          // ================= KATEGORI SCROLL =================
          SizedBox(
            height: 48,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: kategoriList.length,
              itemBuilder: (context, index) {
                final kategori = kategoriList[index];
                final isSelected = selectedKategori == kategori;

                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(kategori),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() {
                        selectedKategori = kategori;
                      });
                      filterAlat(searchQuery);
                    },
                    selectedColor: Colors.blue,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : Colors.black,
                    ),
                  ),
                );
              },
            ),
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.category),
              title: const Text("Kategori"),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const KategoriPage()),
                );
                fetchKategori();
                filterAlat(searchQuery);
              },
            ),

          // List alat
          Expanded(
            child: filteredAlatList.isEmpty
                ? const Center(child: Text("Belum ada data"))
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: filteredAlatList.length,
                    itemBuilder: (context, index) {
                      final alat = filteredAlatList[index];
                      return Card(
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(12),
                          leading: alat["foto"] != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    alat["foto"],
                                    width: 50,
                                    height: 50,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Icon(Icons.image, size: 40),
                          title: Text(
                            alat["nama_alat"],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "Stok: ${alat["stok"]}\n"
                            "Kategori: ${alat["kategori"]?["nama"] ?? '-'}\n"
                            "Denda: Rp ${alat["denda"]}",
                          ),

                          trailing: isAdmin
                              ? PopupMenuButton<String>(
                                  onSelected: (value) async {
                                    if (value == 'edit') {
                                      final hasil = await Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) =>
                                              TambahAlatPage(alat: alat),
                                        ),
                                      );
                                      if (hasil == true) fetchAlat();
                                    }
                                    if (value == 'hapus') {
                                      await hapusAlat(alat['id']);
                                    }
                                  },
                                  itemBuilder: (context) => const [
                                    PopupMenuItem(
                                      value: 'edit',
                                      child: Text("Edit"),
                                    ),
                                    PopupMenuItem(
                                      value: 'hapus',
                                      child: Text("Hapus"),
                                    ),
                                  ],
                                )
                              : widget.fromPeminjam
                              ? ElevatedButton(
                                  onPressed: alat['stok'] > 0
                                      ? () async {
                                          final result = await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AjukanPeminjamanPage(
                                                    alat: alat,
                                                  ),
                                            ),
                                          );

                                          if (result == true) {
                                            setState(
                                              () {},
                                            ); // 🔥 refresh daftar alat
                                          }
                                        }
                                      : null,
                                  child: const Text("Pinjam"),
                                )
                              : const SizedBox.shrink(),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),

      floatingActionButton: isAdmin
          ? FloatingActionButton(
              backgroundColor: Colors.blue,
              onPressed: () async {
                final hasil = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const TambahAlatPage()),
                );

                if (hasil == true) {
                  fetchAlat();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Alat berhasil ditambahkan")),
                  );
                }
              },
              child: const Icon(Icons.add),
            )
          : null,
    );
  }

  Future<void> ajukanPeminjaman(int alatId) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      await supabase.from('peminjaman').insert({
        'alatid': alatId,
        'userid': user.id,
        'jumlah': 1,
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Pengajuan peminjaman berhasil dikirim"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      debugPrint("❌ ERROR AJUKAN: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal mengajukan peminjaman"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

/// =======================================================
/// =================== TAMBAH / EDIT =====================
/// =======================================================

class TambahAlatPage extends StatefulWidget {
  final Map<String, dynamic>? alat;
  const TambahAlatPage({super.key, this.alat});

  @override
  State<TambahAlatPage> createState() => _TambahAlatPageState();
}

class _TambahAlatPageState extends State<TambahAlatPage> {
  final nama = TextEditingController();
  final stok = TextEditingController();
  final deskripsi = TextEditingController();
  final denda = TextEditingController();

  List<Map<String, dynamic>> kategoriList = [];
  int? selectedKategoriId;
  XFile? pickedImage;
  String? imageUrl;

  final picker = ImagePicker();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchKategori();

    if (widget.alat != null) {
      selectedKategoriId = widget.alat!['kategori']?['id'];
      nama.text = widget.alat!['nama_alat'] ?? '';
      stok.text = widget.alat!['stok'].toString();
      deskripsi.text = widget.alat!['deskripsi'] ?? '';
      denda.text = widget.alat!['denda']?.toString() ?? '';
      imageUrl = widget.alat!['foto'];
    }
  }

  Future pickImage() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) setState(() => pickedImage = img);
  }

  Future<String?> uploadImage(XFile file) async {
    final bytes = await file.readAsBytes();
    final fileName = "${DateTime.now().millisecondsSinceEpoch}.png";

    await supabase.storage
        .from('alat')
        .uploadBinary(
          fileName,
          bytes,
          fileOptions: const FileOptions(
            contentType: 'image/png',
            upsert: true,
          ),
        );

    return supabase.storage.from('alat').getPublicUrl(fileName);
  }

  Future<void> fetchKategori() async {
    final data = await supabase.from('kategori').select().order('nama');

    setState(() {
      kategoriList = List<Map<String, dynamic>>.from(data);
      selectedKategoriId ??= kategoriList.isNotEmpty
          ? kategoriList.first['id']
          : null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.alat != null;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text(isEdit ? "Edit Alat" : "Tambah Alat"),
        centerTitle: true,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// ===== FOTO =====
            GestureDetector(
              onTap: pickImage,
              child: CircleAvatar(
                radius: 60,
                backgroundColor: Colors.grey.shade300,
                backgroundImage: pickedImage != null
                    ? (kIsWeb
                          ? NetworkImage(pickedImage!.path)
                          : FileImage(File(pickedImage!.path)) as ImageProvider)
                    : imageUrl != null
                    ? NetworkImage(imageUrl!)
                    : null,
                child: pickedImage == null && imageUrl == null
                    ? const Icon(Icons.camera_alt, size: 36)
                    : null,
              ),
            ),
            const SizedBox(height: 24),

            /// ===== FORM CARD =====
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Column(
                children: [
                  _input(nama, "Nama Alat"),
                  _input(stok, "Stok", number: true),
                  _input(deskripsi, "Deskripsi"),
                  _input(denda, "Denda / Hari", number: true),

                  const SizedBox(height: 12),

                  DropdownButtonFormField<int>(
                    value: selectedKategoriId,
                    decoration: _decoration("Kategori"),
                    items: kategoriList.map((k) {
                      return DropdownMenuItem<int>(
                        value: k['id'],
                        child: Text(k['nama']),
                      );
                    }).toList(),
                    onChanged: (v) => setState(() => selectedKategoriId = v),
                  ),

                  const SizedBox(height: 24),

                  /// ===== BUTTON =====
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () async {
                        final user = supabase.auth.currentUser;
                        if (user == null) return;

                        if (pickedImage != null) {
                          imageUrl = await uploadImage(pickedImage!);
                        }

                        final data = {
                          'nama_alat': nama.text,
                          'stok': int.tryParse(stok.text) ?? 0,
                          'deskripsi': deskripsi.text,
                          'denda': int.tryParse(denda.text) ?? 0,
                          'kategori_id': selectedKategoriId,
                          'foto': imageUrl,
                        };

                        if (isEdit) {
                          await supabase
                              .from('alat')
                              .update(data)
                              .eq('id', widget.alat!['id']);
                        } else {
                          await supabase.from('alat').insert({
                            ...data,
                            'user_id': user.id,
                          });
                        }

                        Navigator.pop(context, true);
                      },
                      child: Text(
                        isEdit ? "UPDATE ALAT" : "SIMPAN ALAT",
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
          ],
        ),
      ),
    );
  }

  /// ===== HELPER =====
  Widget _input(TextEditingController c, String label, {bool number = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        keyboardType: number ? TextInputType.number : TextInputType.text,
        decoration: _decoration(label),
      ),
    );
  }

  InputDecoration _decoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    );
  }
}
