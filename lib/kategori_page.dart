import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class KategoriPage extends StatefulWidget {
  const KategoriPage({super.key});

  @override
  State<KategoriPage> createState() => _KategoriPageState();
}

class _KategoriPageState extends State<KategoriPage> {
  final supabase = Supabase.instance.client;
  final TextEditingController namaCtrl = TextEditingController();

  List<Map<String, dynamic>> kategoriList = [];

  @override
  void initState() {
    super.initState();
    fetchKategori();
  }

  @override
  void dispose() {
    namaCtrl.dispose();
    super.dispose();
  }

  Future<void> fetchKategori() async {
    final data = await supabase.from('kategori').select().order('nama');

    setState(() {
      kategoriList = List<Map<String, dynamic>>.from(data);
    });
  }

  Future<void> tambahKategori() async {
    if (namaCtrl.text.trim().isEmpty) return;

    await supabase.from('kategori').insert({'nama': namaCtrl.text.trim()});

    namaCtrl.clear();
    fetchKategori();
  }

  Future<void> hapusKategori(int id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Hapus Kategori"),
        content: const Text("Yakin ingin menghapus kategori ini?"),
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

    await supabase.from('kategori').delete().eq('id', id);
    fetchKategori();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Kelola Kategori")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: namaCtrl,
                    decoration: const InputDecoration(
                      labelText: "Nama Kategori",
                      border: OutlineInputBorder(),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: tambahKategori,
                  child: const Text("Tambah"),
                ),
              ],
            ),
          ),

          Expanded(
            child: kategoriList.isEmpty
                ? const Center(child: Text("Belum ada kategori"))
                : ListView.builder(
                    itemCount: kategoriList.length,
                    itemBuilder: (context, index) {
                      final k = kategoriList[index];
                      return ListTile(
                        title: Text(k['nama']),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => hapusKategori(k['id']),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
