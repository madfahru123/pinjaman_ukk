import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DipinjamPage extends StatefulWidget {
  const DipinjamPage({super.key});

  @override
  State<DipinjamPage> createState() => _DipinjamPageState();
}

class _DipinjamPageState extends State<DipinjamPage> {
  final supabase = Supabase.instance.client;
  List<Map<String, dynamic>> data = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDipinjam();
  }

  Future<void> fetchDipinjam() async {
    try {
      final result = await supabase
          .from('peminjaman')
          .select('''
      id,
      status,
      jumlah,
      tanggal_pinjaman,
      alat:alatid(
        nama_alat,
        foto
      ),
      profiles:userid(
        email
      )
    ''')
          .inFilter('status', ['dipinjam', 'disetujui']);

      if (!mounted) return;

      setState(() {
        data = List<Map<String, dynamic>>.from(result);
        loading = false;
      });
    } catch (e) {
      debugPrint("FETCH DIPINJAM ERROR: $e");
      setState(() => loading = false);
    }
  }

  int hitungDurasi(String tanggalPinjam) {
    final tglPinjam = DateTime.parse(tanggalPinjam);
    final now = DateTime.now();
    return now.difference(tglPinjam).inDays;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Alat Sedang Dipinjam"),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : data.isEmpty
          ? const Center(child: Text("Tidak ada alat dipinjam"))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: data.length,
              itemBuilder: (context, i) {
                final item = data[i];

                final namaAlat = item['alat']?['nama_alat'] ?? '-';
                final fotoAlat = item['alat']?['foto'];
                final peminjamEmail = item['profiles']?['email'] ?? '-';
                final jumlah = item['jumlah'] ?? 0;
                final tanggalPinjam = item['tanggal_pinjaman'];
                final durasi = tanggalPinjam != null
                    ? hitungDurasi(tanggalPinjam)
                    : 0;

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
                  child: Row(
                    children: [
                      // ===== FOTO ALAT =====
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          bottomLeft: Radius.circular(16),
                        ),
                        child:
                            fotoAlat != null && fotoAlat.toString().isNotEmpty
                            ? Image.network(
                                fotoAlat,
                                width: 110,
                                height: 110,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 110,
                                height: 110,
                                color: Colors.grey.shade300,
                                child: const Icon(
                                  Icons.image,
                                  size: 40,
                                  color: Colors.grey,
                                ),
                              ),
                      ),

                      // ===== INFO =====
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(14),
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
                              const SizedBox(height: 6),
                              Text(
                                "Peminjam: $peminjamEmail",
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                "Jumlah: $jumlah",
                                style: const TextStyle(fontSize: 12),
                              ),
                              Text(
                                "Durasi: $durasi hari",
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Text(
                                  "Sedang Dipinjam",
                                  style: TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ],
                          ),
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
