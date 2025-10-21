// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_alert/screens/ProfileSettings/contatos_emergencia_screen.dart';
import 'package:safe_alert/screens/ProfileSettings/editar_email_screen.dart';
import 'package:safe_alert/screens/ProfileSettings/editar_senha_screen.dart';
import 'package:safe_alert/screens/ProfileSettings/editar_telefone_screen.dart';
import 'Login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  Stream<DocumentSnapshot>? _userStream;

  final List<Color> _opcoesDeCor = [
    Colors.grey,
    Colors.blue,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.purple,
    Colors.teal,
    Colors.black,
  ];

  @override
  void initState() {
    super.initState();
    if (user != null) {
      _userStream = FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .snapshots();
    }
  }

  void _mostrarSeletorDeCor(Color corAtual) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Escolha uma cor para o seu perfil',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 15,
                runSpacing: 15,
                alignment: WrapAlignment.center,
                children: _opcoesDeCor.map((cor) {
                  return GestureDetector(
                    onTap: () {
                      _atualizarCorDoPerfil(cor);
                      Navigator.pop(context);
                    },
                    child: CircleAvatar(
                      radius: 25,
                      backgroundColor: cor,
                      child: cor == corAtual
                          ? const Icon(Icons.check, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _atualizarCorDoPerfil(Color novaCor) async {
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('usuarios')
          .doc(user!.uid)
          .set({
        // <-- CORREÇÃO APLICADA AQUI
        'profileColor': novaCor.toARGB32(),
      }, SetOptions(merge: true));
    }
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (Route<dynamic> route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(""),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
          stream: _userStream,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final userData = snapshot.data!.data() as Map<String, dynamic>? ?? {};
            final nome = userData['nome'] as String? ?? '...';
            final telefone = userData['telefone'] as String? ?? '-';
            
            // <-- CORREÇÃO APLICADA AQUI
            final int corValor = userData['profileColor'] ?? Colors.grey.toARGB32();
            final Color corDoPerfil = Color(corValor);

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: corDoPerfil,
                        child: const Icon(Icons.person, size: 50, color: Colors.white),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: GestureDetector(
                          onTap: () => _mostrarSeletorDeCor(corDoPerfil),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.edit, color: Colors.white, size: 18),
                          ),
                        ),
                      )
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Dados Pessoais", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 10),
                          _buildInfoRow("Nome", nome),
                          _buildInfoRow("E-mail", user?.email ?? "-"),
                          _buildInfoRow("Telefone", telefone),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  Card(
                    color: Colors.white,
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Configurações", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(height: 10),
                          _buildAction("Alterar telefone", () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditarTelefoneScreen()));
                          }),
                          _buildAction("Alterar E-mail", () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditarEmailScreen()));
                          }),
                          _buildAction("Alterar senha", () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => const EditarSenhaScreen()));
                          }),
                          _buildAction("Contatos de Emergência", () {
                            Navigator.push(context, MaterialPageRoute(builder: (_) => ContatosEmergenciaScreen()));
                          }),
                          const SizedBox(height: 10),
                          GestureDetector(
                            onTap: _logout,
                            child: const Text("Sair", style: TextStyle(color: Colors.red, fontSize: 16)),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(
            "$label:",
            style: const TextStyle(fontSize: 15),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAction(String text, VoidCallback onTap) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(text, style: const TextStyle(fontSize: 15)),
      onTap: onTap,
      dense: true,
    );
  }
}