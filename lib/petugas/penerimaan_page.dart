import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PenerimaanPage extends StatefulWidget {
  final int peminjamanId;
  final int jumlah;

  const PenerimaanPage({
    super.key,
    required this.peminjamanId,
    required this.jumlah,
  });

  @override
  State<PenerimaanPage> createState() => _PenerimaanPageState();
}

class _PenerimaanPageState extends State<PenerimaanPage> {
  final supabase = Supabase.instance.client;

  bool isSubmitting = false;
  String kondisi = 'Baik';

  final TextEditingController jumlahController = TextEditingController();
  final TextEditingController catatanController = TextEditingController();

  @override
  void initState() {
    super.initState();
    jumlahController.text = widget.jumlah.toString();
  }

  @override
  void dispose() {
    jumlahController.dispose();
    catatanController.dispose();
    super.dispose();
  }

  // ================= SUBMIT PENERIMAAN =================
  Future<void> submitPenerimaan() async {
    final int jumlahKembali = int.tryParse(jumlahController.text) ?? 0;

    if (jumlahKembali <= 0) {
      _showSnack("Jumlah tidak valid");
      return;
    }

    setState(() => isSubmitting = true);

    try {
      await supabase
          .from('peminjaman')
          .update({
            'status': 'selesai', // 🔑 STATUS FINAL
            'kondisi': kondisi,
            'catatan': catatanController.text.trim(),
            'jumlah': jumlahKembali,
            'tanggal_kembalikan': DateTime.now().toIso8601String(),
          })
          .eq('id', widget.peminjamanId);

      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('ERROR Penerimaan: $e');
      _showSnack("Gagal menyimpan penerimaan");
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text('Form Penerimaan Alat'),
        backgroundColor: const Color(0xFF3F2BFF),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Data Pengembalian",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 16),

              // ===== JUMLAH =====
              TextField(
                controller: jumlahController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Jumlah dikembalikan',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 16),

              // ===== KONDISI =====
              DropdownButtonFormField<String>(
                value: kondisi,
                decoration: const InputDecoration(
                  labelText: 'Kondisi Alat',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'Baik', child: Text('Baik')),
                  DropdownMenuItem(value: 'Rusak', child: Text('Rusak')),
                ],
                onChanged: (val) => setState(() => kondisi = val ?? 'Baik'),
              ),

              const SizedBox(height: 16),

              // ===== CATATAN =====
              TextField(
                controller: catatanController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Catatan (opsional)',
                  border: OutlineInputBorder(),
                ),
              ),

              const SizedBox(height: 24),

              // ===== SUBMIT =====
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: isSubmitting ? null : submitPenerimaan,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3F2BFF),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Submit Penerimaan',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
