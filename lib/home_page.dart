import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          /// 🔵 HEADER BIRU (MENTOK KIRI–KANAN–ATAS)
          ///
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
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        "HAI ! ADMIN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 6),
                      Text(
                        "CoachPahru",
                        style: TextStyle(color: Colors.white70, fontSize: 13),
                      ),
                    ],
                  ),
                ),
                const CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, color: Color(0xFF3F2BFF), size: 34),
                ),
              ],
            ),
          ),

          /// 📦 CARD ISI
          Expanded(
            child: Container(
              margin: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  const Text(
                    "Daftar Peminjaman",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      children: const [
                        PeminjamanTile(
                          tanggal: "Senin 12-Jan-1997",
                          nama: "Dava",
                          proyek: "Proyektor A12",
                        ),
                        PeminjamanTile(
                          tanggal: "Selasa 15-Jan-1997",
                          nama: "Dewa",
                          proyek: "Proyektor A12",
                        ),
                        PeminjamanTile(
                          tanggal: "Rabu 14-Jan-1997",
                          nama: "Ahmad",
                          proyek: "Proyektor A12",
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class PeminjamanTile extends StatelessWidget {
  final String tanggal;
  final String nama;
  final String proyek;

  const PeminjamanTile({
    super.key,
    required this.tanggal,
    required this.nama,
    required this.proyek,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tanggal, style: const TextStyle(fontSize: 12)),
                  Text(
                    nama,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            Text(
              proyek,
              style: const TextStyle(color: Colors.blue, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
