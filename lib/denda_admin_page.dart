import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DendaAdminPage extends StatefulWidget {
  const DendaAdminPage({super.key});

  @override
  State<DendaAdminPage> createState() => _DendaAdminPageState();
}

enum FilterDenda { all, minggu, bulan }

class _DendaAdminPageState extends State<DendaAdminPage> {
  final supabase = Supabase.instance.client;
  FilterDenda filterAktif = FilterDenda.all;

  // ================= FETCH DENDA =================
  Future<List<Map<String, dynamic>>> fetchDenda() async {
    DateTime? fromDate;
    final now = DateTime.now();

    if (filterAktif == FilterDenda.minggu) {
      fromDate = now.subtract(const Duration(days: 7));
    } else if (filterAktif == FilterDenda.bulan) {
      fromDate = DateTime(now.year, now.month - 1, now.day);
    }

    var query = supabase.from('denda').select('''
      id,
      jumlah_denda,
      status,
      jenis_denda,
      nama_alat,
      created_at,
      profiles:peminjamid ( nama )
    ''');

    if (fromDate != null) {
      query = query.gte('created_at', fromDate.toIso8601String());
    }

    final res = await query.order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(res as List);
  }

  // ================= HAPUS DENDA (LUNAS SAJA) =================
  Future<void> hapusDenda(int id) async {
    await supabase.from('denda').delete().eq('id', id);
    if (!mounted) return;
    setState(() {});
  }

  // ================= FILTER BUTTON =================
  Widget _filterButton(String text, FilterDenda type) {
    final aktif = filterAktif == type;

    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: aktif ? const Color(0xFF3F2BFF) : Colors.white,
            foregroundColor: aktif ? Colors.white : Colors.black,
            elevation: aktif ? 2 : 0,
            side: const BorderSide(color: Color(0xFF3F2BFF)),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: () {
            setState(() {
              filterAktif = type;
            });
          },
          child: Text(text),
        ),
      ),
    );
  }

  String rupiah(int angka) {
    return angka.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]}.',
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Rekap Denda"),
        backgroundColor: const Color(0xFF3F2BFF),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchDenda(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text("Error: ${snapshot.error}"));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text("Belum ada data denda"));
          }

          final data = snapshot.data!;

          final totalDenda = data.fold<int>(
            0,
            (sum, d) => sum + (d['jumlah_denda'] as int),
          );

          return Column(
            children: [
              const SizedBox(height: 16),

              // ===== TOTAL DENDA =====
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                padding: const EdgeInsets.symmetric(vertical: 24),
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFFF5F6D), Color(0xFFFFC371)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  children: [
                    const Text(
                      "TOTAL SEMUA DENDA",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      "Rp ${rupiah(totalDenda)}",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ===== FILTER =====
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _filterButton("Semua", FilterDenda.all),
                    _filterButton("Minggu", FilterDenda.minggu),
                    _filterButton("Bulan", FilterDenda.bulan),
                  ],
                ),
              ),

              const SizedBox(height: 12),

              // ===== LIST DENDA =====
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: data.length,
                  itemBuilder: (context, i) {
                    final d = data[i];
                    final status = d['status'];
                    final peminjam = d['profiles']?['nama'] ?? '-';
                    final alat = d['nama_alat'] ?? '-';
                    final alasan = d['jenis_denda'] ?? '-';

                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Rp ${rupiah(d['jumlah_denda'])}",
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Icon(
                                  status == 'lunas'
                                      ? Icons.check_circle
                                      : Icons.schedule,
                                  color: status == 'lunas'
                                      ? Colors.green
                                      : Colors.orange,
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text("Peminjam : $peminjam"),
                            Text("Alat     : $alat"),
                            Text(
                              "Alasan   : $alasan",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            const Divider(),
                            Align(
                              alignment: Alignment.centerRight,
                              child: IconButton(
                                icon: Icon(
                                  Icons.delete,
                                  color: status == 'lunas'
                                      ? Colors.red
                                      : Colors.grey,
                                ),
                                onPressed: status != 'lunas'
                                    ? null
                                    : () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text("Hapus Denda"),
                                            content: const Text(
                                              "Denda wis lunas. Yakin pengin ngapus?",
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text("Batal"),
                                              ),
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor: Colors.red,
                                                ),
                                                onPressed: () async {
                                                  Navigator.pop(context);
                                                  await hapusDenda(d['id']);
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
