import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:safe_alert/screens/ProfileSettings/contatos_emergencia_screen.dart';
import 'package:safe_alert/screens/ProfileSettings/editar_email_screen.dart';
import 'package:safe_alert/screens/ProfileSettings/editar_senha_screen.dart';
import 'package:safe_alert/screens/ProfileSettings/editar_telefone_screen.dart';
import 'Login/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final user = FirebaseAuth.instance.currentUser;
  String? nome;
  String? telefone;

  @override
  void initState() {
    super.initState();
    _buscarDadosUsuario();
  }

  Future<void> _buscarDadosUsuario() async {
    final doc = await FirebaseFirestore.instance
        .collection('usuarios')
        .doc(user?.uid)
        .get();

    setState(() {
      nome = doc['nome'];
      telefone = doc['telefone'];
    });
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => LoginScreen()),
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
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: Colors.grey,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),

            // --- DADOS PESSOAIS ---
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
                    _buildInfoRow("Nome", nome ?? "Carregando..."),
                    _buildInfoRow("E-mail", user?.email ?? "-"),
                    _buildInfoRow("Telefone", telefone ?? "-"),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // --- CONFIGURAÇÕES ---
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
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EditarTelefoneScreen()));
                    }),
                    _buildAction("Alterar E-mail", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EditarEmailScreen()));
                    }),
                    _buildAction("Alterar senha", () {
                      Navigator.push(context, MaterialPageRoute(builder: (_) => EditarSenhaScreen()));
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
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
