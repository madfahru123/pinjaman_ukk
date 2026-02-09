import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/services.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  final TextEditingController hariCtrl = TextEditingController();
  final TextEditingController dendaCtrl = TextEditingController();
  int totalDenda = 0;
  bool loading = true;
  List<Map<String, dynamic>> peminjamanAcc = [];
  List<Map<String, dynamic>> filtered = [];
  double persentaseTop = 0;
  String? namaAlatTop;
  int totalTop = 0;

  final TextEditingController searchCtrl = TextEditingController();
  @override
  void initState() {
    super.initState();
    fetchPeminjamanAcc();
    searchCtrl.addListener(_onSearch);
  }

  @override
  void dispose() {
    searchCtrl.dispose();
    hariCtrl.dispose();
    dendaCtrl.dispose();
    super.dispose();
  }

  void _onSearch() {
    if (peminjamanAcc.isEmpty) return;

    final q = searchCtrl.text.toLowerCase();
    setState(() {
      filtered = peminjamanAcc.where((e) {
        final alat = e['alat']?['nama_alat']?.toString().toLowerCase() ?? '';
        return alat.contains(q);
      }).toList();
    });
  }

  Future<void> fetchPeminjamanAcc() async {
    try {
      final res = await supabase
          .from('peminjaman')
          .select('''
            id,
            jumlah,
            profiles(nama),
            alat(nama_alat, foto)
          ''')
          .eq('status', 'dipinjam');

      final List<Map<String, dynamic>> data = res == null
          ? <Map<String, dynamic>>[]
          : List<Map<String, dynamic>>.from(res as List);

      setState(() {
        peminjamanAcc = data;
        filtered = data;
        loading = false;
      });

      hitungAlatTerpopuler(); // 🔥 TAMBAH INI
    } catch (e) {
      debugPrint('FETCH ERROR: $e');
      setState(() => loading = false);
    }
  }

  void hitungAlatTerpopuler() {
    if (peminjamanAcc.isEmpty) return;

    final Map<String, int> counter = {};

    for (final p in peminjamanAcc) {
      final nama = p['alat']?['nama_alat']?.toString();
      final int jumlah = (p['jumlah'] as num?)?.toInt() ?? 1;

      if (nama == null || nama.isEmpty) continue;

      counter[nama] = (counter[nama] ?? 0) + jumlah;
    }

    if (counter.isEmpty) return; // 🔒 GUARD PENTING

    String topNama = counter.keys.first;
    int topJumlah = counter[topNama]!;

    counter.forEach((k, v) {
      if (v > topJumlah) {
        topNama = k;
        topJumlah = v;
      }
    });

    final total = counter.values.fold<int>(0, (a, b) => a + b);

    if (!mounted) return;

    setState(() {
      namaAlatTop = topNama;
      totalTop = topJumlah;
      persentaseTop = total == 0 ? 0 : topJumlah / total;
    });
  }

  Widget cardPeminjaman(Map<String, dynamic> data) {
    final alat = data['alat']?['nama_alat'] ?? '-';
    final peminjam = data['profiles']?['nama'] ?? '-';
    final jumlah = data['jumlah'];
    final foto = data['alat']?['foto'];

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: foto != null && foto.toString().isNotEmpty
              ? Image.network(foto, width: 50, height: 50, fit: BoxFit.cover)
              : Container(
                  width: 50,
                  height: 50,
                  color: Colors.grey.shade300,
                  child: const Icon(Icons.image),
                ),
        ),
        title: Text(alat, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text("Peminjam: $peminjam\nJumlah: $jumlah"),
        trailing: const Icon(Icons.check_circle, color: Colors.green),
      ),
    );
  }

  Widget hitungDenda() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Hitung Denda",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        TextField(
          controller: hariCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: "Hari Telat",
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _prosesDenda(),
        ),
        const SizedBox(height: 10),

        TextField(
          controller: dendaCtrl,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          decoration: const InputDecoration(
            labelText: "Denda / Hari",
            border: OutlineInputBorder(),
          ),
          onChanged: (_) => _prosesDenda(),
        ),
        const SizedBox(height: 12),

        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            "Total Denda: Rp ${totalDenda.toString()}",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
        ),
      ],
    );
  }

  void _prosesDenda() {
    final hari = int.tryParse(hariCtrl.text.trim()) ?? 0;
    final denda = int.tryParse(dendaCtrl.text.trim()) ?? 0;

    if (!mounted) return;

    setState(() {
      totalDenda = hari * denda;
    });
  }

  /// ===== GRAFIK BUNDER PERSENTASE =====
  Widget grafikBunderPersentase() {
    if (loading ||
        persentaseTop <= 0 ||
        namaAlatTop == null ||
        namaAlatTop!.isEmpty) {
      return const Center(
        child: Text("Belum ada data", style: TextStyle(color: Colors.grey)),
      );
    }

    final persenText = (persentaseTop * 100).toStringAsFixed(0);

    return Column(
      children: [
        const Text(
          "Persentase Alat Terpopuler",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 140,
              height: 140,
              child: CircularProgressIndicator(
                value: persentaseTop.clamp(0.0, 1.0),
                strokeWidth: 14,
                backgroundColor: Colors.grey.shade300,
                valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
              ),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  "$persenText%",
                  style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  namaAlatTop!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          "$totalTop x disewa",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      body: SafeArea(
        bottom: true, // 🔑 INI KUNCI TERAKHIR
        child: Column(
          children: [
            // ===== APPBAR (LEBIH PENDEK + SEARCH) =====
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(16, 36, 16, 16),
              decoration: const BoxDecoration(
                color: Color(0xFF3F2BFF),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(28),
                  bottomRight: Radius.circular(28),
                ),
              ),
              child: SafeArea(
                bottom: false,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min, // 🔑 PENTING
                  children: [
                    const Text(
                      "PEMINJAMAN DISETUJUI",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      height: 40, // 🔒 tinggi search dikunci
                      child: TextField(
                        controller: searchCtrl,
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Cari alat yang dipinjam...",
                          prefixIcon: const Icon(Icons.search, size: 20),
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding: EdgeInsets.zero,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 12),

            /// ===== KOTAKAN SCROLL =====
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: loading
                      ? const Center(child: CircularProgressIndicator())
                      : filtered.isEmpty
                      ? const Center(child: Text("Data tidak ditemukan"))
                      : ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) => cardPeminjaman(filtered[i]),
                        ),
                ),
              ),
            ),

            /// ===== GRAFIK + TERPOPULER =====
            SizedBox(
              height: 260, // 🔒 BATASI TINGGI
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(), // 🔑
                          child: grafikBunderPersentase(),
                        ),
                      ),
                    ),

                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: LayoutBuilder(
                          builder: (context, constraints) {
                            return SingleChildScrollView(
                              child: ConstrainedBox(
                                constraints: BoxConstraints(
                                  minHeight: constraints.maxHeight,
                                ),
                                child: hitungDenda(),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
