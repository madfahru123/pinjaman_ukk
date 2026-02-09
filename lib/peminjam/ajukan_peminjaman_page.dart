import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AjukanPeminjamanPage extends StatefulWidget {
  final Map<String, dynamic> alat;

  const AjukanPeminjamanPage({super.key, required this.alat});

  @override
  State<AjukanPeminjamanPage> createState() => _AjukanPeminjamanPageState();
}

class _AjukanPeminjamanPageState extends State<AjukanPeminjamanPage> {
  final supabase = Supabase.instance.client;

  final jumlah = TextEditingController(text: "1");
  final durasi = TextEditingController();

  DateTime? tanggalPinjam;
  DateTime? tanggalKembali;

  bool loading = false;

  int _hitungDurasi(DateTime start, DateTime end) {
    return end.difference(start).inDays + 1;
  }

  // ================= OPSI KELENGKAPAN (FINAL) =================

  @override
  void initState() {
    super.initState();
  }

  // ================= PILIH TANGGAL =================
  Future<void> _pilihTanggal({required bool isPinjam}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked == null) return;

    setState(() {
      if (isPinjam) {
        tanggalPinjam = picked;
        tanggalKembali = null;
        durasi.clear();
      } else {
        if (tanggalPinjam == null) return;
        if (picked.isBefore(tanggalPinjam!)) return;

        tanggalKembali = picked;
        durasi.text = _hitungDurasi(tanggalPinjam!, tanggalKembali!).toString();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Ajukan Peminjaman"),
        backgroundColor: Colors.blueAccent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// FOTO
            if ((widget.alat['foto'] ?? '').isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  widget.alat['foto'],
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),

            const SizedBox(height: 16),

            /// INFO ALAT
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
              margin: const EdgeInsets.only(bottom: 20),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.alat['nama_alat'],
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _infoTile("Stok", "${widget.alat['stok']}"),
                        _infoTile(
                          "Kategori",
                          widget.alat['kategori']?['nama'] ?? "-",
                        ),
                        _infoTile("Denda", "Rp ${widget.alat['denda']}"),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            /// JUMLAH
            TextField(
              controller: jumlah,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Jumlah dipinjam",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.confirmation_number),
              ),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: durasi,
              readOnly: true,
              decoration: InputDecoration(
                labelText: "Durasi (hari)",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.schedule),
              ),
            ),

            const SizedBox(height: 16),

            /// TANGGAL PINJAM
            InkWell(
              onTap: () => _pilihTanggal(isPinjam: true),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Tanggal Peminjaman",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.date_range),
                ),
                child: Text(
                  tanggalPinjam == null
                      ? "Pilih tanggal"
                      : "${tanggalPinjam!.day}-${tanggalPinjam!.month}-${tanggalPinjam!.year}",
                ),
              ),
            ),

            const SizedBox(height: 16),

            /// TANGGAL KEMBALI
            InkWell(
              onTap: tanggalPinjam == null
                  ? null
                  : () => _pilihTanggal(isPinjam: false),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: "Tanggal Pengembalian",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  prefixIcon: const Icon(Icons.event_available),
                ),
                child: Text(
                  tanggalKembali == null
                      ? "Pilih tanggal"
                      : "${tanggalKembali!.day}-${tanggalKembali!.month}-${tanggalKembali!.year}",
                ),
              ),
            ),

            const SizedBox(height: 16),

            const SizedBox(height: 24),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : _konfirmasiAjukan,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "AJUKAN PEMINJAMAN",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= KONFIRMASI =================
  Future<void> _konfirmasiAjukan() async {
    if (tanggalPinjam == null || tanggalKembali == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Lengkapi semua data terlebih dahulu")),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Konfirmasi Peminjaman"),
        content: Text(
          "Alat: ${widget.alat['nama_alat']}\n"
          "Jumlah: ${jumlah.text}\n"
          "Durasi: ${durasi.text} hari\n"
          "Tanggal Pinjam: ${tanggalPinjam!.day}-${tanggalPinjam!.month}-${tanggalPinjam!.year}\n"
          "Tanggal Kembali: ${tanggalKembali!.day}-${tanggalKembali!.month}-${tanggalKembali!.year}\n"
          "Yakin ingin mengajukan?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Ajukan"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      ajukan();
    }
  }

  // ================= AJUKAN =================
  Future<void> ajukan() async {
    final user = supabase.auth.currentUser;
    if (user == null) return;

    setState(() => loading = true);

    await supabase.from('peminjaman').insert({
      'alatid': widget.alat['id'],
      'userid': user.id,
      'jumlah': int.parse(jumlah.text),
      'durasi': int.parse(durasi.text),
      'tanggal_pinjaman': tanggalPinjam!.toIso8601String(),
      'tanggal_kembalikan': tanggalKembali!.toIso8601String(),
      'status': 'pending',
    });

    await supabase.from('log_aktivitas').insert({
      'aksi': 'Peminjam mengajukan peminjaman alat ${widget.alat['nama_alat']}',
      'userid': user.id,
    });

    if (!mounted) return;
    Navigator.pop(context);
  }

  Widget _infoTile(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }
}
