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
            alatid,
            userid,
            alat:alatid(nama_alat),
            profiles:userid(email)
          ''')
          .eq('status', 'dipinjam');

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Alat Sedang Dipinjam"),
        backgroundColor: Colors.blue,
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
                final peminjamEmail = item['profiles']?['email'] ?? '-';
                final jumlah = item['jumlah'] ?? 0;

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
                  child: Padding(
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
                        const SizedBox(height: 6),
                        Text("Peminjam: $peminjamEmail"),
                        Text("Jumlah: $jumlah"),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Text(
                            "Sedang Dipinjam",
                            style: TextStyle(
                              color: Colors.green,
                              fontWeight: FontWeight.bold,
                            ),
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
}
