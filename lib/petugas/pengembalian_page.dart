import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'denda_page.dart';

class PengembalianPage extends StatefulWidget {
  const PengembalianPage({super.key});

  @override
  State<PengembalianPage> createState() => _PengembalianPageState();
}

class _PengembalianPageState extends State<PengembalianPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> listPengembalian = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    fetchPengembalian();
  }

  // ================= FETCH DATA =================
  Future<void> fetchPengembalian() async {
    if (!mounted) return;

    setState(() => isLoading = true);

    try {
      final data = await supabase
          .from('peminjaman')
          .select('''
      *,
      alat:alatid(
        nama_alat,
        foto
      ),
      peminjam:userid(
        nama
      )
    ''')
          .eq('status', 'pengembalian_diajukan')
          .order('tanggal_kembalikan', ascending: true);

      if (!mounted) return;

      setState(() {
        listPengembalian = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR fetch pengembalian: $e');
      if (!mounted) return;
      setState(() => isLoading = false);
    }
  }

  // ================= TERIMA =================
  Future<void> terimaPengembalian(int id, int alatId) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    await supabase
        .from('peminjaman')
        .update({'status': 'selesai'})
        .eq('id', id);

    await supabase.from('log_aktivitas').insert({
      'aksi': 'Petugas menerima pengembalian alat (ID: $alatId)',
      'userid': user.id,
    });

    if (!mounted) return;
    fetchPengembalian();
  }

  // ================= DENDA =================
  Future<void> dendaPengembalian(
    int peminjamanId,
    int alatId,
    String peminjamId,
  ) async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    final alat = await supabase
        .from('alat')
        .select('denda')
        .eq('id', alatId)
        .single();

    final int nominalDenda = int.tryParse(alat['denda'].toString()) ?? 0;

    await supabase.from('denda').insert({
      'peminjaman_id': peminjamanId,
      'jumlah_denda': nominalDenda,
      'status': 'belum_bayar',
      'jenis_denda': 'alat rusak',
    });

    await supabase
        .from('peminjaman')
        .update({'status': 'denda'})
        .eq('id', peminjamanId);

    await supabase.from('log_aktivitas').insert({
      'aksi': 'Petugas memberi denda pengembalian alat (ID: $alatId)',
      'userid': user.id,
    });

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const DendaPage()),
    );
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Pengembalian Barang'),
        backgroundColor: Colors.blue,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : listPengembalian.isEmpty
          ? const Center(child: Text('Tidak ada pengajuan pengembalian'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: listPengembalian.length,
              itemBuilder: (context, index) {
                final item = listPengembalian[index];
                final alat = item['alat'];
                final peminjam = item['peminjam'];
                final String namaPeminjam = peminjam?['nama'] ?? '-';

                final String namaAlat = alat?['nama_alat'] ?? 'Alat';
                final String? fotoAlat = alat?['foto'];

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (fotoAlat != null && fotoAlat.isNotEmpty)
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
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            _info("Peminjam", namaPeminjam),

                            _info("Jumlah Dipinjam", item['jumlah']),
                            _info(
                              "Jumlah Dikembalikan",
                              item['jumlah_dikembalikan'],
                            ),
                            _info(
                              "Tanggal Kembali",
                              item['tanggal_kembalikan'],
                            ),

                            const SizedBox(height: 16),

                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.report_problem),
                                  label: const Text("Rusak / Denda"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () => dendaPengembalian(
                                    item['id'],
                                    item['alatid'],
                                    item['userid'],
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  icon: const Icon(Icons.check_circle),
                                  label: const Text("Terima"),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                  ),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (_) => AlertDialog(
                                        title: const Text("Konfirmasi"),
                                        content: const Text(
                                          "Yakin menerima pengembalian alat ini?",
                                        ),
                                        actions: [
                                          TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context, false),
                                            child: const Text("Batal"),
                                          ),
                                          ElevatedButton(
                                            onPressed: () =>
                                                Navigator.pop(context, true),
                                            child: const Text("Terima"),
                                          ),
                                        ],
                                      ),
                                    );

                                    if (confirm == true) {
                                      await terimaPengembalian(
                                        item['id'],
                                        item['alatid'],
                                      );

                                      if (!mounted) return;
                                      ScaffoldMessenger.of(
                                        context,
                                      ).showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                            "Pengembalian berhasil diterima",
                                          ),
                                          backgroundColor: Colors.green,
                                          behavior: SnackBarBehavior.floating,
                                          margin: EdgeInsets.all(16),
                                        ),
                                      );
                                    }
                                  },
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

  Widget _info(String label, dynamic value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Text(
        "$label : ${value ?? '-'}",
        style: const TextStyle(color: Colors.black87),
      ),
    );
  }
}
