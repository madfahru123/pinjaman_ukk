import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PengajuanPage extends StatefulWidget {
  const PengajuanPage({super.key});

  @override
  State<PengajuanPage> createState() => _PengajuanPageState();
}

class _PengajuanPageState extends State<PengajuanPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> pengajuan = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchPengajuan();
  }

  Future<void> fetchPengajuan() async {
    setState(() => loading = true);
    try {
      final data = await supabase
          .from('peminjaman')
          .select('''
            id,
            jumlah,
            status,
            durasi,
            kelengkapan,
            created_at,
            alat:alatid(nama_alat, foto),
            profiles:userid(email)
          ''')
          .eq('status', 'pending')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        pengajuan = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      debugPrint("FETCH ERROR: $e");
      setState(() => loading = false);
    }
  }

  Future<void> updateStatus(int id, String status) async {
    try {
      await supabase.from('peminjaman').update({'status': status}).eq('id', id);
      fetchPengajuan();
    } catch (e) {
      debugPrint("UPDATE ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pengajuan Peminjaman"),
        backgroundColor: Colors.blue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : pengajuan.isEmpty
          ? const Center(child: Text("Tidak ada pengajuan"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: pengajuan.length,
              itemBuilder: (_, i) {
                final item = pengajuan[i];

                /// ===== DATA AMAN =====
                String namaAlat = '-';
                String fotoAlat = '';
                String email = '-';
                String kelengkapan = item['kelengkapan'] ?? '-';

                final alat = item['alat'];
                final profile = item['profiles'];
                final int durasi =
                    int.tryParse(item['durasi']?.toString() ?? '0') ?? 0;

                if (alat is Map) {
                  namaAlat = alat['nama_alat'] ?? '-';
                  fotoAlat = alat['foto'] ?? '';
                }

                if (profile is Map) {
                  email = profile['email'] ?? '-';
                }

                /// ===== TANGGAL =====
                String tanggal = '-';
                if (item['created_at'] != null) {
                  final dt = DateTime.tryParse(item['created_at'].toString());
                  if (dt != null) {
                    tanggal = dt.toLocal().toString().split(' ')[0];
                  }
                }

                final int jumlah =
                    int.tryParse(item['jumlah']?.toString() ?? '0') ?? 0;
                final int id = int.tryParse(item['id']?.toString() ?? '0') ?? 0;

                Color statusColor = Colors.orange;
                if (item['status'] == 'ditolak') {
                  statusColor = Colors.red;
                } else if (item['status'] == 'dipinjam') {
                  statusColor = Colors.green;
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      /// FOTO ALAT
                      if (fotoAlat.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.vertical(
                            top: Radius.circular(16),
                          ),
                          child: Image.network(
                            fotoAlat,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),

                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            /// NAMA ALAT
                            Text(
                              namaAlat,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),

                            Text("Peminjam : $email"),
                            Text("Jumlah    : $jumlah"),
                            Text("Kelengkapan : $kelengkapan"),
                            Text("Tanggal   : $tanggal"),
                            Text("Durasi    : $durasi hari"),

                            const SizedBox(height: 12),

                            /// STATUS + TOMBOL
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    item['status'].toString().toUpperCase(),
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Row(
                                  children: [
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () =>
                                          updateStatus(id, 'dipinjam'),
                                      child: const Text("ACC"),
                                    ),
                                    const SizedBox(width: 8),
                                    ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            12,
                                          ),
                                        ),
                                      ),
                                      onPressed: () =>
                                          updateStatus(id, 'ditolak'),
                                      child: const Text("Tolak"),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
