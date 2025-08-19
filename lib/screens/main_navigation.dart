import 'package:flutter/material.dart';
import 'package:safe_alert/screens/chamados_screen.dart';
import 'package:safe_alert/screens/conversas_screen.dart';
import 'package:safe_alert/screens/profile_screen.dart';
import 'home_screen.dart';
import 'Denuncias/denuncias_screen.dart';
// Adicione aqui outras telas conforme for criando

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 2; // Começa na Home

  final List<Widget> _screens = [
    DenunciasScreen(),         // 0 - ícone de alerta
    ConversasScreen(),         // 1 - conversas
    HomeScreen(),          // 2 - tela inicial
    ChamadosScreen(),         // 3 - notificações
    ProfileScreen(),     // 4 - perfil (ícone mais à direita)
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
        backgroundColor: Colors.white,
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
          BottomNavigationBarItem(icon: Icon(Icons.notifications), label: 'Notificações'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
        ],
      ),
    );
  }
}
