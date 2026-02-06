import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final supabase = Supabase.instance.client;

  bool loading = true;
  List<Map<String, dynamic>> logs = [];

  DateTime? startDate;
  DateTime? endDate;

  @override
  void initState() {
    super.initState();
    fetchLogAktivitas();
  }

  /// =====================
  /// FETCH LOG + FILTER TANGGAL
  /// =====================
  Future<void> fetchLogAktivitas() async {
    try {
      final List<Map<String, dynamic>> res;

      if (startDate != null && endDate != null) {
        res = await supabase
            .from('log_aktivitas')
            .select('id, aksi, created_at, profiles(nama)')
            .gte('created_at', DateFormat('yyyy-MM-dd').format(startDate!))
            .lte(
              'created_at',
              DateFormat('yyyy-MM-dd 23:59:59').format(endDate!),
            )
            .order('created_at', ascending: false);
      } else if (startDate != null) {
        res = await supabase
            .from('log_aktivitas')
            .select('id, aksi, created_at, profiles(nama)')
            .gte('created_at', DateFormat('yyyy-MM-dd').format(startDate!))
            .order('created_at', ascending: false);
      } else if (endDate != null) {
        res = await supabase
            .from('log_aktivitas')
            .select('id, aksi, created_at, profiles(nama)')
            .lte(
              'created_at',
              DateFormat('yyyy-MM-dd 23:59:59').format(endDate!),
            )
            .order('created_at', ascending: false);
      } else {
        res = await supabase
            .from('log_aktivitas')
            .select('id, aksi, created_at, profiles(nama)')
            .order('created_at', ascending: false);
      }

      setState(() {
        logs = res;
        loading = false;
      });
    } catch (e) {
      debugPrint('ERROR FETCH LOG: $e');
      setState(() => loading = false);
    }
  }

  /// =====================
  /// DELETE LOG
  /// =====================
  Future<void> hapusLog(int id) async {
    try {
      await supabase.from('log_aktivitas').delete().eq('id', id);
      fetchLogAktivitas();
    } catch (e) {
      debugPrint('ERROR DELETE LOG: $e');
    }
  }

  String formatWaktu(String iso) {
    final dt = DateTime.parse(iso);
    return DateFormat('dd MMM yyyy • HH:mm').format(dt);
  }

  Future<void> pilihTanggal({required bool isStart}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          startDate = picked;
        } else {
          endDate = picked;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          /// 🔵 HEADER
          Container(
            width: double.infinity,
            height: 170,
            padding: const EdgeInsets.fromLTRB(16, 40, 16, 20),
            decoration: const BoxDecoration(
              color: Color(0xFF3F2BFF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "LOG AKTIVITAS ADMIN",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

          /// 🟡 FILTER TANGGAL
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => pilihTanggal(isStart: true),
                    child: Text(
                      startDate == null
                          ? "Tanggal Mulai"
                          : DateFormat('dd MMM yyyy').format(startDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => pilihTanggal(isStart: false),
                    child: Text(
                      endDate == null
                          ? "Tanggal Akhir"
                          : DateFormat('dd MMM yyyy').format(endDate!),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.search),
                  onPressed: fetchLogAktivitas,
                ),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    setState(() {
                      startDate = null;
                      endDate = null;
                    });
                    fetchLogAktivitas();
                  },
                ),
              ],
            ),
          ),

          /// 📦 LIST LOG
          Expanded(
            child: loading
                ? const Center(child: CircularProgressIndicator())
                : logs.isEmpty
                ? const Center(
                    child: Text(
                      "Tidak ada log aktivitas",
                      style: TextStyle(color: Colors.grey),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      return Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: ListTile(
                          title: Text(
                            log['aksi'],
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            "${log['profiles']?['nama'] ?? '-'} • ${formatWaktu(log['created_at'])}",
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () async {
                              final confirm = await showDialog<bool>(
                                context: context,
                                builder: (_) => AlertDialog(
                                  title: const Text("Hapus Log"),
                                  content: const Text(
                                    "Yakin ingin menghapus log ini?",
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () =>
                                          Navigator.pop(context, false),
                                      child: const Text("Batal"),
                                    ),
                                    ElevatedButton(
                                      onPressed: () =>
                                          Navigator.pop(context, true),
                                      child: const Text("Hapus"),
                                    ),
                                  ],
                                ),
                              );

                              if (confirm == true) {
                                await hapusLog(log['id']);
                              }
                            },
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
