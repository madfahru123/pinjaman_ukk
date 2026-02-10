import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'denda_admin_page.dart';
import 'pie_alat_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;
  Map<String, int> dataAlat = {};

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

  Future<int> fetchTotalDenda() async {
    final res = await supabase.from('denda').select('jumlah_denda');

    final data = List<Map<String, dynamic>>.from(res as List);

    return data.fold<int>(0, (sum, d) => sum + (d['jumlah_denda'] as int));
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

    if (counter.isEmpty) return;

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
      dataAlat = counter; // 🔥 SIMPEN SEMUA
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

  Widget hitungDenda(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const DendaAdminPage()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(14),
        ),
        child: FutureBuilder<int>(
          future: fetchTotalDenda(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(strokeWidth: 2),
              );
            }

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Denda",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),

                Text(
                  "Rp ${snapshot.data}",
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.red,
                  ),
                ),

                const SizedBox(height: 4),
                const Text(
                  "Total semua denda",
                  style: TextStyle(color: Colors.grey),
                ),

                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerRight,
                  child: Icon(Icons.arrow_forward_ios, size: 16),
                ),
              ],
            );
          },
        ),
      ),
    );
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
      mainAxisAlignment: MainAxisAlignment.center, // 🔑 KUNCI UTAMA
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const Text(
          "Persentase Alat Terpopuler",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 120,
              height: 120,
              child: CircularProgressIndicator(
                value: persentaseTop.clamp(0.0, 1.0),
                strokeWidth: 10,
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
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  namaAlatTop!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 12),
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
              height: 240, // 🔒 BATASI TINGGI
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: SingleChildScrollView(
                          physics: const NeverScrollableScrollPhysics(),
                          child: InkWell(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      PieAlatPage(dataAlat: dataAlat),
                                ),
                              );
                            },
                            child: grafikBunderPersentase(),
                          ),
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
                                child: hitungDenda(context),
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
