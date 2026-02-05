import 'package:flutter/material.dart';
import 'package:pinjaman_ukk/alat_page_local.dart';
import 'package:pinjaman_ukk/profil_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../login_page.dart';
import 'pengajuan_page.dart';
import 'dipinjam_page.dart';
import 'pengembalian_page.dart';
import 'riwayat_petugas_page.dart';
import 'denda_page.dart';

class PetugasHomePage extends StatefulWidget {
  const PetugasHomePage({super.key});

  @override
  State<PetugasHomePage> createState() => _PetugasHomePageState();
}

class _PetugasHomePageState extends State<PetugasHomePage> {
  int _currentIndex = 0;

  // ================= LOGOUT =================
  Future<void> _logout(BuildContext context) async {
    final supabase = Supabase.instance.client;
    await supabase.auth.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  // ================= MENU CARD MODERN =================
  Widget _menuCardModern({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 100,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.85), color.withOpacity(0.65)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.35),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 14,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    );
  }

  // ================= DASHBOARD =================
  Widget _dashboardPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                // ==== Row 1: Denda & Pengembalian ====
                Row(
                  children: [
                    Expanded(
                      child: _menuCardModern(
                        icon: Icons.gavel,
                        title: "Denda",
                        subtitle: "Kerusakan / Telat",
                        color: Colors.red,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DendaPage(),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _menuCardModern(
                        icon: Icons.assignment_returned,
                        title: "Pengembalian",
                        subtitle: "Alat kembali",
                        color: Colors.green,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => PengembalianPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // ==== Row 2: Dipinjam ====
                Row(
                  children: [
                    Expanded(
                      child: _menuCardModern(
                        icon: Icons.sync,
                        title: "Dipinjam",
                        subtitle: "Sedang dipinjam",
                        color: Colors.blue,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DipinjamPage(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // ===== PERMINTAAN PEMINJAM =====
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Permintaan Peminjam",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _menuCard(
              icon: Icons.assignment,
              title: "Pengajuan Peminjaman",
              subtitle: "ACC / Tolak permintaan",
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => PengajuanPage()),
                );
              },
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ================= MENU CARD DEFAULT =================
  Widget _menuCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
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

  // ================= PROFIL PAGE =================
  Widget _profilPage() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          const CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
          const SizedBox(height: 12),
          const Text(
            "Petugas",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ProfilTokoPage(canEdit: false),
                  ),
                );
              },
              icon: const Icon(Icons.store),
              label: const Text("Lihat Profil Toko"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _logout(context),
              icon: const Icon(Icons.logout),
              label: const Text("Logout"),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  // ================= PLACEHOLDER =================

  @override
  Widget build(BuildContext context) {
    final pages = [
      _dashboardPage(),
      const AlatPage(),
      const RiwayatPetugasPage(),
      _profilPage(),
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(150),
        child: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.transparent,
          elevation: 0,
          flexibleSpace: Container(
            decoration: const BoxDecoration(
              color: Color(0xFF0A4CFF),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(28),
                bottomRight: Radius.circular(28),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 48, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.person, color: Colors.white),
                    SizedBox(width: 8),
                    Text(
                      "Hai Petugas!!",
                      style: TextStyle(color: Colors.white, fontSize: 14),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  _currentIndex == 0
                      ? "Beranda Petugas"
                      : _currentIndex == 1
                      ? "Daftar Alat"
                      : _currentIndex == 2
                      ? "Riwayat"
                      : "Profil",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Beranda"),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: "Alat"),
          BottomNavigationBarItem(icon: Icon(Icons.history), label: "Riwayat"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
