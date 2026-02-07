import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'penerimaan_page.dart';
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
    try {
      setState(() => isLoading = true);

      final data = await supabase
          .from('peminjaman')
          .select()
          .eq('status', 'pengembalian_diajukan')
          .order('tanggal_kembalikan', ascending: true);

      if (!mounted) return;

      setState(() {
        listPengembalian = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      debugPrint('ERROR fetch pengembalian: $e');
      setState(() => isLoading = false);
    }
  }

  // ================= TERIMA =================
  Future<void> terimaPengembalian(int id, int alatId) async {
    try {
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

      fetchPengembalian();
    } catch (e) {
      debugPrint('ERROR terima pengembalian: $e');
    }
  }

  // ================= DENDA / RUSAK =================
  Future<void> dendaPengembalian(
    int peminjamanId,
    int alatId,
    String peminjamId,
  ) async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // ===============================
      // AMBIL NOMINAL DENDA DARI TABEL ALAT
      // ===============================
      final alat = await supabase
          .from('alat')
          .select('denda')
          .eq('id', alatId)
          .single();

      final int nominalDenda = int.tryParse(alat['denda'].toString()) ?? 0;

      // ===============================
      // INSERT KE TABEL DENDA (SESUAI DB)
      // ===============================
      await supabase.from('denda').insert({
        'peminjamid': peminjamId,
        'jumlah_denda': nominalDenda,
        'status': 'belum_bayar',
      });

      // ===============================
      // UPDATE STATUS PEMINJAMAN
      // ===============================
      await supabase
          .from('peminjaman')
          .update({'status': 'denda'})
          .eq('id', peminjamanId);

      // ===============================
      // LOG AKTIVITAS
      // ===============================
      await supabase.from('log_aktivitas').insert({
        'aksi': 'Petugas memberi denda pengembalian alat (ID: $alatId)',
        'userid': user.id,
      });

      if (!mounted) return;

      // ===============================
      // PINDAH KE DENDA PAGE (AWAIT!)
      // ===============================
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const DendaPage()),
      );
    } catch (e) {
      debugPrint('ERROR denda pengembalian: $e');
    }
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengembalian Barang'),
        backgroundColor: Colors.blue,
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

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Alat ID : ${item['alatid']}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text('User ID : ${item['userid']}'),
                        Text('Jumlah dipinjam : ${item['jumlah']}'),
                        Text(
                          'Jumlah dikembalikan : ${item['jumlah_dikembalikan']}',
                        ),
                        Text('Durasi : ${item['durasi']} hari'),
                        Text(
                          'Tanggal dikembalikan : ${item['tanggal_kembalikan']}',
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                await dendaPengembalian(
                                  item['id'],
                                  item['alatid'],
                                  item['userid'],
                                );

                                // 👉 setelah balik dari DendaPage, refresh list
                                fetchPengembalian();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red,
                              ),
                              child: const Text('Rusak / Denda'),
                            ),

                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PenerimaanPage(
                                      peminjamanId: item['id'],
                                      jumlah: item['jumlah'],
                                    ),
                                  ),
                                );

                                if (result == true) {
                                  await terimaPengembalian(
                                    item['id'],
                                    item['alatid'],
                                  );
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              child: const Text('Terima'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
