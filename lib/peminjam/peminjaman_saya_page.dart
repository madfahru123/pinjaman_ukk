import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PeminjamanSayaPage extends StatefulWidget {
  const PeminjamanSayaPage({super.key});

  @override
  State<PeminjamanSayaPage> createState() => _PeminjamanSayaPageState();
}

class _PeminjamanSayaPageState extends State<PeminjamanSayaPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> peminjaman = [];

  @override
  void initState() {
    super.initState();
    fetchPeminjaman();
  }

  Future<void> fetchPeminjaman() async {
    setState(() => loading = true);
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      final res = await supabase
          .from('peminjaman')
          .select('id, alatid, jumlah, durasi, status, alat:alatid(nama_alat)')
          .eq('userid', user.id)
          .neq(
            'status',
            'dikembalikan',
          ) // <-- filter: jangan tampilkan yg sudah dikembalikan
          .order('id', ascending: false);

      if (!mounted) return;

      peminjaman = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint("FETCH PEMINJAMAN ERROR: $e");
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Peminjaman Saya"),
        backgroundColor: Colors.blue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : peminjaman.isEmpty
          ? const Center(
              child: Text(
                "Belum ada peminjaman aktif",
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            )
          : RefreshIndicator(
              onRefresh: fetchPeminjaman,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: peminjaman.length,
                itemBuilder: (_, i) {
                  final p = peminjaman[i];
                  final status = p['status'];
                  Color statusColor;
                  String statusText;

                  switch (status) {
                    case 'pending':
                      statusColor = Colors.orange.shade300;
                      statusText = "Menunggu ACC petugas";
                      break;
                    case 'dipinjam':
                      statusColor = Colors.green.shade300;
                      statusText = "Sedang dipinjam";
                      break;
                    case 'ditolak':
                      statusColor = Colors.red.shade300;
                      statusText = "Ditolak";
                      break;
                    default:
                      statusColor = Colors.grey.shade300;
                      statusText = status;
                  }

                  return Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      title: Text(
                        p['alat']?['nama_alat'] ?? "Alat",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(
                            "Jumlah: ${p['jumlah']}  •  Durasi: ${p['durasi']} hari",
                            style: const TextStyle(
                              color: Colors.black87,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              statusText,
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      leading: CircleAvatar(
                        backgroundColor: statusColor.withOpacity(0.2),
                        child: Icon(Icons.inventory_2, color: statusColor),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}
