import 'package:flutter/material.dart';
import 'home_page.dart';
import 'petugas_page.dart';
import 'alat_page_local.dart';
import 'profil_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(), // 0
    const PetugasPage(), // 1
    const AlatPage(), // 2
    const ProfilTokoPage(), // ✅ PAKAI INI
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        selectedItemColor: Colors.blue,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Petugas"),
          BottomNavigationBarItem(icon: Icon(Icons.inventory), label: "Alat"),
          BottomNavigationBarItem(icon: Icon(Icons.store), label: "Profil"),
        ],
      ),
    );
  }
}
