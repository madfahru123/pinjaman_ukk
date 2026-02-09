import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'form_pengembalian_page.dart';

class PengembalianAlatPage extends StatefulWidget {
  const PengembalianAlatPage({super.key});

  @override
  State<PengembalianAlatPage> createState() => _PengembalianAlatPageState();
}

class _PengembalianAlatPageState extends State<PengembalianAlatPage> {
  final supabase = Supabase.instance.client;
  bool loading = true;
  List<Map<String, dynamic>> dipinjamList = [];

  @override
  void initState() {
    super.initState();
    fetchDipinjam();
  }

  Future<void> fetchDipinjam() async {
    setState(() => loading = true);
    final user = supabase.auth.currentUser;
    if (user == null) return;

    try {
      final res = await supabase
          .from('peminjaman')
          .select('''
          id,
          alatid,
          jumlah,
          durasi,
          status,
          alat:alatid(
            nama_alat,
            stok,
            foto,
            kategori:kategori_id(nama)
          )
          ''')
          .eq('userid', user.id)
          .eq('status', 'dipinjam');

      if (!mounted) return;

      setState(() {
        dipinjamList = List<Map<String, dynamic>>.from(res as List);
      });
    } catch (e) {
      debugPrint("FETCH DIPINJAM ERROR: $e");
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xfff6f8fb),
      appBar: AppBar(
        title: const Text("Pengembalian Alat"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : dipinjamList.isEmpty
          ? const Center(
              child: Text(
                "Tidak ada alat yang sedang dipinjam",
                style: TextStyle(color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: dipinjamList.length,
              itemBuilder: (context, index) {
                final item = dipinjamList[index];
                final alat = item['alat'] ?? {};
                final jumlah = item['jumlah'];
                final kategori = alat['kategori']?['nama'] ?? '-';
                final foto = alat['foto'];

                return Card(
                  elevation: 4,
                  shadowColor: Colors.black12,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        /// HEADER
                        Row(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: foto != null && foto.toString().isNotEmpty
                                  ? Image.network(
                                      foto,
                                      width: 56,
                                      height: 56,
                                      fit: BoxFit.cover,
                                    )
                                  : Container(
                                      width: 56,
                                      height: 56,
                                      color: Colors.grey.shade200,
                                      child: const Icon(
                                        Icons.image_not_supported,
                                      ),
                                    ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                alat['nama_alat'] ?? "-",
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        /// INFO
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _infoChip(
                              Icons.inventory_2,
                              "Dipinjam",
                              "$jumlah unit",
                            ),
                            _infoChip(
                              Icons.store,
                              "Stok",
                              "${alat['stok'] ?? '-'}",
                            ),
                            _infoChip(Icons.category, "Kategori", kategori),
                          ],
                        ),

                        const SizedBox(height: 20),

                        /// JUMLAH (READ ONLY)
                        TextField(
                          readOnly: true,
                          controller: TextEditingController(
                            text: jumlah.toString(),
                          ),
                          decoration: InputDecoration(
                            labelText: "Jumlah dikembalikan",
                            prefixIcon: const Icon(Icons.lock_outline),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),

                        /// BUTTON
                        SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.assignment_return),
                            label: const Text(
                              "Ajukan Pengembalian",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blueAccent,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => FormPengembalianPage(
                                    peminjaman: item,
                                    jumlahController: TextEditingController(
                                      text: jumlah.toString(),
                                    ),
                                    onSubmit:
                                        ({
                                          required String statusPengembalian,
                                          required String kerusakan,
                                        }) async {
                                          final user =
                                              supabase.auth.currentUser;
                                          if (user == null) return;

                                          final alatNama =
                                              alat['nama_alat'] ?? '-';

                                          await supabase
                                              .from('peminjaman')
                                              .update({
                                                'jumlah_dikembalikan': jumlah,
                                                'status_pengembalian':
                                                    statusPengembalian, // 🔥 BARU
                                                'catatan_kerusakan': kerusakan,
                                                'status':
                                                    'pengembalian_diajukan',
                                              })
                                              .eq('id', item['id']);

                                          await supabase
                                              .from('log_aktivitas')
                                              .insert({
                                                'aksi':
                                                    'Peminjam mengajukan pengembalian alat $alatNama',
                                                'userid': user.id,
                                              });

                                          fetchDipinjam();
                                        },
                                  ),
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
            ),
    );
  }

  // ================= INFO CHIP =================
  Widget _infoChip(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 18, color: Colors.blueGrey),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
      ],
    );
  }
}
