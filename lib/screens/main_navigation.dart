import 'package:flutter/material.dart';
import 'package:safe_alert/screens/chamados_screen.dart';
import 'package:safe_alert/screens/conversas_screen.dart';
import 'package:safe_alert/screens/profile_screen.dart';
import 'home_screen.dart';
import 'Denuncias/denuncias_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 2; // Começa na Home

  final List<Widget> _screens = [
    DenunciasScreen(),       // 0 - Denúncias
    ConversasScreen(),       // 1 - Conversas
    HomeScreen(),            // 2 - Tela inicial
    ChamadosScreen(),        // 3 - Chamados
    ProfileScreen(),         // 4 - Perfil
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        // --- ALTERAÇÕES APLICADAS AQUI ---
        backgroundColor: Colors.white,   // Cor de fundo
        type: BottomNavigationBarType.fixed, // Garante que a cor de fundo seja aplicada
        elevation: 0, // Remove qualquer sombra abaixo da barra

        // --- Estilo dos ícones ---
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        selectedItemColor: Colors.black,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: false,
        showUnselectedLabels: false,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.report), label: 'Denúncias'),
          BottomNavigationBarItem(icon: Icon(Icons.chat), label: 'Conversas'),
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Chamados'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
