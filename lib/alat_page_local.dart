import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'peminjam/ajukan_peminjaman_page.dart';

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

  final List<String> kategoriList = [
    "Semua",
    "Komputer",
    "Keyboard",
    "Mouse",
    "Proyektor",
  ];

  bool isAdmin = false;

  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    fetchAlat();
    loadRole();
  }

  Future<void> fetchAlat() async {
    final data = await supabase.from('alat').select().order('created_at');
    setState(() {
      alatList = List<Map<String, dynamic>>.from(data);
      filteredAlatList = alatList; // tambahkan iki
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
      final kategori = alat['kategori']?.toLowerCase() ?? '';

      final cocokNama = nama.contains(query.toLowerCase());
      final cocokKategori =
          selectedKategori == "Semua" ||
          kategori == selectedKategori.toLowerCase();

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
                            "Kategori: ${alat["kategori"] ?? '-'}\n"
                            "Denda: Rp ${alat["denda"]}\n",
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
                                      ? () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  AjukanPeminjamanPage(
                                                    alat: alat,
                                                  ),
                                            ),
                                          );
                                        }
                                      : null,

                                  child: const Text("Pinjam"),
                                )
                              : null,
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
  String kategori = "Komputer";
  final Map<String, List<String>> kelengkapanByKategori = {
    "Komputer": ["CPU", "Monitor", "Keyboard", "Mouse"],
    "Keyboard": ["Kabel", "Dongle"],
    "Mouse": ["Kabel", "Dongle"],
    "Proyektor": ["Kabel HDMI", "Remote", "Tas"],
  };

  late String kelengkapan;

  XFile? pickedImage;
  String? imageUrl;

  final picker = ImagePicker();
  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();

    if (widget.alat != null) {
      kategori = widget.alat!['kategori'] ?? 'Komputer';
      kelengkapan =
          widget.alat!['kelengkapan'] ?? kelengkapanByKategori[kategori]!.first;
      if (![
        "Lengkap",
        ...kelengkapanByKategori[kategori]!,
      ].contains(kelengkapan)) {
        kelengkapan = "Lengkap";
      }
      nama.text = widget.alat!['nama_alat'] ?? '';
      stok.text = widget.alat!['stok'].toString();
      deskripsi.text = widget.alat!['deskripsi'] ?? '';
      denda.text = widget.alat!['denda']?.toString() ?? '';
      imageUrl = widget.alat!['foto'];
    } else {
      kategori = 'Komputer';
      kelengkapan = kelengkapanByKategori[kategori]!.first;
    }
  }

  Future pickImage() async {
    final img = await picker.pickImage(source: ImageSource.gallery);
    if (img != null) {
      setState(() => pickedImage = img);
    }
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

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.alat != null;

    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? "Edit Alat" : "Tambah Alat")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            GestureDetector(
              onTap: pickImage,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(16),
                ),
                child: pickedImage != null
                    ? kIsWeb
                          ? Image.network(pickedImage!.path, fit: BoxFit.cover)
                          : Image.file(
                              File(pickedImage!.path),
                              fit: BoxFit.cover,
                            )
                    : imageUrl != null
                    ? Image.network(imageUrl!, fit: BoxFit.cover)
                    : const Icon(Icons.image, size: 40),
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: nama,
              decoration: const InputDecoration(labelText: "Nama Alat"),
            ),
            TextField(
              controller: stok,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Stok"),
            ),
            TextField(
              controller: deskripsi,
              decoration: const InputDecoration(labelText: "Deskripsi"),
            ),
            TextField(
              controller: denda,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Denda (Rp)"),
            ),

            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: kategori,
              decoration: const InputDecoration(labelText: "Kategori"),
              items: const [
                DropdownMenuItem(value: "Komputer", child: Text("Komputer")),
                DropdownMenuItem(value: "Keyboard", child: Text("Keyboard")),
                DropdownMenuItem(value: "Mouse", child: Text("Mouse")),
                DropdownMenuItem(value: "Proyektor", child: Text("Proyektor")),
              ],
              onChanged: (v) {
                setState(() {
                  kategori = v!;
                  kelengkapan = kelengkapanByKategori[kategori]!.first;
                });
              },
            ),
            DropdownButtonFormField<String>(
              value: kelengkapan,
              decoration: const InputDecoration(labelText: "Kelengkapan"),
              items: [
                const DropdownMenuItem(
                  value: "Lengkap",
                  child: Text("Lengkap"),
                ),
                ...kelengkapanByKategori[kategori]!
                    .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                    .toList(),
              ],
              onChanged: (v) => setState(() => kelengkapan = v!),
            ),

            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: () async {
                try {
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
                    'kategori': kategori, // 🔥 INI KUNCINÉ
                    'kelengkapan': kelengkapan,
                    'foto': imageUrl,
                  };

                  if (isEdit) {
                    await supabase
                        .from('alat')
                        .update(data)
                        .eq('id', widget.alat!['id']);

                    await supabase.from('log_aktivitas').insert({
                      'aksi': 'Admin edit alat ${nama.text}',
                      'userid': user.id,
                    });
                  } else {
                    await supabase.from('alat').insert({
                      ...data,
                      'user_id': user.id,
                    });

                    await supabase.from('log_aktivitas').insert({
                      'aksi': 'Admin nambah alat ${nama.text}',
                      'userid': user.id,
                    });
                  }

                  Navigator.pop(context, true);
                } catch (e) {
                  debugPrint("❌ ERROR: $e");
                }
              },
              child: Text(isEdit ? "UPDATE" : "SIMPAN"),
            ),
          ],
        ),
      ),
    );
  }
}
