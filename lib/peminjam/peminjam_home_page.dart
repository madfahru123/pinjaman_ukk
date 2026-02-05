import 'package:flutter/material.dart';
import 'peminjaman_saya_page.dart';
import 'pengembalian_alat_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login_page.dart';
import '/alat_page_local.dart';

class PeminjamHomePage extends StatefulWidget {
  const PeminjamHomePage({super.key});

  @override
  State<PeminjamHomePage> createState() => _PeminjamHomePageState();
}

class _PeminjamHomePageState extends State<PeminjamHomePage> {
  final supabase = Supabase.instance.client;

  int sedangDipinjam = 0;
  int riwayat = 0;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    fetchStatus();
  }

  Future<void> fetchStatus() async {
    try {
      final user = supabase.auth.currentUser;
      if (user == null) return;

      // 🔥 Sedang dipinjam
      final dipinjamRes = await supabase
          .from('peminjaman')
          .select('id')
          .eq('userid', user.id)
          .eq('status', 'dipinjam');

      // 🔥 Riwayat (selain pending)
      final riwayatRes = await supabase
          .from('peminjaman')
          .select('id')
          .eq('userid', user.id)
          .neq('status', 'pending');

      if (!mounted) return;

      setState(() {
        sedangDipinjam = dipinjamRes.length;
        riwayat = riwayatRes.length;
        loading = false;
      });
    } catch (e) {
      debugPrint("FETCH STATUS ERROR: $e");
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F7FA),
      appBar: AppBar(
        title: const Text("Dashboard Peminjam"),
        automaticallyImplyLeading: false,
        elevation: 0,
        backgroundColor: Colors.blue,
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👋 HEADER
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.blue,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 26,
                          backgroundColor: Colors.white,
                          child: Icon(
                            Icons.person,
                            size: 30,
                            color: Colors.blue,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Sugeng Rawuh 👋",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                              ),
                            ),
                            Text(
                              user?.email ?? "-",
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // 📊 STATUS CARDS
                  Row(
                    children: [
                      _statusCard(
                        title: "Sedang Dipinjam",
                        value: sedangDipinjam.toString(),
                        icon: Icons.assignment,
                        color: Colors.orange,
                      ),
                      const SizedBox(width: 12),
                      _statusCard(
                        title: "Riwayat",
                        value: riwayat.toString(),
                        icon: Icons.history,
                        color: Colors.green,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // 📋 MENU
                  const Text(
                    "Menu",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),

                  _menuCard(
                    icon: Icons.inventory_2,
                    title: "Daftar Alat",
                    subtitle: "Lihat alat yang tersedia",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AlatPage(fromPeminjam: true),
                        ),
                      ).then((_) => fetchStatus());
                    },
                  ),

                  _menuCard(
                    icon: Icons.assignment_turned_in,
                    title: "Peminjaman Saya",
                    subtitle: "Cek status peminjaman",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PeminjamanSayaPage()),
                      ).then((_) => fetchStatus());
                    },
                  ),

                  _menuCard(
                    icon: Icons.assignment_return,
                    title: "Pengembalian Alat",
                    subtitle: "Ajukan pengembalian alat",
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PengembalianAlatPage(),
                        ),
                      ).then((_) => fetchStatus());
                    },
                  ),

                  _menuCard(
                    icon: Icons.logout,
                    title: "Logout",
                    subtitle: "Keluar dari aplikasi",
                    onTap: () async {
                      await supabase.auth.signOut();
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => const LoginPage()),
                        (route) => false,
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  // ===== STATUS CARD =====
  Widget _statusCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 6),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            Text(title, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  // ===== MENU CARD =====
  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue.withOpacity(0.1),
          child: Icon(icon, color: Colors.blue),
        ),
        title: Text(title),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
