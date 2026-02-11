import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class RiwayatPetugasPage extends StatefulWidget {
  const RiwayatPetugasPage({super.key});

  @override
  State<RiwayatPetugasPage> createState() => _RiwayatPetugasPageState();
}

class _RiwayatPetugasPageState extends State<RiwayatPetugasPage> {
  final supabase = Supabase.instance.client;

  List<Map<String, dynamic>> riwayat = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchRiwayat();
  }

  // ================= FETCH RIWAYAT =================
  Future<void> fetchRiwayat() async {
    try {
      final data = await supabase
          .from('peminjaman')
          .select('''
            id,
            status,
            created_at,
            profiles:userid ( nama ),
            alat:alatid ( nama_alat )
          ''')
          .or('status.eq.selesai,status.eq.denda')
          .order('created_at', ascending: false);

      if (!mounted) return;

      setState(() {
        riwayat = List<Map<String, dynamic>>.from(data);
        loading = false;
      });
    } catch (e) {
      debugPrint("FETCH RIWAYAT ERROR: $e");
      setState(() => loading = false);
    }
  }

  Future<void> hapusRiwayat(int id) async {
    try {
      await supabase.from('peminjaman').delete().eq('id', id);

      fetchRiwayat();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Data berhasil dihapus"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal hapus: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // ================= CETAK PDF =================
  Future<void> cetakPdf() async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Text(
            'LAPORAN RIWAYAT PEMINJAMAN',
            style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 16),
          pw.Table.fromTextArray(
            headers: const ['No', 'Peminjam', 'Alat', 'Status', 'Tanggal'],
            data: List.generate(riwayat.length, (i) {
              final item = riwayat[i];
              final namaPeminjam = item['profiles']?['nama'] ?? '-';
              final namaAlat = item['alat']?['nama_alat'] ?? '-';

              return [
                (i + 1).toString(),
                namaPeminjam,
                namaAlat,
                item['status']?.toUpperCase() ?? '-',
                item['created_at'] != null
                    ? item['created_at'].toString().substring(0, 10)
                    : '-',
              ];
            }),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellHeight: 30,
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (format) async => pdf.save());
  }

  // ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: Colors.red,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text("PDF"),
        onPressed: riwayat.isEmpty ? null : cetakPdf,
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                "Riwayat Peminjaman",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            Expanded(child: _buildBody()),
          ],
        ),
      ),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (riwayat.isEmpty) {
      return const Center(child: Text("Belum ada riwayat"));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: riwayat.length,
      itemBuilder: (context, index) {
        final item = riwayat[index];
        final isDenda = item['status'] == 'denda';

        final namaPeminjam = item['profiles']?['nama'] ?? '-';
        final namaAlat = item['alat']?['nama_alat'] ?? '-';

        return Card(
          elevation: 2,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        namaPeminjam,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isDenda
                                ? Colors.red.withOpacity(0.15)
                                : Colors.green.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            item['status'].toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDenda ? Colors.red : Colors.green,
                            ),
                          ),
                        ),

                        const SizedBox(width: 8),

                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: const Text("Hapus Data"),
                                content: const Text(
                                  "Yakin ingin menghapus riwayat ini?",
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    child: const Text("Batal"),
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                    ),
                                    onPressed: () {
                                      Navigator.pop(context);
                                      hapusRiwayat(item['id']);
                                    },
                                    child: const Text("Hapus"),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 8),
                Text("Alat : $namaAlat"),
                Text(
                  "Tanggal : ${item['created_at'] != null ? item['created_at'].toString().substring(0, 10) : '-'}",
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
