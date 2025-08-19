import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../main_navigation.dart';
import 'login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navegar();
  }

  void _navegar() async {
    await Future.delayed(const Duration(seconds: 2)); // tempo do splash

    final user = FirebaseAuth.instance.currentUser;

    if (!mounted) return; // evitar erro se o widget foi desmontado

    if (user != null) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => MainNavigation()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Image(
          image: AssetImage('assets/logo_safealert.png'), // sua logo aqui
          width: 180,
        ),
      ),
    );
  }
}
