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
  created_at,
  alat:alatid(
    nama_alat,
    foto,
    kategori:kategori_id(nama)
  ),
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

  /// =====================
  /// UPDATE STATUS + LOG
  /// =====================
  Future<void> updateStatus(int id, String status, String alatNama) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 1️⃣ update status dulu
      await supabase.from('peminjaman').update({'status': status}).eq('id', id);

      // 2️⃣ baru bikin log
      String aksiLog = '';
      if (status == 'dipinjam') {
        aksiLog = 'Petugas menyetujui peminjaman alat $alatNama';
      } else if (status == 'ditolak') {
        aksiLog = 'Petugas menolak peminjaman alat $alatNama';
      }

      if (aksiLog.isNotEmpty) {
        await supabase.from('log_aktivitas').insert({
          'userid': user.id, // HARUS ADA DI profiles.userid
          'aksi': aksiLog,
        });
      }

      fetchPengajuan();
    } catch (e) {
      debugPrint("UPDATE ERROR: $e");
    }
  }

  Future<void> konfirmasiAksi({
    required BuildContext context,
    required int id,
    required String status,
    required String alatNama,
  }) async {
    final isAcc = status == 'dipinjam';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(isAcc ? "Konfirmasi ACC" : "Konfirmasi Tolak"),
        content: Text(
          isAcc
              ? "Yakin ingin MENYETUJUI peminjaman alat $alatNama?"
              : "Yakin ingin MENOLAK peminjaman alat $alatNama?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isAcc ? Colors.green : Colors.red,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(isAcc ? "Setujui" : "Tolak"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await updateStatus(id, status, alatNama);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(isAcc ? "Peminjaman disetujui" : "Peminjaman ditolak"),
        ),
      );
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
                String kategori = '-';

                final alat = item['alat'];
                if (alat is Map) {
                  final kategoriMap = alat['kategori'];
                  if (kategoriMap is Map) {
                    kategori = kategoriMap['nama'] ?? '-';
                  }
                }

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
                            Text("Kategori   : $kategori"),
                            Text("Tanggal   : $tanggal"),
                            Text("Durasi    : $durasi hari"),
                            const SizedBox(height: 12),
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
                                      onPressed: () => konfirmasiAksi(
                                        context: context,
                                        id: id,
                                        status: 'dipinjam',
                                        alatNama: namaAlat,
                                      ),

                                      child: const Text("TERIMA"),
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
                                      onPressed: () => konfirmasiAksi(
                                        context: context,
                                        id: id,
                                        status: 'ditolak',
                                        alatNama: namaAlat,
                                      ),
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
