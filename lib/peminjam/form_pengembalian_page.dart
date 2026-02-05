import 'package:flutter/material.dart';

class FormPengembalianPage extends StatefulWidget {
  final Map<String, dynamic> peminjaman;
  final TextEditingController jumlahController;
  final Function({
    required String kelengkapan,
    required String kondisi,
    required String kerusakan,
  })
  onSubmit;

  const FormPengembalianPage({
    super.key,
    required this.peminjaman,
    required this.jumlahController,
    required this.onSubmit,
  });

  @override
  State<FormPengembalianPage> createState() => _FormPengembalianPageState();
}

class _FormPengembalianPageState extends State<FormPengembalianPage> {
  String? kelengkapan;
  String? kondisi;
  final kerusakanController = TextEditingController();
  int durasiHari = 0;

  @override
  void initState() {
    super.initState();

    /// jumlah dipinjam (READ ONLY)
    widget.jumlahController.text =
        widget.peminjaman['jumlah']?.toString() ?? '0';

    /// hitung durasi (AMAN flutter web)
    final pinjamStr = widget.peminjaman['tanggal_pinjaman'];
    final kembaliStr = widget.peminjaman['tanggal_kembalikan'];

    if (pinjamStr is String && kembaliStr is String) {
      final tPinjam = DateTime.tryParse(pinjamStr);
      final tKembali = DateTime.tryParse(kembaliStr);
      if (tPinjam != null && tKembali != null) {
        durasiHari = tKembali.difference(tPinjam).inDays;
      }
    }
  }

  @override
  void dispose() {
    kerusakanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alat = widget.peminjaman['alat'] is Map
        ? widget.peminjaman['alat']
        : {};
    final String? foto = alat['foto_url'];
    final String namaAlat = alat['nama_alat'] ?? '-';

    final bool validFoto = foto != null && foto.toString().startsWith('http');

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Pengembalian Alat"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// FOTO ALAT
            Container(
              height: 190,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                image: validFoto
                    ? DecorationImage(
                        image: NetworkImage(foto),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: !validFoto
                  ? const Center(
                      child: Icon(Icons.devices, size: 80, color: Colors.grey),
                    )
                  : null,
            ),

            const SizedBox(height: 16),

            /// NAMA ALAT
            Text(
              namaAlat,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            /// INFO CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _infoRow("Jumlah Dipinjam", widget.jumlahController.text),
                  const Divider(),
                  _infoRow("Durasi Peminjaman", "$durasiHari hari"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// KELENGKAPAN
            DropdownButtonFormField<String>(
              value: kelengkapan,
              items: const [
                DropdownMenuItem(value: "Lengkap", child: Text("Lengkap")),
                DropdownMenuItem(
                  value: "Tidak Lengkap",
                  child: Text("Tidak Lengkap"),
                ),
              ],
              onChanged: (v) => setState(() => kelengkapan = v),
              decoration: _inputDecoration("Kelengkapan Alat"),
            ),

            const SizedBox(height: 12),

            /// KERUSAKAN
            TextField(
              controller: kerusakanController,
              maxLines: 2,
              decoration: _inputDecoration("Catatan Kerusakan"),
            ),

            const SizedBox(height: 12),

            /// KONDISI
            DropdownButtonFormField<String>(
              value: kondisi,
              items: const [
                DropdownMenuItem(value: "Baik", child: Text("Baik")),
                DropdownMenuItem(
                  value: "Rusak Ringan",
                  child: Text("Rusak Ringan"),
                ),
                DropdownMenuItem(
                  value: "Rusak Berat",
                  child: Text("Rusak Berat"),
                ),
              ],
              onChanged: (v) => setState(() => kondisi = v),
              decoration: _inputDecoration("Kondisi Barang"),
            ),

            const SizedBox(height: 28),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () {
                  if (kelengkapan == null || kondisi == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Lengkapi semua data")),
                    );
                    return;
                  }

                  widget.onSubmit(
                    kelengkapan: kelengkapan!,
                    kondisi: kondisi!,
                    kerusakan: kerusakanController.text,
                  );

                  Navigator.pop(context);
                },
                child: const Text(
                  "Simpan Pengembalian",
                  style: TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ===== helper =====
  Widget _infoRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: Colors.grey)),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}
