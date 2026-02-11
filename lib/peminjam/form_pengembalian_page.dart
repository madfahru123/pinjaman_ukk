import 'package:flutter/material.dart';

class FormPengembalianPage extends StatefulWidget {
  final Map<String, dynamic> peminjaman;
  final TextEditingController jumlahController;
  final Function({
    required String statusPengembalian,
    required String alasanKeterlambatan, // 🔥 ganti dari kerusakan
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
  String? statusPengembalian;
  final alasanKeterlambatanController = TextEditingController();
  int durasiHari = 0;

  @override
  void initState() {
    super.initState();

    /// jumlah dipinjam (read only)
    widget.jumlahController.text =
        widget.peminjaman['jumlah']?.toString() ?? '0';

    /// hitung durasi otomatis
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
    alasanKeterlambatanController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final alat = widget.peminjaman['alat'] ?? {};
    final foto = alat['foto'];
    final namaAlat = alat['nama_alat'] ?? '-';
    final kategori = alat['kategori']?['nama'] ?? '-';

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(title: const Text("Pengembalian Alat"), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// FOTO
            Container(
              height: 180,
              width: double.infinity,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
                image: foto != null
                    ? DecorationImage(
                        image: NetworkImage(foto),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: foto == null
                  ? const Icon(Icons.devices, size: 80, color: Colors.grey)
                  : null,
            ),

            const SizedBox(height: 16),

            /// NAMA ALAT
            Text(
              namaAlat,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            /// INFO CARD
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _infoRow("Kategori", kategori),
                  const Divider(),
                  _infoRow("Jumlah Dipinjam", widget.jumlahController.text),
                  const Divider(),
                  _infoRow("Durasi Peminjaman", "$durasiHari hari"),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// STATUS PENGEMBALIAN
            DropdownButtonFormField<String>(
              value: statusPengembalian,
              items: const [
                DropdownMenuItem(
                  value: "Tepat Waktu",
                  child: Text("Tepat Waktu"),
                ),
                DropdownMenuItem(value: "Terlambat", child: Text("Terlambat")),
              ],
              onChanged: (v) => setState(() => statusPengembalian = v),
              decoration: _inputDecoration("Status Pengembalian"),
            ),

            const SizedBox(height: 12),

            /// CATATAN KERUSAKAN
            TextField(
              controller: alasanKeterlambatanController,
              maxLines: 2,
              decoration: _inputDecoration("Alasan Keterlambatan (opsional)"),
            ),

            const SizedBox(height: 28),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  if (statusPengembalian == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Pilih status pengembalian"),
                      ),
                    );
                    return;
                  }

                  final status = widget.peminjaman['status'] ?? '';

                  // 🔹 Nek wis diajukan
                  if (status == 'pengembalian_diajukan') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          "Pengembalian alat ini sudah diajukan sebelumnya",
                        ),
                        backgroundColor: Colors.orange,
                      ),
                    );
                    return;
                  }

                  // 🔥 Nek wis benar-benar dikembalikan
                  if (status == 'dikembalikan') {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Alat ini sudah dikembalikan ✅"),
                        backgroundColor: Colors.green,
                      ),
                    );
                    return;
                  }

                  // Submit normal
                  await widget.onSubmit(
                    statusPengembalian: statusPengembalian!,
                    alasanKeterlambatan: alasanKeterlambatanController.text,
                  );

                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Pengembalian berhasil diajukan ✅"),
                      backgroundColor: Colors.green,
                    ),
                  );

                  Navigator.pop(context);
                },

                child: const Text("Simpan Pengembalian"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// helper
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
