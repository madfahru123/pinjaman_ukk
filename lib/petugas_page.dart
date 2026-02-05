import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'tambah_petugas_page.dart';

class PetugasPage extends StatefulWidget {
  const PetugasPage({super.key});

  @override
  State<PetugasPage> createState() => _PetugasPageState();
}

class _PetugasPageState extends State<PetugasPage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> dataPetugas = [];

  @override
  void initState() {
    super.initState();
    fetchPetugas();
  }

  Future<void> fetchPetugas() async {
    try {
      final List<dynamic> res = await supabase
          .from('petugas')
          .select()
          .order('nama', ascending: true);

      if (!mounted) return;
      setState(() {
        dataPetugas = List<Map<String, dynamic>>.from(res);
        loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Gagal ambil data: $e')));
    }
  }

  /// 🔥 ID = INT (WAJIB)
  Future<void> deletePetugas(int id) async {
    await supabase.from('petugas').delete().eq('id', id);
    fetchPetugas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Daftar Petugas"),
        backgroundColor: Colors.blue,
        centerTitle: true,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : dataPetugas.isEmpty
          ? const Center(child: Text("Belum ada petugas"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dataPetugas.length,
              itemBuilder: (context, index) {
                final p = dataPetugas[index];

                /// 🔥 CAST AMAN
                final int id = (p['id'] as num).toInt();

                final String? fotoUrl =
                    (p['foto'] is String && p['foto'].startsWith('http'))
                    ? p['foto']
                    : null;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: PetugasCard(
                    nama: p['nama']?.toString() ?? '-',
                    email: p['email']?.toString() ?? '-',
                    fotoUrl: fotoUrl,
                    onEdit: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TambahPetugasPage(
                            id: id,
                            nama: p['nama']?.toString(),
                            alamat: p['alamat']?.toString(),
                            email: p['email']?.toString(),
                            foto: fotoUrl,
                          ),
                        ),
                      );
                      fetchPetugas();
                    },
                    onDelete: () => deletePetugas(id),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const TambahPetugasPage()),
          );
          fetchPetugas();
        },
      ),
    );
  }
}

class PetugasCard extends StatelessWidget {
  final String nama;
  final String email;
  final String? fotoUrl;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const PetugasCard({
    super.key,
    required this.nama,
    required this.email,
    required this.fotoUrl,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 25,
            backgroundColor: Colors.grey.shade200,
            backgroundImage: (fotoUrl != null) ? NetworkImage(fotoUrl!) : null,
            child: fotoUrl == null
                ? const Icon(Icons.account_circle, size: 40)
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nama,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(email, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.blue),
            onPressed: onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}
