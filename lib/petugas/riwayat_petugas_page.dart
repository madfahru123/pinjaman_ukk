import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class RiwayatPetugasPage extends StatefulWidget {
  const RiwayatPetugasPage({super.key});

  @override
  State<RiwayatPetugasPage> createState() => _RiwayatPetugasPageState();
}

class _RiwayatPetugasPageState extends State<RiwayatPetugasPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> riwayat = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRiwayat();
  }

  // ================= FETCH RIWAYAT =================
  Future<void> fetchRiwayat() async {
    try {
      final data = await supabase
          .from('peminjaman')
          .select()
          .or('status.eq.selesai,status.eq.denda')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        riwayat = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      debugPrint("FETCH RIWAYAT ERROR: $e");
      setState(() => loading = false);
    }
  }

  // ================= HAPUS RIWAYAT =================
  Future<void> hapusRiwayat(int id) async {
    try {
      await supabase.from('peminjaman').delete().eq('id', id);

      if (!mounted) return;

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Riwayat berhasil dihapus")));

      fetchRiwayat();
    } catch (e) {
      debugPrint("HAPUS RIWAYAT ERROR: $e");
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Gagal menghapus riwayat")));
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (riwayat.isEmpty) {
      return const Center(child: Text("Belum ada riwayat"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: riwayat.length,
      itemBuilder: (context, index) {
        final item = riwayat[index];

        final isDenda = item['status'] == 'denda';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          child: ListTile(
            leading: Icon(
              isDenda ? Icons.warning : Icons.check_circle,
              color: isDenda ? Colors.red : Colors.green,
            ),
            title: Text(item['nama_peminjam'] ?? 'Peminjam'),
            subtitle: Text("Alat: ${item['nama_alat'] ?? '-'}"),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  item['status'],
                  style: TextStyle(
                    color: isDenda ? Colors.red : Colors.green,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.grey),
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: const Text("Hapus Riwayat"),
                        content: const Text(
                          "Yakin ingin menghapus riwayat ini?\nData tidak bisa dikembalikan.",
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Batal"),
                          ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red,
                            ),
                            onPressed: () {
                              Navigator.pop(context);
                              hapusRiwayat(item['id']);
                            },
                            child: const Text("Hapus"),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
