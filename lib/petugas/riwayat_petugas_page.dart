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
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ====== HEADER ======
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      item['nama_peminjam'] ?? 'Peminjam',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isDenda
                            ? Colors.red.withOpacity(0.1)
                            : Colors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        item['status'].toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDenda ? Colors.red : Colors.green,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                // ====== INFO ALAT ======
                Row(
                  children: [
                    const Icon(Icons.inventory_2, size: 18, color: Colors.grey),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        item['nama_alat'] ?? '-',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 6),

                // ====== TANGGAL ======
                Row(
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: 16,
                      color: Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      item['created_at'] != null
                          ? item['created_at'].toString().substring(0, 10)
                          : '-',
                      style: const TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // ====== AKSI ======
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
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
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
