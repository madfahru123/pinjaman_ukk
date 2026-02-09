import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DendaPage extends StatefulWidget {
  const DendaPage({super.key});

  @override
  State<DendaPage> createState() => _DendaPageState();
}

class _DendaPageState extends State<DendaPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> listDenda = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchDenda();
  }

  // ================= FETCH DENDA =================
  Future<void> fetchDenda() async {
    try {
      setState(() => loading = true);

      final data = await supabase
          .from('denda')
          .select()
          .order('id', ascending: false);

      if (!mounted) return;

      setState(() {
        listDenda = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      debugPrint('ERROR fetch denda: $e');
      setState(() => loading = false);
    }
  }

  // ================= TANDAI LUNAS =================
  Future<void> tandaiLunas(int dendaId) async {
    try {
      await supabase
          .from('denda')
          .update({'status': 'lunas'})
          .eq('id', dendaId);

      fetchDenda();
    } catch (e) {
      debugPrint('ERROR update denda: $e');
    }
  }

  int get totalDendaAktif {
    return listDenda
        .where((e) => e['status'] == 'belum_bayar')
        .fold<int>(0, (sum, e) => sum + (e['jumlah_denda'] as int));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Denda Peminjaman"),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : listDenda.isEmpty
          ? const Center(child: Text("Tidak ada data denda"))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _summaryCard(),
                const SizedBox(height: 16),
                ...listDenda.map(_dendaCard),
              ],
            ),
    );
  }

  // ================= SUMMARY =================
  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade400, Colors.red.shade600],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.gavel, color: Colors.white, size: 40),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Total Denda Aktif",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 4),
              Text(
                "Rp ${_rupiah(totalDendaAktif)}",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= DENDA CARD =================
  Widget _dendaCard(Map<String, dynamic> item) {
    final bool lunas = item['status'] == 'lunas';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== HEADER =====
          Row(
            children: [
              Expanded(
                child: Text(
                  'Peminjam ID: ${item['peminjamid']}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: lunas
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lunas ? 'LUNAS' : 'BELUM BAYAR',
                  style: TextStyle(
                    color: lunas ? Colors.green : Colors.orange,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),

          const Text(
            'Jenis denda: Keterlambatan',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),

          const Divider(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoItem("Nominal", "Rp ${_rupiah(item['jumlah_denda'])}"),
              _infoItem("Status", item['status']),
            ],
          ),

          const SizedBox(height: 12),

          if (!lunas)
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton.icon(
                onPressed: () => tandaiLunas(item['id']),
                icon: const Icon(Icons.check_circle),
                label: const Text("Tandai Lunas"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _infoItem(String title, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }

  static String _rupiah(int number) {
    return number.toString().replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}
