import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:safe_alert/screens/Denuncias/nova_denuncia_screen.dart';
import 'package:safe_alert/screens/Login/splash_screen.dart';
import 'package:safe_alert/screens/Login/login_screen.dart';
import 'package:safe_alert/screens/home_screen.dart';
import 'package:safe_alert/screens/chat_screen.dart';

// ▼▼▼ FUNÇÃO CORRIGIDA ▼▼▼
class AuthCheck extends StatelessWidget {
  // Adicionado o construtor com a key
  const AuthCheck({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData) {
          // Adicionado 'const' para melhor performance
          return const HomeScreen();
        }
        // Adicionado 'const' para melhor performance
        return const LoginScreen();
      },
    );
  }
}
// ▲▲▲ FIM DA CORREÇÃO ▲▲▲

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const SafeAlertApp());
}

class SafeAlertApp extends StatelessWidget {
  const SafeAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Safe Alert',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.grey,
        inputDecorationTheme: InputDecorationTheme(
          labelStyle: const TextStyle(color: Colors.black),
          floatingLabelStyle: const TextStyle(color: Colors.black),
          focusedBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(12),
          ),
          enabledBorder: OutlineInputBorder(
            borderSide: const BorderSide(color: Colors.black),
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        textSelectionTheme: TextSelectionThemeData(
          cursorColor: Colors.black,
          selectionColor: Colors.grey.shade300,
          selectionHandleColor: Colors.black,
        ),
      ),
      home: const SplashScreen(),
      routes: {
        // Adicionado 'const' para melhor performance
        '/nova-denuncia': (_) => const NovaDenunciaScreen(),
        '/chat': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>;
          return ChatScreen(
            chatId: args['chatId'],
            otherUserId: args['otherUserId'] ?? args['uidDestino'],
            otherUserName: args['otherUserName'] ?? args['nomeDestino'],
          );
        },
      },
    );
  }
}