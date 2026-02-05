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
  String kondisi = 'Baik'; // default
  TextEditingController catatanController = TextEditingController();
  TextEditingController jumlahController = TextEditingController();

  @override
  void initState() {
    super.initState();
    jumlahController.text = widget.jumlah.toString();
  }

  Future<void> submitPenerimaan() async {
    setState(() => isSubmitting = true);
    try {
      await supabase
          .from('peminjaman')
          .update({
            'status': 'selesai',
            'kondisi': kondisi,
            'catatan': catatanController.text,
            'jumlah': int.parse(jumlahController.text),
          })
          .eq('id', widget.peminjamanId);

      if (mounted)
        Navigator.pop(context, true); // kembali ke halaman sebelumnya
    } catch (e) {
      debugPrint('ERROR Penerimaan: $e');
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Form Penerimaan Alat')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: jumlahController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Jumlah dikembalikan',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: kondisi,
              decoration: const InputDecoration(labelText: 'Kondisi Alat'),
              items: const [
                DropdownMenuItem(value: 'Baik', child: Text('Baik')),
                DropdownMenuItem(value: 'Rusak', child: Text('Rusak')),
              ],
              onChanged: (val) => setState(() => kondisi = val ?? 'Baik'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: catatanController,
              decoration: const InputDecoration(
                labelText: 'Catatan (opsional)',
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSubmitting ? null : submitPenerimaan,
              child: isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Submit Penerimaan'),
            ),
          ],
        ),
      ),
    );
  }
}
