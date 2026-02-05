import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'penerimaan_page.dart';

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

  Future<void> fetchPengembalian() async {
    try {
      setState(() => isLoading = true);

      final data = await supabase
          .from('peminjaman')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      setState(() {
        listPengembalian = List<Map<String, dynamic>>.from(data);
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      debugPrint('ERROR pengembalian: $e');
    }
  }

  Future<void> terimaPengembalian(int id) async {
    await supabase
        .from('peminjaman')
        .update({'status': 'selesai'})
        .eq('id', id);

    fetchPengembalian();
  }

  Future<void> dendaPengembalian(int id) async {
    await supabase.from('peminjaman').update({'status': 'denda'}).eq('id', id);

    fetchPengembalian();
  }

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
          ? const Center(child: Text('Tidak ada pengembalian'))
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
                        Text('Jumlah : ${item['jumlah']}'),
                        Text('Durasi : ${item['durasi']} hari'),
                        Text('Tanggal Dikembalikan : ${item['created_at']}'),

                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            ElevatedButton(
                              onPressed: () => dendaPengembalian(item['id']),
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
                                  fetchPengembalian(); // refresh list setelah submit
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
